defmodule Himmel.Services.Weather do
  alias Himmel.Utils
  alias Himmel.Weather.Descriptions
  alias Himmel.Places.{PlaceView, Coordinates}

  @weather_keys [
    :current,
    :daily,
    :hourly,
    :last_updated
  ]

  def get_raw_weather_hamburg() do
    ("https://api.open-meteo.com/v1/forecast?hourly=temperature_2m,weathercode&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,weathercode&current_weather=true&forecast_days=10&timezone=auto&" <>
       "latitude=53.5488&" <>
       "longitude=9.9872")
    |> Utils.json_request()
  end

  def get_weather(
        %PlaceView{
          coordinates: %Coordinates{latitude: latitude, longitude: longitude}
        } = place
      ) do
    weather =
      ("https://api.open-meteo.com/v1/forecast?hourly=temperature_2m,weathercode&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,weathercode&current_weather=true&forecast_days=10&timezone=auto&" <>
         "latitude=#{latitude}&" <>
         "longitude=#{longitude}")
      |> Utils.json_request()
      |> prepare_current_weather()
      |> prepare_daily_weather()
      |> prepare_hourly_weather(36)
      |> Map.take(@weather_keys)

    Map.put(place, :weather, weather)
  end

  defp prepare_current_weather(%{"current_weather" => current} = weather) do
    day_or_night = if current["is_day"] == 0, do: :night, else: :day

    updated_current_weather = %{
      temperature: round(current["temperature"]),
      description: Descriptions.get_description(current["weathercode"], day_or_night),
      day_or_night: day_or_night
    }

    Map.drop(weather, ["current_weather"])
    |> Map.put(:current, updated_current_weather)
    |> Map.put(:timestamp, Utils.meteo_datetime_to_struct(current["time"], weather))
  end

  defp prepare_daily_weather(%{"daily" => daily} = weather) do
    daily_temperature =
      Enum.zip_reduce(
        [daily["temperature_2m_min"], daily["temperature_2m_max"]],
        [],
        fn [low, high], acc ->
          [%{high: round(high), low: round(low)} | acc]
        end
      )
      |> Enum.reverse()

    daily_suntimes =
      Enum.zip_reduce([daily["sunrise"], daily["sunset"]], [], fn [sunrise, sunset], acc ->
        [
          %{
            sunrise: Utils.meteo_datetime_to_struct(sunrise, weather),
            sunset: Utils.meteo_datetime_to_struct(sunset, weather)
          }
          | acc
        ]
      end)
      |> Enum.reverse()

    daily_data =
      Enum.zip_reduce(
        [daily["time"], daily_temperature, daily_suntimes, daily["weathercode"]],
        [],
        fn [time, temperature, suntimes, weathercode], acc ->
          [
            %{
              weekday: Utils.weekday_name_from_date(time),
              date: time |> Date.from_iso8601() |> elem(1),
              temperature: temperature,
              sunrise: suntimes.sunrise,
              sunset: suntimes.sunset,
              description: Descriptions.get_description(weathercode, :day)
            }
            | acc
          ]
        end
      )
      |> Enum.reverse()
      |> List.update_at(0, &Map.put(&1, :weekday, "Today"))

    Map.drop(weather, ["daily"])
    |> Map.put(:daily, daily_data)
  end

  defp prepare_hourly_weather(%{"hourly" => hourly} = weather, hours_to_forecast) do
    timestamp = weather.timestamp

    first_3_days = Enum.take(weather.daily, 3)

    all_hourly_forecasts =
      [hourly["time"], hourly["temperature_2m"], hourly["weathercode"]]
      |> Enum.zip()
      |> Enum.map(fn {datetime, temperature, weathercode} ->
        datetime_struct = Utils.meteo_datetime_to_struct(datetime, weather)
        day_or_night = Utils.is_datetime_day_or_night?(datetime_struct, first_3_days)

        %{
          hour: Utils.meteo_datetime_to_hour(datetime),
          temperature: round(temperature),
          description: Descriptions.get_description(weathercode, day_or_night),
          datetime: datetime_struct
        }
      end)

    current_hour =
      Enum.find_index(all_hourly_forecasts, fn forecast ->
        forecast.hour == timestamp.hour
      end)

    hourly_forecasts =
      all_hourly_forecasts
      |> Enum.drop(current_hour)
      |> Enum.take(hours_to_forecast)
      |> Enum.map(fn forecast -> Map.drop(forecast, [:datetime]) end)

    Map.drop(weather, ["hourly"])
    |> Map.put(:hourly, hourly_forecasts)
  end
end
