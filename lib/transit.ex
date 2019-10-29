defmodule Transit do
  @moduledoc """
  Documentation for Transit.
  """
  require Logger

  def calculate_time_diff(time1, time2) do
    seconds_in_12_hours = 12*60*60
    seconds_in_24_hours = 24*60*60
    diff = Time.diff(time1, time2, :second)
           |> abs()

    if diff > seconds_in_12_hours do
      diff - seconds_in_24_hours
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
    i = Enum.count(sorted_values)
            |> Kernel.*(percentile)
            |> Kernel./(100)
            |> Kernel.+(0.5)

    integer = Float.floor(i)
              |> round()

    fractional = (i - integer)
    index = (integer - 1)

    (Enum.at(sorted_values, index) * (1.0 - fractional) +
      Enum.at(sorted_values, index + 1) * fractional)
      |> Float.round(0)
      |> round()
  end

  def download_gtfs do
    url = "http://kamino.mcts.org/gtfs/google_transit.zip"
    directory = "/tmp/gtfs"
    destination = "/tmp/gtfs/transit.zip"
    with :ok <- File.mkdir_p(directory),
         {:ok, 200, _headers, client_ref} <- :hackney.get(url, [], "", follow_redirect: true),
         {:ok, body} <- :hackney.body(client_ref),
         :ok <- File.write(destination, body),
         {:ok, _files} <- :zip.unzip(String.to_charlist(destination), [cwd: directory]) do
      IO.inspect("DONE")
    else
      e ->
        Logger.error(inspect(e))
    end
  end
end

# j = {_, trips, stops, _} = Transit.read_text_files("./gtfs/");1
# north_green_trips = trips |> Enum.filter(&(&1.headsign == "BAYSHORE - VIA OAKLAND-HOWELL" && &1.route_id == "GRE"));1
# south_green_trips = trips |> Enum.filter(&(&1.headsign == "AIRPORT - VIA OAKLAND-HOWELL" && &1.route_id == "GRE"));1
# s = Enum.map(south_green_trips, fn(trip) ->
#   trip.stop_times |> Enum.chunk_every(2, 1, :discard) |> Enum.map(fn([first, second]) ->
#     first_stop = Map.fetch!(stops, first.stop_id)
#     second_stop = Map.fetch!(stops, second.stop_id)
#     %{id: "#{first.stop_id}-#{second.stop_id}", name: "#{first_stop.name} to #{second_stop.name}", diff: Transit.calculate_time_diff(first.departure_time, second.departure_time)}
#   end)
# end) |> List.flatten() |> Enum.group_by(&(&1.id))
# median = fn(list) ->
#   sorted = Enum.sort(list)
#   length = Enum.count(sorted)
#   if rem(length, 2) == 1 do
#     Enum.at(sorted, div(length, 2))
#   else
#     0.5 * (Enum.at(sorted, div(length, 2)) + Enum.at(sorted, div(length, 2) - 1))
#   end
# end
# Enum.map(s, fn({k, v}) ->
#   median_time = median.(Enum.map(v, &(&1.diff)))
#   sum_above_median = Enum.filter(v, fn(v) -> v.diff > median_time end)
#                   |> Enum.map(fn(v) ->
#                     v.diff
#                   end) |> Enum.sum()
#   [%{name: name} | _] = v
#   {name, sum_above_median}
# end) |> Enum.sort_by(fn({_k, v}) -> v * -1 end) |> Enum.map(fn({k, v} ) -> "#{k} - #{v}" end)
