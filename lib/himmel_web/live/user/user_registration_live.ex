defmodule HimmelWeb.UserRegistrationLive do
  use HimmelWeb, :live_view

  alias Himmel.Accounts
  alias Himmel.Accounts.User

  def mount(_params, _session, socket) do
    # TODO: Get pin code from environment variable
    secret_pin = Application.get_env(:himmel, :registration_pin)

    socket =
      socket
      |> assign(
        secret_pin: secret_pin,
        pin: "",
        show_registration_form: false,
        shake: false
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm pt-28">
      <.header class="text-center pb-10">
        You found the secret registration page!
        <:subtitle>
          Already registered?
          <.link navigate={~p"/user/log_in"} class="font-bold text-brand underline">
            Sign in here
          </.link>
        </:subtitle>
      </.header>

      <form
        :if={!@show_registration_form}
        for="pin"
        id="pin_form"
        phx-submit="submit_pin"
        phx-change="set_pin"
        class={@shake && "shake"}
      >
        <div class="flex flex-col items-center h-16 gap-6">
          <input
            type="text"
            name="pin"
            value={@pin}
            phx-debounce="300"
            placeholder="pin code"
            autocomplete="off"
            class="text-center text-4xl w-52 text-white placeholder:text-primary-medium p-4 rounded-xl bg-primary-dark placeholder:focus:text-transparent"
          />
          <button class="text-xl w-32 p-3 rounded-xl outline-none border-2 border-primary-light bg-secondary-dark">
            Submit
          </button>
        </div>
      </form>

      <.simple_form
        :if={@show_registration_form}
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/user/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:email]} type="email" label="Email" class="p-4" required />
        <.input field={@form[:password]} type="password" label="Password" required />

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("set_pin", %{"pin" => pin}, socket) do
    {:noreply, assign(socket, pin: pin)}
  end

  def handle_event("submit_pin", %{"pin" => pin}, socket) do
    if pin == socket.assigns.secret_pin do
      changeset = Accounts.change_user_registration(%User{})

      socket =
        socket
        |> assign(
          trigger_submit: false,
          check_errors: false,
          show_registration_form: true
        )
        |> assign_form(changeset)

      {:noreply, assign(socket, temporary_assigns: [form: nil])}
    else
      Process.send_after(self(), :reset_shake, 500)
      {:noreply, assign(socket, :shake, true)}
    end
  end

  def handle_info(:reset_shake, socket) do
    {:noreply, assign(socket, :shake, false)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/user/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
