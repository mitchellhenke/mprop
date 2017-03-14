defmodule Properties.Repo.Migrations.Convey do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      add :convey_datetime, :datetime
      add :convey_type, :string
    end
  end
end
