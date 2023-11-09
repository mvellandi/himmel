defmodule HimmelWeb.Utils do
  alias Himmel.Accounts
  alias Phoenix.Component
  alias Phoenix.LiveView, as: LV
  alias Phoenix.LiveView.AsyncResult
  alias Himmel.Services.{IP, Places}
  alias Himmel.Places
  alias Himmel.Places.Place
  alias Himmel.Weather

  @doc """
  This function is called when the LiveView is mounted. It quick tests the weather service by first getting
  the current location weather. If ok, it continues to get the saved places and their weather. If not, it
  sets the screen to error and displays the error message.
  """
  def init_data_start(socket) do
    case get_current_location_weather(socket) do
      {:error, reason} ->
        IO.puts("init data start error")

        Component.assign(socket,
          screen: :error,
          error: prepare_error_message(reason)
        )

      {:ok, weather} ->
        Phoenix.PubSub.subscribe(
          Himmel.PubSub,
          "weather_updates:#{weather.location_id}"
        )

        init_data_continue(%{current: weather}, socket)
    end
  end

  @doc """
  The entire app state is set here. If a user is authenticated:
  * Their saved places and associated weather data is async retrieved and assigned.
  * The main weather is set to their last active place

  Otherwise, saved places is set to an empty list and the main weather is set to the current location weather.
  """
  def init_data_continue(%{current: current_location_weather}, socket) do
    {current_user, active_place_id, saved_places} =
      case socket.assigns.current_user do
        nil -> {nil, nil, []}
        %Accounts.User{} = user -> {user, user.active_place_id, user.places}
      end

    active_place_weather =
      if current_user && active_place_id do
        Enum.find(saved_places, fn p -> p.location_id == active_place_id end)
        |> Weather.get_weather()
        |> elem(1)
      else
        nil
      end

    main_weather =
      case active_place_weather do
        nil ->
          prepare_main_weather(current_location_weather)

        _ ->
          prepare_main_weather(active_place_weather)
      end

    # Subscribe to all saved places
    for place <- saved_places do
      IO.inspect(place.location_id, label: "Subscribing to weather_updates")
      Phoenix.PubSub.subscribe(Himmel.PubSub, "weather_updates:#{place.location_id}")
    end

    saved_places_socket =
      case saved_places do
        [] ->
          Component.assign(socket, saved_places: %AsyncResult{ok?: true, result: []})

        places when is_list(places) ->
          # if there's an active place, we don't need to get the weather for it again
          LV.assign_async(socket, :saved_places, fn ->
            {:ok,
             %{
               saved_places:
                 Enum.map(places, fn p ->
                   if active_place_weather && p.location_id == active_place_weather.location_id do
                     active_place_weather
                   else
                     Weather.get_weather(p) |> elem(1)
                   end
                 end)
             }}
          end)
      end

    _places_weather_socket =
      Component.assign(saved_places_socket,
        main_weather: main_weather,
        current_location: current_location_weather,
        screen: :main,
        search: "",
        search_results: nil
      )
  end

  @doc """
  Gets the user's current location weather based on their IP address.
  """
  def get_current_location_weather(socket) do
    socket
    |> IP.get_user_ip()
    |> IP.get_ip_details()
    |> Places.create_place_from_ip_details()
    |> Weather.get_weather()
  end

  @doc """
  Takes a Place struct and prepares it for the main weather display.
  """
  def prepare_main_weather(%Place{
        name: name,
        location_id: location_id,
        weather: %{current: current, daily: daily, hourly: hourly}
      }) do
    todays_temp_range = List.first(daily) |> Map.get(:temperature)

    %{
      name: name,
      location_id: location_id,
      temperature: current.temperature,
      description_text: current.description.text,
      high: todays_temp_range.high,
      low: todays_temp_range.low,
      hours: hourly,
      days: daily
    }
  end

  def save_place_and_set_to_main_weather(location, socket) do
    current_user = socket.assigns[:current_user]
    async_saved_places = socket.assigns.saved_places
    saved_places_list = async_saved_places.result

    weather_response =
      location
      |> Places.create_place_from_search_result()
      |> Weather.get_weather()

    case weather_response do
      {:ok, new_place_with_weather} ->
        updated_saved_places = [new_place_with_weather | saved_places_list]

        updated_user =
          if current_user do
            current_user
            |> Accounts.update_user_places(updated_saved_places)
            |> Accounts.update_user_active_place(new_place_with_weather.location_id)
          else
            nil
          end

        Component.assign(socket,
          main_weather: prepare_main_weather(new_place_with_weather),
          saved_places: %AsyncResult{async_saved_places | result: updated_saved_places},
          screen: :main,
          search: "",
          search_results: nil,
          updated_user: updated_user
        )

      {:error, reason} ->
        Component.assign(socket,
          screen: :error,
          error: prepare_error_message(reason)
        )
    end
  end

  def delete_place_and_maybe_change_main_weather(location_id, socket) do
    current_user = socket.assigns[:current_user]
    async_saved_places = socket.assigns.saved_places
    saved_places_list = async_saved_places.result
    main_weather = socket.assigns.main_weather
    current_location = socket.assigns.current_location

    updated_saved_places =
      Enum.reject(saved_places_list, fn p -> p.location_id == location_id end)

    IO.inspect(Enum.map(updated_saved_places, fn p -> p.name end),
      label: "updated_saved_places BEFORE DB UPDATE"
    )

    updated_main_weather =
      if location_id == main_weather.location_id do
        {first, second} =
          Enum.split_while(saved_places_list, fn p -> p.location_id != location_id end)

        case {first, second} do
          # only and last
          {[], [_p | []]} -> prepare_main_weather(current_location)
          # first of many
          {[], [_p | ps]} -> List.first(ps) |> prepare_main_weather()
          # last of many
          {first, [_p | []]} -> List.last(first) |> prepare_main_weather()
          # has previous and next
          {_first, [_p | ps]} -> List.first(ps) |> prepare_main_weather()
          _ -> raise "Unexpected pattern match in delete_place_and_maybe_change_main_weather"
        end
      else
        main_weather
      end

    updated_user =
      if current_user do
        current_user
        |> Accounts.update_user_places(updated_saved_places)
        |> Accounts.update_user_active_place(updated_main_weather.location_id)
      else
        nil
      end

    _updated_socket =
      Component.assign(socket,
        main_weather: updated_main_weather,
        saved_places: %AsyncResult{async_saved_places | result: updated_saved_places},
        current_user: updated_user
      )
  end

  def prepare_error_message(type) do
    case type do
      :timeout ->
        %{
          reason: "We're having trouble reaching the weather service",
          advisory: "Please try again later"
        }

      _ ->
        %{
          reason: "Hmmm, we're having technical difficulties right now",
          advisory: "Please try again later"
        }
    end
  end

  def update_saved_places_weather(%{location_id: location_id, weather: weather}, socket) do
    async_saved_places = socket.assigns.saved_places
    saved_places_list = async_saved_places.result

    updated_saved_places =
      Enum.map(saved_places_list, fn p ->
        if p.location_id == location_id do
          %Place{p | weather: weather}
        else
          p
        end
      end)

    Component.assign(socket,
      saved_places: %AsyncResult{async_saved_places | result: updated_saved_places}
    )
  end
end
