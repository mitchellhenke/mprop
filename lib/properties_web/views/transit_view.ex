defmodule PropertiesWeb.TransitView do
  use PropertiesWeb, :view

  def time_for_percentile(trips, stop_time, percentile) do
    ConCache.get_or_store(:transit_cache, "stop_time_percentile_#{stop_time.trip_id}_#{stop_time.stop_id}_#{percentile}", fn ->
      times = Enum.map(trips, fn(trip) ->
        stop_time = Enum.find(trip.stop_times, &(&1.stop_id == stop_time.stop_id))
        if stop_time do
          stop_time.seconds_until_next_stop
        else
          nil
        end
      end)

      if Enum.all?(times, &(&1 == nil)) do
        nil
      else
        Transit.percentile(times, percentile)
      end
    end)
  end

  def seconds_to_human_readable(seconds) when is_integer(seconds) do
    minutes = div(seconds, 60)
    "#{minutes}m"
  end
end
