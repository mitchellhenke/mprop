defmodule Properties.Repo.Migrations.LastAssessmentAmountIndex do
  use Ecto.Migration

  def up do
    execute "CREATE INDEX properties_last_assessment_amount_index_DESC on properties (last_assessment_amount DESC)"
  end

  def down do
    execute "DROP INDEX properties_last_assessment_amount_index_DESC"
  end
end
