defmodule Properties.Repo.Migrations.LastAssessedLandAndImprovementsExemptions do
  use Ecto.Migration

  def change do
    alter table(:assessments) do
      add :last_assessment_land_exempt, :integer
      add :last_assessment_improvements_exempt, :integer
      add :last_assessment_amount_exempt, :integer
      add :exemption_code, :string
    end
  end
end
