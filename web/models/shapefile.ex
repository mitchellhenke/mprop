defmodule Properties.ShapeFile do
  use Ecto.Schema
  import Ecto.Query

  @primary_key {:gid, :id, autogenerate: true}
  schema "shapefiles" do
    field :taxkey, :string
    field :geom_point, Geo.Point
  end
end
