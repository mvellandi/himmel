defmodule Himmel.Scheduler do
  alias Himmel.Places.{Place, Coordinates}

  use Quantum, otp_app: :himmel

  def update_data_start() do
    IO.puts("periodic weather update")

    # Fetch all location_ids from the cache.
    {:ok, [first_id | rest_ids]} = Cachex.keys(:weather_cache)

    # Test the connection to the weather API. If it fails, we don't want to continue.
    case test_weather_service(first_id) do
      {:error, _info} ->
        IO.puts("periodic weather update error")

        Phoenix.PubSub.broadcast(MyApp.PubSub, "weather_service", %{
          error: %{type: :timeout, stage: :update}
        })

      {:ok, weather_data} ->
        IO.puts("periodic weather update success")
        Phoenix.PubSub.broadcast(MyApp.PubSub, first_id, weather_data)
        update_data_continue(rest_ids)
    end
  end

  def update_data_continue(location_ids) do
    # Create a job queue
    queue = Enum.into(location_ids, :queue.new())

    # Define a function to process each job
    processor = fn location_id ->
      # Check for subscribers
      subscribers = Phoenix.Tracker.list(MyApp.PubSub, location_id)
      [latitude, longitude] = Himmel.Utils.location_id_to_coordinates(location_id)

      # If there are subscribers, fetch fresh data, update the cache, and publish the updates
      if length(subscribers) > 0 do
        # Fetch fresh data
        response =
          Himmel.Services.Weather.get_weather(%Place{
            coordinates: %Coordinates{latitude: latitude, longitude: longitude}
          })

        case response do
          {:ok, weather_data} ->
            # Update the cache
            # TODO: Fix this. Are we putting the whole place or just the weather data for that location?
            # {:ok, true} = Cachex.put(:weather_cache, location_id, weather_data)

            # Publish the updates
            Phoenix.PubSub.broadcast(Himmel.PubSub, location_id, weather_data)

          {:error, info} ->
            # TODO: Okay, maybe this is just a single connection error. We don't want to stop the whole process. So maybe we should put the location_id back in the queue?
            # But what if multiple location_ids have errors? At a certain point, we should stop or kill the process if there's no data coming in. Maybe we should have a counter for errors and if it reaches a certain number, we stop the process and send a specific message to clients via PubSub. The client handler can then conditionally display a hazard icon or something to indicate that the weather data is stale, so that way clients can still use the app, but they know that the data is stale.
            IO.inspect(info, label: "Weather update error")
            new_data = %{}
        end
      end
    end

    # Process the jobs
    Task.async_stream(queue, processor, max_concurrency: 10)
    |> Enum.each(fn {:ok, _} -> :ok end)
  end

  def test() do
    IO.puts("test")

    # Phoenix.PubSub.broadcast(Himmel.PubSub, "weather_service", %{error: %{type: :timeout, stage: :update}})
  end

  # Test the connection to the weather API. If it fails, we don't want to continue.
  def test_weather_service(location_id) do
    IO.puts("test weather service with sample data")
    [latitude, longitude] = Himmel.Utils.location_id_to_coordinates(location_id)

    Himmel.Services.Weather.get_weather(%Place{
      coordinates: %Coordinates{latitude: latitude, longitude: longitude}
    })
  end
end
