defmodule PropertiesWeb.Plugs.Brotli do
  @behaviour Plug
  import Plug.Conn

  def init(opts) do
    %{
      content_types: Keyword.get(opts, :content_types, %{}),
    }
  end

  def call(conn, %{content_types: types}) do
    with true <- accept_brotli?(conn),
         true <- content_type_matches?(conn, types)
    do
      Plug.Conn.register_before_send(conn, fn(conn) ->
        new_body = :brotli.encode(conn.resp_body)
        conn = update_in(conn.resp_headers, &[{"vary", "Accept-Encoding"} | &1])
               |> put_resp_header("content-encoding", "br")

        %{conn | resp_body: new_body}
      end)
    else
      _ -> conn
    end
  end

  defp accept_brotli?(conn) do
    encoding? = &String.contains?(&1, ["br", "*"])

    Enum.any?(get_req_header(conn, "accept-encoding"), fn accept ->
      accept |> Plug.Conn.Utils.list() |> Enum.any?(encoding?)
    end)
  end

  defp content_type_matches?(_conn, _content_types) do
    true
    # encoding? = &String.contains?(&1, ["br", "*"])

    # Enum.any?(get_req_header(conn, "accept-encoding"), fn accept ->
    #   accept |> Plug.Conn.Utils.list() |> Enum.any?(encoding?)
    # end)
  end
end
