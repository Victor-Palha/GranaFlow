defmodule GranaFlow.Entities.User do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
    name: String.t(),
    provider: String.t(),
    email: String.t(),
    avatar_url: String.t(),
    provider_uid: String.t(),
    premium: boolean()
  }

  schema "users" do
    field :name, :string
    field :provider, :string
    field :email, :string
    field :avatar_url, :string
    field :provider_uid, :string
    field :premium, :boolean

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :avatar_url, :provider, :provider_uid, :premium])
    |> validate_required([:email, :name, :avatar_url, :provider, :provider_uid])
    |> unique_constraint([:provider, :provider_uid])
  end
end
