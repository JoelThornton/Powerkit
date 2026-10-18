# Judgement calls and open questions

*Last updated: 18 October 2026.*

Every open question about the routing prototype, in one place, for the
maintainer to decide. Decided entries move to
[`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md)
(their headings stay here with a link), so this file holds open questions
only.

**Recommendations (from 18 October 2026).** New and revised entries end
with Claude's recommendation and a one-line reason, so the maintainer can
accept or overrule it instead of weighing every option from scratch.
Older entries list options in the order of their source documents and
carry no recommendation unless one has been added.

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
  [`decision-tree.md`](decision-tree.md), or the entry says which text was
  opened and when (for example the full texts the maintainer supplied on
  17 October 2026: Rubin, 2021, author preprint; Rubin, 2024; Mikael
  Rubin, 2025; Uttley, 2019).
- **(verified, maintainer)**: the maintainer checked the full-text PDF
  and confirmed the details quoted (17 October 2026). These are in
  `engine/inst/citations/refs.bib` with the note "Verified 2026-10-17
  from full-text PDF held by the maintainer":
  - Rubin (2021, *Synthese*; `Rubin2021_alpha`): states the individual,
    disjunction and conjunction framework and gives the .80 × .80 = .64
    conjunction example (p. 7);
  - Rubin (2024, *Methods in Psychology*; `Rubin2024_inconsistent`):
    section 7 covers sensitivity analysis, justified alpha and one-sided
    tests;
  - Mikael Rubin (2025, *International Journal of Psychology*;
    `RubinMikael2025_power`): Table 1 names MLMPower, Longpower, PowerLMM,
    MixedPower and SimR, and it cites Dziak et al. (2020);
  - Frane (2019; `Frane2019_misguided`): the reference as printed in
    Rubin (2024)'s reference list. Frane's own arguments were not read.

  Still candidates: Dziak et al. (until its published version is
  checked), Lakens et al. (2018), Hoenig and Heisey (2001) and the
  G\*Power manual.
- **(second-hand)**: `decision-tree.md` tags it *seen second-hand, to
  verify*.
- **(unsourced)**: no source was found or checked.

"Who might disagree" is reasoning about the positions, not a report of
what named people have said, unless a source is given.

The statistical decisions phase 3b needs before coding are in
[`phase-3b-questions.md`](phase-3b-questions.md) and are only linked here
(E4).

For the session itself, [`judgement-session.md`](judgement-session.md)
condenses the calls that change what users see into one page each,
ordered by impact.

## Contents

- [A. What the cards say](#a-what-the-cards-say): A1–A9
- [B. What the cards and forms ask](#b-what-the-cards-and-forms-ask): B1–B18
- [C. Which card users reach](#c-which-card-users-reach): C1–C18
- [D. The routes and the start screen](#d-the-routes-and-the-start-screen): D1–D7
- [E. Behind the scenes](#e-behind-the-scenes): E1–E6
- [F. Validation](#f-validation): F1
- [G. Coverage and scope](#g-coverage-and-scope): G1–G9

## A. What the cards say

### A1. Naming other tools on "not covered" cards

**Decided 18 October 2026, for two cards** (`decisions.md`, "The new
design"): the start screen's aims that powerkit doesn't run point to
established tools: estimation to MBESS and Spower's precision criterion
(E46), and showing there's no meaningful effect to established
equivalence tools (E36, which already names TOSTER). Still open: every
other "not covered" card.

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

Decided; moved to [`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md#a2-e45-says-no-ready-made-tool-but-pits-exists).

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

Decided; moved to [`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md#a9-exact-analytic-for-superpowers-anovaexact-e7-e8).

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
    (second-hand; still not opened). Uttley (2019) quotes them (see B11).
  - Mikael Rubin (2025, *International Journal of Psychology*,
    doi:10.1002/ijop.70017; opened): "post hoc power analyses are useless
    at best, misleading at worst (Dziak et al. 2020)" (p. 14 of 15). He
    also notes that "it is sometimes requested by reviewers" (same page).
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

**Decided 18 October 2026** (`decisions.md`, "The new design"): the
effect-size source "one published study" carries a warning that
published effects tend to be inflated, with a pointer to BUCSS; powerkit
doesn't run bias-corrected planning itself. Still open: whether
benchmarks are shown at all, even as context.

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

### B4. Defaults for alpha and target power (judgement call 3.6)

Decided; moved to [`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md#b4-defaults-for-alpha-and-target-power-judgement-call-36).
Setting `alpha_power_defaults` is updated to match when the inputs
screen is built.

### B5. Which kinds of analysis to offer (open question 2)

**Decided 18 October 2026** (`decisions.md`, "The new design"): the
smallest detectable effect is a first-class route (G9), reached from the
start screen's "My sample size is fixed". Where a design can't run it
yet, the screen says why. Still open: whether "power at a given N" stays
a separate goal, and whether compromise and criterion are listed as
coming later.

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

**Decided 18 October 2026** (`decisions.md`, "The new design"): the
start screen asks every user what the main claim rests on, with four
options, each with a one-line psychology example: one test; several
claims, each standing on its own (individual testing: each test powered
separately, no correction; the most common case); any of several
(disjunction: Bonferroni, G7; the screen says the claim is about the
set, not each test); all of several (conjunction: guidance only, no
computed joint power; tests on the same people are usually positively
correlated, so the product of their powers is roughly a floor). Still
open: power for "all of several" beyond guidance, the guided route's
study-level result (D4, D6), and checking the option wording with Mark
Rubin.

- **Question:** when a study tests several hypotheses, how does powerkit
  ask what the user will conclude from them, and what does that mean for
  alpha and for power? Should the single-analysis routes ask about it at
  all?
- **Options:**
  - don't ask: each analysis is planned on its own, at the alpha the user
    enters (as now);
  - ask in the single-analysis routes, and point to the guided route;
  - ask the inference question in the guided route only, using Rubin's
    three cases below (see
    [`inference-question-design.md`](inference-question-design.md) for
    how the question could be worded).
- **What tools and sources do:**
  - **Rubin's framework** (opened 17 October 2026, from texts the
    maintainer supplied; verified, maintainer, the same day). Rubin (2021), *Synthese*,
    doi:10.1007/s11229-021-03276-4, was read in the author preprint
    (SSRN abstract 3904565); the preprint gives no volume or pages, so
    "199, 10969–11000" is as printed in Rubin (2024)'s reference list.
    Rubin (2024), *Methods in Psychology*, 10, 100140,
    doi:10.1016/j.metip.2024.100140, was read in the published version.
    Whether alpha needs adjusting depends on the type of multiple testing:
    - *individual testing*: "each individual result must be significant in
      order to reject each associated individual null hypothesis" (Rubin,
      2021, author preprint, p. 1). "Like conjunction testing, individual
      testing does not require an adjustment to the alpha level of each
      test" (p. 7), "even when multiple instances of individual testing
      take place side-by-side within the same study" (p. 8);
    - *disjunction testing*: "at least one test result must be significant
      in order to reject the associated joint null hypothesis". "It is
      argued that alpha adjustment is only appropriate in the case of
      disjunction testing" (both p. 1);
    - *conjunction testing*: "all relevant results must be significant in
      order to reject the joint null hypothesis" (p. 1). It "does not
      require an adjustment to the alpha level for tests of each
      constituent null hypothesis" (p. 6). Endnote 5 adds that the
      constituent alpha "cannot be higher than" the joint alpha (p. 30).
      The power cost is Rubin's own example: two constituent tests "each
      tested with a power value of .80" give "a power level of .64, which
      is lower than the desired power of .80" (p. 7). This matches the
      .80 × .80 = .64 figure this entry gave. Rubin's examples are clinical
      (a therapy "effective on both cognition and global clinical scores",
      p. 7); "co-primary endpoints" is powerkit's term, not his.
    - Rubin also says conjunction suits theory testing: "it is more
      logical for researchers to use conjunction testing rather than
      disjunction testing when they want to make a statistical inference
      about a joint hypothesis that comprises a family of hypotheses that
      belong to the same theory" (p. 17).
    - Rubin (2024) names the mismatch: "an inconsistent correction occurs
      when a researcher corrects their alpha level during multiple testing
      but does not make an inference about a union alternative hypothesis"
      (abstract, p. 1).
    - **Where the maintainer's earlier description differed:** the three
      cases and the correction rules match the papers. The conditions for
      choosing disjunction are fuller in the paper than in the earlier
      description; see
      [`inference-question-design.md`](inference-question-design.md),
      "Guidance on choosing 'any one is enough'".
  - **Rubin on power.** Both papers discuss power: Rubin (2021) returns
    to the low power of conjunction tests several times (author preprint,
    pp. 7, 16, 17, 19 and 20), and Rubin (2024, section 5, p. 4) says
    "Inconsistent corrections also lead to an unjustifiable loss of
    statistical power". Neither paper sets out how to plan N for each
    case. The power targets and N
    in [`inference-question-design.md`](inference-question-design.md) are
    still powerkit's extension.
  - **The competing view:** Frane (2019) (verified, maintainer: the
    reference only; Frane's text not read). As printed in Rubin
    (2024)'s reference list: "Frane, A.V., 2019. Misguided opposition to
    multiplicity adjustment remains a problem. J. Mod. Appl. Stat. Methods
    18 (2), eP2836. https://doi.org/10.22237/jmasm/1556669400." Rubin
    (2024) cites it once, for a phrase: "this is not an "anti-adjustment
    article" (Frane, 2019, p. 3). It is a pro-consistency article!"
    (p. 1). He doesn't summarise Frane's arguments, and they were not
    read here. Rubin (2021) states the view he argues against: "The most
    common view is that alpha adjustment is almost always required during
    multiple testing" (author preprint, p. 2), quoting Bennett et al.
    (2009) and Goeman and Solari (2014) for it (second-hand).
  - Rubin's blog post on redundant corrections
    (markrubin.substack.com) could not be fetched: the session's proxy
    refused the host (403). It is not used here.
  - Maxwell (2004) on the "curse of multiplicities" (second-hand).
  - Tools: power4mome 0.2.1 `rejection_rates(collapse = )` gives "none",
    "all_sig", "at_least_one_sig" and "at_least_k_sig" (opened). Superpower
    0.2.4.1 `ANOVA_power(p_adjust = )` corrects ANOVA effects but reports
    power per effect (opened). powertools 1.0.0 `coprimary.z()`,
    `coprimary.t()` (all) and `altprimary()` (at least one) (opened). Full
    list in [`coverage-roadmap.md`](coverage-roadmap.md), row C2.
- **Who might disagree, and why:**
  - Those who correct by default (the position Frane's title suggests,
    and the "most common view" Rubin, 2021, p. 2, describes) would see
    "no correction" for individual or conjunction testing as too lenient.
  - Rubin argues that alpha adjustment belongs only to disjunction
    testing (Rubin, 2021, author preprint, p. 1, quoted above).
  - Users may not know in advance which claim they will make; asking may
    add a step they can't answer.
  - Rubin discusses the power cost of conjunction tests and of
    inconsistent corrections, but not how to plan N for each case. That
    part is powerkit's extension, to be checked with him.
- **Knock-on effects:**
  - D4 and D6 (the guided route and its study-level result); G7 (any
    correction by default); the methods paragraph must state which of the
    three cases the user chose.
  - E7 and E8 already report power for one chosen effect, with no
    ANOVA-wise correction, which is consistent with individual testing
    (see the E7/E8 note under G7).
  - Disjunction raises the required N (alpha / k); conjunction needs
    joint power, which only a whole-study simulation can give when tests
    are correlated (`decision-tree.md` 3.5 and 4).
- **Recorded in:** `decision-tree.md` 3.5; open question 5; setting
  `several_hypotheses`; [`inference-question-design.md`](inference-question-design.md).

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

**Decided 18 October 2026** (`decisions.md`, "The new design"):
effect-size fields stay empty, with no suggested values. The user chooses
a source (smallest effect worth caring about, meta-analysis, one
published study, pilot, or "I can't justify one") and writes one short
rationale or citation per design, required only to save or export. "I
can't justify one" leads to the smallest detectable effect (G9). Still
open: benchmarks as context (B2), and the schema change for the new
"can't justify" source.

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

**Decided 18 October 2026** (`decisions.md`, "The new design"): the
result keeps the condition and says "would get a significant result",
not "would find it": "If the true effect is d = 0.5, about 8 in 10
studies like this would get a significant result." It names the
effect-size source in the user's own words and adds one line on what
power can't tell you. No verdict words ("justified", "adequate",
"sufficiently powered"), enforced by a test. Still open: the rest of the
draft sentences, and a source for the "observed power" line.

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
  before release.
  - **Maintainer's decision (17 October 2026):** keep the "planned power,
    not observed power" line.
  - **Hoenig and Heisey (2001): still not opened.** DOI
    10.1198/000313001300339897. On 17 October 2026 the DOI resolved at
    doi.org; its metadata gives "The Abuse of Power", John M. Hoenig and
    Dennis M. Heisey, *The American Statistician*, 55(1), 19–24, 2001. The
    publisher's page (tandfonline.com) returned 403 Forbidden, so the
    article itself wasn't read.
    - **Quoted in Uttley (2019)** (second-hand). Uttley (2019, *LEUKOS*,
      15(2–3), 143–162, doi:10.1080/15502724.2018.1533851; opened) quotes
      Hoenig and Heisey (2001, p. 23): "Power calculations tell us how
      well we might be able to characterize nature in the future given a
      particular state and statistical study design, but they cannot use
      information in the data to tell us about the likely states of
      nature" (Uttley, p. 156). Uttley's reference list gives the full
      title as "The abuse of power: the pervasive fallacy of power
      calculations for data analysis". Uttley's own words, same page:
      "Post hoc calculation of observed power, using the observed effect
      size and sample size used, provides almost no information of
      value."
    - The quoted sentence says power calculations can't tell us about
      the state of nature from the data. It does not itself say observed
      power adds "nothing beyond the p-value". That claim still rests on
      Dziak et al. (below), not on a sentence read from Hoenig and Heisey.
    - It is **not** in `refs.bib`.
  - **Dziak, Dierker and Abar: author manuscript opened (17 October
    2026).** "The interpretation of statistical power after the data have
    been gathered", *Current Psychology*, 39(3), 870–877 (online 2018;
    print 2020), DOI 10.1007/s12144-018-0018-1. The published article
    (link.springer.com) served a browser challenge to this session and was
    not opened; its Crossref metadata was. The author manuscript was read
    in full from PMC (PMC7286546, NIHMS1508709; plain text from the PMC
    Open Access data bucket,
    `pmc-oa-opendata.s3.amazonaws.com/PMC7286546.1/PMC7286546.1.txt`).
    Its abstract says post hoc power "is a monotone function of the
    p-value and therefore contains no additional helpful information",
    and its introduction says it explains why post hoc power "should never
    be used in practice, following explanations given by Hoenig and Heisey
    (2001)". This supports the line's claim that observed power "says
    nothing beyond the study's p-value". Mikael Rubin (2025, reference
    list) gives the same journal, volume, pages and DOI. Status: candidate
    for `refs.bib`; the maintainer should check the quotes against the
    published version before adding the entry. It is **not** in
    `refs.bib`.
  - **A third source agreeing:** Mikael Rubin (2025, *International
    Journal of Psychology*, doi:10.1002/ijop.70017; opened): "it has been
    well established (and is worth noting again) that post hoc power
    analyses are useless at best, misleading at worst (Dziak et al.
    2020)" (p. 14 of 15).
  - **The competing view: not fetched.** Joel linked a Replication Index
    post (replicationindex.com/2016/01/14/the-abuse-of-hoenig/). The
    session's proxy refused the host (403), so its author, title, date and
    claim could not be read from the page. `decision-tree.md` 3.1 lists it
    second-hand as "The abuse of Hoenig and Heisey" (2016) and says it
    argues against broad readings of Hoenig and Heisey; that summary is
    still unverified.
- **Who might disagree, and why:**
  - A sentence is easier to read and to copy into a methods section.
  - A number first is quicker to scan.
  - Some find the "observed power" line unnecessary for planning.
  - Those who read Hoenig and Heisey narrowly might find "says nothing"
    too broad: Perugini et al. (2014, p. 319, opened) write that post hoc
    power "can also be useful for characterizing entire domains of
    research" (`decision-tree.md` 3.1). The Replication Index post may
    argue this too (not fetched).
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

**Decided 18 October 2026** (`decisions.md`, "The new design"): a
power curve goes in an explore panel that never changes the saved plan,
for formula designs only in v1. Still open: a curve for simulated
results.

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

- **Question:** the banner said "Prototype: shows which analysis you need;
  it doesn't calculate anything yet.", and each card ended "No numbers are
  calculated in this prototype." Both were out of date for E1–E8, which
  calculate on their input screen.
- **Maintainer's decision (17 October 2026):** make the text accurate.
  - The banner now reads "Prototype: calculations are available for
    E1–E8; other designs show guidance only for now."
  - E1–E8's cards no longer say "No numbers are calculated"; every other
    card keeps it.
  - The input screens that don't calculate yet (E9–E14) say "The
    calculation for this design isn't wired into the prototype yet".
- **Knock-on effects:** when another end point is wired in, the banner's
  list changes with it (`tree.yaml`, `banner`; the card line follows
  `forms.yaml`, `calculates`).
- **Recorded in:** this entry, `tree.yaml` (`banner`) and `forms.yaml`
  (`calculates`).
- **Update (phase 5, part 2, 17 October 2026):** with E9 wired, the banner
  reads "calculations are available for E1–E9", and E9's card no longer
  says "No numbers are calculated".

### B15. The seed for a calculation

- **Question:** which random-number seed does a calculation on the result
  screen use?
- **Before:** a new random seed each time, recorded with the result. The
  same answers entered twice could give slightly different simulated
  results: in the screenshots for PR #34, E2's required N came out as 196,
  198 and 200 on three runs (Monte Carlo noise within the reported 95%
  interval).
- **Options:**
  - a fixed default seed, so the same answers always give the same
    result;
  - a new random seed each time;
  - more replications, so the result moves less from seed to seed (at
    the cost of time).
- **Maintainer's decision (17 October 2026): a fixed default seed is now
  in place.** The seed is 1 (`forms.yaml`, `default_seed`). It is a field
  on every input screen ("Random seed"), which the user can change; it is
  shown on the result screen, recorded in the result (spec and
  reproducibility record) and written into the exported R script. A
  simulated result also says: "Calculated by simulation with [k]
  replications; a different seed can shift the result slightly."
- **What tools and sources do:** not checked for this entry (unsourced).
- **Who might disagree, and why:**
  - A fixed seed avoids confusion when a user reruns and sees a different
    N.
  - A random seed avoids treating one simulated draw as exact.
  - More replications reduce the noise rather than hide it.
- **Knock-on effects:** exact results (E1–E6 by formula, E7, E8) don't
  depend on the seed in practice (Departure 3 for E7 and E8). The seed
  field is shown on every screen, including those whose default doesn't
  simulate.
- **Recorded in:** setting `calculation_seed` (now `fixed`, shown on the
  result screen).

### B16. Simulation for "data that won't meet the assumptions" (E1–E6)

- **Question:** E1–E6 offer Spower simulation "if you expect your data
  won't meet the test's assumptions" (maintainer's decision, 17 October
  2026). As wired, Spower simulates normal data with equal variances
  (Welch's aside), the same assumptions as pwr's formula. So the
  simulation gives the formula's answer up to Monte Carlo noise; it
  doesn't yet model the data the user is worried about.
- **Options:**
  - keep the option as is, and say on the screen that it simulates
    normal data;
  - let the user describe the departure (for example skewness, unequal
    variances, a different distribution), which needs new spec fields
    and Spower's other data generators;
  - remove the option until the spec can describe the departure.
- **What tools and sources do:** Spower's experiment functions accept
  custom data generators (its documentation; not checked in detail for
  this entry).
- **Who might disagree, and why:** offering the option now signals the
  direction; offering it before it does anything different may mislead.
- **Knock-on effects:** the spec format (new fields), validation for each
  new generator.
- **Recorded in:** this entry only (no setting).

### B17. E9's progress indicator: estimated from the usual run time

- **Question:** InteractionPoweR doesn't report its progress, so what
  should E9's progress indicator show while it runs (about 5 seconds for
  power, about 80 seconds for a required N)?
- **Options:**
  - **(a) An estimated bar** from the usual run time, labelled as an
    estimate, with the time so far; it stops at 95% until the run
    finishes, and says when a run is taking longer than usual.
    **In place now (phase 5, part 2).**
  - **(b) A moving "busy" bar with the time so far**, and no estimate.
    Never misleading, but says nothing about how long is left.
  - **(c) Real progress** from the engine, counting finished replications
    or sample sizes searched. The most accurate, but needs the engine to
    report progress from inside the backend's loop (an engine change).
- **Default now:** (a). The usual run times are in `forms.yaml`
  (`background`), measured with the example values on one core; larger
  samples and smaller effects take longer.
- **Knock-on effects:** the same choice applies to E10–E14 if they are
  wired with a progress indicator (`phase5-simulations.md`).
- **Recorded in:** this entry and `forms.yaml` (`background`).

### B18. Asking whether the hypothesis predicts a direction

*Added 18 October 2026, for the maintainer's meeting with Mark Rubin.*

- **Question:** the inputs screen pre-fills a two-sided test, with a
  reason asked only if it is changed (G8, decided). Should powerkit ask
  "Do you predict a direction?" instead of using a silent two-sided
  default?
- **Options:**
  - keep the silent two-sided default, with a reason asked only if it
    is changed (as decided for G8);
  - ask "Do you predict a direction?" on every design that supports a
    one-sided test, with two-sided pre-selected;
  - ask it, with nothing pre-selected.
- **What tools and sources do:**
  - G\*Power asks for the number of tails (B3, opened).
  - pwr and Spower default to two-sided (`forms.yaml`
    `alternative_source`, read from the installed packages).
  - Rubin (2024, p. 7; verified, maintainer) lists, as a ritual habit,
    using "a two-sided test when a one-sided test is more consistent with
    one's statistical inference" (G8, archived).
  - The prototype already has a closing question, Q-dir ("Does your
    hypothesis predict a direction?"), on E1–E5, tied to the
    `one_sided_tests` setting (B3).
- **Who might disagree, and why:**
  - Asking makes the choice visible and matches Rubin's point.
  - A silent default is quicker, and many journals treat one-sided
    tests as suspect unless preregistered (unsourced, as in B3).
- **Knock-on effects:** B3 (a preregistration note for one-sided
  tests); the write-up states the tails and the reason; one-sided tests
  beyond E1–E5 need engine support.
- **Recommendation:** keep the two-sided default for now, and ask Mark
  Rubin whether "Do you predict a direction?" is better. Reason: the
  default follows the wrapped tools, and Rubin's view is the one the
  change would rest on.
- **Recorded in:** this entry; `decisions.md` (18 October 2026);
  setting `one_sided_tests`.

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
  - G\*Power's Fisher's exact test: confirmed in G\*Power 3.1.9.7's Tests
    menu (Proportions: "Two independent groups: Fisher's exact"), from the
    maintainer's list, 17 October 2026.
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

**Decided 18 October 2026** (`decisions.md`, "The new design"): the
start screen asks first whether N is fixed and what the aim is, so
"what do you want to find out?" moves to the start. Still open: how the
start screen joins the design finder without asking twice
(`routing-design-options.md`, "Screen A as the start of the profile";
`judgement-session.md`, item 1).

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
  - It adds scope, and a choice (individual, "at least one" or "all")
    that is itself contested (B6).
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

### E6. Saving projects

*Added 18 October 2026; for the maintainer's judgement session.*

- **Question:** how, if at all, can users keep their work: the route,
  inputs, seed, results and versions of an analysis?
- **Options** (details in [`saving-projects.md`](saving-projects.md)):
  - (a) a project file the user saves and loads;
  - (b) autosave in the browser's storage;
  - (c) share links that carry the inputs in the address;
  - (d) private result links for background jobs;
  - (e) user accounts with stored projects (for example Supabase);
  - none (as now: only the R script and citations can be downloaded).
- **What tools and sources do:**
  - G\*Power: whether and how it saves analyses is unknown (not checked;
    the maintainer's screenshots could show it).
  - Shiny's `enableBookmarking()` (shiny's help page, opened 18 October
    2026): "two types of bookmarking: saving an application's state to
    disk on the server, and encoding the application's state in a URL";
    URL encoding suits apps with few inputs, since "Some browsers have a
    length limit for URLs of about 2000 characters".
  - powerkit's spec is already a JSON file with a schema, and every result
    records its seed, versions and spec hash (opened: the schema and
    `run_spec()`'s provenance).
- **Who might disagree, and why:**
  - Users who move between computers want stored projects; data
    protection officers prefer that nothing is stored.
  - A file is easy to lose; accounts are a barrier to a quick check.
- **Knock-on effects:** hosting (options (c) to (e) need a server, (d)
  and (e) need storage and GDPR duties); the About panel's "Nothing is
  sent from this app" line would change for (d) and (e); a file format
  that future versions must read.
- **Recorded in:** this entry; [`saving-projects.md`](saving-projects.md);
  a draft PR implements (a) for review.

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

## G. Coverage and scope

Added on 17 October 2026 with [`coverage-roadmap.md`](coverage-roadmap.md),
which lists every test and design powerkit might cover, with its status.

**Checks closed (17 October 2026).** ANCOVA ("ANCOVA: main effects and
interactions", Means) and Fisher's exact test ("Two independent groups:
Fisher's exact", Proportions) are both in G\*Power 3.1.9.7's Tests menu, as
listed by the maintainer. This closes the open check in `coverage.md`
(the 2023 manual's contents list no ANCOVA chapter) and the second-hand
source for Fisher's exact test in C11.

### G1. Scope for the G\*Power tests powerkit doesn't run

- **Question:** for a G\*Power test powerkit doesn't run, what does the
  user see?
- **Options:**
  - a card that says "G\*Power covers this" (naming G\*Power);
  - add the tests later, in waves (for example, first the ones a
    foundation tool already does);
  - out of scope, with no card.
- **What the roadmap shows:** of G\*Power's 49 tests, powerkit runs 10
  (validated, and wired in the app since PR #34), 4 are planned, 23 a foundation tool can do
  but aren't planned, 11 no foundation tool covers (Hotelling's T²,
  MANOVA, the unconditional exact tests and the five generic tests), and
  1 needs checking ([roadmap](coverage-roadmap.md), Part A).
- **What tools and sources do:** `coverage.md` proposes "not planned" for
  the generic tests ("the full-model builder and R script export are the
  route") and for variance tests ("rare as a study's main hypothesis in
  psychology") (opened). The build guide says basic tests are for
  "G\*Power parity" (opened).
- **Who might disagree, and why:**
  - Users who come from G\*Power expect every test there.
  - Naming G\*Power on a card is naming another tool, which A1 leaves
    open.
  - Waves keep scope small but leave gaps that users meet first.
- **Knock-on effects:** A1 (naming tools); new cards or none; validation
  work per test added.
- **Recorded in:** this entry; [`coverage-roadmap.md`](coverage-roadmap.md),
  Part A.

### G2. Frequentist or Bayesian in the screening

- **Question:** does the screening ask whether the analysis is
  frequentist or Bayesian, and where does Bayesian planning sit?
- **Options:**
  - a screening question (S5, or a sixth profile question in the "design
    profile" options in [`routing-design-options.md`](routing-design-options.md));
  - after Q1 or among the closing questions (D3's options);
  - only in the shortcut list;
  - Bayesian planning as its own route, separate from the screening.
- **What tools and sources do:**
  - None of the tools reviewed routes between p-values and Bayes factors
    (D3) (opened).
  - The build guide puts Bayesian design analysis at "Later", with
    Spower and BFDA as likely backends (opened).
  - Spower documents "expected power" with an effect drawn from a prior,
    and user-written Bayes-factor, posterior-probability and ROPE
    experiments (its help and vignette, opened 17 October 2026; roadmap
    rows B58–B62).
- **Who might disagree, and why:**
  - Bayesian users want to say so early.
  - Most users plan with p-values; an extra screening question adds a
    step for them and invites answers they aren't sure of.
  - Expected power over a prior can be offered to frequentist users too,
    so it may not belong behind a Bayesian question.
- **Knock-on effects:** D3; the screening (C1); which end points need a
  Bayesian version.
- **Recorded in:** this entry; D3; roadmap B58–B62 and C12.

### G3. Which cross-cutting features belong in v1

- **Question:** which of the roadmap's Part C features go into v1?
- **Options (each separately):** alpha correction (C1); joint power
  across hypotheses (C2); attrition (C3, already in the engine); unequal
  allocation (C4, two-group tests now); unreliability (C5, E9 now);
  non-normal data and unequal variances (C6); covariates (C7);
  one- vs two-tailed (C8, basic tests now); effect-size formats and
  conversion (C9); bias-corrected effect sizes (C10); power curves and
  sensitivity plots (C11); Bayesian framework (C12).
- **What tools and sources do:** the build guide lists "attrition and
  missing data, unequal group sizes, measurement reliability,
  multiple-comparison correction, non-normal data, and a sensitivity
  analysis" as options "every design needs" (opened). Which foundation
  tool supports each is in the roadmap, Part C.
- **Who might disagree, and why:**
  - Each feature added to v1 needs validation for every end point it
    applies to.
  - Leaving one out (for example covariates) can make the planned N
    wrong for the analysis people actually run.
- **Knock-on effects:** spec fields, input screens, validation, the
  methods paragraph.
- **Recorded in:** this entry; [`coverage-roadmap.md`](coverage-roadmap.md),
  Part C.

### G4. Which outputs the methods paragraph must report

Decided; moved to [`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md#g4-which-outputs-the-methods-paragraph-must-report).

### G5. Showing the actual power at the rounded N

Decided; moved to [`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md#g5-showing-the-actual-power-at-the-rounded-n).

### G6. The method for correlations (E4), and for two proportions (E5)

Decided; moved to [`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md#g6-the-method-for-correlations-e4-and-for-two-proportions-e5).

### G7. A multiple-testing correction by default

Decided; moved to [`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md#g7-a-multiple-testing-correction-by-default).

### G8. Alpha and the number of tails as required inputs, with a reason

Decided; moved to [`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md#g8-alpha-and-the-number-of-tails-as-required-inputs-with-a-reason).

### G9. Sensitivity analysis: first-class, or the default when no effect size can be justified

Decided; moved to [`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md#g9-sensitivity-analysis-first-class-or-the-default-when-no-effect-size-can-be-justified).
