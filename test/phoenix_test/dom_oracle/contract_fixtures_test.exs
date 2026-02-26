defmodule PhoenixTest.DomOracle.ContractFixturesTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest

  @endpoint PhoenixTest.WebApp.Endpoint

  setup do
    %{conn: build_conn()}
  end

  test "P0 contract routes render deterministic fixtures", %{conn: conn} do
    expectations = [
      {"/page/contracts/c001", ~w(data-contract=\"c001\" id=\"c001-form\" name=\"token\")},
      {"/page/contracts/c002", ~w(data-contract=\"c002\" id=\"c002-form\" name=\"admin\")},
      {"/page/contracts/c003", ~w(data-contract=\"c003\" id=\"c003-form\" fieldset_blocked)},
      {"/page/contracts/c004", ~w(data-contract=\"c004\" id=\"c004-form\" form=\"c004-form\")},
      {"/page/contracts/c005", ~w(data-contract=\"c005\" id=\"c005-form\" form=\"c005-form\")},
      {"/page/contracts/c006", ~w(data-contract=\"c006\" id=\"c006-form\" type=\"button\")},
      {"/page/contracts/c007", ~w(data-contract=\"c007\" id=\"c007-form\" type=\"submit\")},
      {"/page/contracts/c008", ~w(data-contract=\"c008\" id=\"c008-form-a\" id=\"c008-form-b\")},
      {"/page/contracts/c009", ~w(data-contract=\"c009\" id=\"c009-form\" disabled)},
      {"/page/contracts/c010", ~w(data-contract=\"c010\" id=\"c010-form\" type=\"radio\")},
      {"/page/contracts/c011", ~w(data-contract=\"c011\" id=\"c011-form\" name=\"save_a\")},
      {"/page/contracts/c012", ~w(data-contract=\"c012\" id=\"c012-form\" formmethod=\"get\")},
      {"/page/contracts/c013", ~w(data-contract=\"c013\" id=\"c013-form\" id=\"c013-no-name\")},
      {"/page/contracts/c014", ~w(data-contract=\"c014\" id=\"c014-form\" id=\"c014-race\")},
      {"/page/contracts/c015", ~w(data-contract=\"c015\" id=\"c015-form\" multiple)},
      {"/page/contracts/c016", ~w(data-contract=\"c016\" id=\"c016-form\" Implicit\ Name)},
      {"/page/contracts/c017", ~w(data-contract=\"c017\" id=\"c017-form\" type=\"image\")},
      {"/page/contracts/c018", ~w(data-contract=\"c018\" id=\"c018-form\" required)}
    ]

    Enum.each(expectations, fn {path, snippets} ->
      body =
        conn
        |> recycle()
        |> get(path)
        |> html_response(200)

      Enum.each(snippets, fn snippet ->
        assert body =~ snippet
      end)
    end)
  end
end
