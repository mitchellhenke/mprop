defmodule Properties.Repo.Migrations.RenameTable do
  use Ecto.Migration

  def change do
    drop(index(:properties, [:tax_key]))
    rename(table(:properties), to: table(:assessments))

    alter table(:assessments) do
      modify(:year, :integer, null: false)
      remove(:last_sale_datetime)
      remove(:last_sale_amount)
    end

    create(unique_index(:assessments, [:year, :tax_key]))

    create table(:properties) do
      add(:tax_key, :string)

      timestamps()
    end

    alter table(:assessments) do
      add(:property_id, references(:properties, on_delete: :nothing))
    end

    create(unique_index(:properties, [:tax_key]))
  end
end
