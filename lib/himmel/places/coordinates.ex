defmodule Himmel.Places.Coordinates do
  use Ecto.Schema

  embedded_schema do
    field :latitude, :float
    field :longitude, :float
  end
end
