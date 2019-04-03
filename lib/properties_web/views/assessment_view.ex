defmodule PropertiesWeb.AssessmentView do
  use PropertiesWeb, :view

  def render("index.json", %{assessments: assessments}) do
    %{data: render_many(assessments, PropertiesWeb.AssessmentView, "show.json")}
  end

  def render("show.json", %{assessment: assessment}) do
    %{
      id: assessment.id,
      tax_key: assessment.tax_key,
      address: Properties.Assessment.address(assessment),
      bedrooms: assessment.number_of_bedrooms,
      bathrooms: Properties.Assessment.bathroom_count(assessment),
      lot_area: assessment.lot_area,
      building_area: assessment.building_area,
      last_assessment_amount: assessment.last_assessment_amount,
      parking_type: assessment.parking_type,
      air_conditioning: assessment.air_conditioning,
      basement: assessment.basement,
      attic: assessment.attic,
      year: assessment.year,
      other_assessments: maybe_render_assessments(assessment.other_assessments),
      sales: maybe_render_sales(assessment.sales),
      latitude: assessment.latitude,
      longitude: assessment.longitude,
    }
  end

  def maybe_render_assessments(assessments) when is_list(assessments) do
    render_many(assessments, PropertiesWeb.AssessmentView, "show.json")
  end
  def maybe_render_assessments(_), do: nil

  def maybe_render_sales(assessments) when is_list(assessments) do
    render_many(assessments, PropertiesWeb.SaleView, "show.json")
  end
  def maybe_render_sales(_), do: nil
end
