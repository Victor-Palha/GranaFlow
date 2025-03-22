defmodule GranaFlowWeb.WalletController do
  use GranaFlowWeb, :controller
  alias GranaFlow.Services.Wallet, as: WalletService

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"name" => wallet_name, "type" => wallet_type}) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)

    if WalletService.user_can_create_wallet?(user_id) do
      {:ok, wallet_created} = WalletService.create(%{name: wallet_name, type: wallet_type, user_id: user_id})
      wallet_mapped = Map.from_struct(wallet_created) |> Map.delete(:__meta__)

      conn
      |> put_status(:ok)
      |> json(%{wallet: wallet_mapped})
    else
      conn
      |> put_status(:forbidden)
      |> json(%{message: "You already has a wallet! Please upgrade your account to create more."})
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"wallet_id" => wallet_id}) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)

    case WalletService.find_and_delete(wallet_id, user_id) do
      {:ok, wallet} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Wallet #{wallet.name} was deleted"})
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "Wallet not found on your account"})
      {:error, changeset} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{message: "Fail to delete waller", errors: changeset.errors})
    end
  end

  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, _params) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)

    case WalletService.find_wallets_from_user(user_id) do
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "You don't have any wallets yet, please create a new one."})

      {:ok, wallets} ->
        wallets_mapped = Enum.map(wallets, fn w -> Map.from_struct(w) |> Map.delete(:__meta__) end)

        conn
        |> put_status(:ok)
        |> json(%{wallets: wallets_mapped})
    end
  end
end
