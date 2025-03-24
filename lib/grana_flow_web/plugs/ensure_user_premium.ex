defmodule GranaFlowWeb.Plugs.EnsureUserPremium do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, expected_type) do
    claims = Guardian.Plug.current_claims(conn)

    case claims do
      %{"premium" => ^expected_type} ->
        conn

      _ ->
        body = Jason.encode!(%{message: "Ops, você precisa ser uma conta premium para acessar esse recurso!"})
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, body)
    end
  end
end
