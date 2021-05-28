defmodule Transit.Trip do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias Properties.Repo
  alias Transit.{ShapeGeom, Stop, StopTime}

  @schema_prefix "gtfs"
  @primary_key false
  schema "trips" do
    field(:trip_id, :string)
    field(:service_id, :string)
    field(:trip_headsign, :string)
    field(:direction_id, :integer)
    field(:block_id, :string)
    field(:length_seconds, :integer)
    field(:start_time, Interval)
    field(:end_time, Interval)

    field(:speed_mph, :time, virtual: true)

    belongs_to(:feed, Transit.Feed)

    belongs_to(:shape_geom, Transit.ShapeGeom,
      references: :shape_id,
      foreign_key: :shape_id,
      type: :string
    )

    belongs_to(:route, Transit.Route, references: :route_id, foreign_key: :route_id, type: :string)

    has_many(:stop_times, Transit.StopTime, references: :trip_id, foreign_key: :trip_id)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :feed_id,
      :trip_id,
      :route_id,
      :service_id,
      :trip_headsign,
      :direction_id,
      :block_id,
      :shape_id
    ])
    |> validate_required([
      :feed_id,
      :trip_id,
      :route_id,
      :service_id,
      :direction_id,
      :block_id,
      :shape_id
    ])
    |> assoc_constraint(:feed)
  end

  def get_by_route_and_date(route, date) do
    %{route_id: route_id, feed_id: feed_id} = route

    from(t in Transit.Trip,
      join: cd in Transit.CalendarDate,
      on: cd.service_id == t.service_id,
      where: cd.date == ^date and t.route_id == ^route_id and t.feed_id == ^feed_id
    )
    |> Repo.all()
  end

  def preload_stop_times([]), do: []

  def preload_stop_times(trips) do
    [%{feed_id: feed_id} | _] = trips
    stop_times = from(st in StopTime, where: st.feed_id == ^feed_id)
    stop = from(s in Stop, where: s.feed_id == ^feed_id)
    shape_geom = from(sg in ShapeGeom, where: sg.feed_id == ^feed_id)

    Repo.preload(trips, [[stop_times: {stop_times, stop: stop}], shape_geom: shape_geom])
    |> Enum.map(fn trip ->
      stop_times =
        Transit.StopTime.load_elixir_times(trip.stop_times)
        |> Enum.sort_by(& &1.stop_sequence)

      trip = %{trip | stop_times: stop_times}

      speed_mph =
        Float.round(trip.shape_geom.length_meters / 1609.34 * 60 * 60 / trip.length_seconds, 1)

      %{trip | speed_mph: speed_mph}
    end)
  end
end
