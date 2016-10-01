defmodule Properties.PropertyController do
  use Properties.Web, :controller

  def index(conn, _params) do
    render conn, "index.json"
  end
end
