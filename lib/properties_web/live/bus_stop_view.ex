defmodule PropertiesWeb.BusStopLiveView do
  defmodule Params do
    defstruct [:date, :time, :text_query, :radius_miles]

    def change(params) do
      types = %{
        text_query: :string,
        radius_miles: :float,
        date: :date,
        time: :time
      }

      data = %Params{}

      {data, types}
      |> Ecto.Changeset.cast(params, [:text_query, :radius_miles, :date, :time])
      |> Ecto.Changeset.validate_required([:radius_miles, :date, :time])
      |> Ecto.Changeset.validate_number(:radius_miles, less_than_or_equal_to: 1.25, greater_than: 0)
    end
  end
  use Phoenix.LiveView
  alias Properties.Assessment
  alias Transit.{Feed, Stop}
  alias Properties.Repo
  use Phoenix.HTML

  import Ecto.Query

  def render(assigns) do
    ~L"""
      <div>
        <h1>Milwaukee Nearby Bus Stops</h1>
        <p>
          Type in an address, and you'll see nearby bus stops that have a bus scheduled within 30 minutes on either side of the given time.<br>
          The page link also updates as you change the search, so you can share it with others!<br>
       </p>
        <p>
          For further information on planning a trip, visit <%= link("https://www.ridemcts.com/trip-planner", to: "https://www.ridemcts.com/trip-planner") %>.
       </p>
        <%= form_for @changeset, "#", [phx_change: :change], fn f -> %>
           <div class="form-row">
              <div class="form-group col-md-3">
                <%= label f, :date %>
                <%= date_input f, :date, class: "form-control" %>
              </div>
              <div class="form-group col-md-3">
                <%= label f, :time %>
                <%= time_input f, :time, class: "form-control" %>
              </div>
              <div class="form-group col-md-3">
                <%= label f, :radius_miles, "Radius (miles)" %>
                <%= number_input f, :radius_miles, class: "form-control", step: "0.01" %>
              </div>
           </div>
          <div class="form-row">
            <div class="col-sm-3">
              <%= PropertiesWeb.ViewHelper.error_tag f, :date %>
            </div>
            <div class="col-sm-3">
              <%= PropertiesWeb.ViewHelper.error_tag f, :time %>
            </div>
            <div class="col-sm-6">
              <%= PropertiesWeb.ViewHelper.error_tag f, :radius_miles %>
            </div>
          </div>
          <div class="form-row">
            <div class="form-group col-md-12">
              <%= label f, :text_query, "Address Search" %>
              <%= text_input f, :text_query, class: "form-control" %>
            </div>
          </div>
        <% end %>

        <table class="table table-hover mt-2 mb-2 bus-stop-search property-results">
          <thead>
            <tr>
              <th>Search Results</th>
            </tr>
          </thead>
          <tbody>
            <%= for properties <- Enum.chunk_every(@properties, 2)  do %>
              <tr>
                <%= for property <- properties do %>
                  <td><%= Assessment.address(property) %></td>
                <% end %>
              </tr>
            <% end %>
          </tbody>
        </table>

        <h2><%= bus_stops_near_header(@properties) %></h2>
        <table class="table table-hover mt-2">
          <thead>
            <tr>
              <th>Route</th>
              <th>Direction</th>
              <th>Stop Location</th>
              <th>Distance (miles)</th>
            </tr>
          </thead>
          <tbody>
            <%= for stop <- @stops do %>
              <tr>
                <td>
                  <%= stop.route_id %>
                </td>
                <td>
                  <%= stop.trip_headsign %>
                </td>
                <td>
                  <%= stop.stop_name %>
                </td>
                <td>
                  <%= Float.round(stop.distance / 1609.34, 2) %> miles
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    """
  end

  def handle_params(params, _uri, socket) do
    {:ok, now} = DateTime.now("America/Chicago")
    time = DateTime.to_time(now)
    date = DateTime.to_date(now)
    default_params = %{"date" => date, "time" => time, "radius_miles" => 0.25}
    params = Map.merge(default_params, params)
    changeset = Params.change(params)
    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, params} ->
        properties = get_properties(params)
        stops = get_stops(properties, params)
        socket = assign(socket, :changeset, changeset)
                 |> assign(:stops, stops)
                 |> assign(:properties, properties)
        {:noreply, socket}
      {:error, error_changeset} ->
        socket = assign(socket, :changeset, error_changeset)
        {:noreply, socket}
    end
  end

  def handle_event("change", %{"params" => params}, socket) do
    {:noreply, push_patch(socket, replace: true, to: PropertiesWeb.Router.Helpers.live_path(socket, __MODULE__, params))}
  end

  def handle_event(_, _value, socket) do
    {:noreply, socket}
  end

  def mount(_params, _session, socket) do
    socket = assign(socket, :properties, [])
             |> assign(:stops, [])
             |> assign(:changeset, Params.change(%{date: Date.utc_today(), time: Time.utc_now(), radius_miles: 0.25}))
    {:ok, socket}
  end

  def get_properties(params) do
    if is_nil(params.text_query) do
      []
    else
      query = from(p in Assessment,
        where: p.year == 2018,
        limit: 6)
        |> Assessment.filter_by_address(params.text_query)
        |> Assessment.with_joined_shapefile()
        |> Assessment.select_latitude_longitude()

      Repo.all(query, timeout: :infinity)
    end
  end

  def get_stops(properties, params) do
    case properties do
      [property | _rest] ->
        meters = params.radius_miles * 1609.34
        point = %Geo.Point{coordinates: {property.longitude, property.latitude}, srid: 4326}
        feed = Feed.get_first_after_date(params.date)
        Stop.get_nearest(point, meters, params.date, params.time, feed.id)
      [] ->
        []
    end
  end

  def bus_stops_near_header([]), do: "Bus Stops"
  def bus_stops_near_header([property | _]) do
    address = Assessment.address(property)
    "Bus Stops near #{address}"
  end
end
