defmodule PropertiesWeb.ViewHelper do
  @number_regex ~r/\B(?=(\d{3})+(?!\d))/
  def number_with_commas(number) do
    number = to_string(number)
    Regex.replace(@number_regex, number, ",")
  end

  def air_conditioning(ac) when ac == "1", do: "Yes"
  def air_conditioning(_), do: "No"
  def parking_type(nil), do: "None"
  def parking_type(parking_type), do: parking_type

  def mapbox_static(latitude, longitude) do
    "https://api.mapbox.com/styles/v1/mapbox/streets-v10/static/geojson(%7B%22type%22%3A%22Point%22%2C%22coordinates%22%3A%5B#{longitude}%2C#{latitude}%5D%7D)/#{longitude},#{latitude},14/500x300?access_token=pk.eyJ1IjoibWl0Y2hlbGxoZW5rZSIsImEiOiJjam5ybXN5ZnQwOXpkM3BwYXo3ZDY4aHJzIn0.ktVRbqOVQpj75MqJPZueCA"
  end
end
