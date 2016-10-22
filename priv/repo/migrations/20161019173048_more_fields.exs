defmodule Properties.Repo.Migrations.MoreFields do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      add :neighborhood, :string
      add :geo_tract, :string
      add :geo_block, :string
    end
  end
end
