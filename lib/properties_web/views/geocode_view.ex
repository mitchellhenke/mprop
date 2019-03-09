defmodule PropertiesWeb.GeocodeView do
  use PropertiesWeb, :view

  def render("index.json", %{assessments: assessments}) do
    %{data: render_many(assessments, PropertiesWeb.GeocodeView, "show.json", as: :assessment)}
  end

  def render("show.json", %{assessment: assessment}) do
    %{
      address: Properties.Assessment.address(assessment),
      latitude: assessment.latitude,
      longitude: assessment.longitude,
    }
  end
end
