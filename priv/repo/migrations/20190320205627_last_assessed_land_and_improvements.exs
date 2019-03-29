defmodule Properties.Repo.Migrations.LastAssessedLandAndImprovements do
  use Ecto.Migration

  def change do
    alter table(:assessments) do
      add :last_assessment_land, :integer
      add :last_assessment_improvements, :integer
    end
  end
end
