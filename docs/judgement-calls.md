# Judgement calls and open questions

*Last updated: 16 October 2026.*

Every open question about the routing prototype, in one place, for the
maintainer to decide in one session. **Nothing here is decided, and
nothing is recommended.** Where an option is listed first, that is only
the order it appears in its source document.

Entries are grouped by topic. The groups that change what users see come
first:

- A. What the cards say;
- B. What the cards and forms ask;
- C. Which card users reach;
- D. The routes and the start screen;
- E. Behind the scenes (spec, engine, docs).

Each entry gives:
- the question;
- the options;
- what established tools or sources do;
- who might disagree, and why;
- knock-on effects;
- where it is recorded.

Each entry also names its setting key in `app/routing/tree.yaml`, if it
has one; the prototype shows that setting as a placeholder on the screens
it affects.

**How sources are marked:**
- **(opened)**: the source was opened and read. Either it was opened on
  16 October 2026 (listed in [`card-sources.md`](card-sources.md),
  "Sources opened"), or it is tagged *read in full* or *read directly* in
  [`decision-tree.md`](decision-tree.md).
- **(second-hand)**: `decision-tree.md` tags it *seen second-hand, to
  verify*.
- **(unsourced)**: no source was found or checked.

"Who might disagree" is reasoning about the positions, not a report of
what named people have said, unless a source is given.

The statistical decisions phase 3b needs before coding are in
[`phase-3b-questions.md`](phase-3b-questions.md) and are only linked here
(E4).

## Contents

- [A. What the cards say](#a-what-the-cards-say): A1–A9
- [B. What the cards and forms ask](#b-what-the-cards-and-forms-ask): B1–B15
- [C. Which card users reach](#c-which-card-users-reach): C1–C18
- [D. The routes and the start screen](#d-the-routes-and-the-start-screen): D1–D7
- [E. Behind the scenes](#e-behind-the-scenes): E1–E5
- [F. Validation](#f-validation): F1

## A. What the cards say

### A1. Naming other tools on "not covered" cards

- **Question:** should cards for designs powerkit doesn't cover name other
  established tools (for example simr, or G\*Power's logistic and Poisson
  routines)? Now the generic cards (E43, E44, E46, E47) say only
  "Established tools exist for this design; powerkit hasn't checked them".
  Cards built from [`coverage.md`](coverage.md) already list its tools.
- **Options:**
  - name the tools, as `coverage.md` does;
  - the neutral sentence only, on every "not covered" card.
- **What tools and sources do:**
  - G\*Power, Spower, Superpower, InteractionPoweR and PAMLj don't
    point users to other tools (`decision-tree.md`, section 1) (opened).
  - The tools themselves exist and are documented (opened, see
    `card-sources.md`):
    - Hmisc `cpower()` and `spower()` (time-to-event);
    - Ackerman and Kenny's apimpower app (dyadic);
    - Spower `p_glm()` (factorial logistic regression);
    - PITS (interrupted time series).
- **Who might disagree, and why:**
  - Naming tools helps users act, but powerkit hasn't checked them, and a
    named tool reads as an endorsement.
  - The neutral sentence avoids that, but can read as unhelpful, or as
    hiding names that are easy to find.
- **Knock-on effects:**
  - Applies to the cards built from `coverage.md` too.
  - Naming tools means keeping the names current. PITS (CRAN, 30 June
    2026) appeared after E45 was written (A2).
  - Every named tool needs a source in `card-sources.md`.
- **Recorded in:** open question 18; setting `name_other_tools`.

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
- **Recorded in:** [`card-sources.md`](card-sources.md), "Contradictions"
  (16 October 2026). No setting yet.

### A3. A note on other defensible analyses

- **Question:** should covered cards say "Other defensible analyses exist
  for this design (e.g. ...), and they can need different sample sizes.
  Power the analysis you plan to run"? The per-card lists are drafts in
  [`routing-audit.md`](routing-audit.md), "Other defensible analyses".
- **Options:**
  - show the note on covered cards;
  - don't show it.
- **What tools and sources do:**
  - UCLA OARC's test-selection table says "Usually your data could be
    analyzed in multiple ways, each of which could yield legitimate
    answers" (opened).
  - The power tools themselves don't list alternatives
    (`decision-tree.md`, section 1) (opened).
- **Who might disagree, and why:**
  - Showing it is candid, and warns users that the sample size belongs to
    one analysis.
  - Not showing it avoids implying powerkit endorses each alternative, and
    avoids lists that users can't act on in powerkit.
  - The lists themselves are judgements. For example, ANCOVA vs change
    scores vs a mixed model is a long-running debate (unsourced here).
- **Knock-on effects:**
  - Some entries overlap judgement calls 3.4 (simple effects), 3.8 (rank
    tests) and 3.9 (Fisher's exact).
  - E15's list includes a latent-variable model "that allows for
    measurement error", although E15 no longer asks about reliability
    (decided 16 October 2026).
  - If shown, each list needs sources.
- **Recorded in:** open question 20; setting `other_analyses_note` (off
  while undecided).

### A4. Wording that points to another tool, and "never a simpler stand-in"

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

### A5. The dyadic card's wording (E44)

- **Question:** E44 says treating partners as independent "can overstate
  or understate power, depending on whether the predictor varies between
  dyads ... or within dyads". The opened source states it differently.
  Keep, reword, or shorten?
- **Options:**
  - keep the current wording;
  - reword it to follow Kenny: too many or too few significant results,
    depending on between or within dyads *and* on whether the partners'
    scores correlate positively or negatively;
  - drop the explanation and keep only "dyadic methods are needed".
- **What tools and sources do:** Kenny, "Dyadic Analysis", Topic 6
  (opened):
  - between-dyads predictor with a positive correlation: "too many Type I
    errors";
  - within-dyads with a positive correlation: "too few";
  - the reverse for a negative correlation;
  - mixed predictors fall in between.
- **Who might disagree, and why:**
  - "Power" is a plain-English simplification of the Type I error bias.
    Some will prefer the simpler word; others will want the source's terms.
  - Adding the sign of the correlation is more accurate, but longer.
- **Knock-on effects:**
  - `card-sources.md` marks the claim "partly sourced"; a rewording
    would change that.
  - Matched pairs (C2) also reach this card.
- **Recorded in:** [`card-sources.md`](card-sources.md) (E44, card text).
  No setting.

### A6. The segmented-regression card's points, and E45 vs E35

**Autocorrelation point decided 17 October 2026** (`decisions.md`): E45
now says "Autocorrelation makes standard power calculations wrong: too
optimistic when it's positive, too pessimistic when it's negative.",
sourced to Zhang, Wagner and Ross-Degnan (2011), Table 1. The
contradiction below is **resolved**; `card-sources.md` lists it under
"Contradictions" as resolved. Still open: the estimated-breakpoint point
and whether E45 and E35 share a card.

- **Question:**
  - Should E45's points stay as they are? Two are only partly supported:
    - "With a breakpoint that is estimated from the data, a custom
      simulation is needed";
    - "autocorrelation ... makes standard power calculations too
      optimistic".
  - And should E45 and E35 (growth curves, diary and panel studies)
    share one card?
- **Options:**
  - Card points: keep; reword to what the sources support; or remove the
    autocorrelation direction.
  - Shared card: keep two end points, or merge them into one "many
    measurements over time" card.
- **What tools and sources do** (all opened):
  - UCLA estimates a piecewise regression's cut point with nonlinear
    least squares.
  - chngpt uses bootstrap intervals and Monte Carlo or bootstrap
    p-values for an estimated threshold.
  - EnvStats notes that serial correlation can be positive or negative.
  - PITS models only positive autocorrelation and calls a higher `rho`
    "conservative".
  - Zhang, Wagner and Ross-Degnan (2011) (opened, PDF supplied by the
    maintainer): power falls as positive autocorrelation rises but rises
    with negative autocorrelation (Table 1: effect size 0.5, N = 24, power
    0.25 at 0, 0.18 at +0.5, 0.43 at −0.5). So the card's "too optimistic"
    held for positive autocorrelation only; `card-sources.md` marked it
    "contradicted" in part (resolved 17 October 2026, above).
- **Who might disagree, and why:**
  - The direction may hold only for positive autocorrelation, which is
    the common case in time series; some would keep the simple warning
    for that reason.
  - Merging E45 and E35 is simpler for users, but the designs ask
    different questions: a change at a known point vs the shape of
    change.
- **Knock-on effects:**
  - Merging changes T1's answers and the routing audit.
  - Rewording changes `card-sources.md`.
  - A2 (PITS) bears on both.
- **Recorded in:** open question 17 (setting `segmented_growth_shared`);
  [`card-sources.md`](card-sources.md) (E45 card points).

### A7. Glossary hints whose details differ from their sources

- **Question:** twenty glossary hints are only partly supported. In most,
  a detail differs from the opened source. Reword any? Examples:
  - **fixed effects:** with random slopes, the fixed effect is the
    average effect, not "the same for everyone";
  - **pooled SD:** variances weighted by n − 1;
  - **discordant proportions:** Spower takes their sum and ratio;
  - **rate ratio:** rates, not average counts, unless exposure is equal;
  - **regression coefficients:** "holding the other predictors constant";
  - **autocorrelation:** a correlation with the previous measurement,
    after the trend;
  - **ICC:** the sample ICC can be negative;
  - **covariate:** "measured alongside" could include after treatment;
  - **prior:** used for averaging power, or used in the test.
- **Options:**
  - reword each to match its source;
  - keep the plainer wording and accept the simplification;
  - decide term by term.
- **What tools and sources do:** each source and quote is in
  [`card-sources.md`](card-sources.md) (opened).
- **Who might disagree, and why:**
  - Plain-English hints trade precision for readability. A statistician
    reviewer may want the source's precision; a novice user may be lost
    by it.
- **Knock-on effects:**
  - A test checks that hints never suggest a value; rewording must keep
    to that.
  - `glossary.md` and `card-sources.md` are regenerated from
    `tree.yaml`.
- **Recorded in:** [`card-sources.md`](card-sources.md), "Still to
  check". No setting.

### A8. The reason given for the pilot-study warning

**Now sourced (17 October 2026):** Albers and Lakens (2018), read from the
PDF the maintainer supplied, support the reason (Section 6: "Especially
with small pilot samples, it is likely that the effect size is either
severely under- or overestimated"). What remains open is only whether to
keep or reword it.

- **Question:** the justification prompt says pilot estimates get a
  warning "because pilot estimates are very imprecise". The reason has no
  opened source. Keep, source, or reword?
- **Options:**
  - keep it, and source it after opening Albers and Lakens (2018);
  - reword it to what `decisions.md` records (that a warning is given);
  - drop the reason.
- **What tools and sources do:**
  - Superpower's `mu_from_ES` help page cites Albers and Lakens (2018),
    "When power analyses based on pilot data are biased" (opened; the
    paper itself is a candidate, not verified).
  - `decision-tree.md` 3.2 describes the same paper (second-hand).
- **Who might disagree, and why:**
  - Some argue pilots are useful for feasibility but not for effect sizes.
  - Others use pilot effects with corrections. "Very imprecise" is a
    summary some would soften.
- **Knock-on effects:** ties to judgement call 3.2 (B2).
- **Recorded in:** [`card-sources.md`](card-sources.md) (candidate, not
  verified). No setting.

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
- **Recorded in:** [`card-sources.md`](card-sources.md), "Contradictions".
  No setting.

## B. What the cards and forms ask

### B1. Observed power (judgement call 3.1)

- **Question:** if the effect size comes from the study's own result,
  should the form block it, warn about it, or allow it?
- **Options:**
  - block it;
  - warn and allow;
  - allow without comment.
- **What tools and sources do:**
  - G\*Power's manual reproduces SPSS's "Observed Power" column with its
    "post hoc" analysis (opened, read directly).
  - Hoenig and Heisey (2001) argue it adds nothing to the p-value
    (second-hand).
  - Perugini et al. (2014) note post hoc power can describe a body of
    research (opened, read in full).
- **Who might disagree, and why:**
  - Methodologists who follow Hoenig and Heisey would block it.
  - Users asked for it by reviewers, or who use it to describe a
    literature, would want it allowed.
- **Knock-on effects:** `effect_justification.type` has no "this study's
  own result" option. Blocking or warning needs one (a schema change).
- **Recorded in:** `decision-tree.md` 3.1; open question 5; setting
  `observed_power`.

### B2. Effect-size benchmarks and bias correction (judgement call 3.2)

- **Question:** should small, medium and large benchmarks be shown, even
  as context? Should bias-corrected planning (for example BUCSS) be
  offered?
- **Options:**
  - don't show benchmarks;
  - show them as context only, never as defaults;
  - show them as context, and offer bias-corrected planning.
- **What tools and sources do:**
  - G\*Power shows Cohen's conventions as tooltips, warning they "may
    have different meanings for different tests" (opened).
  - power4mome's quick functions accept "s"/"m"/"l" labels (opened).
  - BUCSS implements Anderson, Kelley and Maxwell (2017) (second-hand).
  - Perugini et al.'s safeguard power (opened).
- **Who might disagree, and why:**
  - The build guide rules out "medium effect" defaults.
  - Some argue benchmarks as context still anchor users.
  - Others say users without any context guess worse.
- **Knock-on effects:**
  - Bias-corrected planning has no backend in powerkit yet.
  - Hints must keep explaining meaning, not values (a test checks this).
- **Recorded in:** `decision-tree.md` 3.2; open question 5; setting
  `effect_size_benchmarks`.

### B3. One-sided tests (judgement call 3.3)

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

### B4. Defaults for alpha and target power (judgement call 3.6)

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

### B5. Which kinds of analysis to offer (open question 2)

- **Question:** offer only "sample size needed", "power at a given N" and
  "smallest detectable effect"? Show compromise and criterion as "coming
  later"? Should "smallest detectable effect" be greyed out or hidden
  where the engine can't do it?
- **Options:**
  - three types, with sensitivity greyed out where unavailable;
  - three types, with sensitivity hidden;
  - also list compromise and criterion as coming later.
- **What tools and sources do:**
  - G\*Power offers five types of analysis (opened, manual p. 2).
  - Spower sets the type by which argument is `NA` (opened).
  - The engine's `goal.type` has three values; sensitivity runs only for
    the 2 x 2 designs.
- **Who might disagree, and why:**
  - Greying out shows users what's coming, but can frustrate them.
  - Hiding is cleaner, but hides the roadmap.
- **Knock-on effects:** the Q-goal card notes depend on it.
- **Recorded in:** open question 2; setting `analysis_types`.

### B6. Power for several hypotheses in one study (judgement call 3.5)

- **Question:** should the single-analysis routes ask whether the study
  tests several hypotheses?
- **Options:**
  - no;
  - yes: ask, and point to the guided route.
- **What tools and sources do:**
  - Maxwell (2004) on the "curse of multiplicities" (second-hand).
  - Rubin (2021) distinguishes disjunction, conjunction and individual
    testing (second-hand).
  - Tools: powertools, power4mome and Superpower support parts of this
    (`coverage.md`).
- **Who might disagree, and why:**
  - Whether alpha needs adjusting depends on how results combine into a
    claim. Some adjust by default; Rubin argues against automatic
    adjustment.
- **Knock-on effects:** linked to the guided route (D4) and its
  combination rule.
- **Recorded in:** `decision-tree.md` 3.5; open question 5; setting
  `several_hypotheses`.

### B7. Simple effects as a target (judgement call 3.4)

- **Question:** should simple effects become a power target alongside the
  interaction?
- **Options:**
  - no: the interaction only;
  - yes: offer simple effects as a target.
- **What tools and sources do:**
  - Superpower gives power for simple effects through emmeans
    (`coverage.md`).
  - Sources on attenuated interactions needing large samples
    (second-hand; `decision-tree.md` 3.4).
- **Who might disagree, and why:**
  - Some say the hypothesis is really about the simple effects.
  - Others say only the interaction licenses the claim that an effect
    differs.
- **Knock-on effects:**
  - The spec has no simple-effect target, so this would be a schema
    change.
  - Overlaps A3 (other defensible analyses).
- **Recorded in:** `decision-tree.md` 3.4; open question 5; setting
  `simple_effects_target`.

### B8. Reliability for E15's score variable

- **Question:** E15 (moderated regression, one yes/no variable and one
  score) no longer asks about reliability (decided 16 October 2026).
  Should it still ask about the *score's* reliability?
- **Options:**
  - no reliability question on E15 (as now);
  - ask for the score variable only.
- **What tools and sources do:** InteractionPoweR takes a reliability per
  variable (`rel.x1`, `rel.x2`; default 1, "perfect reliability")
  (opened).
- **Who might disagree, and why:**
  - The decision's reason (misclassification differs from unreliability)
    applies to the 0/1 variable, not to the score. Some would ask for the
    score's reliability.
  - Others prefer one simple rule per card.
- **Knock-on effects:** the engine's spec accepts reliabilities for any
  regression interaction (E5).
- **Recorded in:** [`decisions.md`](decisions.md) (16 October 2026). No
  setting.

### B9. Three or more parallel mediators (open question 10)

- **Question:** allow three or more parallel mediators before that is
  validated (validated with two)?
- **Options:**
  - two only, until validated;
  - up to nine, as the spec allows.
- **What tools and sources do:** power4mome's quick functions take paths
  for any number of mediators (`coverage.md`); powerkit's validation
  covers two (`validation-log.md`).
- **Who might disagree, and why:**
  - Users with three mediators would otherwise be turned away.
  - The validation rule says not to offer what isn't validated.
- **Knock-on effects:** a validation run with three or more mediators is
  in `status.md`, "What's next".
- **Recorded in:** open question 10; setting `parallel_mediators_max`.

### B10. Effect sizes on the input screens

- **Question:** the input screens (E1–E14) leave effect sizes, SDs and
  correlations empty and require them, with a justification. Should they
  offer suggested values (for example conventional benchmarks) that the
  user can change?
- **Options:**
  - start empty and required, with a justification (as built);
  - offer suggested values the user can change, still with a
    justification.
- **What tools and sources do:**
  - G\*Power shows Cohen's conventions as tooltips (opened,
    `decision-tree.md` section 1).
  - power4mome's quick functions accept "s"/"m"/"l" labels for paths
    (opened, `decision-tree.md` section 1).
  - The engine's spec requires `effect_justification`: "it feeds the
    write-up and prevents unexamined 'medium effect' defaults"
    (`design.schema.json`, opened).
  - The build guide rules out "medium effect" defaults (section 4).
- **Who might disagree, and why:**
  - Empty fields make users think about their effect.
  - Suggested values help users who have no idea where to start, but may
    anchor them (the same argument as B2).
- **Knock-on effects:**
  - Ties to B2 (benchmarks as context).
  - Other settings on the screens start at the wrapped tool's default,
    each labelled with its source (not effect sizes).
- **Recorded in:** setting `effect_size_inputs` (shown on the input
  screens).

### B11. How results are worded

- **Question:** the result screen (E1–E8, phase 5 part 1) gives the
  number in a sentence. Keep the draft wording, or change it?
  - Draft for a sample size: "You need 206 participants in total (103 per
    group) for 80% power to detect the effect you entered, with a
    two-sided test at alpha = .05."
  - Draft for power: "With 120 participants in total (60 per group), the
    study has 61% power: if the true effect is the one you entered, about
    61 in 100 studies like this would give a significant result …"
  - Every result adds: "This is planned power for the effect you entered,
    before the study is run. It is not "observed power" calculated from a
    finished study's results, which says nothing beyond the study's
    p-value."
- **Options:** keep the draft; a shorter number-first wording; other
  wording.
- **What tools and sources do:** not yet checked against a source for
  this entry (unsourced). The "observed power" line states the build
  guide's intent; it cites no reference, and the claim that observed
  power "says nothing beyond the p-value" needs a source from `refs.bib`
  before release (unsourced).
- **Who might disagree, and why:**
  - A sentence is easier to read and to copy into a methods section.
  - A number first is quicker to scan.
  - Some find the "observed power" line unnecessary for planning.
- **Knock-on effects:** the methods paragraph (still a placeholder); the
  wording of the same numbers in the exported script's comments.
- **Recorded in:** setting `result_wording` (shown on the result screen).

### B12. Rounding of N

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

### B13. A power curve

- **Question:** should the result screen show a power curve (power
  against N)?
- **Now:** no curve; the number only. For a simulated sample size the
  engine already returns the points it simulated.
- **Options:** no curve; a table of the computed points; a plot.
- **What tools and sources do:** G\*Power can plot power against N
  (unsourced here; to check in its manual).
- **Who might disagree, and why:** a curve shows how sensitive the N is to
  the target power, but simulated points are noisy and can look jagged.
- **Knock-on effects:** for simulated results, a curve needs more
  simulated sample sizes than the search uses.
- **Recorded in:** setting `power_curve` (shown on the result screen).

### B14. The prototype banner, now that E1–E8 calculate

- **Question:** the banner says "Prototype: shows which analysis you need;
  it doesn't calculate anything yet.", and each card ends "No numbers are
  calculated in this prototype." Both are now out of date for E1–E8,
  which calculate on their input screen. The banner was left unchanged
  (the maintainer's instruction that it stays).
- **Options:** keep both as they are; change the banner to say that some
  analyses calculate; change the card line only on E1–E8.
- **Who might disagree, and why:** an accurate banner avoids confusing
  testers; an unchanged banner keeps expectations low while results are
  under review.
- **Recorded in:** this entry only (no setting).

### B15. The seed for a calculation

- **Question:** which random-number seed does a calculation on the result
  screen use?
- **Now:** a new random seed each time. It's recorded in the spec that was
  run, in the reproducibility record and in the R script, so any one
  result can be reproduced exactly. But the same answers entered twice
  can give slightly different simulated results. In the screenshots for
  this PR, E2's required N came out as 196, 198 and 200 on three runs.
  That's Monte Carlo noise within the reported 95% interval.
- **Options:**
  - a new random seed each time (as now);
  - a fixed default seed, so the same answers always give the same
    result;
  - ask the user, with a default.
- **What tools and sources do:** not checked for this entry (unsourced).
- **Who might disagree, and why:**
  - A fixed seed avoids confusion when a user reruns and sees a different
    N.
  - A random seed avoids treating one simulated draw as exact.
- **Knock-on effects:** exact results (E7, E8) don't depend on the seed in
  practice (Departure 3).
- **Recorded in:** setting `calculation_seed` (shown on the result
  screen).

## C. Which card users reach

### C1. Wording of the screening questions (open question 16)

- **Question:** the screening questions S1–S4 and T1 are drafts. In
  particular, does S3's "Twice (e.g. once before and once after)"
  separate a two-measurement design from a trend over time? Someone with
  a segmented-regression design who answers "Twice" still reaches the
  before/after tests.
- **Options:**
  - keep the drafts;
  - revise them in `tree.yaml` and `decision-tree.md`.
- **What tools and sources do:** established tools don't screen designs
  first (`decision-tree.md`, section 1) (opened). There is no precedent
  for the wording.
- **Who might disagree, and why:**
  - Shorter questions are easier to answer, but let more designs through
    to the wrong card.
  - More precise ones are harder for novices.
- **Knock-on effects:**
  - Walkthrough paths (`scenarios.json`) and the routing audit depend on
    the exact answer labels.
  - A test checks the paths.
- **Recorded in:** open question 16; setting `screening_wording`.

### C2. Matched pairs vs dyads (open question 19)

- **Question:** S2's "Pairs" leads to the dyadic card (E44). A
  matched-pairs design analysed with a paired t-test might belong at E3.
  Should S2 tell the two apart?
- **Options:**
  - keep one "Pairs" answer (as now);
  - split it into "pairs of people who influence each other (couples,
    parent and child)" and "matched pairs";
  - add a follow-up question after "Pairs".
- **What tools and sources do:**
  - UCLA OARC lists "dependent/matched groups" with the paired t-test,
    the Wilcoxon signed-rank test and McNemar (opened).
  - Kenny treats dyads as interdependent, needing dyadic methods
    (opened).
- **Who might disagree, and why:**
  - Some see matched pairs as a paired design; others note matching
    doesn't always make scores dependent in the same way (unsourced).
- **Knock-on effects:** changes S2, the walkthroughs and audit item 8.
- **Recorded in:** open question 19; routing audit, "What's left" item 8.
  No setting.

### C3. Diary studies (walkthrough flag F12)

- **Question:** T1's "how people change" sends within-person
  relationships (diary studies) to E35 (growth curves, diary and panel
  studies) rather than E41 (relationships within people). Which card
  should a diary study about a within-person relationship reach?
- **Options:**
  - E35 (as now);
  - E41;
  - a T1 answer that separates them.
- **What tools and sources do:** E41 lists mlmpower and simr; E35's tools
  are from `coverage.md` (opened). No source on how tools route diary
  studies (unsourced).
- **Who might disagree, and why:**
  - Diary studies are both longitudinal and multilevel, so either card
    is defensible.
- **Knock-on effects:** T1's wording (C1); the walkthroughs.
- **Recorded in:** [`walkthroughs.md`](walkthroughs.md), flag F12. No
  setting.

### C4. Reliability studies: inter-rater and test–retest

- **Question:** inter-rater designs fit S3's "Twice" awkwardly, and only
  S4's "Estimate an effect precisely" leads to a fitting card (E46).
  Test–retest answered "Twice" plus a relationship reaches E41 (now
  recorded in the audit). Should reliability studies get their own answer
  or card?
- **Options:**
  - leave as is (E46 via S4; E41 or E4 via the relationship path);
  - add a reliability or agreement answer, for example at Q1 or S4;
  - add a reliability card.
- **What tools and sources do:** psych's `ICC()` and `statsBy()` compute
  ICCs (opened). No power or precision tool for ICCs was checked
  (unsourced).
- **Who might disagree, and why:**
  - Reliability planning is usually about precision, not power, so some
    would send it to E46.
  - Others want it named, so users recognise it.
- **Knock-on effects:** audit item 2; walkthrough flag F11 (the audit
  part is decided).
- **Recorded in:** routing audit, "What's left" item 2; PR #21 "Need a
  routing decision". No setting.

### C5. Two groups, a yes/no outcome, measured twice

- **Question:** for example, yes/no before and after, in a treatment and
  a control group.
  - The guided route gives the safety net (E-unsure).
  - "Help me choose" offers only E26 (McNemar or Cochran's Q), which
    compares conditions within people, not groups.

  Which card should it reach?
- **Options:**
  - the safety net in both routes;
  - a new generic "not covered" card;
  - a route to an existing card, if one fits.
- **What tools and sources do:** UCLA OARC's table has "repeated
  measures logistic regression" for a categorical outcome with dependent
  groups (opened). It has no row for a between factor crossed with
  repeated measures and a yes/no outcome. Spower's `p_glm()` doesn't
  model repeated measures (opened).
- **Who might disagree, and why:**
  - A safety net is honest, but leaves users with nothing.
  - A new card needs content and sources.
- **Knock-on effects:** audit item 13; guided-route and "Help me choose"
  consistency (C8).
- **Recorded in:** routing audit, "What's left" item 13. No setting.

### C6. Several categories, same people

- **Question:** an outcome with several categories measured twice reaches
  E26 (McNemar's test or Cochran's Q, both for yes/no outcomes). Does it
  need its own card?
- **Options:**
  - keep E26;
  - a new "not covered" card;
  - the safety net.
- **What tools and sources do:**
  - UCLA OARC lists McNemar for "categorical" with two dependent groups
    (opened). The same table doesn't name a test for several categories
    with dependent groups beyond that.
  - Spower's `p_mcnemar.test()` is for 2 x 2 tables (opened).
- **Who might disagree, and why:**
  - Some would accept E26 with a note.
  - Others see it as a misroute, since McNemar is for two categories.
- **Knock-on effects:** audit item 12.
- **Recorded in:** routing audit, "What's left" item 12. No setting.

### C7. Factorial yes/no outcome through Q1's moderation answer

- **Question:** "That an effect depends on something else" with a yes/no
  outcome leads to E32 ("no ready-made tool") for every moderation
  design, including two binary factors. Those reach E47 by the other
  paths. Should Q2 for moderation separate them?
- **Options:**
  - leave as is;
  - add a question that sends crossed binary factors to E47;
  - send all yes/no moderation to E47.
- **What tools and sources do:**
  - UCLA OARC lists "factorial logistic regression" for two or more
    independent-group IVs and a two-category outcome (opened).
  - Spower's `p_glm()` handles it (opened).
- **Who might disagree, and why:**
  - Moderation and factorial designs are the same model, described
    differently.
  - Some would route by the model; others by how the user describes the
    hypothesis.
- **Knock-on effects:**
  - E32's "no ready-made tool" may itself be wrong for the factorial
    case (A1, A2 show the same pattern).
  - Audit item 11.
- **Recorded in:** routing audit, "What's left" item 11. No setting.

### C8. Guided-route choices made to match "Help me choose"

- **Question:** PR #21 made these choices to stay consistent with "Help
  me choose". Confirm each:
  - after "Twice", X a score with no covariate → E41;
  - X of three or more groups with a score outcome, after "Twice" → E21
    (3 x 2 mixed);
  - several categories with X a score → E-unsure (no card exists);
  - after yes/no and "Twice", the end-point list still shows E6, because
    the relationship path's categorical question doesn't check how many
    times people were measured.
- **Options:**
  - confirm;
  - change any of them, case by case.
- **What tools and sources do:** these are about powerkit's own routes.
  No external source applies (unsourced).
- **Who might disagree, and why:**
  - Consistency between routes is one goal; the best card for each
    design is another, and they can conflict (E21 is a stretch for a
    measured X, for example).
- **Knock-on effects:**
  - The walkthroughs, `test-walkthrough-fixes.R` and the audit record
    these paths.
  - The E6 quirk also affects "Help me choose".
- **Recorded in:** PR #21, "Routing choices to confirm". No setting.

### C9. Chi-square goodness-of-fit (judgement call 3.7)

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

### C10. Rank-based tests reaching the parametric cards (judgement call 3.8)

- **Question:** Mann–Whitney, Wilcoxon, Kruskal–Wallis, Friedman and rank
  correlation reach the parametric end points. How should powerkit handle
  them?
- **Options:**
  - G\*Power's efficiency adjustment, recorded as the convention;
  - simulate the rank test with Spower;
  - label the parametric figure as an approximation;
  - honest cards until one of these is built.
- **What tools and sources do:**
  - Spower's `p_wilcox.test()` and `p_kruskal.test()` (opened); no
    Friedman function.
  - G\*Power's efficiency approach (second-hand).
- **Who might disagree, and why:**
  - The two approaches can give different answers, and both need an
    assumed distribution users rarely know.
- **Knock-on effects:** whichever is chosen is a convention to record in
  `conventions.md`, with a test of the size of any difference.
- **Recorded in:** `decision-tree.md` 3.8; setting `rank_based_tests`.

### C11. Fisher's exact test reaching the large-sample tests (judgement call 3.9)

- **Question:** Fisher's exact test reaches E5 or E6, which can be quite
  wrong with small expected counts. Offer the exact test, warn, or both?
- **Options:**
  - offer Spower's `p_prop.test(exact = TRUE)` as a test version;
  - warn about small expected counts;
  - both.
- **What tools and sources do:**
  - Spower's exact option (opened).
  - G\*Power's Fisher's exact test (second-hand).
- **Who might disagree, and why:**
  - A warning needs a threshold for "small", itself a convention.
  - The exact test changes E5's spec and needs validation.
- **Knock-on effects:** spec, validation, and the Q-test card note on E5.
- **Recorded in:** `decision-tree.md` 3.9; setting `fisher_exact`.

### C12. Curvilinear effects

- **Question:** rel → … → E4 gives a linear correlation for a curved
  relationship. Is the right card E24 (regression with a quadratic term)
  or a generic card?
- **Options:**
  - E24 with a quadratic term;
  - a generic "not covered" card;
  - the safety net only (as offered now at R1).
- **What tools and sources do:** UCLA's piecewise-regression page
  describes fitting a curved pattern with separate lines or a quadratic
  (opened). No power tool was checked (unsourced).
- **Who might disagree, and why:**
  - Some treat a quadratic term as ordinary multiple regression.
  - Others see curvilinear hypotheses as needing their own planning.
- **Knock-on effects:** audit item 1.
- **Recorded in:** routing audit, "What's left" item 1. No setting.

### C13. Sequential designs

- **Question:** sequential designs (interim looks) reach fixed-sample end
  points. Is that a misroute?
- **Options:**
  - accept it;
  - add a "not covered" card;
  - add a screening answer.
- **What tools and sources do:** `coverage.md` lists sequential designs
  under needs the five tools don't cover, with candidate tools (opened).
- **Who might disagree, and why:**
  - A fixed-sample N is a reasonable upper bound to some.
  - Others say a sequential design needs its own calculation.
- **Knock-on effects:** audit item 4.
- **Recorded in:** routing audit, "What's left" item 4. No setting.

### C14. Several outcomes (MANOVA)

- **Question:** users with several outcomes pick one and reach a
  single-outcome card. Is powering each outcome separately acceptable?
- **Options:**
  - accept it, with Q-multi's question;
  - a MANOVA card;
  - a screening answer for several outcomes.
- **What tools and sources do:**
  - UCLA OARC lists one-way MANOVA and multivariate multiple regression
    for two or more dependent variables (opened).
  - `coverage.md` lists candidate tools (opened).
- **Who might disagree, and why:**
  - Some analyse each outcome separately, with a correction.
  - Others test them jointly.
- **Knock-on effects:** audit item 5; B6 (several hypotheses).
- **Recorded in:** routing audit, "What's left" item 5. No setting.

### C15. Covariates other than a baseline, in a two-group comparison

- **Question:** a non-baseline covariate isn't asked about, and the
  design reaches E2. The audit notes this is probably conservative rather
  than wrong. Ask about it?
- **Options:**
  - leave as is;
  - ask about covariates, leading to E23 (ANCOVA).
- **What tools and sources do:** Superpower's `ANCOVA_analytic()` takes
  the covariates' R-squared (`coverage.md`, card E23) (opened).
- **Who might disagree, and why:**
  - Ignoring a covariate usually overstates the N needed. Some accept
    that; others want the efficiency.
- **Knock-on effects:** audit item 6; open questions 13 and 15 (D7).
- **Recorded in:** routing audit, "What's left" item 6. No setting.

### C16. Latent-variable mediation entered as mediation

- **Question:** a path between latent variables entered as mediation
  reaches E10 (observed-variable mediation). Is E10 with reliabilities
  ever an acceptable stand-in?
- **Options:**
  - accept E10;
  - send it to E37 (SEM);
  - ask whether the variables are latent.
- **What tools and sources do:** power4mome has a latent mediation vignette
  ("power4test_latent_mediation") (opened, file listing; contents not
  checked).
- **Who might disagree, and why:**
  - Observed-variable mediation underestimates paths when measures are
    unreliable. Some would accept it with reliabilities; others want a
    latent model (unsourced).
- **Knock-on effects:** audit item 7; A4's "never a simpler stand-in"
  rule.
- **Recorded in:** routing audit, "What's left" item 7. No setting.

### C17. Ratings and counts beyond differences (decision D1)

- **Question:** decision D1 lets a rating be analysed as a score for
  differences. Does it apply in the relationship, moderation and
  mediation paths too? Counts and ratings are now caught at S1.
- **Options:**
  - apply D1 everywhere;
  - differences only;
  - ask per path.
- **What tools and sources do:** UCLA OARC's table separates "interval &
  normal" from "ordinal or interval" outcomes (opened).
- **Who might disagree, and why:**
  - Treating ratings as scores is common practice. Some see it as wrong
    for ordinal data.
- **Knock-on effects:** audit item 14; open question 4 (where the "rating
  analysed as a score" answer is stored).
- **Recorded in:** routing audit, "What's left" item 14. No setting.

### C18. SEM in the guided route (walkthrough flag F8)

- **Question:** the guided route has no SEM option. Add one?
- **Options:**
  - leave it to "Help me choose" (Q1 reaches E37);
  - add a variables-screen option that leads to E37.
- **What tools and sources do:** no source applies (powerkit's own route)
  (unsourced).
- **Who might disagree, and why:**
  - A guided route is meant to cover a whole study, and SEM studies are
    common.
  - Adding it widens the guided route's scope (D5).
- **Knock-on effects:** D5.
- **Recorded in:** [`walkthroughs.md`](walkthroughs.md), flag F8. No
  setting.

## D. The routes and the start screen

### D1. Where the tree starts (open question 1)

- **Question:** start from the hypothesis (as now), or also offer
  G\*Power's design-based order (parameter class, then design)?
- **Options:**
  - hypothesis first;
  - also offer the design-based order.
- **What tools and sources do:** G\*Power offers distribution-based and
  design-based selection (opened, manual p. 2). PAMLj's menu is by
  analysis family (opened).
- **Who might disagree, and why:**
  - Users who know their test want G\*Power's order.
  - Novices may not know the parameter class.
- **Knock-on effects:** another route to maintain and walk through.
- **Recorded in:** open question 1; setting `starting_point`.

### D2. When to ask "what do you want to find out?" (open question 3)

- **Question:** ask it after the design (G\*Power's order, as now) or
  first (PAMLj's order)?
- **Options:**
  - after the design;
  - first.
- **What tools and sources do:** G\*Power asks after choosing the test;
  PAMLj's "aim" comes first (opened).
- **Who might disagree, and why:**
  - Asking first frames the task.
  - Asking after avoids offering types the design can't support
    (sensitivity is 2 x 2 only today).
- **Knock-on effects:** B5.
- **Recorded in:** open question 3; setting `closing_order`.

### D3. Where Bayes factors enter (open question 8)

- **Question:** ask "p-values or Bayes factors?" on the start screen,
  after Q1, among the closing questions (as the prototype shows Q-bayes
  now), or only in the shortcut list?
- **Options:**
  - start screen;
  - after Q1;
  - closing questions;
  - shortcut list only.
- **What tools and sources do:** none of the tools reviewed routes
  between p-values and Bayes factors (`decision-tree.md`, section 1)
  (opened). `coverage.md` lists Bayesian design tools as candidates
  (opened).
- **Who might disagree, and why:**
  - Bayesian users want to say so early.
  - Most users plan with p-values, and an early question adds friction.
- **Knock-on effects:** E-bayes is reachable only from the list now.
- **Recorded in:** open question 8; setting `bayes_entry`.

### D4. The guided "plan my whole study" route (open question 11)

- **Question:** keep the guided route? If so, is a study file that wraps
  several specs acceptable (a schema change)?
- **Options:**
  - yes;
  - no.
- **What tools and sources do:** no tool reviewed plans several analyses
  together (`decision-tree.md`, section 1) (opened).
- **Who might disagree, and why:**
  - It helps users with several hypotheses.
  - It adds scope, and choices (combination rules) that are themselves
    contested (B6).
- **Knock-on effects:** D5–D7; the walkthroughs' guided runs.
- **Recorded in:** open question 11; setting `guided_route` (hides the
  route when "no").

### D5. What the guided route covers (open question 14)

- **Question:** what does the guided route do with repeated measures,
  many stimuli or nested data? Now the screening stops nested data,
  stimuli and measurements over time before it, and three or more
  conditions per person go to "Help me choose".
- **Options:**
  - send users to "Help me choose" (as now);
  - extend the guided route;
  - say on the start screen that it is for single-session,
    between-person studies.
- **What tools and sources do:** no source applies (unsourced).
- **Who might disagree, and why:**
  - Extending it covers more studies but multiplies the routes to keep
    consistent (C8).
- **Knock-on effects:** C18 (SEM in the guided route).
- **Recorded in:** open question 14; setting `guided_scope`.

### D6. Consistency between hypotheses (open question 12)

- **Question:** per-hypothesis forms with a consistency check,
  whole-study simulation from one model, or both?
- **Options:**
  - per hypothesis;
  - whole-study simulation;
  - both.
- **What tools and sources do:** `decision-tree.md` 4.2 sets out both
  (opened). Whether either is a departure from established tools is part
  of the question.
- **Who might disagree, and why:**
  - Per hypothesis follows each backend exactly.
  - Whole-study simulation is more coherent, but new.
- **Knock-on effects:** may need a record in `conventions.md`.
- **Recorded in:** open question 12; setting `consistency_approach`.

### D7. Covariates in each analysis (open questions 13 and 15)

- **Question:** should the app ask, for each analysis, which covariates
  it includes? In the guided route, should covariates enter the
  moderation and mediation analyses too? (No template has covariates
  yet.)
- **Options:**
  - Open question 13: ask per analysis; or don't.
  - Open question 15: comparison only (as now, saying so on the plan);
    include once the templates support covariates; or ask per analysis.
- **What tools and sources do:**
  - InteractionPoweR has `power_interaction_r2_covs()` for covariates
    (opened, `decision-tree.md` section 1).
  - Superpower's ANCOVA functions (`coverage.md`).
- **Who might disagree, and why:**
  - Including covariates is more accurate.
  - Asking per analysis adds questions most users can't answer yet.
- **Knock-on effects:** schema changes for covariates; C15.
- **Recorded in:** open questions 13 and 15; settings
  `covariates_per_analysis` and `guided_covariates`.

## E. Behind the scenes

### E1. Answers the spec can't store (open question 4)

- **Question:** where should these answers go:
  - a rating analysed as a score;
  - randomised or not;
  - why ANCOVA or the mixed interaction was chosen;
  - the expected interaction shape;
  - manipulated or measured?

  And should PP1 (randomised?) and F6 (expected shape) be stored, shown
  on screen only, or not asked until there is somewhere to store them?
- **Options:**
  - Storage: a new spec field (a schema change); `effect_justification.notes`;
    or the app only.
  - PP1 and F6: store them; show them on screen only; or don't ask them
    yet.
- **What tools and sources do:** no tool reviewed stores these (unsourced).
- **Who might disagree, and why:**
  - Storing them helps the write-up.
  - A new field is a spec version change.
- **Knock-on effects:** the methods paragraph (phase 4); C17.
- **Recorded in:** open question 4; settings `unstored_answers` and
  `pp1_f6_stored`.

### E2. Scripts for designs powerkit doesn't run (open question 7)

- **Question:** for uncovered designs, should the full-model builder
  generate a power4mome or Spower script that the user runs themselves,
  without powerkit's validation?
- **Options:**
  - no;
  - yes, clearly labelled as not validated.
- **What tools and sources do:** `export_script()` writes scripts for the
  designs powerkit runs (`status.md`) (opened). No tool reviewed exports
  for unvalidated designs (unsourced).
- **Who might disagree, and why:**
  - A script helps users go further.
  - An unvalidated script with powerkit's name on it may be trusted too
    much.
- **Knock-on effects:** A4's wording; the export code.
- **Recorded in:** open question 7; setting `r_script_for_uncovered`.

### E3. `design-finder.md` and `decision-tree.md` (open question 9)

- **Question:** should the two documents stay separate (card wording in
  one, structure in the other) or be merged?
- **Options:**
  - keep them separate;
  - merge them.
- **What tools and sources do:** not applicable.
- **Who might disagree, and why:**
  - Merging removes duplication.
  - Separate documents suit different readers.
- **Knock-on effects:** the docs-match tests.
- **Recorded in:** open question 9. No setting.

### E4. Phase 3b: binary X and W

- **Question:** the statistical decisions needed before coding binary X
  and W:
  - how users specify a 0/1 X's effect when paths are standardised;
  - whether the group proportion is an input;
  - how power4mome generates binary variables;
  - how this interacts with the planned Cohen's d departure;
  - the validation targets.
- **Where:** [`phase-3b-questions.md`](phase-3b-questions.md), with the
  options and what the backends' documentation says. Not copied here.
- **Knock-on effects:** the E15, E16 and E17 cards (B8; E5).

### E5. The engine still accepts reliabilities for a binary X or W

- **Question:** E15 no longer asks about reliability in the prototype,
  but the engine's spec accepts `variables.*.reliability` for a
  regression interaction of any variable type. Should the engine refuse
  it for a binary X or W?
- **Options:**
  - refuse it (an engine change);
  - accept it (as now).
- **What tools and sources do:** InteractionPoweR's `power_interaction()`
  takes `rel.x1` (reliability) and `k.x1` (number of discrete values) as
  separate arguments (help page; opened). The help page doesn't say
  whether a reliability is meaningful for a binary variable.
- **Who might disagree, and why:** the same as B8.
- **Knock-on effects:**
  - an engine change, for the engine's owner; phase 3b (E4);
  - separately, InteractionPoweR's `power_interaction_r2()`, which powerkit
    uses only to narrow the sample-size search for E9, is documented as
    valid for continuous, normally distributed variables (help page;
    opened). Whether E15 could reuse it is for phase 3b.
- **Recorded in:** [`decisions.md`](decisions.md) (16 October 2026). No
  setting.

## F. Validation

### F1. Known gap: the Monte Carlo interval for two or more mediators

Known gap: nothing independently checks powerkit's default Monte Carlo
interval for two or more mediators (the simsem cross-checks cover the
joint test only).

- **Context:** the parallel and serial cross-checks
  (`mediation_crosscheck_parallel`, `mediation_crosscheck_serial`) passed
  on 17 October 2026 (`validation-log.md`). They compare the joint test in
  power4mome and simsem. For simple mediation, pwrss also checks the Monte
  Carlo interval; pwrss has no parallel or serial mediation.
- **Recorded in:** this entry; `validation-log.md`, "Parallel and serial
  mediation (joint test against simsem)".
