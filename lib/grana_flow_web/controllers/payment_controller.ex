defmodule GranaFlowWeb.PaymentController do
  alias GranaFlow.Services.{Payment, User}
  use GranaFlowWeb, :controller

  def create(conn, _params) do
    with %{id: user_id} <- Guardian.Plug.current_resource(conn),
         {:ok, user} <- User.get_by_id(user_id),
         {:ok, checkout_url} <- Payment.generate_premium_upgrade_url(user) do
      json(conn, %{url: checkout_url})
    else
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Não autenticado"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Usuário não encontrado"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  def notification(conn, params) do
    case Payment.process(params) do
      {:ok, message} ->
        conn
        |> put_status(:ok)
        |> json(%{message: message})

      {:error, :invalid_format} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Formato de notificação inválido"})
    end
  end
end
