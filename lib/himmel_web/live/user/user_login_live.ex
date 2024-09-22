defmodule HimmelWeb.UserLoginLive do
  use HimmelWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm pt-28">
      <.header class="text-center pb-4">
        Try out Himmel
        <:subtitle>
          <span class="text-primary-dark font-bold">Email:</span> demo@himmel.com<br />
          <span class="text-primary-dark font-bold">Password:</span> weathertoday<br />
          <%!-- PREVIOUS REGISTRATION LINK --%>
          <%!-- <.link navigate={~p"/user/register"} class="text-xl font-bold text-brand underline">
            Register here
          </.link> --%>
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/user/log_in"} phx-update="ignore">
        <.input field={@form[:email]} type="email" label="Email" value="demo@himmel.com" required />
        <.input
          field={@form[:password]}
          type="password"
          label="Password"
          value="weathertoday"
          required
        />

        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" />
          <.link href={~p"/user/reset_password"} class="text-sm font-semibold">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with="Signing in..." class="w-full">
            Sign in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
