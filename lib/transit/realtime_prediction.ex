defmodule Transit.RealtimePrediction do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "gtfs"
  @primary_key false
  schema "rt_vehicle_predictions" do
    field(:timestamp, :utc_datetime)
    field(:prediction_timestamp, :utc_datetime)
    field(:vehicle_id, :string)
    field(:route_id, :string)
    field(:trip_id, :string)
    field(:stop_id, :string)
    field(:block_id, :string)
    field(:dist_from_stop, :float)
    field(:delay, :boolean)
  end

  def changeset(model, params) do
    model
    |> cast(params, [
      :timestamp,
      :prediction_timestamp,
      :vehicle_id,
      :route_id,
      :trip_id,
      :stop_id,
      :block_id,
      :dist_from_stop,
      :delay
    ])
    |> validate_required([
      :timestamp,
      :prediction_timestamp,
      :vehicle_id,
      :route_id,
      :trip_id,
      :stop_id,
      :block_id,
      :dist_from_stop,
      :delay
    ])
    |> Ecto.Changeset.unique_constraint(:timestamp,
      name: "rt_vehicle_predictions_timestamp_vehicle_id_index"
    )
  end
end
