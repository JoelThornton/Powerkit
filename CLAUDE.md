# powerkit — project rules

## What this is
A unified power analysis tool for psychology. One design specification format,
routed to validated R backends (Spower, power4mome, Superpower, InteractionPoweR),
with a Shiny front end (design finder, design forms, full-model builder,
confirmation screen, results and exports). An optional AI assistant comes last.
Full plan: docs/build-guide.md. Product background: docs/strategy.md (if present).

## Non-negotiables
- Never write new statistical maths when a backend package already does it; adapt the spec.
- Never edit expected values in tests/testthat/test-validation-*. They are transcribed
  from published sources by the maintainer. If a test fails, report why.
- Validation tests may contain `TODO_PUBLISHED_VALUE` placeholders; leave them for the maintainer.
- Every result records: spec hash, seed, backend, R and package versions.
- The Shiny app never computes power; it builds specs and calls the engine.
- Citations come only from inst/citations/refs.bib or a package's own citation().
  Never invent references or write one from memory.
- Plain-English errors for users; no stack traces in the UI.
- powerkit follows the established tools' conventions by default. Any
  departure must be recorded in docs/conventions.md, shown to the user on the
  results screen, stated in the methods paragraph, and covered by a test
  showing the size of the difference.
- Work one build phase at a time (docs/build-guide.md section 8). Stop at the end of
  a phase and summarise what was done, what's untested, and open questions.

## Conventions
- R package in engine/ with roxygen2 docs, testthat 3rd edition, renv for versions.
- tidyverse style guide; small, pure functions where possible.
- Design specs are JSON validated against engine/inst/schema/design.schema.json.
- High-replication validation tests are skipped by default (skip unless
  env var POWERKIT_FULL_VALIDATION=true). Nightly CI runs a fast subset
  (basic tests, regression interactions); the full validation runs on
  demand, before merges and releases, on the maintainer's machine, with
  scripts/run-validation.R.

## Working process (maintainer, 18 October 2026)
The maintainer is the only reviewer and decider, so keep what they have
to read small.
- Judgement calls: give a recommendation and a one-line reason, not only
  neutral options. The maintainer accepts or overrules it. When a call is decided, move
  its entry to docs/archive/judgement-calls-decided.md and record it in
  docs/decisions.md.
- docs/status.md is current state only: replace old entries, don't append
  history (git, NEWS.md and docs/archive/ hold that).
- Prefer updating an existing doc to adding a new one.
- One design or one feature per PR; keep code changes to a few hundred
  lines where possible, and keep docs-only changes in their own PR.
- One thread per area at a time (engine, app, docs). Before editing a
  shared page (handover.md, status.md), check open PRs for edits to it.
- Local R in a cloud session: scripts/setup-cloud-session.sh (also usable
  as the environment's setup script).

## Before finishing any task
- Run devtools::test() and devtools::check() in engine/; both must pass
  (validation tests with TODO placeholders may be skipped, not deleted).
- Update NEWS.md with user-visible changes.
- Update docs/status.md (where the project is and what's next) in every PR.
