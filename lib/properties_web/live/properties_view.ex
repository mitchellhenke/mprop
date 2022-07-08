defmodule PropertiesWeb.PropertiesLiveView do
  defmodule Params do
    defstruct [
      :year,
      :text_query,
      :min_year_built,
      :max_year_built,
      :min_number_stories,
      :max_number_stories,
      :min_bath,
      :max_bath,
      :num_units,
      :min_bed,
      :max_bed,
      :zoning,
      :min_lot_area,
      :max_lot_area,
      :alder,
      :zip_code,
      :land_use,
      :parking_type,
      :building_type,
      :latitude,
      :longitude,
      :radius
    ]

    def change(params) do
      types = %{
        text_query: :string,
        min_year_built: :integer,
        max_year_built: :integer,
        min_number_stories: :integer,
        max_number_stories: :integer,
        min_bath: :integer,
        max_bath: :integer,
        min_bed: :integer,
        max_bed: :integer,
        zoning: :string,
        min_lot_area: :integer,
        max_lot_area: :integer,
        alder: :string,
        num_units: :integer,
        latitude: :float,
        longitude: :float,
        radius: :decimal,
        zip_code: :string,
        land_use: :string,
        parking_type: :string,
        building_type: :string
      }

      data = %Params{}

      {data, types}
      |> Ecto.Changeset.cast(params, [
        :text_query,
        :min_year_built,
        :max_year_built,
        :min_number_stories,
        :max_number_stories,
        :min_bath,
        :max_bath,
        :num_units,
        :min_bed,
        :max_bed,
        :zoning,
        :min_lot_area,
        :max_lot_area,
        :alder,
        :zip_code,
        :land_use,
        :parking_type,
        :building_type,
        :latitude,
        :longitude,
        :radius
      ])
      |> Ecto.Changeset.validate_number(:radius, less_than_or_equal_to: 2_000, greater_than: 0)
    end

    def update_location(changeset, params) do
      Ecto.Changeset.cast(changeset, params, [:latitude, :longitude, :radius])
      |> Ecto.Changeset.validate_number(:radius, less_than_or_equal_to: 2_000, greater_than: 0)
    end
  end

  use Phoenix.LiveView, layout: {PropertiesWeb.LayoutView, "live.html"}
  alias Properties.Assessment
  alias Properties.Repo
  use Phoenix.HTML

  import Ecto.Query

  def render(assigns) do
    Phoenix.View.render(PropertiesWeb.PropertyView, "index.html", assigns)
  end

  def handle_event("change", %{"params" => params}, socket) do
    changeset = Params.change(params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, params} ->
        properties = get_properties(params)

        socket =
          assign(socket, :changeset, changeset)
          |> assign(:properties, properties)

        {:noreply, socket}

      {:error, error_changeset} ->
        socket = assign(socket, :changeset, error_changeset)
        {:noreply, socket}
    end
  end

  def handle_event("search_near_me:" <> tax_key, _value, socket) do
    with %{latitude: lat, longitude: long} <-
           Enum.find(socket.assigns.properties, &(&1.tax_key == tax_key)),
         changeset <-
           Params.update_location(socket.assigns.changeset, %{
             latitude: lat,
             longitude: long,
             radius: 500
           }) do
      case Ecto.Changeset.apply_action(changeset, :insert) do
        {:ok, params} ->
          properties = get_properties(params)

          socket =
            assign(socket, :changeset, changeset)
            |> assign(:properties, properties)

          {:noreply, socket}

        {:error, error_changeset} ->
          socket = assign(socket, :changeset, error_changeset)
          {:noreply, socket}
      end
    else
      _ ->
        {:noreply, socket}
    end
  end

  def handle_event(_, _value, socket) do
    {:noreply, socket}
  end

  def mount(_params, _session, socket) do
    socket =
      assign(socket, :properties, [])
      |> assign(:changeset, Params.change(%{}))

    properties = get_properties(%Params{})
    socket = assign(socket, :properties, properties)
    {:ok, socket}
  end

  def get_properties(params) do
    {point, radius} = build_point_and_radius(params.latitude, params.longitude, params.radius)

    query =
      from(p in Assessment,
        where: p.year == 2022,
        order_by: [desc: p.last_assessment_amount],
        limit: 50
      )
      |> Assessment.filter_by_address(params.text_query)
      |> Assessment.filter_greater_than(:number_stories, params.min_number_stories)
      |> Assessment.filter_less_than(:number_stories, params.max_number_stories)
      |> Assessment.filter_greater_than(:year_built, params.min_year_built)
      |> Assessment.filter_less_than(:year_built, params.max_year_built)
      |> Assessment.filter_greater_than(:bathrooms, params.min_bath)
      |> Assessment.filter_less_than(:bathrooms, params.max_bath)
      |> Assessment.filter_greater_than(:number_of_bedrooms, params.min_bed)
      |> Assessment.filter_less_than(:number_of_bedrooms, params.max_bed)
      |> Assessment.filter_by_zipcode(params.zip_code)
      |> Assessment.filter_by_geo_alder(params.alder)
      |> Assessment.filter_by_zoning(params.zoning)
      |> Assessment.filter_greater_than(:lot_area, params.min_lot_area)
      |> Assessment.filter_less_than(:lot_area, params.max_lot_area)
      # |> Assessment.maybe_filter_by(:land_use, "8810")
      |> Assessment.maybe_filter_by(:parking_type, params.parking_type)
      |> Assessment.maybe_filter_by(:number_units, params.num_units)
      |> Assessment.maybe_filter_by(:building_type, params.building_type)
      |> Assessment.with_joined_shapefile()
      |> Assessment.select_latitude_longitude()

    query =
      if point && radius do
        query
        |> Assessment.maybe_within(point, radius)
      else
        query
      end

    Repo.all(query, timeout: :infinity)
  end

  defp build_point_and_radius(latitude, longitude, radius_in_m) do
    if is_float(latitude) && is_float(longitude) && not is_nil(radius_in_m) do
      {%Geo.Point{coordinates: {longitude, latitude}, srid: 4326}, Decimal.to_float(radius_in_m)}
    else
      {nil, nil}
    end
  end
end
