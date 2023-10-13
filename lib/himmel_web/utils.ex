defmodule HimmelWeb.Utils do
  alias Himmel.Accounts.User
  alias Himmel.Services.{IP, Places}
  alias Himmel.Places
  alias Himmel.Places.Place
  alias Himmel.Weather

  def app_data_init(%User{} = current_user, socket) do
    current_location_weather = get_current_location_weather(socket)

    active_place =
      Enum.find(current_user.places, fn p -> p.location_id == current_user.active_place_id end) ||
        nil

    main_weather =
      case active_place do
        nil ->
          prepare_main_weather(current_location_weather)

        %Place{} = active_place ->
          Weather.get_weather(active_place)
          |> prepare_main_weather()
      end

    %{
      current_location: current_location_weather,
      main_weather: main_weather,
      saved_places: current_user.places
    }
  end

  def app_data_init(nil, socket) do
    current_location_weather = get_current_location_weather(socket)

    main_weather = prepare_main_weather(current_location_weather)

    %{
      current_location: current_location_weather,
      main_weather: main_weather,
      saved_places: []
    }
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
