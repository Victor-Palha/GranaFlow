defmodule GranaFlow.Wallets.Wallet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "wallets" do
    field :name, :string
    field :type, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(wallet, attrs) do
    wallet
    |> cast(attrs, [:name, :type, :user_id])
    |> validate_required([:name, :type, :user_id])
    |> foreign_key_constraint(:user_id, name: :wallets_user_id_fkey, message: "User does not exist")
  end
end
