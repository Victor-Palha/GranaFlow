defmodule GranaFlowWeb.TransactionController do
  use GranaFlowWeb, :controller
  alias GranaFlow.Services.Transaction, as: TransactionService
  alias GranaFlow.Services.Wallet, as: WalletService

  def create(conn, %{"name" => name, "type" => type, "amount" => amount, "transaction_date" => transaction_date, "subtype" => subtype, "proof_url" => proof_url, "wallet_id" => wallet_id}) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)

    case WalletService.find_by_id(wallet_id, user_id) do
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "Wallet not found..."})
      {:ok, _wallet} ->
        {:ok, transaction} = TransactionService.create(%{
          name: name,
          type: String.upcase(type),
          amount: Decimal.new(amount),
          transaction_date: Date.from_iso8601!(transaction_date),
          subtype: String.upcase(subtype),
          proof_url: proof_url,
          wallet_id: wallet_id
        })

        transaction_mapped = Map.from_struct(transaction) |> Map.delete(:__meta__)

        conn
        |> put_status(:created)
        |> json(%{message: "Transaction created with sucess", transaction: transaction_mapped})
    end
  end
end
