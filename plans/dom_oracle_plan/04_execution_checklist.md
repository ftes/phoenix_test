# Execution Checklist

This is the implementation runbook.

## Phase 0 Baseline

1. Run baseline tests and record failures.
2. Confirm Playwright JS availability for oracle harness.

Commands:

```bash
cd /Users/ftes/src/phoenix_test
mix test
node -v
```

DoD:

1. Baseline test status captured.
2. Node runtime confirmed.

## Phase 1 Add Oracle Harness

Create files:

1. `test/support/oracle/playwright_oracle_runner.mjs`
2. `test/support/oracle/oracle_ops.mjs`
3. `test/support/oracle/oracle_capture.mjs`
4. `test/support/oracle/schema_step_ir.json`
5. `test/support/oracle_runner.ex`
6. `test/support/oracle_normalize.ex`
7. `test/support/oracle_diff.ex`

Update files:

1. `test/test_helper.exs` to load support modules.
2. `mix.exs` only if test aliases need Node bootstrap hook.

Implementation notes:

1. Runner input: JSON file path argument.
2. Runner output: single JSON object to stdout.
3. Include operation trace in output for debugging.
4. Include structured errors:
   - `failed_step_index`
   - `failed_op`
   - `playwright_error`

DoD:

1. One smoke contract test can invoke runner and parse response.

## Phase 2 Add Contract Fixtures

Create files:

1. `test/support/web_app/contract_page_controller.ex`
2. `test/support/web_app/templates/contract/*.html.heex` or inline render.

Update files:

1. `test/support/web_app/router.ex` add contract routes.

Fixture naming:

1. `c001.html.heex`
2. `c002.html.heex`
3. ...

DoD:

1. Each contract route returns deterministic HTML.

## Phase 3 Add Differential Contract Tests

Create files:

1. `test/phoenix_test/dom_oracle/contracts_test.exs`
2. `test/phoenix_test/dom_oracle/contracts_live_parity_test.exs`
3. Optional: `test/phoenix_test/dom_oracle/contracts_static_parity_test.exs`

Test pattern:

1. Build step IR for contract.
2. Execute oracle runner.
3. Execute equivalent `phoenix_test` flow.
4. Normalize and compare.

DoD:

1. P0 contracts exist and fail where divergences are known.
2. Diff output is readable and points to exact mismatch.

## Phase 4 Extract Form Owner Rules

Create files:

1. `lib/phoenix_test/dom/form_owner.ex`

Update files:

1. `lib/phoenix_test/element/field.ex`
2. `lib/phoenix_test/element/select.ex`
3. `lib/phoenix_test/element/button.ex`

DoD:

1. `C004`, `C005`, `C008` pass.

## Phase 5 Extract Successful Controls + Disabled Rules

Create files:

1. `lib/phoenix_test/dom/disabled_state.ex`
2. `lib/phoenix_test/dom/successful_controls.ex`
3. `lib/phoenix_test/dom/form_serializer.ex`

Update files:

1. `lib/phoenix_test/element/form.ex` delegates to serializer.
2. Tests in:
   - `test/phoenix_test/element/form_test.exs`
   - new contract tests.

DoD:

1. `C001`, `C003`, `C013`, `C015` pass.

## Phase 6 Submitter Model

Create files:

1. `lib/phoenix_test/dom/submitter.ex`

Update files:

1. `lib/phoenix_test/element/button.ex`
2. `lib/phoenix_test/element/form.ex`
3. `lib/phoenix_test/static.ex`
4. `lib/phoenix_test/live.ex`

DoD:

1. `C006`, `C007`, `C011`, `C012` pass.

## Phase 7 Driver Parity Cleanup

Update files:

1. `lib/phoenix_test/static.ex` add disabled click guard parity.
2. Ensure both drivers consume same DOM result structures.

DoD:

1. `C009` passes.
2. No regressions in existing driver tests.

## Phase 8 Documentation And Changelog

Update files:

1. `README.md` minimal note on browser-oracle conformance testing.
2. `CHANGELOG.md` behavior changes.
3. `upgrade_guides.md` migration notes if needed.

DoD:

1. Behavioral changes are explicitly documented.

## Suggested Commit Boundaries

1. `test(dom-oracle): add playwright runner and exunit wrapper`
2. `test(dom-oracle): add P0 differential contract tests`
3. `refactor(dom): add form owner module and integrate field/select/button`
4. `refactor(dom): replace form_data heuristics with successful controls serializer`
5. `refactor(dom): implement submitter model and action/method overrides`
6. `fix(static): align disabled button behavior with live driver`
7. `docs: add conformance notes and upgrade guide`

## Minimal Acceptance Gate

Run:

```bash
cd /Users/ftes/src/phoenix_test
mix test test/phoenix_test/dom_oracle
mix test
```
