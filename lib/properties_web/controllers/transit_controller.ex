defmodule PropertiesWeb.TransitController do
  use PropertiesWeb, :controller
  alias PropertiesWeb.TransitView
  alias Transit.{Route, Trip}

  def index(conn, params) do
    date = Map.get(params, "date", Date.utc_today())
    feed = Transit.Feed.get_first_before_date(date)
    routes = Route.list_all(feed)
    render(conn, "index.html", routes: routes)
  end

  def trips(conn, params) do
    route_id = Map.fetch!(params, "id")
    date = Map.get(params, "date", Date.utc_today())
    feed = Transit.Feed.get_first_before_date(date)
    route = Route.get_by_id!(feed, route_id)

    trips =
      Trip.get_by_route_and_date(route, date)
      |> Trip.preload_stop_times()
      |> Enum.sort_by(fn trip ->
        {trip.direction_id, List.first(trip.stop_times).elixir_departure_time}
      end)

    render(conn, "trips.html", route: route, trips: trips, date: date)
  end

  def route_headsign_shape(conn, params) do
    route_id = Map.fetch!(params, "id")
    date = Map.get(params, "date", Date.utc_today())
    feed = Transit.Feed.get_first_before_date(date)
    route = Route.get_by_id!(feed, route_id)
    trips = Trip.get_by_route_and_date(route, date)

    groups =
      Enum.group_by(trips, fn trip ->
        {trip.trip_headsign, trip.shape_id}
      end)
      |> Enum.sort_by(fn {{_headsign, _shape_id}, trips} ->
        Enum.count(trips) * -1
      end)
      |> Enum.take(2)

    render(conn, "route_headsign_shape.html", groups: groups, route: route, date: date)
  end

  def stop_times_comparison(conn, params) do
    route_id = Map.fetch!(params, "id")
    date = Map.get(params, "date", Date.utc_today())
    feed = Transit.Feed.get_first_before_date(date)
    route = Route.get_by_id!(feed, route_id)

    trips =
      Trip.get_by_route_and_date(route, date)
      |> Trip.preload_stop_times()

    headsign = Map.get(params, "headsign")
    shape_id = Map.get(params, "shape_id")

    trips =
      get_trips(trips, headsign, shape_id)
      |> Enum.sort_by(fn trip ->
        Transit.calculate_time_diff(
          List.first(trip.stop_times).elixir_departure_time,
          List.last(trip.stop_times).elixir_arrival_time
        )
      end)

    fastest_trip = List.first(trips)
    slowest_trip = List.last(trips)

    starting_stop_id =
      Map.get(params, "starting_stop_id", List.first(slowest_trip.stop_times).stop_id)

    start_fastest = Enum.find(fastest_trip.stop_times, &(&1.stop_id == starting_stop_id))
    start_slowest = Enum.find(slowest_trip.stop_times, &(&1.stop_id == starting_stop_id))

    stop_times =
      Enum.map(fastest_trip.stop_times, fn stop_time ->
        stop_time_slowest = Enum.find(slowest_trip.stop_times, &(&1.stop_id == stop_time.stop_id))

        diff_fastest =
          Transit.calculate_time_diff(
            stop_time.elixir_arrival_time,
            start_fastest.elixir_arrival_time
          )

        diff_slowest =
          Transit.calculate_time_diff(
            stop_time_slowest.elixir_arrival_time,
            start_slowest.elixir_arrival_time
          )

        Map.put(stop_time, :diff, diff_fastest)
        |> Map.put(:diff_100, diff_slowest)
      end)

    fastest_trip = %{fastest_trip | stop_times: stop_times}

    render(conn, "stop_times_comparison.html",
      date: date,
      slowest_trip: slowest_trip,
      fastest_trip: fastest_trip
    )
  end

  def dashboard(conn, params) do
    date = Map.get(params, "date", Date.utc_today())

    feed = Transit.Feed.get_first_before_date(date)

    data =
      ConCache.get_or_store(:transit_cache, "dashboard-#{date}", fn ->
        routes =
          Route.list_all(feed)
          |> Enum.filter(
            &(&1.route_id != "137" && &1.route_id != "219" && &1.route_id != "RS1" &&
                &1.route_id != "BRW" &&
                !String.starts_with?(&1.route_id, "RR"))
          )

        Enum.map(routes, fn route ->
          get_slowest_and_fastest_trips_for_route(feed, route, date)
        end)
        |> Enum.reject(&is_nil(&1))
        |> Enum.map(fn {{slowest1, fastest1, all1}, {slowest2, fastest2, all2}} ->
          median_speed_1 = median_trip_speed(all1)
          median_speed_2 = median_trip_speed(all2)

          {{slowest1, fastest1, median_speed_1, TransitView.graph(fastest1, all1)},
           {slowest2, fastest2, median_speed_2, TransitView.graph(fastest2, all2)}}
        end)
        |> Enum.sort_by(fn {{_slowest1, _fastest1, median1, _all1},
                            {_slowest2, _fastest2, median2, _all2}} ->
          Enum.min([
            median1,
            median2
          ])
        end)
      end)

    render(conn, "dashboard.html", data: data, date: date)
  end

  def get_slowest_and_fastest_trips(trips, headsign, shape_id) do
    trips =
      get_trips(trips, headsign, shape_id)
      |> Enum.sort_by(fn trip ->
        Transit.calculate_time_diff(
          List.first(trip.stop_times).elixir_departure_time,
          List.last(trip.stop_times).elixir_arrival_time
        )
      end)

    fastest_trip = List.first(trips)
    slowest_trip = List.last(trips)

    starting_stop_id = List.first(slowest_trip.stop_times).stop_id

    start_fastest = Enum.find(fastest_trip.stop_times, &(&1.stop_id == starting_stop_id))
    start_slowest = Enum.find(slowest_trip.stop_times, &(&1.stop_id == starting_stop_id))

    stop_times =
      Enum.map(fastest_trip.stop_times, fn stop_time ->
        stop_time_slowest = Enum.find(slowest_trip.stop_times, &(&1.stop_id == stop_time.stop_id))

        diff_fastest =
          Transit.calculate_time_diff(
            stop_time.elixir_arrival_time,
            start_fastest.elixir_arrival_time
          )

        diff_slowest =
          Transit.calculate_time_diff(
            stop_time_slowest.elixir_arrival_time,
            start_slowest.elixir_arrival_time
          )

        Map.put(stop_time, :diff, diff_fastest)
        |> Map.put(:diff_100, diff_slowest)
      end)

    fastest_trip = %{fastest_trip | stop_times: stop_times}

    {slowest_trip, fastest_trip, trips}
  end

  def get_slowest_and_fastest_trips_for_route(feed, route, date) do
    _route = Route.get_by_id!(feed, route.route_id)

    trips =
      Trip.get_by_route_and_date(route, date)
      |> Trip.preload_stop_times()

    case get_top_2_headsign_shape_ids(trips) do
      [{headsign1, shape_id1}, {headsign2, shape_id2}] ->
        {slowest1, fastest1, all1} = get_slowest_and_fastest_trips(trips, headsign1, shape_id1)
        {slowest2, fastest2, all2} = get_slowest_and_fastest_trips(trips, headsign2, shape_id2)

        {{slowest1, fastest1, all1}, {slowest2, fastest2, all2}}

      [] ->
        # IGNORE
        nil
    end
  end

  def get_top_2_headsign_shape_ids(trips) do
    Enum.group_by(trips, fn trip ->
      {trip.trip_headsign, trip.shape_id, trip.direction_id}
    end)
    |> Enum.sort_by(fn {{_headsign, _shape_id, _direction_id}, trips} ->
      Enum.count(trips) * -1
    end)
    |> Enum.take(2)
    |> Enum.sort_by(fn {{_headsign, _shape_id, direction_id}, _trips} ->
      direction_id
    end)
    |> Enum.map(fn {{headsign, shape_id, _direction_id}, _trips} ->
      {headsign, shape_id}
    end)
  end

  def get_trips(trips, nil, nil) do
    {_, trips} =
      Enum.group_by(trips, fn trip ->
        {trip.trip_headsign, trip.shape_id}
      end)
      |> Enum.sort_by(fn {{_headsign, _shape_id}, trips} ->
        Enum.count(trips)
      end)
      |> List.last()

    trips
  end

  def get_trips(trips, headsign, shape_id) do
    Enum.filter(trips, fn trip ->
      trip.trip_headsign == headsign && trip.shape_id == shape_id
    end)
  end

  defp median_trip_speed(trips) do
    trip_speeds =
      Enum.map(trips, fn trip ->
        trip.speed_mph
      end)
      |> Enum.sort()

    length = Enum.count(trip_speeds)

    if rem(length, 2) == 0 do
      first_speed = Enum.at(trip_speeds, div(length + 2, 2))
      second_speed = Enum.at(trip_speeds, div(length, 2))

      (first_speed + second_speed) / 2
    else
      Enum.at(trip_speeds, div(length + 1, 2))
    end
  end
end
