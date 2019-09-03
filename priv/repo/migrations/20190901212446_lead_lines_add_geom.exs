defmodule MilwaukeeProperties.Repo.Migrations.LeadLinesAddGeom do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE lead_service_lines ADD COLUMN geom geometry(MultiPolygon,4326);"
    execute "ALTER TABLE lead_service_lines ADD COLUMN geo_json jsonb;"
    execute "CREATE INDEX lead_service_lines_geom_index on lead_service_lines using GIST (geom)"
  end

  def down do
    execute "DROP INDEX lead_service_lines_geom_index"
    alter table(:lead_service_lines) do
      drop :geom
      drop :geo_json
    end
  end
end
