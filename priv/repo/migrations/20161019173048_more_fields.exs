defmodule Properties.Repo.Migrations.MoreFields do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      add :neighborhood, :string
      add :geo_tract, :string
      add :geo_block, :string
      add :air_conditioning, :integer
      add :fireplace, :integer
      add :parking_type, :string
      add :attic, :string
      add :basement, :string
    end
  end
end
