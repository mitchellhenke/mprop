defmodule Transit.CalendarDate do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "gtfs"
  @primary_key false
  schema "calendar_dates" do
    field :service_id, :string
    field :date, :date
    field :exception_type, :integer

    belongs_to :feed, Transit.Feed
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:feed_id, :service_id, :date, :exception_type])
    |> validate_required([:feed_id, :service_id, :date, :exception_type])
    |> assoc_constraint(:feed)
  end
end
