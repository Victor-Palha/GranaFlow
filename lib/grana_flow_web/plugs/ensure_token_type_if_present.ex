defmodule GranaFlowWeb.Plugs.EnsureTokenTypeIfPresent do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, expected_type) do
    claims = Guardian.Plug.current_claims(conn)

    case claims do
      nil -> conn
      %{"typ" => ^expected_type} -> conn
      %{"typ" => other} ->
        body = Jason.encode!(%{message: "Expected token type: #{expected_type}, got: #{other}"})

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, body)
      _ ->
        body = Jason.encode!(%{message: "Invalid token claims"})
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, body)
    end
  end
end
