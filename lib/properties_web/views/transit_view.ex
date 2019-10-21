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

  def human_readable_time(time) do
    if time.hour < 12 || (time.hour == 12 && time.minute == 0) do
      "#{zeroed_int2(time.hour)}:#{zeroed_int2(time.minute)} AM"
    else
      "#{zeroed_int2(rem(time.hour, 12))}:#{zeroed_int2(time.minute)} PM"
    end
  end

  def zeroed_int2(int) when int >= 10, do: Integer.to_string(int)
  def zeroed_int2(int), do: <<?0, Integer.to_string(int)::1-bytes>>

  def percent_difference(fastest, slowest) do
    (slowest - fastest) / fastest
    |> Kernel.*(100)
    |> round()
  end
end
