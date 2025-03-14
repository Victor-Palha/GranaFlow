defmodule GranaFlow.Services.Transaction do
  import Ecto.Query
  alias GranaFlow.{Repo, Transaction.Transaction, Wallets.Wallet}

  @spec create(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  @spec create_many([map()]) :: {:ok, list(map())}
  def create_many(attrs_list) when is_list(attrs_list) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    prepared_attrs = Enum.map(attrs_list, fn attrs ->
      Map.merge(attrs, %{
        inserted_at: now,
        updated_at: now
      })
    end)

    {_count, inserted} = Repo.insert_all(Transaction, prepared_attrs, returning: true)
    {:ok, inserted}
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

  @spec all(String.t(), String.t(), number() | nil, boolean(), boolean(), String.t()) :: {:error, :not_found} | {:ok, list(Ecto.Schema.t())}
  def all(user_id, wallet_id, limit, true, false, type_transaction) do
    with {:ok, wallet} <- get_wallet(user_id, wallet_id) do
      today = Date.utc_today()

      base_query = from(t in Transaction,
        where: t.wallet_id == ^wallet.id and t.transaction_date <= ^today,
        order_by: [desc: t.transaction_date],
        limit: ^limit_if_needed(limit)
      )

      query = if is_nil(type_transaction) do
          base_query
        else
          from(t in base_query, where: t.type == ^type_transaction)
      end

      {:ok, Repo.all(query)}
    end
  end

  def all(user_id, wallet_id, limit, false, true, type_transaction) do
    with {:ok, wallet} <- get_wallet(user_id, wallet_id) do
      today = Date.utc_today()

      base_query = from(t in Transaction,
        where: t.wallet_id == ^wallet.id and t.transaction_date > ^today,
        order_by: [desc: t.transaction_date],
        limit: ^limit_if_needed(limit)
      )

      query = if is_nil(type_transaction) do
          base_query
        else
          from(t in base_query, where: t.type == ^type_transaction)
      end

      {:ok, Repo.all(query)}
    end
  end

  def all(user_id, wallet_id, limit, false, false, type_transaction) do
    with {:ok, wallet} <- get_wallet(user_id, wallet_id) do
      base_query = from(t in Transaction,
          where: t.wallet_id == ^wallet.id,
          order_by: [desc: t.transaction_date],
          limit: ^limit_if_needed(limit)
      )

      query = if is_nil(type_transaction) do
          base_query
        else
          from(t in base_query, where: t.type == ^type_transaction)
      end

      {:ok, Repo.all(query)}
    end
  end

  def all(_, _, _, true, true, _), do: {:error, :invalid_filter_combination}

  defp get_wallet(user_id, wallet_id) do
    query = from(w in Wallet, where: w.user_id == ^user_id and w.id == ^wallet_id)

    case Repo.one(query) do
      nil -> {:error, :not_found}
      wallet -> {:ok, wallet}
    end
  end

  defp limit_if_needed(nil), do: nil
  defp limit_if_needed(limit), do: limit
end
