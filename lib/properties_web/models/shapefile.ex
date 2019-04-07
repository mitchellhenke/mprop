defmodule Properties.ShapeFile do
  use Ecto.Schema
  import Ecto.Query

  @primary_key {:gid, :id, autogenerate: true}
  schema "shapefiles" do
    field :taxkey, :string
    field :geom_point, Geo.PostGIS.Geometry
    field :geom, Geo.PostGIS.Geometry

    field :geo_json, :map, virtual: true
  end

  def list(x_min, y_min, x_max, y_max) do
    from(s in "mitchells_material_view",
      where: fragment("? && ST_MakeEnvelope(?, ?, ?, ?)", s.geom, ^x_min, ^y_min, ^x_max, ^y_max) and s.land_use != "8811",# and s.zoning == "RT4",
      select: %{geo_json: s.geo_json, assessment: %{last_assessment_land: s.last_assessment_land, lot_area: s.lot_area, tax_key: s.tax_key}})
      |> Properties.Repo.all
  end
end
