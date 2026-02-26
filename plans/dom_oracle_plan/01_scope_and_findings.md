# Scope And Findings

## Scope

This plan targets:

1. HTML form control ownership and serialization behavior.
2. Submitter behavior and default submit flow.
3. Selector flexibility improvements that are compatible with current APIs.
4. Separation of DOM-generic rules from Phoenix-specific mechanics.

This plan does not target full browser event simulation.

## Current Behavior Snapshot (Validated)

Validated from current code and local probes in `/Users/ftes/src/phoenix_test`.

1. Form default data generation is hardcoded via selector buckets.
   - `lib/phoenix_test/element/form.ex:92`
   - `lib/phoenix_test/element/form.ex:103`
2. Hidden inputs are included even when disabled.
   - `lib/phoenix_test/element/form.ex:92`
3. Checked checkbox/radio without `value` are omitted from default form data.
   - `lib/phoenix_test/element/form.ex:93`
4. Disabled fieldset inherited disabledness is not modeled.
   - `lib/phoenix_test/element/form.ex:100`
5. `form=` ownership for controls outside form subtree is mostly unsupported.
   - `lib/phoenix_test/element/field.ex:75`
   - `lib/phoenix_test/element/select.ex:68`
6. Hidden uncheck fallback uses global lookup by `name` and can become ambiguous.
   - `lib/phoenix_test/element/field.ex:51`
7. Default submit button discovery only covers `<button>`, not `<input type=submit|image>`.
   - `lib/phoenix_test/element/button.ex:32`
8. `Button.belongs_to_form?` treats any `form=` button as form-associated submit path, even `type="button"`.
   - `lib/phoenix_test/element/button.ex:62`
9. `Live` blocks disabled button click, `Static` does not.
   - `lib/phoenix_test/live.ex:117`
   - `lib/phoenix_test/static.ex:89`

## Local Probe Results (already verified)

From `mix run` probes:

1. `disabled hidden included?: true`
2. `checked checkbox no value included?: false`
3. `form= associated input included?: false`
4. `type=button with form attr belongs_to_form?: true`
5. `input submit picked as submit_button?: false`
6. `hidden fallback ambiguity: yes`
7. `fieldset-disabled input included?: true`
8. `select belongs_to_form with form= attr?: false`

## `ptp` (phoenix_test_playwright) Snapshot

1. Uses Playwright internal selector model (`internal:label`, `internal:role`, `internal:text`).
   - `../ptp/deps/playwright_ex/lib/playwright_ex/selector.ex:52`
2. Action calls delegate to browser primitives (`fill`, `check`, `select_option`, `set_input_files`).
   - `../ptp/lib/phoenix_test/playwright.ex:678`
3. `exact_option: false` is explicitly not implemented.
   - `../ptp/lib/phoenix_test/playwright.ex:684`
4. `submit/1` is currently Enter key on last focused input.
   - `../ptp/lib/phoenix_test/playwright.ex:785`

## Why Browser Oracle First

Current test suite includes behavioral expectations that mix:

1. Intended user-facing semantics.
2. Existing implementation quirks.

A browser oracle gives a stable ground truth for DOM/form behavior before refactoring.

## Success Criteria

1. Contract tests explicitly describe DOM/form semantics.
2. Browser oracle and `phoenix_test` are compared automatically.
3. Known divergences are reduced phase-by-phase.
4. DOM rules become explicit modules, not scattered heuristics.
5. Phoenix specifics stay separate and clearly named.

