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
end
