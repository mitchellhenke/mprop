defmodule Properties.Plugs.Location do
  @behaviour Plug
  import Plug.Conn

  def init(_dc), do: []

  def call(conn, _dc) do
    location = Properties.Location.from_params(conn.params)
    if location do
      assign(conn, :location, location)
    else
      conn
    end
  end
end

