defmodule Himmel.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Cachex.Spec

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      HimmelWeb.Telemetry,
      # Start the Ecto repository
      Himmel.Repo,
      # Start Finch
      {Finch, name: Himmel.Finch},
      # Start the Endpoint (http/https)
      HimmelWeb.Endpoint,
      # Start the PubSub system and Tracker
      {Phoenix.PubSub, name: Himmel.PubSub},
      {Himmel.PlaceTracker, [pubsub_server: Himmel.PubSub]},
      # Start the Scheduler
      Himmel.Scheduler,
      # Start the Cache
      {Cachex, [name: :weather_cache, hooks: [hook(module: Himmel.CacheInfoHook)]]}
      # Start a worker by calling: Himmel.Worker.start_link(arg)
      # {Himmel.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Himmel.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HimmelWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
