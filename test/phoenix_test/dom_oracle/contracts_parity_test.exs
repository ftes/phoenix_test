defmodule PhoenixTest.DomOracle.ContractsParityTest do
  use ExUnit.Case,
    async: false,
    parameterize: PhoenixTest.DomOracle.ParityHelpers.parity_cases()

  import Phoenix.ConnTest

  alias PhoenixTest.DomOracle.ParityHelpers
  alias PhoenixTest.OracleDiff
  alias PhoenixTest.OracleRunner

  setup_all do
    case OracleRunner.availability() do
      :ok -> :ok
      {:error, reason} -> {:skip, "Oracle runner unavailable: #{inspect(reason)}"}
    end
  end

  setup do
    %{conn: build_conn()}
  end

  test "contract parity baseline", %{conn: conn} = contract do
    oracle = ParityHelpers.oracle_outcome(contract)
    ours = ParityHelpers.ours_outcome(conn, contract)
    diff = OracleDiff.diff(oracle, ours)

    ParityHelpers.assert_expected_state(contract, diff, oracle)
  end
end
