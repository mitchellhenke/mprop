defmodule Properties.ShapeFile do
  use Ecto.Schema

  @primary_key {:gid, :id, autogenerate: true}
  schema "shapefiles" do
    field :taxkey, :string
    field :geom_point, Geo.PostGIS.Geometry
  end
end
