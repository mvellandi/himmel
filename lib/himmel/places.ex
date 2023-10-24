defmodule Himmel.Places do
  alias Himmel.Repo
  alias Himmel.Accounts.User
  alias Himmel.Places.{Place, Coordinates}

  @moduledoc """
  The Places context is responsible for managing the user's saved places and the current location.
  """

  @doc "Add a place to the user's saved places."
  def save_place_to_user(user, attrs) do
    %User{} =
      user
      |> User.places_changeset(attrs)
      |> Repo.update()
  end

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
          {details.city, %Coordinates{latitude: details.latitude, longitude: details.longitude}}

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
