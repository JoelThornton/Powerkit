# Project status

*Last updated: 17 October 2026. Update this page with every PR.*

powerkit is in development and **not ready for use**: results are not yet
fully validated. Validation runs are recorded in
[`validation-log.md`](validation-log.md).

For a short summary and the working rules, see [`handover.md`](handover.md).

## Where things are

- **E5 validated again (17 October 2026).** The `basic` chunk was rerun
  on main after #42 (unequal groups by pwrss;
  [run 39073022227](https://github.com/JoelThornton/Powerkit/actions/runs/39073022227)):
  no failures, the usual 4 published-value skips. Unequal groups are
  checked against G\*Power in `test-backend-pwr.R`. As the maintainer
  asked, E5's card says "Validated" again.
- **E6 G\*Power reference (df 1).** The maintainer's screenshot (w .3,
  α .05, N 100, df 1: power 0.8508388, λ 9, critical χ² 3.8414588)
  matches pwr to 7 decimals; recorded in
  [`gpower-parity.md`](gpower-parity.md). df 2 is still needed.
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
  groups for now (Departure 11 in [`conventions.md`](conventions.md);
  reasoning in [`decisions.md`](decisions.md)). At the maintainer's
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
  decimals ([`gpower-parity.md`](gpower-parity.md), E5); they are tests.
- **`basic` chunk rerun after the E5 switch** (run 39071722512, commit
  43e8d0e): 21 pass, 4 published-value skips; recorded in
  [`validation-log.md`](validation-log.md).
- **G\*Power screenshots checked (17 October 2026; docs only).** The
  maintainer's G\*Power 3.1.9.7 screenshots are in
  [`figures/gpower/`](figures/gpower/) and recorded in
  [`gpower-parity.md`](gpower-parity.md). E5: G\*Power's z test equals
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
    [`conventions.md`](conventions.md), shown on the card and the result
    screen, with a test of its size (at most 0.004 in power, 1 in N).
  - **E5 (G6):** the maintainer wants a z test by default. Base R's
    `power.prop.test()` matches pwrss's pooled z test to 1e-16 when it
    counts both tails (`strict = TRUE`), and differs from pwr's arcsine by
    up to 0.018. The switch waits for G\*Power screenshots and the
    maintainer's yes; `power.prop.test()` handles equal groups only.
  - **Spower:** `p_r()`'s two-sided p-value when `rho != 0` is recorded in
    `decisions.md` and the roadmap, with a draft note to Phil Chalmers in
    [`upstream-questions.md`](upstream-questions.md) (not sent).
  - **Multiple hypotheses (Rubin addendum, docs only):** B6 now uses Mark
    Rubin's individual / disjunction / conjunction framework, with Frane's
    competing view; new judgement calls G7 (a correction by default?), G8
    (alpha and tails as required inputs with a reason) and G9
    (sensitivity analysis first-class); a second candidate source for
    B11; joint-power tools in roadmap row C2; multilevel and longitudinal
    candidates; and [`inference-question-design.md`](inference-question-design.md)
    (options only). Most sources couldn't be opened here and are marked
    "candidate (not opened)".
- **G\*Power parity and E4/E5 methods (PR #37, merged 17 October 2026; docs only).** [`gpower-parity.md`](gpower-parity.md)
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
  the maintainer's decision on [`phase5-simulations.md`](phase5-simulations.md).
- **Routing design options (17 October 2026; docs only).**
  [`routing-design-options.md`](routing-design-options.md) compares the
  current question tree with a "design profile" (the same six questions
  every time, matched against a rule table), on one screen or one
  question at a time. Of 28 recorded misroutes and route conflicts, the
  current tree now prevents 15 (3 partly) and a profile with exact
  matching would likely have prevented 19 (2 partly); 7 need a further
  question in either approach. It drafts the rule table for E1–E14.
  Options and evidence only; nothing decided.
- **Coverage roadmap (17 October 2026; docs only).**
  [`coverage-roadmap.md`](coverage-roadmap.md) is the master list of
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
    [`phase5-simulations.md`](phase5-simulations.md) sets out the options.
- **Independent cross-checks for parallel and serial mediation (merged in
  PR #30; passed 17 October 2026).** Two validation chunks,
  `mediation_crosscheck_parallel` and `mediation_crosscheck_serial`,
  compare the joint test in power4mome and simsem. All four designs agree
  within the Monte Carlo interval with no allowance (differences 0.003 to
  0.009; [validation log](validation-log.md)). powerkit's Monte Carlo CI
  itself has no independent check for two mediators.
- **CI installs packages from `renv.lock` (17 October 2026).** Spower 0.7
  reached CRAN on 16 October and CI picked it up, which broke the
  one-sided departure test on every PR. All workflows now restore the
  versions in `renv.lock` (Spower stayed at 0.6.4 until a separate PR,
  which waits for the maintainer, moves to 0.7). Who may merge PRs, and
  when: [decisions](decisions.md), 17 October 2026.
- **Spower 0.7 (merged in PR #31, 17 October 2026).** `renv.lock` is on
  Spower 0.7, and one-sided basic tests use Spower's own one-sided test;
  Departure 4 is retired. Results are identical with the same seeds. The
  `basic` validation chunk passed on GitHub on Spower 0.7 (20 PASS, 4
  TODO skips; [validation log](validation-log.md)). power4mome stays at
  0.2.1 (Departure 8 stays until its fix reaches CRAN). Known gap: nothing
  independently checks the Monte Carlo interval for two or more mediators
  ([judgement calls](judgement-calls.md), F1).
- **Build phases 0–3 are done** ([build guide](build-guide.md), section 8):
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
  ([validation log](validation-log.md)).
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
  is defined at the top of the [validation log](validation-log.md).
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
  n >= 100 ([validation log](validation-log.md)). Moderated,
  parallel and serial mediation have no independent cross-check yet. Why
  power4mome is used, and its established alternatives, are in
  [decisions](decisions.md), 16 October 2026.
- **Drafts for the maintainer:** a message to Shu Fai Cheung (power4mome)
  in [`upstream-questions.md`](upstream-questions.md) (seeding with product
  terms; multi-category X), not sent; and the statistical decisions phase
  3b needs before coding, in [`phase-3b-questions.md`](phase-3b-questions.md)
  (options and what the backends' docs say; nothing chosen).
- **Waiting on published values:** several validation tests still have
  `TODO_PUBLISHED_VALUE` placeholders (including the G*Power published
  examples for basic tests), to be transcribed by the maintainer.
- **Upstream:** two issues found while wrapping Spower and power4mome were
  reported and fixed upstream on GitHub; powerkit keeps its workarounds
  until the fixes reach CRAN ([conventions](conventions.md), Departures 4
  and 8).
- **Routing prototype (merged in PR #15):** a clickable Shiny prototype of
  [`decision-tree.md`](decision-tree.md), in `app/routing/`. Routing only:
  no calculations (the input screens, added later, use the engine's
  `validate_spec()` only). It covers the three routes (I know
  my analysis; help me choose; plan my whole study), end-point cards, and
  placeholders for the undecided judgement calls, which are settings in
  `app/routing/tree.yaml`. A test keeps that file in step with
  `decision-tree.md`, and the prototype's tests run on GitHub on every
  pull request. How to run it: [`routing-prototype.md`](routing-prototype.md).
- **User-testing kit (draft PR, 17 October 2026; builds on the input
  screens PR):**
  - [`user-testing.md`](user-testing.md): who to recruit (a mix of
    subfields and confidence with statistics), a 20-minute session script
    (bring your own study, think aloud, try all three routes), what to
    record, and how each problem becomes a test case;
  - [`test-cases.md`](test-cases.md): a template, with the
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
    ([`routing-prototype.md`](routing-prototype.md)).
- **Judgement-calls pack and small fixes (draft PR, 16 October 2026; builds
  on the routing-decisions PR):**
  - [`judgement-calls.md`](judgement-calls.md) collects every open
    question in one place, for the maintainer to decide in one session.
    Included:
    - `decision-tree.md`'s open questions and judgement calls;
    - the prototype's placeholder settings;
    - the routing decisions left by PRs #21 and #22;
    - the questions raised by the sourcing (E45 and PITS, the dyadic
      wording, hints whose details differ from their sources);
    - links to [`phase-3b-questions.md`](phase-3b-questions.md).

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
    ([decisions](decisions.md), 16 October 2026);
  - the routing audit now says test-retest answered "Twice" reaches E41
    (F11) and IRT reaches E37 (F7); E37 says IRT designs aren't covered.
    Routing unchanged;
  - every claim in [`card-sources.md`](card-sources.md) now has a source,
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
    table in [`decision-tree.md`](decision-tree.md);
  - every technical term in "What you would enter" has a plain-English
    hint, collected in [`glossary.md`](glossary.md);
  - other defensible analyses for each covered card are drafted in
    [`routing-audit.md`](routing-audit.md), with a card note that stays off
    until decided (open question 20);
  - every factual claim on a card has its source recorded in
    [`card-sources.md`](card-sources.md). 51 claims were unsourced at
    merge, including the 42 glossary definitions (now sourced: see the
    entry above);
  - the safety-net card lists what to write down for a statistician;
  - an accessibility pass (axe-core: no violations on ten screens at
    desktop and phone width; focus moves to each new screen). What wasn't
    checked is listed in [`routing-prototype.md`](routing-prototype.md);
  - walkthroughs re-run, with before/after notes for every changed card.
- **Routing fixes from the walkthroughs (merged in PR #21, 16 October 2026):**
  - fixes F1–F3, F5, F9, F13 and F14 from [`walkthroughs.md`](walkthroughs.md),
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
  [`walkthroughs.md`](walkthroughs.md) gives an example study for each of
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
  - [`routing-audit.md`](routing-audit.md) traces 29 designs through all
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
  - Three new judgement calls in [`decision-tree.md`](decision-tree.md),
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
  ([decisions](decisions.md), 15 October 2026). The `validate_spec()` bug
  it reported (a null SD crashed with "non-character argument") is fixed.
- **Goal and coverage:** the maintainer's goal is stated in the
  [build guide](build-guide.md) overview. [`coverage.md`](coverage.md)
  lists every user-facing capability of Superpower, Spower, power4mome,
  InteractionPoweR and G*Power, with powerkit's status and proposed tiers.
  The tiers are for the maintainer to confirm, and the G*Power rows still
  need checking against the G*Power manual.
  A section on needs the five tools don't cover (crossed participants and
  stimuli, multilevel, longitudinal, SEM, sequential and Bayesian designs,
  equivalence, precision, bias-corrected and replication planning, several
  outcomes, ordinal outcomes) lists candidate tools for each, checked
  against their own package sources.
- **Decision tree (draft):** [`decision-tree.md`](decision-tree.md) is a
  draft spec of how an app user gets from their study to a power analysis,
  for phase 5. It covers how G*Power, Superpower, Spower, power4mome,
  InteractionPoweR and PAMLj route users; a question tree mapped to the
  spec schema, with end points E1 to E42; the judgement calls where
  methodologists disagree, left undecided; and open questions. All of it
  is a proposal for the maintainer to confirm. It builds on
  [`design-finder.md`](design-finder.md), whose status labels are now up
  to date. The flowcharts, including a single full chart for
  presentations, are rendered in
  [`figures/decision-tree/`](figures/decision-tree/).
  Section 4 proposes how to handle studies with several hypotheses: an
  optional guided "plan my whole study" route (variables defined once,
  one card per analysis, the combined N for the primary analyses, and
  warnings when effect sizes contradict each other), two approaches to
  consistency (per hypothesis, or whole-study simulation) left
  undecided, and a worked example.
- **Coverage:** [`coverage.md`](coverage.md) now also has rows for ANCOVA
  (including pre–post), covariates in mediation, mediation with a
  multi-category X, moderation with a 3+ group X or W, and several
  hypotheses in one study.
- **Validation on GitHub:** the `full-validation` workflow works: after a
  setup fix (PR #11), the basic chunk passed there on 15 October 2026
  (20 PASS, 4 SKIP for TODO published values), matching the earlier
  Windows runs ([validation log](validation-log.md)).
- **Known risk, time limit:** process_7 and process_14 finish about 45
  minutes inside the GitHub time limit (4 h 47 m against the script's
  5 h 30 m stop). If either ever runs out of time, the fix is to split
  that chunk (for example, the direct-call and Type I error tests as
  separate chunks).
- **Memory:** mediation and moderated-mediation simulations run in batches
  of at most 200 replications, so they no longer need more memory than an
  ordinary laptop has (an unbatched 10,000-replication run did). The
  validation can also run on GitHub, one chunk at a time
  ([validation log](validation-log.md), "Running the full validation on
  GitHub").

## What's next

1. Rerun the `basic` validation chunk on the pwr default (17 October 2026).
   Decide how E10–E14 run in the app ([`phase5-simulations.md`](phase5-simulations.md),
   questions 1–4); then wire them.
1. The remaining published values for every design (the maintainer
   transcribes them), and validation with three or more mediators for
   parallel and serial mediation (open question 10 in
   [`decision-tree.md`](decision-tree.md)).
2. Simulation versions of the 2 x 2 ANOVA Type I error tests (build guide,
   section 6, open items).
3. Binary X and W in regression interactions and mediation (phase 3b,
   build guide section 8). It comes next after phase 3 closes, before
   phase 4. The maintainer has decided its effect-size convention, group
   split and handling of correlated predictors. The decisions still open
   before coding are listed in [`phase-3b-questions.md`](phase-3b-questions.md).
4. Consider independent cross-checks for parallel, serial and moderated mediation.
   Send (or edit) the draft message to Shu Fai Cheung in [`upstream-questions.md`](upstream-questions.md).
5. Confirm the proposed tiers in [`coverage.md`](coverage.md), and check
   its G*Power and MorePower rows against the G*Power manual and the
   MorePower paper.
6. The rest of phase 4: the methods paragraph and preregistration text;
   the method-paper and powerkit entries in `engine/inst/citations/refs.bib`
   (the maintainer adds them); and, once phase 3b lands, scripts for
   binary X and W.
7. Decide the open questions collected in [`judgement-calls.md`](judgement-calls.md),
   including whether to name PITS on E45 (A1), and the partly sourced hints
   in [`card-sources.md`](card-sources.md). Decide what to do about the
   remaining walkthrough flags (in
   [`walkthroughs.md`](walkthroughs.md)), and the routing audit's open items: the screening wording and
   open questions 16–19 in [`decision-tree.md`](decision-tree.md), and the
   remaining misroutes listed in [`routing-audit.md`](routing-audit.md).
8. Run the first round of user testing ([`user-testing.md`](user-testing.md))
   and log what it finds in [`test-cases.md`](test-cases.md).
9. Phase 5: the Shiny app, starting from the routing prototype's
   `app/routing/tree.yaml` and guided by [`decision-tree.md`](decision-tree.md)
   and [`design-finder.md`](design-finder.md), once the maintainer has
   answered their open questions.
