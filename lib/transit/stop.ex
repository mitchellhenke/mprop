defmodule Transit.Stop do
  use Ecto.Schema

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
end
