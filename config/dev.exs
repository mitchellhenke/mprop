import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :properties, PropertiesWeb.Endpoint,
  http: [port: 4000],
  https: [
    port: 4001,
    keyfile: "priv/dev.key",
    certfile: "priv/dev.crt"
  ],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]

# Watch static and templates for browser reloading.
config :properties, PropertiesWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/properties_web/views/.*(ex)$},
      ~r{lib/properties_web/templates/.*(eex)$},
      ~r{lib/properties_web/live/.*(ex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :properties, Properties.Repo,
  url: "postgres://localhost/milwaukee_properties",
  pool_size: 75,
  types: Properties.PostgresTypes
