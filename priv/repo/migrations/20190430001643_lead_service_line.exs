defmodule Properties.Repo.Migrations.LeadServiceLine do
  use Ecto.Migration

  def change do
    create table(:lead_service_lines) do
      add(:tax_key, :string, null: false)
      add(:address, :string)

      timestamps()
    end

    create(unique_index(:lead_service_lines, [:tax_key]))
  end
end
