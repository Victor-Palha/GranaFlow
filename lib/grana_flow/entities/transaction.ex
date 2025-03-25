defmodule GranaFlow.Entities.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
    name: String.t(),
    type: String.t(),
    amount: number(),
    transaction_date: Date.t(),
    subtype: String.t(),
    proof_url: String.t(),
    description: String.t(),
    wallet_id: number()
  }

  schema "transactions" do
    field :name, :string
    field :type, :string
    field :amount, :decimal
    field :transaction_date, :date
    field :subtype, :string
    field :proof_url, :string
    field :description, :string
    field :wallet_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:name, :amount, :transaction_date, :type, :subtype, :proof_url, :wallet_id, :description])
    |> validate_required([:name, :amount, :transaction_date, :type, :subtype, :wallet_id, :description])
    |> foreign_key_constraint(:wallet_id, name: :transactions_wallet_id_fkey, message: "Wallet does not exist")
  end
end
