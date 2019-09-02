defmodule PropertiesWeb.MapChannel do
  use Phoenix.Channel

  def join("map:" <> _map, _message, socket) do
    socket = assign(socket, :object_id_set, MapSet.new())
    {:ok, socket}
  end

  def handle_in("layer_change", %{"layer" => layer}, socket) do
    socket = assign(socket, :object_id_set, MapSet.new())
             |> assign(:layer, layer)
    case layer do
      "bike_lanes" ->
        broadcast!(socket, "layer_change", PropertiesWeb.MapView.render("bike_lanes_legend.json"))
      "lead" ->
        broadcast!(socket, "layer_change", PropertiesWeb.MapView.render("lead_legend.json"))
      _ -> nil
    end

    {:noreply, socket}
  end

  def handle_in("location_change", params, %{assigns: %{layer: "bike_lanes"}} = socket) do
    shapefiles = fetch_bike_lanes(params)
                 |> Enum.reject(fn(shape) -> MapSet.member?(socket.assigns.object_id_set, PropertiesWeb.MapView.id(shape)) end)
    response = PropertiesWeb.MapView.render("bike_index.json", shapefiles: shapefiles)
    ids = Enum.map(response[:shapefiles], &(&1[:properties][:id]))
    set = socket.assigns.object_id_set
          |> MapSet.union(MapSet.new(ids))
    broadcast!(socket, "location_change", response)
    {:noreply, assign(socket, :object_id_set, set)}
  end

  def handle_in("location_change", params, %{assigns: %{layer: "lead"}} = socket) do
    shapefiles = fetch_lead(params)
    {set, response} = PropertiesWeb.MapView.render("lead_index_reject.json", set: socket.assigns.object_id_set, shapefiles: shapefiles)

    broadcast!(socket, "location_change", response)
    {:noreply, assign(socket, :object_id_set, set)}
  end

  def handle_in("location_change", _params, socket) do
    {:noreply, socket}
  end

  def fetch_bike_lanes(params) do
    x_min = params["southWestLongitude"]
    y_min = params["southWestLatitude"]
    x_max = params["northEastLongitude"]
    y_max = params["northEastLatitude"]

    bike_shapefiles = Properties.BikeShapeFile.list(x_min, y_min, x_max, y_max)
    off_street_path_shapefiles = Properties.OffStreetPathShapeFile.list(x_min, y_min, x_max, y_max)
    bike_shapefiles ++ off_street_path_shapefiles
  end

  def fetch_lead(params) do
    x_min = params["southWestLongitude"]
    y_min = params["southWestLatitude"]
    x_max = params["northEastLongitude"]
    y_max = params["northEastLatitude"]
    Properties.LeadServiceLine.list_lead_service_lines(x_min, y_min, x_max, y_max)
  end
end
