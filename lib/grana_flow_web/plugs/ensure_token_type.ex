defmodule GranaFlowWeb.Plugs.EnsureTokenType do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, expected_type) do
    claims = Guardian.Plug.current_claims(conn)

    case claims do
      %{"typ" => ^expected_type} ->
        conn

      _ ->
        body = Jason.encode!(%{message: "Tipo de token inválido para esse recurso!"})
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, body)
    end
  end
end
