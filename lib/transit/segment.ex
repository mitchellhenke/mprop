defmodule Transit.Segment do
  alias Properties.Repo
  import Ecto.Query

  alias Transit.{Trip}

  defstruct [
    :route_id,
    :trip_headsign,
    :speed_mph,
    :geo_json,
    :shape_pt_sequence,
    :shape_id,
    :trip_id,
    :stop_id,
    :stop_name,
    :arrival_time,
    :time_lag,
    :last_shape_sequence
  ]

  @stops_map %{
    # DOWNTOWN TO INTERMODAL, East
    {"12", 0} => ["1064", "7711", "943", "874", "1501", "1749"],
    # 92ND AND HAMILTON, West
    {"12", 1} => ["1749", "410", "792", "811", "943", "7711", "1064"],
    # BAYSHORE, North
    {"14", 0} => ["1162", "9112", "5128", "2151", "891", "64", "4474", "4488", "7754"],
    # SOUTHRIDGE, South
    {"14", 1} => ["7754", "4526", "4539", "405", "410", "2066", "1093", "1162"],
    # OZAUKEE COUNTY EXP, North
    {"143", 0} => ["381", "3057", "764", "744", "8348", "2399", "6682", "2752", "2756", "2754", "2796", "2755"],
    # DOWNTOWN MILWAUKEE, South
    {"143", 1} => ["2755", "2796", "2754", "2756", "2752", "6683", "8069", "8420", "623", "7805", "3055", "5527"],
    # BAYSHORE, North
    {"15", 0} => ["482", "1271", "1286", "1301", "1315", "722", "727", "736", "1243", "6064", "7754"],
    # CHICAGO/DREXEL, South
    {"15", 1} => ["7754", "1027", "6026", "632", "641", "2776", "1427", "1439", "1454", "1469", "1544", "482"],
    # 1ST-MITCHELL, East
    {"17", 0} => ["7530", "1489", "2060", "1211", "2777"],
    # CANAL-ROUNDHOUSE, West
    {"17", 1} => ["2777", "1073", "2158", "7931", "7530"],
    # SILVER SPRING, North
    {"19", 0} => ["1924", "7795", "2124", "2140", "334", "337", "1958", "1797", "1976", "6074", "7717"],
    # COLLEGE, South
    {"19", 1} => ["7717", "1846", "1868", "4347", "1886", "286", "289", "2077", "2093", "7720", "1924"],
    # UWM, East
    {"21", 0} => ["7723", "2186", "2203", "2216", "2227", "3644", "3672", "2536"],
    # MAYFAIR, West
    {"21", 1} => ["2536", "3672", "3668", "3682", "3693", "3705", "3721", "7723"],
  }

  def get_segments(_date_time) do
    date = ~D[2019-12-13]
    time = ~T[17:00:00.0]

    # t.route_id, t.trip_headsign, t.direction_id, t.shape_id
    route_trips = Transit.routes_top_two(date)
                  |> Enum.filter(&(&1.route_id != "137" && &1.route_id != "219" && !String.starts_with?(&1.route_id, "RR")))

    Enum.map(route_trips, fn(route_trip = %{route_id: route_id, trip_headsign: headsign, direction_id: direction, shape_id: shape_id}) ->
      stop_ids = Map.get(@stops_map, {route_id, direction})
      if stop_ids do
        trip = get_slowest_trip_for_hour(route_id, headsign, direction, shape_id, time)
        if trip do
          get_stuff(stop_ids, trip.trip_id, date, trip.start_time)
        end
      end
    end)
    |> Enum.reject(&(is_nil(&1)))
    |> List.flatten()
  end

  def get_slowest_trip_for_hour(route_id, trip_headsign, direction_id, shape_id, time) do
    interval = Transit.time_to_interval(time)
    from(t in Trip, where: t.route_id == ^route_id and t.trip_headsign == ^trip_headsign
      and t.direction_id == ^direction_id and t.shape_id == ^shape_id and t.start_time <= ^interval and
      t.end_time >= ^interval,
      order_by: [desc: t.length_seconds],
      limit: 1
    )
    |> Repo.one
  end

  def get_stuff(stop_ids, trip_id, date, start_time) do
    stop_id_query =
      Enum.map(1..Enum.count(stop_ids), &"$#{&1 + 3}")
      |> Enum.join(", ")

    {:ok, result} =
      Repo.query(
        """
        select *,
        ST_AsGeoJson(ST_MakeLine(ARRAY(select geom_point from gtfs.shapes sh where sh.shape_pt_sequence >= s.last_shape_sequence AND sh.shape_pt_sequence <= s.shape_pt_sequence AND sh.shape_id = s.shape_id order by sh.shape_pt_sequence))) as geo_json,
        ((ST_Length(ST_MakeLine(ARRAY(select geom_point from gtfs.shapes sh where sh.shape_pt_sequence >= s.last_shape_sequence AND sh.shape_pt_sequence <= s.shape_pt_sequence AND sh.shape_id = s.shape_id order by sh.shape_pt_sequence))) * 69) * 60 / (time_lag)) as speed_mph
        from(
        select sh.shape_pt_sequence, t.trip_headsign, t.route_id, sh.shape_id, st.trip_id, s.stop_id, s.stop_name, st.arrival_time, extract(epoch FROM st.arrival_time)/60 - lag(extract(epoch from st.arrival_time)/60, 1) OVER (partition by t.trip_id ORDER BY st.stop_sequence) as time_lag, lag(sh.shape_pt_sequence) OVER (partition by t.trip_id order by sh.shape_pt_sequence) as last_shape_sequence
        from gtfs.stop_times st
        JOIN gtfs.trips t on t.trip_id = st.trip_id
        JOIN gtfs.stops s on s.stop_id = st.stop_id
        JOIN gtfs.routes r on r.route_id =  t.route_id
        JOIN gtfs.calendar_dates cd on cd.service_id = t.service_id
        CROSS JOIN LATERAL (SELECT shape_pt_sequence, shape_id, shape_pt_lat, shape_pt_lon from gtfs.shapes sh where t.shape_id = sh.shape_id order by sh.geom_point <-> s.geom_point limit 1) as sh
        WHERE (
          (t.trip_id = $1 AND
          cd.date = $2 AND
          t.start_time = $3 AND
          s.stop_id IN (#{stop_id_query})
          )
        )
        order by (SELECT st2.arrival_time from gtfs.stop_times st2 where st2.trip_id = st.trip_id order by st2.stop_sequence limit 1), st.stop_sequence) s;
        """,
        [trip_id, date, start_time] ++ stop_ids
      )

    columns = Enum.map(result.columns, &String.to_atom(&1))

    Enum.map(result.rows, fn row ->
      map =
        Enum.zip(columns, row)
        |> Enum.into(%{})
        |> Map.update!(:geo_json, fn geo_json ->
          if geo_json != nil do
            Jason.decode!(geo_json)
          else
            geo_json
          end
        end)

      struct(__MODULE__, map)
    end)
    |> Enum.filter(&(&1.geo_json != nil))
  end
end
