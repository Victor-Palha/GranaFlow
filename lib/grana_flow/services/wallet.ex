defmodule GranaFlow.Services.Wallet do
  import Ecto.Query
  alias GranaFlow.{Repo, Wallets.Wallet}

  @spec create(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(attr) do
    %Wallet{}
    |> Wallet.changeset(attr)
    |> Repo.insert()
  end

  @spec count_wallets(String.t()) :: number() | nil
  def count_wallets(user_id) do
    user_id = String.to_integer(user_id)
    query = from(w in Wallet, where: w.user_id == ^user_id)
    Repo.aggregate(query, :count, :id)
  end
end
