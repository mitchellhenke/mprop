defmodule Properties.Assessment do
  use Ecto.Schema
  import Ecto.Query

  @optional_fields [:tax_rate_cd, :house_number_high, :house_number_low,
                    :street_direction, :street, :street_type, :last_assessment_year,
                    :last_assessment_land, :last_assessment_improvements,
                    :last_assessment_amount, :last_assessment_land_exempt,
                    :last_assessment_improvements_exempt,
                    :last_assessment_amount_exempt, :exemption_code,
                    :building_area, :year_built,
                    :number_of_bedrooms, :number_of_bathrooms,
                    :number_of_powder_rooms, :lot_area, :zoning, :building_type,
                    :zip_code, :air_conditioning, :fireplace, :parking_type,
                    :number_units, :neighborhood, :geo_tract, :geo_block, :convey_datetime,
                    :convey_type, :geo_alder, :year, :land_use, :land_use_general]

schema "assessments" do
    field :tax_key, :string
    field :tax_rate_cd, :integer
    field :house_number_high, :string
    field :house_number_low, :string
    field :street_direction, :string
    field :street, :string
    field :street_type, :string
    field :last_assessment_year, :integer
    field :last_assessment_land, :integer
    field :last_assessment_improvements, :integer
    field :last_assessment_amount, :integer
    field :last_assessment_land_exempt, :integer
    field :last_assessment_improvements_exempt, :integer
    field :last_assessment_amount_exempt, :integer
    field :exemption_code, :string
    field :building_area, :integer
    field :year_built, :integer
    field :number_of_bedrooms, :integer
    field :number_of_bathrooms, :integer
    field :number_of_powder_rooms, :integer
    field :lot_area, :integer
    field :zoning, :string
    field :building_type, :string
    field :zip_code, :string
    field :land_use, :string
    field :land_use_general, :string
    field :fireplace, :integer
    field :air_conditioning, :integer
    field :parking_type, :string
    field :number_units, :integer
    field :attic, :string
    field :basement, :string
    field :neighborhood, :string
    field :geo_tract, :string
    field :geo_block, :string
    field :geo_alder, :string
    field :convey_datetime, :naive_datetime
    field :convey_type, :string
    field :year, :integer
    field :distance, :float, virtual: true
    field :other_assessments, {:array, :map}, virtual: :true
    field :sales, {:array, :map}, virtual: :true
    field :latitude, :float, virtual: true
    field :longitude, :float, virtual: :true

    belongs_to :property, Properties.Property
    timestamps()
  end

  def changeset(model, params) do
    model
    |> Ecto.Changeset.cast(params, [:tax_key, :property_id] ++ @optional_fields)
    |> Ecto.Changeset.validate_required([:tax_key, :property_id])
    |> Ecto.Changeset.assoc_constraint(:property)
    |> Ecto.Changeset.unique_constraint(:tax_key, name: :assessments_year_tax_key_index)
  end

  def address(property) do
    zip_code = String.slice(property.zip_code, 0, 5)
    "#{property.house_number_low} #{property.street_direction} #{property.street} #{property.street_type}, Milwaukee, WI #{zip_code}"
  end

  def bathroom_count(assessment) do
    case {assessment.number_of_bathrooms, assessment.number_of_powder_rooms} do
      {nil, nil} -> 0
      {br, nil} -> br
      {nil, pr} -> pr * 0.5
      {br, pr} -> br + (pr * 0.5)
    end
  end

  def street_type("TR"), do: "TERRACE"
  def street_type("CR"), do: "CIRCLE"
  def street_type("AV"), do: "AVENUE"
  def street_type("ST"), do: "STREET"
  def street_type(type), do: type

  def maybe_within(query, nil, _), do: query
  def maybe_within(query, _, nil), do: query
  def maybe_within(query, point, radius_in_m), do: within(query, point, radius_in_m)

  def within(query, point, radius_in_m) do
    {lng, lat} = point.coordinates
    from([property, shapefile] in query,
      where: fragment("ST_DWithin(?::geography, ST_SetSRID(ST_MakePoint(?, ?), ?)::geography, ?)", shapefile.geom_point, ^lng, ^lat, ^point.srid, ^radius_in_m))
  end

  def order_by_nearest(query, point) do
    {lng, lat} = point.coordinates
    from(property in query, order_by: fragment("? <-> ST_SetSRID(ST_MakePoint(?,?), ?)", property.geom, ^lng, ^lat, ^point.srid))
  end

  def select_with_distance(query, point) do
    {lng, lat} = point.coordinates
    from(property in query,
         select: %{property | distance: fragment("ST_Distance_Sphere(?, ST_SetSRID(ST_MakePoint(?,?), ?))", property.geom, ^lng, ^lat, ^point.srid)})
  end

  def with_joined_shapefile(queryable) do
    if has_named_binding?(queryable, :shapefile) do
      queryable
    else
      queryable
      |> join(:left, [assessment], shapefile in Properties.ShapeFile, on: shapefile.taxkey == assessment.tax_key, as: :shapefile)
    end
  end

  def select_latitude_longitude(query) do
    from([assessment, shapefile] in query, select: %{assessment | longitude: fragment("ST_X(?)", shapefile.geom_point), latitude: fragment("ST_Y(?)", shapefile.geom_point)})
  end

  def filter_by_address(query, nil), do: query
  def filter_by_address(query, ""), do: query
  def filter_by_address(query, text_query) do
    text_query = transform_text_query(text_query)

    from(s in query, where: fragment("? @@ to_tsquery(?, ?)", s.full_address_vector, "simple", ^text_query))
  end

  def order_by_address_text_search(query, nil), do: query
  def order_by_address_text_search(query, ""), do: query
  def order_by_address_text_search(query, text_query) do
    text_query = transform_text_query(text_query)
    from(q in query,
      order_by: fragment("ts_rank_cd(?, ?)", q.full_address_vector, ^text_query))
  end

  def filter_greater_than(query, _, nil), do: query
  def filter_greater_than(query, :bathrooms, number) do
    from(p in query,
       where: fragment("(? + (coalesce(?, 0) * 0.5)) >= ?", p.number_of_bathrooms, p.number_of_powder_rooms, ^number))
  end

  def filter_greater_than(query, field, number) do
    from(p in query,
       where: field(p, ^field) >= ^number)
  end

  def filter_less_than(query, _, nil), do: query
  def filter_less_than(query, :bathrooms, number) do
    from(p in query,
       where: fragment("(? + (coalesce(?, 0) * 0.5)) <= ?", p.number_of_bathrooms, p.number_of_powder_rooms, ^number))
  end

  def filter_less_than(query, field, number) do
    from(p in query,
       where: field(p, ^field) <= ^number)
  end

  def filter_by_zipcode(query, nil), do: query
  def filter_by_zipcode(query, ""), do: query
  def filter_by_zipcode(query, zipcode) do
    if String.length(zipcode) != 5 do
      query
    else
      from(p in query,
         where: fragment("substring(?, 0, 6) = ?", p.zip_code, ^zipcode)
       )
    end
  end

  def maybe_filter_by(query, _field, nil), do: query
  def maybe_filter_by(query, _field, ""), do: query
  def maybe_filter_by(query, field, value) do
    from(p in query,
       where: field(p, ^field) == ^value
     )
  end

  defp transform_text_query(text_query) do
    String.upcase(text_query)
    |> String.split()
    |> Enum.join(" & ")
  end
end
