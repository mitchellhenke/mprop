# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# General application configuration
config :properties,
  gtfs_import_connections: String.to_integer(System.get_env("GTFS_IMPORT_CONNECTIONS") || "2"),
  ecto_repos: [Properties.Repo]

config :properties,
  mcts_key: System.get_env("MCTS_KEY")

# Configures the endpoint
config :properties, PropertiesWeb.Endpoint,
  url: [host: "localhost"],
  http: [compress: true],
  secret_key_base: "5UUQajanov7iRJdsiR1T4JRYaniTXCTgBGtFXGmhvWJ20PHHQWCI2NR63B0664b4",
  render_errors: [view: PropertiesWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Properties.PubSub,
  live_view: [
    signing_salt: "TlvpvGFzpO3J55/oVoHzGhOeFfZHU4f1"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix,
  json_library: Jason,
  template_engines: [leex: Phoenix.LiveView.Engine]

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# config/config.exs
config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
