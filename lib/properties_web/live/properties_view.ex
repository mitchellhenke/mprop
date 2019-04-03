defmodule PropertiesWeb.PropertiesLiveView do
  defmodule Params do
    defstruct [:year, :text_query, :min_bath, :max_bath, :num_units, :min_bed,
      :max_bed, :zip_code, :land_use, :parking_type]
  end
  use Phoenix.LiveView
  alias Properties.Assessment
  alias Properties.Repo
  import Ecto.Query
  @number_comma_regex ~r/\B(?=(\d{3})+(?!\d))/

  def render(assigns) do
    ~L"""
      <div>
        <h1>Milwaukee Property Search</h1>
        <p>A website that allows filtering by some attributes from Milwaukee's <a href='http://city.milwaukee.gov/DownloadTabularData3496.htm?docid=3496'>Master Property Record</a></p>
        </h1>
        <form>
          <div class="row mb-2">
            <label class="col-sm-2 justify-content-start form-control-label" htmlFor="textSearch">Address Search</label>
            <input id="textSearch" type="search" class="form-control col-sm-10" value="<%= @params.text_query %>" phx-keyup="update_text_search" />
          </div>
          <div class="row mb-2">
            <label class="col-sm-2 justify-content-start form-control-label" htmlFor="minBathrooms">Min Bath</label>
            <input id="minBathrooms" type="number" class="form-control col-sm-2" value="<%= @params.min_bath %>" phx-keyup="update_min_bath" />
            <label class="col-sm-2 justify-content-start form-control-label" htmlFor="maxBathrooms">Max Bath</label>
            <input id="maxBathrooms" type="number" class="form-control col-sm-2" value="<%= @params.max_bath %>" phx-keyup="update_max_bath" />
            <label class="col-sm-2 justify-content-start form-control-label" htmlFor="number_units">Num Units</label>
            <input id="number_units" type="number" class="form-control col-sm-2" value="<%= @params.num_units %>" phx-keyup="update_num_units" />
          </div>
          <div class="row mb-2">
            <label class="col-sm-2 justify-content-start form-control-label" htmlFor="minBedrooms">Min Beds</label>
            <input id="minBedrooms" type="number" class="form-control col-sm-2" value="<%= @params.min_bed %>" phx-keyup="update_min_bed" />
            <label class="col-sm-2 justify-content-start form-control-label" htmlFor="maxBedrooms">Max Beds</label>
            <input id="maxBedrooms" type="number" class="form-control col-sm-2" value="<%= @params.max_bed %>" phx-keyup="update_max_bed" />
          </div>
          <div class="row mb-2">
            <label class="col-sm-2 justify-content-start form-control-label" htmlFor="zip_code">ZIP Code</label>
            <input id="zip_code" type="number" class="form-control col-sm-2" value="<%= @params.zip_code %>" phx-keyup="update_zip_code" />
            <label class="col-sm-2 justify-content-start form-control-label" htmlFor="land_use">Land Use</label>
            <select id="land_use" class="form-control col-sm-2" phx-change="update_land_use">
              <option value=""></option>
              <option value="8810">Single-Private Households</option>
            </select>
          </div>
        </div>
      </form>

      <table class="table table-hover mt-2">
        <thead>
          <tr>
            <th>Tax Key</th>
            <th>Address</th>
            <th>Bedrooms</th>
            <th>Bathrooms</th>
            <th>Lot Area</th>
            <th>Property Area</th>
            <th>Parking Type</th>
            <th>Link</th>
            <th>Search Near Me</th>
            <th>Assessment</th>
          </tr>
        </thead>
        <tbody>
          <%= for property <- @properties do %>
            <tr>
              <td>
                <%= property.tax_key %>
              </td>
              <td>
                <%= Assessment.address(property) %>
              </td>
              <td>
                <%= property.number_of_bedrooms %>
              </td>
              <td>
                <%= Assessment.bathroom_count(property) %>
              </td>
              <td>
                <%= comma_separated_number(property.lot_area) %>
              </td>
              <td>
                <%= comma_separated_number(property.building_area) %>
              </td>
              <td>
                <%= property.parking_type %>
              </td>
              <td>
                <a href="<%= "http://assessments.milwaukee.gov/remast.asp?taxkey=#{property.tax_key}"%>" rel="noopener noreferrer" target='_blank'>Link</a>
              </td>
              <td>
              </td>
              <td>
                <%= comma_separated_number(property.last_assessment_amount) %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    """
  end

  def handle_event("update_text_search", text_value, socket) do
    socket = update_socket_params_and_get_properties(socket, :text_query, text_value)
    {:noreply, socket}
  end

  def handle_event("update_max_bath", value, socket) do
    value = handle_maybe_integer(value)
    socket = update_socket_params_and_get_properties(socket, :max_bath, value)
    {:noreply, socket}
  end

  def handle_event("update_min_bath", value, socket) do
    value = handle_maybe_integer(value)
    socket = update_socket_params_and_get_properties(socket, :min_bath, value)
    {:noreply, socket}
  end

  def handle_event("update_max_bed", value, socket) do
    value = handle_maybe_integer(value)
    socket = update_socket_params_and_get_properties(socket, :max_bed, value)
    {:noreply, socket}
  end

  def handle_event("update_min_bed", value, socket) do
    value = handle_maybe_integer(value)
    socket = update_socket_params_and_get_properties(socket, :min_bed, value)
    {:noreply, socket}
  end

  def handle_event("update_num_units", value, socket) do
    value = handle_maybe_integer(value)
    socket = update_socket_params_and_get_properties(socket, :num_units, value)
    {:noreply, socket}
  end

  def handle_event("update_zip_code", value, socket) do
    socket = update_socket_params_and_get_properties(socket, :zip_code, value)
    {:noreply, socket}
  end

  def handle_event("update_land_use", value, socket) do
    IO.inspect value
    socket = update_socket_params_and_get_properties(socket, :land_use, value)
    {:noreply, socket}
  end

  def handle_event(s, value, socket) do
    IO.inspect s
    IO.inspect value
    {:noreply, socket}
  end

  def mount(_session, socket) do
    socket = assign(socket, :properties, [])
             |> assign(:params, %Params{year: 2017})

    properties = get_properties(socket.assigns.params)
    socket = assign(socket, :properties, properties)
    {:ok, socket}
  end

  def update_socket_params_and_get_properties(socket, param_key, param_value) do
    new_params = Map.put(socket.assigns.params, param_key, param_value)
    properties = get_properties(new_params)
    assign(socket, :params, new_params)
    |> assign(:properties, properties)
  end

  def get_properties(params) do
    from(p in Assessment,
      where: p.year == ^params.year,
      order_by: [desc: p.last_assessment_amount],
      limit: 20)
      |> Assessment.filter_by_address(params.text_query)
      |> Assessment.filter_greater_than(:bathrooms, params.min_bath)
      |> Assessment.filter_less_than(:bathrooms, params.max_bath)
      |> Assessment.filter_greater_than(:number_of_bedrooms, params.min_bed)
      |> Assessment.filter_less_than(:number_of_bedrooms, params.max_bed)
      |> Assessment.filter_by_zipcode(params.zip_code)
      |> Assessment.maybe_filter_by(:land_use, params.land_use)
      |> Assessment.maybe_filter_by(:parking_type, params.parking_type)
      |> Assessment.maybe_filter_by(:number_units, params.num_units)
      |> Repo.all
  end

  def comma_separated_number(nil), do: nil
  def comma_separated_number(num) do
    Regex.replace(@number_comma_regex, "#{num}", ",")
  end

  defp handle_maybe_integer(nil), do: nil
  defp handle_maybe_integer(binary) do
    case Integer.parse(binary) do
      {integer, _} -> integer
      _ -> nil
    end
  end
end
