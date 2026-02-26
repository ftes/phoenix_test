defmodule PhoenixTest.DomOracle.OracleRunnerTest do
  use ExUnit.Case, async: false

  alias PhoenixTest.OracleRunner

  setup do
    case OracleRunner.availability() do
      :ok -> :ok
      {:error, reason} -> {:skip, "Oracle runner unavailable: #{inspect(reason)}"}
    end
  end

  test "smoke: oracle runner returns a parsed form snapshot payload" do
    spec = %{
      "base_url" => OracleRunner.base_url(),
      "initial_path" => "/page/index",
      "steps" => [],
      "capture" => %{
        "type" => "form_snapshot",
        "form_selector" => "#full-form"
      }
    }

    result = OracleRunner.run!(spec)

    assert result["ok"] == true
    assert is_list(result["trace"])
    assert %{"entries" => entries, "controls" => controls} = result["capture"]
    assert is_list(entries)
    assert is_list(controls)
  end
end
