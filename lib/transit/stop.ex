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
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:stop_id, :stop_name, :stop_lat, :stop_lon, :zone_id, :stop_url, :stop_desc, :timepoint])
    |> validate_required([:stop_id, :stop_name, :stop_lat, :stop_lon])
  end

  def get_nearest(point, radius_meters, date, time) do
    interval = Transit.time_to_interval(time)
    {:ok, result} =
      Repo.query(
        """
        select DISTINCT ON (t.route_id, t.direction_id) t.trip_headsign, t.direction_id, s.stop_id,
        s.stop_name, geom_point::geography <-> $1::geography as distance,
        t.route_id from gtfs.stops s
        JOIN gtfs.stop_times st on st.stop_id = s.stop_id
        JOIN gtfs.trips t on t.trip_id = st.trip_id
        JOIN gtfs.calendar_dates cd on cd.service_id = t.service_id
        WHERE cd.date = $2 AND
        ST_DWithin(s.geom_point::geography, $3::geography, $4) AND st.arrival_time > $5
        AND st.arrival_time < ($5 + interval '1 hour');
        """,
        [point, date, point, radius_meters, interval]
      )

    columns = Enum.map(result.columns, &String.to_atom(&1))

    Enum.map(result.rows, fn row ->
      Enum.zip(columns, row)
      |> Enum.into(%{})
    end)
  end
end
