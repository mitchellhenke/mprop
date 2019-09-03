defmodule PropertiesWeb.MapView do
  use PropertiesWeb, :view

  def render("index.json", %{shapefiles: shapefiles}) do
    covs = Enum.map(shapefiles, &(&1.adjacent_cov))
           |> Enum.filter(&(&1 > 0.0))
           |> Enum.sort()
    percentiles = percentiles(covs)
    Enum.map(shapefiles, fn(shapefile) ->
      render("show.json", %{shapefile: shapefile, percentiles: percentiles})
    end)
  end

  def render("show.json", %{shapefile: shapefile, percentiles: p}) do
    assessment_sq_foot = assessment_sq_foot(shapefile.assessment)

    %{
      geometry: shapefile.geo_json,
      type: "Feature",
      properties: %{
        tax_key: shapefile.assessment.tax_key,
        popupContent: """
        <a href=\"/properties/#{shapefile.assessment.tax_key}\" target=\"_blank\">Assessment Link</a>
        <p>Zoning: #{shapefile.assessment.zoning}</p>
        <p>Lot Area: #{shapefile.assessment.lot_area} sq ft</p>
        <p>Land Assessment: $#{shapefile.assessment.last_assessment_land}</p>
        <p>#{assessment_sq_foot} $/sq ft</p>
        """,
        style: %{
          weight: 1,
          color: "#999",
          opacity: 1,
          fillColor: fill_color(shapefile, p),
          fillOpacity: 0.8
        }
      },
    }
  end

  def render("lead_index_reject.json", %{set: set, shapefiles: shapefiles}) do
    {set, shapefiles} = Enum.reduce(shapefiles, {set, []}, fn(shapefile, {set, list}) ->
      if MapSet.member?(set, id(shapefile)) do
        {set, list}
      else
        json = render("lead_show.json", %{shapefile: shapefile})
        {MapSet.put(set, id(shapefile)), [json | list]}
      end
    end)

    {set,
      %{
        shapefiles: shapefiles,
      }
    }
  end

  def render("lead_legend.json", %{}) do
    %{
      legend: %{
        name: "lead",
        colors: ["#FF0000"],
        labels: ["Lead Service Line"],
      }
    }
  end

  def render("bike_lanes_legend.json", %{}) do
    %{
      legend: %{
        name: "bike_lanes",
        colors: ["#4AA564", "#E31C3D"],
        labels: ["Bike Lane", "Trail"],
      }
    }
  end

  def render("lead_index.json", %{shapefiles: shapefiles}) do
    shapefiles = Enum.map(shapefiles, fn(shapefile) ->
      ConCache.get_or_store(:lead_service_render_cache, shapefile.assessment.tax_key, fn ->
        render("lead_show.json", %{shapefile: shapefile})
      end)
    end)

    %{
      shapefiles: shapefiles,
      legend: %{
        name: "lead",
        colors: ["#FF0000"],
        labels: ["Lead Service Line"],
      }
    }
  end

  def render("lead_show.json", %{shapefile: shapefile}) do
    {color, address} = if not is_nil(shapefile.lead_service_line_address) do
      {"#FF0000", String.replace(shapefile.lead_service_line_address, "- ", " ")}
    else
      {"", ""}
    end
    %{
      geometry: shapefile.geo_json,
      type: "Feature",
      properties: %{
        tax_key: shapefile.assessment.tax_key,
        id: id(shapefile),
        popupContent: """
        <div>#{address}</div>
        <a href=\"/properties/#{shapefile.assessment.tax_key}\" target=\"_blank\">Assessment Link</a>
        """,
        style: %{
          weight: 1,
          color: "#999",
          opacity: 1,
          fillColor: color,
          fillOpacity: 0.8
        }
      },
    }
  end

  def render("percent_change_index.json", %{shapefiles: shapefiles}) do
    shapefiles = Enum.map(shapefiles, fn(shapefile) ->
      render("percent_change_show.json", %{shapefile: shapefile})
    end)

    %{
      shapefiles: shapefiles,
      legend: %{
        colors: ["#003F5C", "#2F4B7C", "#665191", "#A05195", "#D45087", "#F95D6A", "#FF7C43", "#FFA600", "#FF0000"],
        labels: ["1", "2", "3", "4", "5", "6", "7", "8", "9"],
      }
    }
  end

  def render("percent_change_show.json", %{shapefile: shapefile}) do
    %{
      geometry: shapefile.geo_json,
      type: "Feature",
      properties: %{
        tax_key: shapefile.assessment.tax_key,
        id: id(shapefile),
        style: %{
          weight: 2,
          color: "#999",
          opacity: 1,
          fillColor: fill_color(shapefile.assessment.percent_change, :percent_assessment_change),
          fillOpacity: 0.8
        }
      },
    }
  end

  def render("bike_index.json", %{shapefiles: shapefiles}) do
    shapefiles = Enum.map(shapefiles, fn(shapefile) ->
      render("bike_show.json", %{shapefile: shapefile})
    end)

    %{
      shapefiles: shapefiles,
      legend: %{
        name: "bike_lanes",
        colors: ["#4AA564", "#E31C3D"],
        labels: ["Bike Lane", "Trail"],
      }
    }
  end

  def render("bike_show.json", %{shapefile: shapefile}) do
    %{
      geometry: shapefile.geo_json,
      type: "Feature",
      properties: %{
        gid: shapefile.gid,
        type: shapefile.type,
        id: id(shapefile),
        style: %{
          weight: 2,
          color: if(shapefile.type in ["BIKE LANE", "BUFFERED BIKE LANE", "PROTECTED BIKE LANE"], do: "#4AA564", else: "#E31C3D"),
          opacity: 1,
          fillColor: "#FF0000",
          fillOpacity: 0.8
        }
      },
    }
  end

  def render("neighborhood_show.json", %{neighborhood: neighborhood}) do
    %{
      name: neighborhood.neighborhd
    }
  end

  defp fill_color(%{assessment: %{last_assessment_land: land}}, _p) when land < 1 do
    ""
  end
  defp fill_color(%{adjacent_cov: number}, p) do
    cond do
      number <= Enum.at(p, 0) ->
        "#003F5C"
      number <= Enum.at(p, 1) ->
        "#2F4B7C"
      number <= Enum.at(p, 2) ->
        "#665191"
      number <= Enum.at(p, 3) ->
        "#A05195"
      number <= Enum.at(p, 4) ->
        "#D45087"
      number <= Enum.at(p, 5) ->
        "#F95D6A"
      number <= Enum.at(p, 6) ->
        "#FF7C43"
      number <= Enum.at(p, 7) ->
        "#FFA600"
      true ->
        "#FF0000"
    end
  end

  defp fill_color(number, :percent_assessment_change) do
    cond do
      Decimal.compare(number, Decimal.from_float(-0.061)) == Decimal.new(-1) ->
        "#003F5C"
      Decimal.compare(number, Decimal.from_float(-0.018)) == Decimal.new(-1) ->
        "#2F4B7C"
      Decimal.compare(number, Decimal.from_float(0.0)) == Decimal.new(-1) ->
        "#665191"
      Decimal.compare(number, Decimal.from_float(0.021)) == Decimal.new(-1) ->
        "#A05195"
      Decimal.compare(number, Decimal.from_float(0.046)) == Decimal.new(-1) ->
        "#D45087"
      Decimal.compare(number, Decimal.from_float(0.08)) == Decimal.new(-1) ->
        "#F95D6A"
      Decimal.compare(number, Decimal.from_float(0.143)) == Decimal.new(-1) ->
        "#FF7C43"
      Decimal.compare(number, Decimal.from_float(306.0)) == Decimal.new(-1) ->
        "#FFA600"
      true ->
        "#FF0000"
    end
  end

  defp assessment_sq_foot(%{lot_area: nil, last_assessment_land: _}) do
    0
  end

  defp assessment_sq_foot(%{lot_area: _, last_assessment_land: nil}) do
    0
  end

  defp assessment_sq_foot(%{lot_area: area, last_assessment_land: assessment}) when area > 0 and assessment > 0 do
    assessment/area
  end

  defp assessment_sq_foot(_) do
    0
  end

  defp percentiles(covs) do
    count = Enum.count(covs)
    Enum.map(1..8, fn(x) ->
      Enum.at(covs, trunc(count * (x/7 - 1)))
    end)
  end

  def id(%{assessment: %{tax_key: tax_key}}), do: tax_key
  def id(%{gid: gid, type: type}), do: "#{gid}-#{type}"

  # absolute percentiles
  # .125, .25, .375, .5, .625, .75, .825, 1
  # -5200 | -1300 |    0  |  1600 |  4100 |  7500 | 13800 | 30124650
  # percent percentiles
  # -0.061 | -0.018 | 0.000 | 0.021 | 0.046 | 0.080 | 0.143 | 305.500
end
