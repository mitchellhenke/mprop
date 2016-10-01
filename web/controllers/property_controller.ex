defmodule Properties.PropertyController do
  use Properties.Web, :controller
  alias Properties.Property

  plug Properties.Plugs.Location

  def index(conn, _params) do
    location = conn.assigns[:location]
    point = %Geo.Point{coordinates: {location.longitude, location.latitude}, srid: 4326}
    properties = from(p in Property, limit: 10)
                 |> Properties.Property.within(point, location.radius_in_m)
                 |> Properties.Property.order_by_nearest(point)
                 |> Repo.all
    render conn, "index.json", properties: properties
  end
end
