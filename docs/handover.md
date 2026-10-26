# Handover

*Updated 18 October 2026, for whoever picks the project up next.
[`status.md`](status.md) is the current state and the priorities; this
page is the working rules and where things live. [`README.md`](README.md)
maps every document.*

## Current state

- **Engine** (`engine/`): every design E1–E14 runs through `run_spec()`
  and has passed its full validation run. Published values are still to
  be transcribed by the maintainer (`TODO_PUBLISHED_VALUE` placeholders).
  The basic tests (E1–E6) use pwr's or base R's formula by default
  (Departure 9) and can find the smallest detectable effect at a fixed N.
  Wave 2 (one-way ANOVA, R², one proportion, McNemar, Welch by formula)
  runs in the engine but isn't in the app yet.
- **App** (`app/routing/`): the new four-screen design
  ([`decisions.md`](decisions.md), "2026-10-18 · The new design"):
  - screen A, start questions (situation, aim, claim);
  - screen B, the question tree and end-point cards;
  - screen C, inputs with the effect-size source and the user's
    reasoning, and "I can't justify an effect size" (E1–E4);
  - screen D, the result with a plain reading, 80% and 95% side by side,
    the reasoning, what power can't tell you, an explore panel (E1–E4),
    and the departures and known differences.

  E1–E9 calculate on the input screen (E9 in the background); E10–E14
  give a preview, then a full run or an R script. Plans save as project
  files. Saving, the R script and the write-up need the reasoning.
- **Open PRs, next steps and what the maintainer still owes:** in
  [`status.md`](status.md). Pull requests and git history hold everything
  merged before that.
- **Branches:** sessions can't delete remote branches (403), so merged
  branches pile up until the maintainer deletes them; the one to keep is
  `claude/project-thread-uqcark-webr-spike` (never merged).

## Adding a power analysis

[`adding-a-test.md`](adding-a-test.md) is the process, start to finish, and
holds the queue of what to add next. The short version: a test is added
when a researcher can run it and see that it exists, so the engine, the
card, the input screen, the "What's new" entry and the version bump land
together.

## Rules

- **Priorities and process (18 October 2026):** usefulness for
  psychologists comes before validation until release, and the new
  design is built in the order in [`status.md`](status.md), "What's
  next". How to keep reviews small (recommendations on judgement
  calls, PR size, one thread per area, status as current state) is in
  `CLAUDE.md`, "Working process".
- **Public content:** the repository is public. Commits, PR titles and
  descriptions, comments and repo files explain what a change does, why
  (in terms of the software, its users or published sources) and how.
  They never summarise project chats, private emails or correspondence,
  or who said what; personal and discussion notes stay outside the
  repository (`CLAUDE.md`, "Working process").
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
  adding it to `refs.bib`, with a verification note (or, for a source the
  maintainer checked in full text, "Verified YYYY-MM-DD from full-text PDF
  held by the maintainer"); if it can't be opened,
  mark it "candidate" and leave it out (as with Hoenig and Heisey for B11).
  Any departure from a tool's conventions goes in `conventions.md`, on the
  result screen, in the methods paragraph, and in a test showing its size.
- **Every PR:** run the engine and app tests (`devtools::test()`,
  `devtools::check()` in `engine/`; `testthat::test_dir("app/routing/tests/testthat")`
  from the repo root with `NOT_CRAN=true`), and update `engine/NEWS.md`
  and `status.md`. A PR that changes what users see also adds a dated,
  plain-words entry at the top of `app/routing/whats-new.yaml` (the app's
  "What's new" tab; no internal codes such as E5).
- **Saving usage:** report only failures from tests and checks, and read
  full logs only when something failed.

## Where the judgement calls and decisions live

- [`judgement-session.md`](judgement-session.md): the open calls
  that change what users see, one page each, for the session (routing
  from screen A onwards first).
- [`judgement-calls.md`](judgement-calls.md): every open or decided
  judgement call, with options and the default now. Open ones include B12
  (N rounding), B13 (power curve), B16 (what "simulation for data that
  won't meet the assumptions" should simulate) and B17 (E9's progress
  bar); B11 waits for its source. B4 and G7–G9 were decided with the new
  design and G4 (what the methods paragraph reports) on 18 October 2026;
  B6 is partly decided. Open questions for the
  maintainer on phase 5 are in `phase5-simulations.md` (questions 1–4).
- [`decisions.md`](decisions.md): the maintainer's decisions, dated.
- [`conventions.md`](conventions.md): each backend's conventions and
  powerkit's departures (1–11) and known differences (1–2).
- [`phase5-simulations.md`](phase5-simulations.md): options for E10–E14 and the maintainer's decision.
- [`phase-3b-questions.md`](phase-3b-questions.md): binary X and W.
- In the app, the "For the maintainer: undecided settings" tab lists the
  placeholders from `tree.yaml`.
