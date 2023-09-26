defmodule HimmelWeb.WeatherComponents do
  use Phoenix.Component

  attr :id, :string, required: true
  attr :data, :map, required: true

  def place_card(assigns) do
    ~H"""
    <div id={@id} class="flex justify-between items-center rounded-xl bg-red-dark py-3.5 px-4">
      <div class="flex flex-col">
        <h2 class="text-2xl font-bold leading-none"><%= @data.place %></h2>
        <h3 class="font-semibold"><%= @data.description %></h3>
        <h4 class="font-semibold text-red-light pt-6">DELETE</h4>
      </div>
      <div class="flex flex-col h-full justify-between items-end">
        <span class="text-5xl font-light leading-[0.9]"><%= @data.temperature %>&deg;</span>
        <div class="flex justify-end gap-5 font-semibold">
          <h4>L: <%= @data.high %>&deg;</h4>
          <h4>H: <%= @data.low %>&deg;</h4>
        </div>
      </div>
    </div>
    """
  end
end
