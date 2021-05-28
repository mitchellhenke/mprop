defmodule Properties.Repo.Migrations.AssessmentsTaxKeyIndex do
  use Ecto.Migration
  @disable_ddl_transaction true

  def change do
    create(index("assessments", [:tax_key], concurrently: true))
  end
end
