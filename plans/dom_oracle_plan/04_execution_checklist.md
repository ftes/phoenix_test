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

1. `test/phoenix_test/dom_oracle/contracts_parity_test.exs`

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

## Phase 7 Systematic Divergence Discovery

Create files:

1. `test/phoenix_test/dom_oracle/discovery_test.exs` (or extend `contracts_parity_test.exs`).

Work items:

1. Add targeted matrix cases per control type/attribute combination (disabled ancestry, defaults, submitter attrs).
2. Add one lightweight generator/property sweep for DOM permutations where deterministic.
3. Capture each newly found mismatch with a stable contract ID and fixture route.

DoD:

1. New mismatches are discovered by test generation, not ad-hoc guessing.
2. Every discovered mismatch is either tracked as a contract or fixed.

## Phase 8 Driver Parity Cleanup

Update files:

1. `lib/phoenix_test/static.ex` add disabled click guard parity.
2. Ensure both drivers consume same DOM result structures.

DoD:

1. `C009` passes.
2. No regressions in existing driver tests.

## Phase 9 Documentation And Changelog

Update files:

1. `README.md` minimal note on browser-oracle conformance testing.
2. `CHANGELOG.md` behavior changes.
3. `upgrade_guides.md` migration notes if needed.

DoD:

1. Behavioral changes are explicitly documented.

## Phase 10 Spec Reference Docs

Update files:

1. `lib/phoenix_test/element/form.ex` moduledoc and key function docs.
2. `lib/phoenix_test/dom/form_owner.ex` moduledoc and key function docs.
3. `lib/phoenix_test/dom/disabled_state.ex` moduledoc and key function docs.
4. `lib/phoenix_test/dom/successful_controls.ex` moduledoc and key function docs.
5. `lib/phoenix_test/dom/form_serializer.ex` moduledoc and key function docs.
6. `lib/phoenix_test/dom/submitter.ex` moduledoc and key function docs.

Reference targets:

1. WHATWG HTML form submission algorithm.
2. WHATWG HTML successful controls and disabled controls rules.
3. MDN pages only as explanatory secondary links.

DoD:

1. Each Form/Rules module links to at least one primary spec section.
2. Publicly-relevant helper functions have brief docstrings citing the rule source.
3. Docs clearly separate browser-spec behavior from `phoenix_test` compatibility behavior.

## Phase 11 Live Oracle Parity Contracts

Create files:

1. `test/support/web_app/live_contracts.ex`
2. `test/support/web_app/contract_live.ex`

Update files:

1. `test/support/web_app/router.ex` add `/live/contracts/:contract` route.
2. `test/phoenix_test/dom_oracle/contracts_parity_test.exs` execute shared matrix for both `:static` and `:live` surfaces.

Work items:

1. Build LiveView fixtures matching each static contract (`C001`..`C018`) with equivalent DOM structure and submit targets.
2. Reuse the same contract definitions, expected statuses, and capture types for both static and live parity suites.
3. Run oracle against `/live/contracts/:id` and compare to `phoenix_test` live flow outputs.
4. Keep `C017` ignored in live parity until image-coordinate behavior is implemented.
5. Add failure diagnostics mirroring static contracts (failed step index/op + normalized diff payload).

DoD:

1. `mix test test/phoenix_test/dom_oracle/contracts_parity_test.exs` passes for all surfaces.
2. `mix test test/phoenix_test/dom_oracle` passes with both static and live parity cases enabled.
3. For each non-ignored contract, static and live suites have aligned expected states (`:match` or `:mismatch`).

## Phase 12 Spec Matrix Expansion

Work items:

1. Add new browser-spec contracts (`C019+`) to broaden HTML form coverage (readonly controls, option text fallback, disabled optgroup behavior, and other edge cases).
2. Define each new contract once in shared matrix data and execute against both static and live fixture surfaces.
3. Keep fixtures deterministic and minimal so diffs point to one rule per contract.
4. When a new contract uncovers divergence, either:
   - fix behavior to match the oracle and mark `:match`, or
   - track as explicit `:mismatch`/`:ignore` with rationale.

DoD:

1. Added contracts execute in `contracts_parity_test.exs` for both `:static` and `:live`.
2. `mix test test/phoenix_test/dom_oracle/contracts_parity_test.exs` passes.
3. `mix test test/phoenix_test/dom_oracle` passes.

Execution note:

1. Do not run multiple `mix test ...` commands in parallel in this project; test endpoint uses a fixed port (`4000`) and parallel runs will conflict.
2. Prefer a single full-suite invocation (`mix test`) instead of multiple scoped invocations; otherwise expensive parity tests run repeatedly and slow down feedback.

## Phase 13 Priority Order (Current)

Priority order:

1. Run full regression gate first: `mix test` (sequential execution only).
2. Reduce duplication between static and live parity suites by extracting shared parity harness code.
3. Continue refactoring boundaries so DOM-spec rules stay in `lib/phoenix_test/dom/*` and Phoenix-specific behavior is isolated in adapter/driver layers.
4. Implement image submitter coordinates parity (`C017`) after priorities 1-3 are complete.

DoD:

1. `mix test` passes after each priority boundary.
2. Static/live parity tests stay green while refactors are applied.
3. No new behavior coupling is introduced between DOM-rule modules and Phoenix transport/event specifics.

## Phase 14 DOM/Phoenix Boundary Cleanup (Current)

Findings:

1. `Static.submit_form/4` and `Live.submit_form/4` both implement submission preflight rules (form data merge, submitter contribution, constraint validation) with partially duplicated logic.
2. The execution backends are intentionally different and should remain separate:
   - Static path: conn dispatch + redirect handling.
   - Live path: `LiveViewTest` event/render flow (`phx-click`, `phx-submit`, nested view semantics).
3. Practical split target is shared submission planning, not a fully unified driver.

Plan:

1. Add `lib/phoenix_test/dom/submission_plan.ex` for shared DOM-side planning helpers:
   - merge form/default data + active-form data when owner matches,
   - merge submitter contribution,
   - run constraint-validation gate,
   - expose effective method/action resolution hooks.
2. Refactor `lib/phoenix_test/static.ex` to consume `SubmissionPlan` for preflight/decision logic while keeping HTTP dispatch local.
3. Refactor `lib/phoenix_test/live.ex` to consume `SubmissionPlan` for preflight/decision logic while keeping LiveView event transport local.
4. Keep behavior identical; no path-level semantic changes in this phase.

DoD:

1. Shared submission planning rules live in `lib/phoenix_test/dom/submission_plan.ex`.
2. `Static` and `Live` call shared planner helpers for merge/validation/submitter logic.
3. One full `mix test` run passes.

## Phase 15 High-Frequency Form Parity Expansion (Current)

Findings:

1. `C017` (`input[type=image]`) is valid but lower-frequency than repeated-name and ordering behavior in everyday forms.
2. Current matrix does not explicitly lock down repeated-name semantics (multiple controls sharing one `name`) and duplicate entry handling.
3. These patterns have higher product impact because they appear in multi-select/checkbox groups and dynamic form builders.

Next steps:

1. Add new shared contracts (`C025+`) targeting repeated names and ordering-sensitive scenarios:
   - repeated non-`[]` names across multiple controls,
   - repeated `[]` names with duplicate values,
   - mixed hidden + checkbox combinations with repeated names.
2. Keep fixtures deterministic and minimal; one rule per contract.
3. Start with expected `:mismatch` where current behavior is intentionally tracked but not fixed yet.
4. After matrix expansion, prioritize fixes for the highest-frequency mismatches before returning to `C017`.

Progress:

1. `C025`-`C028` were added and are now `:match` on both static and live surfaces after `FormData` entry-order/preservation updates.

DoD:

1. Added contracts run on both static and live surfaces through `contracts_parity_test.exs`.
2. Matrix clearly marks which high-frequency cases are currently mismatches.
3. One full `mix test` run passes.

## Suggested Commit Boundaries

1. `test(dom-oracle): add playwright runner and exunit wrapper`
2. `test(dom-oracle): add P0 differential contract tests`
3. `refactor(dom): add form owner module and integrate field/select/button`
4. `refactor(dom): replace form_data heuristics with successful controls serializer`
5. `refactor(dom): implement submitter model and action/method overrides`
6. `fix(static): align disabled button behavior with live driver`
7. `test(dom-oracle): add systematic divergence discovery matrix`
8. `docs: add conformance notes and upgrade guide`
9. `docs(dom): add spec-linked moduledocs for form/rules modules`
10. `test(dom-oracle): add live contract fixtures and parity suite`

## Minimal Acceptance Gate

Run:

```bash
cd /Users/ftes/src/phoenix_test
mix test
```
