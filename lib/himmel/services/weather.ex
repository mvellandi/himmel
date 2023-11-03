defmodule Himmel.Services.Weather do
  alias Himmel.Utils
  alias Himmel.Weather.Descriptions
  alias Himmel.Places.{Place, Coordinates}

  def get_raw_weather_hamburg() do
    response =
      Utils.web_request(
        "https://api.open-meteo.com/v1/forecast?hourly=temperature_2m,weathercode&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,weathercode&current_weather=true&forecast_days=10&timezone=auto&" <>
          "latitude=53.5488&" <>
          "longitude=9.9872"
      )

    case response do
      {:ok, response} ->
        Jason.decode!(response.body)

      {:error, reason} ->
        IO.inspect(reason, label: "Web request error")
    end
  end

  def get_weather(
        %Place{coordinates: %Coordinates{latitude: latitude, longitude: longitude}} = place
      ) do
    response =
      Utils.web_request(
        "https://api.open-meteo.com/v1/forecast?hourly=temperature_2m,weathercode&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,weathercode&current_weather=true&forecast_days=10&timezone=auto&" <>
          "latitude=#{latitude}&" <>
          "longitude=#{longitude}"
      )

    case response do
      {:ok, %Finch.Response{status: 200} = response} ->
        data = Jason.decode!(response.body)

        {_, weather_info} =
          {data, %WeatherInfo{}}
          |> prepare_current_weather()
          |> prepare_daily_weather()
          |> prepare_hourly_weather(36)

        {:ok, Map.put(place, :weather, weather_info)}

      {:ok, %Finch.Response{status: 504}} ->
        {:error, :timeout}

      {:error, %Mint.TransportError{reason: :timeout}} ->
        {:error, :timeout}
    end
  end

  defp prepare_current_weather(
         {%{"current_weather" => current} = weather_data, %WeatherInfo{} = weather_info}
       ) do
    day_or_night = if current["is_day"] == 0, do: :night, else: :day

    updated_current_weather = %WeatherInfo.Current{
      temperature: round(current["temperature"]),
      description: Descriptions.get_description(current["weathercode"], day_or_night),
      day_or_night: day_or_night
    }

    {weather_data,
     %WeatherInfo{
       weather_info
       | current: updated_current_weather,
         last_updated: Utils.meteo_datetime_to_struct(current["time"], weather_data)
     }}
  end

  defp prepare_daily_weather({%{"daily" => daily} = weather_data, %WeatherInfo{} = weather_info}) do
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
            sunrise: Utils.meteo_datetime_to_struct(sunrise, weather_data),
            sunset: Utils.meteo_datetime_to_struct(sunset, weather_data)
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
            %WeatherInfo.Day{
              date: time |> Date.from_iso8601() |> elem(1),
              description: Descriptions.get_description(weathercode, :day),
              temperature: temperature,
              sunrise: suntimes.sunrise,
              sunset: suntimes.sunset,
              weekday: Utils.weekday_name_from_date(time)
            }
            | acc
          ]
        end
      )
      |> Enum.reverse()
      |> List.update_at(0, &Map.put(&1, :weekday, "Today"))

    {weather_data, %WeatherInfo{weather_info | daily: daily_data}}
  end

  defp prepare_hourly_weather(
         {%{"hourly" => hourly} = weather_data,
          %WeatherInfo{last_updated: last_updated} = weather_info},
         hours_to_forecast
       ) do
    initial_hours_to_forecast = hours_to_forecast + 23

    first_3_days = Enum.take(weather_info.daily, 3)

    all_hourly_forecasts =
      [hourly["time"], hourly["temperature_2m"], hourly["weathercode"]]
      |> Enum.zip()
      |> Enum.take(initial_hours_to_forecast)
      |> Enum.map(fn {datetime, temperature, weathercode} ->
        datetime_struct = Utils.meteo_datetime_to_struct(datetime, weather_data)
        day_or_night = Utils.is_datetime_day_or_night?(datetime_struct, first_3_days)

        %WeatherInfo.Hour{
          hour: Utils.meteo_datetime_to_hour(datetime),
          temperature: round(temperature),
          description: Descriptions.get_description(weathercode, day_or_night),
          day_or_night: day_or_night
        }
      end)

    current_hour =
      Enum.find_index(all_hourly_forecasts, fn forecast ->
        forecast.hour == last_updated.hour
      end)

    hourly_forecasts =
      all_hourly_forecasts
      |> Enum.drop(current_hour)
      |> Enum.take(hours_to_forecast)

    {weather_data, %WeatherInfo{weather_info | hourly: hourly_forecasts}}
  end
end
