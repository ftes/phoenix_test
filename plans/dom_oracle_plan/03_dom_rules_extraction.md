# DOM/Form Rules Extraction Blueprint

## Design Principle

`Live` and `Static` should differ in transport and event mechanics, not in DOM/form semantics.

## Target Module Boundaries

## 1) DOM Generic

Planned namespace:

1. `lib/phoenix_test/dom/form_owner.ex`
2. `lib/phoenix_test/dom/successful_controls.ex`
3. `lib/phoenix_test/dom/form_serializer.ex`
4. `lib/phoenix_test/dom/submitter.ex`
5. `lib/phoenix_test/dom/disabled_state.ex`

Responsibilities:

1. Determine form owner using ancestor and `form=` association.
2. Determine successful controls for serialization.
3. Serialize controls into ordered entries.
4. Resolve submitter and submitter data.
5. Evaluate disabledness including fieldset inheritance.

## 2) Phoenix Specific

Stay outside DOM generic namespace:

1. `phx-change` and `phx-submit` triggering.
2. `data-method` fallback form behavior.
3. `_method` conventions for Phoenix endpoints.
4. ActiveForm merging mechanics for test sessions.

Candidates:

1. Keep in existing `Live` and `Static`.
2. Optionally add `lib/phoenix_test/phoenix_form_adapter.ex` to keep logic centralized.

## Integration Points

Current files to migrate off implicit heuristics:

1. `lib/phoenix_test/element/form.ex`
2. `lib/phoenix_test/element/field.ex`
3. `lib/phoenix_test/element/select.ex`
4. `lib/phoenix_test/element/button.ex`
5. `lib/phoenix_test/live.ex`
6. `lib/phoenix_test/static.ex`

## Incremental Refactor Sequence

## Phase A: Form Owner Resolution

Contracts: `C004`, `C005`, `C008`

1. Introduce `DOM.FormOwner.owner_form_selector(control, document)`.
2. Replace ancestor-only checks in `Field.belongs_to_form?` and `Select.belongs_to_form?`.
3. Scope hidden fallback lookup by resolved form owner.

Acceptance:

1. `C004`, `C005`, `C008` pass.
2. Existing unrelated tests pass.

## Phase B: Successful Controls + Disabled Semantics

Contracts: `C001`, `C003`, `C013`, `C015`

1. Replace selector bucket heuristics in `Element.Form.form_data/1`.
2. Add disabled-state evaluator for fieldset inherited disabledness.
3. Ensure unnamed controls are always excluded.

Acceptance:

1. `C001`, `C003`, `C013`, `C015` pass.

## Phase C: Checkbox/Radio Default Value

Contracts: `C002`, `C010`

1. Ensure checked checkbox/radio use `"on"` when value attribute missing.
2. Preserve explicit `value` when present.

Acceptance:

1. `C002`, `C010` pass.

## Phase D: Submitter Model

Contracts: `C006`, `C007`, `C011`, `C012`

1. Add submitter resolution for `button`, `input[type=submit]`, optional image later.
2. Exclude non-submit button types even when `form=` exists.
3. Include only actual submitter `name/value` on submit.
4. Apply submitter overrides to effective method/action.

Acceptance:

1. `C006`, `C007`, `C011`, `C012` pass.

## Phase E: Driver Parity And Cleanup

Contracts: `C009`

1. Align disabled click behavior in `Static` with `Live`.
2. Ensure both drivers use shared DOM rules module outputs.

Acceptance:

1. `C009` passes for both `Live` and `Static`.

## API Compatibility Guidance

1. Keep public `PhoenixTest` API unchanged in Phase 1.
2. If behavior changes, document in `CHANGELOG.md` and `upgrade_guides.md`.
3. Add explicit divergence tags only where intentionally retained.

## Testing Guidance During Refactor

For each extraction step:

1. Add contract test first.
2. Watch it fail on current behavior.
3. Implement one focused change.
4. Re-run contract and full affected suites.
5. Commit with contract ID in message.

