defmodule GranaFlowWeb.AuthController do
  use GranaFlowWeb, :controller
  plug(Ueberauth, providers: [:google_custom])

  @provider_config {Ueberauth.Strategy.Google, [default_scope: "email profile"]}

  alias GranaFlow.Guardian
  alias GranaFlow.{Services.User}

  def request(conn, %{"provider" => "google", "client" => client}) do
    conn
    |> put_session(:client, client)
    |> Ueberauth.run_request("google", @provider_config)
  end

  def callback(conn, _params) do
    %{assigns: %{ueberauth_auth: auth}} = conn |> Ueberauth.run_callback("google", @provider_config)

    case find_or_create_user(auth) do
      {:ok, user} ->
        {:ok, main_token, _claims_main} = GranaFlow.Guardian.generate_token(user, "main")
        {:ok, refresh_token, _claims_refresh} = GranaFlow.Guardian.generate_token(user, "refresh")

        client_device = get_session(conn, :client) || "web"
        url_to_redirect = case client_device do
          "mobile" -> "exp://10.0.1.40:8081"
          _ -> "http://localhost:5173"
        end
        IO.inspect(url_to_redirect)

        conn
        |> redirect(
          external:
            "#{url_to_redirect}/auth/callback?token=#{main_token}" <>
            "&refresh_token=#{refresh_token}" <>
            "&id=#{user.id}" <>
            "&email=#{URI.encode_www_form(user.email)}" <>
            "&name=#{URI.encode_www_form(user.name)}" <>
            "&avatar_url=#{URI.encode_www_form(user.avatar_url)}"
        )
        # conn
        # |> put_status(:ok)
        # |> json(%{token: token, user: %{id: user.id, email: user.email, name: user.name, avatar_url: user.avatar_url}})

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: reason})
    end
  end

  defp find_or_create_user(auth) do
    user_information = %{
      provider: to_string(auth.provider),
      provider_uid: auth.uid,
      email: auth.info.email,
      name: auth.info.name,
      avatar_url: auth.info.image
    }

    case User.get_by_provider(user_information.provider, user_information.provider_uid) do
      nil -> User.create(user_information)
      user -> {:ok, user}
    end
  end

  def validate_token(conn, _params) do
    with %{id: id} <- Guardian.Plug.current_resource(conn), {:ok, user} <- User.get_by_id(id) do
      {:ok, token, _claims} = GranaFlow.Guardian.generate_token(user, "main")
      {:ok, refresh_token, _claims_refresh} = GranaFlow.Guardian.generate_token(user, "refresh")

      conn
      |> put_status(:ok)
      |> json(%{token: token, refresh_token: refresh_token, user_id: user.id})
    else
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{message: "Invalid token"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "User not found"})
    end
  end
end
