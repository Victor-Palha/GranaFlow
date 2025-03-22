defmodule GranaFlow.Services.User do
  alias GranaFlow.{Repo, Accounts.User}

  @spec create(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @spec get_by_provider(String.t(), String.t()) :: Ecto.Schema.t() | term() | nil
  def get_by_provider(provider, provider_uid) do
    Repo.get_by(User, provider: provider, provider_uid: provider_uid)
  end

  @spec get_by_id(String.t()) :: {:error, :not_found} | {:ok, Ecto.Schema.t()}
  def get_by_id(user_id) do
    case Repo.get(User, user_id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  @spec upgrade_profile(String.t()) :: {:error, :not_found} | {:ok, Ecto.Schema.t()}
  def upgrade_profile(user_id) do
    with {:ok, user} <- get_by_id(user_id) do
      user
      |> User.changeset(%{})
      |> Ecto.Changeset.put_change(:premium, true)
      |> Repo.update()
    else
      _ -> {:error, :not_found}
    end
  end

  @spec is_user_premium(String.t()) :: true | false
  def is_user_premium(user_id) do
    with {:ok, user} <- get_by_id(user_id) do
      user.premium == true
    else
      _ -> false
    end
  end
end
