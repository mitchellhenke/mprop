defmodule Properties.PropertyView do
  use Properties.Web, :view

  def render("index.json", %{properties: properties}) do
    %{data: render_many(properties, Properties.PropertyView, "show.json")}
  end

  def render("show.json", %{property: property}) do
    %{
      id: property.id,
      tax_key: property.tax_key,
      address: Properties.Property.address(property),
      bedrooms: property.number_of_bedrooms,
      bathrooms: bathroom_count(property),
      lot_area: property.lot_area,
      building_area: property.building_area,
      last_assessment_amount: property.last_assessment_amount,
      parking_type: property.parking_type,
    }
  end

  def bathroom_count(property) do
    case {property.number_of_bathrooms, property.number_of_powder_rooms} do
      {nil, nil} -> 0
      {br, nil} -> br
      {nil, pr} -> pr * 0.5
      {br, pr} -> br + (pr * 0.5)
    end
  end
end
