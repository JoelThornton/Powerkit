# Card sources

*Last updated: 16 October 2026.*

Every factual claim on the routing prototype's end-point cards, with where
it comes from. A claim is anything the card states as fact: what a tool
supports, what a test assumes, which direction a bias goes, what powerkit
runs and how it was validated.

**Status:**
- **sourced:** the claim appears in a source the repository records
  (`coverage.md` and its source tags, the validation log, the engine code,
  `conventions.md`, `decisions.md`, the build guide, or a package's own
  documentation cited in `decision-tree.md`);
- **partly sourced:** part of the claim is recorded, part isn't (the Source
  column says which part);
- **unsourced:** no source is recorded. These are listed, not deleted, for
  the maintainer to source, reword or remove.

The table was built from `app/routing/tree.yaml`. Each tool line was
checked automatically against `coverage.md` (the package's name, and each
function the line names), and the other claims by hand. A test checks that
every card with tools, card text or card points has rows here. Where a row
cites `coverage.md`, that page's own source tags ([Sp], [SP], [p4m], [IP],
[GP] and so on) give the original source and say whether it was read
first-hand.

**Counts:** no claim: 1, partly sourced: 2, sourced: 90, unsourced: 51

| Card | Where on the card | Claim | Source | Status |
| --- | --- | --- | --- | --- |
| E1 | Status line | Full validation run passed. No published example has been checked for this design yet. | docs/validation-log.md; engine/tests/testthat/test-validation-basic-tests.R | sourced |
| E1 | Backend | Spower: Spower() with p_t.test() | engine/R (backend code) | sourced |
| E2 | Status line | Full validation run passed. A check against a published example is still to come. | docs/validation-log.md; engine/tests/testthat/test-validation-basic-tests.R | sourced |
| E2 | Backend | Spower: Spower() with p_t.test() | engine/R (backend code) | sourced |
| E3 | Status line | Full validation run passed. A check against a published example is still to come. | docs/validation-log.md; engine/tests/testthat/test-validation-basic-tests.R | sourced |
| E3 | Backend | Spower: Spower() with p_t.test(type = 'paired') | engine/R (backend code) | sourced |
| E4 | Status line | Full validation run passed. A check against a published example is still to come. | docs/validation-log.md; engine/tests/testthat/test-validation-basic-tests.R | sourced |
| E4 | Backend | Spower: Spower() with p_r() | engine/R (backend code) | sourced |
| E5 | Status line | Full validation run passed. A check against a published example is still to come. | docs/validation-log.md; engine/tests/testthat/test-validation-basic-tests.R | sourced |
| E5 | Backend | Spower: Spower() with p_prop.test() (no continuity correction) | engine/R (backend code); docs/conventions.md, Departure 5 | sourced |
| E6 | Status line | Full validation run passed. No published example has been checked for this design yet. | docs/validation-log.md; engine/tests/testthat/test-validation-basic-tests.R | sourced |
| E6 | Backend | Spower: Spower() with p_chisq.test() | engine/R (backend code) | sourced |
| E7 | Status line | Full validation run passed. Smallest detectable effect is available for this design. | docs/validation-log.md; engine/tests/testthat/test-validation-anova-2x2-between.R | sourced |
| E7 | Backend | Superpower: ANOVA_exact() (ANOVA_power() if simulation is chosen) | engine/R (backend code) | sourced |
| E8 | Status line | Full validation run passed. Smallest detectable effect is available for this design. | docs/validation-log.md; engine/tests/testthat/test-validation-anova-2x2-mixed.R | sourced |
| E8 | Backend | Superpower: ANOVA_exact() | engine/R (backend code) | sourced |
| E9 | Status line | Full validation run passed on 16 October 2026. A check against a published example is still to come. | docs/validation-log.md; engine/tests/testthat/test-validation-regression-interaction.R | sourced |
| E9 | Backend | InteractionPoweR: power_interaction() (power_interaction_r2() only brackets N) | engine/R; docs/conventions.md (regression interaction) | sourced |
| E10 | Status line | Full validation run passed on 16 October 2026. A check against a published example is still to come. | docs/validation-log.md; engine/tests/testthat/test-validation-mediation-simple.R | sourced |
| E10 | Backend | power4mome: power4test() with test_indirect_effect(), Monte Carlo CI | engine/R (backend code) | sourced |
| E11 | Status line | Full validation run passed on 16 October 2026, with two mediators; three or more not yet tested. A check against a published example is still to come. | docs/validation-log.md; engine/tests/testthat/test-validation-mediation-parallel.R | sourced |
| E11 | Backend | power4mome: power4test() with test_indirect_effect() | engine/R (backend code) | sourced |
| E12 | Status line | Full validation run passed on 15 October 2026, with two mediators; three or more not yet tested. A check against a published example is still to come. | docs/validation-log.md; engine/tests/testthat/test-validation-mediation-serial.R | sourced |
| E12 | Backend | power4mome: power4test() with test_indirect_effect() | engine/R (backend code) | sourced |
| E13 | Status line | The full run of 16 October 2026 passed, but a later fix to how power4mome calls are seeded changed this design's results slightly, so it will be … | docs/validation-log.md; engine/tests/testthat/test-validation-modmed-process7.R | sourced |
| E13 | Backend | power4mome: power4test() with test_index_of_mome() | engine/R (backend code) | sourced |
| E14 | Status line | The full run of 16 October 2026 passed, but a later fix to how power4mome calls are seeded changed this design's results slightly, so it will be … | docs/validation-log.md; engine/tests/testthat/test-validation-modmed-process14.R | sourced |
| E14 | Backend | power4mome: power4test() with test_index_of_mome() | engine/R (backend code) | sourced |
| E15 | Backend | InteractionPoweR: power_interaction() with k.x1 / k.x2 = 2 (planned) | docs/build-guide.md (planned backend); docs/decisions.md | sourced |
| E15 | Coming soon | Planned next: a yes/no X or W. | docs/build-guide.md, section 8 (phase 3b) | sourced |
| E15 | What you would enter | Groups are always 50/50 for interactions (InteractionPoweR has no unequal split) | docs/decisions.md (group split); docs/coverage.md (Binary X or W) | sourced |
| E16 | Backend | power4mome: power4test() with x_fun = rbinary_rs() (planned) | docs/build-guide.md (planned backend); docs/decisions.md | sourced |
| E16 | Coming soon | Planned next: a yes/no X or W. | docs/build-guide.md, section 8 (phase 3b) | sourced |
| E17 | Backend | power4mome: power4test() with rbinary_rs() (planned) | docs/build-guide.md (planned backend); docs/decisions.md | sourced |
| E17 | Coming soon | Planned next: a yes/no X or W. | docs/build-guide.md, section 8 (phase 3b) | sourced |
| E17 | What you would enter | A yes/no X or W must be uncorrelated with the other predictors (fits a randomised condition) | docs/build-guide.md (correlated predictors); docs/decisions.md | sourced |
| E18 | Tool: Superpower | Factorial ANOVA power from means, SDs and correlations (between, within and mixed designs, up to three factors). | coverage.md (the row or section naming Superpower; its source tags give the original) | sourced |
| E19 | Tool: Superpower | Power for emmeans contrasts (pairwise, custom, simple effects) in factorial designs. | coverage.md (the row or section naming Superpower; its source tags give the original) | sourced |
| E19 | Tool: pwranova | Analytic power for planned contrasts in between- or within-factor ANOVA (pwrcontrast()). | coverage.md (the row or section naming pwranova; its source tags give the original) | sourced |
| E20 | Tool: Superpower | Factorial ANOVA power from means, SDs and correlations, including within-participants designs ("2w*2w"). | coverage.md (the row or section naming Superpower; its source tags give the original) | sourced |
| E21 | Tool: Superpower | Factorial ANOVA up to three factors, 2 to 99 levels each, any mix of between and within. | coverage.md (the row or section naming Superpower; its source tags give the original) | sourced |
| E21 | Tool: pwranova | Analytic power for any number of between and within factors (default cap six), from partial eta-squared or Cohen's f. | coverage.md (the row or section naming pwranova; its source tags give the original) | sourced |
| E22 | Tool: Superpower | Documents unequal group sizes for ANOVA_power() only: ANOVA_design() help, argument n ("If unequal n is entered then the design can only be passed … | Superpower ANOVA_design() help (argument n) and NEWS 0.0.3; docs/conventions.md, 'Superpower and unequal group sizes' | sourced |
| E23 | Tool: Superpower | Analytic ANCOVA power from cell means, SD and the covariates' R-squared (ANCOVA_analytic(), power_oneway_ancova()). | coverage.md (the row or section naming Superpower; its source tags give the original) | sourced |
| E23 | Tool: pwrss | Analytic power for ANCOVA (Keppel and Shieh methods) and many other common tests. | coverage.md (the row or section naming pwrss; its source tags give the original) | sourced |
| E24 | Tool: Spower | Simulation power for R-squared and R-squared change (p_lm.R2()) and any linear hypothesis in a regression (p_glm()). | coverage.md (the row or section naming Spower; its source tags give the original) | sourced |
| E24 | Tool: pwrss | Analytic power for regression coefficients and R-squared. | coverage.md (the row or section naming pwrss; its source tags give the original) | sourced |
| E25 | Tool: Spower | Simulation power for one proportion against a constant (p_prop.test(), binomial test). | coverage.md (the row or section naming Spower; its source tags give the original) | sourced |
| E26 | Tool: Spower | Simulation power for McNemar's test (p_mcnemar.test()). | coverage.md (the row or section naming Spower; its source tags give the original) | sourced |
| E26 | Status | No ready-made tool (Cochran's Q) | coverage.md (row for this design: no tool found) | sourced |
| E27 | Tool: Spower | Simulation power for generalised linear models with fixed predictors, including logistic (p_glm(family = binomial())). | coverage.md (the row or section naming Spower; its source tags give the original) | sourced |
| E27 | Tool: pwrss | Analytic power for logistic regression. | coverage.md (the row or section naming pwrss; its source tags give the original) | sourced |
| E28 | Tool: Spower | Simulation power for Poisson regression (p_glm(family = poisson())). | coverage.md (the row or section naming Spower; its source tags give the original) | sourced |
| E28 | Tool: pwrss | Analytic power for Poisson regression. | coverage.md (the row or section naming pwrss; its source tags give the original) | sourced |
| E29 | Tool: Hmisc | popower() and posamsize(): power and sample size for comparing two groups on an ordinal outcome (proportional odds). | coverage.md (the row or section naming Hmisc; its source tags give the original) | sourced |
| E29 | Tool: powertools | propodds(): power for proportional-odds comparisons. | coverage.md (the row or section naming powertools; its source tags give the original) | sourced |
| E30 | Tool: Spower | For a custom simulation: a general Monte Carlo power engine where you write the data-generating and analysis code yourself. | coverage.md (Spower as a general Monte Carlo engine); Spower documentation | sourced |
| E30 | Status | No ready-made tool (Moderator with three or more groups) | coverage.md (row for this design: no tool found) | sourced |
| E31 | Tool: InteractionPoweR | power_interaction_3way_r2(): analytic power for three-way interactions, with reliabilities. | coverage.md (the row or section naming InteractionPoweR; its source tags give the original) | sourced |
| E32 | Tool: Spower | For a custom simulation: a general Monte Carlo power engine where you write the data-generating and analysis code yourself. | coverage.md (Spower as a general Monte Carlo engine); Spower documentation | sourced |
| E32 | Status | No ready-made tool (Moderation or mediation with a yes/no, count or categorical outcome) | coverage.md (row for this design: no tool found) | sourced |
| E33 | Tool: simr | Simulation power for (generalised) linear mixed models fitted with lme4, including models built without pilot data (makeLmer()). | coverage.md (the row or section naming simr; its source tags give the original) | sourced |
| E33 | Tool: mixpower | Design-first simulation power for linear and generalised linear mixed models (newer, released 2026). | coverage.md (the row or section naming mixpower; its source tags give the original) | sourced |
| E34 | Tool: mlmpower | Power for multilevel models specified by variance explained, with within- and between-cluster effects and random slopes. | coverage.md (the row or section naming mlmpower; its source tags give the original) | sourced |
| E34 | Tool: PAMLj | jamovi module with power for mixed models (search over the number of clusters or cluster size). | coverage.md (the row or section naming PAMLj; its source tags give the original) | sourced |
| E35 | Tool: longpower | Power for longitudinal mixed models, GLS and GEE. | coverage.md (the row or section naming longpower; its source tags give the original) | sourced |
| E35 | Tool: powRICLPM | Simulation power for random-intercept cross-lagged panel models. | coverage.md (the row or section naming powRICLPM; its source tags give the original) | sourced |
| E35 | Tool: PowerAnalysisIL | Shiny app for intensive longitudinal (experience sampling) designs. | coverage.md (the row or section naming PowerAnalysisIL; its source tags give the original) | sourced |
| E36 | Tool: TOSTER | Power for equivalence tests (TOST) for t-tests, correlations, proportions and F tests. | coverage.md (the row or section naming TOSTER; its source tags give the original) | sourced |
| E37 | Tool: semPower | A priori, post hoc and compromise power for SEM, including CFA, measurement invariance and RMSEA-based fit. | coverage.md (the row or section naming semPower; its source tags give the original) | sourced |
| E38 | Tool: power4mome | Power for any mediation or moderated mediation model written in lavaan syntax (no ready-made template for these models). | coverage.md (the row or section naming power4mome; its source tags give the original) | sourced |
| E39 | Tool: Spower | For a custom simulation: a general Monte Carlo power engine where you write the data-generating and analysis code yourself. | coverage.md (Spower as a general Monte Carlo engine); Spower documentation | sourced |
| E39 | Status | No ready-made tool (Mediation with a yes/no or categorical mediator) | coverage.md (row for this design: no tool found) | sourced |
| E40 | Tool: power4mome | Power for any moderated mediation model written in lavaan syntax (no ready-made template). | coverage.md (the row or section naming power4mome; its source tags give the original) | sourced |
| E41 | Tool: mlmpower | Power for multilevel models (moderation, cross-level effects). No tool found for within-person mediation. | coverage.md (the row or section naming mlmpower; its source tags give the original) | sourced |
| E41 | Tool: simr | Simulation power for mixed models fitted with lme4. | coverage.md (the row or section naming simr; its source tags give the original) | sourced |
| E42 | Tool: Spower | For a custom simulation: a general Monte Carlo power engine where you write the data-generating and analysis code yourself. | coverage.md (Spower as a general Monte Carlo engine); Spower documentation | sourced |
| E42 | Status | Not covered by the five tools powerkit builds on | coverage.md (the row for this design) | sourced |
| E42 | Status | No ready-made tool (Mediation with a condition of three or more groups (multi-category X)) | coverage.md (row for this design: no tool found) | sourced |
| E43 | Card text | powerkit doesn't cover outcomes that are the time until something happens (survival or time-to-event analysis), where some people may not reach the … | — (censoring is a standard feature of time-to-event data; no source recorded) | unsourced |
| E43 | Card text | Established tools exist for this design; powerkit hasn't checked them. | — | unsourced |
| E44 | Card text | powerkit doesn't cover data from pairs of people whose scores are related (dyadic data), such as couples or a parent and child. Treating the two … | Maintainer's wording (16 October 2026); no published source recorded | unsourced |
| E44 | Card text | Established tools exist for this design; powerkit hasn't checked them. | — | unsourced |
| E45 | Tool: Spower | For a custom simulation: a general Monte Carlo power engine where you write the data-generating and analysis code yourself. | coverage.md (Spower as a general Monte Carlo engine); Spower documentation | sourced |
| E45 | Status | No ready-made tool (Many measurements over time: segmented regression or interrupted time series) | — | unsourced |
| E45 | Card point | With a known breakpoint (for example, the date an intervention started), the change in slope can be treated as an added predictor in a regression (a … | Maintainer's specification (routing-audit task, 16 October 2026); no published source recorded | unsourced |
| E45 | Card point | With a breakpoint that is estimated from the data, a custom simulation is needed. | Maintainer's specification (routing-audit task, 16 October 2026); no published source recorded | unsourced |
| E45 | Card point | With time-series data, autocorrelation (each measurement depending on the previous ones) makes standard power calculations too optimistic. | Maintainer's specification (routing-audit task, 16 October 2026); no published source recorded | unsourced |
| E45 | Card point | A before/after comparison of means (a t-test) asks a different question: whether the average level differs, not whether the trend changes. | Maintainer's specification (routing-audit task, 16 October 2026); no published source recorded | unsourced |
| E46 | Card text | Planning a sample size for a target confidence-interval width is a different calculation from power. powerkit doesn't do it yet. | coverage.md, 'Precision (AIPE)' rows (planned; MBESS, Spower precision criterion) | sourced |
| E46 | Card text | Established tools exist for this design; powerkit hasn't checked them. | coverage.md, 'Precision (AIPE)' rows (Spower, MBESS) | sourced |
| E47 | Card text | powerkit doesn't cover designs with two or more crossed factors and a yes/no outcome yet (for example, whether people book a flu jab after a gain or … | — (describes the design only) | no claim |
| E47 | Card text | Established tools exist for this design; powerkit hasn't checked them. | coverage.md, 'Logistic regression' row (Spower p_glm(); G*Power, second-hand) | partly sourced |
| E-bayes | Tool: bfpwr | Analytic power and sample size for z-test, t-test and normal-moment-prior Bayes factors. | coverage.md (the row or section naming bfpwr; its source tags give the original) | sourced |
| E-bayes | Tool: BFDA | Bayes factor design analysis by simulation, fixed-N and sequential (GitHub, not on CRAN). | coverage.md (the row or section naming BFDA; its source tags give the original) | sourced |
| All cards with a justification prompt | Where your effect size comes from | powerkit asks for a justification and never uses a 'medium effect' default | docs/build-guide.md, section 4 (effect_justification) | sourced |
| All cards with a justification prompt | Where your effect size comes from | A pilot study: you'll see a warning, because pilot estimates are very imprecise | docs/decisions.md (pilot_study gives a warning); the reason itself has no source recorded | partly sourced |
| Not-in-powerkit cards | Status | No ready-made tool: options are a custom simulation in R (e.g. Spower) or advice from a statistician | coverage.md (Spower as a general engine); maintainer's wording | sourced |
| E2 | Closing question Q-test | Student's or Welch's t-test. | decision-tree.md, table 2.2 (Q-test; decision D7) | sourced |
| E7, E8 | Closing question Q-test | Exact (analytic) or simulation. | decision-tree.md, table 2.2 (Q-test); engine (options.method) | sourced |
| Cards with closing questions | Closing question Q-goal | The smallest detectable effect isn't available for this design yet. Observed power (from the study's own result) is not offered. | decision-tree.md, table 2.2 (Q-goal row); engine (sensitivity for the 2 x 2 designs) | sourced |
| Cards with closing questions | Closing question Q-goal | All three are available for this design. Observed power (from the study's own result) is not offered. | decision-tree.md, table 2.2 (Q-goal row); engine (sensitivity for the 2 x 2 designs) | sourced |
| Cards using the term | Hint: Cohen's d | A difference between two averages, measured in standard deviations: 0.5 means the averages are half a standard deviation apart. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: d_z | The average change within people (for example, after minus before), divided by how much that change varies from person to person. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: SD (standard deviation) | How spread out the scores are around their average. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: pooled SD | The two groups' standard deviations combined into one, weighted by the groups' sizes. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: SD units | Differences expressed in standard deviations rather than in the outcome's own units (raw). | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: Student's or Welch's test | Two versions of the t-test: Student's assumes the two groups' scores are equally spread out; Welch's doesn't. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: correlation (r) | A number from -1 to 1 for how closely two measures go up and down together; 0 means no straight-line relationship. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: repeated measurements | The same people measured more than once (for example, before and after, or in each condition); their scores on different occasions usually go … | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: cell means | The expected average in each combination of the factors, such as praise with a hard task (each combination is a 'cell'). | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: factor and levels | A factor is something you vary or compare (for example, feedback); its levels are its versions (for example, praise and none). | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: between factor and within factor | A between factor has different people at each level; a within factor has the same people at every level. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: interaction | Whether the effect of one factor or variable depends on the level of another. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: reliability | How consistently a measure gives the same result; 1 means no measurement error. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: standardised paths | The strength of each arrow in the model (for example, X to M), expressed in standard deviations so that arrows between differently scaled measures … | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: Monte Carlo draws per CI | How many random draws are used to build each confidence interval for the indirect effect; more draws give a more stable interval. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: residuals | The part of each mediator that X doesn't explain; their correlation says how much the mediators overlap beyond X. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: indirect path | The route from X to the outcome through a mediator (X to M to Y). | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: contrast weights | Numbers that say which groups a specific comparison sets against which (for example, 1, 1 and -2 compare the first two groups together with the … | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: adjusted group means | Group averages after taking the covariate into account. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: covariate | A variable measured alongside the outcome (for example, a before score) that the analysis takes into account. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: R-squared | The share of the differences in the outcome that the predictors explain, from 0 to 1. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: R-squared change | How much R-squared goes up when the predictor or predictors of interest are added. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: discordant proportions | Among people measured twice, the share who change from yes to no and the share who change from no to yes. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: odds ratio | How many times higher the odds of 'yes' (the chance of yes divided by the chance of no) are in one group than in another; 1 means no difference. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: regression coefficients | How much the outcome is expected to change for a one-unit change in a predictor. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: rate ratio | How many times higher the average count is in one group than in another; 1 means no difference. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: product terms | Two predictors multiplied together (for example, x1 times x2), which is how a regression represents an interaction. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: fixed effects | The effects you're testing (for example, of a condition), taken to be the same for everyone. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: variance components | How much scores vary because some participants, and some stimuli, score higher or lower than others overall. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: intraclass correlation (ICC) | How similar people in the same group (for example, the same class) are, compared with people in different groups, from 0 to 1. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: cluster size | How many people there are in each group (for example, pupils per class). | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: equivalence bounds | The smallest difference you would care about, in each direction; a difference inside them counts as negligible. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: RMSEA | A number summarising how far a model's predictions are from the data, allowing for the model's complexity; smaller means a closer fit. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: relative indirect effects | With three or more groups, the indirect effect for each group compared with one chosen reference group. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: breakpoint | The point in time at which the trend may change (for example, when an intervention started). | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: level and slope | The level is how high the trend is; the slope is how fast it rises or falls. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: autocorrelation | How much each measurement depends on the ones just before it. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: mediator | A variable through which X affects the outcome (a go-between). | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: predictor | A variable used to explain or predict the outcome. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: confidence interval (CI) | A range of plausible values for an effect, estimated from the data. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: model parameters | The numbers that define a model, such as the strength of each path. | — (standard definition; no source recorded) | unsourced |
| Cards using the term | Hint: prior | The range of effect sizes you consider plausible before seeing the data, written as a distribution. | — (standard definition; no source recorded) | unsourced |

## Unsourced or partly sourced claims

For the maintainer to source, reword or remove:

- **E43, Card text** (unsourced): powerkit doesn't cover outcomes that are the time until something happens (survival or time-to-event analysis), where some people may not reach the …
- **E43, Card text** (unsourced): Established tools exist for this design; powerkit hasn't checked them.
- **E44, Card text** (unsourced): powerkit doesn't cover data from pairs of people whose scores are related (dyadic data), such as couples or a parent and child. Treating the two …
- **E44, Card text** (unsourced): Established tools exist for this design; powerkit hasn't checked them.
- **E45, Status** (unsourced): No ready-made tool (Many measurements over time: segmented regression or interrupted time series)
- **E45, Card point** (unsourced): With a known breakpoint (for example, the date an intervention started), the change in slope can be treated as an added predictor in a regression (a …
- **E45, Card point** (unsourced): With a breakpoint that is estimated from the data, a custom simulation is needed.
- **E45, Card point** (unsourced): With time-series data, autocorrelation (each measurement depending on the previous ones) makes standard power calculations too optimistic.
- **E45, Card point** (unsourced): A before/after comparison of means (a t-test) asks a different question: whether the average level differs, not whether the trend changes.
- **E47, Card text** (partly sourced): Established tools exist for this design; powerkit hasn't checked them.
- **All cards with a justification prompt, Where your effect size comes from** (partly sourced): A pilot study: you'll see a warning, because pilot estimates are very imprecise
- **Glossary hints** (unsourced): all 42 plain-English definitions. They are standard definitions, but no source is recorded for them.
