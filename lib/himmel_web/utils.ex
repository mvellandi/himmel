defmodule HimmelWeb.Utils do
  alias Phoenix.Component
  alias Phoenix.LiveView, as: LV
  alias Phoenix.LiveView.AsyncResult
  alias Himmel.Accounts.User
  alias Himmel.Services.{IP, Places}
  alias Himmel.Places
  alias Himmel.Places.Place
  alias Himmel.Weather

  def app_data_init(
        socket,
        %User{places: saved_places, active_place_id: active_place_id}
      ) do
    # PLACES AND POSSIBLY MAIN WEATHER
    current_location_weather = get_current_location_weather(socket)

    # MAIN WEATHER
    # This is for setting the main weather to either the last loaded weather or the current location weather
    active_place =
      Enum.find(saved_places, fn p -> p.location_id == active_place_id end) ||
        nil

    main_weather =
      case active_place do
        nil ->
          prepare_main_weather(current_location_weather)

        %Place{} = active_place ->
          Weather.get_weather(active_place)
          |> prepare_main_weather()
      end

    # SETS ASSIGNS FOR BOTH MAIN AND PLACES LIVE COMPONENTS
    _socket =
      case saved_places do
        [] ->
          Component.assign(socket, saved_places: %AsyncResult{ok?: true, result: []})

        places when is_list(places) ->
          LV.assign_async(socket, :saved_places, fn ->
            {:ok, %{saved_places: Enum.map(places, fn p -> Weather.get_weather(p) end)}}
          end)
      end
      |> Component.assign(
        main_weather: main_weather,
        current_location: current_location_weather
      )
  end

  def app_data_init(socket, nil) do
    current_location_weather = get_current_location_weather(socket)

    main_weather = prepare_main_weather(current_location_weather)

    _socket =
      Component.assign(socket,
        main_weather: main_weather,
        current_location: current_location_weather,
        saved_places: %AsyncResult{ok?: true, result: []}
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

  def maybe_save_place_and_set_to_main_weather(location, socket) do
    async_saved_places = socket.assigns.saved_places
    saved_places_list = async_saved_places.result

    already_saved? =
      Enum.any?(saved_places_list, fn p ->
        p.location_id == "#{location.latitude},#{location.longitude}"
      end)

    if already_saved? do
      socket
    else
      place_with_weather =
        location
        |> Places.create_place_from_search_result()
        |> Weather.get_weather()

      if socket.assigns[:current_user] do
        # TODO: see if place already exists in DB
        # if not, then save place in DB
        # then add place to user's saved places

        IO.puts("save place in DB (if not already) and add to user's saved places")
      end

      Component.assign(socket,
        main_weather: prepare_main_weather(place_with_weather),
        saved_places: %AsyncResult{
          async_saved_places
          | result: [place_with_weather | saved_places_list]
        }
      )
    end
  end

  def delete_place_and_maybe_change_main_weather(location_id, socket) do
    async_saved_places = socket.assigns.saved_places
    saved_places_list = async_saved_places.result

    updated_saved_places_list =
      Enum.reject(saved_places_list, fn p -> p.location_id == location_id end)

    if socket.assigns[:current_user] do
      # TODO: remove place from user's saved places
      # TODO: if place has no users, then remove place in DB
      IO.puts(
        "remove place from user's saved places, and if there's place has no users, then remove place in DB"
      )
    end

    Component.assign(socket,
      #  main_weather: Utils.prepare_main_weather(place),
      saved_places: %AsyncResult{async_saved_places | result: updated_saved_places_list}
    )
  end
end
