defmodule Himmel.Weather.Service do
  use GenServer
  alias Himmel.Weather

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_weather(%{latitude: _, longitude: _} = coords, place_name) do
    GenServer.call(__MODULE__, {:get, coords, place_name})
  end

  def init(init_state) do
    {:ok, init_state}
  end

  def handle_call({:get, coords, place_name}, _from, state) do
    case Map.get(state, place_name) do
      nil ->
        weather = Weather.get_weather(coords, place_name)
        {:reply, weather, Map.put(state, place_name, weather)}

      weather ->
        {:reply, weather, state}
    end
  end
end
