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

# TODO
# UPDATE assessments set full_address_vector = to_tsvector((house_number_low || ' ' || house_number_high || ' ' || street_direction || ' ' || street || ' ' || street_type)) limit 1;
#
# "UPDATE assessments set full_address_vector = to_tsvector('simple', house_number_low || ' ' || house_number_high || ' ' || coalesce(street_direction, '') || ' ' || coalesce(street, '') || ' ' || coalesce(street_type, '') || ' ' || coalesce(
#       CASE street_type
#       WHEN 'AV' THEN 'AVENUE AVE'
#       WHEN 'BL' THEN 'BOULEVARD BLVD'
#       WHEN 'LA' THEN 'LANE LN'
#       WHEN 'ST' THEN 'STREET STR'
#       WHEN 'DR' THEN 'DRIVE'
#       WHEN 'RD' THEN 'ROAD'
#       WHEN 'CT' THEN 'CRT COURT'
#       WHEN 'TR' THEN 'TERRACE'
#       WHEN 'PK' THEN 'PARKWAY PKWY'
#       WHEN 'CR' THEN 'CIRCLE CIR'
#       WHEN 'WA' THEN 'WAY WY'
#       WHEN 'PL' THEN 'PLACE'
#       ELSE ''
#       END
#       , ''));
