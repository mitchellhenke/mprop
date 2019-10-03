defmodule PropertiesWeb.TransitController do
  use PropertiesWeb, :controller

  def index(conn, _params) do
    routes = ConCache.get(:transit_cache, "all_routes")
    render conn, "index.html", routes: routes
  end

  def trips(conn, %{"id" => route_id}) do
    date = ~D[2019-07-09]
    route = ConCache.get(:transit_cache, "routes_#{route_id}")
    trips = ConCache.get(:transit_cache, "trips_by_route_date_#{route_id}_#{date}")

    render conn, "trips.html", route: route, trips: trips
  end

  def stop_times(conn, %{"id" => trip_id}) do
    trip = ConCache.get(:transit_cache, "trips_#{trip_id}")
    render conn, "stop_times.html", trip: trip, stop_times: trip.stop_times
  end
end
