defmodule PropertiesWeb.TwitterController do
  use PropertiesWeb, :controller

  plug :handle_crc_check

  def twitter(conn, _params) do
    send_resp(conn, 200, "oops")
    |> halt()
  end

  defp is_crc_check?(%{"crc_token" => _token}), do: true
  defp is_crc_check?(_params), do: false

  def handle_crc_check(conn, _opts) do
    if is_crc_check?(conn.params) do
      crc_token = Map.get(conn.params, "crc_token")
      consumer_secret = Application.get_env(:properties, :twitter_consumer_secret)
      response_token = :crypto.hmac(:sha256, consumer_secret, crc_token)
                       |> Base.encode16

      render(conn, "crc.json", response_token: response_token)
    else
      conn
    end
  end
end
