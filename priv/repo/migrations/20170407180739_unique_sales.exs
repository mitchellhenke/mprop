defmodule Properties.Repo.Migrations.UniqueSales do
  use Ecto.Migration

  def change do
    create unique_index(:sales, [:tax_key, :date_time])
  end
end
