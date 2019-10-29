defmodule Transit.CalendarDate do
  use Ecto.Schema

  @schema_prefix "gtfs"
  @primary_key false
  schema "calendar_dates" do
    field :service_id, :string
    field :date, :date
    field :exception_type, :integer
  end
end
