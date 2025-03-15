defmodule GranaFlowWeb.AuthController do
  use GranaFlowWeb, :controller
  plug Ueberauth

  alias GranaFlow.Guardian
  alias GranaFlow.{Services.User}

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case find_or_create_user(auth) do
      {:ok, user} ->
        {:ok, token, _claim} = Guardian.encode_and_sign(user)

        conn
        |> redirect(
          external:
            "exp://10.0.1.40:8081/auth/callback?token=#{token}" <>
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
    %{id: id} = Guardian.Plug.current_resource(conn)
    case User.get_by_id(id) do
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "User not found"})
      {:ok, user} ->
        {:ok, token, _claim} = Guardian.encode_and_sign(user)

        conn
        |> put_status(:ok)
        |> json(%{token: token, user_id: id})
    end
  end

  def test(conn, _params) do
    %{id: id} = Guardian.Plug.current_resource(conn)
    json(conn, %{message: id})
  end
end
