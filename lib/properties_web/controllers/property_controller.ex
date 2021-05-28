defmodule PropertiesWeb.PropertyController do
  use PropertiesWeb, :controller
  alias Properties.Assessment
  alias Properties.Sale

  def show(conn, %{"id" => id}) do
    query =
      if length(String.codepoints(id)) == 10 do
        from(a in Assessment, where: a.tax_key == ^id and a.year == 2020)
      else
        id = String.to_integer(id)
        from(a in Assessment, where: a.id == ^id)
      end

    assessment =
      query
      |> Assessment.with_joined_shapefile()
      |> Assessment.select_latitude_longitude()
      |> Repo.one()
      |> Assessment.preload_shapefile()

    key = assessment.tax_key

    other_assessments =
      from(a in Assessment, where: a.tax_key == ^key)
      |> Repo.all()

    sales =
      from(s in Sale, where: s.tax_key == ^key)
      |> Repo.all()

    assessment = %{assessment | sales: sales, other_assessments: other_assessments}
    nearby_assessments = Assessment.similar_nearby_assessments(assessment)
    render(conn, "show.html", assessment: assessment, nearby_assessments: nearby_assessments)
  end
end
