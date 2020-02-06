defmodule Transit.Stop do
  use Ecto.Schema
  import Ecto.Changeset
  alias Properties.Repo

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

    belongs_to :feed, Transit.Feed
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:feed_id, :stop_id, :stop_name, :stop_lat, :stop_lon, :zone_id, :stop_url, :stop_desc, :timepoint])
    |> validate_required([:feed_id, :stop_id, :stop_name, :stop_lat, :stop_lon])
    |> assoc_constraint(:feed)
  end

  def get_nearest(point, radius_meters, date, time, feed_id) do
    interval = Transit.time_to_interval(time)
    {:ok, result} =
      Repo.query(
        """
        select DISTINCT ON (t.route_id, t.direction_id) t.trip_headsign, t.direction_id, s.stop_id,
        s.stop_name, (ABS(ST_X(s.geom_point) - ST_X($1)) * 81228.4367802347 + ABS(ST_Y(s.geom_point) - ST_Y($1)) * 111320) as distance,
        t.route_id from gtfs.stops s
        JOIN gtfs.stop_times st on st.stop_id = s.stop_id AND st.feed_id = $3
        JOIN gtfs.trips t on t.trip_id = st.trip_id AND t.feed_id = $3
        JOIN gtfs.calendar_dates cd on cd.service_id = t.service_id AND cd.feed_id = $3
        WHERE cd.date = $2 AND s.feed_id = $3
        AND ST_DWithin(s.geom_point::geography, $1::geography, $4)
        AND (ABS(ST_X(s.geom_point) - ST_X($1)) * 81228.4367802347 + ABS(ST_Y(s.geom_point) - ST_Y($1)) * 111320) <= $4
        AND st.arrival_time > ($5 - interval '30 minutes')
        AND st.arrival_time < ($5 + interval '30 minutes');
        """,
        [point, date, feed_id, radius_meters, interval]
      )

    columns = Enum.map(result.columns, &String.to_atom(&1))

    Enum.map(result.rows, fn row ->
      Enum.zip(columns, row)
      |> Enum.into(%{})
    end)
  end
end
