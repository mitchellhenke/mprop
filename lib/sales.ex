defmodule Properties.SalesParser do
  import Ecto.Query

  def run(path \\ "sales.csv") do
    File.stream!(path)
    |> CSV.decode(headers: true)
    |> Enum.each(fn(x) ->
      tax_key = Map.get(x, "Taxkey")
                |> String.replace("-", "")

      # Properties.Repo.get_by!(Properties.Property, tax_key: tax_key)
      last_sale_amount = x["Sale $"]
                         |> String.replace(",", "")
                         |> String.to_integer()

      last_sale = "#{x["Sale Date"]} 00:00:00"
                  |> Ecto.DateTime.cast!()

      changes = [last_sale_datetime: last_sale, last_sale_amount: last_sale_amount]


      from(p in Properties.Property, where: [tax_key: ^tax_key])
      |> Properties.Repo.update_all(set: changes)
    end)
  end
end
