defmodule MilwaukeeProperties.Repo.Migrations.SpecificSrid do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE properties ALTER COLUMN geom TYPE geometry(Point, 4326) USING ST_SetSRID(geom, 4326);"
  end

  def down do

  end
end
