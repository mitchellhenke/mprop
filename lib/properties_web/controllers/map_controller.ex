defmodule PropertiesWeb.MapController do
  use PropertiesWeb, :controller

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

    # zoning = params["zoning"]
    # shapefiles = Properties.ShapeFile.list(x_min, y_min, x_max, y_max, zoning)
    shapefiles = Properties.ShapeFile.list_shapefiles_with_lead_service_lines(x_min, y_min, x_max, y_max)

    # shapefiles = Enum.map(shapefiles, fn(shapefile) ->
    #   cov = Properties.LandValue.adjacent_cov(shapefile.assessment)
    #   Map.put(shapefile, :adjacent_cov, cov)
    # end)

    render(conn, "lead_index.json", shapefiles: shapefiles)
  end
end
