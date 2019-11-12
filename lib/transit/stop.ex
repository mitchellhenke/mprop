defmodule Transit.Stop do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "gtfs"
  @primary_key false
  schema "stops" do
    field :stop_id, :string
    field :stop_name, :string
    field :stop_lat, :float
    field :stop_lon, :float
    field :zone_id, :string
    field :stop_url, :string
    field :stop_desc, :string
    field :stop_code, :string
    field :timepoint, :string
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:stop_id, :stop_name, :stop_lat, :stop_lon, :zone_id, :stop_url, :stop_desc, :timepoint])
    |> validate_required([:stop_id, :stop_name, :stop_lat, :stop_lon])
  end
end
