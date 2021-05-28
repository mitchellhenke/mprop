defmodule PropertiesWeb.MapController do
  use PropertiesWeb, :controller

  plug PropertiesWeb.Plugs.Brotli
  plug PropertiesWeb.Plugs.Location when action in [:neighborhood]
  action_fallback PropertiesWeb.FallbackController

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def neighborhood(conn, _params) do
    location = conn.assigns[:location]
    point = %Geo.Point{coordinates: {location.longitude, location.latitude}, srid: 4326}

    with {:ok, neighborhood} <- Properties.NeighborhoodShapeFile.find(point) do
      render(conn, "neighborhood_show.json", neighborhood: neighborhood)
    end
  end

  def neighborhood_random(conn, _params) do
    neighborhood = Properties.NeighborhoodShapeFile.random()
    render(conn, "neighborhood_show.json", neighborhood: neighborhood)
  end
end
