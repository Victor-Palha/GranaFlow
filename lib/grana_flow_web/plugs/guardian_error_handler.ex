defmodule GranaFlowWeb.GuardianErrorHandler do
  import Plug.Conn

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, reason}, _opts) do
    message = case reason do
      :no_resource_found -> "Please, provide the auth token to access this resource"
      :invalid_token -> "Invalid token, please log-in again"
      _ -> type
    end

    body = Jason.encode!(%{message: to_string(message)})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, body)
  end
end
