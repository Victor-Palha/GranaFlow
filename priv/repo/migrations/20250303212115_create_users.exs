defmodule GranaFlow.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :name, :string
      add :avatar_url, :string
      add :provider, :string
      add :provider_uid, :string

      timestamps(type: :utc_datetime)
    end
  end
end
