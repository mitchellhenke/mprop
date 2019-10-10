defmodule Transit.StopTime do
  defstruct [
    :trip_id,
    :stop_id,
    :arrival_time,
    :departure_time,
    :stop_sequence,
    :stop_headsign,
    :stop,
    :pickup_type,
    :drop_off_type,
    :timepoint,
    :seconds_until_next_stop
  ]

  def seconds_between_stops(stop_times, stop_id_1, stop_id_2) do
    stop_time1 = Enum.find(stop_times, &(&1.stop_id == stop_id_1))
    stop_time2 = Enum.find(stop_times, &(&1.stop_id == stop_id_2))

    Time.diff(stop_time1.arrival_time, stop_time2.arrival_time, :second)
  end
end
