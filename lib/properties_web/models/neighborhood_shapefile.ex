defmodule Properties.NeighborhoodShapeFile do
  use Ecto.Schema
  import Ecto.Query

  @primary_key {:gid, :id, autogenerate: true}
  schema "neighborhood_shapefiles" do
    field :geom, Geo.PostGIS.Geometry
    field :neighborhd, :string
  end

  def find(point) do
    {lng, lat} = point.coordinates
    neighborhood =
      from(s in Properties.NeighborhoodShapeFile,
        where: fragment("ST_Within(ST_SetSRID(ST_MakePoint(?, ?), ?), ?)", ^lng, ^lat, ^point.srid, s.geom),
        limit: 1
      )
      |> Properties.Repo.one

    if neighborhood do
      {:ok, neighborhood}
    else
      {:error, :not_found}
    end
  end
end
