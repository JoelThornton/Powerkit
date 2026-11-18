# Project status: history

*Moved here from [`status.md`](../status.md): everything up to 18 October
2026, when `status.md` became a current-state page, and at the end the
page as it stood on 30 October, 8 November and 18 November 2026. Other history is in git and
`engine/NEWS.md`. Links are relative to `docs/`.*

## Where things are

- **Project files (draft PR; waits for the maintainer's yes, 18 October
  2026).** Option (a) of `saving-projects.md` (PR #50): "Save project"
  writes one file (route, inputs, seed, result, versions) through the
  engine's `write_project()`; "Or open a saved project" on the start
  screen reopens the input screen with the same values, and checking
  them reproduces the same result (tested for E2 and E7 in the app, and
  in the engine for exact, sensitivity and simulated results).

- **Run it yourself, and the About tab (draft PR; waits for the
  maintainer's yes, 18 October 2026).** [`run-it-yourself.md`](../run-it-yourself.md)
  takes a psychologist with no R or Git experience from nothing to the
  running app on Windows or macOS; `run_powerkit.R` is the one line. The
  `run-it-yourself` workflow follows the page on clean Windows and macOS
  runners and checks the app answers. The app's new "About this
  prototype" tab lists what calculates (from `forms.yaml`), how to report
  problems, and credits from each package's `citation()`.
  [`hosting-options.md`](../hosting-options.md) compares hosting, including
  a webR feasibility spike (options and measurements only): every package
  installs in webR except Spower and SimDesign; E2 ran instantly in the
  browser with the same result; E10 took 3.5 times as long as native R.

- **Wave 2 G\*Power checks (18 October 2026).** The maintainer's
  screenshots (`docs/figures/gpower/A10_*`, `A11_*`, `A23_*`, `A35_*`,
  `A37_*`) match the engine to seven decimals for one-way ANOVA, R²
  against 0, R² increase and one proportion. G\*Power's R² noncentrality
  is f² × N (pwrss's convention), and it reports N = 90 for the
  one-proportion example, as powerkit does. McNemar's post hoc power
  with G\*Power's exact option matches too (0.6742876); so does its a
  priori N (129, as powerkit). All wave 2 G\*Power checks match.

- **Wave 2 engine groundwork (draft PR; waits for the maintainer's yes,
  18 October 2026).** One-way ANOVA, R² against 0 and R² increase, one
  proportion, McNemar's test, and Welch's t-test by formula on request
  run in the engine, with example specs, exported scripts, and tests
  against the backend called directly. Not wired into the app or the
  question tree. All five match the maintainer's G\*Power screenshots.
  The smallest N for exact tests of counts is now Known difference 2 in
  `conventions.md` (it was Departure 12; maintainer's decision, 18
  October 2026). Open: one-way sensitivity.

- **Handover refreshed (18 October 2026).** [`handover.md`](../handover.md)
  lists the open PRs (#49, #51, #52, all waiting for the maintainer's
  yes), what merged today (#47, #48, #50) and what is still needed.

- **Judgement session agenda (18 October 2026).**
  [`judgement-session.md`](../judgement-session.md) gives the nine open
  calls that change what users see, one page each, ordered by impact:
  routing, effect sizes and sensitivity, alpha and tails, several
  hypotheses, the methods paragraph, hosting, G\*Power scope, naming
  other tools, and Bayesian planning. Nothing recommended.
  [`saving-projects.md`](../saving-projects.md) and judgement call E6
  compare saving projects: a project file, browser autosave, share links,
  private result links, and accounts.

- **E5 unequal groups in the `basic` validation chunk (18 October
  2026).** Two new tests check pwrss's z test against the maintainer's
  G\*Power screenshots at 1 : 2 and 1 : 3 (both directions), one tail at
  1 : 2, and a priori at 1 : 3 (70 + 210 = 280). The chunk passed on
  GitHub ([run 39081335537](https://github.com/JoelThornton/Powerkit/actions/runs/39081335537):
  23 pass, 4 published-value skips); recorded in
  [`validation-log.md`](../validation-log.md).

- **Phase 5, part 2: E10–E14 (PR #47; the maintainer said yes on 18
  October 2026).** As the maintainer decided: a rough preview (100 simulations, in
  a separate process, shown as a range with "Don't report this; run the
  full analysis"), then the full run in the app for mediation power at a
  fixed N (about 12 to 15 minutes, with a progress bar and Cancel), or an
  R script to run the full analysis on the user's computer for a
  mediation required N and for moderated mediation. One change from the
  plan, approved: a required N has no preview (at 100
  replications per sample size the search took over 15 minutes for E10
  and couldn't pin the N down), so it goes straight to the script. Background jobs are
  deferred until hosting and cost are decided. Details in
  [`phase5-simulations.md`](../phase5-simulations.md).

- **Walkthrough pictures re-rendered (17 October 2026).** All 26 pictures
  in `docs/figures/walkthroughs/` come from the current prototype (after
  #44), so E4's card shows Fisher's z and E5's says "Validated".

- **Attrition applied (17 October 2026; the maintainer said yes).** With
  an attrition rate, the result now gives the number analysed and the
  number to recruit: each group's analysed N divided by (1 − attrition),
  rounded up (64 + 64 analysed at 10% → 72 + 72 = 144 to recruit). The
  result screen adds a caveat that this common heuristic ignores how
  missing data will be handled (Mikael Rubin, 2025), and the exported R
  script works it out and checks it.

- **E5 validated again (17 October 2026).** The `basic` chunk was rerun
  on main after #42 (unequal groups by pwrss;
  [run 39073022227](https://github.com/JoelThornton/Powerkit/actions/runs/39073022227)):
  no failures, the usual 4 published-value skips. Unequal groups are
  checked against G\*Power in `test-backend-pwr.R`. As the maintainer
  asked, E5's card says "Validated" again.
- **E6 G\*Power reference (df 1).** The maintainer's screenshot (w .3,
  α .05, N 100, df 1: power 0.8508388, λ 9, critical χ² 3.8414588)
  matches pwr to 7 decimals; recorded in
  [`gpower-parity.md`](../gpower-parity.md). df 2 is still needed.
- **Sources verified by the maintainer (17 October 2026).** Rubin (2021),
  Rubin (2024), Mikael Rubin (2025) and Frane (2019) are in `refs.bib`,
  marked "Verified 2026-10-17 from full-text PDF held by the maintainer"
  (a rule the maintainer added), and marked verified in `card-sources.md`
  and `judgement-calls.md`. Dziak et al., Lakens et al. (2018), Hoenig and
  Heisey and the G\*Power manual stay candidates. `pwrss_method` and
  `stats_method` stay placeholders: neither `citation()` gives a method
  paper.
- **E5 switch to G\*Power's z test (17 October 2026; the maintainer
  said yes).** Two proportions in equal groups now use base R's
  `power.prop.test(strict = TRUE)`, which matches G\*Power to seven
  decimals; pwr's Cohen's h stays as a choice and is used for unequal
  groups for now (Departure 11 in [`conventions.md`](../conventions.md);
  reasoning in [`decisions.md`](../decisions.md)). At the maintainer's
  request, the validation test now uses G\*Power's z-test output as its
  reference (0.2344921 at 20 per group, p1 = .10, p2 = .25), recorded as
  a G\*Power value, and a separate test covers the Cohen's h option.
  E5's card says validation is in progress until the `basic` chunk is
  rerun.
- **E5 unequal groups by pwrss (draft PR; waits for the maintainer's
  yes).** pwrss's `power.z.twoprops()` replaces Cohen's h for unequal
  groups (maintainer's decision): it matches G\*Power's power at 123 and
  247 (0.9498668). pwrss moves to Imports and is credited with the other
  backends. The maintainer's G\*Power screenshots at 1 : 2 and 1 : 3 in
  both directions, one tail, and a priori at 1 : 3 all match pwrss to 7
  decimals ([`gpower-parity.md`](../gpower-parity.md), E5); they are tests.
- **`basic` chunk rerun after the E5 switch** (run 39071722512, commit
  43e8d0e): 21 pass, 4 published-value skips; recorded in
  [`validation-log.md`](../validation-log.md).
- **G\*Power screenshots checked (17 October 2026; docs only).** The
  maintainer's G\*Power 3.1.9.7 screenshots are in
  [`figures/gpower/`](../figures/gpower/) and recorded in
  [`gpower-parity.md`](../gpower-parity.md). E5: G\*Power's z test equals
  base R's `power.prop.test(strict = TRUE)` to seven decimals, so the E5
  switch can go ahead once the maintainer says yes. E8: Superpower's
  `ANOVA_exact()` reproduces G\*Power's within-between interaction
  (N 34, power 0.8070367). E4: G\*Power's default is the exact method
  below N = 10,000. Still needed: a screenshot of the contingency-table
  test for E6.
- **Sources and the G\*Power manual checked (17 October 2026; docs
  only).** With the texts the maintainer supplied, the Rubin entries (B6,
  G7–G9, `inference-question-design.md`), B11 and the roadmap now quote
  Mark Rubin (2021, 2024), Mikael Rubin (2025) and Uttley (2019) directly,
  and say where the earlier description differed (for example, Rubin's
  conditions for "any one is enough", and Mikael Rubin's wording on
  attrition). The G\*Power 3.1 manual settles most of the parity table's
  "to confirm" items and confirms E4's exact method: pwrss reproduces its
  examples. E5, E6 and E8 aren't in the manual and still need
  screenshots. Roadmap C3 corrected: attrition is asked but not yet
  applied to N.
- **The maintainer's decisions on G5, G6 and the Spower flag, and the Rubin
  addendum (17 October 2026).**
  - **Actual power at the rounded N (G5):** an exact required N now comes
    with the power it gives ("With 64 per group, power is 80.1%."); not
    shown for a simulated N.
  - **E4 keeps Fisher's z (G6):** Departure 10 in
    [`conventions.md`](../conventions.md), shown on the card and the result
    screen, with a test of its size (at most 0.004 in power, 1 in N).
  - **E5 (G6):** the maintainer wants a z test by default. Base R's
    `power.prop.test()` matches pwrss's pooled z test to 1e-16 when it
    counts both tails (`strict = TRUE`), and differs from pwr's arcsine by
    up to 0.018. The switch waits for G\*Power screenshots and the
    maintainer's yes; `power.prop.test()` handles equal groups only.
  - **Spower:** `p_r()`'s two-sided p-value when `rho != 0` is recorded in
    `decisions.md` and the roadmap, with a draft note to Phil Chalmers in
    [`upstream-questions.md`](../upstream-questions.md) (not sent).
  - **Multiple hypotheses (Rubin addendum, docs only):** B6 now uses Mark
    Rubin's individual / disjunction / conjunction framework, with Frane's
    competing view; new judgement calls G7 (a correction by default?), G8
    (alpha and tails as required inputs with a reason) and G9
    (sensitivity analysis first-class); a second candidate source for
    B11; joint-power tools in roadmap row C2; multilevel and longitudinal
    candidates; and [`inference-question-design.md`](../inference-question-design.md)
    (options only). Most sources couldn't be opened here and are marked
    "candidate (not opened)".
- **G\*Power parity and E4/E5 methods (PR #37, merged 17 October 2026; docs only).** [`gpower-parity.md`](../gpower-parity.md)
  compares E1–E14 with the matching G\*Power tests (inputs, outputs and
  the effect-size calculator). pwr's Fisher's z method for E4 differs
  from the exact method by at most 0.004 in power (1 participant at
  r = .3); its arcsine method for E5 differs from a z test by up to 0.018
  (3 per group). Three new judgement calls (G4–G6): what the methods
  paragraph reports, showing actual power at the rounded N, and the E4/E5
  method. G\*Power screenshots are needed to confirm the marked items.
- **Phase 5, part 2: E9 (interaction) calculates in the app (PR #36,
  merged 17 October 2026 with the maintainer's yes).** E9's input screen runs
  the engine in a background R process, with an estimated progress bar
  (from the usual run time: about 5 seconds for power, 80 seconds for a
  required N) and a Cancel button. Same result screen, fixed seed, R
  script and citations as E1–E8. Tests check that the background result
  equals a direct `run_spec()` call with the same spec and seed, that the
  exported script reproduces it, and that a cancelled run stops. The
  banner now says calculations are available for E1–E9. E10–E14 wait for
  the maintainer's decision on [`phase5-simulations.md`](../phase5-simulations.md).
- **Routing design options (17 October 2026; docs only).**
  [`routing-design-options.md`](../routing-design-options.md) compares the
  current question tree with a "design profile" (the same six questions
  every time, matched against a rule table), on one screen or one
  question at a time. Of 28 recorded misroutes and route conflicts, the
  current tree now prevents 15 (3 partly) and a profile with exact
  matching would likely have prevented 19 (2 partly); 7 need a further
  question in either approach. It drafts the rule table for E1–E14.
  Options and evidence only; nothing decided.
- **Coverage roadmap (17 October 2026; docs only).**
  [`coverage-roadmap.md`](../coverage-roadmap.md) is the master list of
  everything powerkit might cover: G\*Power 3.1.9.7's 49 tests, 69
  designs beyond G\*Power and 12 cross-cutting features, each with its
  end point, status, the analysis types its backend supports, and a
  candidate function found in the package's help. 15 rows are done
  (validated and wired, E1–E8) and 8 more run and are validated; 37 a
  foundation tool can do but aren't planned; 11 only G\*Power covers; 49
  of the 118 tests and designs can't be reached as themselves by the
  question tree. Three new judgement calls (G1–G3): scope for G\*Power's
  other tests, frequentist or Bayesian in the screening, and which
  cross-cutting features go into v1. ANCOVA and Fisher's exact test are
  confirmed in G\*Power's menu.
- **Phase 5, part 1: calculations in the app for E1–E8 (PR #34, merged
  17 October 2026).** The input screens for the basic tests and the 2 x 2
  ANOVAs run the engine's `run_spec()` on the checked spec and show the
  result: the number in plain English, the inputs, the backend credited by
  name, the validation status, the departures that apply, and buttons for
  the R script and citations. Tests check that each result equals a direct
  engine call with the same spec and seed, and that the exported script
  reproduces it. With the maintainer's decisions of 17 October 2026:
  - **E1–E6 use pwr's formula by default** (Departure 9; no Monte Carlo
    noise). Spower simulation stays available when the user expects their
    data won't meet the test's assumptions, and for Welch's t-test. The
    analytic path must match pwr, and the G*Power published values once
    transcribed, to 3 decimal places. The `basic` validation chunk needs
    rerunning on this code.
  - **A fixed default seed (1)**, shown and changeable on every screen,
    recorded in the result and its script (B15).
  - **Accurate banner and cards** (B14): calculations for E1–E8; other
    designs show guidance only.
  - **"Planned power, not observed power" line kept** (B11); its candidate
    source (Hoenig and Heisey) couldn't be opened here, so it isn't in
    refs.bib yet.
  - Result wording, N rounding and a power curve are still undecided
    (B11–B13); B16 asks what "simulation for data that won't meet the
    assumptions" should simulate. E9–E14 aren't wired:
    [`phase5-simulations.md`](../phase5-simulations.md) sets out the options.
- **Independent cross-checks for parallel and serial mediation (merged in
  PR #30; passed 17 October 2026).** Two validation chunks,
  `mediation_crosscheck_parallel` and `mediation_crosscheck_serial`,
  compare the joint test in power4mome and simsem. All four designs agree
  within the Monte Carlo interval with no allowance (differences 0.003 to
  0.009; [validation log](../validation-log.md)). powerkit's Monte Carlo CI
  itself has no independent check for two mediators.
- **CI installs packages from `renv.lock` (17 October 2026).** Spower 0.7
  reached CRAN on 16 October and CI picked it up, which broke the
  one-sided departure test on every PR. All workflows now restore the
  versions in `renv.lock` (Spower stayed at 0.6.4 until a separate PR,
  which waits for the maintainer, moves to 0.7). Who may merge PRs, and
  when: [decisions](../decisions.md), 17 October 2026.
- **Spower 0.7 (merged in PR #31, 17 October 2026).** `renv.lock` is on
  Spower 0.7, and one-sided basic tests use Spower's own one-sided test;
  Departure 4 is retired. Results are identical with the same seeds. The
  `basic` validation chunk passed on GitHub on Spower 0.7 (20 PASS, 4
  TODO skips; [validation log](../validation-log.md)). power4mome stays at
  0.2.1 (Departure 8 stays until its fix reaches CRAN). Known gap: nothing
  independently checks the Monte Carlo interval for two or more mediators
  ([judgement calls](../judgement-calls.md), F1).
- **Build phases 0–3 are done** ([build guide](../build-guide.md), section 8):
  the design spec format and its checks, and an engine that runs every MVP
  design through its backend package.
- **Phase 4, part 1 (merged in PR #20): script and citation exports.**
  `export_script()` writes a standalone R script that reproduces a result
  by calling Spower, Superpower, InteractionPoweR or power4mome directly,
  with a comment on each argument. A test for each runnable end point
  (E1–E14) runs the script in a fresh R session and checks it matches
  powerkit; all matched exactly. `export_citations()` gives the package's
  own `citation()`, its method paper, the supporting packages doing work
  underneath ("software used", each from its own `citation()`) and
  powerkit's citation; the repository has a `CITATION.cff`. Citations come
  only from refs.bib or a package's own `citation()`. A refs.bib entry is
  either copied from a package's `citation()` or has a DOI a session
  opened, with a dated "Verified ..." note; a test enforces this
  (17 October 2026). refs.bib has the method papers that `citation()`
  gives (Superpower, InteractionPoweR); Spower's and power4mome's method
  papers and powerkit's own citation are placeholders. The methods
  paragraph is a placeholder too.
  - **Known gaps in the script tests:** sample-size scripts for power4mome
    and InteractionPoweR have not been run (only Spower's and the exact
    2 x 2 ones); allocation ratios other than 1 and per-cell SDs have not
    been tested in exported scripts; the script tests themselves (which
    compare an exported script with powerkit) have run only on Windows,
    so multi-core runs on Linux and macOS are untested there. The
    process_7 and process_14 reruns did run power4mome on 4 cores on
    Linux.
- **Seeding fix (PR #20) and the reruns.** PROCESS model 7 and 14 results
  depended slightly on earlier calls in the session, because power4mome
  standardises models with a product term by Monte Carlo before its own
  seed takes effect. powerkit now seeds each call. process_7 and
  process_14 were rerun on GitHub on the fixed code on 17 October 2026 and
  passed, so **E13 and E14 are validated again**
  ([validation log](../validation-log.md)).
- **Validated (full validation run passed):**
  - 2 x 2 between and 2 x 2 mixed ANOVA (via Superpower);
  - basic tests (via Spower), against analytic results, direct Spower
    calls and Type I error;
  - simple, parallel and serial mediation and first- and second-stage
    moderated mediation, PROCESS models 4, 6, 7 and 14 (via power4mome;
    parallel and serial with two mediators, three or more not yet tested),
    against direct power4mome calls and Type I error;
  - regression interactions (via InteractionPoweR), against analytic
    results, direct InteractionPoweR calls and Type I error.

  The mediation and interactions chunks ran on GitHub on 15–17 October
  2026. Their published-value tests are still TODO. What "validated" means
  is defined at the top of the [validation log](../validation-log.md).
- **Independent cross-check for mediation (merged in PR #23; first run
  passed, 17 October 2026).** The direct-call tests check powerkit's
  wrapping of power4mome, not power4mome itself. The `mediation_crosscheck`
  chunk compares simple mediation with two independently written tools
  (pwrss 1.3.3, simsem 0.5-17), at two designs. All 4 tests passed
  (1 h 45 m on GitHub):
  - The sharpest check, the joint test in power4mome against simsem,
    agreed to within 0.006 and 0.0002.
  - Against pwrss's normal-theory calculations, the simulated power was
    0.005 to 0.017 lower, as expected. The provisional 0.02 allowance was
    needed once, by 0.0015.

  The allowance is decided: 0.02, for comparisons with pwrss only, at
  n >= 100 ([validation log](../validation-log.md)). Moderated,
  parallel and serial mediation have no independent cross-check yet. Why
  power4mome is used, and its established alternatives, are in
  [decisions](../decisions.md), 16 October 2026.
- **Drafts for the maintainer:** a message to Shu Fai Cheung (power4mome)
  in [`upstream-questions.md`](../upstream-questions.md) (seeding with product
  terms; multi-category X), not sent; and the statistical decisions phase
  3b needs before coding, in [`phase-3b-questions.md`](../phase-3b-questions.md)
  (options and what the backends' docs say; nothing chosen).
- **Waiting on published values:** several validation tests still have
  `TODO_PUBLISHED_VALUE` placeholders (including the G*Power published
  examples for basic tests), to be transcribed by the maintainer.
- **Upstream:** two issues found while wrapping Spower and power4mome were
  reported and fixed upstream on GitHub; powerkit keeps its workarounds
  until the fixes reach CRAN ([conventions](../conventions.md), Departures 4
  and 8).
- **Routing prototype (merged in PR #15):** a clickable Shiny prototype of
  [`decision-tree.md`](../decision-tree.md), in `app/routing/`. Routing only:
  no calculations (the input screens, added later, use the engine's
  `validate_spec()` only). It covers the three routes (I know
  my analysis; help me choose; plan my whole study), end-point cards, and
  placeholders for the undecided judgement calls, which are settings in
  `app/routing/tree.yaml`. A test keeps that file in step with
  `decision-tree.md`, and the prototype's tests run on GitHub on every
  pull request. How to run it: [`routing-prototype.md`](../routing-prototype.md).
- **User-testing kit (draft PR, 17 October 2026; builds on the input
  screens PR):**
  - [`user-testing.md`](../user-testing.md): who to recruit (a mix of
    subfields and confidence with statistics), a 20-minute session script
    (bring your own study, think aloud, try all three routes), what to
    record, and how each problem becomes a test case;
  - [`test-cases.md`](../test-cases.md): a template, with the
    segmented-regression misroute as the first entry (TC-001);
  - every card has a **Something doesn't fit?** link that shows the exact
    path taken as copyable text and asks what the user expected instead.
    Nothing is sent anywhere.
- **Input screens for the end points that run (draft PR, 17 October 2026;
  phase 5 groundwork, no maths):** each of E1–E14 has an input screen,
  reached from its card, with one field per value the card lists and the
  plain-English hints beside them.
  - Effect sizes start empty and are required (undecided setting
    `effect_size_inputs`); other settings start at the wrapped tool's
    default, each labelled with its source.
  - On submit, the screen builds a design spec and checks it with the
    engine's `validate_spec()` (read-only), showing its messages in plain
    English. Nothing is calculated: a valid spec shows "Calculation not
    wired in yet" and the spec.
  - "Copy my answers" copies the route, end point and values as text.
  - E7 (2 x 2 between) takes one SD for all cells or one per cell (17
    October 2026), as the design spec and `validate_spec()` accept; the
    fields that don't apply are hidden. E8 still takes one SD.
  - Tests for every screen; axe-core finds no violations on the screen at
    desktop and phone width. The app-tests job on GitHub now installs the
    engine, so the engine checks run there too
    ([`routing-prototype.md`](../routing-prototype.md)).
- **Judgement-calls pack and small fixes (draft PR, 16 October 2026; builds
  on the routing-decisions PR):**
  - [`judgement-calls.md`](../judgement-calls.md) collects every open
    question in one place, for the maintainer to decide in one session.
    Included:
    - `decision-tree.md`'s open questions and judgement calls;
    - the prototype's placeholder settings;
    - the routing decisions left by PRs #21 and #22;
    - the questions raised by the sourcing (E45 and PITS, the dyadic
      wording, hints whose details differ from their sources);
    - links to [`phase-3b-questions.md`](../phase-3b-questions.md).

    Each entry gives the options, what established tools or sources do,
    who might disagree and why, and the knock-on effects. Nothing is
    recommended. A test checks that every placeholder setting and open
    question has an entry;
  - question IDs ("Question Q1") are hidden from users and screen readers,
    and kept in the page source;
  - the answer chips are at least 44 x 44 px (touch targets);
  - hints now also explain terms in the standard names and backend lines
    (for example omnibus and TOST), with the same rule: meaning only, never
    a value;
  - walkthroughs re-run.
- **Routing decisions and card sourcing (draft PR, 16 October 2026):**
  - E15 (a yes/no X or W) no longer asks about reliability: misclassification
    in a 0/1 variable is a different problem from unreliable scores
    ([decisions](../decisions.md), 16 October 2026);
  - the routing audit now says test-retest answered "Twice" reaches E41
    (F11) and IRT reaches E37 (F7); E37 says IRT designs aren't covered.
    Routing unchanged;
  - every claim in [`card-sources.md`](../card-sources.md) now has a source,
    or a status saying why not. Sources were opened and read: R package
    documentation (help pages, vignettes, CRAN manuals), UCLA OARC pages
    and David Kenny's dyadic-analysis pages. Of the 53 claims that were
    unsourced or partly sourced: 34 sourced (E45's autocorrelation point
    after its rewording, below) and 19 partly sourced;
  - **contradictions, now fixed (17 October 2026):** E45 said "No ready-made
    tool", but the PITS package (on CRAN since 30 June 2026) estimates power
    for interrupted time series with a known breakpoint. E45 now says "A
    recently released package addresses the known-breakpoint case; powerkit
    hasn't checked it", without naming the package (open question 18). E7
    and E8 said "Exact (analytic)"; they now say "Exact dataset (no
    repeated simulation)", following Superpower's own help;
  - two papers supplied by the maintainer were read: Albers and Lakens
    (2018) now sources the pilot-study warning's reason; Zhang, Wagner and
    Ross-Degnan (2011) qualified E45's autocorrelation point (negative
    autocorrelation raises power). The maintainer reworded it on
    17 October 2026: "Autocorrelation makes standard power calculations
    wrong: too optimistic when it's positive, too pessimistic when it's
    negative.", sourced to their Table 1. No contradictions remain open;
  - partly sourced claims are mostly glossary hints whose details differ
    from the source (for example, fixed effects with random slopes, the
    pooled SD's weighting, autocorrelation as dependence on the previous
    measurement only); each is listed in `card-sources.md`;
  - no references were added to `engine/inst/citations/refs.bib`: the
    sources opened are package documentation and web pages, and refs.bib
    holds only entries copied from a package's own `citation()` (a test
    checks this). Papers that couldn't be opened are listed as candidates.
- **Card content and usability (merged in PR #22, 16 October 2026):**
  - each card asks only the closing questions that apply to it, with a
    table in [`decision-tree.md`](../decision-tree.md);
  - every technical term in "What you would enter" has a plain-English
    hint, collected in [`glossary.md`](../glossary.md);
  - other defensible analyses for each covered card are drafted in
    [`routing-audit.md`](../routing-audit.md), with a card note that stays off
    until decided (open question 20);
  - every factual claim on a card has its source recorded in
    [`card-sources.md`](../card-sources.md). 51 claims were unsourced at
    merge, including the 42 glossary definitions (now sourced: see the
    entry above);
  - the safety-net card lists what to write down for a statistician;
  - an accessibility pass (axe-core: no violations on ten screens at
    desktop and phone width; focus moves to each new screen). What wasn't
    checked is listed in [`routing-prototype.md`](../routing-prototype.md);
  - walkthroughs re-run, with before/after notes for every changed card.
- **Routing fixes from the walkthroughs (merged in PR #21, 16 October 2026):**
  - fixes F1–F3, F5, F9, F13 and F14 from [`walkthroughs.md`](../walkthroughs.md),
    and the wording of F10;
  - the guided route uses S3's "Twice" (paired tests; the pre-post
    question for two groups), and offers an outcome with several
    categories (E6);
  - the end-point list shows only the analyses that fit the screening
    answers;
  - factorial logistic regression reaches a new generic card, E47, in both
    routes, with the neutral tools sentence (open question 18);
  - the dyadic card's wording is corrected;
  - internal references are out of user-facing text.

  Left for the maintainer:
  - F7 and F11 (decided 16 October 2026: the audit changes, routing
    doesn't; see the entry above);
  - F12 (diary studies);
  - inter-rater designs;
  - new routing questions listed in the audit's "What's left" (items 11–13).

  Walkthroughs re-run; six entries changed end point.
- **Walkthroughs (merged in PR #19, 16 October 2026):**
  [`walkthroughs.md`](../walkthroughs.md) gives an example study for each of
  the audit's 61 entries (29 designs and the 32 UCLA OARC rows).
  - Each example was run through all three routes of the prototype, with
    a screenshot of every end card and a note on whether a reader without
    statistics training would follow it.
  - All 183 route runs reached the end points recorded for them, and a
    test keeps the recorded paths in step with the tree.
  - It flags 15 problems, without fixing them. The main ones:
    - the guided route ignores the screening's "Twice" (F1) and has no
      outcome with several categories (F2);
    - factorial logistic regression gets "use these tools" in one route
      and "no ready-made tool" in another (F3);
    - the end-point list ignores the screening (F5);
    - the dyadic card claims more than the audit supports (F9);
    - two places where the audit's description doesn't match what users
      reach (F7, F11).
- **Recognising designs powerkit doesn't cover (merged in PR #18, 16 October
  2026):** a tester's segmented regression was routed to a paired t-test,
  and on another path to a t-test.
  - [`routing-audit.md`](../routing-audit.md) traces 29 designs through all
    three routes. It found misroutes for nested, crossed,
    cluster-randomised and dyadic data, time series and segmented
    regression, time-to-event outcomes, precision planning, equivalence
    in the guided route, and SEM with latent variables.
  - Every route now starts with four screening questions (outcome,
    grouping, times measured, goal). Designs outside powerkit's scope
    leave at an honest card before any test is suggested. Every question
    offers "None of these fit / I'm not sure", which suggests a
    statistician.
  - There are new cards:
    - E45 (segmented regression and interrupted time series; no
      ready-made tool);
    - generic cards for time-to-event outcomes (E43), dyadic data (E44)
      and precision (E46);
    - the safety net (E-unsure).
  - Each fixed misroute has a test (`test-misroutes.R`).
  - The audit is cross-checked against UCLA OARC's test-selection table
    (adapted from Leeper), with one row per analysis. That found one more
    misroute, now fixed: factorial logistic regression reaches E27. It
    also found chi-square goodness-of-fit, which has no end point and is
    left for the maintainer. The table doesn't cover nested, clustered or
    time-series data, so the earlier list still applies. The list of 31
    analyses was checked against the page on 16 October 2026.
  - Three new judgement calls in [`decision-tree.md`](../decision-tree.md),
    section 3, each with its positions, the maintainer's view and the
    reason it is a judgement call:
    - 3.7: chi-square goodness-of-fit, E6 or its own card. E6 is
      independence only today;
    - 3.8: rank-based tests that reach parametric end points;
    - 3.9: Fisher's exact test that reaches the large-sample tests.

    Each is an undecided setting shown on the cards it affects.
  - Still misrouting, left for the maintainer because each needs a
    statistical judgement: curvilinear effects, reliability/ICC,
    non-parametric tests, sequential designs, MANOVA, non-baseline
    covariates and latent-variable mediation entered as mediation (audit,
    "What's left").
  - New undecided settings: the screening wording (open question 16),
    whether E45 and E35 share an end point (17), and whether "not
    covered" cards name other tools (18). Matched pairs versus dyads is
    open question 19.
- **App:** a prototype Shiny app for the 2 x 2 designs is in a draft PR
  (#4). It stays an open draft, kept as a starting point for phase 5
  ([decisions](../decisions.md), 15 October 2026). The `validate_spec()` bug
  it reported (a null SD crashed with "non-character argument") is fixed.
- **Goal and coverage:** the maintainer's goal is stated in the
  [build guide](../build-guide.md) overview. [`coverage.md`](../coverage.md)
  lists every user-facing capability of Superpower, Spower, power4mome,
  InteractionPoweR and G*Power, with powerkit's status and proposed tiers.
  The tiers are for the maintainer to confirm, and the G*Power rows still
  need checking against the G*Power manual.
  A section on needs the five tools don't cover (crossed participants and
  stimuli, multilevel, longitudinal, SEM, sequential and Bayesian designs,
  equivalence, precision, bias-corrected and replication planning, several
  outcomes, ordinal outcomes) lists candidate tools for each, checked
  against their own package sources.
- **Decision tree (draft):** [`decision-tree.md`](../decision-tree.md) is a
  draft spec of how an app user gets from their study to a power analysis,
  for phase 5. It covers how G*Power, Superpower, Spower, power4mome,
  InteractionPoweR and PAMLj route users; a question tree mapped to the
  spec schema, with end points E1 to E42; the judgement calls where
  methodologists disagree, left undecided; and open questions. All of it
  is a proposal for the maintainer to confirm. It builds on
  [`design-finder.md`](../design-finder.md), whose status labels are now up
  to date. The flowcharts, including a single full chart for
  presentations, are rendered in
  [`figures/decision-tree/`](../figures/decision-tree/).
  Section 4 proposes how to handle studies with several hypotheses: an
  optional guided "plan my whole study" route (variables defined once,
  one card per analysis, the combined N for the primary analyses, and
  warnings when effect sizes contradict each other), two approaches to
  consistency (per hypothesis, or whole-study simulation) left
  undecided, and a worked example.
- **Coverage:** [`coverage.md`](../coverage.md) now also has rows for ANCOVA
  (including pre–post), covariates in mediation, mediation with a
  multi-category X, moderation with a 3+ group X or W, and several
  hypotheses in one study.
- **Validation on GitHub:** the `full-validation` workflow works: after a
  setup fix (PR #11), the basic chunk passed there on 15 October 2026
  (20 PASS, 4 SKIP for TODO published values), matching the earlier
  Windows runs ([validation log](../validation-log.md)).
- **Known risk, time limit:** process_7 and process_14 finish about 45
  minutes inside the GitHub time limit (4 h 47 m against the script's
  5 h 30 m stop). If either ever runs out of time, the fix is to split
  that chunk (for example, the direct-call and Type I error tests as
  separate chunks).
- **Memory:** mediation and moderated-mediation simulations run in batches
  of at most 200 replications, so they no longer need more memory than an
  ordinary laptop has (an unbatched 10,000-replication run did). The
  validation can also run on GitHub, one chunk at a time
  ([validation log](../validation-log.md), "Running the full validation on
  GitHub").

## What's next

1. Rerun the `basic` validation chunk on the pwr default (17 October 2026).
   Decide how E10–E14 run in the app ([`phase5-simulations.md`](../phase5-simulations.md),
   questions 1–4); then wire them.
1. The remaining published values for every design (the maintainer
   transcribes them), and validation with three or more mediators for
   parallel and serial mediation (open question 10 in
   [`decision-tree.md`](../decision-tree.md)).
2. Simulation versions of the 2 x 2 ANOVA Type I error tests (build guide,
   section 6, open items).
3. Binary X and W in regression interactions and mediation (phase 3b,
   build guide section 8). It comes next after phase 3 closes, before
   phase 4. The maintainer has decided its effect-size convention, group
   split and handling of correlated predictors. The decisions still open
   before coding are listed in [`phase-3b-questions.md`](../phase-3b-questions.md).
4. Consider independent cross-checks for parallel, serial and moderated mediation.
   Send (or edit) the draft message to Shu Fai Cheung in [`upstream-questions.md`](../upstream-questions.md).
5. Confirm the proposed tiers in [`coverage.md`](../coverage.md), and check
   its G*Power and MorePower rows against the G*Power manual and the
   MorePower paper.
6. The rest of phase 4: the methods paragraph and preregistration text;
   the method-paper and powerkit entries in `engine/inst/citations/refs.bib`
   (the maintainer adds them); and, once phase 3b lands, scripts for
   binary X and W.
7. Decide the open questions collected in [`judgement-calls.md`](../judgement-calls.md),
   including whether to name PITS on E45 (A1), and the partly sourced hints
   in [`card-sources.md`](../card-sources.md). Decide what to do about the
   remaining walkthrough flags (in
   [`walkthroughs.md`](../walkthroughs.md)), and the routing audit's open items: the screening wording and
   open questions 16–19 in [`decision-tree.md`](../decision-tree.md), and the
   remaining misroutes listed in [`routing-audit.md`](../routing-audit.md).
8. Run the first round of user testing ([`user-testing.md`](../user-testing.md))
   and log what it finds in [`test-cases.md`](../test-cases.md).
9. Phase 5: the Shiny app, starting from the routing prototype's
   `app/routing/tree.yaml` and guided by [`decision-tree.md`](../decision-tree.md)
   and [`design-finder.md`](../design-finder.md), once the maintainer has
   answered their open questions.


## status.md as it stood on 30 October 2026 (0.24.0)

Replaced on 31 October 2026 by a shorter page of the current state; kept
here whole, with its item numbers for next.md as they were then (several
had gone stale).

powerkit is in development and **not ready for use**: results are not yet
fully validated. Validation runs are recorded in
[`validation-log.md`](validation-log.md). For the working rules, see
[`handover.md`](handover.md) and `CLAUDE.md`.

### Where things are

- **Engine** (`engine/`): designs E1–E14 run through `run_spec()`. Their
  validation so far is mostly agreement with the package each one calls,
  plus Type I error; independent checks exist for the basic tests (the
  maintainer's G\*Power screenshots) and simple, parallel and serial
  mediation (pwrss and simsem). Published values (27 October 2026): 17
  published examples are transcribed in full and pass locally (the
  independent and paired t-tests, both dependent-correlation tests, the
  three planned contrasts, the four generic tests, logistic regression
  with a normal and with a yes/no predictor, the Poisson swimmers example and the three
  variance tests). Two InteractionPoweR tutorial examples are complete
  and run in the interactions chunk. The rest keep
  `TODO_PUBLISHED_VALUE` placeholders, partly filled where a value is
  still to be checked. Six cards are now marked validated on the
  strength of these runs (planned contrasts, logistic regression, the
  generic tests, two dependent correlations and the two variance tests);
  eight still say "validation in progress" (`next.md`, item 15). Wave 2 (one-way
  ANOVA, R², one proportion, McNemar, Welch by formula) matches G\*Power
  in the engine's tests; it isn't in the full validation run yet.
- **Batch 1: designs the engine computes, being wired into the app**
  ([`next.md`](next.md), batch 1; version 0.6.0). Each runs by
  formula through pwrss unless stated, has validation placeholders for the
  G\*Power manual's examples, and reaches the app in its own PR:
  - **Logistic regression** (E27; pwrss's Wald z test of one predictor, a
    score or a yes/no group, with other predictors through an R-squared):
    **in the app** (26 October 2026). Above an R-squared of 0 the result
    screen states Known difference 3, which G\*Power itself has to settle.
  - **Poisson regression** (E28; one predictor of a count outcome, over a
    mean exposure): card and input screen **in review** (26 October 2026).
    It reproduces every number in the manual's section 30 that powerkit
    can compute. Count outcomes now pass the screening questions first:
    only a count measured once per person reaches it.
  - **Planned comparisons (contrasts)** (E19; pwrss's t test of a weighted
    combination of one factor's means, trend tests included): card and
    input screen **in review** (26 October 2026). Superpower's emmeans
    route agrees with it (a unit test).
  - **Two dependent correlations** (one group, with or without a shared
    variable; pwrss's Steiger test, unpooled as G\*Power, Departure 12):
    their own card (E51) and input screen **in review** (26 October 2026).
  - **The two variance tests** (one group's variance against a value, two
    groups' variances; simulated with Spower's `p_var.test()`, Known
    difference 4; an allocation ratio is refused while Spower can't draw
    unequal groups, [`upstream-questions.md`](upstream-questions.md)):
    their own cards (E52, E53), input screens and a design-finder
    question ("Whose spread of scores are you comparing?") **in review**
    (26 October 2026).
- **More tests by formula already in the app** (pwrss): Fisher's exact
  test (E5's test version), ANCOVA with one factor or, from 0.17.0
  (28 October 2026), two crossed factors (E23), chi-square goodness of
  fit (E48, its own card), two independent correlations (E49) and the
  generic t, F, chi-square and z tests (E50, only from "I know my
  analysis"; no sample size). pwrss's search for the noncentrality is
  wrong for a t test with few degrees of freedom (3 to about 12); the
  engine checks the answer and refuses a wrong one.
- **G\*Power manual checks:** two independent correlations (A6, section
  27) and the generic t test (A47, section 25) reproduce the manual. The
  G\*Power entries in [`conventions.md`](conventions.md) are filled in for
  the manual's sections 3 to 6, 10, 11, 13, 14 and 19 to 21; the manual has
  no section on repeated-measures ANOVA, the two-proportions z test, the
  chi-square test of independence, ANCOVA or mediation, so those need
  G\*Power itself. Next there: the pwrss column, from the installed
  sources.
- **Clustered designs (27 October 2026, 0.12.0):** cluster-randomised
  trials (whole groups assigned to two conditions) and multisite trials
  (people randomised within each group), with a score outcome
  (powertools' `crt.parallel.cont()` and `multisite.cont()`, with the
  design effect and the effective sample size on the result screen) or,
  from 0.16.0 (28 October 2026), a yes/no outcome (`crt.parallel.bin()`
  and `multisite.bin()`, groups of equal size, no smallest detectable
  effect), all by formula on the "People nested in groups" card (E34).
  Also in 0.16.0, group treatment trials (people randomised one by one,
  only one condition delivered in groups: powertools' `irgtt.cont()` and
  `irgtt.bin()`; the smallest detectable d is found from the t-based
  power, not powertools' normal approximation, `conventions.md`), and an
  optional baseline score (one covariate) for a score outcome in the
  first two designs. Validation in progress (published examples to
  choose and transcribe); three questions for powertools in
  `upstream-questions.md`. Next: simulated multilevel models wait for a
  package decision (`next.md`, item 5).
- **Structural equation models (27 to 29 October 2026, 0.13.0 and
  0.21.0):** on the latent variables card (E37), by formula with
  semPower: model fit (the chi-square test of exact fit by RMSEA, for a
  CFA described by its items and factors or any model by its df) and,
  from 0.21.0, measurement invariance of one factor across two groups
  (metric or scalar, `semPower.powerMI()`; over two occasions from
  0.22.0, `semPower.powerLI()`), the correlation between two
  factors (`semPower.powerCFA()`) and a latent slope
  (`semPower.powerRegression()`), each by the chi-square difference test.
  Validation in progress (published examples to choose and transcribe).
  Not yet: invariance with several factors, groups or occasions, and the
  test of close fit (left out for now, 29 October 2026).
- **Repeated measures and larger factorial designs (27 to 28 October
  2026, 0.14.0 to 0.19.0):** the one-way repeated-measures ANOVA (the same
  people in three or more conditions, E54), the mixed ANOVA beyond 2 x 2
  (groups of different people each measured at three or more timepoints
  or in several conditions, E55), the two-factor within-participants
  ANOVA (everyone in every combination, 2 x 2 or larger, E20) and the
  two-factor between-participants ANOVA beyond 2 x 2 (E21) and, from
  0.19.0, the three-factor ANOVA with any mix of between and within
  factors (E56) run in the app by Superpower's exact data set, with one SD and, for repeated measures,
  one correlation, so sphericity holds; from 0.21.0 the MANOVA approach's
  power (Pillai's trace, no sphericity assumed) is shown beside the
  univariate F when the effect involves a within factor with three or
  more levels. Validation in progress (published examples to choose and
  transcribe). Next: sphericity corrections and unequal SDs or
  correlations (`next.md`, item 17); four or more factors go to the safety
  net. Welch's F (unequal SDs) is a test version on the one-way ANOVA
  card from 0.21.0, simulated with Spower.
- **Rank correlations and the Pitman-Morgan test (29 October 2026,
  0.22.0):** Spearman's rho and Kendall's tau are a test version on the
  correlation card (Spower's `p_r(method =)`, normal scores), and the
  Pitman-Morgan test of two paired variances has its own card (E57),
  simulated with Spower's `p_r()` on the sum and difference of the paired
  scores. Validation in progress.
- **Three-way interactions, and moderated mediation with two mediators (29 October 2026, 0.23.0):** the three-way
  interaction card (E31) calculates, by InteractionPoweR's analytic
  `power_interaction_3way_r2()` with reliabilities (predictors treated as
  fixed; there is no three-way simulation). Validation in progress.
  Moderated mediation with two parallel mediators (E40, models 7 and 14,
  the index through a chosen mediator) runs on power4mome, with a preview
  and an R script. PROCESS model 8 is blocked by an upstream question to
  manymome, and models 58 and 59 need a decision on what to power
  (`next.md`, item 12).
- **Ordinal outcomes and factorial logistic regression (29 October 2026,
  0.23.0):** two groups compared on ordered categories (E29), by
  powertools' `propodds()`, which matches Hmisc's `popower()`; and two
  crossed factors with a yes/no outcome (E47), simulated with Spower's
  `p_glm()`. Validation in progress.
- **MANOVA (30 October 2026, 0.24.0):** E59, two or more groups compared
  on several outcomes at once (Pillai's trace; Hotelling's T-squared with
  two groups), reached from F2. Simulated with Spower and powerkit's
  `p_manova()` experiment; matches the exact two-group answer (pwrss) and
  a separate simulation, and holds alpha. G\*Power values to transcribe
  (Known difference 8). Validation in progress.
- **Latent profile and latent class analysis (30 October 2026, 0.24.0):**
  a guidance card (E58), reached from Q1's "That people fall into
  distinct types or profiles". No package computes this power, so the
  card gives the published simulation results (Tein, Coxe and Cham,
  2013; Nylund, Asparouhov and Muthén, 2007), the usual working range
  (Nylund-Gibson and Choi, 2018; Spurk et al., 2020) and how to simulate
  one's own model; sources in `card-sources.md` and `refs.bib`.
- **A study plan any card can join (30 October 2026, 0.24.0):** after a
  result, "Add this to my study plan" keeps the analysis in one plan for
  the session; the plan screen lists each analysis, names the largest
  sample size counted in people (cluster trials apart), says that joint
  power isn't calculated, and saves and opens one file (the engine's
  `write_study_plan()` and `read_study_plan()`). "Add another analysis"
  starts "Help me choose". When every analysis compares the same
  randomised groups on different outcomes (independent t-tests, or
  cluster-randomised trials), the plan asks for the outcomes' correlation
  and gives the chance that all are significant, with PUMP's
  `pump_power()` (the engine's `joint_power()`); other plans keep the
  note. Plans that mix designs are `next.md`, item 1.
- **Mixed models, first design (30 October 2026, 0.23.0):** E33
  (participants responding to many items in two conditions) calculates
  with simr and lmerTest's Satterthwaite test (Departure 16); the required
  number of participants comes from the R script. Its inputs show example
  values from Brysbaert and Stevens (2018, Table 2), a masked-priming
  response-time study (0.24.0). Validation in progress. More models need
  decisions (`next.md`, item 3).
- **Mediation with a yes/no X (29 October 2026, 0.23.0):** E16 (one
  mediator) calculates with power4mome's `rbinary_rs()`, the group split an
  input, showing the group difference in M the path implies; the parallel
  and serial screens take a yes/no X too. Validation in progress. Next:
  E17, waiting on a power4mome question (`next.md`, item 14).
- **Moderation with a yes/no X or W (29 October 2026, 0.23.0):** E15
  calculates with InteractionPoweR (`k.x1` or `k.x2 = 2`, groups 50/50),
  showing the group difference the correlation implies; reliability for
  the score and outcome only. Validation in progress (published example
  to choose).
- **Unequal group sizes in a 2 x 2 between ANOVA (29 October 2026,
  0.23.0):** E22 calculates, simulated with Superpower's `ANOVA_power()`
  and one n per cell (`options > cell_ratio`), checked against pwrss's
  Shieh formula with a null covariate (decision N3). A mixed design with
  unequal groups reaches the safety net (`next.md`, item 17).
- **Technical details (29 October 2026, 0.23.0):** a folded section
  under "How it was calculated" gives the test's df, critical value and
  noncentrality, read from pwrss (and through pwrss for pwr's t-tests,
  two proportions and chi-square) and from Superpower's exact ANOVAs; a
  simulated required n now shows the power reached there with its
  interval. Other backends and the critical effect size: `next.md`,
  item 24.
- **Simulated data sets (29 October 2026, 0.22.0):** a CSV of one
  sample of the planned size, drawn from the population entered by the
  backend's own generator, downloadable from the results screen and
  rebuilt by a section at the end of the R script (`simulated_data()`).
  For writing analysis code before the data arrive; marked as simulated
  in its first column and its file name. The basic tests (not McNemar's),
  the rank tests, equivalence and non-inferiority, the Superpower ANOVA
  designs, Welch's ANOVA, planned contrasts, regression interactions,
  mediation, one-predictor logistic and Poisson regression, factorial
  logistic regression, ordinal outcomes and cluster trials with a score
  outcome (0.23.0 added the rank tests onwards); the rest need data
  choices (`next.md`, item 11).
- **Rank tests (28 October 2026, 0.18.0):** the Wilcoxon signed-rank
  test (one sample, or pairs), the Mann-Whitney test and the
  Kruskal-Wallis test are a test version on the one-sample, paired,
  two-group and one-way ANOVA cards, simulated with Spower for the shape
  of scores the user expects (normal, skewed or heavy-tailed; the
  signed-rank test, which assumes symmetry, offers normal and
  heavy-tailed). Known difference 5: G\*Power adjusts the t-test by an
  efficiency factor instead; its values are still to transcribe
  (`test-validation-rank-tests.R`). Friedman's test still carries the
  "only approximates" note (`next.md`, item 19).
- **Bayes factor t-tests (28 October 2026, 0.20.0):** the one-sample,
  paired and two-group t-test cards offer a Bayes factor t-test as a test
  version, by bfpwr's closed form (Pawel & Held, 2025): the chance the
  Bayes factor passes a threshold (BF10 = 10 by default, Cauchy prior
  scale 0.707), and, with no effect, the chance of strong evidence for
  none and of misleading evidence. Fixed N, equal groups. Awaiting the
  maintainer: Departure 15 (plan for exactly the effect entered, not
  bfpwr's spread-out default). Known difference 6: bfpwr is slightly low
  in small samples. Sequential designs (BFDA) and other designs later.
- **Housekeeping (29 October 2026, 0.20.1):** the README, the package
  description and `CITATION.cff` name every backend and design family
  that runs; `_dependencies.R` declares every package the engine imports
  (a test now checks it); the app says how to get the engine when it is
  missing; names of variables and levels are optional, with neutral
  defaults. No change to any result.
- **Safeguard power (27 October 2026, 0.9.0):** for an effect size from
  one previous study or pilot, the one-sample, paired and independent
  t-tests and the correlation can plan with the lower bound of a 60% (or
  90%) confidence interval around it, worked out by psych (Perugini,
  Gallucci & Costantini, 2014). Not yet for other designs.
- **Effect-size conversion (30 October 2026, 0.24.0):** the same four
  cards take an effect as published (a t statistic, an F with one
  numerator df, r, d or an odds ratio), converted with effectsize and
  recorded in the spec; the result and the write-up say what was
  converted and how. Between-participants ANOVA (one-way, 2 x 2 and
  larger factorial designs) can also be given by the partial eta-squared
  of the effect tested, as G*Power takes it, or a published F(df1, df2)
  or f converted into it; pwrss's `power.f.ancova()` computes power.
  Repeated-measures and mixed ANOVA with one within factor take it too
  (`power.f.mixed.anova()`), with a required question on which kind of
  partial eta-squared it is: as a published ANOVA reports it, or planned
  the G*Power way with the correlation given separately. The moderation
  card also takes the R-squared the interaction adds, through pwrss's
  fixed-model test (Known difference 7 states how it compares with
  InteractionPoweR).
- **Equivalence tests (27 and 29 October 2026, 0.10.0 and 0.21.0):** the
  two one-sided tests (TOST) for two groups, paired data and one sample
  run in the app through TOSTER's exact `power_t_TOST()` (E36), with the
  bound and the expected difference as Cohen's d or in the measure's own
  units; from 0.21.0 also a correlation (`power_z_cor()`) and two
  proportions (`power_twoprop()`, equal groups); from 0.22.0
  non-inferiority for two groups, paired data, one sample and two
  proportions (pwrss's one-sided tests against a margin). Validation in
  progress: published examples are placeholders.
- **Whole-study simulation (27 October 2026, 0.10.0, experimental):** on
  the guided plan, one population model for the whole study, entered
  once as standardised paths; every planned analysis (correlation,
  interaction, mediation with one or two mediators, moderated mediation)
  is run on the same power4mome simulations, giving each analysis's power
  and the joint power for the claim, and the values each analysis's own
  screen would need (Departure 13). The app runs a quick look (200
  simulated studies); the full run and the sample size search (0.11.0)
  run on the user's computer from an R script
  (`export_whole_study_script()`). Waiting for a
  statistician's check (`next.md`, item 13); the method note for it is
  `docs/whole-study-method.md`. Since 0.10.1 it is the plan's first
  step when it covers the plan, with the separate calculations folded
  below. Next: a quick run in the app, an R script for the full run, and
  a search for the sample size.
- **App** (`app/routing/`): the question tree, cards and input screens for
  every end point. E1–E9, one-way ANOVA (E18), one-way repeated measures (E54), mixed designs beyond 2 x 2 (E55), two-factor within and larger between designs (E20, E21), ANCOVA (E23), multiple
  regression (E24), one proportion (E25), McNemar (E26), goodness of fit
  (E48), two correlations (E49), the generic tests (E50) and
  clustered designs (E34) and model fit for CFA and SEM (E37) calculate in
  the app; E10–E14 give a rough preview, then a full run in the app or an
  R script. Results save as a project file and reopen. It is online at
  <https://joelthornton-powerkit.share.connect.posit.cloud> and updates
  itself from main; [`run-it-yourself.md`](run-it-yourself.md) is for
  running it on one's own computer. Each tab has its own link
  (`?page=labs` and so on); Connect Cloud's frame keeps the address bar
  from showing it, so the top bar has a "Share this page" button. What the app
  now does, all merged:
  - larger text on large screens with no sideways scrolling when zoomed,
    the page moving to the result after "Check my answers", and a result
    screen ordered answer, exploring, save and share, then how it was
    calculated, with a shorter write-up for the paper;
  - the input screen in sections (goal first, fields only for the goals
    that need them, default settings folded into one line), four progress
    steps, shorter cards and labels, and problems shown next to their
    fields;
  - the direction asked first and not pre-filled; a claim needing several
    tests raises each one's target power; changing alpha or choosing a
    one-sided test asks for a reason, which goes into the write-up;
  - help with the effect size (honest routes to a defensible number and an
    "I don't know" button; entering the difference in raw units is
    queued in [`next.md`](next.md));
  - "I know my analysis" can skip the four screening questions and show
    every end point, as G\*Power's menu does, with the questions offered as
    a filter ([`decisions.md`](decisions.md), 26 October 2026);
  - the first screen asks only how to start; whether the sample size is
    fixed and how the conclusion rests on several tests are asked on the
    input screen (26 October 2026);
  - browser Back and Forward move between screens;
  - a card-based layout: Back and Start again at the top of each screen,
    the next step pinned to the bottom of the window, choices and results
    as cards (26 October 2026);
  - About and "What's new" tabs (`app/routing/whats-new.yaml`); a Feedback
    tab whose Send button stores the message in the `powerkit_feedback`
    table of the goal-machine Supabase project (read it in Supabase's table
    editor), with a GitHub issue and copying as alternatives; undecided settings only in the maintainer's
    view (`?view=maintainer`);
  - in "Plan my whole study", each analysis on the plan that powerkit
    calculates opens its input screen, carrying the plan's claim and its
    number of main analyses; the combined sample size and the consistency
    check between analyses are still "Coming soon" and queued in
    [`next.md`](next.md);
  - Labs (experimental): a list of tools, and pre-replication notes that
    can feed a plan without losing work;
  - at most two long calculations at once across all visitors
    (`forms.yaml`, `background_limit`), and the shared tabs built once at
    start-up.
- **Decisions recorded 22 October 2026:** eleven settings that were marked
  undecided but already built now record their value; four more change the
  app: observed power allowed with a warning (spec type
  `own_study_result`), the rank-test label, named tools on "not covered"
  cards, and two parallel mediators only ([`decisions.md`](decisions.md)).
- **Candidates recorded (25 October 2026):** powerMediation for B14,
  semPower for B17 and DescTools for B27's test, all **not checked**
  against their own help files (CRAN wasn't reachable when they were
  recorded); nothing is built on them.
- **CI (26 October 2026):** the test workflows run in a prebuilt image
  with R and the locked packages installed (rebuilt only when `renv.lock`
  changes), and set `NOT_CRAN` themselves, so the app's calculation tests
  run in CI ([`decisions.md`](decisions.md)).
- **Whole-study plan (26 October 2026, 0.7.0):** the plan gives the
  combined sample size (the largest N among the main analyses, named,
  from the calculations made from the plan) and asks for shared values
  once: an input two analyses both ask for fills the second's input
  screen. Whole-study simulation is queued ([`next.md`](next.md), item 13)
  and needs a statistician's check.
- **Effect in the measure's own units (27 October 2026, 0.8.0):** the
  three t-tests take the means and SD instead of Cohen's d (or d_z); the
  engine works out the standardised effect, the result and write-up show
  it, and a smallest detectable effect is also given in the measure's
  units.
- **Three effects side by side (27 October 2026, 0.9.0):** on the
  result screen for the t-tests and the correlation, a conservative and an
  optimistic effect the user enters are drawn with the plan's effect, with
  the N each needs.
- **Labs: plan from a published result (30 October 2026, 0.24.0):** an
  effect as a paper reported it, shown as the effect size a card uses
  (`convert_effect()`) and as a safeguard value (`safeguard_effect()`, the
  t-tests and the correlation), with a note that published effects run
  high.
- **Labs map of the methods (27 October 2026, 0.9.0):** an interactive
  "cosmos" (stars for research questions, planets for analyses) generated from the design finder's questions (Cytoscape.js,
  bundled), with filters, search, two views and each analysis's
  card. Charts on each analysis's page and a
  sourced reading list are not built yet.
- **Repository checks:** `test-repo-consistency.R` holds the docs, scripts
  and workflows together: every validation file in a chunk of
  run-validation.R with a time estimate and a place in the full-validation
  workflow, every test conventions.md names existing, coverage-roadmap.md's
  summary counts matching its rows and its wired statuses matching
  forms.yaml, the version agreeing across `engine/DESCRIPTION`,
  `CITATION.cff` and the About page, and every engine template named by a
  card or listed in forms.yaml's `engine_only`.
- **How tests get added:** [`adding-a-test.md`](adding-a-test.md) is the one
  page: what "added" means (engine, validation placeholders, card, input
  screen, "What's new" entry, version bump, status, in one PR), how a
  backend package is chosen with the maintainer, and every file a design
  touches. powerkit's version is `engine/DESCRIPTION`'s, major.minor.patch:
  fixes raise the last number, each batch of features the middle one (by
  one, however many pull requests), a big shift the first.
- **Scheduled validation:** on GitHub, every night that the engine
  changed in the last day, the short validation chunks and the long chunks
  whose tests or backend changed; every Sunday, every chunk
  (`scripts/validation-plan.R`, `nightly-validation.yaml`, each chunk as its
  own `full-validation.yaml` job, each within GitHub's six-hour limit;
  the yes/no-X mediation tests are their own chunk, `process_4_binary`).
  A pull request runs its own design's chunk before merging.
- **CI time:** the engine's test files run in parallel, four at a time
  (37 minutes on one core, under 10 on four; the longest are the tests
  that run an exported script against powerkit, and the whole-study
  sample-size search). App tests run once per pull request push (not also on the
  branch push), a newer push cancels the run it replaces, and the
  Windows and macOS install test runs only when the launcher, the app's
  start-up file, the lockfile or its instructions change (and weekly).
- **R in cloud sessions:** `scripts/setup-cloud-session.sh`, run as the
  cloud environment's setup script, copies R and every locked package out
  of the CI image (about a minute; the environment then caches it) when
  the network allows `pkg-containers.githubusercontent.com`. Otherwise it
  exits without installing, and a session builds R 4.3 from source with
  `--build-from-source` (20-30 minutes, too long for a setup script).
- **Open PRs:** GitHub is the list; this page doesn't duplicate it.
  What to work on is [`next.md`](next.md).

### Priorities (the maintainer, 18 October 2026)

- **Usefulness before validation.** powerkit won't be released for a
  while. What matters now is that it is useful, logical and helpful for
  psychologists and solves the problems they have with power analysis.
  Validation and checks come afterwards, before release.
- **The new design** (approved 18 October 2026): four screens (start
  questions, design finder, inputs centred on the effect size, result
  with a plain reading and write-up). The decisions are in
  [`decisions.md`](decisions.md), "The new design". Screens A, C and D
  and the departures on the result screen were merged on 18 October 2026;
  the write-up was merged the same day. The plain reading counts out of
  100 unless the power is a whole number of tenths (0.14.1), so 95% is
  never shown as "10 in 10". Analyses are named by their standard names,
  not PROCESS model numbers, in the list and the methods paragraph.
  Screens trimmed (0.14.2): the goal of showing there's no meaningful
  effect is asked once, on the aim screen; repeated wording is gone from
  cards and input screens; G\*Power is named only where its answer
  differs, with departures that don't change the answer folded under
  "How it was calculated" (`decisions.md`, 28 October 2026).

### What's next

**The ordered queue is [`next.md`](next.md)** — 27 items. The maintainer's
order for the next work (30 October 2026): every card taking the effect
size researchers have, joint power for study plans that mix designs,
MANOVA follow-ups, more multilevel
models starting with E41, Bayes factors beyond the t-tests, justified
alpha, then precision
planning and the number of items for E33, meta-analysis, and an
interactive picture of power for Labs. Every card the app marks "not in
powerkit" has an item, and the queue was checked against a list of the
tests psychologists most often report (items 26 to 29). What follows is
the direction those items serve.


In priority order (agreed direction, 18 October 2026: a working web app
first; 19 October 2026: optional features that help testing can come in
any time, and user testing is the maintainer's to run):

1. The write-up (short and full methods paragraph): merged on 18 October
   2026.
2. A working web app: **online since 18 October 2026** at
   <https://joelthornton-powerkit.share.connect.posit.cloud> (Posit Connect Cloud; the version on main).
   It updates itself: Connect Cloud publishes from GitHub on each merge
   (set up by the maintainer, 18 October 2026), using
   `app/routing/manifest.json` (kept current by a workflow). Fallback:
   `scripts/deploy-online.R`. A new app process now shows its first page
   in about 2 seconds instead of about 4.5 (measured on a cloud machine;
   0.16.1); hosting stays on Connect Cloud for now (browser-only hosting is ruled out: several backends have no WebAssembly build).
   Running it on your own computer: the Mac
   route broke on 19 October 2026 when CRAN replaced a locked package
   (RcppArmadillo); the lockfile now has the new version.
3. Fill the core gaps: the "does this still apply?" flag on the
   effect-size source is merged (19 October 2026), and so is the smallest
   detectable effect with no effect size for two proportions and
   chi-square; the smallest detectable effect for regression
   interactions (by the fast fixed-model formula, labelled) is merged too.
4. User testing with the online link, run by the maintainer: the plan
   ([`user-testing.md`](user-testing.md)) is ready for the four screens.
5. The maintainer's judgement session
   ([`judgement-session.md`](judgement-session.md); routing from screen A
   onwards first).
6. Optional features (any time; those that help testing first): "guess first" (merged 19 October 2026),
   a plain-words version of the write-up for ethics applications (merged 19
   October 2026), a plan checker for supervisors and reviewers (merged 19
   October 2026), and a "Labs (experimental)" tab whose first tool,
   pre-replication notes (Karhulahti et al., 2025), is merged (plan:
   the "Powerkit Labs: plan" Claude Doc). Later Labs tools, such as the
   design-upgrade comparator, wait for a statistician.
7. More tests by formula from the packages powerkit already uses (the
   maintainer's direction, 18 October 2026): the last five are batch 1
   above. Left for later:
   Wilcoxon and other rank tests (need a statistician's view).
   Validation later.
8. Before release: published values, independent
   checks for moderated mediation and the Monte Carlo interval with two or
   more mediators, phase 3b (binary X and W), and the methodologist
   collaboration.

## status.md as it stood on 8 November 2026 (0.43.0)

*Replaced that day by a page of one short paragraph per area. Links are relative to `docs/`.*

### Where things are

- **Whole-project review (7 November 2026):** numbers, methods, the app
  working and its speed, a researcher's view, the repository and process,
  whole-study planning, and look and feel with Labs. No wrong number was
  found and nothing critical; 21 serious problems (misleading wording in
  write-ups, design-finder dead ends, the app freezing for everyone during
  long calculations, scheduled validation failing unnoticed) and about 110
  smaller ones are grouped into fix batches at the top of
  [`next.md`](next.md), with the maintainer's decisions folded in.
  The first batch (validation runs that finish and report) is done: tests
  are dealt to parts by recorded time, the whole-study chunk runs on four
  cores per test, each scheduled run ends with one list of the tests that
  need attention, and documentation-only pull requests run only the app
  tests that read the docs. The second batch (what the app says) is done:
  methods paragraphs keep to methods and name powerkit as a prototype,
  the planning document has a worded "Validation evidence" section, the
  whole-study paragraph states its population, every author-year
  reference in user text is in `refs.bib` or a package's citation() (a
  test checks), and "validated" has the validation log's meaning
  everywhere. The third batch (design-finder routes) is done: no
  question with one answer, ANCOVA recommended for randomised
  before/after trials, moderation in a before/after trial routed to the
  regression card, goals the chosen test can't answer hidden, search
  words researchers type, and crossover guidance on the paired and mixed
  cards (a crossover card is queued). The fourth batch (draft box and
  page structure) is done: the unfinished-draft offer sits on the plan
  tab only and deletes nothing unless asked, phones show every tab, and
  About is shorter. The fifth batch (effect-size guidance) is done:
  safeguard results name the effect used, pilots are treated like a
  previous study, and the Labs converter refuses impossible values. The
  sixth batch (speed) is done: sample-size searches run in a warm spare
  process rather than the app's own, About is built in a separate
  process, and the fixed tabs are rendered once. The seventh batch
  (whole-study planning) is done: a manipulation check beside a
  mediation, "baseline" in a before/after trial, the experiment script's
  printing and saving, the variables' names, saving and reopening the
  plan, a rough power curve, Cohen's d for two groups, one study plan,
  shared sample sizes across cards and the plan screens' look. The
  eighth batch (input screens) is done: target power empty everywhere
  with 80/90/95% compared, test versions in view, moderation starting at
  the R-squared change, measured run times and plainer messages. The
  ninth batch (Labs) is done: one chart style for Labs and the result
  page, the visualiser's cut-off curves explained, the methods map's
  colours and shapes, one frame per tool, links from results to the
  teaching tools, Bayesian planning and the converter on the cards'
  engine code and wording, and "Not sure of the effect?" on Bayes factor
  t-test results. The tenth batch (docs and start-up reading) is next. The mixed-design Greenhouse-Geisser check
  still fails with new seeds and waits for the statistician; the rerun of
  the moderated mediation Type I error check (yes/no X) is recorded when
  it finishes ([`validation-log.md`](validation-log.md), 7 November 2026).

- **Releases (7 November 2026):** each finished version is tagged
  (`v0.34.1`) and published as a pre-release on GitHub with its NEWS
  section, automatically once main moves on to the next number
  (`scripts/tag-releases.sh`, pushing with the `RELEASE_TOKEN` secret).
  Main requires a pull request with passing
  checks, and release tags can't be moved or deleted
  ([`repository-protection.md`](repository-protection.md)).

- **Whole study in one go: experiments (6 November 2026, experimental):**
  the guided plan simulates a factorial experiment (a condition with two
  or more groups crossed with a moderator's groups, or two conditions
  within participants crossed with groups) as one ANOVA, every F test
  read from the same simulated studies with Superpower, so the chance
  that both the main effect and the interaction succeed is counted, not
  assumed. Still card by card: three or more conditions per person,
  three factors, yes/no and count outcomes, nested data, three or more
  waves (`next.md` item 1).
- **Interrupted time series (E45, 6 November 2026):** calculates, by
  PITS's simulated series fitted with gls() by REML (PITS's own
  maximum-likelihood test as an option), with the Type I error at the
  planned length shown beside the power; validated against a separately
  written simulation and PITS's calculate_power().
- **Cross-lagged panel models (E74, 6 November 2026):** power for a lagged
  effect in a random-intercept cross-lagged panel model, by Spower around
  powRICLPM, with a preview, a full run and an R script; validated against
  a separately written lavaan simulation. Experience sampling still waits
  for a CRAN package (`next.md` item 3).

- **Input screens, first-time-user pass (6 November 2026):** the commonest
  cards were walked through in a browser. Plain-wording fixes are in
  0.33.1; since 0.35.0 every ANOVA can find the smallest detectable effect
  (by scaling the pattern entered) and regression can with no effect size,
  and regression's effect section says what to choose first. Still open:
  the result page is long. An AI walkthrough is no substitute for the
  human sessions in `usability-session-pack.md`.

- **Documents:** the pre-replication notes and the study-planning document
  save as a typeset PDF (through the browser's print window), an editable
  Word .docx and Markdown (`R/documents.R`). The pre-replication notes
  become the document for where the user landed: a negative
  pre-replication report, or a pre-replication section for the
  replication (Karhulahti et al., 2025).

- **Validation checkpoints:** source/lock/installed-package/R fingerprints
  prevent old saved passes being reused for a different calculation context.
  Independent test shards retain test identities, seeds and replication counts.
  Published-value placeholders and the full release run remain unfinished.
- **Input and maintenance assessment:** reported t/F text fills existing
  engine-conversion fields without guessing or rounding unsupported df; matching raw/published summary routes
  and honest missing-input guidance appear on forms. Shared sample metadata
  supports results, recruitment, plans and exports. `dependency-footprint.md`
  measures locked closures and scopes optional profiles; none is advertised
  or implemented as a partial installation.
- **Publishing and protection:** a separate `connect-cloud` branch is prepared
  for Posit, retaining exact main source apart from the generated manifest.
  Main can then require aggregate app/engine gates which reject prerequisite
  failures and accidental skips, without a privileged bot bypass. Activation
  and the Posit branch selection are documented in `repository-protection.md`.


- **Planning decisions and assumptions:** prediction is separate from test
  direction. Accuracy presets explain finite-simulation error and fitting
  failures; family-specific input guides cover meaning, illustration, source
  and unknown routes. Named alternatives and reported/derived/assumed/unknown
  records persist in drafts/projects. Formula comparisons exclude long
  simulations and unsupported goals. Planning documents use captured answers
  and the same staleness/reasoning guards as kept plans.

- **Browser regression gate:** pinned Playwright/Chromium checks real
  calculations, edits, project/draft round trips, precision, cancellation and
  Labs Back/Forward in an isolated local app; reports retain failed traces.

- **Long-job assessment:** `hosting-options.md` proposes external durable
  queueing, ticket recovery and staged checkpointing, with reproducible
  streams, denominator preservation and failure acceptance tests. No durable
  service is implemented; current jobs still end with their Shiny session.

- **Variant evidence and capabilities:** a versioned case registry separates
  software agreement, independent references, published examples and method
  runs. Results, saved projects and scripts retain its hash and snapshot.
  The About catalogue derives discrete choices and limits from current forms;
  unknown variants stay unknown, and historical records are not release-wide
  certification.

- **Welch populations:** two-group planning accepts one common SD or separate
  raw SDs, or a ratio alongside a difference in fixed RMS-SD units. Formula
  and simulation use the same population across allocations; scripts and
  example data preserve it. Point-biserial/test-statistic conversions and
  safeguard planning remain limited to their equal-SD assumptions.

- **Group names:** optional; a levels field takes a count ("3") in place
  of names.
- **Bayes factors:** fifteen designs have a Bayes factor test version,
  all listed on "Plan a study analysed with Bayes factors" (E-bayes) and
  found by searching "Bayes". P-value results of the exactly calculated
  ones offer "Add a Bayes factor?" (`bayes_companion()`): the chances at
  3 and 10, the size for both and, for t-tests, how often they agree.
  Bayes factor t-test results show the plan under JASP's three prior
  widths. Informed priors wait on a bfpwr fault (`upstream-questions.md`).
  Their results also offer the plan as a sequential design.

- **Input screens:** a box hides when every field in it is hidden, and
  means in SD units take an SD of 1 without asking.

- **Unfinished drafts:** input screens can download partial answers without
  a calculation or justification. The same file opener restores blanks and
  editable values, clears any previous calculation and labels the draft as
  unvalidated. Answers on an input screen are also kept in the browser
  (localStorage, same format) and a new visit offers to continue them.

- **Connection and loading:** a starting screen while the server wakes, a
  "Working…" bar when busy, a 20-second heartbeat, a reload by itself on
  returning to a page whose connection was lost, and
  Shiny reconnection to the same session when its process still runs. The
  About page is built after the first screen and fetched by the browser
  in the background, so it opens at once.

- **Simulation outcomes:** every recorded sample-size point retains attempted,
  valid, failed and successful decisions. Power4mome's valid-fit denominator
  and simr's all-attempt denominator are preserved and identified; results
  and methods show both conditional and successful-study frequencies when
  decisions fail. Older saved records are not assigned invented failure counts.

- **Current versus historical guidance:** the README and build guide describe
  the actual routing app and acknowledge sourced Powerkit implementations.
  Obsolete empty screen scaffolds are removed; the optional assistant folder
  explicitly contains no service. Historical coverage/decision inventories
  point to current routing metadata and retain their dated scientific evidence.
  About distinguishes hosted processing, local execution and optional feedback.

- **Verification follow-up:** upstream questions have a per-variant exposure,
  evidence, workaround and recheck register, separating bypassed faults from
  active limitations and recorded resolutions. The psychologist usability
  protocol now covers missing information, plausible mistakes, interpretation,
  file round trips and a counterbalanced comparison. Human sessions remain
  outstanding; no ease-of-use result is claimed.

- **Script handoffs:** package names and the minimum declared R version
  come from the selected engine backend and its supporting software.
  Mixed-model handoffs name simr rather than power4mome; the downloaded
  script records versions and uses the same R requirement.

- **Transparency:** feedback names the entered answers included by its
  checkbox and the browser information accompanying Send. About credits
  include precision and robust-analysis tools, using their own citations.
  The build guide separates implemented phases from outstanding validation,
  usability and hosting completion checks.
  Cards and results identify scoped check records rather than describing
  every variant as validated or every completed check as a published example.
  A complete variant-by-variant evidence registry remains outstanding.

- **Planning guidance:** precision is reachable with its estimate choice
  visible outside Settings. MBESS's expected width and presize's width at
  the supplied values are explained separately, without a median claim.
  Simulation choices describe their supplied populations, including the
  stated group SDs for Welch's test. All-tests planning offers the independence rule or
  a sufficient union-bound target when dependence is unknown, with unchanged
  alpha and explicit unconditional-probability requirements.
  The engine preserves single-test targets exactly, including near zero.

- **Sample counts:** plans distinguish participants, pairs, items and
  studies, and only show a largest comparable requirement for matching
  recorded sample structures. Group allocation metadata is shared by
  recruitment and reproduction scripts. Exact search steps no longer
  default to 1 when a whole allocation requires a large block.
  Meta-analysis comparisons also retain the number of participants and
  dependent effects within each study.

- **Labs and navigation:** research tools and educational tools have
  separate sections. The repeated-studies tool uses actual two-group
  normal-data t-tests and effect estimates, with simulation uncertainty,
  conditional selection summaries and labelled CSV exports. Browser
  history tracks individual tools and the menu; Chrome checks cover menu/tool Back and Forward, cross-tab restoration,
  a completed run and the stale-settings warning. Numerical and screen tests pass.

- **Sample-size search:** doubling checks the largest valid allocation at
  the configured limit. Boundary regressions cover valid allocation steps
  and a small-effect independent t-test that reaches its target below the cap.

- **Scientific decision integrity:** joint power is limited to supported
  tests; effect exploration preserves margins and design priors. Models
  58/59 use full product moments and explicit population residual variances
  (Departure 19), checked against independent populations and the backend
  generator. Their broader validation remains separate from these checks.

- **Search discovery and hosting costs:** the pages search engines index
  (a landing page, the guide, the sitemap) are static files in `site/`,
  published to GitHub Pages at <https://joelthornton.github.io/Powerkit/>;
  the app's `robots.txt` asks crawlers to stay away, because every visit
  starts the app on a host paid for by the hour. The page's keep-open
  message stops after 20 minutes without use. Still to do once, by the
  maintainer: turn on GitHub Pages, point Connect Cloud at `connect-cloud`
  if it still watches main, and add the new site to Search Console
  ([`hosting-options.md`](hosting-options.md), "Setting it up").

- **Saved-result integrity:** calculations capture their original form
  answers; changed or inconsistent restored answers require recalculation
  before saving or joining a plan. Study-plan round trips preserve results
  and original provenance. Numerical records include precision and other
  goal-specific outputs, recovering omitted fields from older typed screens.
  Targeted regression checks accompany these changes; full validation is
  still tracked separately below.

- **The app** (`app/routing/`) is online at
  <https://joelthornton-powerkit.share.connect.posit.cloud> and is
  published once a day from the `connect-cloud` branch (Posit Connect
  Cloud; the `online-app-manifest` workflow updates it from main when the
  app, the engine or `renv.lock` changed);
  [`run-it-yourself.md`](run-it-yourself.md) is for running it locally.
  Parts of screens that repeat (the list of analyses, an input screen's
  groups of fields) are kept as HTML once built (`cached_html()` in
  `R/ui.R`), so a click shows the next screen in about 40 ms on a laptop.
  **51 cards calculate in the app**: E1-E9, E15, E18-E32, E34-E36,
  E37, E43, E44, E46, E47-E57, E59-E61, E64, E66, E69, E70 and E71 (`forms.yaml`'s `calculates`);
  E71, differential item functioning (whether a test's items work the
  same way in two groups, in a 2PL IRT model, by irtpwr's analytical
  method; both of each DIF item's parameters tested by default, the
  maintainer's decision of 5 November 2026), reached from Q1, since 5
  November 2026;
  E73, exploratory factor analysis (the chance every factor's loadings are
  recovered, simulated with Spower around psych's fa()), since 5 November
  2026;
  E58, latent profile analysis (the chance the BIC finds the right number
  of profiles, simulated with Spower around mclust), since 5 November 2026;
  E72, signal detection (d' in two conditions or groups, simulated with
  Spower: hits and false alarms, the log-linear correction, a t-test),
  reached from Q1, since 5 November 2026;
  E35, growth curves (two groups' rates of change over three or more
  occasions, Diggle and colleagues' formula in longpower; with drop-out
  or unequal groups, Hu, Mackey and Thomas's), since 5 November 2026;
  E30, moderation by a factor with three or more groups (the F test of the
  X x group terms, simulated with Spower and lm()), since 5 November 2026;
  E32, moderation of a yes/no outcome (logistic regression with X x W,
  simulated with Spower and glm()), since 4 November 2026;
  E70, multinomial logistic regression (an outcome in three or more
  unordered categories on a score or yes/no predictor, simulated with
  Spower and nnet's `multinom()`; the likelihood-ratio test or one
  category's Wald test), since 4 November 2026;
  E69, reliability and agreement (tests of an ICC, Cronbach's alpha and
  kappa against a value to beat; ICC.Sample.Size, statpsych, kappaSize),
  reached from the aim screen, since 2 November 2026;
  E43, time to event (the log-rank test by Hmisc's `cpower()`, and a
  score in a Cox regression by powerSurvEpi's Hsieh and Lavori formula),
  since 2 November 2026;
  E44, the actor-partner model for pairs (with joint power for actor and partner
  effects tested together, and since 5 November 2026 a pair-level moderator of the actor effects), and E46, precision planning
  (below), since 1 November 2026; E64
  and E66, the Jonckheere-Terpstra and Cochran-Armitage trend tests
  (simulated with Spower; one- or two-sided, equal or unequal groups),
  since 1 November 2026; E61, a planned
  meta-analysis (metapower's z test, or the Hartung-Knapp test by
  default, simulated with metafor), since 31 October 2026, with subgroups
  of studies, several effects per study (POMADE), a moderator that is a
  score and the test of heterogeneity (both simulated with metafor) since
  1 November. Bayes factor versions: the three t-tests
  and, since 1 November 2026, the test of one proportion (E25; bfpwr,
  JASP's prior and one-sided test by default) and the correlation (E4;
  BayesFactor, JASP's Bayes factor and prior width by default) and two proportions (E5; BayesFactor's contingency table Bayes factor, JASP's default), and since 2 November the one-way ANOVA (E18; BayesFactor's ANOVA Bayes factor with JASP's r scale of 0.5, exact) and tables of any size (E6; BayesFactor's contingency table Bayes factor with JASP's sampling plan and prior, simulated with Spower), and since 5 November the effects of two-factor between-participants ANOVAs (E7, E21, E22; JASP's inclusion Bayes factor, simulated) and of the repeated-measures ANOVAs (E8, E54, E55, E20; a preview here and an R script). **Fourteen are simulated with a
  preview first**, then a full run in the app or an R script: E10-E14,
  E17 (a yes/no X or W), E38 (W on both links or the direct path, both
  1 November 2026) and E40 (with a yes/no X or W since 2 November)
  (mediation and moderated mediation, power4mome), E16 (mediation
  with a yes/no X), E33 (participants and items, simr; the conditions within or, since 31 October 2026, between participants), E63 (the same with three or more conditions, 31 October 2026; both with a score or, since 1 November, a yes/no answer on each trial), E68 (three levels, people in groups in larger groups, 1 November 2026), E67 (a predictor measured on each item, 1 November 2026) and E62 (a
  two-level model with predictors at each level and their cross-level
  interaction, simr; reached from the new question C1 for people within
  groups, 31 October 2026; agrees with a separately written simulation,
  published value and statistician review to come; since 1 November 2026
  also with the groups in larger groups, predictors at all three levels);
  E62 and E68 with a score or, since 1 November 2026, a yes/no outcome. No template
  is engine-only.
- **Finding an analysis:** "I know my analysis" lists every analysis in
  closed groups by family with a search box (31 October 2026), common
  starting points and status labels, and keeps the search when you come
  back from a card (1 November 2026); the input screen counts the needed
  answers still empty, in its bottom bar (1 November 2026); the methods
  map in Labs opens full screen: the families as regions, and each
  analysis in focus with the designs that lead to it, the ways to change
  it, its usual test and a "Plan this study" button (`methods-map.yaml`;
  the test labels and connections await the statistician's review;
  1 November 2026); "Help me
  choose" asks the screening questions first; the search also knows other
  names (`tree.yaml`, `search_words`); an "Explanations" switch, on by
  default, shows technical names first and hides the hints when off.
- **About and Updates** (1 November 2026): About says how powerkit
  works in three steps and lists every analysis that calculates by family,
  each opening its card; Updates (once "What's new", between Labs and
  Feedback) is a timeline of titles that open, with Full details, a search
  and the changes since your last visit marked. Every tab shares one
  column.
- **Start screen, Labs, Feedback** (1 November 2026): three short ways
  to start with "Recently opened" for returning visitors; Labs as a grid;
  Feedback in one card; About's families fold on a phone.
- **Precision, study plan and whole-study screens** (1 November 2026)
  follow the result layout: section links, one large figure, write-up
  before downloads. The study plan names analyses in plain words, puts
  the largest N first and can remove one; precision results can join it.
- **Questions and cards** (1 November 2026): each question shows its
  number and takes number keys; a card opens with how it calculates, the
  package and its checks, and lists what you'll need.
- **Results** open with the answer as one large figure and what it
  assumes, then "How sure can you be?" (the effect slider and cautious and
  hopeful guesses), then the write-up with Copy buttons and the downloads
  (1 November 2026). They state their spec hash, seed, backend, R and package
  versions; save as a project file or a study plan and reopen (a project
  saved from 0.26.0 shows its saved result without running it again); export an
  R script that reproduces them with the backend alone, citations, a
  methods paragraph and, for most designs, a simulated data set. A saved
  simulation reproduces on the number of cores it ran on (0.24.1).
- **Effect sizes researchers have:** the t-tests and the correlation take
  a published t, F, r, d or odds ratio (t and F into d by psych's `t2d()`,
  with the group sizes when given; the rest by effectsize;
  `conventions.md`, "Effect-size conversion"); between-participants
  (including three factors), repeated-measures and mixed ANOVA and the
  ANCOVAs take partial eta-squared and the chi-square tests Cohen's w, as
  G\*Power does; the two-group t-test takes a point-biserial r (G\*Power's
  point-biserial model, 0.27.0); moderation
  takes the R-squared change; safeguard power for an effect from one
  study. MANOVA (E59, one or two factors) and one-sample Hotelling's T-squared (E60) take
  means, SDs and a correlation, and their cards say why.
- **Validation.** Most designs are checked against the package each one
  calls, plus Type I error; independent checks exist for the basic tests
  (G\*Power screenshots), mediation (pwrss and simsem) and the two-group
  MANOVA (pwrss's exact F). 17 published examples are transcribed and
  pass; the rest keep `TODO_PUBLISHED_VALUE` for the maintainer. 20 of
  the 70 analyses that run are marked validated, in the validation log's
  sense (a recorded full run agrees with the backend and analytic results
  and keeps Type I error); the other 50 say "validation in progress". Validation runs per design before a PR
  merges, every night the engine changed and in full every Sunday, from
  00:05 UTC (`scripts/validation-plan.R`, `nightly-validation.yaml`).
  The Sunday run of 1 November passed 27 of 28 chunks; the two-mediator
  moderated mediation chunk ran out of time (6 hours), so the moderated
  mediation chunks now run one test at a time on all 4 cores, as the
  mediation chunks do (2 November 2026).
- **The critical effect size** (the smallest observed effect that would be
  significant at the n analysed; Perugini et al., 2025) is on the results
  and in the methods paragraph for the t-tests and the correlation (1
  November 2026).
- **Minimum-effect tests** (an effect larger than a smallest effect of
  interest) are a test version on the one-sample, paired and two-group
  t-tests, by pwrss (0.27.0; Known difference 10).
- **A justified alpha** (the significance level that minimises or
  balances the weighted errors at a fixed N, JustifyAlpha's
  `optimal_alpha()` on pwr's power) is a goal on the one-sample, paired and
  two-group t-tests and the correlation (0.27.0; Known difference 11, the
  balanced version being G\*Power's compromise analysis).
- **Precision planning** (E46, 1 November 2026): the sample size for a
  confidence-interval width, or the width expected at a given n, rather
  than power. Cohen's d between two groups, d_z and a standardised mean
  by MBESS (`ss.aipe.smd()`, `ss.aipe.sm()`, with optional assurance);
  a correlation (Pearson's, Spearman's or Kendall's) and a proportion
  (Wilson's interval by default) by presize; since 1 November 2026 also a
  raw mean difference, an odds ratio and an ICC (presize) and a
  standardised regression coefficient (MBESS's `ss.aipe.reg.coef()`, which
  needs gsl). MBESS brings OpenMx with it, the heaviest new dependency.
  E33 can also plan the number of items for a fixed number of
  participants (1 November 2026).
- **Rank tests** are simulated for normal, skewed or heavy-tailed scores:
  the Wilcoxon, Mann-Whitney and Kruskal-Wallis tests, Friedman's test (E54,
  31 October 2026), Spearman's and Kendall's correlations (E4) and, since
  2 November 2026, the Brunner-Munzel test (E2), for groups whose spreads
  may differ, and the aligned rank transform ANOVA (E7, E21, E22: two
  between-participants factors; since 4 November 2026 also E8, E55 and
  E20, with a within-participants factor), and PERMANOVA for several
  outcomes (E59's test version, vegan's `adonis2()`, 4 November 2026).
- **Negative binomial regression** (E28's model choice, 2 November 2026)
  for overdispersed counts, simulated with Spower and MASS's `glm.nb()`;
  **zero-inflated Poisson and negative binomial regression** (4 November
  2026) for counts with extra zeros, simulated with Spower and pscl's
  `zeroinfl()` (the count part, the zero part or both).
- **One regression coefficient** (E24's third question, 2 November 2026):
  the usual test by pwrss's formula, or with HC3 or HC4 standard errors
  (car) or by quantile regression (quantreg), simulated with Spower.
- **Pairwise comparisons** after a one-way ANOVA (E18, E54): the power of a
  chosen pair, adjusted by Holm's (the default, Departure 17) or
  Bonferroni's method, simulated with Superpower (31 October 2026).
- **Experimental:** whole-study simulation on the guided plan, for
  factorial experiments (Superpower, 6 November 2026), and for a
  measured predictor or two groups (randomised, or since 5 November 2026 non-randomised groups correlated with the moderator or the first measurement), people measured once or twice (each analysis adjusted for the first measurement, including two mediators and moderated mediation of one link; power4mome; waiting for a statistician's check, `next.md`, "Waiting on the maintainer");
  joint power in a study plan when every analysis compares the same
  randomised groups on different outcomes (PUMP: independent t-tests,
  cluster-randomised trials and, since 2 November 2026, multisite trials); Labs (pre-replication
  notes, the methods map, the effect size converter, the power
  visualiser for the two-group t-test and, since 0.27.0, the correlation
  (since 0.28.0 also the paired t-test, the one-way ANOVA, two proportions, a
  chi-square test and a regression's R-squared, and one-sided t-tests),
  and Bayesian planning for the Bayes factor t-tests from bfpwr, at a
  fixed N or, since 0.28.0, sequential: checked as the data come in,
  stopping when the evidence is strong).
- **Moderated mediation with W on both links or the direct path** (E38,
  PROCESS models 8, 58 and 59, 1 November 2026): the difference between
  the conditional indirect effects at two values of W, simulated with
  power4mome and powerkit's test (manymome's `cond_indirect_diff()`); a
  preview in the app, the full run from an R script. A yes/no X or W in
  models 7 and 14 (E17, 1 November 2026) the same way, drawn by
  power4mome's `rbinary_rs()` and checked against a separately written
  simulation; with a yes/no X and no moderation its Type I error is about
  6.7%, against 5.3% for the separate simulation, stated on the results
  screen until power4mome answers (`upstream-questions.md`).
- **Waiting on others:** Spower's faults are ready to raise upstream
  (`docs/upstream/spower-var-test.R`).

### Known gaps on cards that run

- Mixed designs with unequal groups are simulated with Spower and afex
  (1 November 2026); their validation chunk (`anova_mixed_unequal`) has
  not had a full run on GitHub yet. Every repeated-measures card takes an
  SD per cell and correlations per pair, with a sphericity correction
  where one applies.
- Simulated data sets are missing for the three-way regression
  interaction (no package generates its data from the correlations it
  takes), the meta-analysis, SEM, McNemar's test and the generic tests;
  every other card that runs has one (1 November 2026).
- MANOVA with three or more groups is simulated (no formula in a package
  or the G\*Power manual); two groups and one group against fixed values
  are exact since 31 October 2026 (Hotelling's T-squared).
- SEM covers model fit (exact, close and not-close fit), measurement
  invariance of one to five factors across up to ten groups or occasions,
  factor correlations and latent slopes (2 November 2026). Not covered:
  invariance with groups of unequal size beyond two, or with only some
  factors differing in their own items.
- Technical details (df, critical value, noncentrality) are given for
  every exact design whose package reports them, SEM and the correlation
  included since 1 November 2026; TOSTER and powertools return none
  (powertools: `upstream-questions.md`), and Bayes factor designs have
  none to give.

### Working environment

- **Moderated-mediation evidence:** the opt-in conditional-indirect-difference
  chunk completed with three passes and one published-value placeholder skip.
  The validation journal records the independent simulation comparisons,
  run revision and replication limits; this is scoped method evidence,
  not release-wide validation.

- **CI:** the engine's R CMD check on every push that changes the engine,
  `renv.lock` or the CI setup (skipped otherwise), with the engine's
  tests beside it in three parts on separate runners (test files four at
  a time in each); the app's suite on every pull request and on main, as two jobs
  side by side (`test-results.R`, and the rest); the Windows and macOS
  install test when the launcher or lockfile changes, and weekly. All run
  in a prebuilt image with R and the locked packages.
- **Cloud sessions:** `scripts/setup-cloud-session.sh`, as the
  environment's setup script, copies R and the packages from the CI image
  and writes the shell settings R needs to `~/.powerkit-env.sh`, sourced
  from the first line of `~/.bashrc`. devtools and roxygen2 aren't in the
  image; `CLAUDE.md` gives the commands to use instead.
- **Clean-machine install checks:** the R installer download retries transient
  failures with exponential backoff, a connection limit, an attempt limit
  and a retry window. Download failures remain distinct from installer and
  app-start verification failures.

- **Open PRs:** GitHub is the list; this page doesn't duplicate it.

## status.md as it stood on 18 November 2026 (0.78.15)

*Last updated: 17 November 2026 (the input screen's labels are the same with explanations on or off, and a line names the boxes the effect size goes in; the undecided designs decided: prevalence and diagnostic accuracy first, then group-sequential designs with rpact and assurance, queued as item 15; replication Bayes factors count a success only in the original's direction; replication plans: a study design table for Registered Reports, a script for the chosen criteria and a one-sided option; replication plans start from the researcher's purpose, with one main criterion and the others reported at its sample size; the input screen's box headings are the same with explanations on or off and name the effect, it shows the standard name, and a heading no longer shares a line with a question; the mixed-model cards offer Kenward and Roger's degrees of freedom beside Satterthwaite's; the ANCOVA asks whether its covariates are measured or set by the design, and next.md item 27 now also audits the method choices each card makes for the researcher; the smallest detectable effect on the interaction regression cards, a yes/no or count outcome's moderation, an outcome in unordered categories, latent profiles and factor analysis; replication plans: validated against a simulation of their model, published examples pending; accuracy fixes from a review, and the rest of the review queued as items 28 to 32; pairwise rank comparisons after the Kruskal-Wallis and Friedman tests, E18 and E54, with the researcher choosing separate tests of each pair or Dunn's or Conover's test; fixed: the ordinal card shifted group 2 the wrong way, which mattered with uneven shares, and an audit of every card for a check independent of its package is queued; fixed: Friedman's test with heavy-tailed scores no longer fails its check run by chance; a rank test's result shows the usual test's answer beside it, and the usual test's result offers the rank test, chosen in advance; Bayes factors for an R-squared increase and one regression coefficient on card E24; the analysis search finds test versions such as Mann-Whitney, Brunner-Munzel and PERMANOVA by name and opens them chosen, and matches words from their start; Cochran's Q on a card of its own, in the yes/no group; continuity-corrected count tests worked out exactly; the binary-X moderated mediation note gives the 20,000-study null rate; which assumption the answer depends on most, a tornado chart and a two-way grid on the result screen; the other-dyadic-designs card written as a guide to the pair cards; the smallest detectable effect by a simulated search on the Jonckheere-Terpstra trend, factorial logistic regression, moderation-by-groups and interrupted time series cards; moderation of an outcome in three or more unordered categories, card E32; the smallest detectable effect by a simulated search on the paired-variance, trend and d' cards; the smallest detectable effect on the ordinal, survival, growth-curve and reliability cards; the smallest detectable effect for meta-analyses and structural equation models; Cochran's Q, yes/no answers from the same people in three or more conditions, on card E75; the smallest detectable effect on the dependent correlations, variances, Hotelling, MANOVA and equivalence cards; long runs that carry on in a study plan, with progress on the plan's page; the effect panels on the formula cards whose effect is one number; small fixes testers meet: the step bar on a study plan, the effect section's help, field prompts and the analysis search; the smallest detectable effect on the formula cards that lacked it; four fixes as colleague testing starts: no pre-selected count model, the mediation estimate's validation label, rule-of-thumb help and plainer errors and scripts; the analysis list's groups in two independent columns; design review: one look for buttons, boxes and folds; fixes from the 15 November reviews before colleague testing; methods decided for three Bayes factors: the R-squared increase, the multinomial test and the A/B test; developing or validating a prediction model, card E77; review fixes on this round's cards: the online app's missing-package message, a card code in E32's text and the hints under a card's name; the Bayes factor three-factor ANOVA, card E56; replication and study plan fixes from the colleague-testing review; clustered yes/no outcomes can be simulated with glmer(); the ICC planned by its F test's exact power; the Bayes factor ANCOVA, card E23, and the factorial ANOVAs' Bayes factor write-up; the Bayes factor for R-squared, card E24; within-person moderation, card E41; replication plans for an original analysed with Bayes factors; replication goals for any one-number effect; a count or yes/no outcome in moderation and mediation, card E32; the binary-X null check uses seed 1500; two groups in a ratio rounded at every total; mediation with a yes/no mediator, card E39; two or more groups measured more than once with a count, yes/no or ordered categories, card E75; mediation with X in three or more groups, card E42; corrected repeated-measures tests without sphericity simulated by default, and both nightly validation failures explained; counts, yes/no and ordered categories measured more than once, card E75; Bland-Altman limits of agreement on E69; replication plans: the pre-replication notes and the replication planner move from Labs into a kind of study plan; Yuen's trimmed-means t-tests on E2 and E3; tidier cards and input screens; Plan my whole study keeps its plan in a study plan; a study plan's overview and Download everything; repeated-measures correlation, card E76; several named study plans with a page of their own; JASP's analyses reviewed against the cards and the queue reordered; every change on main now gets a version number, and 0.63.0 numbers the waiting notes; specialist maths review fixes; share links for projects, plans and drafts; a clearer save area on the result screen; the AI assistant is dropped from the plan; CLAUDE.md's facts brought up to date; version 0.62.0 closes the pre-tester fix batch; faster results; replication planner gives its simple answer first; small wording fixes; keyboard focus and contrast fixes, accessibility audit script runs again; one line of help per field; a calmer result screen; regression takes Cohen's f-squared; the goal and direction as buttons on the form; choosing an analysis takes fewer screens; MANOVA takes Pillai's V; tables of means, SDs and proportions entered in a labelled grid; moderated regression result screen fixed; replication from the design finder; cards say what they can't do; critical effect beside the smallest effect; sphericity correction default and exact correlation method; pre-tester review fixes; start screen layout; count-search safeguards merged in PR #372; compact guidance follow-up; live rollout unconfirmed). Where the project is
now, one short paragraph per area; replace a paragraph rather than adding
to it. What to do next is [`next.md`](next.md). History is in git,
[`engine/NEWS.md`](../engine/NEWS.md) and
[`archive/status-history.md`](archive/status-history.md), which holds this
page as it stood before each rewrite.*

powerkit is in development and **not ready for use**: results are not yet
fully validated ([`validation-log.md`](validation-log.md)). The working
rules are in `CLAUDE.md`. There is no AI assistant: it was dropped from
the plan (`decisions.md`, 13 November 2026).

The 15 November reviews' fixes for colleague testing are in (16 November
2026): simple mediation's quick estimate calculates, two proportions with
unequal groups find the smallest detectable effect, the ordinal Wald test
with three or more groups uses the interaction's degrees of freedom, the
one-way ANOVA moves to the classical F test when eta-squared or Cohen's f
is chosen, an effect from one study no longer needs a written adjustment,
Bayes factor text speaks of the evidence threshold rather than "strong
evidence", cards open on their points with the checks so far folded
below, and Plan my whole study carries the same "Validation in progress"
badge as the cards. Four more followed as testing began: the
count screens (E75, E32) no longer pre-select Poisson, simple
mediation's quick estimate says "Validation in progress", the help no
longer warns people off a rule-of-thumb effect, and error messages and
the R script's opening read plainly (the evidence record moved to the
script's end). Still open from those reviews, for later: the
whole-study step bar, the reliability-left-empty wording on the
moderation cards, and the smaller items listed as later in the reviews.

The app's layout and names were made consistent the same day, from the
16 November layout review: one name for each thing that is saved
(analysis, analysis file, study plan, replication plan, report); a top
row of Power and sample size, Study plans (with its count and unsaved
dot), Tools (formerly Labs, without "experimental") and About, which now
holds the Updates; one Share button that shares what is open; every way
of keeping a result in "Keep this result"; "Replicate a published
finding" starting a replication plan; a route line on the whole-study
screens; and "Powerkit" spelled the same in the app's sentences. Old
saved files and ?page= addresses still open as before
(`saving-projects.md`, "Names used in the app").

A design review on 16 November 2026 made the same control look the
same on every screen: buttons, text boxes, menus and file pickers share
one corner radius and a border with 3:1 contrast, the Tools sliders take
the app's blue, folds on the result screen and the cards show an arrow,
the action bar is a whole rounded bar, and the power chart's label stays
inside a phone's chart. The analysis list's groups sit in two columns that
move independently, so opening a group leaves no gap on the other side.

Tools offers the replication planner (it starts a replication plan),
About folds the coloured list of every analysis and a capability table
with one row per analysis (downloadable in full as a spreadsheet), and
Feedback confirms a sent message on its button and in a panel.

Moderated mediation with a yes/no X tests slightly liberally (5.38% at alpha .05 in 20,000 studies, `validation-log.md`); its card note says so.

Colleague testing starts 16 November 2026. What testers report, and what
the reviews left for later, is `next.md` item 25 and comes first while
testing runs. With it comes item 27, an audit of every card that
runs for a check independent of the package it wraps, after the
ordinal card's wrong direction of shift passed a validation built on the
same package (fixed 17 November 2026). Done from it on 16 November: the step bar and heading on a
study plan's page, the finder's crossed-factors example, the effect
section's duplicate help, the power and alpha rows' styling, and the
analysis search (general words such as "power" ignored, best-matching
groups first, "simple slopes"). On 17 November the search learned
test versions by their own names (tree.yaml's `test_versions`): a
search for Mann-Whitney, Brunner-Munzel, Kruskal-Wallis, PERMANOVA or
quantile regression shows a "Test version" line under the analysis that
holds it, which opens that input screen with the version chosen; each
typed word now matches from the start of a word. A run that takes a while can move to a study plan
and carry on while the person uses the rest of the app, with its
progress on the plan's page; it still ends with the browser tab, until
a hosting choice adds a durable job queue.

JASP's analyses were reviewed against powerkit's cards (13 November
2026; `coverage-roadmap.md`, "JASP's analyses"). Those powerkit already
plans under other names (CFA, MIMIC, latent growth, mixed models, the
binomial and A/B tests, contingency tables, Cochrane meta-analysis) are
now found by those names in "I know my analysis". The rest lead the
queue in the maintainer's order: three small designs, then every card
that says powerkit can't calculate it yet, then a Bayes factor version
of every design that can have one, then the remaining JASP analyses.
The Bayes factor queue has started (14 November 2026): E24 plans R-squared
against 0 with BayesFactor's linear-regression Bayes factor and JASP's r
scale of 0.354, exactly from the noncentral F; validation in progress
(the `bayes` chunk). E23 plans the Bayes factor of an ANCOVA effect
(15 November 2026): JASP's inclusion Bayes factor from BayesFactor's
`generalTestBF()`, with the covariates as model terms and JASP's r scales
(0.5 for the effects, 0.354 for the covariates), simulated; validation in
progress (the `bayes_ancova` chunk). E56 plans the Bayes factor of a
three-factor ANOVA effect (15 November 2026), any mix of between and
within factors, with `anovaBF()` as for the two-factor ANOVAs, simulated
(a preview and the R script in the app); validation in progress (the
`bayes_three` chunk). The factorial and repeated-measures
ANOVAs' Bayes factor write-ups now name their test and say "effect"
rather than "association". E24's R-squared increase and one coefficient
have a Bayes factor too (17 November 2026): the model with all the
predictors against the model without the tested ones, simulated from the
three independent sums of squares with BayesFactor's
`linearReg.R2stat()`; validation in progress (the `bayes_r2change`
chunk). The methods for the multinomial test (E48) and JASP's A/B test
(E5) are decided (`decisions.md`, 15 November 2026) and waiting to be
built (`next.md` item 2).

Developing or validating a prediction model has a card of its own, E77
(15 November 2026), reached from the start screen's aims. Developing: the
minimum sample size by the criteria of Riley et al. (2019), computed by
pmsampsize's `pmsampsize()` for a yes/no, continuous or time-to-event
outcome, from the number of candidate predictor parameters and a similar
model's C-statistic or R-squared. Validating an existing model of a yes/no
outcome: the criteria of Riley et al. (2021), computed by pmvalsampsize's
`pmvalsampsize()`, from the anticipated C-statistic, the outcome
proportion and the model's linear predictor. There is no power; the
result screen lists each criterion's sample size and the one that sets
the answer. Validation in progress: the chunk `prediction` passes (both
packages called directly, and Riley et al.'s closed forms worked out
without them); the papers' examples await transcription.

A repeated-measures (within-person) correlation is planned on a new card,
E76 (13 November 2026): rmcorr's documented method, a Pearson
correlation's exact power at the effective sample size N(k − 1) + 1
(Bakdash and Marusich, 2017), reached from the design finder's new
question R2 and by search. Validation in progress: the simulation chunk
`rmcorr` passes; the published example awaits transcription. Yuen's
trimmed-means t-tests are a test version on the two-group and paired
cards (E2, E3; WRS2's `yuen()` and `yuend()`, simulated with Spower; the
paired version asks for the correlation between the measurements).
Validation in progress: the simulation chunk `yuen` passes; the
published example awaits transcription. The Bland-Altman limits of
agreement are a fourth question on the reliability card (E69, 14 November
2026): the analysis simulated with SimplyAgree's `agreement_limit()`,
MOVER intervals by default (Departure 27), Bland and Altman's as an
option, Lu et al.'s formula as an instant approximation; power at a
fixed sample size runs on the card, a sample size comes as an R script.
Validation in progress: the simulation chunk `agreement` passes; the
published example awaits transcription. The first of the cards that
said powerkit couldn't calculate now does: E75, the same people measured
more than once with a count, a yes/no answer or an answer in ordered
categories (14 November 2026), a generalised linear mixed model with a
random intercept for each person (simr's `makeGlmer()` for Poisson and
logistic models, Spower with lme4's `glmer.nb()` for negative binomial
counts and ordinal's `clmm()` for ordered categories), the likelihood-ratio test by
default; power at a fixed number of people runs on the card, a number of
people comes as an R script. Two or more groups measured more than once
(the group-by-time interaction, `y ~ group * cond + (1 | person)`) run
on the same card for all four outcomes. Cochran's Q, one yes/no answer
from each person in each of three or more conditions, has its own card
(E78, 17 November 2026) in "Yes/no, categories and ordered categories",
found under its name by search and reached from the design finder; it is
the same engine route as the test version on the repeated-measures card
(16 November 2026): the answers simulated from the card's logistic model
and each study tested with `stats::friedman.test()` (Cochran's Q on 0/1
data), power and the number of people both run in the app. Validation in progress: the chunk `glmm`, with
Cochran's Q's file, passes; the published examples await transcription. E42, mediation with
X in three or more groups, calculates too (14 November 2026): each
group's relative indirect effect against the first (dummy coding, as
PROCESS does), a Spower simulation of the model fitted by lavaan with
manymome's Monte Carlo interval, for one group or every group; power at
a fixed sample size runs on the card, a sample size comes as an R
script. Validation in progress: the chunk `mediation_mcx` passes; the
published example awaits transcription. E39, mediation with a yes/no
mediator, calculates as well (14 November 2026): regression-based causal
mediation analysis (Valeri and VanderWeele) by regmedint, a logistic model
for the mediator and a linear or logistic one for the outcome, the natural
indirect effect tested by its delta-method standard error, simulated with
Spower; power and a sample size both run on the card. Validation in
progress: the chunk `mediation_binm` passes; the published example awaits
transcription. E32's moderation takes a count outcome too (14 November
2026): a Poisson or negative binomial regression with the X x W product,
its Wald z test simulated with Spower; power and a sample size both run
on the card. Its mediation takes a yes/no or count outcome with a score
mediator (14 November 2026): regression-based causal mediation analysis
by regmedint (a linear model for the mediator; logistic, Poisson or
negative binomial for the outcome), the natural indirect effect's
delta-method test simulated with Spower; power and a sample size both
run on the card. Its moderation takes an outcome in three or more
unordered categories too (17 November 2026): a multinomial logistic
regression by `nnet::multinom()` with the X x W product, the
likelihood-ratio test of the K - 1 product terms (or the Wald z test of
one category's) simulated with Spower; power and a sample size both run
on the card. Validation in progress: the chunks `count_interaction`,
`multinomial` and `mediation_yglm` pass; the published examples await
transcription. Mediation of a categorical outcome is still uncovered.
E41 plans within-person moderation (14 November 2026): occasions within
people, an occasion-level predictor centred within each person and a
person-level moderator, in E62's two-level model simulated with simr; the
sample size counts observations, and the result gives people and
occasions. Power runs on the card, a sample size comes as an R script.
Validation in progress: the chunk `two_level` passes; within-person
mediation is not yet calculated. Next in the queue: the rest of those
cards (`next.md` item 1). A tool showing which uncertain input a plan depends on most
(one-at-a-time ranges and a tornado chart) is queued after the cards
that can't yet calculate (`next.md` item 23).

The cross-lagged panel card runs with a reliability below 1 (13
November 2026): its check run compares the specified lagged effects with
those recovered from error-free scores, since measurement error
attenuates them by design (specialist maths review, M-11).

Tables of means, SDs and proportions (two-factor, mixed and repeated
measures ANOVA, ANCOVA, MANOVA, chi-square and logistic factorial cards)
are entered in a grid whose rows and columns are named from the levels
typed above it, with an example and a line on why powerkit asks for
means; the text box stays for pasting, and a link beside the grid
switches to Cohen's w or partial eta-squared where the card takes one
(`decisions.md`, 12 November 2026). MANOVA also takes Pillai's V, as in
G*Power, computed by G*Power's published formula (Faul et al., 2007) and
checked against simulation, and the regression card takes Cohen's
f-squared, as G*Power does, converted by the engine; the within-participants and logistic
factorial cards still take only their tables.

Results come sooner (12 November 2026): the spare R process prepares
the spec checker and Superpower before a calculation needs them, and an
ANOVA's sample size is shown before its 80/90/95% comparison table,
which fills in after it. Welch's ANOVA, the one-way default, is worked
out by Levy's approximation as Jan and Shieh (2014) recommend (13
November 2026), so its answer is instant; the simulation stays as an
option on the card (`decisions.md`, 13 November 2026).

The second specialist mathematics review (13 November 2026) is finished
and its fixes, apart from the cross-lagged panel check run (merged in PR #395),
are in: clustered yes/no outcomes show powertools' unsourced factor 1.2
as Known difference 16, and can be planned instead by a `glmer()`
simulation of the trial without the factor (the formula stays the
default; `decisions.md`, 15 November 2026), the three-way interaction's fixed-model formula
shows its gap from simulated studies as Known difference 17, the SEM
test of fit has no preselected test (not-close fit listed first), the
cross-lagged panel card asks whether to enter the reliability or assume no measurement error (then the result says power is optimistic), and a simulated
meta-analysis's number of studies shows its interval, and the ICC is
planned by its F test's exact power (Donner and Eliasziw, 1987), with
ICC.Sample.Size's approximation as an option (Departure 29). Mediation and
PROCESS simulations test each simulated study 3 to 7 times faster with
identical results: the Monte Carlo interval is computed directly from
manymome's draws (`fast-mediation-test.R`). Whether to change
the clustered yes/no and three-way methods is a queue item for the
maintainer (`next.md`).

The moderated regression cards' result screen, which stopped with an
error for the sample size and power since 10 November, shows its result
again (fixed 12 November, with a test).

"Help me choose" reaches the t-test, one-way ANOVA and MANOVA one
question sooner (the number of groups is asked with the number of
factors), the aim screen leads with "Test a prediction", and the
analysis list shows its groups in two columns and finds the names
researchers use, such as Cohen's f or mixed ANOVA. On the form, the
goal and the test's direction are rows of buttons, the bar names the
answers still needed, and the effect section uses the same white cards
as the rest; each field shows one line of help, with the rest behind an
info button beside its label; a group's info button sits beside its heading, and a card whose checks are in progress says so once (14 November 2026). The result says the answer once, with the sample size at
other powers and significance levels in a small table, and keeps the
records for checking it under one "Technical records" fold
(`decisions.md`, 12 November 2026).

Every route through the design finder now ends on a card that can hold
the user's answers or says at the top what it can't do (the equivalence
aim, a non-score outcome, Bayes factors on "Plan my whole study") and
where to go instead (`decisions.md`, 12 November 2026). The
smallest-effect result gives the critical effect beside it, Welch's
t-test included when groups are equal, and the ANCOVA result shows how
Shieh's method differs from G*Power's (Known difference 15).

A pre-tester review on 11 November corrected three calculations: decimal
group-size ratios no longer force large steps in the total (since 14
November two groups in a ratio are rounded to whole people at every
total, `docs/conventions.md`, "Group sizes given as a ratio"), non-inferiority
t-tests use the one-sided t-test against the margin, and a search whose
power cannot rise says so. Precision planning for one group and paired
data accepts assurance. In the app, exports no longer wait for a written
effect-size reason, the run button is "Calculate", Welch's t-test has the
explore panels, and partial eta-squared with Welch's ANOVA is caught on the
input screen. The study plan is reachable from every screen and kept in
the browser; a result is reused when only free-text answers change; a
conventional effect size can be recorded as one. The non-inferiority and allocation unit tests and the
non-inferiority validation chunk were run; no full validation run is
claimed. Minimum-effect tests now use the same shifted t-test (12
November; the equivalence validation chunk was run). Two groups in a
ratio are now planned at every total with the groups rounded as a
researcher would recruit them (14 November): G*Power's variance-test
example now agrees (443), and two proportions at a ratio of 2 need 371,
one more than G*Power's 370, whose groups fall just short of the target.

Simple mediation (E10, E16) starts on a quick estimate by formula (the
joint-significance test, pwrss), marked as an estimate on the result, with
the simulated methods for the number to report (12 November).

The claim (how many tests a conclusion rests on) is asked in view on every
input screen, with a Bonferroni choice for related tests (12 November).

Results now help users compare with the tools they know (12 November):
Student's answer beside Welch's, the cost of a stricter alpha, Cohen's f
named on the ANOVA screens, and plainer wording in the checks panel and
the advice on effect sizes.

The correlation card plans by the exact distribution of r, as G*Power (12
November; Departure 10 retired), with Fisher's z as a choice.

Repeated measures with SDs or correlations that differ now default to the
Greenhouse-Geisser corrected F test (12 November, Departure 26); the
uncorrected test stays as a choice with a warning. Since 14 November such
a corrected test is simulated by default (Departure 28): Superpower's
exact dataset scales the test by epsilon, which missed the corrected
test's power by up to about 3 points either way. It stays available as
an approximation and still finds the smallest detectable effect, with a
warning.

The input screens were shortened (11 November): the two-group t-test
screen shows about 670 words at first sight, from about 1,200, with the
spread ratio and between-study variation folded. Wording only.

The start screen was laid out again before colleagues try the app
(11 November): a title and one-sentence introduction, the three routes
with more room, and saved projects and the local download in one row
under a divider. Presentation only; no method, default or evidence
claim changes.

The [R checklist](release-readiness-review.md#fix-checklist) now records checked
subtasks directly under each open/partial R14–R36 item, with the remaining
acceptance work beside it. Parent boxes close only when the full requirement
is met; this tracking correction adds no implementation or validation claim.

The [release-readiness review](release-readiness-review.md) safeguards merged
in PR #369 (0.61.1): early analysis limitations, clearer power/paired-input help,
eleven common analysis-translation checks and a phone action-bar correction.
Required gates, full app/browser checks, clean Windows/macOS first/repeat
starts and CRAN-release compatibility passed. Scientific validation gaps
remain open; these checks do not establish broad mathematical validation.

The publishing correction merged in PR #370. Its isolated-index publisher
preserves checked source, prior deployment ancestry and temporary build files.
[Publication run 42927530578](https://github.com/JoelThornton/Powerkit/actions/runs/42927530578)
succeeded: deployment commit 300b53d967df contains checked main bdbdfb6cc7e3
plus the pinned manifest. The host's normal rollout is left to complete;
a new live version is not claimed verified. The public download page and
sitemap body were checked in a browser, including the download-page entry.
CRAN-development job outcomes were still unrecorded at the 11 November
00:03 UTC handoff; CRAN readiness and first-release evidence remain open.

The [first-release support plan](v1-support-plan.md) sets a broad coverage
target, a representative benchmark and complex-design audit briefs. Its
[source inventory](release-support-inventory.json) is generated from current
expanded forms and access routes, with a freshness check. It is discovery
metadata, not new scientific evidence or a measured 99% result. Audit P0
cases and investigate the two recurring failures before further claims.

Local installation recovery merged in PR #368: bounded per-file TLS/download
retries, alternate downloader/mirrors, bootstrap recovery and an engine
completion stamp written only after a successful matching install.
An isolated three-package binary restore on Windows passed with renv 1.0.3
and an unchanged lockfile. Full clean Windows/macOS first/repeat starts passed
on that PR's final head. No fix is claimed for every network.
Since 16 November 2026 the launcher needs no compilers on Windows or
macOS: recorded versions that CRAN no longer builds come from Posit
Package Manager's dated CRAN snapshots, and the install check runs with
every compiler switched off (`run-it-yourself.md`).

The [default review and checklist](variation-default-review.md) records the
maintainer's approval of ordinary t-test and Pearson correlation plans starting
without between-study variation (10 November). Explicit variation scenarios
retain the existing engine and saved values, and explain averaged significance
rather than power at the average effect. The smaller-effect comparison now
shows power at the exact analysed sample size. Since 17 November 2026 the
result screen's "How sure can you be?" card also asks which assumption
matters most: the researcher gives a lowest and highest plausible value
for the effect and for any other uncertain input (an SD, a correlation
between measures, a reliability, an ICC, a base rate), and sees the
answer at each end, one input at a time, as a tornado chart, plus an
optional grid of the effect against one other input changed together.
It runs for formula designs only; simulated designs are next.md item 23. These source changes are not a claim about the deployed app or new scientific validation.

This release batch adds [PROCESS-style mediation planning](process-style-planning.md):
OLS plus casewise percentile bootstrap, alongside the existing ML Monte
Carlo and ML bootstrap methods. All nine applicable forms expose the
method/count; bootstrap plans run through a local script that saves an
app project for viewing the result without rerunning it. Results and exports
record the choice, and same-data
regression/interval checks cover the supported model families. The PR validation completed the two selected null checks (2,000 studies and
1,000 resamples each): .0495 for simple mediation and .0585 for binary-X
model 7, with a direct-reference TODO skip. Results and frozen settings are
archived; the 5,000-resample default and other cases remain outside that
recorded run. A direct archived
PROCESS-software comparison remains pending; no evidence badge is upgraded
and the existing ML/Monte-Carlo binary-X failure remains open.

The five safeguards merged in PR #368 are recorded in the
[review checklist](release-readiness-review.md#five-priority-safeguards-10-november):
visible corrected-ANOVA limitations, a new unknown-dependence default that
preserves historical plans, matched interaction-sensitivity verification,
four independent corrected-count fitted-N checks with honest uncertainty,
and selected-setting evidence on input screens. Since 17 November 2026 the
continuity-corrected two-proportion and 2 x 2 tests are worked out exactly
over every possible result, so their sample size is the smallest that
reaches the target, with no simulation error; the simulated search with
fresh confirmation checks (PR #372) remains for specs that ask for
simulation. Historical saved results retain the old warning. Independent case checks and hosted gates are recorded
in the count-test checklist; the ANOVA/mediation failures and broader evidence
requirements remain open. Attrition input/results/methods now distinguish a
recruitment buffer from missing-data modelling. Pilot guidance describes
uncertainty and selection without asserting inflation or automatic halving.

The compact-guidance follow-up makes explanations-off fold routine field
help, defaults and group notes behind native info controls, with concise
common labels. Selected methods, units, errors and scientific limitations
stay visible. Explanations-on keeps guidance inline. Target power remains
blank, with equally styled 80/90/95% examples and consequence/cost guidance
rather than a preferred 80% shortcut. This changes presentation, not methods,
effect values or numerical defaults. Desktop/phone interaction, keyboard
and automated accessibility checks passed locally for the exercised routes.

### Where things are

- **Review fixes (7 November 2026):** the earlier project review grouped 21 serious problems
  and about 110 smaller ones into fourteen fix batches, all done by
  8 November: validation runs that finish and report, what the app says,
  design-finder routes, the draft box and page structure, effect-size
  guidance, speed, whole-study planning, input screens, Labs, docs and
  start-up reading, change notes that no longer need catch-up merges
  (each pull request writes its own note files and sets the version with
  `scripts/close-batch.R` before it merges, so every change on main has
  a number: `decisions.md`, 13 November 2026), Welch's tests by default
  (Welch's t-test on the two-group card, by formula, Departure 21;
  Welch's F on the one-way ANOVA card, by Levy's approximation as Jan
  and Shieh, 2014, recommend, simulated on request, Departure 22), small
  telescopes for replications (0.47.2: d33 at the original study's own
  significance level, the power if the true effect is small but not
  zero, and wording that says what a result below d33 does and doesn't
  show), and the review's own checks kept for
  each release: property checks over every example spec and a run of
  every card in a browser (`repository-protection.md`, "Checks before a
  release"). A check of every review finding against what merged
  (8 November) found a few left: the small ones are fixed, and the
  larger ones are in `next.md`; two proportions now take a published
  odds ratio or risk ratio, mediation with two groups takes X's
  effects as Cohen's d, the card for people in groups offers joint
  power for several effects, precision planning by MBESS asks for a
  chance (assurance) that the interval is narrow enough, and mediation
  results say that the planned Monte Carlo interval differs from
  PROCESS's percentile bootstrap, and the significance level and the
  Bayes factor threshold start empty, as target power does, with the
  usual value one click away and an optional reason (9 November).
  Decisions from October are archived (`archive/decisions-2026-10.md`,
  indexed at the top of `decisions.md`), and closing a batch moves Updates
  entries over a month old to `whats-new-archive.yaml`, which the Updates
  tab still shows. Each document's downloads are one PDF button with a menu
  for Word and Markdown, and the pre-replication notes in Labs are worded
  as a tool rather than as a summary of their source paper. Effects that vary between
  studies are on the t-test and correlation cards, with a table of the
  answer at no, small, medium and large variation, and an opt-in Bayes
  mode is on the start screen, with Bayes factor write-ups worded as
  design analyses and a write-up for plans that report a p-value and a
  Bayes factor together (8 November). Next: the queue in `next.md`; the rest of
  Bayes mode (item 17) waits on a decision.

- **What calculates:** 77 of the 78 analyses run in the app (80 cards,
  counting the "none of these fit" and Bayes factor guide cards;
  `tree.yaml`'s statuses); the other dyadic designs card is a guide to the
  pair cards. 59 calculate in the app directly (`forms.yaml`'s
  `calculates`), by a package's formula where one exists, otherwise by
  simulation with Spower, Superpower, simr, power4mome, metafor or PITS.
  The rest are simulations too slow for the app: a preview in the app,
  then a full run or an R script the researcher runs themselves
  (mediation and moderated mediation, participants and items, multilevel
  models, Bayes factors of repeated-measures effects). Every design but the
  generic tests is reached from the design finder, and "I know my
  analysis" lists all of them by family with a search. No answer leads to
  "No matching design" unless the user chooses it, apart from a short list
  of known gaps that two tests in `test-misroutes.R` hold fixed: a new
  gap fails them (8 November 2026, after counts and ratings measured twice
  had reached it).

- **Test versions researchers commonly need:** rank tests for skewed or
  heavy-tailed scores; robust standard errors and quantile regression;
  negative binomial and zero-inflated counts; minimum-effect and
  equivalence tests; a justified alpha; pairwise comparisons with Holm's
  adjustment, including rank comparisons of pairs after the Kruskal-Wallis
  and Friedman tests (separate tests of each pair, or Dunn's or Conover's
  test, as the researcher chooses); effects that vary between studies on the three t-test
  cards (Kenny & Judd, 2019, through pwr; an SD of 0.05 in d to start
  with, Departure 23) and the correlation card (McShane & Böckenholt,
  2014, through pwr; 0.025 on Fisher's z, Departure 24), each result
  showing the answer at no, small, medium and large variation;
  precision planning (a confidence interval's width, by MBESS
  and presize) as a goal beside power. Bayes factor versions exist for
  fifteen designs, with JASP's default priors; p-value results of the
  exact ones offer "Add a Bayes factor?", and Bayes factor t-test results
  show three prior widths, a sequential plan and an uncertain effect.
  An opt-in switch, "I'll analyse with Bayes factors", at the top of
  "I know my analysis" (where it narrows the list to the 15 designs with
  a Bayes factor version) and of "Help me choose" (12 November; it was a
  "Bayes mode" on the start screen), opens every card on its Bayes factor
  version and asks how unsure the user is about the effect instead of
  assuming 0.
  Informed priors wait on a bfpwr fault (`upstream-questions.md`).

- **Effect sizes:** the commonest cards take what researchers have: a
  published t, F, r, d or odds ratio, partial eta-squared, Cohen's w, the
  R-squared change; safeguard power for an effect from one study or a
  pilot, or small telescopes for a replication (Simonsohn, 2015); the
  smallest detectable effect on the t-tests, the correlation,
  proportions, the ANOVAs (Welch's F by formula; by partial eta-squared
  too), multiple, logistic and Poisson regression, moderated regression,
  one proportion, McNemar's test, two independent correlations, goodness
  of fit, planned contrasts, ANCOVA and the clustered design (16 November
  2026: pwrss's power searched over the effect, checked against G*Power's
  F test, pwr, WebPower, stats and a simulation), and since 17 November
  2026 the dependent correlations, one and two variances, Hotelling's
  T-squared, MANOVA by Pillai's V or with two groups, and equivalence
  tests, where the answer is the narrowest bounds the sample could show,
  the meta-analysis's average effect (metapower's z test, and the
  Hartung-Knapp test by simulation) and structural equation models (the
  RMSEA for exact, close and not-close fit, a factor correlation, a latent
  slope), two groups on an ordinal outcome, the log-rank test and a Cox
  predictor, growth curves, and the ICC, Cronbach's alpha and kappa (each
  backend's power searched, checked against simulations of the tests and
  the packages' own solvers), and, by a simulated search with a 95%
  interval, two paired variances, a trend in proportions, d' in two
  conditions the Jonckheere-Terpstra trend test and
  the factorial logistic regression's main effects and interaction and
  moderation by three or more groups, the interrupted time series,
  moderation of a yes/no or count outcome, an outcome in unordered
  categories, moderated regression with a yes/no X or W, latent
  profiles (the separation) and factor recovery (the loading), and by
  InteractionPoweR's formula the three-way interaction (the rest is `next.md` item 11). Results show the critical effect size for the
  t-tests (Student's) and the correlation. The "If the effect were
  different" and "What if the true effect is smaller?" panels work on the
  basic tests and, since 16 November 2026, on the formula cards whose
  effect is one number: multiple regression (R-squared, partial R-squared
  or the R-squared increase), logistic and Poisson regression (the odds
  or rate ratio, weaker meaning closer to 1), the ANOVAs from partial
  eta-squared, the interaction's R-squared change, one proportion, two
  proportions and two correlations. Not yet: an ANOVA or ANCOVA given by
  its means (a pattern, not one number) and the simulated designs.

- **Results and documents:** a result opens with the answer and what it
  assumes, then "How sure can you be?", the write-up with a methods
  paragraph, and downloads: a project file, an R script that reproduces
  it with the backend alone, citations and, for most designs, a simulated
  data set. A "Keep this result" box under the answer holds Save project
  file, Copy a link and Add to my study plan, with a "Not saved yet"
  status, a warning before leaving and browser recovery of the last
  result; the documents sit apart, with a "Download everything" zip that
  the Open button also reads. "Copy a link" beside each save button puts the same file
  inside a link's fragment, so a project, study plan or draft opens on
  any computer with nothing stored and no account
  ([`saving-projects.md`](saving-projects.md); not yet tried inside
  Connect Cloud's frame). Every result records its spec hash, seed,
  backend, and R and package versions. The pre-replication notes and the study-planning
  document save as PDF, Word and Markdown. Results link to the Labs tool
  that explains them.

- **Study plans:** several named plans, each with a description, kept
  in the browser and saved as a file or a link that opens on any
  computer. "Study plans" in the top bar opens a page of its own
  (`?page=plans`) listing them; each plan's page gives the largest
  comparable N, joint power where it can be calculated, and each analysis
  with a role (primary, secondary, check), a note, and Open, which brings
  back its card, answers and saved result. Each plan says whether it has
  been saved to a file, since the browser's copy can be cleared. Each plan
  has an overview (its analyses by role) and "Download everything": one
  zip with the plan file, a study-wide planning document (Markdown and
  Word), the merged references and each analysis's own files; the zip
  opens again as the plan. "Plan my whole study" makes or fills a study
  plan that keeps the guided plan, its analyses (with the roles the
  guided plan gives them) and the last whole-study result, and reopens
  the guided screens from the plan's page
  ([`saving-projects.md`](saving-projects.md), "Study plans").

- **Experimental: whole-study planning.** The guided plan simulates
  several analyses of one study together, so the chance all succeed is
  counted rather than assumed: measured predictors or two groups
  (randomised or not), people measured once or twice, mediation and
  moderated mediation (power4mome), factorial experiments (Superpower),
  and a pair-level moderator in dyadic studies. Joint power for several
  outcomes of one randomised trial uses PUMP. Its result gives a
  planning document (PDF, Word or Markdown) with every analysis and its
  role, the claim, the population assumed, the joint and separate powers
  and the R script that reproduces them, marked experimental on its first
  page. It waits for a statistician's check ([`whole-study-method.md`](whole-study-method.md));
  the designs still to add are in `next.md` item 7.

- **Replication plans** (14 November 2026). A replication plan is a kind
  of study plan, started from "New replication plan" on the Study plans
  page, from Labs or from the input screen's signpost for an effect from
  an earlier study. Its page holds the sections that were Labs' tools:
  the pre-replication notes (whether to replicate), the original study,
  the goals table for an original t-test or correlation finding
  (Anderson & Maxwell, 2016; BayesRepDesign, Pawel, Consonni & Held,
  2026; the small-telescopes card's calculation) under three beliefs
  about the true effect, how the replication differs, and one write-up.
  The original's design is found with the design finder's questions; its
  card, with each effect field labelled as the original's, plans the
  replication and keeps the result in the plan. The plan saves, shares
  and downloads like any study plan. Since 15 November 2026 the goals
  table covers any card whose focal effect is one number: the original's
  estimate with its standard error, interval or test statistic, ratios on
  the log scale and correlations on Fisher's z (each card's effect is in
  `forms.yaml`, `replication_effects`); the four keep their exact routes.
  An original analysed with Bayes factors (15 November 2026) is read
  from its Bayes factor (a t-test, inverted with BayesFactor's
  `ttest.tstat()`; Ly et al., 2018) or from a posterior with a vague or
  default prior; small telescopes is left out, and the goals add the
  original's Bayes factor test repeated and evidence for no effect
  (bfpwr), with a way on to a sequential Bayes factor design in Labs.
  After the colleague-testing review (15 November 2026) the notes show
  one box per part, the references are listed once at the foot, the
  Bayes factor goals use the cards' "Evidence threshold" wording,
  variation between studies starts at Small (0.05; docs/conventions.md),
  and the replication's alpha and power start empty with buttons. Each
  study plan can be deleted from its row on the Study plans list. A
  review on 17 November 2026 fixed what gave wrong or misleading output:
  a goal met by any replication (the pooled goal after a strong
  original) said "not reachable"; variation between studies was applied
  in d to a correlation's Fisher's z and to another design's own scale;
  the plan accepted a card for a different design from the one entered,
  and kept the "None of these fit" card as the original's design; an
  extension added to the plan was written up as the original's analysis;
  and the write-up cited every method. A paired original can now be
  entered as its t or as d_rm or d_av with the correlation (Lakens,
  2013), and another design's uncertainty as an F with one numerator df.
  Validation (17 November 2026, `validation-log.md`): every goal's
  chance agrees with a separate simulation of the method's model, and the
  classical goal and small telescopes with t-tests on simulated people;
  the published examples are placeholders, so the plan says "Validation
  in progress". A replication or sceptical Bayes factor counts as a
  success only in the original's direction (Departure 31; BayesRepDesign
  counts either side by default). Since 17 November 2026 the
  Goals section asks the purpose first (confirm the effect, settle it
  either way, or test its absence) and gives one sample size, from one
  main criterion under one belief, with each criterion under "Also
  report" as its chance at that size; a criterion that can show absence
  starts ticked (Departure 30), the default Bayes factor t-test is
  offered for p-value originals, d33 is the equivalence bound when none
  is entered, and the table of every criterion folds under the answer.
  The write-up adds the study design table Registered Reports ask for,
  the R script runs only the chosen criteria under the chosen belief,
  and the significance test can be one-sided. Still to come: the card in
  replication mode and a step bar (item 28), extensions (29), BUCSS for
  originals reported as an F (30) and study plans' shared settings (31).

- **Experimental: Labs.** The methods map, the effect-size converter,
  the power visualiser, the repeated-studies tool and Bayesian planning
  (fixed and sequential), all on the cards' engine code and one chart
  style. The replication tools moved to replication plans.

PR #368 added selectable continuity-corrected two-proportion and
2 by 2 contingency tests, leaving existing defaults intact. Inputs/results
name the correction and sampling plan; corrected tests simulate the actual
R analysis and report failed studies. Direction/allocation/replay checks and
the selected high-replication comparisons passed locally and on GitHub.
Four independent returned-N checks are archived, including small target
shortfalls and a reference outside the smooth curve interval; fresh final-N
confirmation is implemented in PR #372. Published references, broader parameter coverage
and minimum-N efficiency remain open. See the
[count-test checklist](count-test-review.md).

The wording pass merged in PR #368 corrects the equal-group Welch/Student
overstatement, scopes the interaction comparison to its recorded cases,
labels interaction sensitivity as a formula approximation, and distinguishes
one-test power from any/all-test success. The regression form now explains
why its two input routes need not agree. This is the first pass of the
full wording audit in release-readiness-review.md, not every-screen sign-off;
statistical engines are unchanged; new all-required-test plans now use the
existing unknown-dependence bound while saved choices are preserved. Three
fresh sensitivity checks (10,000 simulated studies each) are archived; all
99% power intervals included the 80% target. They use the same backend and
do not establish universal agreement or an independent-package validation.

Compact-mode naming has been audited across all 77 analysis entries and
14 families. Curated conventional names replace explanatory title suffixes
in the analysis list, cards, input headings, recent entries and the methods
map's standard-name field. Common method selectors are shorter; detailed
analysis assumptions and validation warnings remain separate and visible.
This is display metadata, not a change of method, defaults or evidence.
R22's crossover scope correction is also implemented: ordinary paired
analysis is no longer presented as a general adjusted-crossover approximation;
card/input guidance and copied methods state the limitation. The dedicated
crossover model remains a separate capability/evidence gap.

### Validation

Most designs are checked against the package each one calls, plus their
Type I error; independent checks exist for the basic tests (G\*Power), for
mediation (pwrss and simsem), for the two-group MANOVA and for several
simulations (a separately written simulation each). 17 published examples
are transcribed and pass; the rest keep `TODO_PUBLISHED_VALUE` for the
maintainer. 20 of the 70 cards that run are validated in the validation
log's sense; the other 50 say "validation in progress". Validation runs
for a design before its PR merges, every night the engine changed, and in
full every Sunday from 00:05 UTC (`scripts/validation-plan.R`), with
tests dealt to parts by their recorded times so each part ends within
GitHub's six hours, and one list at the end of each run of the tests that
need attention. The recorded full run of 8 November took 4 hours 13
minutes (389 pass, 2 fail, 110 skipped; skips include partitioning and
published placeholders). An earlier inspected nightly,
[9 November run 42570428222](https://github.com/JoelThornton/Powerkit/actions/runs/42570428222),
also failed the ANOVA and binary-X checks (the latter .077 in 1,000).
The latest completed nightly inspected,
[11 November run 42968983200](https://github.com/JoelThornton/Powerkit/actions/runs/42968983200),
at fbbd237 (0.61.1), failed only the two recurring partitions: GG .2130
versus .2313, and binary-X ML/Monte-Carlo null .0750 versus a .0707 limit.
Both are explained (14 November, `validation-log.md`). The GG reference
.2313 is Superpower's epsilon-scaled approximation; the corrected test's
power is .217. Such tests are now simulated by default (Departure 28).
With the maintainer's approval, the chunk's three corrected-test checks
now compare the simulated default with independent references (.4658,
.2169 and .0971), and bound the exact dataset's approximation at 4 points. The binary-X null rate is 5.38% in
20,000 studies, consistent with 5%; seed 1703 drew a 1-in-80 sample every
night. The maintainer chose seed 1500 for that check (`decisions.md`, 14
November 2026), which gives .051.

### Known gaps on cards that run

- Simulated data sets are missing for the three-way regression
  interaction, the meta-analysis, SEM, McNemar's test and the generic
  tests.
- MANOVA with three or more groups is simulated (no formula in a package
  or the G\*Power manual).
- SEM doesn't cover invariance with more than two groups of unequal size,
  or with only some factors differing in their own items.
- Technical details (df, critical value, noncentrality) are missing where
  the package reports none (TOSTER, powertools) and for Bayes factors.
- With a yes/no X and no moderated mediation, power4mome's Monte Carlo
  interval rejected in 5.38% of 20,000 studies (likely about 0.4 points
  above 5%); the results screen states it (`validation-log.md`,
  14 November 2026; `upstream-questions.md`).
- Long simulations end with the visitor's session; no durable job queue
  (`hosting-options.md`, `next.md` item 11).
- No usability sessions with researchers yet
  ([`usability-session-pack.md`](usability-session-pack.md)); no
  ease-of-use result is claimed.

### The online app and releases

The app is online at
<https://joelthornton-powerkit.share.connect.posit.cloud>, published at
most once a day from the `connect-cloud` branch (at 04:23 UTC, with a
second look at 16:23 in case GitHub skips the first), which the
`online-app-manifest` workflow writes with the manifest Connect Cloud
installs from ([`hosting-options.md`](hosting-options.md)). "Copy page
link" gives the open tab, the Labs tool or the open card (`?card=E8`,
which opens that card as the list of every analysis does). The pages
search engines index are static, in `site/`, on GitHub Pages. Main
requires a pull request with passing checks; each finished version is
tagged and published as a GitHub pre-release
([`repository-protection.md`](repository-protection.md)). Verify the static site, download page and indexing configuration against
the actual deployment; Search Console registration alone does not prove
that every page is indexed.

**CRAN (11 November 2026):** every package the engine uses is on CRAN,
and the engine has been prepared for submission: the backends only some
designs use are in Suggests (25 non-base Imports remain, and installing
the engine alone brings 228 locked packages rather than 300,
[`dependency-footprint.md`](dependency-footprint.md)), a run whose
backend is missing says which package to install, every exported
function has an example, and on CRAN a quick set of 23 test files runs
(`engine/tests/testthat.R`). The online app still installs every
backend (`app/routing/optional-packages.R`). The v0.60.0 Linux current-dependency
quick CRAN suite passed on R release and devel with NOT_CRAN=false.
The 0.61.1 release job also passed; the development-job outcome was not yet
recorded at the handoff. This is compatibility evidence, not scientific
validation or CRAN acceptance. Other platforms, optional-backend
coverage and submission checks remain. Submitting is a queue item
in [`next.md`](next.md).

### Working environment

- **Claude Code sessions:** `.claude/settings.json` caps the context
  window before compaction at 400,000 tokens (`autoCompactWindow`), for
  every Claude Code session on this repository.
- **CI:** R CMD check and the engine's tests in three parts when the
  engine, `renv.lock` or the CI setup changed; the app's suite in two
  parts and the browser checks on every pull request; the Windows and
  macOS install test when the launcher or lockfile changes, and weekly;
  all in a prebuilt image with R and the locked packages.
- **Cloud sessions:** `scripts/setup-cloud-session.sh`, as the
  environment's setup script, copies R and the packages from the CI image.
  roxygen2 isn't in the image; `CLAUDE.md` says what to do instead.
- **Open PRs:** GitHub is the list; this page doesn't duplicate it.
- **Upstream reports:** the questions in `upstream-questions.md` were
  rerun on 13 November 2026 for longpower 1.0.27, irtpwr 1.0.3 and
  semPower 2.2.0; all three still reproduce, and none has been sent yet.
