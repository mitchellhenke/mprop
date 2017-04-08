defmodule Properties.Repo.Migrations.AddYear do
  use Ecto.Migration
  def change do
    alter table(:properties) do
      add :year, :integer
    end
  end
end
