defmodule MilwaukeeProperties.Repo.Migrations.AddPropertiesTable do
  use Ecto.Migration

  def change do
    create table(:properties) do
      add :tax_key, :string
      add :tax_rate_cd, :integer
      add :house_number_high, :string
      add :house_number_low, :string
      add :street_direction, :string
      add :street, :string
      add :street_type, :string
      add :last_assessment_year, :integer
      add :last_assessment_amount, :integer
      add :building_area, :integer
      add :year_built, :integer
      add :number_of_bedrooms, :integer
      add :number_of_bathrooms, :integer
      add :number_of_powder_rooms, :integer
      add :lot_area, :integer
      add :zoning, :string
      add :building_type, :string
      add :zip_code, :string
      add :land_use, :string
      add :land_use_general, :string

      timestamps
    end

    create index(:properties, [:tax_key], unique: true)
  end
end
