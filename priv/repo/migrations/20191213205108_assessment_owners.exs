defmodule Properties.Repo.Migrations.AssessmentOwners do
  use Ecto.Migration

  def change do
    alter table(:assessments) do
      add :owner_name_1, :text
      add :owner_name_2, :text
      add :owner_name_3, :text
      add :owner_mail_address, :text
      add :owner_city_state, :text
      add :owner_zip_code, :text
      add :owner_occupied, :text
    end
  end
end
