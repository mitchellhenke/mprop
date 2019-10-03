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

    with {:ok, pid} <- Supervisor.start_link(children, opts) do
      fill_cache()
      {:ok, pid}
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PropertiesWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def fill_cache do
    routes = Path.join("./data/gtfs/", "routes.txt")
    |> File.stream!()
    |> Transit.text_to_routes()

    ConCache.put(:transit_cache, "all_routes", routes)

    Enum.each(routes, fn(%{id: id} = route) ->
      ConCache.put(:transit_cache, "routes_#{id}", route)
    end)

    # {_stop_times, stop_times_map} =
    #   Path.join("./data/gtfs", "stop_times.txt")
    #   |> File.stream!()
    #   |> Transit.text_to_stop_times()

    stop_map =
      Path.join("./data/gtfs", "stops.txt")
      |> File.stream!()
      |> Transit.text_to_stops()

    calendar_dates = Path.join("./data/gtfs/", "calendar_dates.txt")
    |> File.stream!()
    |> Transit.text_to_calendar_dates()

    Enum.group_by(calendar_dates, fn(%{service_id: service_id}) -> service_id end)
    |> Enum.each(fn({service_id, calendar_dates}) ->
      ConCache.put(:transit_cache, "calendar_dates_#{service_id}", calendar_dates)
    end)

    Enum.group_by(calendar_dates, fn(%{date: date}) -> date end)
    |> Enum.each(fn({date, calendar_dates}) ->
      ConCache.put(:transit_cache, "calendar_dates_#{date}", calendar_dates)
    end)

    trips = Path.join("./data/gtfs/", "trips.txt")
    |> File.stream!()
    |> Transit.text_to_trips()
    |> Enum.map(fn(trip) ->
      # stop_times = Map.fetch!(stop_times_map, trip.id)
      #              |> Enum.sort_by(&(&1.stop_sequence))
      #              |> Enum.map(fn(stop_time) ->
      #                stop = Map.get(stop_map, stop_time.stop_id)
      #                %{stop_time | stop: stop}
      #              end)

      # %{trip | stop_times: stop_times}
      trip
    end)

    Enum.each(trips, fn(trip) ->
      ConCache.put(:transit_cache, "trips_#{trip.id}", trip)
    end)

    # a service is a set of trips
    Enum.group_by(trips, fn(%{route_id: route_id, service_id: service_id}) ->
      {route_id, service_id}
    end)
    |> Enum.each(fn({{route_id, service_id}, trips}) ->
      dates = ConCache.get(:transit_cache, "calendar_dates_#{service_id}")
      Enum.each(dates, fn(date) ->
        ConCache.update(:transit_cache, "trips_by_route_date_#{route_id}_#{date.date}", fn(current) ->
          case current do
            nil ->
              {:ok, MapSet.new(trips)}
            existing ->
              {:ok, MapSet.union(existing, MapSet.new(trips))}
          end
        end)
      end)
    end)
  end
end
