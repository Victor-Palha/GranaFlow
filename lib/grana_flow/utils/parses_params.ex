defmodule GranaFlow.Utils.ParsesParams do
  def maybe_parse_int(nil), do: nil
  def maybe_parse_int(""), do: nil
  def maybe_parse_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {int, _} -> int
      :error -> nil
    end
  end

  def maybe_parse_boolean(value) when (is_nil(value)), do: false
  def maybe_parse_boolean(""), do: false
  def maybe_parse_boolean("false"), do: false
  def maybe_parse_boolean("true"), do: true
  def maybe_parse_boolean(_), do: true

  def maybe_parse_type(value) when (is_nil(value)), do: nil
  def maybe_parse_type("INCOME"), do: "INCOME"
  def maybe_parse_type("OUTCOME"), do: "OUTCOME"
  def maybe_parse_type(_), do: nil
end
