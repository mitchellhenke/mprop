defmodule Properties.XMLParser do
  @chunk 10000
  import Ecto.Query

  def run(path \\ "file.xml") do
    {:ok, handle} = File.open(path, [:binary])

    position           = 0
    c_state            = {handle, position, @chunk}

    :erlsom.parse_sax("",
                      nil,
                      &sax_event_handler/2, 
                      [{:continuation_function, &continue_file/2, c_state}])

    :ok = File.close(handle)
  end

  def get_valid_ids(path \\ "file.xml") do
    {:ok, handle} = File.open(path, [:binary])

    position           = 0
    c_state            = {handle, position, @chunk}

    x = :erlsom.parse_sax("",
                      [],
                      &id_event_handler/2, 
                      [{:continuation_function, &continue_file/2, c_state}])

    :ok = File.close(handle)
    x
  end

  def continue_file(tail, {handle, offset, chunk}) do
    case :file.pread(handle, offset, chunk) do
      {:ok, data} ->
        {<<tail :: binary, data::binary>>, {handle, offset + chunk, chunk}}
      :oef ->
        {tail, {handle, offset, chunk}}
    end
  end

  def id_event_handler({:startElement, _, 'MPROP', _, _}, state) do
    {"", state}
  end

  def id_event_handler({:startElement, _, _field, _, _}, {_, state}) do
    {"", state}
  end

  def id_event_handler({:characters, value}, {element_accumulator, state}) do
    {element_accumulator <> to_string(value), state}
  end

  def id_event_handler({:endElement, _, 'GEO_BLOCK', _}, {element_accumulator, {_, state}}) do
    {"", [element_accumulator | state]}
  end

  def id_event_handler({:endElement, _, 'MPROP', _}, {_element_accumulator, state}) do
    {"", state}
  end
  def id_event_handler(:endDocument, state), do: state
  def id_event_handler(_, state), do: state

  def sax_event_handler({:startElement, _, 'MPROP', _, _}, _property) do
    {"", %Properties.Property{}}
  end

  def sax_event_handler({:startElement, _, _field, _, _}, {_, property}) do
    {"", property}
  end

  def sax_event_handler({:characters, value}, {element_accumulator, property}) do
    {element_accumulator <> to_string(value), property}
  end

  def sax_event_handler({:endElement, _, 'TAXKEY', _}, {element_accumulator, property}) do
    {"", %{property | tax_key: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'TAX_RATE_CD', _}, {element_accumulator, property}) do
    {"", %{property | tax_rate_cd: String.to_integer(element_accumulator)}}
  end

  def sax_event_handler({:endElement, _, 'HOUSE_NR_LO', _}, {element_accumulator, property}) do
    {"", %{property | house_number_low: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'HOUSE_NR_HI', _}, {element_accumulator, property}) do
    {"", %{property | house_number_high: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'SDIR', _}, {element_accumulator, property}) do
    {"", %{property | street_direction: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'STREET', _}, {element_accumulator, property}) do
    {"", %{property | street: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'STTYPE', _}, {element_accumulator, property}) do
    {"", %{property | street_type: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'YR_ASSMT', _}, {element_accumulator, property}) do
    {"", %{property | last_assessment_year: String.to_integer(element_accumulator)}}
  end

  def sax_event_handler({:endElement, _, 'C_A_TOTAL', _}, {element_accumulator, property}) do
    {"", %{property | last_assessment_amount: String.to_integer(element_accumulator)}}
  end

  def sax_event_handler({:endElement, _, 'BLDG_AREA', _}, {element_accumulator, property}) do
    {"", %{property | building_area: String.to_integer(element_accumulator)}}
  end

  def sax_event_handler({:endElement, _, 'YR_BUILT', _}, {element_accumulator, property}) do
    {"", %{property | year_built: String.to_integer(element_accumulator)}}
  end

  def sax_event_handler({:endElement, _, 'BEDROOMS', _}, {element_accumulator, property}) do
    {"", %{property | number_of_bedrooms: String.to_integer(element_accumulator)}}
  end

  def sax_event_handler({:endElement, _, 'BATHS', _}, {element_accumulator, property}) do
    {"", %{property | number_of_bathrooms: String.to_integer(element_accumulator)}}
  end

  def sax_event_handler({:endElement, _, 'POWDER_ROOMS', _}, {element_accumulator, property}) do
    {"", %{property | number_of_powder_rooms: String.to_integer(element_accumulator)}}
  end

  def sax_event_handler({:endElement, _, 'LOT_AREA', _}, {element_accumulator, property}) do
    {"", %{property | lot_area: String.to_integer(element_accumulator)}}
  end

  def sax_event_handler({:endElement, _, 'ZONING', _}, {element_accumulator, property}) do
    {"", %{property | zoning: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'BLDG_TYPE', _}, {element_accumulator, property}) do
    {"", %{property | building_type: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'GEO_ZIP_CODE', _}, {element_accumulator, property}) do
    {"", %{property | zip_code: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'LAND_USE', _}, {element_accumulator, property}) do
    {"", %{property | land_use: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'LAND_USE_GP', _}, {element_accumulator, property}) do
    {"", %{property | land_use_general: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'FIREPLACE', _}, {element_accumulator, property}) do
    {"", %{property | fireplace: String.to_integer(element_accumulator)}}
  end

  def sax_event_handler({:endElement, _, 'AIR_CONDITIONING', _}, {element_accumulator, property}) do
    {"", %{property | air_conditioning: String.trim(element_accumulator) |> String.to_integer}}
  end
  def sax_event_handler({:endElement, _, 'PARKING_TYPE', _}, {element_accumulator, property}) do
    {"", %{property | parking_type: String.strip element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'NR_UNITS', _}, {element_accumulator, property}) do
    {"", %{property | number_units: String.to_integer(element_accumulator)}}
  end

  def sax_event_handler({:endElement, _, 'ATTIC', _}, {element_accumulator, property}) do
    {"", %{property | attic: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'BASEMENT', _}, {element_accumulator, property}) do
    {"", %{property | basement: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'GEO_TRACT', _}, {element_accumulator, property}) do
    {"", %{property | geo_tract: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'GEO_BLOCK', _}, {element_accumulator, property}) do
    {"", %{property | geo_block: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'NEIGHBORHOOD', _}, {element_accumulator, property}) do
    {"", %{property | neighborhood: element_accumulator}}
  end

  def sax_event_handler({:endElement, _, 'MPROP', _}, {_element_accumulator, property}) do
    if is_nil(Properties.Repo.get_by(Properties.Property, [tax_key: property.tax_key])) do
      Properties.Repo.insert!(property)
    else
      changes = Map.to_list(property) |> Keyword.drop([:geom, :distance, :__struct__, :updated_at, :inserted_at, :__meta__, :id])
      from(p in Properties.Property, where: [tax_key: ^property.tax_key])
      |> Properties.Repo.update_all(set: changes)
    end
    {"", property}
  end

  def sax_event_handler(:endDocument, state), do: state
  def sax_event_handler(_, state), do: state

end

