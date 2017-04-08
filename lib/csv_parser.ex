defmodule Properties.CSVParser do
  import Ecto.Query

  def run(path, year) do
    File.stream!(path)
    |> CSV.decode(headers: true)
    |> Enum.each(fn(x) ->
      attrs = %{
      year: year,
      tax_key: String.pad_leading(x["TAXKEY"], 10, "0"),
      tax_rate_cd: String.to_integer(x["TAX_RATE_CD"]),
      house_number_low: x["HOUSE_NR_LO"],
      house_number_high: x["HOUSE_NR_HI"],
      street_direction: x["SDIR"],
      street: x["STREET"],
      street_type: x["STTYPE"],
      last_assessment_year: parse_int(x["YR_ASSMT"]),
      last_assessment_amount: String.to_integer(x["C_A_TOTAL"]),
      building_area: parse_int(x["BLDG_AREA"]),
      year_built: parse_int(x["YR_BUILT"]),
      number_of_bedrooms: parse_int(x["BEDROOMS"]),
      number_of_bathrooms: parse_int(x["BATHS"]),
      number_of_powder_rooms: parse_int(x["POWDER_ROOMS"]),
      lot_area: parse_int(x["LOT_AREA"]),
      building_type: x["BLDG_TYPE"],
      zip_code: x["GEO_ZIP_CODE"],
      land_use: x["LAND_USE"],
      land_use_general: x["LAND_USE_GP"],
      fireplace: parse_int(x["FIREPLACE"]),
      air_conditioning: parse_air(String.trim(x["AIR_CONDITIONING"])),
      parking_type: String.strip(x["PARKING_TYPE"]),
      number_units: String.to_integer(x["NR_UNITS"]),
      attic: x["ATTIC"],
      basement: x["BASEMENT"],
      geo_tract: x["GEO_TRACT"],
      geo_block: x["GEO_BLOCK"],
      neighborhood: x["NEIGHBORHOOD"],
      convey_datetime: parse_date(x["CONVEY_DATE"]),
      convey_type: x["CONVEY_TYPE"],
      geo_alder: x["GEO_ALDER"],
      }

      property = case Properties.Repo.get_by(Properties.Property, tax_key: attrs.tax_key) do
        nil ->
          Properties.Property.changeset(%Properties.Property{}, %{tax_key: attrs.tax_key})
          |> Properties.Repo.insert!
        p -> p
      end

      attrs = Map.put(attrs, :property_id, property.id)

      case Properties.Repo.get_by(Properties.Assessment, tax_key: attrs.tax_key, year: year) do
        nil ->
          Properties.Assessment.changeset(%Properties.Assessment{}, attrs)
          |> Properties.Repo.insert!
        a ->
          Properties.Assessment.changeset(a, attrs)
          |> Properties.Repo.update!
      end
    end)
  end

  defp parse_air("False"), do: 0
  defp parse_air("True"), do: 1
  defp parse_air(_), do: 0

  defp parse_int(""), do: nil
  defp parse_int(num), do: String.to_integer(num)

  defp parse_date(""), do: nil
  defp parse_date(date) do
    if(String.length(date) == 10) do
      "#{date} 00:00:00"
    else
      date
    end
    |> Ecto.DateTime.cast!
  end
end
