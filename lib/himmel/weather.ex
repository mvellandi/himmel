defmodule Himmel.Weather do
  alias Himmel.Services

  @type error_info :: %{type: atom(), stage: atom()}

  @spec get_weather(String.t()) :: {:ok, WeatherInfo.t()} | {:error, error_info() | any()}
  def get_weather(location_id) do
    case Cachex.get(:weather_cache, location_id) do
      {:ok, nil} ->
        with {:ok, weather = %WeatherInfo{}} <-
               Services.Weather.get_weather(location_id),
             {:ok, true} <-
               Cachex.put(:weather_cache, location_id, weather, ttl: 1_800_000) do
          {:ok, weather}
        else
          {:error, false} -> {:error, %{type: :cache, stage: :cache_put}}
          {:error, info} -> {:error, info}
        end

      {:ok, weather = %WeatherInfo{}} ->
        {:ok, true} = Cachex.expire(:weather_cache, location_id, 1_800_000)
        {:ok, weather}
    end
  end
end
