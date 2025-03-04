defmodule GranaFlow.Services.Wallet do
  alias GranaFlow.{Repo, Wallets.Wallet}

  @spec create(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(attr) do
    %Wallet{}
    |> Wallet.changeset(attr)
    |> Repo.insert()
  end
end
