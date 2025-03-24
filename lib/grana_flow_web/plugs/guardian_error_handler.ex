defmodule GranaFlowWeb.GuardianErrorHandler do
  import Plug.Conn

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, reason}, _opts) do
    message = case reason do
      :no_resource_found -> "Parece que você não tem o token de authenticação, faça login para receber um token!"
      :invalid_token -> "Ops, parece que você não está authenticado corretamente! Refaça login para acessar esse recurso."
      _ -> type
    end

    body = Jason.encode!(%{message: to_string(message)})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, body)
  end
end
