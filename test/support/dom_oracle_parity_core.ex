defmodule PhoenixTest.DomOracle.ParityCore do
  @moduledoc false

  alias PhoenixTest.OracleContracts
  alias PhoenixTest.OracleNormalize
  alias PhoenixTest.OracleRunner

  def parity_cases do
    Enum.flat_map([:static, :live], fn surface ->
      Enum.map(OracleContracts.for_surface(surface), &Map.put(&1, :surface, surface))
    end)
  end

  def assert_expected_state(contract, diff, oracle) do
    label = contract_label(contract)

    case {contract.expected, diff} do
      {:ignore, _} ->
        :ok

      {:mismatch, {:mismatch, _message}} ->
        :ok

      {:mismatch, :ok} ->
        raise ExUnit.AssertionError, """
        #{label} currently matches oracle output.
        Update expected to :match and continue refactor.
        payload=#{inspect(oracle, pretty: true, limit: :infinity)}
        """

      {:match, :ok} ->
        :ok

      {:match, {:mismatch, message}} ->
        raise ExUnit.AssertionError, """
        #{label} expected to match oracle but diverged:
        #{message}
        """
    end
  end

  def oracle_outcome(contract) do
    spec = %{
      "base_url" => OracleRunner.base_url(),
      "initial_path" => contract.path,
      "steps" => contract.steps,
      "capture" => contract.capture,
      "timeout_ms" => Map.get(contract, :timeout_ms, oracle_timeout_ms())
    }

    case OracleRunner.run(spec) do
      {:ok, %{"capture" => capture}} ->
        %{
          "status" => "ok",
          "payload" => normalize_capture(contract.capture, capture)
        }

      {:error, {:runner_failed, _status, payload}} ->
        %{
          "status" => "error",
          "payload" =>
            payload
            |> Map.take(["failed_step_index", "failed_op", "playwright_error"])
            |> Map.put("message", "playwright_step_failed")
        }

      {:error, reason} ->
        raise "Oracle runner error for #{contract_label(contract)}: #{inspect(reason)}"
    end
  end

  def normalize_entries(entries) do
    entries
    |> OracleNormalize.normalize_entries()
    |> Enum.map(fn {name, value} -> [name, normalize_value(value)] end)
    |> Enum.sort()
  end

  def normalize_value(value) when is_binary(value), do: value
  def normalize_value(value) when is_boolean(value), do: to_string(value)
  def normalize_value(value) when is_atom(value), do: Atom.to_string(value)
  def normalize_value(value), do: to_string(value)

  defp contract_label(contract) do
    "#{contract.surface} #{contract.id} #{contract.name}"
  end

  defp normalize_capture(%{"type" => "form_snapshot"}, capture) do
    %{"entries" => normalize_entries(capture["entries"])}
  end

  defp normalize_capture(%{"type" => "submit_result"}, capture) do
    %{
      "submitted" => capture["submitted"] == true,
      "effective_method" => capture["effective_method"],
      "effective_action" => capture["effective_action"],
      "entries" => normalize_entries(capture["entries"] || [])
    }
  end

  defp normalize_capture(%{"type" => "selector_text", "selector" => selector}, capture) do
    %{
      "selector" => selector,
      "text" => normalize_value(capture["text"] || "")
    }
  end

  defp normalize_capture(%{"type" => "current_path"}, capture) do
    %{"current_path" => capture["current_path"]}
  end

  defp oracle_timeout_ms do
    case Integer.parse(System.get_env("PHOENIX_TEST_ORACLE_TIMEOUT_MS", "7000")) do
      {ms, ""} when ms > 0 -> ms
      _ -> 7_000
    end
  end
end
