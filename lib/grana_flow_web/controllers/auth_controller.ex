defmodule GranaFlowWeb.AuthController do
  use GranaFlowWeb, :controller
  plug Ueberauth

  alias GranaFlow.Guardian
  alias GranaFlow.{Repo, Accounts.User}

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case find_or_create_user(auth) do
      {:ok, user} ->
        IO.inspect(user)
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
    provider = to_string(auth.provider)
    provider_uid = auth.uid
    email = auth.info.email
    name = auth.info.name
    avatar_url = auth.info.image

    case Repo.get_by(User, provider: provider, provider_uid: provider_uid) do
      nil ->
        create_user(%{
          provider: provider,
          provider_uid: provider_uid,
          email: email,
          name: name,
          avatar_url: avatar_url
        })
      user -> {:ok, user}
    end
  end

  defp create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def test(conn, _params) do
    %{id: id} = Guardian.Plug.current_resource(conn)
    json(conn, %{message: id})
  end
end
