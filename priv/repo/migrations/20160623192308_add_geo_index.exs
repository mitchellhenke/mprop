defmodule MilwaukeeProperties.Repo.Migrations.AddGeoIndex do
  use Ecto.Migration

  def up do
    execute "CREATE INDEX properties_geom_index on properties using GIST (geom)"
  end

  def down do
    execute "DROP INDEX properties_geom_index"
  end
end
