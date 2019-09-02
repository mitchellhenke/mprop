defmodule Properties.LeadServiceLine do
  use Ecto.Schema
  import Ecto.Query

  schema "lead_service_lines" do
    field :tax_key, :string
    field :address, :string
    field :geom, Geo.PostGIS.Geometry
    field :geo_json, :map

    timestamps()
  end

  def maybe_insert(tax_key, address, geom) do
    changeset(%__MODULE__{}, %{tax_key: tax_key, address: address, geom: geom})
    |> Properties.Repo.insert()
  end

  def changeset(model, params) do
    model
    |> Ecto.Changeset.cast(params, [:tax_key, :address, :geom])
    |> Ecto.Changeset.validate_required([:tax_key])
    |> Ecto.Changeset.unique_constraint(:tax_key)
  end

  def list_lead_service_lines(x_min, y_min, x_max, y_max) do
    from(l in Properties.LeadServiceLine,
      where: fragment("? @ ST_MakeEnvelope(?, ?, ?, ?)", l.geom, ^x_min, ^y_min, ^x_max, ^y_max),
      select: %{geo_json: l.geo_json, lead_service_line_address: l.address, assessment: %{tax_key: l.tax_key}}
    )
    |> Properties.Repo.all()
  end
end
