defmodule GranaFlow.Services.Transaction do
  alias GranaFlow.{Repo, Transaction.Transaction}

  @spec create(map()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end
end
