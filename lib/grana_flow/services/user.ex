defmodule GranaFlow.Services.User do
  alias GranaFlow.{Entities.User, Repo}

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
    case get_by_id(user_id) do
      {:ok, user} ->
        user
        |> User.changeset(%{})
        |> Ecto.Changeset.put_change(:premium, true)
        |> Repo.update()

      _ -> {:error, :not_found}
    end
  end

  @spec user_premium?(String.t()) :: true | false
  def user_premium?(user_id) do
    case get_by_id(user_id) do
      {:ok, user} -> user.premium == true
    end
  end
end
