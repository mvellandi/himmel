defmodule HimmelWeb.AppLive do
  use HimmelWeb, :live_view
  alias Himmel.Weather
  alias Himmel.Places
  alias Himmel.Places.Place
  alias HimmelWeb.Utils
  alias HimmelWeb.{MainLive, PlacesLive, SettingsLive}

  @doc """
  MAIN shows data for the current PLACE. If there's a user session or authenticated user's places and history,
  the last loaded place is shown. Otherwise, the user's IP is used to get the current place and weather.
  """
  def mount(_params, _session, socket) do
    # if connected?(socket) do
    #   HimmelWeb.Endpoint.subscribe("places")
    # end
    current_user = socket.assigns.current_user

    user_location_weather =
      Utils.get_user_ip_details_from_socket(socket)
      |> Places.create_place_from_ip_details()
      |> Weather.get_weather()

    {saved_places, main_weather} =
      if current_user do
        # TODO: get user's last loaded place instead of IP, and have the Weather genserver get the weather for that place, user's location, and user's other saved places, otherwise get current weather from user's IP
        # IO.inspect(current_user, label: "current user")
        saved_places = current_user.places

        _last_active_place =
          case current_user.active_place_id do
            nil ->
              user_location_weather

            active_place_id ->
              saved_places
              |> Enum.filter(fn p -> p.id == active_place_id end)
          end

        # TODO: get weather for last active place
        # weather_for_last_active_place = Weather.get_weather(last_active_place) ??
        {saved_places, prepare_main_weather(user_location_weather)}
      else
        {nil, prepare_main_weather(user_location_weather)}
      end

    # TODO: if the user has a last loaded place, we still need to get the weather for my_location and assign it accordingly, so it shows up in the places list
    # my_location_weather = # get weather for my_location
    # IO.inspect(user_location_weather, label: "user_location_weather")

    {:ok,
     assign(socket,
       main_weather: main_weather,
       my_location: user_location_weather,
       saved_places: saved_places,
       screen: :main
     )}
  end

  def render(assigns) do
    ~H"""
    <%!-- MOBILE NAV --%>
    <nav class="fixed z-1 bg-red bottom-0 w-full h-[70px] flex justify-center py-3 px-5 xl:hidden">
      <div class="flex w-full max-w-[850px] justify-between items-center text-lg leading-none">
        <button
          phx-click="settings"
          class="p-3 rounded-xl bg-blue-dark border border-red-light tracking-[0.05rem]
          hover:bg-blue-light hover:text-blue-dark hover:border-blue-dark"
        >
          <%= if @screen == :settings, do: "Return", else: "Settings" %>
        </button>
        <%!-- IF TIME PERMITS: ADD DOT PAGINATION --%>
        <%!-- <%= if @screen == :main do %>
          <div class="flex gap-3">
            <button>O</button><button>O</button><button>O</button><button>O</button>
          </div>
        <% end %> --%>
        <button
          phx-click="places"
          class="md:hidden p-3 rounded-xl bg-blue-dark border border-red-light tracking-[0.05rem]
          hover:bg-blue-light hover:text-blue-dark hover:border-blue-dark"
        >
          <%= if @screen == :places, do: "Return", else: "My Places" %>
        </button>
      </div>
    </nav>
    <%!-- DESKTOP HEADER --%>
    <header class="hidden lg:flex justify-center gap-4">
      <h1 class="font-extrabold text-5xl py-4">☀️ &nbsp; Himmel &nbsp; 🌧️</h1>
    </header>
    <%!-- SCREEN / LIVEVIEW WRAPPER --%>
    <main class="pb-[6rem] w-full">
      <%!-- > 1280px: CURRENT @SCREEN SHOWN --%>
      <%!-- =< 1280px: ALL @SCREEN SHOWN IN A SINGLE ROW --%>
      <div class="flex justify-center gap-10">
        <%!-- MAIN --%>
        <.live_component module={MainLive} id="main" screen={@screen} main_weather={@main_weather} />
        <%!-- PLACES --%>
        <.live_component
          module={PlacesLive}
          id="places"
          screen={@screen}
          my_location={@my_location}
          current_user={assigns.current_user}
        />
        <%!-- SETTINGS --%>
        <.live_component
          module={SettingsLive}
          id="settings"
          screen={@screen}
          current_user={assigns.current_user}
        />
      </div>
    </main>
    """
  end

  def handle_event("settings", _, socket) do
    screen = if socket.assigns.screen == :settings, do: :main, else: :settings
    {:noreply, assign(socket, screen: screen)}
  end

  def handle_event("places", _, socket) do
    screen = if socket.assigns.screen == :places, do: :main, else: :places
    {:noreply, assign(socket, screen: screen)}
  end

  def handle_event("set_main_weather_to_my_location", _, socket) do
    my_location = socket.assigns.my_location
    socket = assign(socket, main_weather: prepare_main_weather(my_location))
    {:noreply, socket}
  end

  # def handle_event(%Phoenix.PubSub.Broadcast{}) do
  # end

  def handle_info({:set_main_weather, place}, socket) do
    {:noreply, assign(socket, main_weather: prepare_main_weather(place))}
  end

  defp prepare_main_weather(
         %Place{name: name, weather: %{current: current, daily: daily, hourly: hourly}} = place
       ) do
    todays_temp_range = List.first(daily) |> Map.get(:temperature)

    %{
      name: name,
      temperature: current.temperature,
      description_text: current.description.text,
      high: todays_temp_range.high,
      low: todays_temp_range.low,
      hours: hourly,
      days: daily
    }
  end
end
