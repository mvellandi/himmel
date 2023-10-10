defmodule Himmel.WeatherInfo do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :current, :map
    field :daily, {:array, :map}
    field :hourly, {:array, :map}
    field :last_updated, :utc_datetime
  end

  def changeset(weather_data, attrs) do
    weather_data
    |> cast(attrs, [:current, :daily, :hourly, :last_updated])
  end
end
