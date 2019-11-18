defmodule Transit.Segment do
  alias Properties.Repo

  def get_stuff do
    shape_id = "19-SEP_15_0_118"
    trip_headsign = "BAYSHORE - VIA HOLTON-KINNICKINNIC"
    stop_ids = ["482", "1271", "1286", "1301", "1315", "722", "727", "736", "1243", "7754"]

    stop_id_query =
      Enum.map(1..Enum.count(stop_ids), &"$#{&1 + 2}")
      |> Enum.join(", ")

    date = ~D[2019-12-13]
    date_param_number = "$#{Enum.count(stop_ids) + 3}"

    {:ok, result} = Repo.query(
      """
      select sh.shape_pt_sequence, sh.shape_id, st.trip_id, s.stop_id, s.stop_name, st.arrival_time, extract(epoch FROM st.arrival_time)/60 - lag(extract(epoch from st.arrival_time)/60, 1) OVER (partition by t.trip_id ORDER BY st.stop_sequence) as time_lag, lag(sh.shape_pt_sequence) OVER (partition by t.trip_id order by sh.shape_pt_sequence) as last_shape_sequence from gtfs.stop_times st
      JOIN gtfs.trips t on t.trip_id = st.trip_id
      JOIN gtfs.stops s on s.stop_id = st.stop_id
      JOIN gtfs.routes r on r.route_id =  t.route_id
      JOIN gtfs.calendar_dates cd on cd.service_id = t.service_id
      CROSS JOIN LATERAL (SELECT shape_pt_sequence, shape_id, shape_pt_lat, shape_pt_lon from gtfs.shapes sh where t.shape_id = sh.shape_id order by ST_MakePoint(sh.shape_pt_lon, sh.shape_pt_lat) <-> ST_MakePoint(s.stop_lon, s.stop_lat) limit 1) as sh
      WHERE ((t.shape_id = $1 AND t.trip_headsign = $2 AND
      s.stop_id IN (#{stop_id_query}))) AND
      cd.date = #{date_param_number}
      order by (SELECT st2.arrival_time from gtfs.stop_times st2 where st2.trip_id = st.trip_id order by st2.stop_sequence limit 1), st.stop_sequence;
      """,
      [shape_id, trip_headsign] ++ stop_ids ++ [date]
    )

    Enum.map(result.rows, fn(row) ->
      Enum.zip(result.columns, row)
      |> Enum.into(%{})
    end)
  end
end
