# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :himmel,
  ecto_repos: [Himmel.Repo]

# Configures the endpoint
config :himmel, HimmelWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: HimmelWeb.ErrorHTML, json: HimmelWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Himmel.PubSub,
  live_view: [signing_salt: "7mK4Yrg/"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :himmel, Himmel.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.3",
  default: [
    args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
  ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# For time zone support
config :elixir, :time_zone_database, Tz.TimeZoneDatabase

# Configure CRON jobs
config :himmel, Himmel.Data.Scheduler,
  jobs: [
    # Every hour, update the weather for all saved places
    # {"0 * * * *", fn -> Himmel.Data.Scheduler.update_all_places_weather() end}
    {"0 * * * *", {Himmel.Data.Scheduler, :update_all_places_weather, []}}
  ]

# To determine the environment for conditional runtime code
config :himmel, :env, Mix.env()

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
