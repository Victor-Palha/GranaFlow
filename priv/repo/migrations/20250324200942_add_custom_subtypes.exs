defmodule GranaFlow.Repo.Migrations.AddCustomSubtypes do
  use Ecto.Migration

  def change do
    create table(:custom_subtypes) do
      add :name, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:custom_subtypes, [:user_id])
    create unique_index(:custom_subtypes, [:user_id, :name], name: :unique_subtype_per_user)
  end
end
