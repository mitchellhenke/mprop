defmodule Properties.Mixfile do
  use Mix.Project

  def project do
    [
      app: :properties,
      version: "0.0.1",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      extra_applications: [:logger],
      mod: {Properties, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:plug_cowboy, "~> 2.2"},
      {:plug, "~> 1.10"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:geo, "~> 3.0"},
      {:geo_postgis, "~> 3.0"},
      {:csv, "~> 2.0"},
      {:corsica, "~> 1.0"},
      {:hackney, "~> 1.6"},
      {:ecto_sql, "~> 3.2"},
      {:postgrex, "~> 0.16.0"},
      {:jason, "~> 1.0"},
      {:nimble_parsec, "~> 0.5.1"},
      {:brotli, ">= 0.0.0"},
      {:con_cache, "~> 1.0"},
      {:phoenix_live_view, "~> 0.17.0"},
      {:nimble_csv, "~> 0.6.0"},
      {:tzdata, "~> 1.0"},
      {:redix, ">= 0.0.0"},
      {:castore, ">= 0.0.0"},
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end
end
