defmodule HimmelWeb.AppLive do
  use HimmelWeb, :live_view
  alias Himmel.Weather
  alias HimmelWeb.{MainLive, PlacesLive, SettingsLive}

  @doc """
  MAIN shows data for the current PLACE. If there's a user session or authenticated user's places and history,
  the last loaded place is shown. Otherwise, the user's IP is used to get the current place and weather.
  """
  def mount(_params, _session, socket) do
    user = false

    weather =
      if user do
        # TODO: get user's last loaded place
        Weather.get_weather_from_ip(socket)
      else
        # get current weather from user's IP
        Weather.get_weather_from_ip(socket)
      end

    {:ok,
     assign(socket,
       #  socket.assigns.current_user will be here
       main: %{
         place: weather["place"],
         temperature: weather["current"]["temperature"],
         description: weather["current"]["description"]["text"],
         #  high: hd(weather["daily"])["temperature"]["high"],
         high: List.first(weather["daily"])["temperature"]["high"],
         low: List.first(weather["daily"])["temperature"]["low"],
         hours: weather["hourly"],
         days: weather["daily"]
       },
       places: %{
         places: PlacesLive.get_places_weather(),
         api: "https://api.weather.gov/points/33.4484,-112.0740",
         user: nil
       },
       settings: %{
         temperature_scale: :celsius
       },
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
        <.live_component module={MainLive} , id="main" screen={@screen} data={@main} />
        <%!-- PLACES --%>
        <.live_component module={PlacesLive} , id="places" screen={@screen} data={@places} />
        <%!-- SETTINGS --%>
        <.live_component
          module={SettingsLive}
          ,
          id="settings"
          screen={@screen}
          data={@settings}
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
end
