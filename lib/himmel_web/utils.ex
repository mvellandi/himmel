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
        %User{places: saved_places, active_place_id: active_place_id},
        socket
      ) do
    current_location_weather = get_current_location_weather(socket)

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

  def app_data_init(nil, socket) do
    current_location_weather = get_current_location_weather(socket)

    main_weather = prepare_main_weather(current_location_weather)

    _socket =
      Component.assign(socket,
        main_weather: main_weather,
        current_location: current_location_weather,
        saved_places: %AsyncResult{ok?: true, result: []}
      )
  end

  defp get_current_location_weather(socket) do
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
end
