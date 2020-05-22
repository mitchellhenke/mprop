defmodule Properties.CSVParser do
  require Logger
  import Ecto.Query

  def run(path, year) do
    File.stream!(path)
    |> CSV.decode!(headers: true, validate_row_length: false)
    |> Task.async_stream(
      fn x ->
        attrs = %{
          year: year,
          zoning: x["ZONING"],
          tax_key: String.pad_leading(x["TAXKEY"], 10, "0"),
          tax_rate_cd: parse_tax_rate_cd(x["TAX_RATE_CD"]),
          house_number_low: x["HOUSE_NR_LO"],
          house_number_high: x["HOUSE_NR_HI"],
          street_direction: x["SDIR"],
          street: x["STREET"],
          street_type: x["STTYPE"],
          last_assessment_year: parse_int(x["YR_ASSMT"]),
          last_assessment_amount: parse_int(x["C_A_TOTAL"]),
          last_assessment_land: parse_int(x["C_A_LAND"]),
          last_assessment_improvements: parse_int(x["C_A_IMPRV"]),
          last_assessment_amount_exempt: parse_int(x["C_A_EXM_TOTAL"]),
          last_assessment_land_exempt: parse_int(x["C_A_EXM_LAND"]),
          last_assessment_improvements_exempt: parse_int(x["C_A_EXM_IMPRV"]),
          exemption_code: x["C_A_EXM_TYPE"],
          building_area: parse_float_as_int(x["BLDG_AREA"]),
          year_built: parse_int(x["YR_BUILT"]),
          number_of_bedrooms: parse_int(x["BEDROOMS"]),
          number_of_bathrooms: parse_int(x["BATHS"]),
          number_of_powder_rooms: parse_int(x["POWDER_ROOMS"]),
          lot_area: parse_float_as_int(x["LOT_AREA"]),
          building_type: x["BLDG_TYPE"],
          zip_code: x["GEO_ZIP_CODE"],
          owner_name_1: x["OWNER_NAME_1"],
          owner_name_2: x["OWNER_NAME_2"],
          owner_name_3: x["OWNER_NAME_3"],
          owner_mail_address: x["OWNER_MAIL_ADDR"],
          owner_city_state: x["OWNER_CITY_STATE"],
          owner_zip_code: x["OWNER_ZIP"],
          owner_occupied: x["OWN_OCPD"],
          land_use: x["LAND_USE"],
          land_use_general: x["LAND_USE_GP"],
          fireplace: parse_int(x["FIREPLACE"]),
          air_conditioning: parse_air(String.trim(x["AIR_CONDITIONING"])),
          parking_type: String.trim(x["PARKING_TYPE"]),
          number_units: parse_int(x["NR_UNITS"]),
          attic: x["ATTIC"],
          basement: x["BASEMENT"],
          geo_tract: x["GEO_TRACT"],
          geo_block: x["GEO_BLOCK"],
          neighborhood: x["NEIGHBORHOOD"],
          convey_datetime: parse_date(x["CONVEY_DATE"]),
          convey_type: x["CONVEY_TYPE"],
          geo_alder: x["GEO_ALDER"]
        }

        property =
          case Properties.Repo.get_by(Properties.Property, tax_key: attrs.tax_key) do
            nil ->
              Properties.Property.changeset(%Properties.Property{}, %{tax_key: attrs.tax_key})
              |> Properties.Repo.insert!()

            p ->
              p
          end

        attrs = Map.put(attrs, :property_id, property.id)

        case Properties.Repo.get_by(Properties.Assessment, tax_key: attrs.tax_key, year: year) do
          nil ->
            Properties.Assessment.changeset(%Properties.Assessment{}, attrs)
            |> Properties.Repo.insert!()

          a ->
            Properties.Assessment.changeset(a, attrs)
            |> Properties.Repo.update!()
        end
      end,
      max_concurrency: 2,
      timeout: :infinity
    )
    |> Stream.run()
  end

  def run_sales(path, _year) do
    File.stream!(path)
    |> CSV.decode!(headers: true)
    |> Enum.each(fn x ->
      tax_key =
        Map.get(x, "Taxkey")
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
        |> Properties.Repo.insert!()
      else
      end
    end)
  end

  def run_new_sales(path) do
    File.stream!(path)
    |> CSV.decode!(headers: true)
    |> Enum.each(fn x ->
      tax_key =
        Map.get(x, "taxkey")
        |> String.replace("-", "")
        |> IO.inspect()

      property = Properties.Repo.get_by(Properties.Property, tax_key: tax_key)
      last_sale_amount = String.replace(x["Sale_price"], ",", "")

      last_sale_amount = if last_sale_amount == "NULL" do
        0
      else
        last_sale_amount
      end

      # 3/11/2019
      date = case String.split(x["Sale_date"], "/") do
        [month, day, year] ->
          "#{year}-#{String.pad_leading(month, 2, "0")}-#{String.pad_leading(day, 2, "0")} 00:00:00"
        _ -> nil
      end


      attrs = %{
        property_id: (property && property.id) || nil,
        tax_key: tax_key,
        amount: last_sale_amount,
        date_time: date,
        style: x["Style"]
      }

      Properties.Sale.changeset(%Properties.Sale{}, attrs)
      |> Properties.Repo.insert()
    end)
  end

  def run_master_sales(path) do
    File.stream!(path)
    |> CSV.decode!(headers: true)
    |> Enum.each(fn x ->
      tax_key =
        Map.get(x, "Taxkey")
        |> String.replace("-", "")

      property = Properties.Repo.get_by(Properties.Property, tax_key: tax_key)
      last_sale_amount = String.replace(x["Sale_price"], ",", "")

      last_sale = "#{x["Sale_date"]}-01 00:00:00"

      attrs = %{
        property_id: (property && property.id) || nil,
        tax_key: tax_key,
        amount: last_sale_amount,
        date_time: last_sale,
        style: x["Style"]
      }

      sale = Properties.Repo.get_by(Properties.Sale, tax_key: tax_key, date_time: last_sale)

      if(is_nil(sale) && !is_nil(property)) do
        Properties.Sale.changeset(%Properties.Sale{}, attrs)
        |> Properties.Repo.insert!()
      else
      end
    end)
  end

  def run_lead_service_lines(path) do
    File.stream!(path)
    |> NimbleCSV.RFC4180.parse_stream(skip_headers: true)
    |> Stream.filter(fn [_, _, _, _, city, _, _] ->
      city == "MILWAUKEE"
    end)
    |> Task.async_stream(fn row ->
      # House Number Low,EMPTY,House Number High,Street Name,City,State,Zip Code
      [house_number_low, _, house_number_high, street_name, city, _state, _zip_code] = row
      address = "#{house_number_low} #{street_name}"
      full_address = "#{house_number_low}-#{house_number_high} #{street_name} #{city}"

      Properties.Repo.transaction fn ->
        tax_keys =
          from(a in Properties.Assessment, where: a.year == 2020, limit: 2)
          |> Properties.Assessment.filter_by_address(address)
          |> Properties.Assessment.select_only_tax_key()
          |> Properties.Repo.all()

        case tax_keys do
          [tax_key] ->
            sf = Properties.ShapeFile.get_by_tax_key(tax_key)

            if sf do
              Properties.LeadServiceLine.maybe_insert(tax_key, full_address, sf.geom)
            else
              Properties.LeadServiceLine.maybe_insert(tax_key, full_address, nil)
              IO.inspect(tax_key)
            end

          _tax_keys = [_tax_key1  | [_tax_key2 | _]] ->
            nil

          [] ->
            nil
        end
      end
    end,
    max_concurrency: 10,
    timeout: :infinity)
    |> Stream.run()
  end

  defp parse_tax_rate_cd(""), do: 0
  defp parse_tax_rate_cd("False"), do: 0

  defp parse_tax_rate_cd(number) when is_binary(number) do
    String.to_integer(number)
  end

  defp parse_air("False"), do: 0
  defp parse_air("True"), do: 1
  defp parse_air(_), do: 0

  defp parse_int(int) do
    String.trim(int)
    |> do_parse_int()
  end

  defp do_parse_int(""), do: nil
  defp do_parse_int("N"), do: nil
  defp do_parse_int("Y"), do: 1
  defp do_parse_int(num), do: String.to_integer(num)

  defp parse_float_as_int(float) do
    case Float.parse(float) do
      {float, _} -> round(float)
      :error -> nil
    end
  end

  defp parse_date(""), do: nil

  defp parse_date(date) do
    date =
      if(String.length(date) == 10) do
        "#{date} 00:00:00"
      else
        date
      end

    with {:ok, parsed} <- NaiveDateTime.from_iso8601(date) do
      parsed
    else
      _ -> nil
    end
  end
end
