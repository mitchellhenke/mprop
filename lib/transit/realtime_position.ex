defmodule Transit.RealtimePosition do
  use Ecto.Schema
  import Ecto.Query, only: [from: 1, from: 2]
  import Ecto.Changeset
  alias Properties.Repo

  @schema_prefix "gtfs"
  @primary_key false
  schema "rt_vehicle_positions" do
    field(:timestamp, :utc_datetime)
    field(:vehicle_id, :string)
    field(:latitude, :float)
    field(:longitude, :float)
    field(:bearing, :float)
    field(:progress, :integer)
    field(:trip_start_date, :date)
    field(:trip_id, :string)
    field(:block, :string)
    field(:stop_id, :string)
    field(:route_id, :string)
    field(:dist_along_route, :float)
    field(:dist_from_stop, :float)
  end

  def changeset(model, params) do
    model
    |> cast(params, [
      :timestamp,
      :vehicle_id,
      :latitude,
      :longitude,
      :trip_start_date,
      :trip_id,
      :bearing,
      :progress,
      :block,
      :stop_id,
      :route_id,
      :dist_along_route,
      :dist_from_stop
    ])
    |> validate_required([
      :timestamp,
      :vehicle_id,
      :latitude,
      :longitude,
      :trip_start_date,
      :route_id,
      :trip_id
    ])
    |> Ecto.Changeset.unique_constraint(:timestamp,
      name: "rt_vehicle_positions_timestamp_vehicle_id_index"
    )
  end

  def update_stop_id(timestamp, vehicle_id, trip_id, route_id, stop_id) do
    from(rt in Transit.RealtimePosition,
      where:
        rt.timestamp == ^timestamp and
          rt.trip_id == ^trip_id and rt.route_id == ^route_id and
          rt.vehicle_id == ^vehicle_id
    )
    |> Repo.update_all(set: [stop_id: stop_id])
  end
end
