defmodule PhoenixTest.DomOracle.ContractsParityTest do
  use ExUnit.Case,
    async: false,
    parameterize: PhoenixTest.DomOracle.ParityCore.parity_cases()

  import Phoenix.ConnTest

  alias PhoenixTest.DomOracle.ParityCore
  alias PhoenixTest.DomOracle.PhoenixAdapter
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
    oracle = ParityCore.oracle_outcome(contract)
    ours = PhoenixAdapter.ours_outcome(conn, contract)
    diff = OracleDiff.diff(oracle, ours)

    ParityCore.assert_expected_state(contract, diff, oracle)
  end
end
