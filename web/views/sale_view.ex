defmodule Properties.SaleView do
  use Properties.Web, :view

  def render("show.json", %{sale: sale}) do
    %{
      id: sale.id,
      amount: sale.amount,
      date_time: sale.date_time
    }
  end
end
