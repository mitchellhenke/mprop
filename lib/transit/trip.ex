defmodule Transit.Trip do
  defstruct [:id, :route_id, :service_id, :headsign, :direction_id, :block_id, :shape_id, :stop_times]

  def preload_stop_time_stops(trip) do
    stop_times = Enum.map(trip.stop_times, fn(stop_time) ->
      stop = ConCache.get(:transit_cache, "stops_#{stop_time.stop_id}")
      %{stop_time | stop: stop}
    end)

    %{trip | stop_times: stop_times}
  end
end
