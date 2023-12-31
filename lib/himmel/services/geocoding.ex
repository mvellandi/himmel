defmodule Himmel.Services.Geocoding do
  require Logger
  import Himmel.Utils

  @doc "Gets a list of search results for a place"
  def search_places(place) when is_binary(place) do
    name = String.split(place) |> Enum.join("+")

    # {:ok, response} =
    response =
      web_request(
        "https://geocoding-api.open-meteo.com/v1/search?count=20&language=en&format=json&" <>
          "name=#{name}"
      )

    case response do
      {:ok, response} ->
        body = Jason.decode!(response.body)

        case Map.get(body, "results") do
          nil ->
            []

          results ->
            Enum.map(results, fn result ->
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

      {:error, info} ->
        Logger.error(inspect(info, label: "Web request error"))
    end
  end
end
