defmodule Transit do
  @moduledoc """
  Documentation for Transit.
  """
  require Logger
  alias Transit.{CalendarDate, Route, Trip, Shape, Stop, StopTime}

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

  def import_gtfs(directory) do
    load_calendar_dates(Path.join([directory, "calendar_dates.txt"]))
    load_routes(Path.join([directory, "routes.txt"]))
    load_trips(Path.join([directory, "trips.txt"]))
    load_stops(Path.join([directory, "stops.txt"]))
    load_stop_times(Path.join([directory, "stop_times.txt"]))
    load_shapes(Path.join([directory, "shapes.txt"]))
  end

  def load_calendar_dates(file) do
    File.stream!(file)
    |> Stream.drop(1)
    |> Stream.each(fn(row) ->
      values = String.trim(row)
               |> String.split(",")

      # 20190606
      date = Enum.at(values, 1)
             |> String.trim()

      {year, rest} = String.split_at(date, 4)

      {month, day} = String.split_at(rest, 2)

      params = %{
        service_id: Enum.at(values, 0) |> String.trim(),
        date: Date.from_iso8601!("#{year}-#{month}-#{day}"),
        exception_type: Enum.at(values, 2) |> String.trim()
      }

      CalendarDate.changeset(%CalendarDate{},  params)
      |> Properties.Repo.insert()
    end)
    |> Enum.to_list()
  end

  def load_routes(file) do
    File.stream!(file)
    |> Stream.drop(1)
    |> Stream.each(fn(row) ->
      values = String.trim(row)
        |> String.split(",")

      params = %{
        route_id: Enum.at(values, 0) |> String.trim(),
        route_short_name: Enum.at(values, 2) |> String.trim(),
        route_long_name: Enum.at(values, 3) |> String.trim(),
        route_desc: Enum.at(values, 4) |> String.trim(),
        route_type: Enum.at(values, 5) |> String.trim(),
        route_url: Enum.at(values, 6) |> String.trim(),
        route_color: Enum.at(values, 7) |> String.trim(),
        route_text_color: Enum.at(values, 8) |> String.trim()
      }

      Route.changeset(%Route{},  params)
      |> Properties.Repo.insert()
    end)
    |> Enum.to_list()
  end

  def load_trips(file) do
    File.stream!(file)
    |> Stream.drop(1)
    |> Stream.each(fn(row) ->
      values = String.trim(row)
        |> String.split(",")

      params = %{
        trip_id: Enum.at(values, 2) |> String.trim(),
        route_id: Enum.at(values, 0) |> String.trim(),
        service_id: Enum.at(values, 1) |> String.trim(),
        trip_headsign: Enum.at(values, 3) |> String.trim(),
        direction_id: Enum.at(values, 4) |> String.trim(),
        block_id: Enum.at(values, 5) |> String.trim(),
        shape_id: Enum.at(values, 6) |> String.trim(),
      }

      {:ok, _} = Trip.changeset(%Trip{},  params)
                 |> Properties.Repo.insert()
    end)
    |> Enum.to_list()
  end

  def load_stops(file) do
    File.stream!(file)
    |> Stream.drop(1)
    |> Stream.each(fn(row) ->
      values = String.trim(row)
        |> String.split(",")

      params = %{
        stop_id: Enum.at(values, 0) |> String.trim(),
        stop_code: Enum.at(values, 1) |> String.trim(),
        stop_name: Enum.at(values, 2) |> String.trim(),
        stop_desc: Enum.at(values, 3) |> String.trim(),
        stop_lat: Enum.at(values, 4) |> String.trim(),
        stop_lon: Enum.at(values, 5) |> String.trim(),
        zone_id: Enum.at(values, 6) |> String.trim(),
        stop_url: Enum.at(values, 7) |> String.trim(),
        timepoint: Enum.at(values, 8) |> String.trim()
      }

      Stop.changeset(%Stop{},  params)
      |> Properties.Repo.insert()
    end)
    |> Enum.to_list()
  end

  def load_stop_times(file) do
    File.stream!(file)
    |> Stream.drop(1)
    |> Task.async_stream(fn(row) ->
      values = String.trim(row)
        |> String.split(",")

      params = %{
        trip_id: Enum.at(values, 0) |> String.trim(),
        arrival_time: Enum.at(values, 1) |> String.trim() |> parse_interval(),
        departure_time: Enum.at(values, 2) |> String.trim() |> parse_interval(),
        stop_id: Enum.at(values, 3) |> String.trim(),
        stop_sequence: Enum.at(values, 4) |> String.trim() |> parse_stop_sequence(),
        stop_headsign: Enum.at(values, 5) |> String.trim(),
        pickup_type: Enum.at(values, 6) |> String.trim(),
        drop_off_type: Enum.at(values, 7) |> String.trim(),
        timepoint: Enum.at(values, 8) |> String.trim()
      }

      {:ok, _} = StopTime.changeset(%StopTime{},  params)
      |> Properties.Repo.insert()
    end, max_concurrency: 20)
    |> Enum.to_list()
  end

  def load_shapes(file) do
    File.stream!(file)
    |> Stream.drop(1)
    |> Task.async_stream(fn(row) ->
      values = String.trim(row)
        |> String.split(",")

      params = %{
        shape_id: Enum.at(values, 0) |> String.trim(),
        shape_pt_lat: Enum.at(values, 1) |> String.trim(),
        shape_pt_lon: Enum.at(values, 2) |> String.trim(),
        shape_pt_sequence: Enum.at(values, 3) |> String.trim(),
      }

      {:ok, _} = Shape.changeset(%Shape{},  params)
      |> Properties.Repo.insert()
    end, max_concurrency: 20)
    |> Enum.to_list()
  end

  defp parse_stop_sequence(sequence) do
    {integer, _} = Integer.parse(sequence)
    integer
  end

  defp parse_interval(interval) do
    [hour, minute, second] = String.split(interval, ":")
                             |> Enum.map(fn(i) ->
                               {integer, _} = Integer.parse(i)
                               integer
                             end)
    seconds = hour * 60 * 60 + minute * 60 + second

    days = div(seconds, 24 * 60 * 60)
    seconds = rem(seconds, 24 * 60 * 60)
    %{months: 0, days: days, secs: seconds}
  end
end
