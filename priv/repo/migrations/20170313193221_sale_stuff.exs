defmodule Properties.Repo.Migrations.SaleStuff do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      add :last_sale_datetime, :datetime
      add :last_sale_amount, :integer
    end
  end
end
