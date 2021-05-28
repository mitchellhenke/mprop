defmodule Transit do
  @moduledoc """
  Documentation for Transit.
  """
  require Logger
  import Ecto.Query, only: [from: 2]
  alias Transit.{CalendarDate, Feed, Route, Trip, Shape, ShapeGeom, Stop, StopTime}
  alias Properties.Repo

  @connections Application.compile_env!(:properties, :gtfs_import_connections)

  def calculate_time_diff(time1, time2) do
    seconds_in_12_hours = 12 * 60 * 60
    seconds_in_24_hours = 24 * 60 * 60

    diff =
      Time.diff(time1, time2, :second)
      |> abs()

    if diff > seconds_in_12_hours do
      (diff - seconds_in_24_hours)
      |> abs()
    else
      diff
    end
  end

  def percentile(values, 0) do
    Enum.sort(values)
    |> List.first()
  end

  def percentile(values, 100) do
    Enum.sort(values)
    |> List.last()
  end

  def percentile(values, percentile) when is_integer(percentile) do
    sorted_values = Enum.sort(values)

    i =
      Enum.count(sorted_values)
      |> Kernel.*(percentile)
      |> Kernel./(100)
      |> Kernel.+(0.5)

    integer =
      Float.floor(i)
      |> round()

    fractional = i - integer
    index = integer - 1

    (Enum.at(sorted_values, index) * (1.0 - fractional) +
       Enum.at(sorted_values, index + 1) * fractional)
    |> Float.round(0)
    |> round()
  end

  def download_and_import_gtfs(url, date) do
    with {:ok, feed} <- Feed.find_or_create(date),
         {:ok, directory} <- download_gtfs(url, feed),
         :ok <- import_gtfs(directory, feed) do
      :ok
    end
  end

  def download_gtfs(url, feed) do
    directory = "/tmp/gtfs_#{feed.date}"
    destination = "/tmp/gtfs_#{feed.date}/transit.zip"

    with :ok <- File.mkdir_p(directory),
         {:ok, 200, _headers, client_ref} <- :hackney.get(url, [], "", follow_redirect: true),
         {:ok, body} <- :hackney.body(client_ref),
         :ok <- File.write(destination, body),
         {:ok, _files} <- :zip.unzip(String.to_charlist(destination), cwd: directory) do
      {:ok, directory}
    else
      e ->
        Logger.error(inspect(e))
    end
  end

  def import_gtfs(directory, feed) do
    dates = load_calendar_dates(Path.join([directory, "calendar_dates.txt"]), feed)
    service_ids = Enum.map(dates, & &1.service_id)
    service_id_set = MapSet.new(service_ids)
    _routes = load_routes(Path.join([directory, "routes.txt"]), feed)
    trips = load_trips(Path.join([directory, "trips.txt"]), feed, service_id_set)
    trip_ids = Enum.map(trips, & &1.trip_id)
    trip_id_set = MapSet.new(trip_ids)
    stops = load_stops(Path.join([directory, "stops.txt"]), feed)
    load_stop_times(Path.join([directory, "stop_times.txt"]), feed, trip_id_set)

    load_shapes(Path.join([directory, "shapes.txt"]), feed)
    update_stop_and_shape_points(feed)
    update_trip_lengths(feed)
    update_trip_times(feed)
    update_stop_route_ids(stops, feed)
  end

  def load_calendar_dates(file, feed) do
    max_date = Date.add(feed.date, 10)

    File.stream!(file)
    |> Stream.drop(1)
    |> Stream.filter(fn row ->
      values =
        String.trim(row)
        |> String.split(",")

      # 20190606
      date =
        Enum.at(values, 1)
        |> String.trim()

      {year, rest} = String.split_at(date, 4)

      {month, day} = String.split_at(rest, 2)

      date = Date.from_iso8601!("#{year}-#{month}-#{day}")

      compare = Date.compare(date, max_date)
      compare == :lt || compare == :eq
    end)
    |> Task.async_stream(
      fn row ->
        values =
          String.trim(row)
          |> String.split(",")

        # 20190606
        date =
          Enum.at(values, 1)
          |> String.trim()

        {year, rest} = String.split_at(date, 4)

        {month, day} = String.split_at(rest, 2)

        params = %{
          service_id: Enum.at(values, 0) |> String.trim(),
          date: Date.from_iso8601!("#{year}-#{month}-#{day}"),
          exception_type: Enum.at(values, 2) |> String.trim(),
          feed_id: feed.id
        }

        CalendarDate.changeset(%CalendarDate{}, params)
        |> Repo.insert!()
      end,
      max_concurrency: @connections
    )
    |> Enum.map(fn {:ok, calendar_date} ->
      calendar_date
    end)
  end

  def load_routes(file, feed) do
    File.stream!(file)
    |> Stream.drop(1)
    |> Task.async_stream(
      fn row ->
        values =
          String.trim(row)
          |> String.split(",")

        params = %{
          route_id: Enum.at(values, 0) |> String.trim(),
          route_short_name: Enum.at(values, 2) |> String.trim(),
          route_long_name: Enum.at(values, 3) |> String.trim(),
          route_desc: Enum.at(values, 4) |> String.trim(),
          route_type: Enum.at(values, 5) |> String.trim(),
          route_url: Enum.at(values, 6) |> String.trim(),
          route_color: Enum.at(values, 7) |> String.trim(),
          route_text_color: Enum.at(values, 8) |> String.trim(),
          feed_id: feed.id
        }

        Route.changeset(%Route{}, params)
        |> Repo.insert!()
      end,
      max_concurrency: @connections
    )
    |> Enum.map(fn {:ok, route} ->
      route
    end)
  end

  def load_trips(file, feed, service_id_set) do
    File.stream!(file)
    |> Stream.drop(1)
    |> Stream.filter(fn row ->
      values =
        String.trim(row)
        |> String.split(",")

      service_id = Enum.at(values, 1) |> String.trim()

      MapSet.member?(service_id_set, service_id)
    end)
    |> Task.async_stream(
      fn row ->
        values =
          String.trim(row)
          |> String.split(",")

        params = %{
          trip_id: Enum.at(values, 2) |> String.trim(),
          route_id: Enum.at(values, 0) |> String.trim(),
          service_id: Enum.at(values, 1) |> String.trim(),
          trip_headsign: Enum.at(values, 3) |> String.trim(),
          direction_id: Enum.at(values, 4) |> String.trim(),
          block_id: Enum.at(values, 5) |> String.trim(),
          shape_id: Enum.at(values, 6) |> String.trim(),
          feed_id: feed.id
        }

        Trip.changeset(%Trip{}, params)
        |> Repo.insert!()
      end,
      max_concurrency: @connections
    )
    |> Enum.map(fn {:ok, trip} ->
      trip
    end)
  end

  def load_stops(file, feed) do
    File.stream!(file)
    |> Stream.drop(1)
    |> Task.async_stream(
      fn row ->
        values =
          String.trim(row)
          |> String.split(",")

        params = %{
          stop_id: Enum.at(values, 0) |> String.trim(),
          stop_code: Enum.at(values, 1) |> String.trim(),
          stop_name: Enum.at(values, 2) |> String.trim(),
          stop_desc: Enum.at(values, 3) |> String.trim(),
          stop_lat: Enum.at(values, 4) |> String.trim(),
          stop_lon: Enum.at(values, 5) |> String.trim(),
          zone_id: Enum.at(values, 6) |> String.trim(),
          stop_url: Enum.at(values, 7) |> String.trim(),
          timepoint: Enum.at(values, 8) |> String.trim(),
          feed_id: feed.id
        }

        Stop.changeset(%Stop{}, params)
        |> Repo.insert!()
      end,
      max_concurrency: @connections
    )
    |> Enum.map(fn {:ok, route} ->
      route
    end)
  end

  def load_stop_times(file, feed, trip_id_set) do
    File.stream!(file)
    |> Stream.drop(1)
    |> Stream.filter(fn row ->
      values =
        String.trim(row)
        |> String.split(",")

      trip_id = Enum.at(values, 0) |> String.trim()

      MapSet.member?(trip_id_set, trip_id)
    end)
    |> Stream.chunk_every(50)
    |> Task.async_stream(
      fn rows ->
        inserts =
          Enum.map(rows, fn row ->
            values =
              String.trim(row)
              |> String.split(",")

            timepoint =
              "#{Enum.at(values, 8)}"
              |> String.trim()

            params = %{
              trip_id: Enum.at(values, 0) |> String.trim(),
              arrival_time: Enum.at(values, 1) |> String.trim() |> parse_interval(),
              departure_time: Enum.at(values, 2) |> String.trim() |> parse_interval(),
              stop_id: Enum.at(values, 3) |> String.trim(),
              stop_sequence: Enum.at(values, 4) |> String.trim() |> parse_stop_sequence(),
              stop_headsign: Enum.at(values, 5) |> String.trim(),
              pickup_type: Enum.at(values, 6) |> String.trim(),
              drop_off_type: Enum.at(values, 7) |> String.trim(),
              timepoint: timepoint,
              feed_id: feed.id
            }

            cs = StopTime.changeset(%StopTime{}, params)
            true = cs.valid?
            cs.changes
          end)

        Repo.insert_all(StopTime, inserts)
      end,
      max_concurrency: @connections
    )
    |> Enum.map(fn {:ok, stop_time} ->
      stop_time
    end)
  end

  def load_shapes(file, feed) do
    File.stream!(file)
    |> Stream.drop(1)
    |> Task.async_stream(
      fn row ->
        values =
          String.trim(row)
          |> String.split(",")

        params = %{
          shape_id: Enum.at(values, 0) |> String.trim(),
          shape_pt_lat: Enum.at(values, 1) |> String.trim(),
          shape_pt_lon: Enum.at(values, 2) |> String.trim(),
          shape_pt_sequence: Enum.at(values, 3) |> String.trim(),
          feed_id: feed.id
        }

        Shape.changeset(%Shape{}, params)
        |> Repo.insert!()
      end,
      max_concurrency: @connections
    )
    |> Enum.map(fn {:ok, shapes} ->
      shapes
    end)
  end

  defp parse_stop_sequence(sequence) do
    {integer, _} = Integer.parse(sequence)
    integer
  end

  defp parse_interval(interval) do
    [hour, minute, second] =
      String.split(interval, ":")
      |> Enum.map(fn i ->
        {integer, _} = Integer.parse(i)
        integer
      end)

    seconds = hour * 60 * 60 + minute * 60 + second

    days = div(seconds, 24 * 60 * 60)
    seconds = rem(seconds, 24 * 60 * 60)
    %{months: 0, days: days, secs: seconds}
  end

  def time_to_interval(time) do
    seconds = time.second + time.minute * 60 + time.hour * 60 * 60
    days = div(seconds, 24 * 60 * 60)
    seconds = rem(seconds, 24 * 60 * 60)
    %Postgrex.Interval{months: 0, days: days, secs: seconds}
  end

  def update_stop_and_shape_points(feed) do
    {:ok, _result} =
      Repo.query(
        """
        update gtfs.stops set geom_point = ST_SetSRID(ST_MakePoint(stop_lon, stop_lat), 4326) where feed_id = $1
        """,
        [feed.id],
        timeout: :infinity
      )

    {:ok, _result} =
      Repo.query(
        """
        update gtfs.shapes set geom_point = ST_SetSRID(ST_MakePoint(shape_pt_lon, shape_pt_lat), 4326) where feed_id = $1
        """,
        [feed.id],
        timeout: :infinity
      )
  end

  def update_trip_lengths(feed) do
    feed_id = feed.id

    shape_ids =
      from(s in Transit.Shape,
        distinct: s.shape_id,
        select: s.shape_id,
        where: s.feed_id == ^feed_id
      )
      |> Repo.all()

    Enum.each(shape_ids, fn shape_id ->
      result =
        """
        SELECT ST_MakeLine(ARRAY(select geom_point from gtfs.shapes s2 where s2.shape_id = $1 AND s2.feed_id = $2 order by s2.shape_pt_sequence)),
        ST_Length(ST_MakeLine(ARRAY(select geom_point from gtfs.shapes s2 where s2.shape_id = $3 AND s2.feed_id = $4 order by s2.shape_pt_sequence))::geography)
        from gtfs.shapes s where s.shape_id = $5 AND s.feed_id = $6 limit 1;
        """
        |> Repo.query!([shape_id, feed_id, shape_id, feed_id, shape_id, feed_id])

      [[linestring, length_meters]] = result.rows

      params = %{
        shape_id: shape_id,
        feed_id: feed_id,
        length_meters: length_meters,
        geom_line: linestring
      }

      ShapeGeom.changeset(%ShapeGeom{}, params)
      |> Repo.insert!()
    end)
  end

  def update_trip_times(feed) do
    feed_id = feed.id

    trips =
      from(st in StopTime,
        select: %{
          trip_id: st.trip_id,
          start_time: min(st.arrival_time),
          end_time: max(st.arrival_time),
          time_seconds:
            fragment(
              "extract(epoch from MAX(?)) - extract(epoch from MIN(?))",
              st.arrival_time,
              st.arrival_time
            )
        },
        where: st.feed_id == ^feed_id,
        group_by: st.trip_id
      )
      |> Repo.all()

    Enum.each(trips, fn %{
                          trip_id: trip_id,
                          time_seconds: seconds,
                          start_time: start_time,
                          end_time: end_time
                        } ->
      from(t in Trip, where: t.trip_id == ^trip_id and t.feed_id == ^feed_id)
      |> Repo.update_all(
        set: [length_seconds: round(seconds), start_time: start_time, end_time: end_time]
      )
    end)
  end

  def update_stop_route_ids(stops, feed) do
    Enum.each(stops, fn stop ->
      Stop.update_route_ids(stop, feed)
    end)
  end

  def routes_top_two(date) do
    {:ok, result} =
      Repo.query(
        """
        select * from (select *, rank() OVER (PARTITION BY sub.route_id order by count desc) from
        (select t.route_id, t.trip_headsign, t.direction_id, t.shape_id, count(*) as count from gtfs.trips t
        join gtfs.calendar_dates cd on cd.service_id = t.service_id
        where cd.date = $1
        group by t.route_id, t.trip_headsign, t.direction_id, t.shape_id) sub) sub2 where rank <= 2;
        """,
        [date]
      )

    columns = Enum.map(result.columns, &String.to_atom(&1))

    Enum.map(result.rows, fn row ->
      Enum.zip(columns, row)
      |> Enum.into(%{})
    end)
  end
end
