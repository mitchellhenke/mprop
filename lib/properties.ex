defmodule Properties do
  use Application
  require Logger

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Properties.Repo, []),
      {ConCache, [name: :near_cache, ttl_check_interval: false]},
      # Start the endpoint when the application starts
      supervisor(PropertiesWeb.Endpoint, []),
      # Start your own worker by calling: Properties.Worker.start_link(arg1, arg2, arg3)
      # worker(Properties.Worker, [arg1, arg2, arg3]),
    ]
    Task.start(fn ->
      Logger.info("Filling near cache")
      adjacent = File.read!("nearest.erl_bin")  |> :erlang.binary_to_term()
      Enum.each(adjacent, fn({key, value}) ->
        ConCache.put(:near_cache, key, value)
      end)
      Logger.info("Done filling near cache")
    end)

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Properties.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PropertiesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
