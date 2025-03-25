defmodule GranaFlow.Transactions.CustomSubtype do
  use Ecto.Schema
  import Ecto.Changeset

  schema "custom_subtypes" do
    field :name, :string
    belongs_to :user, GranaFlow.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(custom_subtype, attrs) do
    custom_subtype
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> validate_length(:name, min: 2, max: 50)
    |> unique_constraint([:user_id, :name], name: :unique_subtype_per_user)
  end
end
