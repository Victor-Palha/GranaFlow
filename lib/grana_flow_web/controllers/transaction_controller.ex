defmodule GranaFlowWeb.TransactionController do
  use GranaFlowWeb, :controller
  alias GranaFlow.Services.Transaction, as: TransactionService
  alias GranaFlow.Services.Wallet, as: WalletService

  def create(conn, %{"name" => name, "type" => type, "amount" => amount, "transaction_date" => transaction_date, "subtype" => subtype, "proof_url" => proof_url, "wallet_id" => wallet_id, "description" => description}) do
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

  def all(conn, %{"wallet_id" => wallet_id}) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)
    case TransactionService.all(user_id, wallet_id) do
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
end
