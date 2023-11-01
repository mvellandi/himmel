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

    # TODO: Handle if the weather service is not responding
    # %Mint.TransportError{reason: :timeout} of type Mint.TransportError (a struct)

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
        location_id: location_id,
        weather: %{current: current, daily: daily, hourly: hourly}
      }) do
    todays_temp_range = List.first(daily) |> Map.get(:temperature)

    %{
      name: name,
      location_id: location_id,
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
        Accounts.update_user_places(current_user, updated_saved_places)
      end

      Component.assign(socket,
        main_weather: prepare_main_weather(new_place_with_weather),
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
    main_weather = socket.assigns.main_weather
    current_location = socket.assigns.current_location

    updated_saved_places =
      Enum.reject(saved_places_list, fn p -> p.location_id == location_id end)

    IO.inspect(Enum.map(updated_saved_places, fn p -> p.name end),
      label: "updated_saved_places BEFORE DB UPDATE"
    )

    updated_user =
      if current_user do
        Accounts.update_user_places(current_user, updated_saved_places)
      else
        nil
      end

    # updated_main_weather =
    #   cond do
    #     location_id == main_weather.location_id ->
    #       {first, second} =
    #         Enum.split_while(saved_places_list, fn p -> p.location_id != location_id end)

    #       new_main_place =
    #         case {first, second} do
    #           {[], []} -> nil
    #           {[_p], []} -> nil
    #           {first, [_p | []]} -> List.last(first)
    #           {_first, [_p | ps]} -> List.first(ps)
    #           _ -> "unexpected"
    #         end

    #       if new_main_place === "unexpected" do
    #         raise "Unexpected pattern match in delete_place_and_maybe_change_main_weather"
    #       else
    #         prepare_main_weather(new_main_place)
    #       end

    #     location_id !== main_weather.location_id && updated_saved_places !== [] ->
    #       main_weather

    #     updated_saved_places === [] ->
    #       prepare_main_weather(current_location)
    #   end

    # IO.inspect(current_user, label: "current_user")
    # IO.inspect(updated_user, label: "updated_user")

    _places_weather_socket =
      Component.assign(socket,
        # current_user: updated_user,
        # main_weather: updated_main_weather,
        saved_places: %AsyncResult{async_saved_places | result: updated_saved_places}
      )
  end
end
