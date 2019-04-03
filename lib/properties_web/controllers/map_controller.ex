defmodule PropertiesWeb.MapController do
  use PropertiesWeb, :controller
  alias Properties.Assessment

  action_fallback PropertiesWeb.FallbackController


  def index(conn, _params) do
    render(conn, "index.html")
  end
end
