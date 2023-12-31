defmodule Himmel.Places do
  alias Himmel.Places.{Place, Coordinates}

  @moduledoc """
  The Places context is responsible for managing the user's saved places and the current location.
  """

  def create_place_from_search_result(%{
        name: name,
        latitude: latitude,
        longitude: longitude
      }) do
    %Place{
      name: name,
      coordinates: %Coordinates{
        latitude: latitude,
        longitude: longitude
      },
      location_id: "#{latitude},#{longitude}",
      weather: %{}
    }
  end

  @doc "Create a %Place{} from user's IP details. Defaults to a static location when in a dev environment, otherwise uses the user's IP info in the details argument"
  def create_place_from_ip_details(details) do
    current_location = Application.get_env(:himmel, :current_location)

    {name, coordinates} =
      case current_location do
        nil ->
          [latitude, longitude] = details["loc"] |> String.split(",")
          {details["city"], %Coordinates{latitude: latitude, longitude: longitude}}

        {name, coordinates} ->
          {name, %Coordinates{latitude: coordinates.latitude, longitude: coordinates.longitude}}
      end

    %Place{
      name: name,
      coordinates: coordinates,
      location_id: "#{coordinates.latitude},#{coordinates.longitude}"
    }
  end
end
