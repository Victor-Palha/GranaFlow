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

    prepared_attrs =
      Enum.map(attrs_list, fn attrs ->
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

    case Repo.get_by(Transaction, id: transaction_id) do
      nil -> {:error, :not_found}
      transaction -> {:ok, transaction}
    end
  end

  @spec all(String.t(), String.t(), number() | nil, boolean(), boolean(), String.t()) ::
          {:error, :not_found} | {:ok, list(Ecto.Schema.t())}
  def all(user_id, wallet_id, limit, true, false, type_transaction) do
    with {:ok, wallet} <- get_wallet(user_id, wallet_id) do
      today = Date.utc_today()

      base_query =
        from(t in Transaction,
          where: t.wallet_id == ^wallet.id and t.transaction_date <= ^today,
          order_by: [desc: t.transaction_date],
          limit: ^limit_if_needed(limit)
        )

      query =
        if is_nil(type_transaction) do
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

      base_query =
        from(t in Transaction,
          where: t.wallet_id == ^wallet.id and t.transaction_date > ^today,
          order_by: [desc: t.transaction_date],
          limit: ^limit_if_needed(limit)
        )

      query =
        if is_nil(type_transaction) do
          base_query
        else
          from(t in base_query, where: t.type == ^type_transaction)
        end

      {:ok, Repo.all(query)}
    end
  end

  def all(user_id, wallet_id, limit, false, false, type_transaction) do
    with {:ok, wallet} <- get_wallet(user_id, wallet_id) do
      base_query =
        from(t in Transaction,
          where: t.wallet_id == ^wallet.id,
          order_by: [desc: t.transaction_date],
          limit: ^limit_if_needed(limit)
        )

      query =
        if is_nil(type_transaction) do
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

  @spec current_balance(String.t(), String.t()) :: {:ok, number()}
  def current_balance(user_id, wallet_id) do
    case get_wallet(user_id, wallet_id) do
      {:error, :not_found} ->
        {:ok, 0.0}

      {:ok, wallet} ->
        today = Date.utc_today()

        incomes_query =
          from(
            t in Transaction,
            where:
              t.wallet_id == ^wallet.id and t.transaction_date <= ^today and t.type == "INCOME",
            select: coalesce(sum(t.amount), 0)
          )

        outcomes_query =
          from(
            t in Transaction,
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

      transactions = fetch_annual_transactions(wallet.id, start_date, end_date)
      grouped = group_transactions_by_month(transactions)
      full_report = build_full_annual_report(grouped)

      {:ok, full_report}
    end
  end

  @spec fetch_annual_transactions(binary(), Date.t(), Date.t()) ::
          list({String.t(), Date.t(), Decimal.t()})
  defp fetch_annual_transactions(wallet_id, start_date, end_date) do
    from(
      t in Transaction,
      where:
        t.wallet_id == ^wallet_id and t.transaction_date >= ^start_date and
          t.transaction_date <= ^end_date,
      select: {t.type, t.transaction_date, t.amount}
    )
    |> Repo.all()
  end

  @spec group_transactions_by_month(list({String.t(), Date.t(), Decimal.t()})) ::
          %{optional(non_neg_integer()) => %{income: Decimal.t(), outcome: Decimal.t()}}
  defp group_transactions_by_month(transactions) do
    Enum.reduce(transactions, %{}, fn {type, date, amount}, acc ->
      month = date.month
      current = Map.get(acc, month, %{income: Decimal.new(0), outcome: Decimal.new(0)})

      updated =
        case type do
          "INCOME" -> %{current | income: Decimal.add(current.income, amount)}
          "OUTCOME" -> %{current | outcome: Decimal.add(current.outcome, amount)}
          _ -> current
        end

      Map.put(acc, month, updated)
    end)
  end

  @spec build_full_annual_report(%{
          optional(non_neg_integer()) => %{income: Decimal.t(), outcome: Decimal.t()}
        }) :: list(map())
  defp build_full_annual_report(grouped_data) do
    1..12
    |> Enum.reduce({[], Decimal.new(0)}, fn month, {acc, previous_balance} ->
      month_data =
        Map.get(grouped_data, month, %{income: Decimal.new(0), outcome: Decimal.new(0)})

      month_balance = Decimal.sub(month_data.income, month_data.outcome)
      cumulative_balance = Decimal.add(previous_balance, month_balance)

      updated_month = %{
        month: month,
        income: Decimal.to_string(month_data.income),
        outcome: Decimal.to_string(month_data.outcome),
        final_balance: Decimal.to_string(cumulative_balance)
      }

      {[updated_month | acc], cumulative_balance}
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  @spec get_month_report(String.t(), String.t(), integer(), integer()) :: {:ok, map()}
  def get_month_report(user_id, wallet_id, year, month) do
    with {:ok, wallet} <- get_wallet(user_id, wallet_id),
         {:ok, start_date, end_date} <- build_date_range(year, month),
         {transactions_report, all_transactions} <-
           fetch_wallet_transactions(wallet.id, start_date, end_date),
         {total_income, total_outcome} <- calculate_totals(transactions_report),
         subtypes_report <-
           build_subtypes_report(transactions_report, total_income, total_outcome) do
      {:ok,
       %{
         total_income: Decimal.to_string(total_income),
         total_outcome: Decimal.to_string(total_outcome),
         final_balance: Decimal.to_string(Decimal.sub(total_income, total_outcome)),
         subtypes: subtypes_report,
         transactions: serialize_transactions(all_transactions)
       }}
    end
  end

  @spec build_date_range(integer(), integer()) :: {:ok, Date.t(), Date.t()}
  defp build_date_range(year, month) do
    with {:ok, start_date} <- Date.new(year, month, 1) do
      end_date = Date.end_of_month(start_date)
      {:ok, start_date, end_date}
    end
  end

  @spec fetch_wallet_transactions(binary(), Date.t(), Date.t()) ::
          {list({String.t(), String.t(), Decimal.t()}), list(Transaction.t())}
  defp fetch_wallet_transactions(wallet_id, start_date, end_date) do
    query =
      from(t in Transaction,
        where:
          t.wallet_id == ^wallet_id and
            t.transaction_date >= ^start_date and
            t.transaction_date <= ^end_date
      )

    all_transactions = Repo.all(query)

    report_data =
      Enum.map(all_transactions, fn %Transaction{type: type, subtype: subtype, amount: amount} ->
        {type, subtype, amount}
      end)

    {report_data, all_transactions}
  end

  @spec calculate_totals(list({String.t(), String.t(), Decimal.t()})) ::
          {Decimal.t(), Decimal.t()}
  defp calculate_totals(transactions) do
    {incomes, outcomes} = Enum.split_with(transactions, fn {type, _, _} -> type == "INCOME" end)

    total_income =
      Enum.reduce(incomes, Decimal.new(0), fn {_, _, amount}, acc -> Decimal.add(acc, amount) end)

    total_outcome =
      Enum.reduce(outcomes, Decimal.new(0), fn {_, _, amount}, acc -> Decimal.add(acc, amount) end)

    {total_income, total_outcome}
  end

  @spec build_subtypes_report(
          list({String.t(), String.t(), Decimal.t()}),
          Decimal.t(),
          Decimal.t()
        ) :: list(map())
  defp build_subtypes_report(transactions, total_income, total_outcome) do
    transactions
    |> Enum.group_by(fn {type, subtype, _} -> {type, subtype} end)
    |> Enum.map(fn {{type, subtype}, list} ->
      total =
        Enum.reduce(list, Decimal.new(0), fn {_, _, amount}, acc -> Decimal.add(acc, amount) end)

      percentage =
        case type do
          "INCOME" ->
            if Decimal.compare(total_income, 0) == :eq,
              do: Decimal.new(0),
              else: Decimal.div(total, total_income) |> Decimal.mult(100)

          "OUTCOME" ->
            if Decimal.compare(total_outcome, 0) == :eq,
              do: Decimal.new(0),
              else: Decimal.div(total, total_outcome) |> Decimal.mult(100)

          _ ->
            Decimal.new(0)
        end

      %{
        type: type,
        subtype: subtype,
        total: Decimal.to_string(total),
        percentage: Decimal.to_string(Decimal.round(percentage, 2))
      }
    end)
  end

  @spec serialize_transactions(list(Transaction.t())) :: list(map())
  defp serialize_transactions(transactions) do
    Enum.map(transactions, fn t -> Map.from_struct(t) |> Map.delete(:__meta__) end)
  end
end
