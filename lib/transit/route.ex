defmodule Transit.Route do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias Properties.Repo
  alias Transit.Feed

  @schema_prefix "gtfs"
  @primary_key false
  schema "routes" do
    field(:route_id, :string)
    field(:route_short_name, :string)
    field(:route_long_name, :string)
    field(:route_desc, :string)
    field(:route_type, :integer)
    field(:route_url, :string)
    field(:route_color, :string)
    field(:route_text_color, :string)

    belongs_to(:feed, Transit.Feed)
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :feed_id,
      :route_id,
      :route_short_name,
      :route_long_name,
      :route_desc,
      :route_type,
      :route_url,
      :route_color,
      :route_text_color
    ])
    |> validate_required([:feed_id, :route_id, :route_short_name, :route_long_name, :route_type])
    |> assoc_constraint(:feed)
  end

  def list_all(%Feed{id: feed_id}) do
    from(r in Transit.Route, where: r.feed_id == ^feed_id)
    |> Repo.all()
  end

  def get_by_id!(%Feed{id: feed_id}, id) do
    from(r in Transit.Route, where: r.route_id == ^id and r.feed_id == ^feed_id)
    |> Repo.one!()
  end
end
