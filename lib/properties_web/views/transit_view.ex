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

  def background_color(percent_difference1, percent_difference2 \\ 0) do
    diff = Enum.max([percent_difference1, percent_difference2])

    cond do
      diff >= 30 ->
        "rgba(255, 86, 72, 1.0)"
      diff >= 20 ->
        "rgba(214, 124, 92, 1.0)"
      diff >= 10 ->
        "rgba(219, 191, 112, 1.0)"
      true ->
        "rgba(148, 184, 154, 1.0)"
    end
  end

  def chart_color(percent_difference) do
    cond do
      is_nil(percent_difference) ->
        "rgba(255, 255, 255, 0.0)"
      percent_difference >= 30 ->
        "rgba(255, 86, 72, 0.9)"
      percent_difference  >= 20 ->
        "rgba(214, 124, 92, 0.9)"
      percent_difference  >= 10 ->
        "rgba(219, 191, 112, 0.9)"
      true ->
        "rgba(148, 184, 154, 0.9)"
    end
  end

  def graph(fastest, trips) do
    hour_map = Enum.reduce(0..23, %{}, fn(hour, map) ->
      hourly_maxes = Enum.filter(trips, fn(trip) ->
        List.first(trip.stop_times).departure_time.hour == hour
      end)
      |> Enum.map(&(&1.total_time))

      max = case hourly_maxes do
        [] ->
          nil
        hourly_maxes ->
          Enum.max(hourly_maxes)
      end

      chart_color = case max do
        nil ->
          chart_color(nil)
        max_duration ->
          percent_difference(fastest.total_time, max_duration)
          |> chart_color()
      end

      chart_height = cond do
        is_nil(max) -> "0%"
        true ->
          diff = percent_difference(fastest.total_time, max)
                 |> max(10)
          "#{round(diff / 50.0 * 100)}%"
      end


      Map.put(map, "#{hour}_color", chart_color)
      |> Map.put("#{hour}_height", chart_height)
    end)


    """
    background: linear-gradient(to bottom, #{Map.get(hour_map, "0_color")}, #{Map.get(hour_map, "0_color")}) no-repeat 0px bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "1_color")}, #{Map.get(hour_map, "1_color")}) no-repeat 4.16% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "2_color")}, #{Map.get(hour_map, "3_color")}) no-repeat 8.32% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "3_color")}, #{Map.get(hour_map, "3_color")}) no-repeat 12.48% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "4_color")}, #{Map.get(hour_map, "4_color")}) no-repeat 16.64% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "5_color")}, #{Map.get(hour_map, "5_color")}) no-repeat 20.8% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "6_color")}, #{Map.get(hour_map, "6_color")}) no-repeat 24.96% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "7_color")}, #{Map.get(hour_map, "7_color")}) no-repeat 29.12% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "8_color")}, #{Map.get(hour_map, "8_color")}) no-repeat 33.28% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "9_color")}, #{Map.get(hour_map, "9_color")}) no-repeat 37.44% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "10_color")}, #{Map.get(hour_map, "10_color")}) no-repeat 41.60% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "11_color")}, #{Map.get(hour_map, "11_color")}) no-repeat 45.76% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "12_color")}, #{Map.get(hour_map, "12_color")}) no-repeat 49.92% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "13_color")}, #{Map.get(hour_map, "13_color")}) no-repeat 54.08% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "14_color")}, #{Map.get(hour_map, "14_color")}) no-repeat 58.24% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "15_color")}, #{Map.get(hour_map, "15_color")}) no-repeat 62.40% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "16_color")}, #{Map.get(hour_map, "16_color")}) no-repeat 66.56% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "17_color")}, #{Map.get(hour_map, "17_color")}) no-repeat 70.72% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "18_color")}, #{Map.get(hour_map, "18_color")}) no-repeat 74.88% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "19_color")}, #{Map.get(hour_map, "19_color")}) no-repeat 79.04% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "20_color")}, #{Map.get(hour_map, "20_color")}) no-repeat 83.20% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "21_color")}, #{Map.get(hour_map, "21_color")}) no-repeat 87.36% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "22_color")}, #{Map.get(hour_map, "22_color")}) no-repeat 91.52% bottom,
      linear-gradient(to bottom, #{Map.get(hour_map, "23_color")}, #{Map.get(hour_map, "23_color")}) no-repeat 95.68% bottom;

    background-size: 4.16% #{Map.get(hour_map, "0_height")},
      4.16% #{Map.get(hour_map, "1_height")},
      4.16% #{Map.get(hour_map, "2_height")},
      4.16% #{Map.get(hour_map, "3_height")},
      4.16% #{Map.get(hour_map, "4_height")},
      4.16% #{Map.get(hour_map, "5_height")},
      4.16% #{Map.get(hour_map, "6_height")},
      4.16% #{Map.get(hour_map, "7_height")},
      4.16% #{Map.get(hour_map, "8_height")},
      4.16% #{Map.get(hour_map, "9_height")},
      4.16% #{Map.get(hour_map, "10_height")},
      4.16% #{Map.get(hour_map, "11_height")},
      4.16% #{Map.get(hour_map, "12_height")},
      4.16% #{Map.get(hour_map, "13_height")},
      4.16% #{Map.get(hour_map, "14_height")},
      4.16% #{Map.get(hour_map, "15_height")},
      4.16% #{Map.get(hour_map, "16_height")},
      4.16% #{Map.get(hour_map, "17_height")},
      4.16% #{Map.get(hour_map, "18_height")},
      4.16% #{Map.get(hour_map, "19_height")},
      4.16% #{Map.get(hour_map, "20_height")},
      4.16% #{Map.get(hour_map, "21_height")},
      4.16% #{Map.get(hour_map, "22_height")},
      4.16% #{Map.get(hour_map, "23_height")};
    """
  end
end
