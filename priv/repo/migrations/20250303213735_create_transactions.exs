defmodule GranaFlow.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :name, :string
      add :amount, :decimal
      add :transaction_date, :date
      add :type, :string
      add :subtype, :string
      add :proof_url, :string
      add :wallet_id, references(:wallets, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:transactions, [:wallet_id])
  end
end
