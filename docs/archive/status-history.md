# Project status: history

*Moved here from [`status.md`](../status.md): everything up to 18 October
2026, when `status.md` became a current-state page, and at the end the
page as it stood on 30 October 2026. Other history is in git and
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
