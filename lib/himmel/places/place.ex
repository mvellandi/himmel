defmodule Himmel.Places.Place do
  use Ecto.Schema
  alias Himmel.Accounts.User
  import Ecto.Changeset

  schema "places" do
    field :name, :string
    field :latitude, :float
    field :longitude, :float

    many_to_many :user, User, join_through: "places_users"

    timestamps()
  end

  @doc false
  def changeset(place, attrs) do
    place
    |> cast(attrs, [:name, :latitude, :longitude])
    |> validate_required([:name, :latitude, :longitude])
  end
end
