defmodule Transit.ShapeGeom do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "gtfs"
  @primary_key false
  schema "shape_geoms" do
    field(:shape_id, :string)
    field(:length_meters, :float)
    field(:geom_line, Geo.PostGIS.Geometry)

    belongs_to(:feed, Transit.Feed)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:feed_id, :shape_id, :length_meters, :geom_line])
    |> validate_required([:feed_id, :shape_id, :length_meters, :geom_line])
    |> assoc_constraint(:feed)
  end
end
