defmodule HimmelWeb.PlacesLive do
  use HimmelWeb, :live_component
  alias Himmel.Services
  alias Himmel.Weather
  alias Himmel.Places.{Place, Coordinates}

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(search: "", search_results: [], saved_places: [])}
  end

  def render(assigns) do
    ~H"""
    <div
      id="places"
      class={"#{if @screen == :places, do: "flex", else: "hidden md:flex"} flex-col gap-3 pt-[120px] w-full max-w-[420px]"}
    >
      <h1 class="text-4xl font-bold ml-4">Places</h1>
      <%!-- SEARCH --%>
      <%!-- TODO: See if I can better handle hiding the saved places list during search results --%>
      <%!-- phx-focus={JS.hide(to: "#places-list") |> JS.show(to: "#search-results")}
          phx-blur={JS.show(to: "#places-list") |> JS.hide(to: "#search-results")} --%>
      <form phx-submit="search_places" phx-target={@myself} class="inline-flex items-center justify-between w-full h-10 rounded-xl bg-red-dark text-red-light py-2 pl-2">
        <input
          type="text"
          name="name"
          value={@search}
          placeholder="Search for a city or place"
          autocomplete="off"
          phx-debounce="200"
          class="w-full bg-transparent text-white placeholder:text-red-light pl-2"
        />
        <button class="px-4 transition ease-in-out duration-150 outline-none">
          <.icon_loupe />
        </button>
      </form>
      <%!-- SEARCH RESULT LIST --%>
      <div id="search-results" class="">
        <ul class="flex flex-col gap-2">
          <%= @search_results |> Enum.with_index |> Enum.map(fn({result, index}) -> %>
            <li id={"result-#{index}"} phx-target={@myself} phx-click="add_place" phx-value-id={result.id} >
                <div class="border-2 border-red-dark px-4 py-2 cursor-pointer rounded-xl bg-red-dark hover:border-red-medium hover:border-2">
                  <h2 class="text-2xl font-bold"><%= result.name %></h2>
                  <h3 class="font-semibold"><%= result.region %>, <%= result.country %></h3>
                </div>
            </li>
          <% end) %>
        </ul>
      </div>
      <%!-- PLACES LIST --%>
      <div id="places-list" class="flex flex-col space-y-3">
        <%!-- MY LOCATION (CUSTOM SIZE) --%>
        <div id="myLocation" class="flex justify-between items-center rounded-xl bg-red-dark py-3.5 px-4">
          <div class="flex flex-col">
            <h2 class="text-2xl font-bold leading-none">My Location</h2>
            <h3 class="font-semibold pb-4 pt-1"><%= @my_location.name %></h3>
            <h4 class="font-semibold"><%= @my_location.description_text %></h4>
          </div>
          <div class="flex flex-col h-full justify-between items-end">
            <span class="text-5xl font-light leading-[0.9]"><%= @my_location.temperature %>&deg;</span>
            <div class="flex justify-end gap-5 font-semibold">
              <h4>L: <%= @my_location.low %>&deg;</h4>
              <h4>H: <%= @my_location.high %>&deg;</h4>
            </div>
          </div>
        </div>
        <%!-- SAVED PLACES --%>
        <%!-- # TODO: add "load place" click attribute to card, and event handler to show weather for that place in main --%>
        <%!-- # TODO: add "delete place" click attribute to button, and event handler to show weather for that place in main --%>
        <%= @saved_places |> IO.inspect() |>Enum.with_index |> Enum.map(fn({place, index}) -> %>
          <.place_card id={"placeCard-#{index}"} place={place} />
        <% end) %>
      </div>
    </div>
    """
  end

  def handle_event("search_places", %{"name" => name}, socket) do
    socket =
      assign(socket,
        search: name,
        search_results: Services.Geocoding.search_places(name)
      )

    {:noreply, socket}
  end

  def handle_event("add_place", %{"id" => id}, socket) do
    place_with_weather =
      get_place_from_search_results(id, socket)
      |> Weather.Manager.get_weather()

    # TODO: if user is authd, see if place is in DB, if not, save it, then save place in memory
    # new function somewhere

    # TODO: set current weather in main with this place
    # send(self(), {:set_main_weather, place_with_weather})

    socket =
      assign(socket,
        search: "",
        search_results: [],
        saved_places: [place_with_weather | socket.assigns.saved_places]
      )

    {:noreply, socket}
  end

  def handle_event("remove_place", %{"place_id" => _place_id}, socket) do
    # place = get_place_in_memory(socket, :saved_places, place_id)
    # updated_places = Enum.reject(socket.assigns.saved_places, fn p -> p["id"] == place_id end)
    {:noreply, socket}
  end

  def place_card(assigns) do
    ~H"""
    <div id={@id} class="flex justify-between items-center rounded-xl bg-red-dark py-3.5 px-4">
      <div class="flex flex-col">
        <h2 class="text-2xl font-bold leading-none"><%= @place.name %></h2>
        <h3 class="font-semibold pb-4"><%= @place.weather.current.description.text %></h3>
        <button class="cursor-pointer text-red-light text-left h-6 w-6" phx-click="remove_place" phx-value-place_id={coordinates_to_id(@place.coordinates)}><.icon_trash /></button>
      </div>
      <div class="flex flex-col h-full justify-between items-end">
        <span class="text-5xl font-light leading-[0.9]"><%= @place.weather.current.temperature %>&deg;</span>
        <div class="flex justify-end gap-5 font-semibold">
          <h4>L: <%= List.first(@place.weather.daily)[:temperature][:low] %>&deg;</h4>
          <h4>H: <%= List.first(@place.weather.daily)[:temperature][:high] %>&deg;</h4>
        </div>
      </div>
    </div>
    """
  end

  def icon_loupe(assigns) do
    ~H"""
    <svg fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6 mx-auto"><path stroke-linecap="round" stroke-linejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607z"/></svg>
    """
  end

  def icon_trash(assigns) do
    ~H"""
    <svg fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6 mx-auto"><path stroke-linecap="round" stroke-linejoin="round" d="M3 6h18M6 6V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v2m-2 0v12a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V6h2z"/></svg>
    """
  end

  def get_place_from_search_results(place_id, socket) do
    place =
      Enum.find(socket.assigns[:search_results], fn result ->
        result.id == String.to_integer(place_id)
      end)

    %Place{
      name: place.name,
      coordinates: %Coordinates{
        latitude: place.latitude,
        longitude: place.longitude
      }
    }
  end

  def coordinates_to_id(%Coordinates{latitude: latitude, longitude: longitude}) do
    (latitude + longitude) |> Float.to_string() |> String.replace(".", "")
  end
end
