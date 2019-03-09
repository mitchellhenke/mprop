defmodule Properties.Repo.Migrations.CreateSale do
  use Ecto.Migration

  def change do
    create table(:sales) do
      add :property_id, references(:properties, on_delete: :nothing), null: false
      add :tax_key, :string, null: false
      add :amount, :integer, null: false
      add :date_time, :naive_datetime_usec, null: false
      add :style, :string
      add :exterior, :string

      timestamps()
    end

    create index(:sales, [:date_time])
    create index(:sales, [:property_id])
    create index(:sales, [:tax_key])
  end
end
