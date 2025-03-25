defmodule GranaFlow.Services.Payment do
  require Logger

  @access_token System.get_env("MP_ACCESS_TOKEN")
  @mp_api_url "https://api.mercadopago.com/v1/payments"
  @valid_topics ~w(merchant_order payment payment.created)
  @callback generate_premium_upgrade_url(GranaFlow.Entities.User.t()) :: {:ok, String.t()} | {:error, any()}

  @spec generate_premium_upgrade_url(GranaFlow.Entities.User.t()) :: {:ok, String.t()} | {:error, any()}
  def generate_premium_upgrade_url(user) do
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
          user_id: user.id
        }
      },
      metadata: %{
        user_id: user.id,
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

    case HTTPoison.post("https://api.mercadopago.com/checkout/preferences", Jason.encode!(body), headers) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
        preference = Jason.decode!(body)
        checkout_url = preference["init_point"]
        {:ok, checkout_url}

      {:error, %HTTPoison.Error{} = error} ->
        {:error, error}
    end
  end

  @spec process(map()) :: {:ok, String.t()} | {:error, atom()}
  def process(params) do
    with {:ok, topic, id} <- extract_notification_data(params),
        {:ok, resource_data} <- fetch_resource_data(topic, id),
        {:ok, message} <- handle_notification(topic, resource_data) do
      {:ok, message}
    else
      {:error, reason} ->
        Logger.error("Failed to process notification: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @spec extract_notification_data(map()) :: {:ok, String.t(), String.t()} | {:error, :invalid_format}
  def extract_notification_data(%{"topic" => topic, "id" => id}) when topic in @valid_topics,
    do: {:ok, topic, id}

  def extract_notification_data(%{"action" => "payment.created", "data" => %{"id" => id}}),
    do: {:ok, "payment", id}

  def extract_notification_data(_),
    do: {:error, :invalid_format}

  @spec fetch_resource_data(String.t(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def fetch_resource_data("payment", id) do
    headers = [{"Authorization", "Bearer #{@access_token}"}]
    url = "#{@mp_api_url}/#{id}"

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        error = "Unexpected status #{status}: #{body}"
        Logger.error(error)
        {:error, error}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP error: #{inspect(reason)}")
        {:error, "HTTP error: #{reason}"}
    end
  end

  def fetch_resource_data(topic, _id),
    do: {:error, "Unsupported topic: #{topic}"}

  @spec handle_notification(String.t(), map()) :: {:ok, String.t()} | {:error, String.t()}
  def handle_notification("payment", payment_data) do
    case payment_data["status"] do
      "approved" ->
        user_id = payment_data["metadata"]["user_id"]
        Logger.info("✅ Pagamento aprovado para user_id: #{user_id}")
        GranaFlow.Services.User.upgrade_profile(user_id)
        {:ok, "Pagamento aprovado"}

      "pending" ->
        Logger.info("Payment pending: #{payment_data["id"]}")
        {:ok, "Pagamento pendente"}

      "rejected" ->
        Logger.info("Payment rejected: #{payment_data["id"]}")
        {:ok, "Pagamento rejeitado"}

      other_status ->
        Logger.info("Unhandled payment status: #{other_status}")
        {:ok, "Status não tratado: #{other_status}"}
    end
  end

  def handle_notification(topic, _data),
    do: {:error, "Unsupported notification topic: #{topic}"}
end
