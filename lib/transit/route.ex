defmodule Transit.Route do
  use Ecto.Schema
  import Ecto.Query, only: [from: 1, from: 2]
  alias Properties.Repo

  @schema_prefix "gtfs"
  @primary_key false
  schema "routes" do
    field :route_id, :string
    field :route_short_name, :string
    field :route_long_name, :string
    field :route_desc, :string
    field :route_type, :integer
    field :route_url, :string
    field :route_color, :string
    field :route_text_color, :string
  end

  def list_all do
    from(r in Transit.Route)
    |> Repo.all()
  end

  def get_by_id!(id) do
    from(r in Transit.Route, where: r.route_id == ^id)
    |> Repo.one!
  end
end
