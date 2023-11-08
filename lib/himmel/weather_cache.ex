defmodule Himmel.Weather do
  alias Himmel.Services
  alias Himmel.Places.Place

  def get_weather(%Place{location_id: location_id} = place) do
    case Cachex.get(:weather_cache, location_id) do
      {:ok, nil} ->
        with {:ok, weather_data} <- Services.Weather.get_weather(place),
             {:ok, true} <- Cachex.put(:weather_cache, location_id, weather_data, ttl: 5000) do
          {:ok, weather_data}
        else
          {:error, false} -> {:error, :cache_put_false}
          {:error, reason} -> {:error, reason}
        end

      {:ok, weather_data} ->
        {:ok, true} = Cachex.expire(:weather_cache, location_id, 5000)
        {:ok, weather_data}
    end
  end
end
