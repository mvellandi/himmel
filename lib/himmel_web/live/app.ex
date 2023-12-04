defmodule HimmelWeb.AppLive do
  use HimmelWeb, :live_view
  alias HimmelWeb.Utils
  alias Himmel.Services
  alias Himmel.Accounts
  import HimmelWeb.Components.{Main, Places, Settings, ApplicationError}
  require Logger

  @doc """
  MAIN shows data for the current PLACE. If there's a user session or authenticated user's places and history,
  the last loaded place is shown. Otherwise, the user's IP is used to get the current location and weather.
  """
  def mount(_params, _session, socket) do
    # This is for receiving any notifications regarding the weather service
    if connected?(socket) and socket.assigns[:current_user] do
      Phoenix.PubSub.subscribe(Himmel.PubSub, "weather_service")
      {:ok, socket}
    end

    {:ok, Utils.init_data_start(socket)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <%!-- MOBILE NAV --%>
    <nav class="fixed z-1 bg-primary bottom-0 w-full h-[70px] flex justify-center py-3 px-5 xl:hidden">
      <div class="flex w-full max-w-[850px] justify-between items-center text-lg leading-none">
        <button phx-click="show_settings" class="nav-button">
          <%= if @screen == :settings, do: "Return", else: "Settings" %>
        </button>
        <button phx-click="show_places" class="md:hidden nav-button">
          <%= if @screen == :places, do: "Return", else: "My Places" %>
        </button>
      </div>
    </nav>
    <%!-- DESKTOP HEADER --%>
    <header class="hidden lg:flex justify-center gap-4">
      <h1 class="font-extrabold text-5xl py-4 text-shadow-surround">☀️ &nbsp; Himmel &nbsp; 🌧️</h1>
    </header>
    <%!-- DATA UPDATE ERROR BANNER --%>
    <%= if @error && @error[:stage] == :update do %>
      <.error_banner error={@error} />
    <% end %>
    <%= if @mobile_onboarding && @info && !@current_user && !@error do %>
      <.info_banner
        info={@info}
        click_target="show_places"
        class="md:hidden cursor-pointer mt-4 -mb-9 md:mb-0 md:mt-0"
      />
    <% end %>
    <%!-- SCREEN / LIVEVIEW WRAPPER --%>
    <main class="pb-[6rem] w-full">
      <%!-- > 1280px: CURRENT @SCREEN SHOWN --%>
      <%!-- =< 1280px: ALL @SCREEN SHOWN IN A SINGLE ROW --%>
      <div class="flex justify-center gap-10">
        <%= if @screen == :error do %>
          <%!-- ERROR --%>
          <.application_error screen={@screen} error={@error} />
        <% else %>
          <%!-- MAIN --%>
          <.main screen={@screen} main_weather={@main_weather} />
          <%!-- PLACES --%>
          <.places
            screen={@screen}
            search={@search}
            search_results={@search_results}
            current_location={@current_location}
            current_user={assigns.current_user}
            saved_places={@saved_places}
          />
          <%!-- SETTINGS --%>
          <.settings screen={@screen} current_user={assigns.current_user} />
        <% end %>
      </div>
    </main>
    """
  end

  def handle_event("show_settings", _, socket) do
    screen = if socket.assigns.screen == :settings, do: :main, else: :settings
    {:noreply, assign(socket, screen: screen)}
  end

  def handle_event("show_places", _, socket) do
    screen = if socket.assigns.screen == :places, do: :main, else: :places
    {:noreply, assign(socket, screen: screen, mobile_onboarding: false, info: nil)}
  end

  def handle_event("set_search", %{"name" => name}, socket) do
    socket = if name == "", do: assign(socket, search_results: nil), else: socket
    {:noreply, assign(socket, search: name)}
  end

  def handle_event("clear_search", _, socket) do
    {:noreply, assign(socket, search: "", search_results: nil)}
  end

  def handle_event("search_places", %{"name" => name}, socket) do
    socket =
      assign(socket,
        search: name,
        search_results: Services.Geocoding.search_places(name)
      )

    {:noreply, socket}
  end

  def handle_event("save_search_result", %{"search_result_id" => search_result_id}, socket) do
    location =
      Enum.find(socket.assigns[:search_results], fn result ->
        result.id == String.to_integer(search_result_id)
      end)

    already_saved? =
      Enum.any?(socket.assigns.saved_places.result, fn p ->
        p.location_id == "#{location.latitude},#{location.longitude}"
      end)

    updated_socket =
      if already_saved? do
        socket
      else
        Utils.save_place_and_set_to_main_weather(location, socket)
      end

    {:noreply, updated_socket}
  end

  def handle_event("delete_place", %{"location_id" => location_id}, socket) do
    updated_socket = Utils.delete_place_and_maybe_change_main_weather(location_id, socket)
    {:noreply, updated_socket}
  end

  def handle_event("set_main_weather", %{"location_id" => location_id}, socket) do
    current_user = socket.assigns[:current_user]

    place =
      Enum.find(socket.assigns.saved_places.result, fn p -> p.location_id == location_id end)

    updated_user =
      if current_user do
        Accounts.update_user_active_place(current_user, location_id)
      else
        nil
      end

    {:noreply,
     assign(socket,
       screen: :main,
       main_weather: Utils.prepare_main_weather(place),
       current_user: updated_user
     )}
  end

  def handle_event("set_main_weather_to_current_location", _, socket) do
    current_user = socket.assigns[:current_user]
    current_location = socket.assigns.current_location

    updated_user =
      if current_user do
        Accounts.update_user_active_place(current_user, nil)
      else
        nil
      end

    {:noreply,
     assign(socket,
       screen: :main,
       main_weather: Utils.prepare_main_weather(current_location),
       current_user: updated_user
     )}
  end

  def handle_info({:place_weather_update, info}, socket) do
    previous_updates = socket.assigns[:updates]
    updates = [info | previous_updates]
    total_updates = length(updates)
    total_places = Utils.total_places(socket)

    if total_places == total_updates do
      updated_socket = Utils.process_all_place_updates(updates, socket)

      {:noreply, updated_socket}
    else
      {:noreply, assign(socket, updates: updates)}
    end
  end

  def handle_info({:weather_service, %{status: :error} = error}, socket) do
    {:noreply, assign(socket, error: Utils.prepare_error_message(error))}
  end

  @doc "Generic error handler"
  def handle_info(%{error: error}, socket) do
    Logger.error("App: handle_info error: #{inspect(error)}")
    {:noreply, assign(socket, error: Utils.prepare_error_message(error))}
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  def error_banner(assigns) do
    ~H"""
    <div
      role="alert"
      class={"rounded-lg px-3 py-2 flex flex-row items-center justify-between gap-4 bg-yellow-200 text-yellow-800 #{if @class, do: @class}"}
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="1.5"
        stroke="currentColor"
        class="w-16 h-12"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z"
        />
      </svg>

      <p class="text-md">
        <%= @error.reason %>. <%= @error.advisory %>.
      </p>
    </div>
    """
  end

  def info_banner(assigns) do
    ~H"""
    <div
      role="alert"
      phx-click={@click_target}
      class={"rounded-lg px-3 py-2 flex flex-row items-center justify-between gap-4 bg-green-200 text-green-800 #{if @class, do: @class}"}
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="1.5"
        stroke="currentColor"
        class="w-16 h-12"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z"
        />
      </svg>

      <p class="text-md">
        <%= @info %>.
      </p>
    </div>
    """
  end
end
