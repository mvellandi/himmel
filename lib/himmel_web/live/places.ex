defmodule HimmelWeb.PlacesLive do
  use HimmelWeb, :live_component
  import HimmelWeb.WeatherComponents

  def render(assigns) do
    ~H"""
    <div
      id="places"
      class={"#{if @screen == :places, do: "flex", else: "hidden md:flex"} flex-col gap-3 pt-[120px] w-full max-w-[420px]"}
    >
      <h1 class="text-4xl font-bold">Places</h1>
      <%!-- SEARCH --%>
      <%!-- option: phx-blur or phx-focus could trigger an event handler, which
      could control some value in state, --%>
      <%!-- <button phx-click={JS.push("inc", loading: ".thermo", target: @myself) |> JS.add_class("warmer", to: ".thermo")}>+</button> --%>
      <%!-- <button phx-blur={JS.hide(to: "#") |> JS.show(to: "#")}>+</button> --%>
      <input
        type="text"
        phx-focus={JS.hide(to: "#places-list") |> JS.show(to: "#places-search")}
        phx-blur={JS.show(to: "#places-list") |> JS.hide(to: "#places-search")}
        placeholder="Search for a city or airport"
        class="rounded-xl w-full bg-red-dark text-red-light placeholder-red-light p-2"
      />
      <%!-- SEARCH RESULT LIST --%>
      <div id="places-search" class="hidden">
      <%!-- # TODO: add search result click attribute and event handler to add place to places list --%>
        <%!-- <ul>
          <%= @data.search_results |> Enum.with_index |> Enum.map(fn({result, index}) -> %>
            <a phx-click={nil}><li id={"result-#{index}"}><%= result %></li></a>
          <% end) %>
        </ul> --%>
      </div>
      <%!-- PLACES LIST --%>
      <div id="places-list" class="flex flex-col space-y-3">
        <%!-- MY LOCATION (CUSTOM SIZE) --%>
        <div id="myLocation" class="flex justify-between items-center rounded-xl bg-red-dark py-3.5 px-4">
          <div class="flex flex-col">
            <h2 class="text-2xl font-bold leading-none">My Location</h2>
            <h3 class="font-semibold"><%= @data.my_location.place %></h3>
            <h4 class="font-semibold pt-6"><%= @data.my_location.description %></h4>
          </div>
          <div class="flex flex-col h-full justify-between items-end">
            <span class="text-5xl font-light leading-[0.9]"><%= @data.my_location.temperature %>&deg;</span>
            <div class="flex justify-end gap-5 font-semibold">
              <h4>L: <%= @data.my_location.low %>&deg;</h4>
              <h4>H: <%= @data.my_location.high %>&deg;</h4>
            </div>
          </div>
        </div>
        <%!-- SAVED PLACES --%>
        <%!-- # TODO: add "load place" click attribute to card, and event handler to show weather for that place in main --%>
        <%!-- # TODO: add "delete place" click attribute to button, and event handler to show weather for that place in main --%>
        <%= @data.places |> Enum.with_index |> Enum.map(fn({place, index}) -> %>
          <.place_card id={"placeCard-#{index}"} data={place} />
        <% end) %>
      </div>
    </div>
    """
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

  def handle_event("add_place", unsigned_params, socket) do
  end
end
