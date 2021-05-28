defmodule Properties.Repo.Migrations.SaleStuff do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      add(:last_sale_datetime, :naive_datetime_usec)
      add(:last_sale_amount, :integer)
    end
  end
end
