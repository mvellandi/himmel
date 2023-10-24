defmodule Himmel.Places.Place do
  use Ecto.Schema
  import Ecto.Changeset
  alias Himmel.Places.Coordinates

  embedded_schema do
    field :name, :string
    field :custom_name, :string
    embeds_one :coordinates, Coordinates
    field :location_id, :string
    field :weather, :map, virtual: true
  end

  def changeset(%__MODULE__{} = place, attrs) do
    place
    |> cast(attrs, [:name, :custom_name])
    |> cast_embed(:coordinates, required: true)
    |> add_location_id(attrs[:coordinates])
    |> validate_required([:name])
  end

  defp add_location_id(changeset, coordinates) do
    put_change(changeset, :location_id, "#{coordinates.latitude},#{coordinates.longitude}")
  end
end
