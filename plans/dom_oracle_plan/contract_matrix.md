# Contract Matrix

Each contract has:

1. Stable ID.
2. Priority (`P0`, `P1`, `P2`).
3. Fixture requirements.
4. Step IR sequence.
5. Expected browser oracle result.
6. Expected current `phoenix_test` status for baseline.

## P0 Contracts (Implement First)

### C001 Disabled hidden control excluded

1. Priority: `P0`
2. Fixture: form with `<input type="hidden" name="token" value="abc" disabled>`.
3. Steps: capture `form_snapshot`.
4. Oracle: `entries` must not include `["token","abc"]`.
5. Current `phoenix_test`: likely fails (includes token).

### C002 Checked checkbox without value defaults to `"on"`

1. Priority: `P0`
2. Fixture: `<input type="checkbox" name="admin" checked>`.
3. Steps: capture `form_snapshot`.
4. Oracle: `entries` includes `["admin","on"]`.
5. Current `phoenix_test`: likely fails (omits field).

### C003 Disabled fieldset descendants excluded

1. Priority: `P0`
2. Fixture: disabled fieldset containing enabled-looking input.
3. Steps: capture `form_snapshot`.
4. Oracle: descendant control excluded unless in first legend exception.
5. Current `phoenix_test`: likely fails (includes control).

### C004 `form=` associated input included

1. Priority: `P0`
2. Fixture: `<form id="f"></form>` and external `<input form="f" ...>`.
3. Steps: capture `form_snapshot` for `#f`.
4. Oracle: includes external control entry.
5. Current `phoenix_test`: likely fails (excludes control).

### C005 `form=` associated select included

1. Priority: `P0`
2. Fixture: external `<select form="f" name="race">...`.
3. Steps: capture `form_snapshot`.
4. Oracle: includes selected option value.
5. Current `phoenix_test`: likely fails.

### C006 `type=button` with `form=` is not submitter

1. Priority: `P0`
2. Fixture: form + external `<button type="button" form="f">`.
3. Steps: click button and capture submit side effects.
4. Oracle: no form submission from this button.
5. Current `phoenix_test`: likely fails for form association path.

### C007 Default submitter supports `<input type="submit">`

1. Priority: `P0`
2. Fixture: form with only `<input type="submit" name="save" value="Save">`.
3. Steps: `submit(active form)` path.
4. Oracle: submitter contributes `["save","Save"]`.
5. Current `phoenix_test`: likely fails.

### C008 Hidden uncheck fallback scoped to same form owner

1. Priority: `P0`
2. Fixture: two forms with same checkbox `name` and hidden fallback.
3. Steps: uncheck checkbox in one form.
4. Oracle: no ambiguity, only same owner hidden control used.
5. Current `phoenix_test`: likely fails due global lookup.

### C009 Static and Live parity for disabled button click

1. Priority: `P0`
2. Fixture: disabled submit button.
3. Steps: `click_button`.
4. Oracle: action blocked.
5. Current `phoenix_test`: Live blocks, Static may not.

## P1 Contracts (Next)

### C010 Radio without value defaults to `"on"` when checked

1. Priority: `P1`
2. Fixture: checked radio input with no `value`.
3. Steps: capture `form_snapshot`.
4. Oracle: includes `["name","on"]`.

### C011 Submitter `name/value` included only for actual submitter

1. Priority: `P1`
2. Fixture: multiple submit controls with names.
3. Steps: click one specific submitter.
4. Oracle: only clicked submitter contributes `name/value`.

### C012 Submitter `formmethod` and `formaction` override

1. Priority: `P1`
2. Fixture: form with method/action + submitter override attrs.
3. Steps: click submitter.
4. Oracle: effective action/method reflect submitter override.

### C013 Missing `name` controls excluded

1. Priority: `P1`
2. Fixture: controls lacking `name`.
3. Steps: capture `form_snapshot`.
4. Oracle: unnamed controls absent in `entries`.

### C014 Select single with no selected option yields first option value

1. Priority: `P1`
2. Fixture: single select with options but no `selected`.
3. Steps: capture `form_snapshot`.
4. Oracle: first successful option is included.

### C015 Multi-select with no selected options yields no entries

1. Priority: `P1`
2. Fixture: `<select multiple>` no selected options.
3. Steps: capture `form_snapshot`.
4. Oracle: no entries for that name.

### C016 Label association explicit + implicit consistency

1. Priority: `P1`
2. Fixture: label with `for` and nested input.
3. Steps: locator by label.
4. Oracle: resolves control consistently.

## P2 Contracts (Later)

### C017 Image submitter coordinates handling

1. Priority: `P2`
2. Fixture: `<input type="image" name="img">`.
3. Steps: click image submitter.
4. Oracle: includes coordinate fields.

### C018 Exotic input types and constraint validation edge cases

1. Priority: `P2`
2. Fixture: date/time and invalid states.
3. Steps: fill and submit.
4. Oracle: browser behavior preserved.

## Suggested Fixture Implementation

Create dedicated test routes/pages for contracts:

1. `/page/contracts/c001`
2. `/page/contracts/c002`
3. ...
4. `/live/contracts/c001` for parity where Live semantics matter.

## Comparison Rules

1. Compare `entries` as ordered tuples.
2. Compare `effective_method`, `effective_action`.
3. Compare submitter identity where relevant.
4. Ignore non-semantic HTML whitespace.

