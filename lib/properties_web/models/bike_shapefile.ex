defmodule Properties.BikeShapeFile do
  use Ecto.Schema
  import Ecto.Query

  @primary_key {:gid, :id, autogenerate: true}
  schema "bike_lane_shapefiles" do
    field :geom, Geo.PostGIS.Geometry
    field :y_2018_fac, :string
  end

  def list(x_min, y_min, x_max, y_max) do
    query =
    from(s in Properties.BikeShapeFile,
      where: fragment("? && ST_MakeEnvelope(?, ?, ?, ?)", s.geom, ^x_min, ^y_min, ^x_max, ^y_max) and s.y_2018_fac in ["BIKE LANE", "BUFFERED BIKE LANE", "PROTECTED BIKE LANE"],
      select: %{geo_json: fragment("ST_AsGeoJSON(?)::jsonb", s.geom), gid: s.gid, type: s.y_2018_fac}
    )

    Properties.Repo.all(query)
  end
end
