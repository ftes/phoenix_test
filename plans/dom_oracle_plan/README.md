# DOM Oracle + DOM/Form Extraction Plan

This plan is written so implementation can restart from disk with zero chat context.

## Goal

Align `phoenix_test` form and selector behavior more closely with browser/HTML behavior while keeping Phoenix ergonomics and test speed.

## Execution Order

1. Read [`01_scope_and_findings.md`](./01_scope_and_findings.md).
2. Read [`02_oracle_design.md`](./02_oracle_design.md).
3. Read [`contract_matrix.md`](./contract_matrix.md).
4. Execute [`04_execution_checklist.md`](./04_execution_checklist.md) in order.
5. Use [`03_dom_rules_extraction.md`](./03_dom_rules_extraction.md) as the refactor guide.
6. Use [`05_risks_and_decisions.md`](./05_risks_and_decisions.md) for tradeoffs and CI strategy.

## Primary Strategy

1. Build browser oracle first.
2. Define spec contract expectations and outcomes.
3. Compare `phoenix_test` outputs against browser outputs.
4. Extract DOM/Form rules into explicit modules incrementally.
5. Keep Phoenix-specific behavior isolated from generic DOM rules.

## Deliverables

1. Browser oracle runner (Node + Playwright) used by ExUnit.
2. Contract tests that compare browser oracle vs `phoenix_test`.
3. New explicit DOM/Form modules in `lib/phoenix_test/dom/*`.
4. Driver integration in `Live` and `Static` through shared rules.
5. Divergence list with explicit test tags only where intentional.

## Quick Restart Commands

```bash
cd /Users/ftes/src/phoenix_test
mix deps.get
mix test
```

When oracle harness exists:

```bash
cd /Users/ftes/src/phoenix_test
mix test test/phoenix_test/dom_oracle
```

## Non-Goals for Phase 1

1. Full Playwright parity API.
2. Full HTTP browser stack emulation in Elixir.
3. Solving every `phoenix_test_playwright` skip immediately.
