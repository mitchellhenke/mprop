defmodule Transit.StopTime do
  use Ecto.Schema

  @schema_prefix "gtfs"
  @primary_key false

  schema "stop_times" do
    field :arrival_time, Interval
    field :departure_time, Interval
    field :stop_sequence, :integer
    field :stop_headsign, :string
    field :pickup_type, :integer
    field :drop_off_type, :integer
    field :timepoint, :integer

    field :elixir_arrival_time, :time, virtual: true
    field :elixir_departure_time, :time, virtual: true

    belongs_to :trip, Transit.Trip, references: :trip_id, foreign_key: :trip_id, type: :string
    belongs_to :stop, Transit.Stop, references: :stop_id, foreign_key: :stop_id, type: :string
  end

  def load_elixir_times(stop_times) when is_list(stop_times) do
    Enum.map(stop_times, &(load_elixir_times(&1)))
  end

  def load_elixir_times(stop_time) do
    %{stop_time | elixir_arrival_time: interval_to_time(stop_time.arrival_time),
      elixir_departure_time: interval_to_time(stop_time.departure_time)}
  end

  def seconds_between_stops(stop_times, stop_id_1, stop_id_2) do
    stop_time1 = Enum.find(stop_times, &(&1.stop_id == stop_id_1))
    stop_time2 = Enum.find(stop_times, &(&1.stop_id == stop_id_2))

    Time.diff(stop_time1.arrival_time, stop_time2.arrival_time, :second)
  end

  defp interval_to_time(interval) do
    hours = div(interval.secs, 3600)
    remaining = interval.secs - 3600 * hours
    minutes = div(remaining, 60)
    seconds = rem(remaining, 60)

    hours = if hours > 23 do
      hours - 24
    else
      hours
    end

    %Time{
      hour: hours,
      minute: minutes,
      second: seconds
    }
  end
end
