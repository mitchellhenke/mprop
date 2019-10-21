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
            |> Enum.map(fn(trip_id) ->
              ConCache.get(:transit_cache, "trips_#{trip_id}")
            end)
            |> Enum.sort_by(fn(trip) ->
              List.first(trip.stop_times).departure_time
            end)

    render conn, "trips.html", route: route, trips: trips, date: date
  end

  def route_headsign_shape(conn, params) do
    route_id = Map.fetch!(params, "id")
    date = Map.get(params, "date", Date.utc_today)
    route = ConCache.get(:transit_cache, "routes_#{route_id}")
    trips = ConCache.get(:transit_cache, "trips_by_route_date_#{route_id}_#{date}")
            |> Enum.map(fn(trip_id) ->
              ConCache.get(:transit_cache, "trips_#{trip_id}")
            end)

    groups = Enum.group_by(trips, fn(trip) ->
      {trip.headsign, trip.shape_id}
    end)
    |> Enum.sort_by(fn({{_headsign, _shape_id}, trips}) ->
      Enum.count(trips) * -1
    end)
    |> Enum.take(2)

    render conn, "route_headsign_shape.html", groups: groups, route: route, date: date
  end

  def stop_times_comparison(conn, params) do
    route_id = Map.fetch!(params, "id")
    date = Map.get(params, "date", Date.utc_today)
    _route = ConCache.get(:transit_cache, "routes_#{route_id}")
    trips = ConCache.get(:transit_cache, "trips_by_route_date_#{route_id}_#{date}")
            |> Enum.map(fn(trip_id) ->
              ConCache.get(:transit_cache, "trips_#{trip_id}")
            end)

    headsign = Map.get(params, "headsign")
    shape_id = Map.get(params, "shape_id")

    trips = get_trips(trips, headsign, shape_id)
            |> Enum.map(fn(trip) ->
              Transit.Trip.preload_stop_time_stops(trip)
            end)
            |> Enum.sort_by(fn(trip) ->
              Transit.calculate_time_diff(List.first(trip.stop_times).departure_time, List.last(trip.stop_times).arrival_time)
            end)

    fastest_trip = List.first(trips)
    slowest_trip = List.last(trips)

    starting_stop_id = Map.get(params, "starting_stop_id", List.first(slowest_trip.stop_times).stop_id)

    start_fastest = Enum.find(fastest_trip.stop_times, &(&1.stop_id == starting_stop_id))
    start_slowest = Enum.find(slowest_trip.stop_times, &(&1.stop_id == starting_stop_id))

    stop_times = Enum.map(fastest_trip.stop_times, fn(stop_time) ->
      stop_time_slowest = Enum.find(slowest_trip.stop_times, &(&1.stop_id == stop_time.stop_id))

      diff_fastest = Transit.calculate_time_diff(stop_time.arrival_time, start_fastest.arrival_time)
      diff_slowest = Transit.calculate_time_diff(stop_time_slowest.arrival_time, start_slowest.arrival_time)

      Map.put(stop_time, :diff, diff_fastest)
      |> Map.put(:diff_100, diff_slowest)
    end)

    fastest_trip = %{fastest_trip | stop_times: stop_times}

    render conn, "stop_times_comparison.html", date: date, slowest_trip: slowest_trip, fastest_trip: fastest_trip
  end

  def dashboard(conn, params) do
    date = Map.get(params, "date", Date.utc_today)
    data = ConCache.get_or_store(:transit_cache, "dashboard-#{date}", fn ->
      routes = ConCache.get(:transit_cache, "all_routes")
               |> Enum.filter(&(&1.id != "137" && &1.id != "219"))

      data = Enum.map(routes, fn(route) ->
        Task.async(fn -> get_slowest_and_fastest_trips_for_route(route.id, date) end)
      end)
      |> Enum.map(fn(task) ->
        Task.await(task)
      end)

    end)
    render conn, "dashboard.html", data: data, date: date
  end

  def get_slowest_and_fastest_trips(trips, headsign, shape_id) do
    trips = get_trips(trips, headsign, shape_id)
            |> Enum.map(fn(trip) ->
              Transit.Trip.preload_stop_time_stops(trip)
            end)
            |> Enum.sort_by(fn(trip) ->
              Transit.calculate_time_diff(List.first(trip.stop_times).departure_time, List.last(trip.stop_times).arrival_time)
            end)

    fastest_trip = List.first(trips)
    slowest_trip = List.last(trips)

    starting_stop_id = List.first(slowest_trip.stop_times).stop_id

    start_fastest = Enum.find(fastest_trip.stop_times, &(&1.stop_id == starting_stop_id))
    start_slowest = Enum.find(slowest_trip.stop_times, &(&1.stop_id == starting_stop_id))

    stop_times = Enum.map(fastest_trip.stop_times, fn(stop_time) ->
      stop_time_slowest = Enum.find(slowest_trip.stop_times, &(&1.stop_id == stop_time.stop_id))

      diff_fastest = Transit.calculate_time_diff(stop_time.arrival_time, start_fastest.arrival_time)
      diff_slowest = Transit.calculate_time_diff(stop_time_slowest.arrival_time, start_slowest.arrival_time)

      Map.put(stop_time, :diff, diff_fastest)
      |> Map.put(:diff_100, diff_slowest)
    end)

    fastest_trip = %{fastest_trip | stop_times: stop_times}

    {slowest_trip, fastest_trip}
  end

  def get_slowest_and_fastest_trips_for_route(route_id, date) do
    _route = ConCache.get(:transit_cache, "routes_#{route_id}")
    trips = ConCache.get(:transit_cache, "trips_by_route_date_#{route_id}_#{date}")
            |> Enum.map(fn(trip_id) ->
              ConCache.get(:transit_cache, "trips_#{trip_id}")
            end)
    [{headsign1, shape_id1}, {headsign2, shape_id2}] = get_top_2_headsign_shape_ids(trips)

    {slowest1, fastest1} = get_slowest_and_fastest_trips(trips, headsign1, shape_id1)
    {slowest2, fastest2} = get_slowest_and_fastest_trips(trips, headsign2, shape_id2)

    {{slowest1, fastest1}, {slowest2, fastest2}}
  end

  def get_top_2_headsign_shape_ids(trips) do
    Enum.group_by(trips, fn(trip) ->
      {trip.headsign, trip.shape_id}
    end)
    |> Enum.sort_by(fn({{_headsign, _shape_id}, trips}) ->
      Enum.count(trips) * -1
    end)
    |> Enum.take(2)
    |> Enum.map(fn({{headsign, shape_id}, _trips}) ->
      {headsign, shape_id}
    end)
  end

  def get_trips(trips, nil, nil) do
    {_, trips} = Enum.group_by(trips, fn(trip) ->
      {trip.headsign, trip.shape_id}
    end)
    |> Enum.sort_by(fn({{_headsign, _shape_id}, trips}) ->
      Enum.count(trips)
    end)
    |> List.last()

    trips
  end

  def get_trips(trips, headsign, shape_id) do
    Enum.filter(trips, fn(trip) ->
      trip.headsign == headsign && trip.shape_id == shape_id
    end)
  end
end