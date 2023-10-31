defmodule HimmelWeb.Utils do
  alias Himmel.Accounts
  alias Phoenix.Component
  alias Phoenix.LiveView, as: LV
  alias Phoenix.LiveView.AsyncResult
  alias Himmel.Services.{IP, Places}
  alias Himmel.Places
  alias Himmel.Places.Place
  alias Himmel.Weather

  def places_weather_data_init(socket) do
    current_location_weather = get_current_location_weather(socket)
    current_user = socket.assigns[:current_user]
    saved_places = if current_user, do: current_user.places, else: []

    active_place =
      if current_user,
        do: Enum.find(saved_places, fn p -> p.location_id == current_user.active_place_id end),
        else: nil

    main_weather =
      case active_place do
        nil ->
          prepare_main_weather(current_location_weather)

        %Place{} = active_place ->
          Weather.get_weather(active_place)
          |> prepare_main_weather()
      end

    saved_places_socket =
      case saved_places do
        [] ->
          Component.assign(socket, saved_places: %AsyncResult{ok?: true, result: []})

        places when is_list(places) ->
          LV.assign_async(socket, :saved_places, fn ->
            {:ok, %{saved_places: Enum.map(places, fn p -> Weather.get_weather(p) end)}}
          end)
      end

    _places_weather_socket =
      Component.assign(saved_places_socket,
        main_weather: main_weather,
        current_location: current_location_weather
      )
  end

  def get_current_location_weather(socket) do
    socket
    |> IP.get_user_ip()
    |> IP.get_ip_details()
    |> Places.create_place_from_ip_details()
    |> Weather.get_weather()
  end

  def prepare_main_weather(%Place{
        name: name,
        weather: %{current: current, daily: daily, hourly: hourly}
      }) do
    todays_temp_range = List.first(daily) |> Map.get(:temperature)

    %{
      name: name,
      temperature: current.temperature,
      description_text: current.description.text,
      high: todays_temp_range.high,
      low: todays_temp_range.low,
      hours: hourly,
      days: daily
    }
  end

  # TODO: Update the user last active place after a new one is set to main weather

  def maybe_save_place_and_set_to_main_weather(location, socket) do
    current_user = socket.assigns[:current_user]
    async_saved_places = socket.assigns.saved_places
    saved_places_list = async_saved_places.result

    already_saved? =
      Enum.any?(saved_places_list, fn p ->
        p.location_id == "#{location.latitude},#{location.longitude}"
      end)

    if already_saved? do
      socket
    else
      new_place_with_weather =
        location
        |> Places.create_place_from_search_result()
        |> Weather.get_weather()

      updated_saved_places = [new_place_with_weather | saved_places_list]

      if current_user do
        # Places.save_place_to_user(current_user, place_with_weather)
        Accounts.update_user_places(current_user, updated_saved_places)
        # else
        #   nil
      end

      Component.assign(socket,
        main_weather: prepare_main_weather(new_place_with_weather),
        # updated_current_user: %{current_user | places: updated_db_saved_places},
        saved_places: %AsyncResult{
          async_saved_places
          | result: updated_saved_places
        }
      )
    end
  end

  def delete_place_and_maybe_change_main_weather(location_id, socket) do
    current_user = socket.assigns[:current_user]
    async_saved_places = socket.assigns.saved_places
    saved_places_list = async_saved_places.result

    updated_saved_places =
      Enum.reject(saved_places_list, fn p -> p.location_id == location_id end)

    # updated_db_saved_places =
    if current_user do
      # Places.remove_place_from_user(current_user, location_id)
      Accounts.update_user_places(current_user, updated_saved_places)

      # else
      #   nil
    end

    # TODO: Update the main weather to the place right after the one that was deleted. If the deleted place was the last one, update to the updated last one.

    Component.assign(socket,
      #  main_weather: Utils.prepare_main_weather(place),
      # current_user: %{current_user | places: updated_db_saved_places},
      saved_places:
        %AsyncResult{async_saved_places | result: updated_saved_places}
        |> IO.inspect(label: "lv_saved_places")
    )
  end
end
