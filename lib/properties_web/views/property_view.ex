defmodule PropertiesWeb.PropertyView do
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
end
