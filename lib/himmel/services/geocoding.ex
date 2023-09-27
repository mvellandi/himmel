defmodule Himmel.Services.Geocoding do
  import Himmel.Utils

  @doc "Gets a list of search results for a place"
  def find_place(place) when is_binary(place) do
    name = String.split(place) |> Enum.join("+")

    ("https://geocoding-api.open-meteo.com/v1/search?count=20&language=en&format=json&" <>
       "name=#{name}")
    |> json_request()
  end
end
