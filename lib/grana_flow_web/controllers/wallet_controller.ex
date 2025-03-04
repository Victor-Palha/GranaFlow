defmodule GranaFlowWeb.WalletController do
  use GranaFlowWeb, :controller
  alias GranaFlow.Services.Wallet, as: WalletService

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"name" => wallet_name, "type" => wallet_type}) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)
    case WalletService.count_wallets(user_id) do
      0 ->
        {:ok, wallet_created} = WalletService.create(%{name: wallet_name, type: wallet_type, user_id: user_id})
        wallet_mapped = Map.from_struct(wallet_created) |> Map.delete(:__meta__)

        conn
        |> put_status(:ok)
        |> json(%{wallet: wallet_mapped})
      _ ->
        conn
        |> put_status(:conflict)
        |> json(%{message: "You already has a wallet! Please upgrade your account to create more."})
    end
  end
end
