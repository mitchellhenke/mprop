defmodule Properties.Repo.Migrations.AddressTextSearch do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")

    execute(
      "CREATE INDEX index_assessment_address_trgm
                 ON assessments using gin ((house_number_low || ' ' || street_direction || ' ' || street || ' ' || street_type) gin_trgm_ops) WHERE year = 2017"
    )
  end
end
