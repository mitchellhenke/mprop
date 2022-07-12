defmodule PropertiesWeb.PropertyView do
  alias Properties.Assessment
  use PropertiesWeb, :view

  @number_comma_regex ~r/\B(?=(\d{3})+(?!\d))/

  def render("index.json", %{properties: properties}) do
    %{data: render_many(properties, PropertiesWeb.PropertyView, "show.json")}
  end

  def render("show.json", %{property: property}) do
    %{
      id: property.id,
      tax_key: property.tax_key
    }
  end

  def comma_separated_number(nil), do: nil

  def comma_separated_number(num) do
    Regex.replace(@number_comma_regex, "#{num}", ",")
  end

  def building_type_options do
    [
      "": "",
      "Ranch": "01",
      "Bi-level": "02",
      "Split-level": "03",
      "Cape-Cod": "04",
      "Colonial": "05",
      "Tudor": "06",
      "Townhouse": "07",
      "Residence (Old-style)": "08",
      "Mansion": "09",
      "Cottage": "10",
      "Duplex (Old-style)": "11",
      "Duplex (New-style)": "12",
      "Duplex Cottage": "13",
      "Triplex": "15",
      "Milwaukee Bungalow": "18",
      "Bungalow (Old-style)": "22",
      "Townhouse Apartment": "17",
      "Apartment (4-6 Units)": "16",
      "Apartment (7-9 Units)": "19",
      "Apartment (10-15 Units)": "20",
      "Apartment (16+ Units)": "21",
    ]
  end

  def land_use_options do
    [{"", ""} | Enum.map(PropertiesWeb.ViewHelper.land_use_map, fn({key, value}) ->
      {value, key}
    end)]
    |> Enum.sort_by(&(elem(&1, 0)))
  end
end
