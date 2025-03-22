defmodule GranaFlow.Repo.Migrations.AddPremiumToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :premium, :boolean, default: false
    end
  end
end
