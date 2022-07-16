import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :properties, PropertiesWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :properties, Properties.Repo,
  username: "postgres",
  password: "postgres",
  database: "properties_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
