defmodule HimmelWeb.PlacesLive do
  use HimmelWeb, :live_component
  alias Himmel.Services.Geocoding
  import HimmelWeb.WeatherComponents

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
      <h1 class="text-4xl font-bold">Places</h1>
      <%!-- SEARCH --%>
      <%!-- phx-focus={JS.hide(to: "#places-list") |> JS.show(to: "#search-results")}
          phx-blur={JS.show(to: "#places-list") |> JS.hide(to: "#search-results")} --%>
      <form phx-submit="search" phx-target={@myself} class="inline-flex items-center justify-between w-full h-10 rounded-xl bg-red-dark text-red-light py-2 pl-4">
        <input
          type="text"
          name="place"
          value={@search}
          placeholder="Search for a city or place"
          autocomplete="off"
          phx-debounce="200"
          class="w-full bg-transparent placeholder-red-light"
        />
        <button class="px-4 transition ease-in-out duration-150 outline-none">
          <.icon_loupe />
        </button>
      </form>
      <%!-- SEARCH RESULT LIST --%>
      <div id="search-results" class="">
        <ul>
          <%= @search_results |> Enum.with_index |> Enum.map(fn({result, index}) -> %>
            <li id={"result-#{index}"} phx-target={@myself} phx-click="add_place" phx-value-place_id={result["provider_place_id"]} >
                <div>
                  <h2 class="text-2xl font-bold"><%= result["name"] %></h2>
                  <h3 class="font-semibold"><%= result["region"] %>, <%= result["country"] %></h3>
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
            <h3 class="font-semibold"><%= @my_location.place %></h3>
            <h4 class="font-semibold pt-6"><%= @my_location.description_text %></h4>
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
        <%= @saved_places |> Enum.with_index |> Enum.map(fn({place, index}) -> %>
          <.place_card id={"placeCard-#{index}"} place={place} />
        <% end) %>
      </div>
    </div>
    """
  end

  def handle_event("search", %{"place" => place}, socket) do
    socket =
      assign(socket,
        search: place,
        search_results: Geocoding.find_place(place)
      )

    {:noreply, socket}
  end

  def handle_event("add_place", %{"place_id" => place_id}, socket) do
    # TODO: if user is authd, add place in DB
    # TODO: get weather for place
    place =
      Enum.find(socket.assigns.search_results, fn result ->
        result["provider_place_id"] == place_id
      end)

    weather =
      Himmel.Weather.Service.get_weather(
        %{longitude: place["longitude"], latitude: place["latitude"]},
        place["name"]
      )

    saved_place = %{
      "name" => weather["place"],
      "description" => weather["current"]["description"]["text"],
      "temperature" => weather["current"]["temperature"],
      "high" => hd(weather["daily"])["temperature"]["high"],
      "low" => hd(weather["daily"])["temperature"]["low"]
    }

    # send(self(), {:set_current_weather, saved_place})

    socket =
      assign(socket,
        search: "",
        search_results: [],
        saved_places: [saved_place | socket.assigns.saved_places]
      )

    {:noreply, socket}
  end

  def get_places_weather() do
    [
      %{
        place: "Bremen",
        temperature: 65,
        description: "Sunny",
        high: 80,
        low: 58
      },
      %{
        place: "San Francisco",
        temperature: 65,
        description: "Foggy",
        high: 70,
        low: 60
      },
      %{
        place: "New York",
        temperature: 75,
        description: "Cloudy",
        high: 80,
        low: 70
      },
      %{
        place: "London",
        temperature: 55,
        description: "Rainy",
        high: 60,
        low: 50
      },
      %{
        place: "Tokyo",
        temperature: 75,
        description: "Sunny",
        high: 80,
        low: 70
      },
      %{
        place: "Sydney",
        temperature: 75,
        description: "Sunny",
        high: 80,
        low: 70
      },
      %{
        place: "Rio de Janeiro",
        temperature: 75,
        description: "Sunny",
        high: 80,
        low: 70
      },
      %{
        place: "Cape Town",
        temperature: 75,
        description: "Sunny",
        high: 80,
        low: 70
      },
      %{
        place: "Moscow",
        temperature: 75,
        description: "Sunny",
        high: 80,
        low: 70
      },
      %{
        place: "Beijing",
        temperature: 75,
        description: "Sunny",
        high: 80,
        low: 70
      }
    ]
  end

  def icon_loupe(assigns) do
    ~H"""
    <svg fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6 mx-auto"><path stroke-linecap="round" stroke-linejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607z"/></svg>
    """
  end
end
