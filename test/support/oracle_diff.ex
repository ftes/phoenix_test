defmodule PhoenixTest.OracleDiff do
  @moduledoc false

  alias PhoenixTest.OracleNormalize

  def diff(expected, actual) do
    normalized_expected = OracleNormalize.normalize(expected)
    normalized_actual = OracleNormalize.normalize(actual)

    if normalized_expected == normalized_actual do
      :ok
    else
      {:mismatch, format_mismatch(normalized_expected, normalized_actual)}
    end
  end

  def diff!(expected, actual) do
    case diff(expected, actual) do
      :ok ->
        :ok

      {:mismatch, message} ->
        raise ExUnit.AssertionError, message: message
    end
  end

  defp format_mismatch(expected, actual) do
    expected_dump = inspect(expected, pretty: true, limit: :infinity)
    actual_dump = inspect(actual, pretty: true, limit: :infinity)

    """
    Oracle result mismatch
    expected: #{expected_dump}
    actual: #{actual_dump}
    """
  end
end
