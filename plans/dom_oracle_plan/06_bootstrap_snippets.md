# Bootstrap Snippets

These snippets are starting points for implementation.

## Node Runner Skeleton

Path: `test/support/oracle/playwright_oracle_runner.mjs`

```js
import fs from "node:fs/promises";
import { chromium } from "playwright";
import { runSteps } from "./oracle_ops.mjs";
import { captureResult } from "./oracle_capture.mjs";

const inputPath = process.argv[2];
const raw = await fs.readFile(inputPath, "utf8");
const spec = JSON.parse(raw);

const browser = await chromium.launch({ headless: true });
const context = await browser.newContext();
const page = await context.newPage();

try {
  const trace = [];
  await page.goto(`${spec.base_url}${spec.initial_path}`);
  await runSteps(page, spec.steps, trace);
  const capture = await captureResult(page, spec.capture);
  process.stdout.write(JSON.stringify({ ok: true, trace, capture }));
} catch (error) {
  process.stderr.write(
    JSON.stringify({
      ok: false,
      message: error?.message || String(error),
      stack: error?.stack || null
    })
  );
  process.exitCode = 1;
} finally {
  await browser.close();
}
```

## ExUnit Wrapper Skeleton

Path: `test/support/oracle_runner.ex`

```elixir
defmodule PhoenixTest.OracleRunner do
  @runner Path.expand("../support/oracle/playwright_oracle_runner.mjs", __DIR__)

  def run!(spec) when is_map(spec) do
    json = Jason.encode!(spec)
    tmp = Path.join(System.tmp_dir!(), "phoenix_test_oracle_#{System.unique_integer([:positive])}.json")
    File.write!(tmp, json)

    {out, status} =
      System.cmd("node", [@runner, tmp], stderr_to_stdout: true)

    case {status, Jason.decode(out)} do
      {0, {:ok, %{"ok" => true} = decoded}} -> decoded
      _ -> raise "Oracle runner failed: #{out}"
    end
  after
    File.rm(tmp)
  end
end
```

## Differential Test Skeleton

Path: `test/phoenix_test/dom_oracle/contracts_test.exs`

```elixir
defmodule PhoenixTest.DomOracle.ContractsTest do
  use PhoenixTest.ConnCase, async: true

  test "C002 checkbox default on", %{conn: conn} do
    spec = %{
      "base_url" => "http://127.0.0.1:4002",
      "initial_path" => "/page/contracts/c002",
      "steps" => [],
      "capture" => %{"type" => "form_snapshot", "form_selector" => "#f"}
    }

    oracle = PhoenixTest.OracleRunner.run!(spec)

    session = PhoenixTest.visit(conn, "/page/contracts/c002")
    form = PhoenixTest.Element.Form.find!(PhoenixTest.render_html(session), "#f")
    ours = PhoenixTest.FormData.to_list(form.form_data)

    assert normalize_entries(oracle["capture"]["entries"]) == normalize_entries(ours)
  end

  defp normalize_entries(entries), do: Enum.map(entries, fn [k, v] -> {k, v} end)
end
```

## Contract ID Convention

Use prefix in tests and commit titles:

1. `C001` disabled hidden excluded
2. `C002` checkbox default on
3. `C003` disabled fieldset exclusion
4. ...

## Validation Command Loop

```bash
cd /Users/ftes/src/phoenix_test
mix test test/phoenix_test/dom_oracle/contracts_test.exs
mix test test/phoenix_test/element/form_test.exs
mix test
```

