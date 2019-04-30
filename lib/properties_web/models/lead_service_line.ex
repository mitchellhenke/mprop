defmodule Properties.LeadServiceLine do
  use Ecto.Schema
  import Ecto.Query

  schema "lead_service_lines" do
    field :tax_key, :string
    field :address, :string

    timestamps()
  end

  def maybe_insert(tax_key, address) do
    changeset(%__MODULE__{}, %{tax_key: tax_key, address: address})
    |> Properties.Repo.insert()
  end

  def changeset(model, params) do
    model
    |> Ecto.Changeset.cast(params, [:tax_key, :address])
    |> Ecto.Changeset.validate_required([:tax_key])
    |> Ecto.Changeset.unique_constraint(:tax_key)
  end
end
