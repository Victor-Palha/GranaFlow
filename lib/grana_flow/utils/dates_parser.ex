defmodule GranaFlow.Utils.DatesParser do
  @spec generate_monthly_dates(DateTime.t(), DateTime.t()) :: list(Date.t())
  def generate_monthly_dates(start_dt, end_dt) do
    start_date = DateTime.to_date(start_dt)
    end_date = DateTime.to_date(end_dt)

    get_all_months_between_dates(start_date, end_date)
  end

  @spec get_all_months_between_dates(Date.t(), Date.t()) :: list(Date.t())
  defp get_all_months_between_dates(start_date, end_date) do
    do_get_months(start_date, end_date, start_date.day, [])
  end

  @spec do_get_months(Date.t(), Date.t(), number(), list()) :: list(Date.t())
  defp do_get_months(current_date, end_date, start_day, acc) do
    if Date.compare(current_date, end_date) == :eq do
      Enum.reverse([current_date | acc])
    else
      year = current_date.year
      month = current_date.month

      date =
        case Date.new(year, month, start_day) do
          {:ok, d} -> d
          {:error, _} ->
            {:ok, first_of_month} = Date.new(year, month, 1)
            Date.end_of_month(first_of_month)
        end

      next_month_date =
        if month == 12 do
          {:ok, d} = Date.new(year + 1, 1, start_day)
          d
        else
          case Date.new(year, month + 1, start_day) do
            {:ok, d} -> d
            {:error, _} ->
              {:ok, first_of_month} = Date.new(year, month + 1, 1)
              Date.end_of_month(first_of_month)
          end
        end
        IO.inspect(next_month_date)
      do_get_months(next_month_date, end_date, start_day, [date | acc])
    end
  end

  @spec build_date_range(integer(), integer()) :: {:ok, Date.t(), Date.t()}
  def build_date_range(year, month) do
    with {:ok, start_date} <- Date.new(year, month, 1) do
      end_date = Date.end_of_month(start_date)
      {:ok, start_date, end_date}
    end
  end
end
