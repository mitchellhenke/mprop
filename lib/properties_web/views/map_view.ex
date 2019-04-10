defmodule PropertiesWeb.MapView do
  use PropertiesWeb, :view

  def render("index.json", %{shapefiles: shapefiles}) do
    render_many(shapefiles, PropertiesWeb.MapView, "show.json", as: :shapefile)
  end

  def render("show.json", %{shapefile: shapefile}) do
    assessment_sq_foot = assessment_sq_foot(shapefile.assessment)

    %{
      geometry: Jason.decode!(shapefile.geo_json),
      type: "Feature",
      properties: %{
        tax_key: shapefile.assessment.tax_key,
        popupContent: """
        <a href=\"/properties/#{shapefile.assessment.tax_key}\" target=\"blank\">Assessment Link</a>
        <p>Lot Area: #{shapefile.assessment.lot_area} sq ft</p>
        <p>Land Assessment: $#{shapefile.assessment.last_assessment_land}</p>
        <p>#{assessment_sq_foot} $/sq ft</p>
        """,
        style: %{
          weight: 1,
          color: "#999",
          opacity: 1,
          fillColor: fill_color(assessment_sq_foot),
          fillOpacity: 0.8
        }
      },
    }
  end

  defp fill_color(number) do
    cond do
      number <= 0.64393939393939393939 ->
        "#003F5C"
      number <= 0.77131540546174692516 ->
        "#2F4B7C"
      number <= 1.2682926829268293 ->
        "#665191"
      number <= 1.7400000000000000 ->
        "#A05195"
      number <= 2.3299028016009148 ->
        "#D45087"
      number <= 3.1190476190476190 ->
        "#F95D6A"
      number <= 4.7138682002451211 ->
        "#FF7C43"
      number <= 6.3951970764813365 ->
        "#FFA600"
      true ->
        "#FF0000"
    end
  end

  defp assessment_sq_foot(%{lot_area: nil, last_assessment_land: _}) do
    0
  end

  defp assessment_sq_foot(%{lot_area: _, last_assessment_land: nil}) do
    0
  end

  defp assessment_sq_foot(%{lot_area: area, last_assessment_land: assessment}) when area > 0 and assessment > 0 do
    assessment/area
  end

  defp assessment_sq_foot(_) do
    0
  end
end
