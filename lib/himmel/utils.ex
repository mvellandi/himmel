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

  def meteo_datetime_to_struct(datetime) when is_binary(datetime) do
    (datetime <> ":00Z")
    |> DateTime.from_iso8601()
    |> elem(1)
  end

  def meteo_datetime_to_hour_string(datetime) when is_binary(datetime) do
    hour = meteo_datetime_to_struct(datetime) |> DateTime.to_time() |> Map.get(:hour)

    case hour < 10 do
      true -> "0" <> to_string(hour)
      false -> to_string(hour)
    end
  end

  def meteo_datetime_night_or_day(%{datetime: datetime, weather: weather})
      when is_binary(datetime) do
    nil
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
end
