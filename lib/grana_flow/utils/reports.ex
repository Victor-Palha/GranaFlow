defmodule GranaFlow.Utils.Reports do
  import Ecto.Query
  alias GranaFlow.Entities.Transaction
  alias GranaFlow.Repo

  @spec fetch_transactions_for_period(binary(), Date.t(), Date.t()) ::
          list({String.t(), Date.t(), Decimal.t()})
  def fetch_transactions_for_period(wallet_id, start_date, end_date) do
    from(
      transaction in Transaction,
      where:
        transaction.wallet_id == ^wallet_id and
          transaction.transaction_date >= ^start_date and
          transaction.transaction_date <= ^end_date,
      select: {transaction.type, transaction.transaction_date, transaction.amount}
    )
    |> Repo.all()
  end

  @spec group_by_month(list({String.t(), Date.t(), Decimal.t()})) ::
          %{optional(non_neg_integer()) => %{income: Decimal.t(), outcome: Decimal.t()}}
  def group_by_month(transactions) do
    Enum.reduce(transactions, %{}, fn {type, date, amount}, grouped ->
      month_number = date.month

      current_month_data =
        Map.get(grouped, month_number, %{income: Decimal.new(0), outcome: Decimal.new(0)})

      updated_month_data =
        case type do
          "INCOME" -> %{current_month_data | income: Decimal.add(current_month_data.income, amount)}
          "OUTCOME" -> %{current_month_data | outcome: Decimal.add(current_month_data.outcome, amount)}
          _ -> current_month_data
        end

      Map.put(grouped, month_number, updated_month_data)
    end)
  end

  @spec build_annual_report(%{
          optional(non_neg_integer()) => %{income: Decimal.t(), outcome: Decimal.t()}
        }) :: list(map())
  def build_annual_report(monthly_data) do
    1..12
    |> Enum.reduce({[], Decimal.new(0)}, fn month, {report_acc, previous_balance} ->
      %{income: income, outcome: outcome} =
        Map.get(monthly_data, month, %{income: Decimal.new(0), outcome: Decimal.new(0)})

      month_balance = Decimal.sub(income, outcome)
      cumulative_balance = Decimal.add(previous_balance, month_balance)

      report_entry = %{
        month: month,
        income: Decimal.to_string(income),
        outcome: Decimal.to_string(outcome),
        final_balance: Decimal.to_string(cumulative_balance)
      }

      {[report_entry | report_acc], cumulative_balance}
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  @spec fetch_transactions_with_subtypes(binary(), Date.t(), Date.t()) ::
          {list({String.t(), String.t(), Decimal.t()}), list(Transaction.t())}
  def fetch_transactions_with_subtypes(wallet_id, start_date, end_date) do
    query =
      from(transaction in Transaction,
        where:
          transaction.wallet_id == ^wallet_id and
            transaction.transaction_date >= ^start_date and
            transaction.transaction_date <= ^end_date
      )

    transactions = Repo.all(query)

    simplified_data =
      Enum.map(transactions, fn %Transaction{type: type, subtype: subtype, amount: amount} ->
        {type, subtype, amount}
      end)

    {simplified_data, transactions}
  end

  @spec calculate_income_and_outcome(list({String.t(), String.t(), Decimal.t()})) ::
          {Decimal.t(), Decimal.t()}
  def calculate_income_and_outcome(transactions) do
    {income_transactions, outcome_transactions} =
      Enum.split_with(transactions, fn {type, _, _} -> type == "INCOME" end)

    total_income =
      Enum.reduce(income_transactions, Decimal.new(0), fn {_, _, amount}, acc ->
        Decimal.add(acc, amount)
      end)

    total_outcome =
      Enum.reduce(outcome_transactions, Decimal.new(0), fn {_, _, amount}, acc ->
        Decimal.add(acc, amount)
      end)

    {total_income, total_outcome}
  end

  @spec build_subtype_report(
          list({String.t(), String.t(), Decimal.t()}),
          Decimal.t(),
          Decimal.t()
        ) :: list(map())
  def build_subtype_report(transactions, total_income, total_outcome) do
    transactions
    |> Enum.group_by(fn {type, subtype, _} -> {type, subtype} end)
    |> Enum.map(fn {{type, subtype}, grouped_transactions} ->
      total =
        Enum.reduce(grouped_transactions, Decimal.new(0), fn {_, _, amount}, acc ->
          Decimal.add(acc, amount)
        end)

      percentage =
        case type do
          "INCOME" ->
            if Decimal.equal?(total_income, 0),
              do: Decimal.new(0),
              else: Decimal.div(total, total_income) |> Decimal.mult(100)

          "OUTCOME" ->
            if Decimal.equal?(total_outcome, 0),
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
end
