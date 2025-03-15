defmodule GranaFlowWeb.AuthController do
  use GranaFlowWeb, :controller
  plug Ueberauth

  alias GranaFlow.Guardian
  alias GranaFlow.{Services.User}

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case find_or_create_user(auth) do
      {:ok, user} ->
        {:ok, main_token, _claims_main} = GranaFlow.Guardian.generate_token(user, "main")
        {:ok, refresh_token, _claims_refresh} = GranaFlow.Guardian.generate_token(user, "refresh")

        conn
        |> redirect(
          external:
            "exp://10.0.1.40:8081/auth/callback?token=#{main_token}" <>
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

  def test(conn, _params) do
    %{id: id} = Guardian.Plug.current_resource(conn)
    json(conn, %{message: id})
  end
end
