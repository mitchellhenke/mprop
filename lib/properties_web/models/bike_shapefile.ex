defmodule Properties.BikeShapeFile do
  use Ecto.Schema
  import Ecto.Query

  @primary_key {:gid, :id, autogenerate: true}
  schema "bike_lane_shapefiles" do
    field :geom, Geo.PostGIS.Geometry
    field :fac_type, :string
  end

  def list(x_min, y_min, x_max, y_max) do
    query =
    from(s in Properties.BikeShapeFile,
      where: fragment("? && ST_MakeEnvelope(?, ?, ?, ?)", s.geom, ^x_min, ^y_min, ^x_max, ^y_max) and s.fac_type == "Bike Lane",
      select: %{geo_json: fragment("ST_AsGeoJSON(?)::jsonb", s.geom), gid: s.gid, type: s.fac_type}
    )

    Properties.Repo.all(query)
  end
end
