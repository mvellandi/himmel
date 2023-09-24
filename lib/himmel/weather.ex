defmodule Himmel.Weather do
  alias Himmel.{Places, Utils}
  alias Himmel.Weather.Descriptions

  def get_weather_from_ip(socket) do
    details =
      socket
      |> Places.get_user_ip()
      |> Places.get_ip_details()

    place = details |> Map.get("city")
    coordinates = Map.take(details, ["latitude", "longitude"])

    case Mix.env() do
      :dev -> get_weather("Hamburg")
      :prod -> get_weather(coordinates, place)
    end
  end

  def get_weather(%{latitude: latitude, longitude: longitude}, place) do
    ("https://api.open-meteo.com/v1/forecast?hourly=temperature_2m,weathercode&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,weathercode&current_weather=true&forecast_days=10&timezone=auto&" <>
       "latitude=#{latitude}&" <>
       "longitude=#{longitude}")
    |> Utils.json_request()
    |> Map.put("place", place)
    |> prepare_current_weather()
    |> prepare_daily_weather()

    # |> prepare_hourly_weather()
  end

  def get_weather(place) when is_binary(place) do
    [lat, lon] =
      case place do
        "Hamburg" -> ["53.5488", "9.9872"]
        "Brisbane" -> ["-27.4705", "153.0260"]
      end

    get_weather(%{latitude: lat, longitude: lon}, place)
  end

  def prepare_current_weather(weather) do
    current = weather["current_weather"]
    day_or_night = if current["is_day"] == 0, do: "night", else: "day"

    %{
      weather
      | "current_weather" => %{
          "temperature" => round(current["temperature"]),
          "description" => Descriptions.get_description(current["weathercode"], day_or_night),
          "day_or_night" => day_or_night
        }
    }
  end

  def prepare_daily_weather(%{"daily" => daily} = weather) do
    daily_temperature =
      Enum.zip_reduce(
        [daily["temperature_2m_min"], daily["temperature_2m_max"]],
        [],
        fn [low, high], acc ->
          [%{"high" => round(high), "low" => round(low)} | acc]
        end
      )
      |> Enum.reverse()

    daily_suntimes =
      Enum.zip_reduce([daily["sunrise"], daily["sunset"]], [], fn [sunrise, sunset], acc ->
        [
          %{
            "sunrise" => Utils.meteo_datetime_to_struct(sunrise),
            "sunset" => Utils.meteo_datetime_to_struct(sunset)
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
              "weekday" => Utils.weekday_name_from_date(time),
              "temperature" => temperature,
              "sunrise" => suntimes["sunrise"],
              "sunset" => suntimes["sunset"],
              "description" => Descriptions.get_description(weathercode, "day")
            }
            | acc
          ]
        end
      )
      |> Enum.reverse()
      |> List.update_at(0, &Map.put(&1, "weekday", "Today"))

    %{weather | "daily" => daily_data}
  end

  def prepare_hourly_weather(%{"hourly" => hourly} = weather) do
    hourly =
      weather["hourly"] |> Enum.map(fn {k, v} -> {k, Enum.take(v, 36)} end) |> Map.new()

    # hourly_data =
    #   Enum.zip_with(hourly["time"], hourly["temperature_2m"], hourly["weathercode"], fn time,
    #                                                                                     temperature,
    #                                                                                     weathercode ->
    #     %{
    #       "hour" => Utils.meteo_datetime_to_hour_string(time),
    #       "temperature" => round(temperature),
    #       "description" => Descriptions.get(weathercode)
    #     }
    #   end)

    # time = hourly["time"] |> Enum.map(&Utils.meteo_datetime_to_hour_string/1)

    # %{ weather | "hourly" => Enum.zip(list1, list2, list3)}
    # weather
  end
end
