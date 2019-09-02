defmodule Properties.ShapeFile do
  use Ecto.Schema
  import Ecto.Query

  @primary_key {:gid, :id, autogenerate: true}
  schema "shapefiles" do
    field :taxkey, :string
    field :geom_point, Geo.PostGIS.Geometry
    field :geom, Geo.PostGIS.Geometry
  end

  def list(x_min, y_min, x_max, y_max, zoning) do
    query =
    from(s in "mitchells_material_view",
      where: fragment("? && ST_MakeEnvelope(?, ?, ?, ?)", s.geom, ^x_min, ^y_min, ^x_max, ^y_max) and s.nonunique_plot == 0,
      select: %{geo_json: s.geo_json, assessment: %{last_assessment_land: s.last_assessment_land, lot_area: s.lot_area, tax_key: s.tax_key, zoning: s.zoning}},
      limit: 1000
    )

    query = if is_nil(zoning) || zoning == "" do
      query
    else
      from(s in query, where: s.zoning == ^zoning)
    end

    Properties.Repo.all(query)
  end

  def list_shapefiles_with_change_in_absolute_assessment(x_min, y_min, x_max, y_max) do
    from(s in "change_in_assessment_material_view",
      where: fragment("? && ST_MakeEnvelope(?, ?, ?, ?)", s.geom, ^x_min, ^y_min, ^x_max, ^y_max),
      select: %{geo_json: s.geo_json, assessment: %{assessment_2018: s."2018_total", assessment_2019: s."2019_total", absolute_change: s.absolute_assessment_change}}
    )
    |> Properties.Repo.all()
  end

  def list_shapefiles_with_change_in_percent_assessment(x_min, y_min, x_max, y_max) do
    from(s in "change_in_assessment_material_view",
      where: fragment("? && ST_MakeEnvelope(?, ?, ?, ?)", s.geom, ^x_min, ^y_min, ^x_max, ^y_max),
      select: %{geo_json: s.geo_json, assessment: %{tax_key: s.tax_key, assessment_2018: s."2018_total", assessment_2019: s."2019_total", percent_change: s.percent_assessment_change}}
    )
    |> Properties.Repo.all()
  end

  def get_by_tax_key(tax_key) do
    results = from(s in Properties.ShapeFile,
      where: s.taxkey == ^tax_key, limit: 1
    )
    case Properties.Repo.all(results) do
      [] -> nil
      [result] -> result
      list -> List.first(list)
    end
  end
end
