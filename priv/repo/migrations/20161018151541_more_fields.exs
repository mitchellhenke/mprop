defmodule Properties.Repo.Migrations.MoreFields do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      add :attic, :string
      add :basement, :string
    end
  end
end
