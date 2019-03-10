defmodule Properties.AddressParser do
  import NimbleParsec
  import Ecto.Query

  street_number =
    integer(min: 3, max: 5)
    |> optional(ignore(utf8_char([?A..?D])))
    |> unwrap_and_tag(:street_number)

  street_direction =
    choice([
      string("N"),
      string("NORTH"),
      string("W"),
      string("WEST"),
      string("E"),
      string("EAST"),
      string("S"),
      string("SOUTH")
    ])
    |> unwrap_and_tag(:street_direction)

  street_type =
    utf8_string([?A..?Z], min: 1)
    |> eos()
    |> unwrap_and_tag(:street_type)

  street_name_part = utf8_string([?A..?Z, ?0..?9], min: 1) |> ignore(string(" "))

  streets_without_types =
    choice([string("BROADWAY"), string("METRO AUTO MALL"), string("BACK BAY")])

  street_name_and_type =
    choice([
      streets_without_types |> eos() |> tag(:street_name),
      lookahead(streets_without_types) |> post_traverse({:error, []}),
      times(
        lookahead_not(street_type)
        |> concat(street_name_part),
        min: 1,
        max: 4
      )
      |> tag(:street_name)
      |> concat(street_type)
    ])

  defparsec :parse_address,
            street_number
            |> ignore(string(" "))
            |> concat(street_direction)
            |> ignore(string(" "))
            |> concat(street_name_and_type), inline: true

  @doc """
  Broadway, Metro Auto Mall, and Back Bay are streets in Milwaukee
  that don't have a type (street, road, lane, etc.)
  """
  def error(_, _, _, _, _) do
    {:error, ""}
  end

  def validate_addresses() do
    from(a in Properties.Assessment, where: a.year == 2017)
    |> Properties.Repo.all()
    |> Enum.map(fn p ->
      address =
        "#{p.house_number_low} #{p.street_direction} #{p.street} #{p.street_type}"
        |> String.trim()

      {address, parse(address)}
    end)
  end

  @spec parse(String.t) :: String.t | {:error, term()}
  def parse(nil), do: {:error, :invalid_address}
  def parse(""), do: {:error, :invalid_address}
  def parse(address) do
    address = String.upcase(address)
    case parse_address(address) do
      {:ok, address_parts, _, _, _, _} ->
        street_number = Keyword.get(address_parts, :street_number)
        street_direction = Keyword.get(address_parts, :street_direction)
        street_name = Keyword.get(address_parts, :street_name)
                      |> Enum.join(" ")

        street_type = Keyword.get(address_parts, :street_type)
                      |> replace_street_type()

        street_name_results = Properties.Indexer.search(street_name)

        {new_street_name, score} = case street_name_results do
          [{best, score} | _] ->
            {best, score}
          [] -> {street_name, 1.0}
        end

        {:ok, {String.trim("#{street_number} #{street_direction} #{new_street_name} #{street_type}"), score}}

      {:error, _, _, _, _, _} ->
        {:error, :invalid_address}
    end
  end

  def replace_street_type("TERRACE"), do: "TR"
  def replace_street_type("BLVD"), do: "BL"
  def replace_street_type("BOULEVARD"), do: "BL"
  def replace_street_type("DRIVE"), do: "DR"
  def replace_street_type("WAY"), do: "WY"
  def replace_street_type("LANE"), do: "LN"
  def replace_street_type("ROAD"), do: "RD"
  def replace_street_type("CIRCLE"), do: "CR"
  def replace_street_type("CIR"), do: "CR"
  def replace_street_type("STREET"), do: "ST"
  def replace_street_type("STR"), do: "ST"
  def replace_street_type("AVENUE"), do: "AV"
  def replace_street_type("AVE"), do: "AV"
  def replace_street_type("CRT"), do: "CT"
  def replace_street_type("COURT"), do: "CT"
  def replace_street_type("PARKWAY"), do: "PK"
  def replace_street_type("PKWY"), do: "PK"
  def replace_street_type(street_type), do: street_type
end
