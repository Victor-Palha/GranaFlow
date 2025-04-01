defmodule GranaFlow.Services.Transaction do
  import Ecto.Query
  alias GranaFlow.{Entities, Repo, Utils.FilterQueries}
  alias GranaFlow.Utils.{DatesParser, FilterQueries, Reports}

  @spec create_transaction(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create_transaction(attrs) do
    %Entities.Transaction{}
    |> Entities.Transaction.changeset(attrs)
    |> Repo.insert()
  end

  @spec create_many_transactions([map()]) :: {:ok, list(map())}
  def create_many_transactions(attrs_list) when is_list(attrs_list) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    prepared_attrs =
      Enum.map(attrs_list, fn attrs ->
        Map.merge(attrs, %{
          inserted_at: now,
          updated_at: now
        })
      end)

    {_count, inserted} = Repo.insert_all(Entities.Transaction, prepared_attrs, returning: true)
    {:ok, inserted}
  end

  @spec get_by_id(String.t()) :: {:ok, Ecto.Schema.t()} | {:error, :not_found}
  def get_by_id(transaction_id) do
    transaction_id = String.to_integer(transaction_id)

    case Repo.get_by(Entities.Transaction, id: transaction_id) do
      nil -> {:error, :not_found}
      transaction -> {:ok, transaction}
    end
  end

  @spec delete_by_id(String.t()) :: {:ok, :deleted} | {:error, :not_found | :deletion_failed}
  def delete_by_id(transaction_id) do
    with {:ok, transaction} <- get_by_id(transaction_id),
         {:ok, _} <- Repo.delete(transaction) do
      {:ok, :deleted}
    else
      {:error, :not_found} -> {:error, :not_found}
      _ -> {:error, :deletion_failed}
    end
  end

  @spec all(String.t(), String.t(), number() | nil, boolean(), boolean(), String.t() | nil) ::
          {:error, :not_found | :invalid_filter_combination} | {:ok, list(Ecto.Schema.t())}
  def all(user_id, wallet_id, limit, past?, future?, type_transaction) do
    if past? and future? do
      {:error, :invalid_filter_combination}
    else
      with {:ok, wallet} <- get_wallet(user_id, wallet_id) do
        query =
          Entities.Transaction
          |> FilterQueries.filter_by_wallet(wallet.id)
          |> FilterQueries.filter_by_date(past?, future?)
          |> FilterQueries.filter_by_type(type_transaction)
          |> order_by(desc: :transaction_date)
          |> limit(^FilterQueries.limit_quey_if_needed(limit))

        {:ok, Repo.all(query)}
      end
    end
  end

  defp get_wallet(user_id, wallet_id) do
    query = from(w in Entities.Wallet, where: w.user_id == ^user_id and w.id == ^wallet_id)

    case Repo.one(query) do
      nil -> {:error, :not_found}
      wallet -> {:ok, wallet}
    end
  end

  @spec current_balance(String.t(), String.t()) :: {:ok, number()}
  def current_balance(user_id, wallet_id) do
    case get_wallet(user_id, wallet_id) do
      {:error, :not_found} ->
        {:ok, 0.0}

      {:ok, wallet} ->
        today = Date.utc_today()

        incomes_query =
          from(
            t in Entities.Transaction,
            where:
              t.wallet_id == ^wallet.id and t.transaction_date <= ^today and t.type == "INCOME",
            select: coalesce(sum(t.amount), 0)
          )

        outcomes_query =
          from(
            t in Entities.Transaction,
            where:
              t.wallet_id == ^wallet.id and t.transaction_date <= ^today and t.type == "OUTCOME",
            select: coalesce(sum(t.amount), 0)
          )

        income = Repo.one(incomes_query)
        outcome = Repo.one(outcomes_query)
        balance = Decimal.sub(income, outcome)
        {:ok, balance}
    end
  end

  @spec get_annual_report(String.t(), String.t(), number()) :: {:ok, list(map())}
  def get_annual_report(user_id, wallet_id, year) do
    with {:ok, wallet} <- get_wallet(user_id, wallet_id) do
      start_date = Date.new!(year, 1, 1)
      end_date = Date.new!(year, 12, 31)

      full_report =
        Reports.fetch_transactions_for_period(wallet.id, start_date, end_date)
        |> Reports.group_by_month()
        |> Reports.build_annual_report()

      {:ok, full_report}
    end
  end

  @spec get_month_report(String.t(), String.t(), integer(), integer()) :: {:ok, map()}
  def get_month_report(user_id, wallet_id, year, month) do
    with {:ok, wallet} <- get_wallet(user_id, wallet_id),
         {:ok, start_date, end_date} <- DatesParser.build_date_range(year, month),
         {transactions_report, all_transactions} <-
           Reports.fetch_transactions_with_subtypes(wallet.id, start_date, end_date),
         {total_income, total_outcome} <-
           Reports.calculate_income_and_outcome(transactions_report),
         subtypes_report <-
           Reports.build_subtype_report(transactions_report, total_income, total_outcome) do
      {:ok,
       %{
         total_income: Decimal.to_string(total_income),
         total_outcome: Decimal.to_string(total_outcome),
         final_balance: Decimal.to_string(Decimal.sub(total_income, total_outcome)),
         subtypes: subtypes_report,
         transactions:
           Enum.map(all_transactions, fn t -> Map.from_struct(t) |> Map.delete(:__meta__) end)
       }}
    end
  end

  @spec find_and_edit(String.t(), map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()} | {:error, :not_found}
  def find_and_edit(transaction_id, transaction_information) do
    case get_by_id(transaction_id) do
      {:ok, transaction} ->
        transaction
        |> Entities.Transaction.changeset(transaction_information)
        |> Repo.update()

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end
end
