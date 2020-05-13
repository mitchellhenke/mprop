defmodule PropertiesWeb.AssessmentController do
  use PropertiesWeb, :controller
  alias Properties.Assessment
  alias Properties.Sale
  plug PropertiesWeb.Plugs.Location

  def show(conn, %{"id" => id}) do
    query = if length(String.codepoints(id)) == 10 do
      from(a in Assessment, where: a.tax_key == ^id and a.year == 2020)
    else
      id = String.to_integer(id)
      from(a in Assessment, where: a.id == ^id)
    end
    assessment = query
                 |> Assessment.with_joined_shapefile()
                 |> Assessment.select_latitude_longitude()
                 |> Repo.one()
    key = assessment.tax_key
    other_assessments = from(a in Assessment, where: a.tax_key == ^key)
                        |> Repo.all
    sales = from(s in Sale, where: s.tax_key == ^key)
            |> Repo.all

    assessment = %{assessment | sales: sales, other_assessments: other_assessments}
    render(conn, "show.json", assessment: assessment)
  end

  def index(conn, params) do
    location = conn.assigns[:location]
    {point, radius} = if(location) do
      {%Geo.Point{coordinates: {location.longitude, location.latitude}, srid: 4326}, location.radius_in_m}
    else
      {nil, nil}
    end

    min_bathrooms = handle_maybe_integer(params["minBathrooms"])
    max_bathrooms = handle_maybe_integer(params["maxBathrooms"])
    min_bedrooms = handle_maybe_integer(params["minBedrooms"])
    max_bedrooms = handle_maybe_integer(params["maxBedrooms"])
    zipcode = params["zipcode"]
    land_use = params["land_use"]
    parking_type = params["parking_type"]
    number_units = params["number_units"]
    year = params["year"] || 2017
    assessments = from(p in Assessment,
                   where: p.year == ^year,
                   order_by: [desc: p.last_assessment_amount],
                   limit: 100)
                 |> Assessment.filter_greater_than(:bathrooms, min_bathrooms)
                 |> Assessment.filter_less_than(:bathrooms, max_bathrooms)
                 |> Assessment.filter_greater_than(:number_of_bedrooms, min_bedrooms)
                 |> Assessment.filter_less_than(:number_of_bedrooms, max_bedrooms)
                 |> Assessment.filter_by_zipcode(zipcode)
                 |> Assessment.maybe_filter_by(:land_use, land_use)
                 |> Assessment.maybe_filter_by(:parking_type, parking_type)
                 |> Assessment.maybe_filter_by(:number_units, number_units)
                 |> Assessment.with_joined_shapefile()
                 |> Assessment.select_latitude_longitude()
                 |> Assessment.maybe_within(point, radius)
                 |> Assessment.filter_by_address(params["textSearch"])
                 |> Repo.all

    render conn, "index.json", assessments: assessments
  end

  defp handle_maybe_integer(nil), do: nil
  defp handle_maybe_integer(binary) do
    case Integer.parse(binary) do
      {integer, _} -> integer
      _ -> nil
    end
  end
end
