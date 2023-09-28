defmodule Himmel.Services.Geocoding do
  import Himmel.Utils

  @doc "Gets a list of search results for a place"
  def search_places(place) when is_binary(place) do
    name = String.split(place) |> Enum.join("+")

    ("https://geocoding-api.open-meteo.com/v1/search?count=20&language=en&format=json&" <>
       "name=#{name}")
    |> json_request()
    |> Map.get("results")
    |> Enum.map(fn result ->
      %{
        name: result["name"],
        region: result["admin1"],
        country: result["country"],
        latitude: result["latitude"],
        longitude: result["longitude"],
        id: result["id"]
      }
    end)
  end
end
