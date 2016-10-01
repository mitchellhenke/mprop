defmodule MilwaukeeProperties.Repo.Migrations.AddLatLng do
  use Ecto.Migration
  def up do
    execute "CREATE EXTENSION IF NOT EXISTS postgis"
    alter table(:properties) do
      add :geom, :geometry
    end
  end

  def down do
    alter table(:properties) do
      drop :geom
    end

    execute "DROP EXTENSION IF EXISTS postgis"
  end
end
