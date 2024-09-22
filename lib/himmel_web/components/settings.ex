defmodule HimmelWeb.Components.Settings do
  use HimmelWeb, :component

  def settings(assigns) do
    ~H"""
    <div class={"#{if @screen == :settings, do: "flex", else: "hidden xl:flex"} flex-col gap-3 pt-[120px] w-full lg:max-w-[400px]"}>
      <h1 class="screen-title">Settings</h1>
      <%!-- ACCOUNT --%>
      <div class="flex flex-col rounded-xl bg-primary-dark pt-3.5 pb-8 px-4 gap-1">
        <%!-- USE DETAILS > SUMMARY + content tags to show/hide elements --%>
        <div class="flex flex-col pb-4 pl-2">
          <h3 class="text-lg text-primary-light">Account</h3>
          <%= if assigns[:current_user] do %>
            <span class="inline-block mb-2">
              <%= assigns[:current_user].email %>
            </span>
          <% else %>
            <span class="inline-block mb-2">
              Not signed in
            </span>
            <p class="py-4 text-xl sm:text-lg">
              To save your places and access weather from any device, register for a free account today.
            </p>
          <% end %>
        </div>

        <%= if assigns[:current_user] do %>
          <%!-- LOGGED IN --%>
          <details>
            <summary class="pb-6 list-none cursor-pointer">
              <span class="px-4 py-2 border border-primary-light rounded-xl text-primary-light">
                Manage Account / Sign Out
              </span>
            </summary>
            <div class="flex flex-col gap-4">
              <%!-- DISABLED FOR DEMO APP --%>
              <%!-- <.link
                href={~p"/user/settings"}
                method="get"
                class="px-10 py-4 text-lg leading-none text-center border-2 rounded-xl text-primary-light border-primary-light"
              >
                Change Email / Password
              </.link> --%>
              <.link
                href={~p"/user/log_out"}
                method="delete"
                class="px-10 py-4 text-lg leading-none text-center border-2 rounded-xl text-primary-light border-primary-light"
              >
                Log out
              </.link>
            </div>
          </details>
        <% else %>
          <%!-- NOT LOGGED IN --%>
          <div class="flex flex-col gap-4">
            <.link
              href={~p"/user/log_in"}
              method="get"
              class="px-10 py-4 text-lg leading-none text-center border-2 bg-secondary-dark rounded-xl"
            >
              Register
            </.link>
            <.link
              href={~p"/user/log_in"}
              method="get"
              class="px-10 py-4 text-lg leading-none text-center border-2 rounded-xl text-primary-light border-primary-light"
            >
              Log in
            </.link>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
