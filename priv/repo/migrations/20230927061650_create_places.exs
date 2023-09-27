defmodule Himmel.Repo.Migrations.CreatePlaces do
  use Ecto.Migration

  def change do
    create table(:places) do
      add :name, :string
      add :latitude, :float
      add :longitude, :float

      timestamps()
    end
  end
end
