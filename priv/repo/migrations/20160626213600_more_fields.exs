defmodule MilwaukeeProperties.Repo.Migrations.MoreFields do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      add :air_conditioning, :integer
      add :fireplace, :integer
      add :parking_type, :string
    end
  end
end
