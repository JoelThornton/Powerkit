# Judgement calls: decided

*Moved here from [`judgement-calls.md`](../judgement-calls.md) on 18
October 2026, so that file holds only open questions. Each decision is
also recorded, dated, in [`decisions.md`](../decisions.md). Links inside
these entries are relative to `docs/`.*

### A2. E45 says "No ready-made tool", but PITS exists

**Decided 17 October 2026** (`decisions.md`): E45 now says "A recently
released package addresses the known-breakpoint case; powerkit hasn't
checked it." PITS isn't named on the card while A1 (open question 18) is
open; it is recorded in `card-sources.md` and `decision-tree.md`. Still
open: whether to name it (A1). E45's autocorrelation point (A6) was
decided later the same day. The entry is kept below as the record of the
options.


- **Question:** E45 (segmented regression, interrupted time series) says
  there is no ready-made tool. The CRAN package PITS 0.1.0 estimates
  power for interrupted time series by simulation, with a known
  breakpoint, a level change, a slope change and AR(1) autocorrelation
  (opened). What should E45 say?
- **Options:**
  - keep "No ready-made tool";
  - name PITS for a known breakpoint (with A1's wording rule);
  - split the card: known breakpoint (a tool exists) and estimated
    breakpoint (no ready-made tool found);
  - say "Established tools exist" (A1's neutral sentence).
- **What tools and sources do:**
  - PITS `calculate_power()` takes `n_pre`, `n_post`, `level_change`,
    `slope_change`, `sigma` and `rho` in [0, 1) (manual) (opened).
  - It doesn't cover a breakpoint estimated from the data, or negative
    autocorrelation.
  - chngpt tests an estimated change point with Monte Carlo or bootstrap
    p-values and has a data simulator, but no power function (opened).
- **Who might disagree, and why:**
  - PITS is new (version 0.1.0) and powerkit hasn't checked it. Some
    would wait for a track record before naming it.
  - Others would say the card is now inaccurate and should change.
- **Knock-on effects:**
  - Ties to A1 (naming tools) and to open question 17 (whether E45 and
    E35 share a card).
  - `coverage.md` has no PITS row yet.
  - `card-sources.md` marks the claim "contradicted".
- **Recorded in:** [`card-sources.md`](../card-sources.md), "Contradictions"
  (16 October 2026). No setting yet.

### A9. "Exact (analytic)" for Superpower's `ANOVA_exact()` (E7, E8)

**Decided 17 October 2026** (`decisions.md`): the cards now say "Exact
dataset (no repeated simulation)", following Superpower's help. The entry
is kept below as the record of the options.


- **Question:** E7 and E8 give the default method as "Exact (analytic)",
  and Q-test offers "Exact (analytic) or simulation". Superpower's
  documentation doesn't call `ANOVA_exact()` analytic. Keep the label, or
  reword it?
- **Options:**
  - keep "Exact (analytic)";
  - use Superpower's own terms, for example "Exact data set" or "Exact
    (one data set matching your inputs)";
  - name the function only.
- **What tools and sources do** (opened):
  - Superpower 0.2.4.1, `ANOVA_exact`: "Simulates an exact dataset (mu,
    sd, and r represent empirical, not population, mean and covariance
    matrix)".
  - The vignette: it "simulates one dataset that exactly matches the
    desired properties" and runs a single ANOVA on it.
  - Superpower uses "Analytic power calculation" for other functions, for
    example `power_oneway_between()`.
  - `conventions.md` describes the method in Superpower's terms.
- **Who might disagree, and why:**
  - "Analytic" signals to users that no random simulation error is
    involved, which is true of the result.
  - Others would keep to the package's own vocabulary, so that the card,
    the methods paragraph and the package documentation agree.
- **Knock-on effects:**
  - The Q-test card note and the method line change together.
  - The methods paragraph (phase 4) should use the same term.
  - `card-sources.md` marks the claim "contradicted".
- **Recorded in:** [`card-sources.md`](../card-sources.md), "Contradictions".
  No setting.

### B4. Defaults for alpha and target power (judgement call 3.6)

**Decided 18 October 2026** (`decisions.md`, "The new design"):
alpha is pre-filled at .05 (two-sided), with a reason asked only if it
is changed. Target power has no silent default: the inputs screen shows
.80 and .95 side by side with the N each needs and asks which and why.
None of the setting's four options matches this exactly, so
`alpha_power_defaults` in `tree.yaml` has a fifth, `as_built`, which
records this (22 October 2026). The entry is kept below as the record of the options.


- **Question:** should alpha and target power have defaults, and which?
- **Options:**
  - blank (the user enters both);
  - pre-filled .05 and .80;
  - pre-filled .05 and .80, with a required reason;
  - pre-filled .05 and .90.
- **What tools and sources do:**
  - Cohen's .80 convention: Perugini et al. report it (opened); Cohen
    (1988) itself is second-hand.
  - "Redefine statistical significance" and "Justify your alpha"
    (second-hand).
  - Superpower `optimal_alpha()` and Spower's compromise analysis justify
    alpha (`coverage.md`).
- **Who might disagree, and why:**
  - Defaults are convenient and conventional.
  - The "justify, don't default" view sees them as a nudge to stop
    thinking.
  - Registered Report formats often ask for higher power (exact
    requirements unchecked).
- **Knock-on effects:**
  - The build guide's no-defaults stance on effect sizes may be read as
    applying here too.
  - Changes the forms in phase 5.
- **Recorded in:** `decision-tree.md` 3.6; open question 5; setting
  `alpha_power_defaults`.

### G4. Which outputs the methods paragraph must report

*Decided by the maintainer, 18 October 2026: the methods paragraph states the test and its sides; alpha; the target power and the user's reason for it; the effect size with the user's reasoning, word for word; N in total and per group, with the power reached at that N; the backend, its version and function; the seed and the number of simulations where power is simulated; and the departures. It leaves out the noncentrality parameter and critical value: a reader can repeat the calculation from the inputs, most backends don't return them, and computing them would be new maths. A short version for the paper; a full one for a supplement or preregistration ([`decisions.md`](../decisions.md), 18 October 2026).*

- **Question:** which of a result's outputs does the methods paragraph
  (phase 4, still a placeholder) have to state?
- **Options (each separately):** the test and its tails; alpha; target
  power; the effect size, its format and where it came from; required or
  given N (total, per group, after attrition); the actual power at the
  reported N; the backend, its function and version; the method (formula
  or simulation, with replications, seed and the Monte Carlo interval);
  any departures; the noncentrality parameter, critical value and df
  where the backend returns them.
- **What tools and sources do:** CLAUDE.md requires every result to
  record the spec hash, seed, backend, and R and package versions, and
  every departure to be stated in the methods paragraph (opened).
  pwr's results carry the arguments, power, "method" and "note"; none of
  powerkit's backends returns a noncentrality parameter or critical
  value for E1–E6 or E9–E14 ([`gpower-parity.md`](gpower-parity.md)).
  What G\*Power's output shows needs the maintainer's screenshots.
- **Who might disagree, and why:**
  - Reviewers used to G\*Power reports look for the noncentrality
    parameter and critical value.
  - A long paragraph is copied less faithfully; a short one can drop
    the effect-size justification.
- **Knock-on effects:** `export_script()` and the methods text; which
  outputs need to be added to the result object.
- **Recorded in:** this entry; [`gpower-parity.md`](gpower-parity.md).

### G5. Showing the actual power at the rounded N

- **Question:** when powerkit reports a required N, does it also show the
  power that N actually gives (which is at or just above the target)?
- **Options:**
  - show it next to the required N;
  - show it only in the details or the exported script;
  - don't show it.
- **What tools and sources do:** G\*Power reports an actual power with the
  sample size (maintainer's list; screenshot to confirm). powerkit's
  result already holds it for exact results: the `curve` has the power
  at every N searched, including the one reported (`run_spec()` help).
  For simulation it is an estimate with its own Monte Carlo error.
- **Who might disagree, and why:**
  - Showing it helps users see how much rounding to whole people (and
    to equal groups) added.
  - For simulated results, a second number with its own interval can
    confuse more than it helps.
- **Knock-on effects:** the result screen's headline (B12, N rounding);
  the methods paragraph (G4).
- **Decided (maintainer, 17 October 2026):** show it on the result
  screen, labelled plainly ("With 64 per group, power is 80.1%."). Shown
  for exact results; not for a simulated N, which has no simulation at
  exactly that N (powerkit's default). `decisions.md`, 17 October 2026.
- **Recorded in:** this entry; [`gpower-parity.md`](../gpower-parity.md).

### G6. The method for correlations (E4), and for two proportions (E5)

- **Question:** E4's default is now pwr's formula, which uses Fisher's z.
  G\*Power uses the exact distribution below N = 10,000 by default
  (maintainer). Match G\*Power, or keep pwr and record a departure? The
  same question arises for E5, where pwr uses Cohen's h (the arcsine
  transformation) rather than a z test.
- **What pwr's help says:** `pwr.r.test()`: "These calculations use the
  Z' transformation of correlation coefficient: Z'=arctanh(r) and a bias
  correction is applied"; its source takes the critical value from the t
  distribution and the power from the normal approximation to Fisher's z
  (opened). `pwr.2p.test()` and `pwr.2p2n.test()` take Cohen's h
  (`ES.h()`).
- **Size of the difference, E4** (two-sided, alpha .05; pwr 1.3-0 against
  pwrss 1.3.3's `power.exact.onecor()`, which its help describes as the
  exact method of Barabesi and Greco (2002), "validated using G\*Power";
  not checked against G\*Power itself here):

  | N | r = .3: pwr | exact | r = .4: pwr | exact | r = .5: pwr | exact |
  | --- | --- | --- | --- | --- | --- | --- |
  | 20 | 0.2559 | 0.2539 | 0.4302 | 0.4303 | 0.6379 | 0.6417 |
  | 30 | 0.3712 | 0.3705 | 0.6075 | 0.6092 | 0.8250 | 0.8277 |
  | 40 | 0.4773 | 0.4774 | 0.7405 | 0.7423 | 0.9218 | 0.9228 |
  | 50 | 0.5716 | 0.5722 | 0.8339 | 0.8352 | 0.9670 | 0.9672 |
  | 60 | 0.6531 | 0.6540 | 0.8965 | 0.8972 | 0.9867 | 0.9866 |
  | 70 | 0.7222 | 0.7230 | 0.9369 | 0.9373 | 0.9948 | 0.9947 |
  | 80 | 0.7797 | 0.7804 | 0.9623 | 0.9624 | 0.9981 | 0.9980 |
  | 90 | 0.8267 | 0.8273 | 0.9778 | 0.9778 | 0.9993 | 0.9992 |
  | 100 | 0.8648 | 0.8652 | 0.9872 | 0.9871 | 0.9997 | 0.9997 |

  Largest difference 0.0038 (N = 20, r = .5). One-sided, the largest at
  N = 20, 50 and 100 was 0.0047 (N = 20, r = .5). Required N for 80%
  power: r = .3, pwr 85 (84.07 rounded up), exact 84; r = .4, 46 and 46;
  r = .5, 29 and 29. So powerkit's E4 can report one more participant
  than G\*Power at r = .3, and its power can differ in the third decimal,
  which the 3-decimal validation against G\*Power's published values
  would catch.
- **Size of the difference, E5** (two-sided, alpha .05, equal groups;
  pwr against pwrss's `power.z.twoprops()`, a normal-approximation z test,
  "validated via G\*Power and PASS documentation"; whether G\*Power's z
  test pools the variance is to confirm from a screenshot): with p1 = .10,
  p2 = .25, power 0.248 vs 0.235 at 20 per group and 0.523 vs 0.506 at 50
  (largest gap 0.018); required N for 80% power 97 vs 100 per group. With
  p1 = .30, p2 = .50 the gap is at most 0.008 and the N is 93 for both.
- **Options:**
  - keep pwr and record the difference as a departure (convention rules:
    `conventions.md`, results screen, methods paragraph, a test showing
    its size);
  - match G\*Power with an exact method from a backend that has one (for
    E4, pwrss `power.exact.onecor()`, not a foundation tool when this was written (it became one on 17 October 2026, for E5's unequal groups); or Spower's
    simulation, which estimates the exact test's power with Monte Carlo
    error);
  - keep pwr for E4 only below some size of difference, and switch for
    E5 (or the reverse).
- **Who might disagree, and why:**
  - Users checking powerkit against G\*Power will see different third
    decimals and, sometimes, one more participant.
  - pwr's help gives Cohen (1988) as the source of its formulas.
- **Knock-on effects:** Departure 9's wording; the G\*Power published-value
  tests for E4 and E5; the card's method line.
- **Decided (maintainer, 17 October 2026):**
  - E4: keep pwr's Fisher's z, recorded as Departure 10 in
    [`conventions.md`](../conventions.md) and shown on the card and the
    result screen.
  - **Checked against the G\*Power manual (17 October 2026):** the
    manual (June 1, 2023, section 3, pp. 9–10) confirms the exact method
    (Barabesi and Greco, 2002) with "Use exact distribution if N <:
    10000". pwrss's `power.exact.onecor()`, the reference used above,
    reproduces both of the manual's examples (N = 1928; power 0.482927),
    so the sizes in this entry are sizes against G\*Power's method. The
    manual has no section for E5's z test, so E5 still needs a
    screenshot.
  - E5: the default should be the z test (or chi-square) most
    psychologists run, not the arcsine. Base R's `power.prop.test()` is to
    be checked against G\*Power's "Two independent groups: inequality,
    z-test" first; the switch waits for the maintainer's yes.
  - **Checked against G\*Power screenshots (17 October 2026):** G\*Power
    3.1.9.7's "Proportions: Difference between two independent
    proportions" (z tests), with its default options (no continuity
    correction, no arcsine transformation), equals
    `power.prop.test(strict = TRUE)` to seven decimals: 0.2344921 at 20
    per group (p1 = .10, p2 = .25); 164 per group for 95% power, actual
    power 0.9502464. `strict = FALSE` gives 0.2339595, so G\*Power counts
    both tails. With N2/N1 = 2 G\*Power gives 123 + 247; `power.prop.test()`
    can't do unequal groups. Details: [`gpower-parity.md`](../gpower-parity.md), E5.
- **Recorded in:** this entry; [`gpower-parity.md`](../gpower-parity.md);
  [`coverage-roadmap.md`](../coverage-roadmap.md), note 1. The comparison
  scripts are in the PR description.

### G7. A multiple-testing correction by default

**Decided 18 October 2026** (`decisions.md`, "The new design"): no
correction by default. The start screen asks what the claim rests on;
only "any of several" (disjunction) corrects alpha, by Bonferroni in v1
(alpha divided by the number of tests, with the reason shown), with Holm
later if wanted. "Several claims, each standing on its own" and "all of
several" get no correction, as Rubin (2021) argues. Because the user
chooses the claim, this follows the tools checked (none corrects by
default) rather than departing from them. Still open under B6: power for
"all of several" beyond guidance, and the guided route's study-level
result. The entry is kept below as the record of the options.


- **Question:** when a user plans more than one test, should powerkit
  apply an alpha correction (for example Bonferroni) by default, or
  only when the user says the claim rests on "at least one" result?
- **Options:**
  - no correction by default; offer one only for "at least one"
    (disjunction) claims (B6);
  - no correction by default, but always show what a correction would do
    to N;
  - a correction by default whenever there is more than one primary test,
    which the user can turn off with a reason;
  - leave it to the user, with no prompt (as now: the user can lower
    alpha by hand).
- **What tools and sources do:**
  - Rubin (2021) (opened, author preprint): "researchers only need to
    adjust their alpha level when they undertake disjunction testing of a
    joint null hypothesis" (p. 17). His conclusion: "researchers should be
    cautious about applying default corrections for multiple testing in
    relation to studywise and multiway ANOVAwise families of hypotheses"
    (p. 22).
  - Rubin (2024) (opened) calls a default correction "the alpha adjustment
    ritual": "the automatic adjustment of alpha levels whenever multiple
    testing occurs, regardless of whether statistical inferences are made
    about individual null hypotheses or intersection null hypotheses"
    (p. 4). If a researcher corrects but makes only individual inferences,
    "they will have lowered the power of their individual tests for no
    good reason" (p. 4). He reports, from García-Pérez (2023)'s review of
    109 articles (second-hand), that such corrections "are very common"
    (p. 4).
  - Frane (2019) (verified, maintainer: the reference only; Frane's text
    not read). As printed in Rubin (2024)'s reference
    list: "Frane, A.V., 2019. Misguided opposition to multiplicity
    adjustment remains a problem. J. Mod. Appl. Stat. Methods 18 (2),
    eP2836. https://doi.org/10.22237/jmasm/1556669400." The title
    indicates the opposite position. Rubin (2024, p. 1) cites it only for
    the phrase "anti-adjustment article"; he doesn't summarise it.
  - Rubin's blog post on redundant corrections
    (markrubin.substack.com/p/redundant-multiple-testing-corrections)
    could not be fetched: the proxy refused the host (403). Not used.
  - Tools: Superpower 0.2.4.1 `ANOVA_power()` has `p_adjust = "none"` and
    `emm_p_adjust = "none"` as defaults (`man/ANOVA_power.Rd`, opened);
    power4mome 0.2.1 `rejection_rates()` defaults to `collapse = "none"`
    ("tests will be summarized individually") (opened); powertools 1.0.0
    `altprimary()` applies no correction itself: "To use a Bonferroni
    correction for multiple comparisons, specify alpha as the desired
    familywise error rate (FWER) divided by K" (opened). pwr 1.3-0 has no
    correction argument (opened). So no default correction was found in
    the tools checked.
- **Who might disagree, and why:**
  - Reviewers and methodologists who correct by default would want it on.
  - Those following Rubin would see a default correction as wrong for
    individual and conjunction testing, and as a needless cost in N
    ("an unjustifiable loss of statistical power", Rubin, 2024, p. 4).
  - A default is a nudge either way; asking the inference question (B6)
    avoids a default but adds a step.
- **Knock-on effects:** B6 (the inference question); D4 and D6; the
  methods paragraph must say whether a correction was applied and why.
  A correction by default would be a departure from the tools checked
  (none corrects by default), so under CLAUDE.md it would need an entry
  in `conventions.md`, a note on the results screen and a test showing the
  size of the difference.
- **Recorded in:** this entry; B6; roadmap row C1;
  [`inference-question-design.md`](../inference-question-design.md).
- **E7 and E8 now** (recorded 17 October 2026): E7 (2 x 2 between) and E8
  (2 x 2 mixed ANOVA, via Superpower) report power for **one** effect the
  user chooses (factor A, factor B or the interaction), at the alpha the
  user enters, with **no ANOVA-wise correction**. This is consistent with
  individual testing in Rubin (2021) (opened, author preprint). On
  multiway ANOVAs he writes: "it is unlikely that researchers would ever
  have reasonable grounds for adjusting their alpha to compensate for
  multiple testing in a multiway ANOVA" (p. 21). Endnote 9 gives the
  exception: corrections "may be necessary in multiway ANOVAs when a
  factor contains more than two levels and multiple comparisons are
  conducted between those levels" (p. 31). E7 and E8 have two levels per
  factor. Where seen:
  - `engine/inst/schema/design.schema.json:215`: `target_test` is "The
    one effect the power analysis is about"; lines 944–948: `effect` is
    one of `main_effect_A`, `main_effect_B`, `interaction`;
  - `app/routing/forms.yaml:262–265` (E7) and `:303–306` (E8): one
    "Which effect" choice;
  - `engine/R/backend-superpower.R:73–74`: alpha is
    `spec$target_test$alpha`, unchanged, and one effect is selected;
  - `engine/R/backend-superpower.R:82–88`: `ANOVA_power()` is called
    without `p_adjust` or `emm_p_adjust`, so Superpower's defaults
    (`"none"`, `man/ANOVA_power.Rd` lines 11 and 18) apply; line 89 reads
    one effect's power;
  - `engine/R/backend-superpower.R:106–108`: `ANOVA_exact(design,
    alpha_level = inputs$alpha, verbose = FALSE)`, then one effect's row.
    `ANOVA_exact()` has no `p_adjust` argument (`man/ANOVA_exact.Rd`
    usage), and its source uses `adjust = "none"` for emmeans comparisons
    (`R/ANOVA_exact.R` lines 286–288; powerkit sets no `emm` option).
  - No call to `p.adjust()`, and no Bonferroni code, was found in
    `engine/R/` or `app/` (search for "p.adjust", "p_adjust",
    "bonferroni"). The only mention is a card note in
    `app/routing/tree.yaml:1342` for the guided route's "any one" choice.

### G8. Alpha and the number of tails as required inputs, with a reason

**Decided 18 October 2026** (`decisions.md`, "The new design"):
alpha .05 and a two-sided test stay pre-filled, labelled with their
source, and a reason is asked only if either is changed (it goes into
the write-up). Target power has no silent default (B4). Still open:
whether to ask "Do you predict a direction?" instead of the silent
two-sided default (B18),
and B3 (one-sided tests). The entry is kept below as the record of the
options.


- **Question:** should alpha and one- or two-sided be inputs the user
  must set, each with a short justification (as the effect size already
  has, `effect_justification`)?
- **Options:**
  - keep them pre-filled from the wrapped tool's default (.05, two-sided),
    labelled with its source (as now, `app/routing/forms.yaml`
    `tool_defaults`);
  - pre-filled, with a required reason if kept or changed (B4's third
    option);
  - blank and required, with a required reason;
  - required, with a reason field that is optional but goes into the
    methods paragraph when filled in.
- **What tools and sources do:**
  - Lakens et al. (2018), "Justify your alpha"
    (doi:10.1038/s41562-018-0311-x) (still not opened). The repo's
    `decision-tree.md` 3.6 summarises it second-hand: every design choice,
    alpha included, should be justified rather than set by convention.
    Two supplied papers describe it the same way (second-hand):
    - Uttley (2019, *LEUKOS*, doi:10.1080/15502724.2018.1533851; opened):
      "Other researchers suggest that this is unwise and that instead we
      should justify all experimental design and analytical choices made,
      including the P-value threshold used to identify a real effect
      (Lakens et al. 2018)" (p. 144), and "the choice of alpha to use
      should not be inflexible (Lakens et al. 2018)" (p. 158);
    - Rubin (2024, *Methods in Psychology*; opened) lists, among ritual
      habits, to "use a conventional alpha level when an alternative
      unconventional alpha level is more appropriate (Lakens et al.,
      2018)" (p. 7).
    The summary still hasn't been checked against the paper itself.
  - Rubin (2021, author preprint; opened) separates choosing alpha from
    correcting it: "In every significance testing situation, researchers
    need to specify their alpha level in the context of a range of
    external background factors" (p. 13), including "the theoretical
    and/or practical costs of Type I and Type II errors, the smallest
    effect size of interest, the sample size, and the variability in the
    data" (p. 13). He calls this "alpha specification", "quite different
    from" alpha adjustment for disjunction testing (p. 13).
  - On tails: Rubin (2024, p. 7) also lists, as a ritual habit, to "use a
    two-sided test when a one-sided test is more consistent with one's
    statistical inference (Georgiev, 2018; Rubin, 2022)". Uttley (2019,
    p. 157) found that "Justification for use of a one-tailed test was
    also absent in nearly all reviewed papers", and gives the size of the
    difference in one case: power "is 0.15 for a one-tailed dependent
    t-test. This reduces to 0.09 when a two-tailed t-test is used", for
    "a group sample size of 20 and an effect size of 0.2".
  - G\*Power asks for the number of tails (B3, opened); its alpha is
    pre-filled (to confirm from screenshots).
  - pwr 1.3-0, Spower 0.7, Superpower 0.2.4.1 and InteractionPoweR 0.2.4
    all default alpha to .05 (`forms.yaml` `tool_defaults`, read from the
    installed packages' signatures). Superpower's `optimal_alpha()` and
    Spower's compromise analysis justify alpha by error-rate trade-offs
    (`coverage.md`).
  - The schema has no field for a reason for alpha or for tails:
    `target_test.alpha` and `target_test.alternative`
    (`engine/inst/schema/design.schema.json:234–247`) are bare values.
- **Who might disagree, and why:**
  - Requiring a reason for .05 slows down most users, whose reason is
    "convention".
  - The "justify, don't default" view sees a pre-filled .05 as a nudge to
    stop thinking.
  - Some would accept a reason only for departures from .05 and two-sided
    (which B3 already does for one-sided tests, if a preregistration note
    is chosen).
- **Knock-on effects:** a schema change (a reason field, perhaps
  `target_test.alpha_justification` and `target_test.alternative_justification`);
  B3 and B4 (they become parts of this choice); the methods paragraph; the
  inference question (B6), since a disjunction claim changes alpha.
- **Recorded in:** this entry; B3; B4; settings `alpha_power_defaults`
  and `one_sided_tests`.

### G9. Sensitivity analysis: first-class, or the default when no effect size can be justified

**Decided 18 October 2026** (`decisions.md`, "The new design"): both.
Sensitivity ("the smallest effect you could detect" on screen; the
technical term only in the write-up) is a first-class route: the start
screen's "My sample size is fixed" leads to it, showing the smallest
detectable effect at .80 and .95 power and asking whether an effect that
size is plausible, or worth caring about, in the user's field. "I can't
justify an effect size", when N isn't fixed, shows the smallest
detectable effect across a range of N (a sensitivity curve) at .80 and
.95, rather than forcing the fixed-N route. Built first for E1–E6 (PR
#56), then E7–E8 in the app; interactions are decided after the basic
tests, and mediation goes to the R script. The entry is kept below as
the record of the options.


- **Question:** should "the smallest effect you could detect at a given
  N" (sensitivity) be a goal on an equal footing with "the sample size
  you need", and should it become the route when the user can't justify
  an effect size?
- **Options:**
  - as now: three goals, with sensitivity only where the engine can run it
    (E7, E8), and an effect size always required;
  - first-class: sensitivity offered for every end point, shown alongside
    the a priori result;
  - the default when no effect size can be justified: if the user can't
    give a source for an effect size, offer a sensitivity analysis (at the
    N they can get) instead of asking for a number;
  - both of the above.
- **What tools and sources do:**
  - Lakens (2022), "Sample Size Justification"
    (doi:10.1525/collabra.33267) (published abstract opened via Crossref;
    body read in the author's revised manuscript, not the published
    version):
    - published abstract: researchers could consider "which ranges of
      effects a study has sufficient power to detect based on a
      sensitivity power analysis";
    - revised manuscript, line 736: "A sensitivity power analysis fixes
      the sample size, desired power, and alpha level, and answers the
      question which effect size a study could detect with a desired
      power.";
    - line 750: "For a sensitivity analysis to be meaningful, the
      sensitivity curve should be compared against a smallest effect size
      of interest, or a range of effect sizes that are expected.";
    - line 932: "Alternatively, if no smallest effect size of interest was
      specified when designing the study, researchers can report a
      sensitivity power analysis.";
    - line 414, on studies with no justification: "It is still possible to
      discuss the smallest effect size of interest, the minimal
      statistically detectable effect, the width of the confidence
      interval around the effect size, and to plot a sensitivity power
      analysis, in relation to the sample size that was collected."
  - Rubin (2024, *Methods in Psychology*; opened) lists, among ritual
    habits, to "conduct an a priori power analysis when there is no clear
    basis for an effect size estimate and a sensitivity power analysis is
    more appropriate (Lakens, 2022; Perugini et al., 2018)" (p. 7). This
    is one published view in favour of the "default when no effect size
    can be justified" option. It is Rubin's reading of Lakens (2022), so
    second-hand for Lakens.
  - Mikael Rubin (2025, *International Journal of Psychology*,
    doi:10.1002/ijop.70017; opened): "the researcher needs to evaluate the
    impact of the effect size on power, either by exploring a range of
    effect sizes or by determining the sample size needed to achieve power
    for the smallest effect size of interest (Anvari and Lakens 2021)"
    (p. 2). In his conclusions: "power analyses should be reported as
    ranges of effect sizes, power and sample sizes. This is not the
    standard in the field" (p. 14 of 15).
  - Uttley (2019, *LEUKOS*, doi:10.1080/15502724.2018.1533851; opened),
    as an alternative to an effect size from the literature: "state the
    minimum effect size that you are willing to accept as detectable with
    your study or to assess what the minimum effect size would be for it
    to be meaningful and not trivial (the smallest effect size of
    interest; Albers and Lakens 2018)" (p. 158).
  - G\*Power offers sensitivity as one of five analysis types (B5, opened,
    manual p. 2).
  - Spower sets the type by which argument is `NA` (B5, opened);
    Superpower and power4mome have sensitivity or effect-size search
    functions (`coverage.md`); powerkit runs sensitivity for E7 and E8
    only (B5; roadmap C11).
  - The schema's `effect_justification.type` has four values
    (`smallest_effect_of_interest`, `meta_analysis`, `prior_study`,
    `pilot_study`) and no "can't justify one"
    (`engine/inst/schema/design.schema.json:163–178`).
- **Who might disagree, and why:**
  - Making sensitivity the default could let users skip the work of
    finding a smallest effect of interest. Lakens (revised manuscript,
    line 750) says the curve should still be compared with one.
  - Users asked for "the N I need" by an ethics board or funder want that
    number first.
  - Offering sensitivity everywhere needs engine work and validation for
    every end point (B5).
- **Knock-on effects:** B5 (analysis types) and setting `analysis_types`;
  B13 (a power curve); a new `effect_justification` option (schema change)
  if "can't justify" leads to sensitivity; validation of sensitivity for
  E1–E6 and E9–E14; the result wording (B11).
- **Recorded in:** this entry; B5; B13; roadmap C11.

### C9. Chi-square goodness-of-fit (judgement call 3.7)

**Decided 19 October 2026** (`decisions.md`): its own card, E48, on
pwrss's `power.chisq.gof()` (Cohen's w from `probs.to.w()`), reached from
Q3 (one group, outcome in several categories). The entry is kept below as
the record of the options.


- **Question:** one categorical variable against expected proportions has
  no answer and no end point. Extend E6, or give it its own card?
- **Options:**
  - extend E6 (a spec change; Spower's `p_chisq.test()` takes a
    probability vector), with the card explaining the degrees of freedom;
  - its own card: not in powerkit yet, use Spower's `p_chisq.test()`.
- **What tools and sources do:**
  - Spower's `p_chisq.test()` does both goodness-of-fit and independence
    (opened).
  - UCLA OARC lists "Chi-square goodness-of-fit" (opened).
  - G\*Power's single chi-square routine is the maintainer's recollection
    (second-hand).
- **Who might disagree, and why:**
  - Extending E6 keeps one card for one routine.
  - Its own card is honest until the spec supports it.
- **Knock-on effects:** a schema change and a validation test if E6 is
  extended.
- **Recorded in:** `decision-tree.md` 3.7; setting `chi_square_gof`.

### B3. One-sided tests (judgement call 3.3)

**Decided 22 October 2026** (`decisions.md`): as built: the basic tests ask first whether the hypothesis predicts a direction, and a one-sided test needs a reason, which goes into the write-up (decided 19 October 2026, B18). Setting `one_sided_tests`. The entry is kept below as the record of the options.

**See also B18** (18 October 2026): whether to ask "Do you predict a
direction?" instead of the silent two-sided default.

- **Question:** should a one-sided test require a preregistration note,
  and should it be offered beyond the basic tests?
- **Options:**
  - basic tests only, no note required;
  - basic tests only, preregistration note required;
  - more designs, preregistration note required.
- **What tools and sources do:**
  - G\*Power asks for the number of tails (opened).
  - Cho and Abe (2013) and Ruxton and Neuhäuser (2010) set conditions for
    one-tailed tests (second-hand).
  - A one-sided test counts only effects in the stated direction: Spower's
    own one-sided test since Spower 0.7 (before that, powerkit's
    Departure 4, now retired; `conventions.md`) (opened).
- **Who might disagree, and why:**
  - Some see one-sided tests as legitimate for directional hypotheses.
  - Others, including many journals, treat them as suspect unless
    preregistered (unsourced for journal policies).
- **Knock-on effects:**
  - Offering one-sided tests for more designs needs engine support and
    validation.
  - Q-dir is shown only on E1–E5 now.
- **Recorded in:** `decision-tree.md` 3.3; open question 5; setting
  `one_sided_tests`.

### B12. Rounding of N

**Decided 22 October 2026** (`decisions.md`): total and per group, as now. Setting `n_rounding`. The entry is kept below as the record of the options.

- **Question:** how is the required N rounded and reported?
- **Now:** the engine gives the smallest total N in steps that keep groups
  whole (even totals for two equal groups; multiples of 4 for a 2 x 2
  between design; with an allocation ratio, steps that keep both groups
  whole). The screen adds the size per group (or per cell). Nothing is
  rounded on the screen itself.
- **Options:** total and per group (as now); total only; per group first.
- **What tools and sources do:** G\*Power reports both a total and group
  sizes (unsourced here; to check in its manual).
- **Who might disagree, and why:** per-group numbers are what a recruiter
  plans with; the total is what a preregistration usually states.
- **Knock-on effects:** attrition (the recruitment target is reported
  separately once attrition is wired in).
- **Recorded in:** setting `n_rounding` (shown on the result screen).

### C11. Fisher's exact test reaching the large-sample tests (judgement call 3.9)

**Decided 22 October 2026** (`decisions.md`): offer the exact test: two proportions (E5) has Fisher's exact test as a test version, from pwrss's power.exact.fisher(); the chi-square test of independence (E6) doesn't have one yet. Setting `fisher_exact`. The entry is kept below as the record of the options.

- **Question:** Fisher's exact test reaches E5 or E6, which can be quite
  wrong with small expected counts. Offer the exact test, warn, or both?
- **Options:**
  - offer Spower's `p_prop.test(exact = TRUE)` as a test version;
  - warn about small expected counts;
  - both.
- **What tools and sources do:**
  - Spower's exact option (opened).
  - G\*Power's Fisher's exact test: confirmed in G\*Power 3.1.9.7's Tests
    menu (Proportions: "Two independent groups: Fisher's exact"), from the
    maintainer's list, 17 October 2026.
- **Who might disagree, and why:**
  - A warning needs a threshold for "small", itself a convention.
  - The exact test changes E5's spec and needs validation.
- **Knock-on effects:** spec, validation, and the Q-test card note on E5.
- **Recorded in:** `decision-tree.md` 3.9; setting `fisher_exact`.

### D4. The guided "plan my whole study" route (open question 11)

**Decided 22 October 2026** (`decisions.md`): yes: "Plan my whole study" stays. Setting `guided_route`. The entry is kept below as the record of the options.

- **Question:** keep the guided route? If so, is a study file that wraps
  several specs acceptable (a schema change)?
- **Options:**
  - yes;
  - no.
- **What tools and sources do:** no tool reviewed plans several analyses
  together (`decision-tree.md`, section 1) (opened).
- **Who might disagree, and why:**
  - It helps users with several hypotheses.
  - It adds scope, and a choice (individual, "at least one" or "all")
    that is itself contested (B6).
- **Knock-on effects:** D5–D7; the walkthroughs' guided runs.
- **Recorded in:** open question 11; setting `guided_route` (hides the
  route when "no").

### A4. Wording that points to another tool, and "never a simpler stand-in"

**Decided 22 October 2026** (`decisions.md`): use the proposed wording, and powerkit never routes to a simpler stand-in test; the cards that point to another tool already use it. Setting `not_in_spec_wording`. The entry is kept below as the record of the options.

- **Question:** confirm the wording "powerkit doesn't cover {analysis}
  yet. {package} does: see the link. powerkit can't check results from
  other tools." Also confirm the rule that powerkit never routes a design
  it doesn't cover to a simpler stand-in test.
- **Options:**
  - use the proposed wording;
  - revise it.
- **What tools and sources do:**
  - Established tools don't route to other tools (opened,
    `decision-tree.md`, section 1).
  - The stand-in rule generalises decision N2 (`decisions.md`) beyond
    2 x 2 main effects (opened).
- **Who might disagree, and why:**
  - Some users would rather have an approximate number from a simpler
    test than none.
  - The rule prevents that, on the view that a wrong number is worse
    than no number.
- **Knock-on effects:**
  - Interacts with A1 (whether to name tools at all) and with C10
    (rank-based tests, where an approximation is one of the options).
- **Recorded in:** open question 6; setting `not_in_spec_wording`.
