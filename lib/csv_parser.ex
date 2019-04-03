defmodule Properties.CSVParser do
  def run(path, year) do
    File.stream!(path)
    |> CSV.decode!(headers: true)
    |> Enum.each(fn(x) ->
      attrs = %{
      year: year,
      tax_key: String.pad_leading(x["TAXKEY"], 10, "0"),
      tax_rate_cd: parse_tax_rate_cd(x["TAX_RATE_CD"]),
      house_number_low: x["HOUSE_NR_LO"],
      house_number_high: x["HOUSE_NR_HI"],
      street_direction: x["SDIR"],
      street: x["STREET"],
      street_type: x["STTYPE"],
      last_assessment_year: parse_int(x["YR_ASSMT"]),
      last_assessment_amount: String.to_integer(x["C_A_TOTAL"]),
      last_assessment_land: String.to_integer(x["C_A_LAND"]),
      last_assessment_improvements: String.to_integer(x["C_A_IMPRV"]),

      last_assessment_amount_exempt: String.to_integer(x["C_A_EXM_TOTAL"]),
      last_assessment_land_exempt: String.to_integer(x["C_A_EXM_LAND"]),
      last_assessment_improvements_exempt: String.to_integer(x["C_A_EXM_IMPRV"]),
      exemption_code: x["C_A_EXM_TYPE"],

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
      parking_type: String.trim(x["PARKING_TYPE"]),
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

  def run_sales(path, _year) do
    File.stream!(path)
    |> CSV.decode!(headers: true)
    |> Enum.each(fn(x) ->
      tax_key = Map.get(x, "Taxkey")
                |> String.replace("-", "")

      property = Properties.Repo.get_by(Properties.Property, tax_key: tax_key)
      last_sale_amount = String.replace(x["Sale $"], ",", "")

      last_sale = "#{x["Sale Date"]} 00:00:00"
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

  defp parse_tax_rate_cd("False"), do: 0
  defp parse_tax_rate_cd(number) when is_binary(number) do
    String.to_integer(number)
  end

  defp parse_air("False"), do: 0
  defp parse_air("True"), do: 1
  defp parse_air(_), do: 0

  defp parse_int(""), do: nil
  defp parse_int(num), do: String.to_integer(num)

  defp parse_date(""), do: nil
  defp parse_date(date) do
    date = if(String.length(date) == 10) do
      "#{date} 00:00:00"
    else
      date
    end

    with {:ok, parsed} <- NaiveDateTime.from_iso8601(date)
    do
      parsed
    else _ -> nil
    end
  end
end
