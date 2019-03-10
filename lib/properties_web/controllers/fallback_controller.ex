defmodule PropertiesWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use PropertiesWeb, :controller

  def call(conn, {:error, :invalid_address}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(PropertiesWeb.ErrorView)
    |> render("422.json", message: "Invalid address")
  end
end
