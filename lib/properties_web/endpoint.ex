defmodule PropertiesWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :properties

  @session_options [
    store: :cookie,
    key: "_properties_key",
    signing_salt: "qgYk+r/a"
  ]

  socket "/socket", PropertiesWeb.UserSocket, websocket: [compress: true]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [compress: true, connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :properties,
    gzip: true,
    only: ~w(assets css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger
  plug Corsica, origins: "*"

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session, @session_options

  plug PropertiesWeb.Router
end
