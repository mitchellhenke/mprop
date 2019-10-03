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
    :timepoint
  ]
end
