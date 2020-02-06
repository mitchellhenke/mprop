defmodule Transit.Shape do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 1, from: 2]
  alias Properties.Repo

  @schema_prefix "gtfs"
  @primary_key false
  schema "shapes" do
    field :shape_id, :string
    field :shape_pt_lat, :float
    field :shape_pt_lon, :float
    field :shape_pt_sequence, :integer

    belongs_to :feed, Transit.Feed
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:feed_id, :shape_id, :shape_pt_lat, :shape_pt_lon, :shape_pt_sequence])
    |> validate_required([:feed_id, :shape_id, :shape_pt_lat, :shape_pt_lon, :shape_pt_sequence])
    |> assoc_constraint(:feed)
  end

  def list_all do
    from(r in Transit.Shape)
    |> Repo.all()
  end

  def get_by_id!(id) do
    from(r in Transit.Shape, where: r.shape_id == ^id)
    |> Repo.one!
  end
end
