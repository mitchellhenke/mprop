defmodule PropertiesWeb.GeocodeController do
  use PropertiesWeb, :controller
  alias Properties.Assessment

  plug PropertiesWeb.Plugs.Brotli
  action_fallback PropertiesWeb.FallbackController


  def index(conn, params) do
    address_search_query = params["q"] || ""
    case Properties.AddressParser.parse(address_search_query) do
      {:ok, {address, score}} ->

        assessments = from(p in Assessment,
          where: p.year == 2017,
          limit: 10)
          |> Assessment.with_joined_shapefile()
          |> Assessment.filter_by_address(address)
          |> Assessment.select_latitude_longitude()
          |> Properties.Repo.all()

        put_view(conn, PropertiesWeb.GeocodeView)
        |> render("index.json", assessments: assessments, score: score)
      {:error, reason} ->
        {:error, reason}
    end
  end
end
