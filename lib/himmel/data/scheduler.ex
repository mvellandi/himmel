defmodule Himmel.Data.Scheduler do
  alias Himmel.Services

  use Quantum, otp_app: :himmel

  def update_all_places_weather() do
    # Fetch all location_ids from the cache.
    {:ok, all_locations} = Cachex.keys(:weather_cache)

    if length(all_locations) > 0 do
      [first_id | rest_ids] = all_locations

      case update_place_weather(first_id) do
        :ok ->
          IO.puts("Scheduler: first location success. Continuing...")
          process_places(rest_ids)

        {:error, info} ->
          # Let all clients know the weather service is down and abort further updates
          IO.puts("Scheduler: first location error. Aborting...")
          Phoenix.PubSub.broadcast(Himmel.PubSub, "weather_service", {:weather_service, info})

        :place_dropped ->
          IO.puts("Scheduler: first location dropped. Continuing...")
          process_places(rest_ids)
      end
    end
  end

  def update_place_weather(location_id, options \\ []) do
    retries = Keyword.get(options, :retries, 3)

    # Check for subscribers
    subscribers = Phoenix.Tracker.list(Himmel.PlaceTracker, "location:#{location_id}")
    IO.puts("Scheduler: #{length(subscribers)} subscribers for #{location_id}")

    # If there are subscribers, fetch fresh data, update the cache, and publish the updates
    response =
      if length(subscribers) > 0 do
        Services.Weather.get_weather(location_id)
      else
        nil
      end

    case response do
      {:ok, weather = %WeatherInfo{}} ->
        {:ok, true} = Cachex.put(:weather_cache, location_id, weather)
        info = %{status: :ok, location_id: location_id, weather: weather}
        publish_update(location_id, info)
        :ok

      {:error, _} when retries > 0 ->
        __MODULE__.update_place_weather(location_id, retries: retries - 1)

      {:error, info} ->
        updated_info =
          %{status: :error, location_id: location_id, stage: :update} |> Map.merge(info)

        publish_update(location_id, updated_info)
        {:error, updated_info}

      nil ->
        {:ok, true} = Cachex.del(:weather_cache, location_id)
        :place_dropped
    end
  end

  def process_places(location_ids) do
    processor = fn location_id ->
      __MODULE__.update_place_weather(location_id)
    end

    # Process the jobs
    Task.async_stream(location_ids, processor, max_concurrency: 10)
    |> Enum.each(fn {:ok, _} -> :ok end)

    IO.puts("Scheduler: All locations processed and published")
  end

  defp publish_update(channel, info) do
    Phoenix.PubSub.broadcast(Himmel.PubSub, "location:#{channel}", {:place_weather_update, info})
  end
end
