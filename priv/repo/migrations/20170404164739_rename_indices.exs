defmodule Properties.Repo.Migrations.RenameIndices do
  use Ecto.Migration

  def up do
    execute "ALTER INDEX properties_pkey RENAME TO assessments_pkey"
    execute "ALTER INDEX properties_geom_index RENAME TO assessments_geom_index"
    execute "ALTER INDEX properties_last_assessment_amount_index_desc RENAME TO assessments_last_assessment_amount_index_desc"
  end

  def down do
    execute "ALTER INDEX assessments_pkey RENAME TO properties_pkey"
    execute "ALTER INDEX assessments_geom_index RENAME TO properties_geom_index"
    execute "ALTER INDEX assessments_last_assessment_amount_index_desc RENAME TO properties_last_assessment_amount_index_desc"
  end
end
