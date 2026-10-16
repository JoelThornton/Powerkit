# Routing audit: designs powerkit doesn't cover

*Last updated: 16 October 2026.*

**Why this audit.** A tester described a segmented regression: a change in
slope at a breakpoint. The routing prototype sent them to a paired t-test,
and on another path to an independent t-test. That is a misroute. A
before/after comparison of means asks a different question from a change in
trend.

**What was checked.** Each design below was traced through the three routes
of the routing prototype ([`routing-prototype.md`](routing-prototype.md)) as
they stood on `main` at commit 099b6d3, before this PR:

- **I know my analysis:** the list of end points;
- **Help me choose:** the question tree;
- **Plan my whole study:** the guided route.

Each design gets one of these verdicts:

| Verdict | Meaning |
| --- | --- |
| **Covered (E*n*)** | powerkit runs it, or will run it, at that end point. |
| **Honest card (E*n*)** | The route ends at a card that says powerkit doesn't cover this design. |
| **MISROUTES** | The route ends at an end point for a different analysis. The path is given. |
| **Not reachable** | No answer leads anywhere that names the design. |
| **Judgement needed** | Whether the end point fits depends on a statistical judgement the docs don't make. The question is stated, not decided. |

Paths are written as the answers clicked, from the first question, using
the labels on `main`. The **After this PR** column gives the new behaviour.
The screening questions S1–S4 and the "None of these fit / I'm not sure"
option on every question are described in
[`decision-tree.md`](decision-tree.md), section 2.2.

## The two segmented regression paths

| | Path on `main` | Reached | After this PR |
| --- | --- | --- | --- |
| **Path 1 (paired t-test)** | A difference between groups or conditions → A score or scale → The same people in every condition → One → Two, with the same people in both (or one group measured twice) | **E3 paired t-test: MISROUTES** | Screening: S1 A score → S2 Independent people → S3 Many times → T1 Over time, to see whether a trend changes at a known point → **E45** (no ready-made tool). The screening comes first in every route, so no test is suggested. |
| Path 1, variant | … → The same people measured over time → Twice (for example, before and after) → One → Two, with the same people in both | **E3: MISROUTES** | As above. Someone who answers S3 "Twice" still reaches the before/after tests. That is right for two measurements, and S3's wording separates the two cases (see open question 16). |
| **Path 2 (t-test)** | A difference between groups or conditions → A score or scale → Different people in each group or condition → One → Two, with different people in each | **E2 independent t-test: MISROUTES** (the periods before and after the breakpoint treated as two groups) | As path 1: **E45**. |
| Path 3 (correlation) | A relationship between two things you measure → A score or scale → Each person is measured once, on both variables → A score or scale | **E4 correlation: MISROUTES** (time as the "other variable"; a linear correlation can't show a change in slope) | As path 1: **E45**. |
| Guided route | Main predictor: a condition with two groups (before/after) → outcome: a score → "The effect of X on the outcome" | **E2: MISROUTES** | Screening comes first: **E45**. |

## All designs

Abbreviations: **K** = I know my analysis; **C** = Help me choose; **G** =
Plan my whole study. Under C, "diff", "rel", "mod" and "med" are the Q1
answers "a difference", "a relationship", "moderation" and "mediation".

### Dependence

| Design | K (on `main`) | C (on `main`) | G (on `main`) | After this PR |
| --- | --- | --- | --- | --- |
| Nested or multilevel data | Honest card (E34) | diff + score: "People are nested in groups" → honest card (E34). rel, mod, med: "The same people repeatedly, or people nested in groups" → honest card (E41). **MISROUTES** with a yes/no outcome: diff → Yes/no → Different people, two groups, yes/no outcome → **E5** (Q3 for categories has no "nested" answer) | **MISROUTES**: the scope note asks users to go elsewhere, but nothing stops them. A cond2 X with a score outcome reaches **E2** | S2 "People within groups" → **E34** in every route and for every outcome |
| Crossed random effects (participants × stimuli) | Honest card (E33) | diff + score: "People respond to many items or stimuli" → honest card (E33). **MISROUTES** with a yes/no outcome per trial (e.g. accuracy): diff → Yes/no → The same people in every condition → **E26** McNemar. rel has no stimuli answer: Each person is measured once → Score → **E4** (**MISROUTES**) | **MISROUTES** (as above: E2 or E4) | S2 "Many trials or stimuli per person" → **E33** in every route |
| Cluster-randomised designs | Honest card (E34) | Honest (E34) if the user answers "People are nested in groups". **MISROUTES** if they answer "Different people in each group or condition": diff → Score → Different people → One → Two, with different people → **E2**. Nothing asks whether groups, rather than people, were assigned. With a yes/no outcome: **E5** | **MISROUTES** (E2) | S2 "People within groups (including when whole groups, such as classes, were assigned)" → **E34** |
| Dyadic data (couples, parent–child) | **Not reachable** | **MISROUTES**: no answer describes pairs. E.g. rel → Score → Each person is measured once → Score → **E4**, which treats partners' scores as independent | **MISROUTES** (E4 or E2) | S2 "Pairs (e.g. couples)" → **E44**, a generic card. **Judgement needed:** matched-pairs designs analysed with a paired t-test may belong at E3 instead (decision-tree.md, open question 19) |
| Longitudinal: growth curves | Honest card (E35) | diff + score: "The same people measured over time" → Three or more times → honest card (E35). rel, mod, med: → honest card (E41) | **MISROUTES**: the baseline covariate leads to E23 or E8 for a study with many waves | S3 "Many times" → T1 "Over time, to see how people change" → **E35** |
| Longitudinal: diary or EMA | Honest card (E35, "experience sampling"; E41) | Honest card (E35 or E41) as for growth curves | **MISROUTES** (as for growth curves) | S3 "Many times" → T1 → **E35** |
| Longitudinal: time series (many measurements of one unit) | **Not reachable** (E35 is about people measured on a few occasions) | Score: "The same people measured over time" → Three or more → E35, an honest card that doesn't mention autocorrelation. Counts per period: diff → A count → **E28** (honest that counts aren't covered, but for the wrong reason). **Judgement needed** on whether E35 fits | **MISROUTES** (E2 or E4) | S3 "Many times" → T1 "Over time, to see whether a trend changes at a known point" → **E45**, which states the autocorrelation point. Time series with a count outcome stop at S1 → E28 first. **Judgement needed:** the right card for a count time series |
| Longitudinal: segmented regression or interrupted time series | **Not reachable** | **MISROUTES** (paths above: E3, E2, E4) | **MISROUTES** (E2) | **E45** (paths above) |

### Outcome type

| Design | K (on `main`) | C (on `main`) | G (on `main`) | After this PR |
| --- | --- | --- | --- | --- |
| Binary outcome | Covered (E5, E6); honest cards (E25, E26, E27) | Covered: diff → Yes/no → E5, E6; honest cards E25, E26, E27; rel → Yes/no → E27. mod, med → honest card (E32) | Covered (E5); honest cards (E27, E32) | Unchanged after S1 "Yes/no, or one of several categories". The yes/no tests powerkit runs (E5, E6) stay reachable |
| Count outcome | Honest card (E28) | diff → A count → honest card (E28). mod, med → honest card (E32). **Judgement needed:** rel offers no count answer, so a count is likely entered as "A score or scale" and reaches **E4** (correlation on a count) | Honest card (E28, E32) | S1 "A count" → **E28** in every route |
| Single ordinal item | Honest card (E29) | diff → A rating on a few points → O5a: as a score → continues (decision D1); as ordered categories → honest card (E29). **Judgement needed:** rel, mod and med don't ask, so a rating goes in as "A score or scale" without D1's note | Honest card (E29) | S1 "Ordered categories (e.g. a single rating item)" → O5a in every route: as a score continues (D1); as ordered categories → **E29** |
| Time-to-event outcome | **Not reachable** | **MISROUTES**: no answer fits. Time in days entered as a score reaches E2, E4 and the rest | **MISROUTES** | S1 "The time until something happens" → **E43**, a generic card |

### Goal

| Design | K (on `main`) | C (on `main`) | G (on `main`) | After this PR |
| --- | --- | --- | --- | --- |
| Equivalence or non-inferiority | Honest card (E36) | Q1 "That an effect is absent, or too small to matter" → honest card (E36). **Judgement needed:** E36 names TOST and minimum-effect tests, not non-inferiority by name | **MISROUTES**: the guided route has no goal question, so it plans a test to detect an effect | S4 "Show there's no meaningful effect (equivalence or non-inferiority)" → **E36** in every route |
| Precision (CI width) | **Not reachable** | **MISROUTES**: no answer fits. Users answer Q1 as if detecting an effect and reach a power end point (E2, E4 and the rest). Power and precision planning answer different questions | **MISROUTES** | S4 "Estimate an effect precisely (a target confidence-interval width)" → **E46**, a generic card |
| Sequential designs with interim looks | **Not reachable** | Not reachable: no question asks about interim analyses, so a sequential design reaches a fixed-sample end point. **Judgement needed:** whether that counts as a misroute | As C | **Not fixed** (listed, see "What's left"). The safety net is available at every question |

### Extensions

| Design | K (on `main`) | C (on `main`) | G (on `main`) | After this PR |
| --- | --- | --- | --- | --- |
| ANCOVA or covariates | Honest card (E23) | Pre–post: … → Yes: before and after → … → ANCOVA → honest card (E23). rel → R1 "controlling for other variables" → honest card (E24). **Judgement needed:** a two-group comparison with a non-baseline covariate isn't asked about and reaches E2. Powering without the covariate is usually conservative rather than wrong | Honest card (E23, E24) | Unchanged. Listed under "What's left" |
| Multiple outcomes (MANOVA) | **Not reachable** | Not reachable: users pick one outcome. The closing question Q-multi asks about several hypotheses (judgement call 3.5). **Judgement needed:** whether powering each outcome separately is acceptable or a misroute | Not reachable | Unchanged; the safety net is available. Listed under "What's left" |
| Unequal variances | Covered (E2 Welch; E7, E8 cell SDs) | Covered (Q-test: Student or Welch) | Covered | Unchanged |
| Attrition or missing data | Covered (Q-attr, every design) | Covered (Q-attr) | Covered | Unchanged. **Judgement needed:** missing data beyond simple attrition (e.g. planned missingness) isn't asked about |
| Curvilinear effects | **Not reachable** | **MISROUTES**: rel → Score → Each person is measured once → Score → **E4** (a linear correlation for a curved relationship) | **MISROUTES** (E4) | **Not fixed**: the safety net is offered at R1, but the E4 answer is still there. Listed under "What's left" (judgement needed: whether E24 with a quadratic term is the right card) |
| Non-parametric tests | **Not reachable** | Not reachable: users reach the t-tests (E2, E3). **Judgement needed:** whether planning a rank test with t-test power is a misroute | As C | Unchanged. Listed under "What's left" |

### Specialised

| Design | K (on `main`) | C (on `main`) | G (on `main`) | After this PR |
| --- | --- | --- | --- | --- |
| SEM with latent variables | Honest card (E37, "SEM model fit") | Q1 "That a model or questionnaire structure fits" → honest card (E37). **MISROUTES** when the hypothesis is a path between latent variables: med → … → **E10** (observed-variable mediation) | **MISROUTES** (E10) | Q1's answer now names "a model with latent variables (SEM)" → **E37**. The med path is still there for people who don't recognise their model as SEM. **Judgement needed:** whether E10 with reliabilities is ever an acceptable stand-in |
| CFA | Honest card (E37) | Honest card (E37) | Not reachable | Unchanged |
| Measurement invariance | Honest card (E37) | Honest card (E37) | Not reachable | Unchanged |
| Reliability or ICC | **Not reachable** | **MISROUTES**: test–retest reliability entered as a relationship reaches **E4** (power to detect r > 0, not the precision of a reliability coefficient). **Judgement needed** on the right card | Not reachable | S4 "Estimate an effect precisely" → E46 catches planning for a CI width. The rel path to E4 is still there. Listed under "What's left" |
| Factor analysis (exploratory) | **Not reachable** (E37 is confirmatory) | Not reachable. The nearest answer is "That a model or questionnaire structure fits" → E37 | Not reachable | Unchanged; the safety net is available |
| IRT | **Not reachable** | Not reachable | Not reachable | Unchanged; the safety net is available |
| Meta-analysis | **Not reachable** | Not reachable | Not reachable | Unchanged; the safety net is available |
| Network models | **Not reachable** | Not reachable | Not reachable | Unchanged; the safety net is available |

## What's left

**Fixed in this PR** (tested in `app/routing/tests/testthat/test-misroutes.R`):
- every route now starts with the four screening questions (S1–S4);
- every question has "None of these fit / I'm not sure", which leads to
  E-unsure;
- these misroutes now reach the right end point:
  - the segmented regression paths;
  - nested, crossed, cluster-randomised and dyadic data;
  - time series;
  - time-to-event outcomes;
  - precision;
  - equivalence in the guided route;
  - SEM with latent variables, through Q1's wording.

**Still misrouting or not reachable.** These are left for the maintainer,
because each needs a statistical judgement or a new end point that the docs
don't define:

1. **Curvilinear effects:** rel → … → E4. Is the right card E24 (regression
   with a quadratic term) or a generic card?
2. **Reliability or ICC planning** entered as a relationship: → E4.
3. **Non-parametric tests:** reach the t-tests. Is that a misroute?
4. **Sequential designs:** reach fixed-sample end points. Is that a
   misroute?
5. **Multiple outcomes (MANOVA):** reach single-outcome end points.
6. **Covariates other than a baseline,** in a two-group comparison: reach
   E2. This is probably conservative rather than wrong.
7. **Latent-variable mediation** entered as mediation: reaches E10.
8. **Matched pairs** answered as "Pairs" at S2: reach the dyadic card
   (E44), although a paired t-test (E3) may be right.
9. **Counts and ratings in the rel, mod and med paths:** now caught at S1.
   Whether decision D1 (a rating may be analysed as a score) applies beyond
   differences is still open.

Exploratory factor analysis, IRT, meta-analysis and network models reach no
end point. The safety net now gives them an honest exit on every screen.
