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
      <div id="places-search" class="hidden">SEARCH RESULTS</div>
      <%!-- PLACES LIST --%>
      <div id="places-list" class="flex flex-col gap-3">
        <%!-- MY LOCATION (CUSTOM SIZE) --%>
        <div
          id="myLocation"
          class="flex justify-between items-center rounded-xl bg-red-dark py-3.5 px-4"
        >
          <div class="flex flex-col">
            <h2 class="text-2xl font-bold leading-none">My Location</h2>
            <h3 class="font-semibold">Phoenix</h3>
            <h4 class="font-semibold pt-6">Sunny</h4>
          </div>
          <div class="flex flex-col h-full justify-between items-end">
            <span class="text-5xl font-light leading-[0.9]">98&deg;</span>
            <div class="flex justify-end gap-5 font-semibold">
              <h4>H: 100&deg;</h4>
              <h4>L: 85&deg;</h4>
            </div>
          </div>
        </div>
        <%!-- SAVED PLACES --%>
        <%= for place <- @data.places, idx <- 1..length(@data.places) do %>
          <.place_card id={"placeCard-#{idx}"} data={place} />
        <% end %>
      </div>
    </div>
    """
  end

  def get_places_weather() do
    [
      %{
        name: "Bremen",
        temperature: 65,
        description: "Sunny",
        high: 80,
        low: 58
      },
      %{
        name: "San Francisco",
        temperature: 65,
        description: "Foggy",
        high: 70,
        low: 60
      },
      %{
        name: "New York",
        temperature: 75,
        description: "Cloudy",
        high: 80,
        low: 70
      },
      %{
        name: "London",
        temperature: 55,
        description: "Rainy",
        high: 60,
        low: 50
      },
      %{
        name: "Tokyo",
        temperature: 75,
        description: "Sunny",
        high: 80,
        low: 70
      },
      %{
        name: "Sydney",
        temperature: 75,
        description: "Sunny",
        high: 80,
        low: 70
      },
      %{
        name: "Rio de Janeiro",
        temperature: 75,
        description: "Sunny",
        high: 80,
        low: 70
      },
      %{
        name: "Cape Town",
        temperature: 75,
        description: "Sunny",
        high: 80,
        low: 70
      },
      %{
        name: "Moscow",
        temperature: 75,
        description: "Sunny",
        high: 80,
        low: 70
      },
      %{
        name: "Beijing",
        temperature: 75,
        description: "Sunny",
        high: 80,
        low: 70
      }
    ]
  end
end
