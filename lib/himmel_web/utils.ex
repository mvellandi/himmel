defmodule HimmelWeb.Utils do
  alias Himmel.Accounts
  alias Phoenix.Component
  alias Phoenix.LiveView, as: LV
  alias Phoenix.LiveView.AsyncResult
  alias Himmel.Services.{IP, Places}
  alias Himmel.Places
  alias Himmel.Places.Place
  alias Himmel.Weather

  def init_data_start(socket) do
    case get_current_location_weather(socket) do
      {:ok, weather} ->
        init_data_continue(%{data: weather}, socket)

      {:error, :timeout} ->
        IO.puts("init data start error")

        Component.assign(socket,
          screen: :error,
          error: %{
            reason: "We're having trouble reaching the weather service",
            advisory: "Please try again later"
          }
        )

      other ->
        IO.inspect(other, label: "Unexpected pattern match in init_data_start")
    end
  end

  def init_data_continue(%{data: current_location_weather}, socket) do
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
            {:ok,
             %{saved_places: Enum.map(places, fn p -> Weather.get_weather(p) |> elem(1) end)}}
          end)
      end

    _places_weather_socket =
      Component.assign(saved_places_socket,
        main_weather: main_weather,
        current_location: current_location_weather,
        screen: :main,
        search: "",
        search_results: nil
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

  def save_place_and_set_to_main_weather(location, socket) do
    current_user = socket.assigns[:current_user]
    async_saved_places = socket.assigns.saved_places
    saved_places_list = async_saved_places.result

    weather_response =
      location
      |> Places.create_place_from_search_result()
      |> Weather.get_weather()

    case weather_response do
      {:ok, new_place_with_weather} ->
        updated_saved_places = [new_place_with_weather | saved_places_list]

        if current_user do
          Accounts.update_user_places(current_user, updated_saved_places)
        end

        Component.assign(socket,
          main_weather: prepare_main_weather(new_place_with_weather),
          saved_places: %AsyncResult{async_saved_places | result: updated_saved_places},
          screen: :main,
          search: "",
          search_results: nil
        )

      {:error, %Mint.TransportError{reason: :timeout}} ->
        IO.puts("Timeout in getting weather")

        Component.assign(socket, screen: :error, error: %{reason: "Timeout in getting weather"})
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

    if current_user do
      Accounts.update_user_places(current_user, updated_saved_places)
    end

    updated_main_weather =
      if location_id == main_weather.location_id do
        {first, second} =
          Enum.split_while(saved_places_list, fn p -> p.location_id != location_id end)

        IO.inspect(Enum.map(first, fn p -> p.name end),
          label: "first"
        )

        IO.inspect(Enum.map(second, fn p -> p.name end),
          label: "second"
        )

        case {first, second} do
          # only and last
          {[], [_p | []]} -> prepare_main_weather(current_location)
          # first of many
          {[], [_p | ps]} -> List.first(ps) |> prepare_main_weather()
          # last of many
          {first, [_p | []]} -> List.last(first) |> prepare_main_weather()
          # has previous and next
          {_first, [_p | ps]} -> List.first(ps) |> prepare_main_weather()
          _ -> raise "Unexpected pattern match in delete_place_and_maybe_change_main_weather"
        end
      else
        main_weather
      end

    _places_weather_socket =
      Component.assign(socket,
        main_weather: updated_main_weather,
        saved_places: %AsyncResult{async_saved_places | result: updated_saved_places}
      )
  end
end
