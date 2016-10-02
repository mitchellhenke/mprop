defmodule Properties.PropertyController do
  use Properties.Web, :controller
  alias Properties.Property

  plug Properties.Plugs.Location

  def index(conn, params) do
    location = conn.assigns[:location]
    point = %Geo.Point{coordinates: {location.longitude, location.latitude}, srid: 4326}

    min_bathrooms = String.to_integer(params["minBathrooms"] || "0")
    max_bathrooms = String.to_integer(params["maxBathrooms"] || "0")
    min_bedrooms = String.to_integer(params["minBedrooms"] || "0")
    max_bedrooms = String.to_integer(params["maxBedrooms"] || "0")
    zipcode = params["zipcode"]
    land_use = params["land_use"]
    parking_type = params["parking_type"]
    properties = from(p in Property, limit: 40,
                      order_by: [desc: p.last_assessment_amount])
                 |> Property.within(point, location.radius_in_m)
                 |> Property.filter_by_bathrooms(min_bathrooms, max_bathrooms)
                 |> Property.filter_by_bedrooms(min_bedrooms, max_bedrooms)
                 |> Property.filter_by_zipcode(zipcode)
                 |> Property.filter_by_land_use(land_use)
                 |> Property.filter_by_parking_type(parking_type)
                 |> Repo.all
    render conn, "index.json", properties: properties
  end
end
