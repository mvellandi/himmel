defmodule HimmelWeb.MainLive do
  use HimmelWeb, :live_component

  def render(assigns) do
    ~H"""
    <div
      id="main"
      class={"#{if @screen == :main, do: "flex", else: "hidden md:flex"} flex-col gap-3 w-full md:max-w-[400px] lg:min-w-[450px] xl:max-w-[450px] 2xl:max-w=[520px]"}
    >
      <%!-- CURRENT --%>
      <div class="self-center justify-self-center w-full ">
        <div class="flex justify-between w-full">
          <%!-- <%= if length(parent.places) > 1 && "this isn't the first place" do %> --%>
          <button>P</button>
          <%!-- <% end %> --%>
          <div class="flex flex-col items-center pt-16 pb-12">
            <h1 class="text-4xl"><%= @data.place %></h1>
            <h2 class="text-8xl py-1 font-extralight">
              <%= @data.temperature %>
              <span class="relative"><span class="absolute">&deg;</span></span>
            </h2>
            <h3 class="text-2xl"><%= @data.description %></h3>
            <div class="flex justify-between gap-5 text-2xl">
              <h4>H: <%= @data.high %>&deg;</h4>
              <h4>L: <%= @data.low %>&deg;</h4>
            </div>
          </div>
          <%!-- <%= if length(parent.places) > 1 && "this isn't the last place" do %> --%>
          <button>N</button>
          <%!-- <% end %> --%>
        </div>
      </div>
      <%!-- TODAY --%>
      <div class="relative flex gap-7 rounded-xl p-4 bg-red-dark overflow-x-auto whitespace-nowrap scrollbar-hide">
        <%!-- HOUR COLUMNS --%>
        <.hours hours={@data.hours} />
      </div>
      <%!-- 10-DAYS --%>
      <div class="flex flex-col rounded-xl pt-2 pb-4 px-4 bg-red-dark">
        <h3 class="uppercase text-red-medium text-[1.1rem] mb-4">Icon 10-Day Forecast</h3>
        <%!-- DAY ROWS --%>
        <div class="space-y-5">
          <.days days={@data.days} />
        </div>
      </div>
    </div>
    """
  end

  def hours_data do
    numbered_hours = Enum.concat([11..23, 0..9])
    ["Now" | Enum.map(numbered_hours, &to_string/1)]
  end

  def hours(assigns) do
    ~H"""
    <%= for hour <- @hours do %>
      <div class="flex flex-col items-center gap-2">
        <h3 class="text-xl"><%= hour %></h3>
        <span>Icon</span>
        <span class="text-2xl">98</span>
      </div>
    <% end %>
    """
  end

  def days_data do
    ["Today", "Wed", "Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed", "Thu"]
  end

  def days(assigns) do
    ~H"""
    <%= for day <- @days do %>
      <%!-- <div class="flex justify-between text-2xl"> --%>
      <div class="grid grid-cols-4 text-2xl">
        <h4><%= day %></h4>
        <span class="justify-self-end">Icon</span>
        <span class="justify-self-end">82</span>
        <span class="justify-self-end">98</span>
      </div>
    <% end %>
    """
  end
end
