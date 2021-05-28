defmodule Transit.Feed do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias Properties.Repo

  @schema_prefix "gtfs"
  schema "feeds" do
    field(:date, :date)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:date])
    |> validate_required([:date])
    |> unique_constraint(:date)
  end

  def find_or_create(date) do
    changeset(%__MODULE__{}, %{date: date})
    |> Repo.insert(on_conflict: {:replace, [:date]}, conflict_target: :date, returning: true)
  end

  def get_first_before_date(date) do
    from(f in Transit.Feed, where: f.date <= ^date, order_by: [desc: f.date], limit: 1)
    |> Repo.one()
  end
end
