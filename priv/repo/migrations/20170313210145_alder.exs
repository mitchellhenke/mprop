defmodule Properties.Repo.Migrations.Alder do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      add(:geo_alder, :string)
    end
  end
end
