defmodule Transit do
  @moduledoc """
  Documentation for Transit.
  """
  alias Transit.{CalendarDate, Route, Stop, StopTime, Trip}

  def read_text_files(directory) do
    routes =
      Path.join(directory, "routes.txt")
      |> File.stream!()
      |> text_to_routes()

    trips =
      Path.join(directory, "trips.txt")
      |> File.stream!()
      |> text_to_trips()

    stop_map =
      Path.join(directory, "stops.txt")
      |> File.stream!()
      |> text_to_stops()

    {stop_times, stop_times_map} =
      Path.join(directory, "stop_times.txt")
      |> File.stream!()
      |> text_to_stop_times()


    trips = Enum.map(trips, fn(trip) ->
      stop_times = Map.fetch!(stop_times_map, trip.id)
                   |> Enum.sort_by(&(&1.stop_sequence))

      %{trip | stop_times: stop_times}
    end)

    {routes, trips, stop_map, stop_times}
  end

  # 0 route_id
  # 1 agency_id
  # 2 route_short_name
  # 3 route_long_name
  # 4 route_desc
  # 5 route_type
  # 6 route_url
  # 7 route_color
  # 8 route_text_color
  def text_to_routes(stream) do
    Stream.drop(stream, 1)
    |> Stream.map(fn row ->
      values = String.trim(row)
        |> String.split(",")

      %Route{
        id: Enum.at(values, 0) |> String.trim(),
        short_name: Enum.at(values, 2) |> String.trim(),
        long_name: Enum.at(values, 3) |> String.trim(),
        description: Enum.at(values, 4) |> String.trim(),
        type: Enum.at(values, 5) |> String.trim(),
        url: Enum.at(values, 6) |> String.trim(),
        color: Enum.at(values, 7) |> String.trim(),
        text_color: Enum.at(values, 8) |> String.trim()
      }
    end)
    |> Enum.to_list()
  end

  # 0 route_id
  # 1 service_id
  # 2 trip_id
  # 3 trip_headsign
  # 4 direction_id
  # 5 block_id
  # 6 shape_id
  # defstruct [:id, :route_id, :service_id, :headsign, :direction_id, :block_id, :shape_id]
  def text_to_trips(stream) do
    Stream.drop(stream, 1)
    |> Stream.map(fn row ->
      values = String.trim(row)
        |> String.split(",")

      %Trip{
        id: Enum.at(values, 2) |> String.trim(),
        route_id: Enum.at(values, 0) |> String.trim(),
        service_id: Enum.at(values, 1) |> String.trim(),
        headsign: Enum.at(values, 3) |> String.trim(),
        direction_id: Enum.at(values, 4) |> String.trim(),
        block_id: Enum.at(values, 5) |> String.trim(),
        shape_id: Enum.at(values, 6) |> String.trim(),
      }
    end)
    |> Enum.to_list()
  end

  # 0 stop_id
  # 1 stop_code
  # 2 stop_name
  # 3 stop_desc
  # 4 stop_lat
  # 5 stop_lon
  # 6 zone_id
  # 7 stop_url
  # 8 timepoint
  # defstruct [:id, :code, :name, :description, :latitude, :longitude, :zone_id, :url, :timepoint]
  def text_to_stops(stream) do
    Stream.drop(stream, 1)
    |> Enum.reduce(%{}, fn(row, map) ->
      values = String.trim(row)
        |> String.split(",")

      stop = %Stop{
        id: Enum.at(values, 0) |> String.trim(),
        code: Enum.at(values, 1) |> String.trim(),
        name: Enum.at(values, 2) |> String.trim(),
        description: Enum.at(values, 3) |> String.trim(),
        latitude: Enum.at(values, 4) |> String.trim(),
        longitude: Enum.at(values, 5) |> String.trim(),
        zone_id: Enum.at(values, 6) |> String.trim(),
        url: Enum.at(values, 7) |> String.trim(),
        timepoint: Enum.at(values, 8) |> String.trim()
      }

      Map.put(map, stop.id, stop)
    end)
  end

  # 0 trip_id
  # 1 arrival_time
  # 2 departure_time
  # 3 stop_id
  # 4 stop_sequence
  # 5 stop_headsign
  # 6 pickup_type
  # 7 drop_off_type
  # 8 timepoint
  # defstruct [
  #   :trip_id,
  #   :stop_id,
  #   :arrival_time,
  #   :departure_time,
  #   :sequence,
  #   :stop_headsign,
  #   :pickup_type,
  #   :drop_off_type,
  #   :timepoint
  # ]
  def text_to_stop_times(stream) do
    Stream.drop(stream, 1)
    |> Enum.reduce({[], %{}}, fn(row, {list, map_by_trip_id}) ->
      values = String.trim(row)
        |> String.split(",")

      stop_time = %StopTime{
        trip_id: Enum.at(values, 0) |> String.trim(),
        arrival_time: Enum.at(values, 1) |> String.trim() |> parse_time(),
        departure_time: Enum.at(values, 2) |> String.trim() |> parse_time(),
        stop_id: Enum.at(values, 3) |> String.trim(),
        stop_sequence: Enum.at(values, 4) |> String.trim() |> parse_stop_sequence(),
        stop_headsign: Enum.at(values, 5) |> String.trim(),
        pickup_type: Enum.at(values, 6) |> String.trim(),
        drop_off_type: Enum.at(values, 7) |> String.trim(),
        timepoint: Enum.at(values, 8) |> String.trim()
      }

      {[stop_time | list], Map.update(map_by_trip_id, stop_time.trip_id, [stop_time], fn(list) -> [stop_time | list] end)}
    end)
  end

  # 0 service_id
  # 1 date
  # 2 exception_type
  def text_to_calendar_dates(stream) do
    Stream.drop(stream, 1)
    |> Enum.map(fn(row) ->
      values = String.trim(row)
        |> String.split(",")

      # 20190606
      date = Enum.at(values, 1)
             |> String.trim()

      {year, rest} = String.split_at(date, 4)

      {month, day} = String.split_at(rest, 2)

      calendar_date = %CalendarDate{
        service_id: Enum.at(values, 0) |> String.trim(),
        date: Date.from_iso8601!("#{year}-#{month}-#{day}"),
        exception_type: Enum.at(values, 2) |> String.trim()
      }

      calendar_date
    end)
  end

  def parse_stop_sequence(sequence_number) do
    {integer, _} = Integer.parse(sequence_number)
    integer
  end

  def parse_time(time) when is_binary(time) do
    String.replace_prefix(time, "24", "00")
    |> String.replace_prefix("25", "01")
    |> String.replace_prefix("26", "02")
    |> String.replace_prefix("27", "03")
    |> String.replace_prefix("28", "04")
    |> Time.from_iso8601!()
  end

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
