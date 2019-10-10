defmodule PropertiesWeb.TransitController do
  use PropertiesWeb, :controller

  def index(conn, _params) do
    routes = ConCache.get(:transit_cache, "all_routes")
    render conn, "index.html", routes: routes
  end

  def trips(conn, params) do
    route_id = Map.fetch!(params, "id")
    date = Map.get(params, "date", Date.utc_today)
    route = ConCache.get(:transit_cache, "routes_#{route_id}")
    trips = ConCache.get(:transit_cache, "trips_by_route_date_#{route_id}_#{date}")
            |> Enum.sort_by(fn(trip) ->
              List.first(trip.stop_times).departure_time
            end)

    render conn, "trips.html", route: route, trips: trips, date: date
  end

  def stop_times(conn, params) do
    trip_id = Map.fetch!(params, "id")
    date = Map.get(params, "date", Date.utc_today)
    trip = ConCache.get(:transit_cache, "trips_#{trip_id}")

    trips = ConCache.get(:transit_cache, "trips_by_route_date_#{trip.route_id}_#{date}")
            |> Enum.filter(&(&1.headsign == trip.headsign && &1.shape_id == trip.shape_id))

    render conn, "stop_times.html", trip: trip, trips: trips, stop_times: trip.stop_times
  end

  def stop_times_cumulative(conn, params) do
    trip_id = Map.fetch!(params, "id")
    trip = ConCache.get(:transit_cache, "trips_#{trip_id}")
    date = Map.get(params, "date", Date.utc_today)
    starting_stop_id = Map.get(params, "starting_stop_id", List.first(trip.stop_times).stop_id)

    trips = ConCache.get(:transit_cache, "trips_by_route_date_#{trip.route_id}_#{date}")
            |> Enum.filter(&(&1.headsign == trip.headsign && &1.shape_id == trip.shape_id))
            |> Enum.sort_by(fn(trip) ->
              Transit.calculate_time_diff(List.first(trip.stop_times).departure_time, List.last(trip.stop_times).arrival_time)
            end)

    percentile_25 = Enum.count(trips) * 0.10
                      |> round()

    percentile_25 = Enum.at(trips, percentile_25)

    start = Enum.find(trip.stop_times, &(&1.stop_id == starting_stop_id))
    start_25th = Enum.find(percentile_25.stop_times, &(&1.stop_id == starting_stop_id))
    stop_times = Enum.map(trip.stop_times, fn(stop_time) ->
      stop_time_25 = Enum.find(percentile_25.stop_times, &(&1.stop_id == stop_time.stop_id))

      diff = Transit.calculate_time_diff(stop_time.arrival_time, start.arrival_time)
      diff_25 = Transit.calculate_time_diff(stop_time_25.arrival_time, start_25th.arrival_time)

      Map.put(stop_time, :diff, diff)
      |> Map.put(:diff_25, diff_25)
    end)

    trip = %{trip | stop_times: stop_times}

    render conn, "stop_times_cumulative.html", trip: trip, trips: trips, stop_times: trip.stop_times
  end
end
