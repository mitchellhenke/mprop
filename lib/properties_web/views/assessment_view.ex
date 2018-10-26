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
      bathrooms: bathroom_count(assessment),
      lot_area: assessment.lot_area,
      building_area: assessment.building_area,
      last_assessment_amount: assessment.last_assessment_amount,
      parking_type: assessment.parking_type,
      air_conditioning: assessment.air_conditioning,
      basement: assessment.basement,
      attic: assessment.attic,
      year: assessment.year,
      other_assessments: maybe_render_assessments(assessment.other_assessments),
      sales: maybe_render_sales(assessment.sales)
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

  def bathroom_count(assessment) do
    case {assessment.number_of_bathrooms, assessment.number_of_powder_rooms} do
      {nil, nil} -> 0
      {br, nil} -> br
      {nil, pr} -> pr * 0.5
      {br, pr} -> br + (pr * 0.5)
    end
  end
end
