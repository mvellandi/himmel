defmodule Himmel.Places.PlaceView do
  alias Himmel.Places.{Place, Coordinates}

  defstruct [
    :id,
    :db_id,
    :name,
    :coordinates,
    :weather,
    :last_updated
  ]

  def from_search_result(%{
        name: name,
        latitude: latitude,
        longitude: longitude
      }) do
    %__MODULE__{
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

  def from_db(place = %Place{}) do
    %__MODULE__{
      id: "#{place.coordinates.latitude},#{place.coordinates.longitude}",
      db_id: place.id,
      name: place.name,
      coordinates: place.coordinates,
      weather: %{},
      last_updated: nil
    }
  end
end
