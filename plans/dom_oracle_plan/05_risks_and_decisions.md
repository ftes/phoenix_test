# Risks And Decisions

## Decision Log

## D001 Oracle backend

Decision:

1. Primary oracle is vanilla Playwright JS.

Rationale:

1. Minimizes shared abstraction bias.
2. Direct browser semantics.

Deferred:

1. Optional secondary oracle via `ptp`.

## D002 Cross dependency with `../ptp`

Decision:

1. Do not symlink `../ptp/lib`.
2. Do not make hard test dependency in Phase 1.

Rationale:

1. Avoid hidden coupling.
2. Keep `phoenix_test` independently testable.

Alternative later:

1. Optional env-gated test job that runs same contracts through `ptp`.

## D003 Behavior change policy

Decision:

1. Browser/spec-aligned behavior wins over legacy quirks.
2. Divergences must be explicit and tagged with reason.

## Major Risks

## R001 CI runtime increase

Risk:

1. Browser tests are slower than unit tests.

Mitigations:

1. Keep contract suite focused and small.
2. Run only contract matrix in oracle lane.
3. Reuse browser process across cases when safe.

## R002 Flaky browser timing

Risk:

1. Async navigation and Live updates can cause non-determinism.

Mitigations:

1. Use deterministic fixtures.
2. Use explicit waits tied to DOM state.
3. Keep form snapshot captures synchronous via `evaluate`.

## R003 Misaligned semantics in translation layer

Risk:

1. Step IR mapping may diverge from PhoenixTest command semantics.

Mitigations:

1. Keep IR small and explicit.
2. Add unit tests for IR->Playwright mapping.
3. Include step trace in oracle output.

## R004 Scope creep

Risk:

1. Attempting full browser simulation in Elixir.

Mitigations:

1. Keep DOM module scope to serialization and form ownership first.
2. Defer advanced event semantics.

## Open Questions

1. Should `submit/1` semantics in oracle mimic current PhoenixTest active-form model or explicit form selector always?
2. Should legacy behavior be retained behind flags for one release cycle?
3. Which contracts must run on both static and live fixtures in Phase 1?

## Recommended Defaults

1. `submit/1` contract uses explicit form selector for oracle clarity.
2. No compatibility flags in first pass unless regression surface is large.
3. P0 runs on static first, then add live parity for `C009` and submitter cases.

## Failure Handling Policy

If mismatch occurs:

1. Fail test with normalized diff.
2. Include contract ID and step index.
3. If mismatch is intentional, tag case as `:known_divergence` with linked issue.

