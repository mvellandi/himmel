defmodule Himmel.Weather2 do
  use GenServer
  alias Himmel.Services
  alias Himmel.Places.Place

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_weather(%Place{} = place) do
    GenServer.call(__MODULE__, {:get, place})
  end

  def init(init_state) do
    Process.send_after(self(), :update_weather_cache, 1000)
    {:ok, init_state}
  end

  def handle_info(:update_weather_cache, state) do
    # Process.send_after(self(), :update_weather_cache, 1000)
    # Enumerate through saved places
    # for each place, get the weather api data
    # IF the weather weather api data has changed
    # broadcast to the pub sub topic for that place
    # save the updated weather in the cache
    # HimmelWeb.Endpoint.broadcast("places", "place_updated", updated_weather)

    {:noreply, state}
  end

  def handle_call({:get, %Place{location_id: location_id} = place}, _from, state) do
    case Map.get(state, location_id) do
      nil ->
        case Services.Weather.get_weather(place) do
          {:ok, weather} ->
            new_state = Map.put(state, location_id, weather)
            {:reply, {:ok, weather}, new_state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      cached_weather ->
        # {:reply, {:error, :timeout}, state}
        {:reply, {:ok, cached_weather}, state}
    end
  end

  # defp clean_weather_cache(state) do
  # ??? I like this generated idea, but I don't think it fits for this function.
  # Enumerate through saved places
  # for each place, get the weather api data
  # IF the weather weather api data has changed
  # broadcast to the pub sub topic for that place
  # save the updated weather in the cache
  # HimmelWeb.Endpoint.broadcast("places", "place_updated", updated_weather)
  # end
end
