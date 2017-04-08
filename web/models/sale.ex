defmodule Properties.Sale do
  use Properties.Web, :model

  schema "sales" do
    belongs_to :property, Properties.Property
    field :tax_key, :string
    field :amount, :integer
    field :date_time, Ecto.DateTime
    field :style, :string
    field :exterior, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:tax_key, :amount, :date_time, :style, :exterior, :property_id])
    |> validate_required([:tax_key, :amount, :date_time, :property_id])
    |> Ecto.Changeset.assoc_constraint(:property)
    |> Ecto.Changeset.unique_constraint(:tax_key, name: :sales_tax_key_date_time_index)
  end
end
