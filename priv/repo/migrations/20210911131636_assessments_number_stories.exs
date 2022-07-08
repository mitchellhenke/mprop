defmodule Properties.Repo.Migrations.AssessmentsNumberStories do
  use Ecto.Migration

  def change do
    alter table(:assessments) do
      add(:number_stories, :float)
    end
  end
end
