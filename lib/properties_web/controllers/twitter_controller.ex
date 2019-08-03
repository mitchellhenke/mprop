defmodule PropertiesWeb.TwitterController do
  use PropertiesWeb, :controller

  def crc(conn, %{"crc_token" => crc_token}) do
    consumer_secret = Application.get_env(:properties, :twitter_consumer_secret)
    response_token = :crypto.hmac(:sha256, consumer_secret, crc_token)
                     |> Base.encode64

    render(conn, "crc.json", response_token: "sha256=#{response_token}")
  end

  def index(conn, params) do
    IO.inspect(Map.get(params, "tweet_create_events"))
    Task.start(fn ->
      Properties.Twitter.handle_events(params)
    end)

    send_resp(conn, 200, "hi")
    |> halt()
  end
end
