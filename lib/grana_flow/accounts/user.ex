defmodule GranaFlow.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :provider, :string
    field :email, :string
    field :avatar_url, :string
    field :provider_uid, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :avatar_url, :provider, :provider_uid])
    |> validate_required([:email, :name, :avatar_url, :provider, :provider_uid])
  end
end
