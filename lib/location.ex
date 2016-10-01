defmodule Properties.Location do
  defstruct latitude: nil, longitude: nil, radius_in_m: nil

  def from_params(%{"latitude" => nil}), do: nil
  def from_params(%{"longitude" => nil}), do: nil
  def from_params(%{"latitude" => latitude, "longitude" => longitude} = params) do
    radius_in_m = Map.get(params, "radius", "32000")
    with {:ok, latitude} <- parse_float(latitude),
         {:ok, longitude} <- parse_float(longitude),
         {:ok, radius_in_m} <- parse_integer(radius_in_m),
         do: %Properties.Location{latitude: latitude, longitude: longitude, radius_in_m: radius_in_m}
  end

  def from_params(_), do: nil

  defp parse_float(float) when is_float(float), do: {:ok, float}
  defp parse_float(string) when is_binary(string) do
    case Float.parse(string) do
      {float, ""} -> {:ok, float}
      _ -> nil
    end
  end

  defp parse_integer(integer) when is_integer(integer), do: {:ok, integer}
  defp parse_integer(float) when is_float(float), do: {:ok, round(float)}
  defp parse_integer(string) when is_binary(string) do
    case Float.parse(string) do
      {float, ""} -> {:ok, round(float)}
      _ -> nil
    end
  end
end

