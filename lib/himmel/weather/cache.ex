defmodule Himmel.Weather.Cache do
  use GenServer
  alias Himmel.Weather

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def call(place) do
    GenServer.call(__MODULE__, {:get, place})
  end

  def init(init_state) do
    {:ok, init_state}
  end

  def handle_call({:get, place}, _from, state) do
    case Map.get(state, place) do
      nil ->
        weather = Weather.get_weather_from_ip(place)
        {:reply, weather, Map.put(state, place, weather)}

      weather ->
        {:reply, weather, state}
    end
  end
end
