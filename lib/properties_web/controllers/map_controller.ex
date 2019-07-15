defmodule PropertiesWeb.MapController do
  use PropertiesWeb, :controller

  plug PropertiesWeb.Plugs.Brotli
  plug PropertiesWeb.Plugs.Location when action in [:neighborhood]
  action_fallback PropertiesWeb.FallbackController


  def index(conn, _params) do
    render(conn, "index.html")
  end

  def geojson(conn, params) do
    {x_min, _} = params["southWestLongitude"]
            |> Float.parse()
    {y_min, _} = params["southWestLatitude"]
            |> Float.parse()
    {x_max, _} = params["northEastLongitude"]
            |> Float.parse()
    {y_max, _} = params["northEastLatitude"]
            |> Float.parse()

    layer = Map.get(params, "layer", "bike_lanes")
    # zoning = params["zoning"]
    # shapefiles = Properties.ShapeFile.list(x_min, y_min, x_max, y_max, zoning)
    cond do
      layer == "bike_lanes" ->
        bike_shapefiles = Properties.BikeShapeFile.list(x_min, y_min, x_max, y_max)
        off_street_path_shapefiles = Properties.OffStreetPathShapeFile.list(x_min, y_min, x_max, y_max)
        shapefiles = bike_shapefiles ++ off_street_path_shapefiles
        render(conn, "bike_index.json", shapefiles: shapefiles)
      layer == "bike_lanes" ->
        shapefiles = Properties.ShapeFile.list_shapefiles_with_lead_service_lines(x_min, y_min, x_max, y_max)
        render(conn, "lead_index.json", shapefiles: shapefiles)
      layer == "absolute_assessment_change" ->
        shapefiles = Properties.ShapeFile.list_shapefiles_with_change_in_absolute_assessment(x_min, y_min, x_max, y_max)
        render(conn, "absolute_change_index.json", shapefiles: shapefiles)
      layer == "percent_assessment_change" ->
        shapefiles = Properties.ShapeFile.list_shapefiles_with_change_in_percent_assessment(x_min, y_min, x_max, y_max)
        render(conn, "percent_change_index.json", shapefiles: shapefiles)
    end
    # shapefiles = Enum.map(shapefiles, fn(shapefile) ->
    #   cov = Properties.LandValue.adjacent_cov(shapefile.assessment)
    #   Map.put(shapefile, :adjacent_cov, cov)
    # end)

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
