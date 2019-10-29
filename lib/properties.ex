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
      supervisor(Task.Supervisor, [[name: Properties.TaskSupervisor]]),
      supervisor(Properties.Repo, []),
      worker(Transit.RealtimeScraper, []),
      Supervisor.child_spec({ConCache, name: :near_cache, ttl_check_interval: false}, id: :con_cache_near_cache),
      Supervisor.child_spec({ConCache, name: :lead_service_render_cache, ttl_check_interval: false}, id: :con_cache_lead_service_render_cache),
      Supervisor.child_spec({ConCache, name: :transit_cache, ttl_check_interval: false}, id: :con_cache_transit_cache),
      # Start the endpoint when the application starts
      supervisor(PropertiesWeb.Endpoint, []),
      # Start your own worker by calling: Properties.Worker.start_link(arg1, arg2, arg3)
      # worker(Properties.Worker, [arg1, arg2, arg3]),
    ]


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
