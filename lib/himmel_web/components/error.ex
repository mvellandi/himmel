defmodule HimmelWeb.Components.ApplicationError do
  use HimmelWeb, :component

  def application_error(assigns) do
    ~H"""
    <%!-- <div class={"#{if @screen == :error, do: "flex", else: "hidden md:flex"} flex-col gap-3 w-full md:max-w-[400px] lg:min-w-[450px] xl:max-w-[450px] 2xl:max-w=[520px]"}> --%>
    <div class="pt-40 flex-col gap-3 text-center w-full md:max-w-[400px] lg:min-w-[450px] xl:max-w-[450px] 2xl:max-w=[520px]">
      <h2 class="text-white text-5xl font-bold">Sorry!</h2>
      <div class="text-white font-light text-3xl pt-12 flex flex-col gap-6">
        <p><%= @error.reason %></p>
        <p><%= @error.advisory %></p>
      </div>
    </div>
    """
  end
end
