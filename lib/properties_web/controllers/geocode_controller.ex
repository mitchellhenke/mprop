defmodule PropertiesWeb.GeocodeController do
  use PropertiesWeb, :controller
  alias Properties.Assessment

  def index(conn, params) do
    assessments = from(p in Assessment,
                   where: p.year == 2017,
                   limit: 10)
                   |> Assessment.with_joined_shapefile()
                   |> Assessment.filter_by_address(params["q"])
                   |> Assessment.select_latitude_longitude()
                   |> Properties.Repo.all()

    put_view(conn, PropertiesWeb.GeocodeView)
    |> render("index.json", assessments: assessments)
  end
end
