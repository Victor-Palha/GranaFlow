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

  @spec find_and_delete(number(), String.t()) :: {:ok, Ecto.Schema.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def find_and_delete(wallet_id, user_id) do
    user_id = String.to_integer(user_id)

    query = from(w in Wallet, where: w.user_id == ^user_id and w.id == ^wallet_id)

    case Repo.one(query) do
      nil -> {:error, :not_found}
      wallet ->
        case Repo.delete(wallet) do
          {:ok, deleted_wallet} -> {:ok, deleted_wallet}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  @spec find_wallets_from_user(String.t()) :: {:ok, list(Wallet.t())} | {:error, :not_found}
  def find_wallets_from_user(user_id) do
    user_id = String.to_integer(user_id)

    query = from(w in Wallet, where: w.user_id == ^user_id)
    wallets = Repo.all(query)

    if Enum.empty?(wallets) do
      {:error, :not_found}
    else
      {:ok, wallets}
    end
  end

  @spec find_by_id(number(), String.t()) :: {:ok, Wallet.t()} | {:error, :not_found}
  def find_by_id(wallet_id, user_id) do
    user_id = String.to_integer(user_id)
    query = from(w in Wallet, where: w.user_id == ^user_id and w.id == ^wallet_id)

    case Repo.one(query) do
      nil -> {:error, :not_found}
      wallet -> {:ok, wallet}
    end
  end
end
