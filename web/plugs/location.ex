defmodule Properties.Plugs.Location do
  @behaviour Plug
  import Plug.Conn

  def init(_dc), do: []

  def call(conn, _dc) do
    location = Properties.Location.from_params(conn.params)
    assign(conn, :location, location)
  end
end

