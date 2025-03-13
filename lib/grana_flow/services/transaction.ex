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

  @spec all(String.t(), String.t(), number() | nil, boolean()) :: {:error, :not_found} | {:ok, list(Ecto.Schema.t())}
  def all(user_id, wallet_id, limit \\ nil, is_until_today \\ false) do
    query = from(w in Wallet, where: w.user_id == ^user_id and w.id == ^wallet_id)

    case Repo.one(query) do
      nil -> {:error, :not_found}
      wallet ->
        base_query = from(t in Transaction, where: t.wallet_id == ^wallet.id)

        # Adiciona a ordenação das transações pela data, do mais recente para o mais antigo
        ordered_query = from(t in base_query, order_by: [desc: t.transaction_date])

        # Adiciona o filtro para transações até a data atual, se is_until_today for true
        final_query =
          if is_until_today do
            today = Date.utc_today()  # Obter a data atual
            from(t in ordered_query, where: t.transaction_date <= ^today)
          else
            ordered_query
          end

        # Se houver um limite, aplica o limite na consulta
        final_query =
          if limit do
            from(t in final_query, limit: ^limit)
          else
            final_query
          end

        {:ok, Repo.all(final_query)}
    end
  end

end
