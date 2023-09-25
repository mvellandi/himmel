defmodule Himmel.Utils do
  @moduledoc false

  def json_request(url) do
    {:ok, response} = Finch.build(:get, url) |> Finch.request(Himmel.Finch)
    json_string = response.body
    Jason.decode!(json_string)
  end

  def celsius_to_fahrenheit(celsius) do
    celsius * 1.8 + 32
  end

  def fahrenheit_to_celsius(fahrenheit) do
    (fahrenheit - 32) / 1.8
  end

  def meteo_datetime_to_struct(datetime, weather) when is_binary(datetime) do
    init_datetime =
      (datetime <> ":00Z")
      |> DateTime.from_iso8601()
      |> elem(1)

    [date, time] = [DateTime.to_date(init_datetime), DateTime.to_time(init_datetime)]

    DateTime.new(date, time, weather["timezone"]) |> elem(1)
  end

  def meteo_datetime_to_hour_string(datetime) when is_binary(datetime) do
    String.split(datetime, "T")
    |> List.last()
    |> String.split(":")
    |> List.first()
  end

  def weekday_name_from_date(time) when is_binary(time) do
    day_number =
      time
      |> Date.from_iso8601()
      |> elem(1)
      |> Date.day_of_week()

    case day_number do
      1 -> "Mon"
      2 -> "Tue"
      3 -> "Wed"
      4 -> "Thu"
      5 -> "Fri"
      6 -> "Sat"
      7 -> "Sun"
    end
  end

  def find_matching_day_from_daily_weather_list(list, date) do
    is_match_date? = fn query_date, item_date -> query_date == item_date end

    Enum.find(list, fn weather_day ->
      DateTime.to_date(date)
      |> is_match_date?.(weather_day["date"])
    end)
  end

  def is_day_or_night?(datetime, sunrise, sunset) do
    case datetime < sunrise || datetime > sunset do
      true -> "night"
      false -> "day"
    end
  end

  def is_datetime_day_or_night?(datetime, daily_weather_list) do
    matching_day =
      daily_weather_list
      |> find_matching_day_from_daily_weather_list(datetime)

    is_day_or_night?(datetime, matching_day["sunrise"], matching_day["sunset"])
  end
end
