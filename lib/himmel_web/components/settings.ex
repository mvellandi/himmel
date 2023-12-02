defmodule HimmelWeb.Components.Settings do
  use HimmelWeb, :component

  def settings(assigns) do
    ~H"""
    <div class={"#{if @screen == :settings, do: "flex", else: "hidden xl:flex"} flex-col gap-3 pt-[120px] w-full max-w-[400px]"}>
      <h1 class="text-4xl font-bold ml-4 text-shadow-surround">Settings</h1>
      <%!-- ACCOUNT --%>
      <div class="flex flex-col rounded-xl bg-primary-dark pt-3.5 pb-8 px-4 gap-1">
        <%!-- USE DETAILS > SUMMARY + content tags to show/hide elements --%>
        <div class="flex flex-col pl-2 pb-4">
          <h3 class="text-lg text-primary-light">Account</h3>
          <%= if assigns[:current_user] do %>
            <span class="inline-block mb-2">
              <%= assigns[:current_user].email %>
            </span>
          <% else %>
            <span class="inline-block mb-2">
              Not signed in
            </span>
            <p class="text-xl sm:text-lg py-4">
              To save your places and access weather from any device, register for a free account today.
            </p>
          <% end %>
        </div>

        <%= if assigns[:current_user] do %>
          <%!-- LOGGED IN --%>
          <details>
            <summary class="pb-6 list-none cursor-pointer">
              <span class="border border-primary-light px-4 py-2 rounded-xl text-primary-light">
                Manage Account / Sign Out
              </span>
            </summary>
            <div class="flex flex-col gap-4">
              <.link
                href={~p"/user/settings"}
                method="get"
                class="text-center rounded-xl py-4 px-10 text-lg text-primary-light leading-none border-2 border-primary-light"
              >
                Change Email / Password
              </.link>
              <.link
                href={~p"/user/log_out"}
                method="delete"
                class="text-center rounded-xl py-4 px-10 text-lg text-primary-light leading-none border-2 border-primary-light"
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
              class="text-center bg-secondary-dark rounded-xl py-4 px-10 text-lg leading-none border-2"
            >
              Register
            </.link>
            <.link
              href={~p"/user/log_in"}
              method="get"
              class="text-center rounded-xl py-4 px-10 text-lg text-primary-light leading-none border-2 border-primary-light"
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
