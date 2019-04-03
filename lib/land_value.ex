defmodule Properties.LandValue do
  use Ecto.Schema
  import Ecto.Query
  import Geo.PostGIS
  alias Properties.{Assessment, Repo, ShapeFile}
  require Logger

  def run() do
    tax_keys_and_shapes = from(a in Assessment, where: a.year == 2018 and a.last_assessment_amount > 0,
      distinct: a.tax_key,
      join: s in ShapeFile, on: s.taxkey == a.tax_key,
      select: {a.tax_key, s.geom}
    )
    |> Repo.all(timeout: :infinity)

    tax_keys_and_shapes
    |> Task.async_stream(&near/1, max_concurrency: 70, timeout: :infinity)
    |> Stream.map(fn({:ok, {tax_key, results}}) ->
      split = Enum.split_with(results, fn(%{tax_key: tax_key1}) ->
        tax_key ==  tax_key1
      end)

      case split do
        {[target], near} ->
          {tax_key, %{target: target, near: near}}
        _ ->
          Logger.error "not found #{tax_key}"
          nil
      end
    end)
    |> Stream.reject(fn(result) ->
      is_nil(result)
    end)
    |> Enum.into(%{})
  end

  def near({tax_key, shape}) do
    query = from(s in ShapeFile,
      join: a in Assessment, on: a.tax_key == s.taxkey and a.year == 2018,
      where: st_intersects(s.geom, ^shape),
      select: %{
        tax_key: s.taxkey,
        area: st_area(s.geom),
        lot_area: a.lot_area,
        land_assessment: a.last_assessment_land,
        land_use: a.land_use
      })

      results = Repo.all(query, timeout: :infinity)

    {tax_key, results}
  end

  def sort_by_largest_diff(list) do
    Enum.filter(list, fn({_tax_key, %{target: %{land_assessment: assessment, lot_area: area, land_use: land_use}, near: near}}) ->
      length(near) > 0 && land_use == "8810" && assessment > 0
    end)
    |> Enum.sort_by(fn({tax_key, %{target: %{lot_area: area, land_assessment: assessment}, near: near}}) ->
      dollar_sq_foot = assessment / area
      Enum.map(near, fn(%{lot_area: area, land_assessment: assessment, land_use: land_use}) ->
        if land_use != "8811" && assessment > 0 do
          abs((assessment / area) - dollar_sq_foot) / dollar_sq_foot
        else
          0
        end
      end)
      |> Enum.max
      |> IO.inspect(label: tax_key)
    end)
  end
end
