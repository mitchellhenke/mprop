defmodule Transit.Trip do
  use Ecto.Schema
  import Ecto.Query, only: [from: 1, from: 2]
  alias Properties.Repo

  @schema_prefix "gtfs"
  @primary_key false
  schema "trips" do
    field :trip_id, :string
    field :service_id, :string
    field :trip_headsign, :string
    field :direction_id, :integer
    field :block_id, :string
    field :shape_id, :string

    field :total_time, :time, virtual: true

    belongs_to :route, Transit.Route, references: :route_id, foreign_key: :route_id, type: :string
    has_many :stop_times, Transit.StopTime, references: :trip_id, foreign_key: :trip_id
  end

  def preload_stop_time_stops(trip) do
    stop_times = Enum.map(trip.stop_times, fn(stop_time) ->
      stop = ConCache.get(:transit_cache, "stops_#{stop_time.stop_id}")
      %{stop_time | stop: stop}
    end)

    %{trip | stop_times: stop_times}
  end

  def get_by_route_id_and_date(route_id, date) do
    from(t in Transit.Trip,
      join: cd in Transit.CalendarDate, on: cd.service_id == t.service_id,
      where: cd.date == ^date and t.route_id == ^route_id
    )
    |> Repo.all()
  end

  def preload_stop_times(trips) do
    Repo.preload(trips, [stop_times: :stop])
    |> Enum.map(fn(trip) ->
      stop_times = Transit.StopTime.load_elixir_times(trip.stop_times)
                   |> Enum.sort_by(&(&1.stop_sequence))
      trip = %{trip | stop_times: stop_times}

      first = List.first(trip.stop_times).elixir_departure_time
      last = List.last(trip.stop_times).elixir_arrival_time

      total_time = Transit.calculate_time_diff(first, last)
      %{trip | total_time: total_time}
    end)
  end
end
