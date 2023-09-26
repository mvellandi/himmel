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
              <h4>L: <%= @data.low %>&deg;</h4>
              <h4>H: <%= @data.high %>&deg;</h4>
            </div>
          </div>
          <%!-- <%= if length(parent.places) > 1 && "this isn't the last place" do %> --%>
          <button>N</button>
          <%!-- <% end %> --%>
        </div>
      </div>
      <%!-- TODAY --%>
      <div class="relative flex gap-2 rounded-xl p-4 bg-red-dark overflow-x-auto whitespace-nowrap hour-scrollbar">
        <%!-- HOUR COLUMNS --%>
        <.hours hours={@data.hours} />
      </div>
      <%!-- 10-DAYS --%>
      <div class="flex flex-col rounded-xl pt-2 pb-4 px-4 bg-red-dark">
        <h3 class="uppercase text-red-medium text-[1.1rem]">Icon 10-Day Forecast</h3>
        <%!-- DAY ROWS --%>
        <.days days={@data.days} />
      </div>
    </div>
    """
  end

  def hours(assigns) do
    ~H"""
    <%= for hour <- @hours do %>
      <div class="flex flex-col items-center">
        <h3 class="text-xl"><%= hour["hour"] %></h3>
        <div class="h-12 w-12"><img src={hour["description"]["image"]} /></div>
        <span class="text-2xl"><%= hour["temperature"] %></span>
      </div>
    <% end %>
    """
  end

  def days(assigns) do
    ~H"""
    <%= for day <- @days do %>
      <%!-- <div class="flex justify-between text-2xl"> --%>
      <div class="grid grid-cols-4 text-2xl">
        <div class="self-center"><h4><%= day["weekday"] %></h4></div>
        <div class="justify-self-center h-14 w-14"><img src={day["description"]["image"]} /></div>
        <div class="self-center justify-self-center"><span class="justify-self-end"><%= day["temperature"]["low"] %></span></div>
        <div class="self-center justify-self-center"><span class="justify-self-end"><%= day["temperature"]["high"] %></span></div>
      </div>
    <% end %>
    """
  end
end
