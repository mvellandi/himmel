defmodule HimmelWeb.PlacesLive do
  alias Phoenix.LiveView.AsyncResult
  use HimmelWeb, :live_component
  alias Himmel.Services
  alias Himmel.Weather
  alias Himmel.Places

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(search: "", search_results: nil)}
  end

  def render(assigns) do
    ~H"""
    <div
      id="places"
      class={"#{if @screen == :places, do: "flex", else: "hidden md:flex"} flex-col gap-3 pt-[120px] w-full max-w-[420px]"}
    >
      <h1 class="text-4xl font-bold ml-4">Places</h1>
      <%!-- SEARCH --%>
      <.search_bar search={@search} myself={@myself} />
      <%!-- SEARCH RESULT LIST --%>
      <div id="search-results">
        <%= if @search_results do %>
          <ul class="flex flex-col gap-2">
            <%= if @search_results == [] && @search !== "" do %>
              <li class="flex justify-left items-center rounded-xl bg-red-dark py-3.5 px-4">
                <h2 class="text-2xl font-bold">No results found</h2>
              </li>
            <% else %>
              <%= @search_results |> Enum.with_index |> Enum.map(fn({result, index}) -> %>
                <li
                  id={"result-#{index}"}
                  phx-target={@myself}
                  phx-click="add_search_result_to_saved_places"
                  phx-value-search_result_id={result.id}
                >
                  <div class="border-2 border-red-dark px-4 py-2 cursor-pointer rounded-xl bg-red-dark hover:border-red-medium hover:border-2">
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
            class="flex justify-between items-center rounded-xl bg-red-dark py-3.5 px-4 cursor-pointer"
          >
            <div class="flex flex-col">
              <h2 class="text-2xl font-bold leading-none">My Location</h2>
              <h3 class="font-semibold pb-4 pt-1"><%= @current_location.name %></h3>
              <h4 class="font-semibold"><%= @current_location.weather.current.description.text %></h4>
            </div>
            <div class="flex flex-col h-full justify-between items-end">
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
          <.saved_places saved_places={@saved_places} myself={@myself} />
        <% end %>
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

  def handle_event("set_search", %{"name" => name}, socket) do
    socket = if name == "", do: assign(socket, search_results: nil), else: socket
    {:noreply, assign(socket, search: name)}
  end

  def handle_event("clear_search", _, socket) do
    {:noreply, assign(socket, search: "", search_results: nil)}
  end

  def handle_event(
        "add_search_result_to_saved_places",
        %{"search_result_id" => search_result_id},
        socket
      ) do
    item = get_item_from_search_results(search_result_id, socket)
    item_location_id = "#{item.latitude},#{item.longitude}"
    async_saved_places = socket.assigns.saved_places
    saved_places_list = async_saved_places.result

    is_already_saved? =
      Enum.any?(saved_places_list, fn p -> p.location_id == item_location_id end)

    case is_already_saved? do
      true ->
        {:noreply, assign(socket, search: "", search_results: nil)}

      false ->
        place_with_weather =
          item
          |> Places.create_place_from_search_result()
          |> Weather.get_weather()

        if socket.assigns[:current_user] do
          # TODO: see if place already exists in DB
          # if not, then save place in DB
          # then add place to user's saved places

          IO.puts("save place in DB (if not already) and add to user's saved places")
        end

        send(self(), {:set_main_weather, place_with_weather})

        {:noreply,
         assign(socket,
           search: "",
           search_results: nil,
           saved_places: %AsyncResult{
             async_saved_places
             | result: [place_with_weather | saved_places_list]
           }
         )}
    end
  end

  def handle_event("remove_place", %{"location_id" => location_id}, socket) do
    async_saved_places = socket.assigns.saved_places
    saved_places = async_saved_places.result

    updated_places =
      Enum.reject(saved_places, fn p -> p.location_id == location_id end)

    if socket.assigns[:current_user] do
      # TODO: remove place from user's saved places
      # TODO: if place has no users, then remove place in DB
      IO.puts(
        "remove place from user's saved places, and if there's place has no users, then remove place in DB"
      )
    end

    {:noreply,
     assign(socket, saved_places: %AsyncResult{async_saved_places | result: updated_places})}
  end

  def handle_event("set_main_weather", %{"location_id" => location_id}, socket) do
    place =
      Enum.find(socket.assigns.saved_places.result, fn p -> p.location_id == location_id end)

    send(self(), {:set_main_weather, place})
    {:noreply, socket}
  end

  def saved_places(assigns) do
    case assigns.saved_places do
      %AsyncResult{} ->
        ~H"""
        <.async_result :let={places} assign={@saved_places}>
          <:loading>Loading saved places...</:loading>
          <:failed :let={reason}><%= reason %></:failed>

          <%= if places !== [] do %>
            <%= places |> Enum.with_index |> Enum.map(fn({place, index}) -> %>
              <.place_card id={"placeCard-#{index}"} place={place} myself={@myself} />
            <% end) %>
          <% else %>
            <div class="flex justify-center items-center rounded-xl bg-red-dark py-3.5 px-4">
              <h2 class="text-2xl font-bold">No saved places</h2>
            </div>
          <% end %>
        </.async_result>
        """

        # [] ->
        #   ~H"""
        #   <div class="flex justify-center items-center rounded-xl bg-red-dark py-3.5 px-4">
        #     <h2 class="text-2xl font-bold">No saved places</h2>
        #   </div>
        #   """

        # places when is_list(places) ->
        #   ~H"""
        #   <div id="savedPlaces" class="flex flex-col space-y-3">
        #     <%= @saved_places |> Enum.with_index |> Enum.map(fn({place, index}) -> %>
        #       <.place_card id={"placeCard-#{index}"} place={place} myself={@myself} />
        #     <% end) %>
        #   </div>
        #   """
    end

    # ~H"""
    # <div id="savedPlaces" class="flex flex-col space-y-3">
    #   <%= if @saved_places == [] do %>
    #     <div class="flex justify-center items-center rounded-xl bg-red-dark py-3.5 px-4">
    #       <h2 class="text-2xl font-bold">No saved places</h2>
    #     </div>
    #   <% else %>
    #     <%= @saved_places |> Enum.map(fn place -> %>
    #       <.place_card place={place} myself={@myself} />
    #     <% end) %>
    #   <% end %>
    # </div>
    # """
  end

  def place_card(assigns) do
    ~H"""
    <div
      id={@id}
      phx-target={@myself}
      phx-click="set_main_weather"
      phx-value-location_id={@place.location_id}
      class="flex justify-between rounded-xl bg-red-dark py-3.5 px-4 cursor-pointer"
    >
      <div class="flex flex-col">
        <h2 class="text-2xl font-bold leading-none"><%= @place.name %></h2>
        <h3 class="font-semibold pb-4"><%= @place.weather.current.description.text %></h3>
        <button
          class="cursor-pointer text-red-light text-left h-6 w-6"
          phx-target={@myself}
          phx-click="remove_place"
          phx-value-location_id={@place.location_id}
        >
          <.icon_trash />
        </button>
      </div>
      <div class="flex flex-col justify-between items-end">
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
      <form phx-submit="search_places" phx-change="set_search" phx-target={@myself}>
        <div class="inline-flex items-center justify-between w-full h-10 rounded-xl bg-red-dark text-red-light py-2 pl-2">
          <div class="relative w-full">
            <input
              type="text"
              name="name"
              value={@search}
              phx-debounce="300"
              placeholder="Search for a city or place"
              autocomplete="off"
              class="w-full bg-transparent text-white placeholder:text-red-light pl-2 pr-8"
            />
            <%= if @search !== "" do %>
              <span
                phx-click="clear_search"
                phx-target={@myself}
                class="absolute right-0 top-0 h-full w-8 bg-red-dark flex place-content-center cursor-pointer"
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

  defp get_item_from_search_results(item_id, socket) do
    Enum.find(socket.assigns[:search_results], fn result ->
      result.id == String.to_integer(item_id)
    end)
  end
end
