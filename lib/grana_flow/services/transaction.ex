defmodule GranaFlow.Services.Transaction do
  import Ecto.Query
  alias GranaFlow.{Repo, Transaction.Transaction, Wallets.Wallet}

  @spec create(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  @spec get_by_id(String.t()) :: {:ok, Ecto.Schema.t()} | {:error, :not_found}
  def get_by_id(transaction_id) do
    transaction_id = String.to_integer(transaction_id)
    IO.inspect(transaction_id)
    case Repo.get_by(Transaction, id: transaction_id) do
      nil -> {:error, :not_found}
      transaction -> {:ok, transaction}
    end
  end

  def all(user_id, wallet_id) do
    query = from(w in Wallet, where: w.user_id == ^user_id and w.id == ^wallet_id)

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      wallet ->
        transactions_query = from(t in Transaction, where: t.wallet_id == ^wallet.id)
        transactions = Repo.all(transactions_query)
        {:ok, transactions}
    end
  end
end
