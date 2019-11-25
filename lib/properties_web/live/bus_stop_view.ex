defmodule PropertiesWeb.BusStopLiveView do
  defmodule Params do
    defstruct [:date, :time, :text_query, :radius_meters]

    def change(params) do
      types = %{
        text_query: :string,
        radius_meters: :integer,
        date: :date,
        time: :time
      }

      data = %Params{}

      {data, types}
      |> Ecto.Changeset.cast(params, [:text_query, :radius_meters, :date, :time])
      |> Ecto.Changeset.validate_required([:radius_meters, :date, :time])
      |> Ecto.Changeset.validate_number(:radius_meters, less_than_or_equal_to: 2_000, greater_than: 0)
    end
  end
  use Phoenix.LiveView
  alias Properties.Assessment
  alias Transit.Stop
  alias Properties.Repo
  use Phoenix.HTML

  import Ecto.Query

  def render(assigns) do
    ~L"""
      <div>
        <h1>Milwaukee Nearby Bus Stops</h1>
        <p>Type in an address, and you'll see bus stops for the top result on the given day and hour within the radius.</p>
        <%= form_for @changeset, "#", [phx_change: :change], fn f -> %>
           <div class="row mb-2">
            <%= label f, :date, class: "col-sm-1 justify-content-start form-control-label" %>
            <%= date_input f, :date, class: "form-control col-sm-2" %>
            <%= label f, :time, class: "col-sm-1 justify-content-start form-control-label" %>
            <%= time_input f, :time, class: "form-control col-sm-2" %>
            <%= label f, :radius_meters, "Radius (m)", class: "col-sm-2 justify-content-start form-control-label" %>
            <%= number_input f, :radius_meters, class: "form-control col-sm-1" %>
           </div>
          <div class="row mb-2">
            <div class="col-sm-3">
              <%= PropertiesWeb.ViewHelper.error_tag f, :date %>
            </div>
            <div class="col-sm-3">
              <%= PropertiesWeb.ViewHelper.error_tag f, :time %>
            </div>
            <div class="col-sm-6">
              <%= PropertiesWeb.ViewHelper.error_tag f, :radius_meters %>
            </div>
          </div>
          <div class="row mb-2">
            <%= label f, :text_query, "Address Search", class: "col-sm-2 justify-content-start form-control-label" %>
            <%= text_input f, :text_query, class: "form-control col-sm-10" %>
          </div>
        <% end %>

        <table class="table table-hover mt-2 bus-stop-search property-results">
          <thead>
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

        <table class="table table-hover mt-2">
          <thead>
            <tr>
              <th>Route</th>
              <th>Direction</th>
              <th>Stop Location</th>
              <th>Distance (m)</th>
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
                  <%= round(stop.distance) %>m
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
    default_params = %{"date" => date, "time" => time, "radius_meters" => 400}
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
    {:noreply, live_redirect(socket, replace: true, to: PropertiesWeb.Router.Helpers.live_path(socket, __MODULE__, params))}
  end

  def handle_event(_, _value, socket) do
    {:noreply, socket}
  end

  def mount(_session, socket) do
    socket = assign(socket, :properties, [])
             |> assign(:stops, [])
             |> assign(:changeset, Params.change(%{date: Date.utc_today(), time: Time.utc_now(), radius_meters: 400}))
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
        point = %Geo.Point{coordinates: {property.longitude, property.latitude}, srid: 4326}
        Stop.get_nearest(point, params.radius_meters, params.date, params.time)
      [] ->
        []
    end
  end
end
