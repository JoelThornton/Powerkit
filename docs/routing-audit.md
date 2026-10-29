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
| Dyadic data (couples, parent–child) | **Not reachable** | **MISROUTES**: no answer describes pairs. E.g. rel → Score → Each person is measured once → Score → **E4**, which treats partners' scores as independent | **MISROUTES** (E4 or E2) | S2 "Pairs (e.g. couples)" → **E44**, a generic card. Its text says that treating partners as independent can overstate or understate power, depending on whether the predictor varies between or within dyads (reworded after the walkthroughs, F9). **Judgement needed:** matched-pairs designs analysed with a paired t-test may belong at E3 instead (decision-tree.md, open question 19) |
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
| Equivalence or non-inferiority | Honest card (E36) | Q1 "That an effect is absent, or too small to matter" → honest card (E36). **Judgement needed:** E36 names TOST and minimum-effect tests, not non-inferiority by name | **MISROUTES**: the guided route has no goal question, so it plans a test to detect an effect | S4 "Show there's no meaningful effect (equivalence or non-inferiority)" → **E36** in every route. E36's title now names non-inferiority (walkthroughs, F13); its tool line is unchanged |
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
| Reliability or ICC | **Not reachable** | Test–retest reliability entered as a relationship: after S3's "Twice" (how a test–retest study would answer), rel reaches **E41** (relationships measured within people), not E4. Only after "Once" does it reach **E4** (power to detect r > 0, not the precision of a reliability coefficient). Corrected on 16 October 2026 from the walkthroughs (flag F11); routing unchanged. **Judgement needed** on the right card | Not reachable | S4 "Estimate an effect precisely" → E46 catches planning for a CI width. The rel path still reaches E41 after "Twice" (E4 after "Once"). Listed under "What's left" |
| Factor analysis (exploratory) | **Not reachable** (E37 is confirmatory) | Not reachable. The nearest answer is "That a model or questionnaire structure fits" → E37 | Not reachable | Unchanged; the safety net is available |
| IRT | **Not reachable** | Q1 "Something about latent variables: that a model or questionnaire structure fits, that a questionnaire measures the same in two groups, or a path between factors (SEM)" → **E37** (the SEM and CFA card). Corrected on 16 October 2026 from the walkthroughs (flag F7). The card now says IRT designs aren't covered | Not reachable | Unchanged routing; E37 now says IRT isn't covered. The safety net is available |
| Meta-analysis | **Not reachable** | Not reachable | Not reachable | Unchanged; the safety net is available |
| Network models | **Not reachable** | Not reachable | Not reachable | Unchanged; the safety net is available |

## Cross-check against the UCLA OARC test-selection table

**Source.** UCLA OARC Statistical Methods and Data Analytics, [*Choosing
the Correct Statistical Test in SAS, Stata, SPSS and R*](https://stats.oarc.ucla.edu/other/mult-pkg/whatstat/).
The page credits James D. Leeper, from whose table it is adapted with his
permission. It is a widely used map from a study's variables to a test.
Its table and text are not reproduced here. The rows below use only the
names of the analyses it lists, grouped and described in our own words,
and each is traced through powerkit's routes after this PR.

**What it doesn't cover.** The table assumes independent observations. It
has no rows for nested, clustered or time-series data, crossed random
effects, dyads, time-to-event outcomes, equivalence or precision. So the
audit above still applies to those designs. This cross-check adds to it
and doesn't replace it.

**The list.** The list of analyses was checked against the page on 16
October 2026. The table has 31 distinct analyses, grouped below by design
rather than in the table's order. The chi-square test appears twice, once for two groups and once for two or
more, so it has two rows here (32 rows in all).

**Routes.** Paths start after the screening answers shown, with "detect
an effect" at S4. **K** is "I know my analysis"; **G** is "Plan my whole
study". Verdicts are as defined at the top of this page.

### One group against a fixed value

| Analysis (UCLA OARC row) | Help me choose (after this PR) | K | G | Verdict |
| --- | --- | --- | --- | --- |
| One-sample t-test | Score, once → difference → One → One group, compared with a fixed value → E1 | E1 | Not offered (the guided route needs a predictor X); safety net | **Covered (E1)** |
| One-sample median | As the t-test → E1. As ordered categories (S1 → O5a) → E29 | E1, E29 | As above | **Judgement needed** (judgement call 3.8): is a t-test's power an acceptable plan for a median test? |
| Binomial test | Yes/no, once → difference → One group, compared with a fixed proportion → E25 | E25 | Not offered; safety net | **Honest card (E25)** |
| Chi-square goodness-of-fit | Yes/no or categories, once → difference: no answer for one variable with three or more categories against expected proportions. The nearest are "One group, compared with a fixed proportion" → E25, a single proportion, and "outcome in categories" → E6, a test of independence | Not by name | Not offered | **MISROUTES** (to E25 or E6). Not fixed. E6 is a test of independence only: its template needs two categorical variables and a table of at least 2 x 2. Spower's `p_chisq.test()` does goodness-of-fit with a probability vector, so the question is whether to extend E6 or give it its own card (judgement call 3.7) |

### Two groups

| Analysis (UCLA OARC row) | Help me choose (after this PR) | K | G | Verdict |
| --- | --- | --- | --- | --- |
| Two independent samples t-test | Score, once → difference → One → Two, with different people in each → E2 | E2 | X: two groups, outcome: score → E2 | **Covered (E2)** |
| Wilcoxon–Mann–Whitney | As the t-test → E2; as ordered categories → E29 | E2, E29 | E2 | **Judgement needed** (rank-based test; judgement call 3.8) |
| Chi-square test (two groups) | Yes/no or categories, once → difference → Different people, two groups, yes/no outcome → E5 (two proportions), or Different people, outcome in categories → E6. Also: relationship → One of several categories → E6 | E5, E6 | Yes/no outcome, two groups → E5; outcome "One of several categories", two groups → E6 (added after the walkthroughs, F2) | **Covered (E5, E6)** |
| Fisher's exact test | As the chi-square test → E5 or E6 | E5, E6 | E5 | **Judgement needed** (judgement call 3.9): at small samples, an exact test's power differs from that of the large-sample test E5 plans for. Spower, E5's backend, has an exact option (`p_prop.test(exact = TRUE)`) |
| Paired t-test | Score, twice → difference → One → Two, with the same people in both → E3 | E3 | After S3 "Twice": X "The same people in two conditions, or before and after" → E3 (added after the walkthroughs, F1; before, a two-group X led to E2) | **Covered (E3)** |
| Wilcoxon signed ranks | As the paired t-test → E3 | E-unsure (not on the list by name) | As the paired t-test → E3 | **Judgement needed** (rank-based test; judgement call 3.8) |
| McNemar | Yes/no, twice → difference → The same people in every condition → E26 | E26 | After "Twice": X "The same people in two conditions, or before and after", outcome yes/no → E26 (F1; before, E5) | **Honest card (E26)** |

### Three or more groups

| Analysis (UCLA OARC row) | Help me choose (after this PR) | K | G | Verdict |
| --- | --- | --- | --- | --- |
| One-way ANOVA | Score, once → difference → One → Three or more → Any difference among the groups → E18 (or a specific comparison → E19) | E18, E19 | X: three or more groups → E18 | **Honest card (E18, E19)** |
| Kruskal–Wallis | As the one-way ANOVA → E18 | E18 | E18 | **Judgement needed** (rank-based test; judgement call 3.8) |
| Chi-square test (two or more groups) | Yes/no or categories, once → difference → Different people, outcome in categories → E6 (any table of at least 2 x 2: groups by outcome categories) | E6 | X three or more groups, outcome "One of several categories" → E6 (F2; before, E27) | **Covered (E6)** |
| One-way repeated measures ANOVA | Score, many times → The same people in three or more conditions → difference → One → Three or more → Any difference among the conditions → E54 | E54 | Sent to "Help me choose" (three or more conditions per person) | **Runs (E54, 27 October 2026)** |
| Friedman | As the repeated measures ANOVA → E54 | E54 | As above | **Judgement needed** (rank-based test; judgement call 3.8) |
| Repeated measures logistic regression | Yes/no, twice or many times → difference → The same people in every condition → E26 (McNemar's test or Cochran's Q). Many yes/no trials per person stop at S2 → E33 | E26, E33 | Not offered | **Honest card (E26 or E33).** **Judgement needed:** does a model-based analysis of repeated yes/no outcomes need its own card? |

### Two or more factors

| Analysis (UCLA OARC row) | Help me choose (after this PR) | K | G | Verdict |
| --- | --- | --- | --- | --- |
| Factorial ANOVA | Score, once → difference → Two, crossed → Yes: 2 x 2 → Both factors: different people → … → E7. Larger designs → E21; within or mixed → E8, E20 | E7, E8, E20, E21 | X two groups × W two groups → E7 | **Covered (E7, E8)** for 2 x 2; **honest card (E20, E21)** otherwise |
| Ordered logistic regression | Ordered categories → O5a → As ordered categories → E29 | E29 | Not offered (S1 sends ordered categories to O5a first) | **Honest card (E29)** |
| Factorial logistic regression | Yes/no, once → difference → **Two or more factors (e.g. a 2 x 2 design), yes/no outcome → E47**. Before the UCLA cross-check, Q3 had no answer for two factors and the nearest led to E5; the cross-check sent it to E27 | E47 | Moderation: X two groups, W two groups, yes/no outcome → **E47** (before: E32) | **Honest card (E47)**, the same in every route (walkthroughs, F3). E47 is a generic card with the neutral sentence "Established tools exist for this design; powerkit hasn't checked them." Whether it names tools is open question 18. **Not changed:** "Help me choose" through Q1's moderation answer, with a yes/no outcome, still leads to E32 for this design (see "What's left") |

### Relationships and regression

| Analysis (UCLA OARC row) | Help me choose (after this PR) | K | G | Verdict |
| --- | --- | --- | --- | --- |
| Correlation | Score, once → relationship → A score or scale → E4 | E4 | X: a score, outcome: score → E4 | **Covered (E4)** |
| Simple linear regression | As correlation → E4 | E4 | E4 | **Covered (E4):** the test of the slope in a simple regression is the same test as the test of r |
| Non-parametric correlation | As correlation → E4 | E4 | E4 | **Judgement needed** (rank-based test; judgement call 3.8) |
| Simple logistic regression | Yes/no, once → relationship → Yes/no → E27 | E27 | Yes/no outcome, X a score → E27 | **Honest card (E27)** |
| Multiple regression | Score, once → relationship → Several predictors at once, or controlling for other variables → E24 | E24 | X a score with covariates → E24 | **Honest card (E24)** |
| Analysis of covariance | Score, twice → … → before and after → ANCOVA → E23. A covariate other than a baseline isn't asked about in a two-group comparison → E2 | E23 | X two groups with covariates → E23 | **Honest card (E23).** **Judgement needed** for non-baseline covariates (already in "What's left") |
| Multiple logistic regression | As simple logistic regression → E27 | E27 | E27 | **Honest card (E27)** |
| Discriminant analysis | Not reachable: no answer predicts group membership from several scores. Safety net | Not by name | Not offered | **Not reachable** (safety net) |

### Several outcomes, or no outcome

| Analysis (UCLA OARC row) | Help me choose (after this PR) | K | G | Verdict |
| --- | --- | --- | --- | --- |
| One-way MANOVA | Not reachable: users pick one outcome and reach that outcome's end point (e.g. E18) | Not by name | Not offered | **Not reachable.** **Judgement needed** on powering each outcome separately (already in "What's left") |
| Multivariate multiple regression | As MANOVA | Not by name | Not offered | **Not reachable** (as MANOVA) |
| Factor analysis | Q1 "Something about latent variables: that a model or questionnaire structure fits, that a questionnaire measures the same in two groups, or a path between factors (SEM)" → E37 (confirmatory). Exploratory factor analysis isn't reachable by name | E37 | Not offered | **Honest card (E37)** for confirmatory; **not reachable** for exploratory (already in the audit) |
| Canonical correlation | Not reachable | Not by name | Not offered | **Not reachable** (safety net) |

**Result.** Of these analyses:
- every one powerkit runs is covered: the one-sample, independent and paired t-tests, correlation and simple regression, two proportions, the chi-square test (two groups, and two or more), and the 2 x 2 ANOVAs;
- one new misroute was found and fixed: factorial logistic regression now reaches E27;
- one new misroute is left: chi-square goodness-of-fit;
- the rank-based rows (judgement call 3.8), Fisher's exact test (3.9), goodness-of-fit (3.7), MANOVA and repeated yes/no outcomes come down to judgement calls. Each is listed below, and 3.7–3.9 are in [`decision-tree.md`](decision-tree.md), section 3, with the positions, the maintainer's view and the reason each is a judgement call.

## Other defensible analyses for covered end points

For each end point that powerkit runs or will run (E1–E17), this table lists
other analyses that could be defended for the same research question.
Different analyses can need different sample sizes, so a power analysis for
one doesn't carry over to another.

**These lists are drafts, not decisions.** Which analysis a study should use
is a judgement for the researcher, and nothing here recommends one. Some
choices are already judgement calls in [`decision-tree.md`](decision-tree.md):
- simple effects versus the interaction (3.4);
- rank-based tests (3.8);
- Fisher's exact test (3.9).

**The card note is off by default.** The draft note below is written for
the card, and it is hidden behind the setting `other_analyses_note`
(open question 20), so the maintainer can review it first. Its wording is
in `tree.yaml` (`other_analyses_text`), and each card's list is the
`alternatives` field.

| End point | Other defensible analyses | Draft card note |
| --- | --- | --- |
| E1 (One-sample t-test) | the one-sample Wilcoxon signed-rank test; the sign test | Other defensible analyses exist for this design (e.g. the one-sample Wilcoxon signed-rank test; the sign test), and they can need different sample sizes. Power the analysis you plan to run. |
| E2 (Independent-samples t-test (Student's; Welch's as an option)) | Student's or Welch's t-test; the Mann-Whitney test; a permutation test | Other defensible analyses exist for this design (e.g. Student's or Welch's t-test; the Mann-Whitney test; a permutation test), and they can need different sample sizes. Power the analysis you plan to run. |
| E3 (Paired-samples t-test) | the Wilcoxon signed-rank test; the sign test | Other defensible analyses exist for this design (e.g. the Wilcoxon signed-rank test; the sign test), and they can need different sample sizes. Power the analysis you plan to run. |
| E4 (Pearson correlation) | Pearson's, Spearman's or Kendall's correlation | Other defensible analyses exist for this design (e.g. Pearson's, Spearman's or Kendall's correlation), and they can need different sample sizes. Power the analysis you plan to run. |
| E5 (Test of two proportions (z test)) | the z test with or without a continuity correction; Fisher's exact test; logistic regression | Other defensible analyses exist for this design (e.g. the z test with or without a continuity correction; Fisher's exact test; logistic regression), and they can need different sample sizes. Power the analysis you plan to run. |
| E6 (Chi-square test of independence) | the chi-square test with or without a continuity correction (2 x 2 tables); Fisher's exact test; a likelihood-ratio (G) test | Other defensible analyses exist for this design (e.g. the chi-square test with or without a continuity correction (2 x 2 tables); Fisher's exact test; a likelihood-ratio (G) test), and they can need different sample sizes. Power the analysis you plan to run. |
| E7 (2 x 2 between-participants ANOVA (main effect or interaction)) | tests of the simple effects; a planned contrast | Other defensible analyses exist for this design (e.g. tests of the simple effects; a planned contrast), and they can need different sample sizes. Power the analysis you plan to run. |
| E8 (2 x 2 mixed ANOVA (incl. group × time)) | for a before-and-after design, ANCOVA on the after score adjusting for the before score; for a before-and-after design, a t-test on change scores; a mixed model | Other defensible analyses exist for this design (e.g. for a before-and-after design, ANCOVA on the after score adjusting for the before score; for a before-and-after design, a t-test on change scores; a mixed model), and they can need different sample sizes. Power the analysis you plan to run. |
| E9 (Moderated regression (continuous × continuous)) | a latent-variable interaction model that allows for measurement error | Other defensible analyses exist for this design (e.g. a latent-variable interaction model that allows for measurement error), and they can need different sample sizes. Power the analysis you plan to run. |
| E10 (Simple mediation (PROCESS model 4)) | a bootstrap confidence interval; the joint-significance test; the Sobel test | Other defensible analyses exist for this design (e.g. a bootstrap confidence interval; the joint-significance test; the Sobel test), and they can need different sample sizes. Power the analysis you plan to run. |
| E11 (Parallel mediation (PROCESS model 4)) | a bootstrap confidence interval; the joint-significance test; testing each specific indirect effect or the total indirect effect | Other defensible analyses exist for this design (e.g. a bootstrap confidence interval; the joint-significance test; testing each specific indirect effect or the total indirect effect), and they can need different sample sizes. Power the analysis you plan to run. |
| E12 (Serial mediation (PROCESS model 6)) | a bootstrap confidence interval; the joint-significance test; testing the full serial path or each shorter path | Other defensible analyses exist for this design (e.g. a bootstrap confidence interval; the joint-significance test; testing the full serial path or each shorter path), and they can need different sample sizes. Power the analysis you plan to run. |
| E13 (First-stage moderated mediation (PROCESS model 7), index of moderated mediation) | conditional indirect effects at chosen values of W | Other defensible analyses exist for this design (e.g. conditional indirect effects at chosen values of W), and they can need different sample sizes. Power the analysis you plan to run. |
| E14 (Second-stage moderated mediation (PROCESS model 14)) | conditional indirect effects at chosen values of W | Other defensible analyses exist for this design (e.g. conditional indirect effects at chosen values of W), and they can need different sample sizes. Power the analysis you plan to run. |
| E15 (Moderated regression with a yes/no X or W) | a latent-variable interaction model that allows for measurement error | Other defensible analyses exist for this design (e.g. a latent-variable interaction model that allows for measurement error), and they can need different sample sizes. Power the analysis you plan to run. |
| E16 (Mediation with a yes/no X) | a bootstrap confidence interval; the joint-significance test; the Sobel test | Other defensible analyses exist for this design (e.g. a bootstrap confidence interval; the joint-significance test; the Sobel test), and they can need different sample sizes. Power the analysis you plan to run. |
| E17 (Moderated mediation with a yes/no X or W) | conditional indirect effects for each group | Other defensible analyses exist for this design (e.g. conditional indirect effects for each group), and they can need different sample sizes. Power the analysis you plan to run. |

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
  - SEM with latent variables, through Q1's wording;
  - factorial logistic regression (found by the UCLA OARC cross-check):
    a yes/no outcome with two or more factors now reaches E47 in
    "Help me choose" and the guided route.

**Fixed after the walkthroughs** ([`walkthroughs.md`](walkthroughs.md), flags
F1–F3, F5, F9, F13, F14; tested in `test-walkthrough-fixes.R`):
- the guided route uses S3's "Twice": paired designs reach E3 or E26, two
  groups measured twice reach the pre-post question (E23 or E8), and a
  baseline covariate needs "Twice";
- the guided route has an outcome with several categories, reaching E6;
- the end-point list offers only the analyses that fit the screening
  answers;
- factorial logistic regression reaches the same card (E47) in both routes;
- the dyadic card's wording;
- E36 names non-inferiority;
- internal references (decision and departure numbers, build phases, file
  names) are out of user-facing text. They stay in the docs, and in
  `refs:` fields in `tree.yaml` that the app doesn't show.

**Still misrouting or not reachable.** These are left for the maintainer,
because each needs a statistical judgement or a new end point that the docs
don't define:

1. **Curvilinear effects:** rel → … → E4. Is the right card E24 (regression
   with a quadratic term) or a generic card?
2. **Reliability or ICC planning** entered as a relationship: → E41 after
   S3's "Twice" (how a test–retest study would answer), or E4 after "Once".
3. **Non-parametric tests:** reach the t-tests. Now judgement call 3.8 (see item 10).
4. **Sequential designs:** reach fixed-sample end points. Is that a
   misroute?
5. **Multiple outcomes (MANOVA):** reach single-outcome end points.
6. **Covariates other than a baseline,** in a two-group comparison: reach
   E2. This is probably conservative rather than wrong.
7. **Latent-variable mediation** entered as mediation: reaches E10.
8. **Matched pairs** answered as "Pairs" at S2: reach the dyadic card
   (E44), although a paired t-test (E3) may be right.
9. **Chi-square goodness-of-fit** (found by the UCLA OARC cross-check):
   one categorical variable with three or more categories against expected
   proportions has no answer and no end point. It reaches E25 (a single
   proportion) or E6 (a test of independence). E6 is independence only,
   so routing goodness-of-fit there needs a spec change first. Judgement
   call 3.7.
10. **Non-parametric tests, by name:** the UCLA OARC rows for the
    one-sample median, Wilcoxon–Mann–Whitney, Wilcoxon signed-rank,
    Kruskal–Wallis, Friedman and non-parametric correlation tests reach
    the parametric end points (item 3): judgement call 3.8. Spower has
    simulation functions for the Wilcoxon and Mann–Whitney tests
    (`p_wilcox.test()`) and Kruskal–Wallis (`p_kruskal.test()`), but none
    for Friedman. Fisher's exact test reaches the large-sample tests (E5,
    E6): judgement call 3.9. Spower's `p_prop.test(exact = TRUE)` is an
    exact option.
11. **Factorial logistic regression through Q1's moderation answer:**
    "That an effect depends on something else" with a yes/no outcome
    leads to E32 ("no ready-made tool") for every moderation design,
    including two binary factors, which reach E47 by the other paths. Does
    Q2 for moderation need a question that separates them?
12. **Several categories, same people:** an outcome with several
    categories measured twice reaches E26 (McNemar's test or Cochran's Q,
    both for yes/no outcomes), in "Help me choose" and in the guided
    route. Does it need its own card?
13. **Two groups, a yes/no or categorical outcome, measured twice** (e.g.
    yes/no before and after, in a treatment and a control group): the
    guided route now gives the safety net (E-unsure) rather than a wrong
    test. "Help me choose" offers only "The same people in every
    condition" (E26), which compares conditions within people, not
    groups. This needs a routing decision and possibly a new card.
14. **Counts and ratings in the rel, mod and med paths:** now caught at S1.
   Whether decision D1 (a rating may be analysed as a score) applies beyond
   differences is still open.

Meta-analysis and network models reach no end point. IRT reaches E37
through Q1's "a questionnaire structure" answer (E37 now says IRT isn't
covered), and that answer is also the nearest one for exploratory factor
analysis. The safety net now gives all of them an
honest exit on every screen.
