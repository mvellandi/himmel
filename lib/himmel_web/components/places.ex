defmodule HimmelWeb.Components.Places do
  use HimmelWeb, :component

  def places(assigns) do
    ~H"""
    <div class={"#{if @screen == :places, do: "flex", else: "hidden md:flex"} flex-col gap-3 pt-[120px] w-full md:min-w-[320px] md:max-w-[440px] lg:min-w-[380px]"}>
      <h1 class="screen-title">Places</h1>
      <%!-- SEARCH --%>
      <.search_bar search={@search} />
      <%!-- SEARCH RESULT LIST --%>
      <div id="search-results">
        <%= if @search_results do %>
          <ul class="flex flex-col gap-2">
            <%= if @search_results == [] && @search !== "" do %>
              <li class="flex justify-left items-center rounded-xl bg-primary-dark py-3.5 px-4">
                <h2 class="text-2xl font-bold">No results found</h2>
              </li>
            <% else %>
              <%= @search_results |> Enum.with_index |> Enum.map(fn({result, index}) -> %>
                <li
                  id={"result-#{index}"}
                  phx-click="save_search_result"
                  phx-value-search_result_id={result.id}
                >
                  <div class="px-4 py-2 border-2 cursor-pointer border-primary-dark rounded-xl bg-primary-dark hover:border-primary-medium hover:border-2">
                    <h2 class="text-2xl font-bold"><%= result.name %></h2>
                    <h3 class="font-semibold"><%= result.region %>, <%= result.country %></h3>
                  </div>
                </li>
              <% end) %>
            <% end %>
          </ul>
        <% end %>
      </div>
      <%!-- PLACES LIST --%>
      <div id="places-list" class="flex flex-col space-y-3">
        <%= if is_nil(@search_results) do %>
          <%!-- MY LOCATION (CUSTOM SIZE) --%>
          <div
            id="currentLocation"
            phx-click="set_main_weather_to_current_location"
            class="flex justify-between items-center rounded-xl bg-primary-dark py-3.5 px-4 cursor-pointer"
          >
            <div class="flex flex-col">
              <h2 class="text-2xl font-bold leading-none">My Location</h2>
              <h3 class="pt-1 pb-4 font-semibold"><%= @current_location.name %></h3>
              <h4 class="font-semibold"><%= @current_location.weather.current.description.text %></h4>
            </div>
            <div class="flex flex-col items-end justify-between h-full">
              <span class="text-5xl font-light leading-[0.9]">
                <%= @current_location.weather.current.temperature %>&deg;
              </span>
              <div class="flex justify-end gap-5 font-semibold">
                <h4>L: <%= List.first(@current_location.weather.daily).temperature.low %>&deg;</h4>
                <h4>L: <%= List.first(@current_location.weather.daily).temperature.high %>&deg;</h4>
              </div>
            </div>
          </div>
          <%!-- SAVED PLACES --%>
          <.saved_places saved_places={@saved_places} />
        <% end %>
      </div>
    </div>
    """
  end

  def saved_places(assigns) do
    ~H"""
    <.async_result :let={places} assign={@saved_places}>
      <:loading>Loading saved places...</:loading>
      <:failed :let={reason}><%= reason %></:failed>

      <%= if places !== [] do %>
        <%= places |> Enum.with_index |> Enum.map(fn({place, index}) -> %>
          <.place_card id={"placeCard-#{index}"} place={place} />
        <% end) %>
      <% else %>
        <div class="flex justify-center items-center rounded-xl bg-primary-dark py-3.5 px-4">
          <h2 class="text-xl font-med text-primary-medium">No saved places</h2>
        </div>
      <% end %>
    </.async_result>
    """
  end

  def place_card(assigns) do
    ~H"""
    <div
      id={@id}
      phx-click="set_main_weather"
      phx-value-location_id={@place.location_id}
      class="flex justify-between rounded-xl bg-primary-dark py-3.5 px-4 cursor-pointer"
    >
      <div class="flex flex-col">
        <h2 class="text-2xl font-bold leading-none"><%= @place.name %></h2>
        <h3 class="pb-4 font-semibold"><%= @place.weather.current.description.text %></h3>
        <button
          class="w-6 h-6 text-left cursor-pointer text-primary-light"
          phx-click="delete_place"
          phx-value-location_id={@place.location_id}
        >
          <.icon_trash />
        </button>
      </div>
      <div class="flex flex-col items-end justify-between">
        <span class="text-5xl font-light leading-[0.9]">
          <%= @place.weather.current.temperature %>&deg;
        </span>
        <div class="flex justify-end gap-5 font-semibold">
          <h4>L: <%= List.first(@place.weather.daily).temperature.low %>&deg;</h4>
          <h4>H: <%= List.first(@place.weather.daily).temperature.high %>&deg;</h4>
        </div>
      </div>
    </div>
    """
  end

  def search_bar(assigns) do
    ~H"""
    <search>
      <form phx-submit="search_places" phx-change="set_search">
        <div class="inline-flex items-center justify-between w-full h-10 py-2 pl-2 rounded-xl bg-primary-dark text-primary-light">
          <div class="relative w-full">
            <input
              type="text"
              name="name"
              value={@search}
              phx-debounce="300"
              placeholder="Search for a city or place"
              autocomplete="off"
              class="w-full pl-2 pr-8 text-white bg-transparent placeholder:text-primary-light"
            />
            <%= if @search !== "" do %>
              <span
                phx-click="clear_search"
                class="absolute top-0 right-0 flex w-8 h-full cursor-pointer bg-primary-dark place-content-center"
              >
                <.icon_x_circle />
              </span>
            <% end %>
          </div>
          <button class="px-4 outline-none">
            <.icon_loupe />
          </button>
        </div>
      </form>
    </search>
    """
  end

  def icon_loupe(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      aria-hidden="true"
      class="w-6 h-6 mx-auto"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607z"
      />
    </svg>
    """
  end

  def icon_trash(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      aria-hidden="true"
      class="w-6 h-6 mx-auto"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M3 6h18M6 6V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v2m-2 0v12a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V6h2z"
      />
    </svg>
    """
  end

  def icon_x_circle(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 20 20"
      fill="currentColor"
      aria-hidden="true"
      class="w-6 h-6 mx-auto"
    >
      <path
        fill-rule="evenodd"
        d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end
end
