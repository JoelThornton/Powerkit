# Handover

*Written 17 October 2026, at the end of a working stretch, for whoever
picks the project up next. [`status.md`](status.md) is the running record;
this page is the short version plus the working rules.*

## Current state

- **Engine** (`engine/`): every design E1–E14 runs through `run_spec()`
  and has passed its full validation run. Published values are still being
  transcribed by the maintainer (`TODO_PUBLISHED_VALUE` placeholders).
- **Basic tests (E1–E6)** use pwr's exact formula by default (merged in
  PR #34; Departure 9 in [`conventions.md`](conventions.md)). Spower
  simulation stays available as an option, and for Welch's t-test. The
  `basic` validation chunk should be rerun on this code.
- **App prototype** (`app/routing/`): the question tree, cards and input
  screens for every end point. E1–E8 calculate on the input screen (merged
  in #34). E9 calculates in the background with a progress bar and Cancel
  (PR #36, waiting for the maintainer's yes). E10–E14 are not wired: they
  wait for the maintainer's decision on
  [`phase5-simulations.md`](phase5-simulations.md), questions 1–4.
- **Seed:** a fixed default (1), shown and changeable on every screen and
  recorded in the result and its R script.

## Open PRs

- **#36: E9 calculates, with a progress bar and Cancel.** Draft; changes
  what users see, so it needs the maintainer's yes before merging.
- **#35: coverage roadmap and routing design options** (docs only; from
  another thread).
- **#4: the early 2 x 2 Shiny demo** (`app/`, not `app/routing/`). An old
  draft built ahead of phase 5; superseded by the routing prototype's
  result screen. Close or keep is the maintainer's call.

## Rules

- **Merging:** anything that changes what users see (cards, wording,
  results, defaults, routing) needs the maintainer's explicit yes before
  merging. Docs-only and test-only PRs can merge on green when the
  maintainer says so. PRs are not watched automatically unless asked;
  check CI once at the end.
- **Areas:** one build phase at a time ([`build-guide.md`](build-guide.md),
  section 8). The app never computes power: it builds specs and calls the
  engine (`validate_spec()`, `run_spec()`, `export_script()`,
  `export_citations()`; a test enforces this). Never write statistics a
  backend already provides.
- **Placeholders:** never edit expected values in
  `engine/tests/testthat/test-validation-*`; leave `TODO_PUBLISHED_VALUE`
  for the maintainer. If a validation test fails, report why. Undecided
  settings stay as visible placeholders in the app (`tree.yaml`,
  `settings`).
- **Sourcing:** citations come only from `engine/inst/citations/refs.bib`
  or a package's own `citation()`. Open a source (via its DOI) before
  adding it to `refs.bib`, with a verification note; if it can't be opened,
  mark it "candidate" and leave it out (as with Hoenig and Heisey for B11).
  Any departure from a tool's conventions goes in `conventions.md`, on the
  result screen, in the methods paragraph, and in a test showing its size.
- **Every PR:** run the engine and app tests (`devtools::test()`,
  `devtools::check()` in `engine/`; `testthat::test_dir("app/routing/tests/testthat")`
  from the repo root with `NOT_CRAN=true`), and update `engine/NEWS.md`
  and `status.md`.
- **Saving usage:** report only failures from tests and checks, and read
  full logs only when something failed.

## Where the judgement calls and decisions live

- [`judgement-calls.md`](judgement-calls.md): every open or decided
  judgement call, with options and the default now. Open ones include B12
  (N rounding), B13 (power curve), B16 (what "simulation for data that
  won't meet the assumptions" should simulate) and B17 (E9's progress
  bar); B11 waits for its source.
- [`decisions.md`](decisions.md): the maintainer's decisions, dated.
- [`conventions.md`](conventions.md): each backend's conventions and
  powerkit's departures (1–9).
- [`phase5-simulations.md`](phase5-simulations.md): options for E10–E14.
- [`phase-3b-questions.md`](phase-3b-questions.md): binary X and W.
- In the app, the "For the maintainer: undecided settings" tab lists the
  placeholders from `tree.yaml`.
