defmodule PropertiesWeb.TwitterController do
  use PropertiesWeb, :controller

  def crc(conn, %{"crc_token" => crc_token}) do
    consumer_secret = Application.get_env(:properties, :twitter_consumer_secret)
    response_token = :crypto.hmac(:sha256, consumer_secret, crc_token)
                     |> Base.encode16

    render(conn, "crc.json", response_token: response_token)
  end

  def index(conn, _params) do
    send_resp(conn, 200, "oops")
    |> halt()
  end
end
