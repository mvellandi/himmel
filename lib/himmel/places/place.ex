defmodule Himmel.Places.Place do
  use Ecto.Schema
  import Ecto.Changeset
  alias Himmel.Accounts.User
  alias Himmel.Places.Coordinates

  schema "places" do
    field :name, :string
    embeds_one :coordinates, Coordinates
    field :weather, :map, default: %{}

    many_to_many :user, User, join_through: "places_users"

    timestamps()
  end

  @doc false
  def changeset(place, attrs) do
    place
    |> cast(attrs, [:name, :coordinates])
    |> validate_required([:name, :coordinates])
  end
end
