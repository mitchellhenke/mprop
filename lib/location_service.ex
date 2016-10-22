defmodule Properties.LocationService do
  import Ecto.Query
  alias Properties.Property

  def get_point(address) do
    {:ok, _status, _headers, client} = :hackney.get("http://www.mapquestapi.com/geocoding/v1/address?key=5AqAp2aSqxM9KzB4jpTV0Us67kmUuVjA&location=#{URI.encode(address)}", [], "", [connect_timeout: 10000, recv_timeout: 10000])
    {:ok, body} = :hackney.body(client)
    location = Poison.decode!(body)
    |> Map.fetch!("results")
    |> List.first
    |> Map.fetch!("locations")
    |> List.first
    quality_code = Map.fetch!(location, "geocodeQualityCode")
    quality = Map.fetch!(location, "geocodeQuality")

    lat_lng = Map.fetch!(location, "latLng")

    if quality_code == "P1AAA" and quality == "POINT" do
      lat = Map.fetch!(lat_lng, "lat")
      lng = Map.fetch!(lat_lng, "lng")
      {:ok, {lat, lng}}
    else
      IO.inspect quality_code
      IO.inspect quality
      {:error, :bad}
    end
  end

  def get_google_point(address) do
    url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{URI.encode(address)}&key=AIzaSyAfjiLtPjTZABu5nGqBLMEBs5yOQhH4uac"
    {:ok, _status, _headers, client} = :hackney.get(url, [], "", [connect_timeout: 10000, recv_timeout: 10000])
    {:ok, body} = :hackney.body(client)
    location = Poison.decode!(body)
               |> Map.fetch!("results")
               |> List.first
               |> Map.fetch!("geometry")

    location_type = Map.fetch!(location, "location_type")
    lat_lng = Map.fetch!(location, "location")

    if location_type == "ROOFTOP" do
      lat = Map.fetch!(lat_lng, "lat")
      lng = Map.fetch!(lat_lng, "lng")
      {:ok, {lat, lng}}
    else
      IO.inspect location_type
      {:error, :bad}
    end
  end

  def point_from_address(address) do
    case get_google_point(address) do
      {:ok, {lat, lng}} ->
        {:ok, %Geo.Point{coordinates: {lng, lat}, srid: 4326}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def update_property_with_geom(%Property{geom: nil} = property) do
    result = Property.address(property)
    |> point_from_address

    case result do
      {:ok, point} ->
        Property.changeset(property, %{"geom" => point})
                                                |> Properties.Repo.update!
      {:error, reason} ->
        IO.inspect property.id
        ":("
    end

  end

  def near(query, {lat, lng}, radius_meters) do
    from(p in query, where: fragment("ST_Distance_Sphere(?, ST_MakePoint(?, ?))", p.geom, ^lng, ^lat) < ^radius_meters)
  end

  # import Ecto.Query; from(i in Properties.Property, where: fragment("substring(?, 0, 6)", i.zip_code) == "53207" and i.land_use == "8810" and is_nil(i.geom)) |> Properties.Repo.all |> Enum.each(fn(p) -> :timer.sleep(50); Properties.LocationService.update_property_with_geom(p) end)
end
