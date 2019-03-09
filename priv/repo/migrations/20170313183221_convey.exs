defmodule Properties.Repo.Migrations.Convey do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      add :convey_datetime, :naive_datetime_usec
      add :convey_type, :string
    end
  end
end
