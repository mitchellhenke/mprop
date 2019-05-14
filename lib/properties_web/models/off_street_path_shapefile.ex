defmodule Properties.OffStreetPathShapeFile do
  use Ecto.Schema
  import Ecto.Query

  @primary_key {:gid, :id, autogenerate: true}
  schema "off_street_path_shapefiles" do
    field :geom, Geo.PostGIS.Geometry
    field :name, :string
    field :status, :string
  end

  def list(x_min, y_min, x_max, y_max) do
    query =
    from(s in Properties.OffStreetPathShapeFile,
      where: fragment("? && ST_MakeEnvelope(?, ?, ?, ?)", s.geom, ^x_min, ^y_min, ^x_max, ^y_max) and s.status == "Existing",
      select: %{geo_json: fragment("ST_AsGeoJSON(?)::jsonb", s.geom), gid: s.gid, type: "Trail"}
    )

    Properties.Repo.all(query)
  end
end
