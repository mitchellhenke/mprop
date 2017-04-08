defmodule Properties.PropertyView do
  use Properties.Web, :view

  def render("index.json", %{properties: properties}) do
    %{data: render_many(properties, Properties.PropertyView, "show.json")}
  end

  def render("show.json", %{property: property}) do
    %{
      id: property.id,
      tax_key: property.tax_key,
    }
  end
end
