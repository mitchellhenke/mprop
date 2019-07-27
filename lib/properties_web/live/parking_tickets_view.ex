defmodule PropertiesWeb.ParkingTicketsLiveView do
  defmodule Params do
    defstruct [:date, :license_plate]

    def change(params) do
      types = %{
        date: :date,
        license_plate: :string,
      }

      data = %Params{}

      {data, types}
      |> Ecto.Changeset.cast(params, [:date, :license_plate])
    end
  end
  use Phoenix.LiveView
  alias Properties.ParkingTicket
  alias Properties.Repo
  use Phoenix.HTML

  import Ecto.Query

  def render(assigns) do
    ~L"""
      <div>
        <h1>Milwaukee Parking Tickets 2014-2018</h1>
        <p>A website that allows searching parking tickets issued in Milwaukee</p>
        <%= form_for @changeset, "#", [phx_change: :change], fn f -> %>
          <div class="row mb-2">
            <%= label f, :license_plate, "License Plate", class: "col-sm-2 justify-content-start form-control-label" %>
            <%= text_input f, :license_plate, class: "form-control col-sm-4" %>
            <%= label f, :date, class: "col-sm-2 justify-content-start form-control-label" %>
            <%= date_input f, :date, class: "form-control col-sm-4" %>
          </div>
        <% end %>

        <table class="table table-hover mt-2">
          <thead>
            <tr>
              <th>Date</th>
              <th>Time</th>
              <th>License Plate</th>
              <th>State</th>
              <th>Location</th>
              <th>Violation</th>
              <th>Fine</th>
            </tr>
          </thead>
          <tbody>
            <%= for ticket <- @tickets do %>
              <tr>
                <td>
                  <%= ticket.date %>
                </td>
                <td>
                  <%= ticket.time %>
                </td>
                <td>
                  <%= ticket.license_plate %>
                </td>
                <td>
                  <%= ticket.license_plate_state %>
                </td>
                <td>
                  <%= ticket.location %>
                </td>
                <td>
                  <%= ticket.violation_description %>
                </td>
                <td>
                  <%= ticket.fine %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    """
  end

  def handle_event("change", %{"params" => params}, socket) do
   changeset = Params.change(params)
    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, params} ->
        tickets = get_tickets(params)
        socket = assign(socket, :changeset, changeset)
                 |> assign(:tickets, tickets)
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
    socket = assign(socket, :tickets, [])
    |> assign(:changeset, Params.change(%{}))

    tickets = get_tickets(%Params{})
    socket = assign(socket, :tickets, tickets)
    {:ok, socket}
  end

  def get_tickets(params) do
    query = from(p in ParkingTicket,
      order_by: [asc: p.date, asc: p.time],
      limit: 2_000)
      |> ParkingTicket.filter_by_date(params.date)
      |> ParkingTicket.filter_by_license_plate(params.license_plate)

    Repo.all(query, timeout: :infinity)
  end
end
