defmodule Properties.SalesParser do
  def run(path \\ "raw_data.erl") do
    File.read!(path)
    |> :erlang.binary_to_term
    |> Enum.each(fn(x) ->
      tax_key = Map.get(x, "Taxkey")
                |> String.replace("-", "")

      property = Properties.Repo.get_by(Properties.Property, tax_key: tax_key)
      last_sale_amount = x["Sale $"]

      last_sale = x["Sale Date"]
      attrs = %{
        property_id: (property && property.id) || nil,
        tax_key: tax_key,
        amount: last_sale_amount,
        date_time: last_sale,
        style: x["Style"],
        exterior: x["Exterior"]
      }

      sale = Properties.Repo.get_by(Properties.Sale, tax_key: tax_key, date_time: last_sale)

      if(is_nil(sale) && !is_nil(property)) do
        Properties.Sale.changeset(%Properties.Sale{}, attrs)
        |> Properties.Repo.insert!
      else
      end
    end)
  end
end
