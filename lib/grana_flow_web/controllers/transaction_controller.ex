defmodule GranaFlowWeb.TransactionController do
  use GranaFlowWeb, :controller
  alias GranaFlow.Services.Transaction, as: TransactionService
  alias GranaFlow.Services.Wallet, as: WalletService

  def create(conn, %{
    "name" => name,
    "type" => type,
    "amount" => amount,
    "transaction_date" => transaction_date,
    "subtype" => subtype,
    "proof_url" => proof_url,
    "wallet_id" => wallet_id,
    "description" => description
  }) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)

    case WalletService.find_by_id(wallet_id, user_id) do
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "Wallet not found..."})
      {:ok, _wallet} ->
        {:ok, dt, _} = DateTime.from_iso8601(transaction_date)
        {:ok, transaction} = TransactionService.create(%{
          name: name,
          type: String.upcase(type),
          amount: amount,
          transaction_date: dt,
          subtype: String.upcase(subtype),
          proof_url: proof_url,
          wallet_id: wallet_id,
          description: description
        })

        transaction_mapped = Map.from_struct(transaction) |> Map.delete(:__meta__)

        conn
        |> put_status(:created)
        |> json(%{message: "Transaction created with sucess", transaction: transaction_mapped})
    end
  end

  def create_recurrent(conn, %{
    "name" => name,
    "type" => type,
    "amount" => amount,
    "start_date" => start_date,
    "end_date" => end_date,
    "subtype" => subtype,
    "proof_url" => proof_url,
    "wallet_id" => wallet_id,
    "description" => description
  }) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)

    case WalletService.find_by_id(wallet_id, user_id) do
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "Wallet not found"})

      {:ok, _wallet} ->
        with {:ok, start_dt, _} <- DateTime.from_iso8601(start_date), {:ok, end_dt, _} <- DateTime.from_iso8601(end_date) do
          days = generate_monthly_dates(start_dt, end_dt)
          transactions = Enum.map(days, fn date ->
              %{
                name: name,
                type: String.upcase(type),
                amount: amount,
                transaction_date: date,
                subtype: String.upcase(subtype),
                proof_url: proof_url,
                wallet_id: wallet_id,
                description: description
              }
          end)

          {:ok, _inserted} = TransactionService.create_many(transactions)

          conn
          |> put_status(:created)
          |> json(%{
            message: "Recurring transactions created"
          })
        else
          _ -> conn |> put_status(:bad_request) |> json(%{message: "Invalid date format"})
        end
    end
  end

  def get(conn, %{"transaction_id" => id}) do
    case TransactionService.get_by_id(id) do
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "Transaction not found!"})
      {:ok, transaction} ->
        transaction_mapped = Map.from_struct(transaction) |> Map.delete(:__meta__)

        conn
        |> put_status(:ok)
        |> json(%{transaction: transaction_mapped})
    end
  end

  def all(conn, %{"wallet_id" => wallet_id} = params) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)
    limit = Map.get(params, "limit") |> maybe_parse_int()
    is_until_today = Map.get(params, "is_until_today") |> maybe_parse_boolean()
    is_after_today = Map.get(params, "is_after_today") |> maybe_parse_boolean()
    type_transaction = Map.get(params, "type_transaction") |> maybe_parse_type()
    case TransactionService.all(user_id, wallet_id, limit, is_until_today, is_after_today, type_transaction) do
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "Transactions not found!"})
      {:ok, transactions} ->
        transactions_mapped = Enum.map(transactions, fn t -> Map.from_struct(t) |> Map.delete(:__meta__) end)
        conn
        |> put_status(:ok)
        |> json(%{transactions: transactions_mapped})
    end
  end

  def balance(conn, %{"wallet_id" => wallet_id}) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)
    {:ok, balance} = TransactionService.current_balance(user_id, wallet_id)
    conn
    |> put_status(:ok)
    |> json(%{current_balance: balance})
  end

  def annual_report(conn, %{"wallet_id" => wallet_id, "year" => year_str}) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)

    year = String.to_integer(year_str)

    case TransactionService.get_annual_report(user_id, wallet_id, year) do
      {:ok, report} -> json(conn, %{report: report})
    end
  end

  def month_report(conn, %{"wallet_id" => wallet_id, "year" => year_str, "month" => month_str}) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)

    year = String.to_integer(year_str)
    month = String.to_integer(month_str)

    case TransactionService.get_month_report(user_id, wallet_id, year, month) do
      {:ok, t} -> json(conn, %{report: t})
    end
  end

  defp maybe_parse_int(nil), do: nil
  defp maybe_parse_int(""), do: nil
  defp maybe_parse_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp maybe_parse_boolean(value) when (is_nil(value)), do: false
  defp maybe_parse_boolean(""), do: false
  defp maybe_parse_boolean("false"), do: false
  defp maybe_parse_boolean("true"), do: true
  defp maybe_parse_boolean(_), do: true

  defp maybe_parse_type(value) when (is_nil(value)), do: nil
  defp maybe_parse_type("INCOME"), do: "INCOME"
  defp maybe_parse_type("OUTCOME"), do: "OUTCOME"
  defp maybe_parse_type(_), do: nil

  defp generate_monthly_dates(start_dt, end_dt) do
    start_date = DateTime.to_date(start_dt)
    end_date = DateTime.to_date(end_dt)
    day = start_date.day

    Stream.unfold({start_date.year, start_date.month}, fn
      {year, month} ->
        case Date.new(year, month, day) do
          {:ok, date} when date <= end_date ->
            next = next_month(year, month)
            {
              DateTime.new!(date, ~T[00:00:00], "Etc/UTC"),
              next
            }

          {:error, _} ->
            {:ok, last_day} = Date.new(year, month, 1)
            date = Date.end_of_month(last_day)

            if date <= end_date do
              next = next_month(year, month)
              {
                DateTime.new!(date, ~T[00:00:00], "Etc/UTC"),
                next
              }
            else
              nil
            end

          _ ->
            nil
        end
    end)
    |> Enum.to_list()
    |> Enum.map(fn datetime -> DateTime.to_date(datetime) end)
  end

  defp next_month(year, 12), do: {year + 1, 1}
  defp next_month(year, month), do: {year, month + 1}
end
