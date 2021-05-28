defmodule MilwaukeeProperties.Repo.Migrations.NumberUnits do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      add(:number_units, :integer)
    end
  end
end
