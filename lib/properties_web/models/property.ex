defmodule Properties.Property do
  use Ecto.Schema

  schema "properties" do
    field :tax_key, :string
    has_many :assessments, Properties.Assessment
    timestamps()
  end

  def changeset(model, params) do
    model
    |> Ecto.Changeset.cast(params, [:tax_key])
    |> Ecto.Changeset.validate_required([:tax_key])
    |> Ecto.Changeset.unique_constraint(:tax_key, name: :properties_tax_key_index)
  end
end
