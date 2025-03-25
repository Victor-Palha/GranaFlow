defmodule GranaFlow.Entities.Wallet do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
    id: integer() | nil,
    name: String.t(),
    type: String.t(),
    user_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

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
