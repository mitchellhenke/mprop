defmodule Transit.Trip do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias Properties.Repo

  @schema_prefix "gtfs"
  @primary_key false
  schema "trips" do
    field :trip_id, :string
    field :service_id, :string
    field :trip_headsign, :string
    field :direction_id, :integer
    field :block_id, :string
    field :shape_id, :string
    field :length_meters, :float
    field :length_seconds, :integer
    field :start_time, Interval
    field :end_time, Interval

    field :speed_mph, :time, virtual: true

    belongs_to :route, Transit.Route, references: :route_id, foreign_key: :route_id, type: :string
    has_many :stop_times, Transit.StopTime, references: :trip_id, foreign_key: :trip_id
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:trip_id, :route_id, :service_id, :trip_headsign, :direction_id, :block_id, :shape_id])
    |> validate_required([:trip_id, :route_id, :service_id, :trip_headsign, :direction_id, :block_id, :shape_id])
  end

  def get_by_route_id_and_date(route_id, date) do
    from(t in Transit.Trip,
      join: cd in Transit.CalendarDate, on: cd.service_id == t.service_id,
      where: cd.date == ^date and t.route_id == ^route_id
    )
    |> Repo.all()
  end

  def preload_stop_times(trips) do
    Repo.preload(trips, [stop_times: :stop])
    |> Enum.map(fn(trip) ->
      stop_times = Transit.StopTime.load_elixir_times(trip.stop_times)
                   |> Enum.sort_by(&(&1.stop_sequence))
      trip = %{trip | stop_times: stop_times}

      speed_mph = Float.round((trip.length_meters / 1609.34) * 60 * 60 / trip.length_seconds, 1)

      %{trip | speed_mph: speed_mph}
    end)
  end
end
