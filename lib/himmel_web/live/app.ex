defmodule HimmelWeb.AppLive do
  use HimmelWeb, :live_view
  alias Himmel.Services.Weather
  alias Himmel.Places.Place
  alias HimmelWeb.{MainLive, PlacesLive, SettingsLive}

  @doc """
  MAIN shows data for the current PLACE. If there's a user session or authenticated user's places and history,
  the last loaded place is shown. Otherwise, the user's IP is used to get the current place and weather.
  """
  def mount(_params, _session, socket) do
    user = false

    # if connected?(socket) do
    #   HimmelWeb.Endpoint.subscribe("places")
    # end

    place_weather =
      if user do
        # TODO: get user's last loaded place instead of IP, and have the Weather manager get the weather for that place
        Weather.get_weather_from_ip(socket)
      else
        # get current weather from user's IP
        Weather.get_weather_from_ip(socket)
      end

    main_weather = prepare_main_weather(place_weather)

    {:ok,
     assign(socket,
       my_location: main_weather,
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
        <.live_component module={MainLive} id="main" screen={@screen} my_location={@my_location} />
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

  # def handle_event(%Phoenix.PubSub.Broadcast{}) do
  # end

  def handle_info({:set_main_weather, place}, socket) do
    main_weather = prepare_main_weather(place)
    {:noreply, assign(socket, my_location: main_weather)}
  end

  def prepare_main_weather(%Place{name: name, weather: weather}) do
    %{
      name: name,
      temperature: weather.current.temperature,
      description_text: weather.current.description.text,
      high: List.first(weather.daily)[:temperature].high,
      low: List.first(weather.daily)[:temperature].low,
      hours: weather.hourly,
      days: weather.daily
    }
  end
end
