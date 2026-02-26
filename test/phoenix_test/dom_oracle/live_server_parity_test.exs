defmodule PhoenixTest.DomOracle.LiveServerParityTest do
  use ExUnit.Case,
    async: false,
    parameterize: PhoenixTest.LiveServerOracleContracts.contracts()

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

  test "live server contract parity baseline", %{conn: conn} = contract do
    contract = Map.put(contract, :surface, :live)

    oracle = ParityCore.oracle_outcome(contract)
    ours = PhoenixAdapter.ours_outcome(conn, contract)
    diff = OracleDiff.diff(oracle, ours)

    ParityCore.assert_expected_state(contract, diff, oracle)
  end
end
