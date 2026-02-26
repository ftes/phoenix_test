# Browser Oracle Design

## Decision

Use **vanilla Playwright JS** as the primary oracle in Phase 1.

Reason:

1. Lowest coupling to `phoenix_test` internals.
2. Browser behavior is direct source of truth.
3. Avoids circular validation through `ptp` abstraction.

`ptp` can be added later as a secondary implementation backend for comparison.

## High-Level Architecture

1. ExUnit contract test builds a list of steps and fixture path.
2. ExUnit executes same steps in:
   - `phoenix_test` runtime
   - Playwright oracle runner (Node process)
3. Both return normalized result JSON.
4. Test compares normalized payloads and metadata.

## Step IR (Intermediate Representation)

Use a serializable map/list format.

```json
{
  "base_url": "http://127.0.0.1:4002",
  "initial_path": "/page/index",
  "steps": [
    { "op": "within", "selector": "#full-form", "mode": "push" },
    { "op": "fill_in", "label": "Name", "value": "Aragorn", "exact": true },
    { "op": "check", "label": "Admin", "exact": true },
    { "op": "click_button", "text": "Save", "exact": true },
    { "op": "within", "mode": "pop" }
  ],
  "capture": {
    "type": "form_snapshot",
    "form_selector": "#full-form"
  }
}
```

## Step Semantics

1. `within push` pushes scope locator to stack.
2. `within pop` pops scope locator.
3. Current scope is page if stack is empty.
4. All label and role queries are resolved from current scope.
5. Strictness default is `true`.

## Operation Mapping To Playwright

1. `visit(path)` -> `page.goto(base_url + path)`.
2. `fill_in(label)` -> `scope.getByLabel(label, { exact }).fill(value)`.
3. `fill_in(css,label)` -> `scope.locator(css).and(scope.getByLabel(label,{ exact })).fill(value)`.
4. `check(label)` -> `scope.getByLabel(label, { exact }).check()`.
5. `uncheck(label)` -> `scope.getByLabel(label, { exact }).uncheck()`.
6. `choose(label)` -> same as `check` for radio.
7. `select(label, option)` -> `scope.getByLabel(label,{ exact }).selectOption(...)`.
8. `click_button(text)` -> `scope.getByRole("button",{ name:text, exact }).click()`.
9. `submit(form_selector)`:
   - if submitter provided, call `form.requestSubmit(submitter)`.
   - else call `form.requestSubmit()`.

## Oracle Capture API

Use in-page `evaluate` helpers.

### Capture `form_snapshot`

Return:

```json
{
  "form_selector": "#full-form",
  "method_attr": "post",
  "action_attr": "/users",
  "effective_method": "post",
  "effective_action": "/users",
  "entries": [["name","Aragorn"],["admin","on"]],
  "controls": [
    {
      "tag": "input",
      "type": "checkbox",
      "name": "admin",
      "disabled": false,
      "form_owner_id": "full-form"
    }
  ]
}
```

### Capture `submit_result`

Return:

```json
{
  "submitted": true,
  "submitter": {"tag":"button","type":"submit","name":"save","value":"yes"},
  "entries": [["name","Aragorn"],["save","yes"]],
  "effective_method": "post",
  "effective_action": "/users"
}
```

## Node Runner Layout

Planned files:

1. `test/support/oracle/playwright_oracle_runner.mjs`
2. `test/support/oracle/oracle_ops.mjs`
3. `test/support/oracle/oracle_capture.mjs`
4. `test/support/oracle/schema_step_ir.json`

Runner contract:

1. Input JSON on file path arg or stdin.
2. Output JSON on stdout.
3. Exit code non-zero with structured error JSON on stderr when step fails.

## Elixir Wrapper Layout

Planned files:

1. `test/support/oracle_runner.ex`
2. `test/support/oracle_normalize.ex`
3. `test/support/oracle_diff.ex`

Wrapper responsibilities:

1. Serialize step IR.
2. Invoke Node runner via `System.cmd/3`.
3. Decode JSON output.
4. Normalize key ordering and string conversions.
5. Produce readable diff on mismatch.

## Determinism Rules

1. Force Chromium in headless mode.
2. Disable animations if needed via injected CSS.
3. Use explicit timeouts.
4. Avoid relying on navigation timing except where contract requires it.
5. Avoid random data in fixture pages.

## Why Not Translate Full Existing Test Suite First

1. Existing tests include current behavior quirks.
2. Contract matrix must be explicit first.
3. Translating everything early adds noise and migration cost.

