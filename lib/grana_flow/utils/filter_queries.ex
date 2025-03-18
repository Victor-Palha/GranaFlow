defmodule GranaFlow.Utils.FilterQueries do
  import Ecto.Query

  def filter_by_wallet(queryable, wallet_id) do
    from(t in queryable, where: t.wallet_id == ^wallet_id)
  end

  def filter_by_date(queryable, true, false) do
    today = Date.utc_today()
    from(t in queryable, where: t.transaction_date <= ^today)
  end

  def filter_by_date(queryable, false, true) do
    today = Date.utc_today()
    from(t in queryable, where: t.transaction_date > ^today)
  end

  def filter_by_date(queryable, false, false), do: queryable

  def filter_by_type(queryable, nil), do: queryable
  def filter_by_type(queryable, type) do
    from(t in queryable, where: t.type == ^type)
  end

  def limit_quey_if_needed(nil), do: nil
  def limit_quey_if_needed(limit), do: limit
end
