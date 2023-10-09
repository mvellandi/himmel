defmodule Himmel.Places do
  @moduledoc """
  The Places context..
  """

  alias Himmel.Places.{Place, PlaceView, Coordinates}

  def create_place_view_from_search_result(%{
        name: name,
        latitude: latitude,
        longitude: longitude
      }) do
    %PlaceView{
      id: "#{latitude},#{longitude}",
      name: name,
      coordinates: %Coordinates{
        latitude: latitude,
        longitude: longitude
      },
      weather: %{},
      last_updated: nil
    }
  end

  def create_place_view_from_place(place = %Place{}) do
    %PlaceView{
      id: "#{place.coordinates.latitude},#{place.coordinates.longitude}",
      name: place.name,
      coordinates: place.coordinates,
      weather: %{},
      last_updated: nil
    }
  end

  @doc "Create a %PlaceView{} from user's IP details. Defaults to a static location when in a dev environment, otherwise uses the user's IP info in the details argument, and returns a %PlaceView{} with the user's city as the name, and the user's coordinates as the coordinates."
  def create_place_view_from_ip_details(details) do
    my_location = Application.get_env(:himmel, :my_location)

    {name, coordinates} =
      case my_location do
        nil ->
          {details.city, %Coordinates{latitude: details.latitude, longitude: details.longitude}}

        {name, coordinates} ->
          {name, %Coordinates{latitude: coordinates.latitude, longitude: coordinates.longitude}}
      end

    %PlaceView{
      id: "#{coordinates.latitude},#{coordinates.longitude}",
      name: name,
      coordinates: coordinates,
      weather: %{},
      last_updated: nil
    }
  end
end
