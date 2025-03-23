defmodule GranaFlowWeb.PaymentController do
  alias GranaFlow.Services.User
  use GranaFlowWeb, :controller

  @access_token System.get_env("MP_ACCESS_TOKEN")

  def create(conn, _params) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)

    with {:ok, user} <- User.get_by_id(user_id) do
      body = %{
        items: [
          %{
            title: "Upgrade Premium - GranaFlow",
            description: "Acesso ilimitado a funcionalidades premium do GranaFlow",
            picture_url: "https://static.victor-palha.com/logo.png",
            category_id: "digital_goods",
            quantity: 1,
            currency_id: "BRL",
            unit_price: 20
          }
        ],
        payer: %{
          name: user.name,
          email: user.email,
          identification: %{
            type: "id",
            user_id: user_id
          }
        },
        metadata: %{
          user_id: user_id,
          feature: "premium_upgrade"
        },
        back_urls: %{
          success: "http://localhost:5173/account/success",
          failure: "http://localhost:5173/account/error",
          pending: "http://localhost:5173/account/pending"
        },
        auto_return: "approved",
        notification_url: "https://deac-2804-d4b-9d0b-6c01-d195-6c2e-eac7-6a3a.ngrok-free.app/payment/notification"
      }

      headers = [
        {"Authorization", "Bearer #{@access_token}"},
        {"Content-Type", "application/json"}
      ]

      case HTTPoison.post(
             "https://api.mercadopago.com/checkout/preferences",
             Jason.encode!(body),
             headers
           ) do
        {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
          preference = Jason.decode!(body)
          checkout_url = preference["init_point"]
          json(conn, %{url: checkout_url})

        {:error, %HTTPoison.Error{} = error} ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: error})
      end
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User Not found"})
    end
  end

  def notification(conn, %{"topic" => "merchant_order", "id" => id, "resource" => resource}) do
    IO.inspect("📥 Webhook recebido: merchant_order - ID: #{id} - Resource: #{resource}")

    case fetch_resource_data("merchant_order", id) do
      {:ok, resource_data} ->
        handle_notification("merchant_order", resource_data, conn)

      {:error, reason} ->
        IO.inspect(reason, label: "❌ Falha ao buscar dados do merchant_order")
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Falha ao buscar dados do merchant_order: #{reason}"})
    end
  end

  def notification(conn, %{"topic" => "payment", "id" => id, "resource" => resource}) do
    IO.inspect("📥 Webhook recebido: payment - ID: #{id} - Resource: #{resource}")

    case fetch_resource_data("payment", id) do
      {:ok, resource_data} ->
        handle_notification("payment", resource_data, conn)

      {:error, reason} ->
        IO.inspect(reason, label: "❌ Falha ao buscar dados do payment")
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Falha ao buscar dados do payment: #{reason}"})
    end
  end

  def notification(conn, %{"action" => "payment.created", "data" => %{"id" => id}, "user_id" => user_id}) do
    IO.inspect("📥 Webhook recebido: payment.created - ID: #{id} - User ID: #{user_id}")

    case fetch_resource_data("payment", id) do
      {:ok, resource_data} ->
        handle_notification("payment", resource_data, conn)

      {:error, reason} ->
        IO.inspect(reason, label: "❌ Falha ao buscar dados do payment.created")
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Falha ao buscar dados do payment.created: #{reason}"})
    end
  end

  def notification(conn, params) do
    IO.inspect(params, label: "❌ Notificação com formato inválido")

    conn
    |> put_status(:bad_request)
    |> json(%{error: "Formato de notificação inválido"})
  end

  defp fetch_resource_data("payment", id) do
    token = System.get_env("MP_ACCESS_TOKEN")
    url = "https://api.mercadopago.com/v1/payments/#{id}?access_token=#{token}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
        {:error, "Status inesperado (#{code}): #{body}"}

      {:error, error} ->
        {:error, "Erro HTTP: #{inspect(error)}"}
    end
  end

  defp fetch_resource_data(type, _id), do: {:error, "Tipo não suportado: #{type}"}

  defp handle_notification("payment", payment_data, conn) do
    case payment_data["status"] do
      "approved" ->
        user_id = payment_data["metadata"]["user_id"]
        IO.puts("✅ Pagamento aprovado para user_id: #{user_id}")

        GranaFlow.Services.User.upgrade_profile(user_id)

        conn
        |> put_status(:ok)
        |> json(%{message: "Pagamento aprovado, redirecionando para o sucesso"})

      "pending" ->
        IO.puts("🕒 Pagamento pendente")
        conn
        |> put_status(:ok)
        |> json(%{message: "Pagamento pendente, aguardando confirmação"})

      "rejected" ->
        IO.puts("❌ Pagamento rejeitado")
        conn
        |> put_status(:ok)
        |> json(%{message: "Pagamento rejeitado, por favor tente novamente"})

      other ->
        IO.puts("ℹ️ Status do pagamento: #{other}")
        conn
        |> put_status(:ok)
        |> json(%{message: "Status não tratado, redirecionando"})
    end
  end

  defp handle_notification(type, _data, conn) do
    conn
    |> put_status(:ok)
    |> json(%{message: "Notificação do tipo #{type} ignorada por enquanto"})
  end
end
