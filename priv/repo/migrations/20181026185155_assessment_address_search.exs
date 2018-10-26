defmodule Properties.Repo.Migrations.AssessmentAddressSearch do
  use Ecto.Migration

  def up do
    alter table("assessments") do
      add :full_address_vector, :tsvector
    end

    execute "CREATE INDEX assessments_full_address_vector_gin_index ON assessments USING gin (full_address_vector);"
  end

  def down do
    execute "DROP INDEX assessments_full_address_vector_gin_index;"

    alter table("assessments") do
      remove :full_address_vector
    end
  end
end

# UPDATE assessments set full_address = ((house_number_low || '-' || house_number_high || ' ' || street_direction || ' ' || street || ' ' || street_type));
