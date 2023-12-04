defmodule HimmelWeb.Utils do
  alias Himmel.Accounts
  alias Phoenix.Component
  alias Phoenix.LiveView, as: LV
  alias Phoenix.LiveView.AsyncResult
  alias Himmel.Services.{IP, Places}
  alias Himmel.Places
  alias Himmel.Places.Place
  alias Himmel.PlaceTracker
  alias Himmel.Weather

  @doc """
  This function is called when the LiveView is mounted. It quick tests the weather service by first getting
  the current location weather. If ok, it continues to get the saved places and their weather. If not, it
  sets the screen to error and displays the error message.
  """
  def init_data_start(socket) do
    current_user = socket.assigns[:current_user]

    case get_current_location_weather(socket) do
      {_place, {:error, info}} ->
        IO.puts("App: init data: start error. Aborting...")

        Component.assign(socket,
          screen: :error,
          error: prepare_error_message(Map.put(info, :stage, :initial))
        )

      {place, {:ok, weather}} ->
        IO.puts("App: init data: start success. Continuing...")
        place_with_weather = %{place | weather: weather}

        # Subscribe to the current location and track user
        if current_user do
          manage_place_updates(:subscribe, place.location_id, current_user)
        end

        init_data_continue(place_with_weather, socket)
    end
  end

  @doc """
  The entire app state is set here. If a user is authenticated:
  * Their saved places and associated weather data is async retrieved and assigned.
  * The main weather is set to their last active place

  Otherwise, saved places is set to an empty list and the main weather is set to the current location weather.
  """
  def init_data_continue(current_location, socket) do
    {current_user, active_place_id, saved_places} =
      case socket.assigns.current_user do
        nil -> {nil, nil, []}
        %Accounts.User{} = user -> {user, user.active_place_id, user.places}
      end

    # If the last active place is not the current location, get the weather for it
    active_place_weather =
      if current_user && active_place_id && active_place_id !== current_location.location_id do
        active_place = Enum.find(saved_places, fn p -> p.location_id == active_place_id end)
        weather_info = Weather.get_weather(active_place_id) |> elem(1)
        %{active_place | weather: weather_info}
      else
        nil
      end

    main_weather =
      case active_place_weather do
        nil ->
          prepare_main_weather(current_location)

        _ ->
          prepare_main_weather(active_place_weather)
      end

    # Subscribe to all saved places and track user
    if current_user do
      for place <- saved_places do
        manage_place_updates(:subscribe, place.location_id, current_user)
      end
    end

    saved_places_socket =
      case saved_places do
        [] ->
          Component.assign(socket, saved_places: %AsyncResult{ok?: true, result: []})

        # We're assuming the weather service is not down if the current location weather was retrieved
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
                     weather_info = Weather.get_weather(p.location_id) |> elem(1)
                     %{p | weather: weather_info}
                   end
                 end)
             }}
          end)
      end

    _updated_socket =
      Component.assign(saved_places_socket,
        main_weather: main_weather,
        current_location: current_location,
        screen: :main,
        error: nil,
        mobile_onboarding: true,
        info: "Not your location? Tap here or on 'Places' to search",
        search: "",
        search_results: nil,
        updates: []
      )
  end

  @doc """
  Gets the user's current location weather based on their IP address.
  """
  @spec get_current_location_weather(LV.t()) ::
          {Place.t(), {:ok, WeatherInfo.t()}} | {Place.t(), {:error, any()}}
  def get_current_location_weather(socket) do
    place =
      socket
      |> IP.get_user_ip()
      |> IP.get_ip_details()
      |> Places.create_place_from_ip_details()

    weather_info = Weather.get_weather(place.location_id)
    {place, weather_info}
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

    new_place = Places.create_place_from_search_result(location)
    weather_info = Weather.get_weather(new_place.location_id)

    case weather_info do
      {:ok, weather_info = %WeatherInfo{}} ->
        new_place_with_weather = %{new_place | weather: weather_info}
        updated_saved_places = [new_place_with_weather | saved_places_list]

        updated_user =
          if current_user do
            current_user
            |> Accounts.update_user_places(updated_saved_places)
            |> Accounts.update_user_active_place(new_place.location_id)
          else
            nil
          end

        # Subscribe to the new place and track user
        if updated_user do
          manage_place_updates(:subscribe, new_place.location_id, updated_user)
        end

        Component.assign(socket,
          main_weather: prepare_main_weather(new_place_with_weather),
          saved_places: %AsyncResult{async_saved_places | result: updated_saved_places},
          screen: :main,
          search: "",
          search_results: nil,
          updated_user: updated_user
        )

      {:error, info} ->
        Component.assign(socket,
          screen: :error,
          error: prepare_error_message(%{info | stage: :manage})
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

    # Unsubscribe from the deleted place and untrack user
    if updated_user do
      manage_place_updates(:unsubscribe, location_id, updated_user)
    end

    _updated_socket =
      Component.assign(socket,
        main_weather: updated_main_weather,
        saved_places: %AsyncResult{async_saved_places | result: updated_saved_places},
        current_user: updated_user
      )
  end

  def prepare_error_message(%{type: type, stage: stage}) do
    case {type, stage} do
      {:timeout, :update} ->
        %{
          stage: stage,
          reason: "The weather service isn't updating one or more places",
          advisory: "We'll try again later"
        }

      {:timeout, stage} when stage in [:initial, :manage] ->
        %{
          stage: stage,
          reason: "We're having trouble reaching the weather service",
          advisory: "Please try again later"
        }

      _ ->
        %{
          stage: stage,
          reason: "Hmmm, we're having technical difficulties right now",
          advisory: "Please try again later"
        }
    end
  end

  def process_all_place_updates(updates, socket) do
    async_saved_places = socket.assigns.saved_places
    saved_places_list = async_saved_places.result
    current_location = socket.assigns.current_location

    process_current_location = fn socket, current_location, updates ->
      case process_one_place_update(current_location, updates) do
        updated_current_location = %Place{} ->
          Component.assign(socket,
            current_location: updated_current_location,
            main_weather: prepare_main_weather(updated_current_location)
          )

        %{status: :error} = error ->
          Component.assign(socket, error: prepare_error_message(error))
      end
    end

    process_saved_places = fn socket, saved_places_list, updates ->
      {errors, updated_saved_places_list} =
        Enum.reduce(saved_places_list, {[], []}, fn place, {errors, processed_places} ->
          case process_one_place_update(place, updates) do
            updated_place = %Place{} -> {errors, [updated_place | processed_places]}
            %{status: :error} = error -> {[error | errors], [place | processed_places]}
          end
        end)

      updated_errors = if errors == [], do: nil, else: prepare_error_message(hd(errors))

      Component.assign(socket,
        errors: updated_errors,
        saved_places: %AsyncResult{async_saved_places | result: updated_saved_places_list}
      )
    end

    _updated_socket =
      socket
      |> process_current_location.(current_location, updates)
      |> process_saved_places.(saved_places_list, updates)
  end

  def process_one_place_update(place, all_updates) do
    update =
      Enum.find(all_updates, fn u -> u.location_id == place.location_id end)

    case update do
      # implies either missing subscription for place updates (never was, or was removed),
      # or 'all_updates' is incomplete from either the caller (handle_info callback) or the scheduler
      nil ->
        place

      %{status: :error} ->
        update

      %{status: :ok} ->
        %Place{place | weather: update.weather}
    end
  end

  def manage_place_updates(action, location_id, user) do
    channel = "location:#{location_id}"

    case action do
      :subscribe ->
        Phoenix.PubSub.subscribe(Himmel.PubSub, channel)
        Phoenix.Tracker.track(PlaceTracker, self(), channel, user.id, %{name: user.email})

      :unsubscribe ->
        Phoenix.PubSub.unsubscribe(Himmel.PubSub, channel)
        Phoenix.Tracker.untrack(PlaceTracker, self(), channel, user.id)
    end
  end

  def time_now_to_string() do
    DateTime.now!("Etc/UTC")
    |> DateTime.shift_zone!("Europe/Paris")
    |> DateTime.to_time()
    |> Time.to_string()
    |> String.slice(0, 5)
  end

  # Total places and current location
  def total_places(socket) do
    (socket.assigns.saved_places.result |> length()) + 1
  end
end
