defmodule PropertiesWeb.PropertiesLiveView do
  defmodule Params do
    defstruct [:year, :text_query, :min_bath, :max_bath, :num_units, :min_bed,
      :max_bed, :zip_code, :land_use, :parking_type]

    def change(params) do
      types = %{
        text_query: :string,
        min_bath: :integer,
        max_bath: :integer,
        min_bed: :integer,
        max_bed: :integer,
        num_units: :integer,
        zip_code: :string,
        land_use: :string,
        parking_type: :string,
      }

      data = %Params{}

      {data, types}
      |> Ecto.Changeset.cast(params, [:text_query, :min_bath, :max_bath,
        :num_units, :min_bed, :max_bed, :zip_code, :land_use, :parking_type])
    end
  end
  use Phoenix.LiveView
  alias Properties.Assessment
  alias Properties.Repo
  use Phoenix.HTML

  import Ecto.Query
  @number_comma_regex ~r/\B(?=(\d{3})+(?!\d))/

  def render(assigns) do
    ~L"""
      <div>
        <h1>Milwaukee Property Search</h1>
        <p>A website that allows filtering by some attributes from Milwaukee's <a href='http://city.milwaukee.gov/DownloadTabularData3496.htm?docid=3496'>Master Property Record</a></p>
        </h1>
        <%= form_for @changeset, "#", [phx_change: :change], fn f -> %>
          <div class="row mb-2">
            <%= label f, :text_query, "Address Search", class: "col-sm-2 justify-content-start form-control-label" %>
            <%= text_input f, :text_query, class: "form-control col-sm-10" %>
          </div>
          <div class="row mb-2">
            <%= label f, :min_bath, class: "col-sm-2 justify-content-start form-control-label" %>
            <%= number_input f, :min_bath, class: "form-control col-sm-2" %>
            <%= label f, :max_bath, class: "col-sm-2 justify-content-start form-control-label" %>
            <%= number_input f, :max_bath, class: "form-control col-sm-2" %>
            <%= label f, :num_units, class: "col-sm-2 justify-content-start form-control-label" %>
            <%= number_input f, :num_units, class: "form-control col-sm-2" %>
           </div>
           <div class="row mb-2">
            <%= label f, :min_bed, class: "col-sm-2 justify-content-start form-control-label" %>
            <%= number_input f, :min_bed, class: "form-control col-sm-2" %>
            <%= label f, :max_bed, class: "col-sm-2 justify-content-start form-control-label" %>
            <%= number_input f, :max_bed, class: "form-control col-sm-2" %>
           </div>
           <div class="row mb-2">
            <%= label f, :zip_code, class: "col-sm-2 justify-content-start form-control-label" %>
            <%= text_input f, :zip_code, class: "form-control col-sm-2" %>
            <%= label f, :parking_type, class: "col-sm-2 justify-content-start form-control-label" %>
            <%= Phoenix.HTML.Form.select f, :parking_type, ["": "", "Attached Garage": "A", "Detached Garage": "D", "Attached/Detached Garage": "AD"], class: "form-control col-sm-2" %>
          </div>
        </div>
      <% end %>

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
                <%= Phoenix.HTML.Link.link(property.tax_key, to: PropertiesWeb.Router.Helpers.property_path(PropertiesWeb.Endpoint, :show, property.tax_key)) %>
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

  def handle_event("change", %{"params" => params}, socket) do
   changeset = Params.change(params)
    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, params} ->
        properties = get_properties(params)
        socket = assign(socket, :changeset, changeset)
                 |> assign(:properties, properties)
        {:noreply, socket}
      {:error, error_changeset} ->
        socket = assign(socket, :changeset, error_changeset)
        {:noreply, socket}
   end
  end

  def handle_event(_, _value, socket) do
    {:noreply, socket}
  end

  def mount(_session, socket) do
    socket = assign(socket, :properties, [])
    |> assign(:changeset, Params.change(%{}))

    properties = get_properties(%Params{})
    socket = assign(socket, :properties, properties)
    {:ok, socket}
  end

  def get_properties(params) do
    from(p in Assessment,
      where: p.year == 2018,
      order_by: [desc: p.last_assessment_amount],
      limit: 20)
      |> Assessment.filter_by_address(params.text_query)
      |> Assessment.filter_greater_than(:bathrooms, params.min_bath)
      |> Assessment.filter_less_than(:bathrooms, params.max_bath)
      |> Assessment.filter_greater_than(:number_of_bedrooms, params.min_bed)
      |> Assessment.filter_less_than(:number_of_bedrooms, params.max_bed)
      |> Assessment.filter_by_zipcode(params.zip_code)
      |> Assessment.maybe_filter_by(:land_use, "8810")
      |> Assessment.maybe_filter_by(:parking_type, params.parking_type)
      |> Assessment.maybe_filter_by(:number_units, params.num_units)
      |> Repo.all(timeout: :infinity)
  end

  defp comma_separated_number(nil), do: nil
  defp comma_separated_number(num) do
    Regex.replace(@number_comma_regex, "#{num}", ",")
  end
end
