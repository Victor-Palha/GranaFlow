defmodule GranaFlow.Services.CustomSubtype do
  import Ecto.Query, warn: false

  alias GranaFlow.Repo
  alias GranaFlow.Transactions.CustomSubtype

  def list_user_custom_subtypes(user_id) do
    query = from(s in CustomSubtype, where: s.user_id == ^user_id)
    Repo.all(query)
  end

  def create_custom_subtype(attrs \\ %{}) do
    %CustomSubtype{}
    |> CustomSubtype.changeset(attrs)
    |> Repo.insert()
  end
end
