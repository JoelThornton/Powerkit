# Handover

*Written 18 October 2026, at the end of a working stretch, for whoever
picks the project up next. [`status.md`](status.md) is the running record;
this page is the short version plus the working rules.*

## Current state

- **Engine** (`engine/`): every design E1–E14 runs through `run_spec()`
  and has passed its full validation run. Published values are still being
  transcribed by the maintainer (`TODO_PUBLISHED_VALUE` placeholders).
- **Basic tests (E1–E6)** use pwr's exact formula by default (merged in
  PR #34; Departure 9 in [`conventions.md`](conventions.md)). Spower
  simulation stays available as an option, and for Welch's t-test. The
  `basic` chunk passed on 18 October 2026 with E5's unequal-group G\*Power
  cases added (#48; `validation-log.md`).
- **App prototype** (`app/routing/`): the question tree, cards and input
  screens for every end point. E1–E8 calculate on the input screen (merged
  in #34). E9 calculates in the background with a progress bar and Cancel
  (PR #36, merged). E10–E14 (phase 5, part 2; PR #47, approved
  18 October 2026) give a rough preview of power, then the full run in
  the app (mediation power) or an R script to run at home; a required N
  goes straight to the R script
  ([`phase5-simulations.md`](phase5-simulations.md), "Decided").
- **Result screen:** an exact required N shows the power it actually
  gives (G5).
- **Seed:** a fixed default (1), shown and changeable on every screen and
  recorded in the result and its R script.

## Open PRs (end of 18 October 2026)

None open. Merged on 18 October 2026, all with the maintainer's yes
where needed:
- The new design: **#56** smallest detectable effect for E1–E6 (engine);
  **#57** the design decisions (docs); **#58** Departures 6–8 and Known
  difference 1 on the result screen; **#59** screen A (start questions,
  fixed-N route); **#60** screen C (effect-size source, "I can't justify
  an effect size", reasoning needed to save or export); **#61** screen D
  (plain reading, 80%/95% side by side, explore panel, verdict-word test).
- **#47** phase 5, part 2; **#48** E5 unequal groups in the basic chunk;
  **#50** `judgement-session.md`, `saving-projects.md`, judgement call E6;
  **#53** this handover.
- **#49** run-it-yourself guide, one-line launcher (`run_powerkit.R`),
  clean-machine CI workflow, the app's About tab, and
  `hosting-options.md` with the webR spike's results (Spower and
  SimDesign don't install in webR; the spike stays on its own branch,
  never merged).
- **#51** wave 2 engine groundwork (one-way ANOVA, R² against 0 and
  increase, one proportion, McNemar, Welch by formula); engine only, not
  yet wired into the app. All five match the maintainer's G\*Power
  screenshots; the smallest-N rule for exact tests of counts is Known
  difference 2.
- **#52** project files: "Save project" and "Open a saved project" in
  the app, and `write_project()`, `read_project()`, `reproduce_project()`
  in the engine (option (a) of `saving-projects.md`).

See [`status.md`](status.md) for the PRs open at the end of the latest
stretch. E5 is settled: the z test by default (base R for equal groups,
pwrss for unequal groups; Departure 11), validated again after the
`basic` rerun. #4 (the early 2 x 2 demo) was closed on 17 October 2026,
superseded by E7 and E8 in the routing prototype.

Merged on 17 October 2026: #35 (coverage roadmap, routing options), #36
(E9 wired), #37 (G\*Power parity), #38 (the G5/G6 decisions and the
Rubin addendum), #39 (sources checked), #40 (G\*Power screenshots for
E4, E5 and E8), #41 (E5's z test, equal groups), #42 (E5's unequal
groups by pwrss), #43 (sources the maintainer checked in full text), #44
(the basic rerun; E5 validated again; E6 G\*Power df 1), #45 (attrition:
the number to recruit) and #46 (walkthrough pictures re-rendered).

Still needed from the maintainer: the judgement session
(`judgement-session.md`); the E6 G\*Power screenshot at df 2; Dziak et al., Lakens et al. (2018), Hoenig and
Heisey and the G\*Power manual stay candidates.

## Rules

- **Priorities and process (18 October 2026):** usefulness for
  psychologists comes before validation until release, and the new
  design is built in the order in [`status.md`](status.md), "What's
  next". How to keep reviews small (recommendations on judgement
  calls, PR size, one thread per area, status as current state) is in
  `CLAUDE.md`, "Working process".
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
  and `status.md`.
- **Saving usage:** report only failures from tests and checks, and read
  full logs only when something failed.

## Where the judgement calls and decisions live

- [`judgement-session.md`](judgement-session.md): the eight open calls
  that change what users see, one page each, for the session (routing
  from screen A onwards first).
- [`judgement-calls.md`](judgement-calls.md): every open or decided
  judgement call, with options and the default now. Open ones include B12
  (N rounding), B13 (power curve), B16 (what "simulation for data that
  won't meet the assumptions" should simulate) and B17 (E9's progress
  bar); B11 waits for its source. B4 and G7–G9 were decided with the new
  design, and G4 (what the methods paragraph reports) on 18 October 2026, and B6 is partly
  decided. Open questions for the
  maintainer on phase 5 are in `phase5-simulations.md` (questions 1–4).
- [`decisions.md`](decisions.md): the maintainer's decisions, dated.
- [`conventions.md`](conventions.md): each backend's conventions and
  powerkit's departures (1–11) and known differences (1–2).
- [`phase5-simulations.md`](phase5-simulations.md): options for E10–E14 and the maintainer's decision.
- [`phase-3b-questions.md`](phase-3b-questions.md): binary X and W.
- In the app, the "For the maintainer: undecided settings" tab lists the
  placeholders from `tree.yaml`.
