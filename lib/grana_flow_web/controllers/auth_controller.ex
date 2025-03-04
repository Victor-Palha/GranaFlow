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
        |> put_status(:ok)
        |> json(%{token: token, user: %{id: user.id, email: user.email, name: user.name, avatar_url: user.avatar_url}})

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

  def test(conn, _params) do
    t = Guardian.Plug.current_resource(conn)
    json(conn, %{t: t})
  end
end
