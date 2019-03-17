defmodule Properties.Parser do
  import NimbleParsec

  #  229       E    WISCONSIN     AVE
  # number direction  street  street type
  #
  # String.split(address, " ")
  # Regex.compile(/\d{3,5} (N|W|S|E) (\w+ ){1,4} (DR|ST|AVE){0,1}/)
  #
  # ["229", "E", "WISCONSIN", "AVE"]
  # ["229", "E", "VEL", "R", "PHILLIPS", "DR"]
  # ["229", "N", "DR", "MARTIN", "LUTHER", "KING", "JR", "DR"]
  # ["229", "N", "BROADWAY"]

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

  defparsec :parse,
            street_number
            |> ignore(string(" "))
            |> concat(street_direction)
            |> ignore(string(" "))
            |> concat(street_name_and_type), debug: true

  def error(_, _, _, _, _) do
    {:error, ""}
  end
end

