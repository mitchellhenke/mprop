defmodule PropertiesWeb.PageController do
  use PropertiesWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
