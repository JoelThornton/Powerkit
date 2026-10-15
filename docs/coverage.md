# Coverage matrix

*Last updated: 15 October 2026.*

This page lists the user-facing capabilities of the five tools powerkit
builds on: Superpower, Spower, power4mome, InteractionPoweR and G\*Power.
For each capability it gives powerkit's status. The goal behind it (build
guide, overview) is one place for psychologists to run the power analyses
these tools offer, built on them, crediting them and validated against
them.

Each row comes from the tool's own documentation and source (the versions in
`renv.lock`), not from memory. Where a GitHub development version differs,
this is noted below.

**The tiers are proposals for the maintainer to confirm.** Rows marked
*(proposal)* in the Tier column have not been agreed. Tiers already set in
the build guide (section 2) are marked *(build guide)*.

## How to read the table

| Column | Meaning |
| --- | --- |
| Capability | What a user can do, in plain terms |
| Tool(s) | Which of the five tools offer it, with the function or section and a source tag (see Sources) |
| powerkit | **done** (runs through `run_spec()`), **partial** (some of it), **planned** (in the build plan or proposed here), **not planned** (proposed to leave out, with the reason in Notes) |
| Tier | MVP / v2 / later |
| Validated? | Whether a validation test covers it, with the file in `engine/tests/testthat/`. "Full run passed" means a recorded full validation run ([validation log](validation-log.md)) |
| Notes | Limits, conventions and anything unclear |

## Sources

Package sources were read from the CRAN releases in `renv.lock`, taken from
the CRAN mirror on GitHub (`github.com/cran/<package>`) at the release tag,
and from each package's own GitHub repository for the development version.

| Tag | Source |
| --- | --- |
| [SP] | Superpower 0.2.4.1 (CRAN; `renv.lock`): `man/`, vignettes `intro_to_superpower`, `more_anova_designs`, `ANCOVAs`, `compromise_power`, `emmeans_power` |
| [SP-dev] | Superpower on GitHub (`arcaldwell49/Superpower`, commit c606a92, 24 April 2026; version 0.2.4.2) |
| [SP-book] | Caldwell, Lakens et al., *Power Analysis with Superpower* (book source, `arcaldwell49/SuperpowerBook`, commit 6dde62d), including "Appendix 2: Direct Comparison to MOREpower" |
| [Sp] | Spower 0.6.4 (CRAN; `renv.lock`): `man/`, `README`, vignettes `SpowerIntro`, `SpowerIntro_logicals`, `Spower_TypeSM`, `gpower_examples` |
| [Sp-dev] | Spower on GitHub (`philchalmers/Spower`, commit 862b867, 15 October 2026; version 0.7) |
| [p4m] | power4mome 0.2.1 (CRAN; `renv.lock`): `man/`, vignettes `power4mome`, `power4test_latent_mediation` |
| [p4m-dev] | power4mome on GitHub (`sfcheung/power4mome`, commit 253f83e, 14 October 2026; version 0.2.1.33), including the website articles in `vignettes/articles/` and `NEWS.md` |
| [IP] | InteractionPoweR 0.2.4 (CRAN; `renv.lock`): `man/`, `R/`, `NEWS.md` |
| [IP-dev] | InteractionPoweR on GitHub (`dbaranger/InteractionPoweR`, commit f4f2b2b, 23 March 2026): the website articles in `vignettes/articles/` (main vignette, three-way, covariates, stability, common questions) and `README` |
| [GP] | G\*Power 3.1 manual (Faul, Erdfelder, Buchner & Lang; edition of 1 June 2023 on the HHU site). **Not read in this session:** its host was not reachable from the build environment. G\*Power rows are taken from the manual example numbers and titles that Spower's `gpower_examples` vignette reproduces ([GP via Sp]), or from the manual's contents as shown in web search results ([GP, search]). [GP: to check] marks rows with no source yet. **Every G\*Power row needs checking against the manual.** |
| [powerkit] | This repository: `engine/inst/schema/design.schema.json`, `engine/R/`, `docs/conventions.md` |

## Differences between the CRAN and development versions

- **Spower 0.7 (GitHub) vs 0.6.4.** One-sided tests: `p_r()`, `p_2r()`,
  `p_prop.test()`, `p_ks.test()`, `p_scale()` and others gain an
  `alternative` argument passed to the underlying test, replacing the
  halved two-sided p-value. `two.tailed` is removed from `p_anova.test()`,
  `p_mcnemar.test()` and `p_mediation()`. This is the upstream fix behind
  powerkit's Departure 4 ([conventions](conventions.md)). The set of
  exported functions is unchanged [Sp, Sp-dev].
- **power4mome 0.2.1.33 (GitHub) vs 0.2.1.** New in the development version
  [p4m-dev, `NEWS.md`]: power for SAM (structural-after-measurement,
  `lavaan::sam()`); `rig_rs()` for correlated non-normal variables;
  `test_fit_measure()` (rejection rate from a fit measure); model
  misspecification keys (`.beta_nil.`, `.fm.`), including for multigroup
  models; `common_processes()` (ordinal, missing and scale-score processing
  together); missing data by variable pattern, wave and attrition rate;
  several tests in one `power4test()` call; plotting of ordinal cut
  patterns. The website articles are only in the GitHub repository (they
  are not in the CRAN package), and the website was built with 0.2.1.31.
- **InteractionPoweR (GitHub) vs 0.2.4.** Same R code (differences are line
  endings and packaging); the website articles are only on GitHub.
- **Superpower 0.2.4.2 (GitHub) vs 0.2.4.1.** Only a fix to the plotting
  code for current ggplot2 (`aes_string()` replaced). That is the source of
  the two ggplot2 deprecation warnings seen in powerkit's test run with
  0.2.4.1.

## Basic tests

| Capability | Tool(s) | powerkit | Tier | Validated? | Notes |
| --- | --- | --- | --- | --- | --- |
| One-sample t-test | Spower `p_t.test(type = "one.sample")` [Sp]; G\*Power t test, means: difference from constant (Example 20.3) [GP via Sp] | done | MVP *(build guide)* | Yes: `test-validation-basic-tests.R` (full run passed; G\*Power published values TODO) | One-sided tests follow Departure 4 |
| Independent-samples t-test, equal or unequal groups, Student or Welch | Spower `p_t.test()` with `n2_n1`, `var.equal` [Sp]; G\*Power t test, two independent means [GP via Sp] | done | MVP *(build guide)* | Yes: `test-validation-basic-tests.R` | Unequal groups via `options > allocation_ratio` |
| Paired-samples t-test | Spower `p_t.test(type = "paired")` [Sp]; G\*Power t test, matched pairs (Example 19.3) [GP via Sp] | done | MVP *(build guide)* | Yes: `test-validation-basic-tests.R` | Effect size d_z |
| Pearson correlation against 0 | Spower `p_r()` [Sp]; G\*Power exact test, bivariate normal model [GP via Sp] | done | MVP *(build guide)* | Yes: `test-validation-basic-tests.R` | |
| Correlation against a constant other than 0 | Spower `p_r(rho = )` [Sp]; G\*Power Example 3.3 [GP via Sp] | planned | v2 *(proposal)* | No | |
| Two independent correlations | Spower `p_2r()` [Sp]; G\*Power Example 27.3 [GP via Sp] | planned | v2 *(proposal)* | No | |
| Two dependent correlations (common index or none) | Spower `p_2r()` [Sp]; G\*Power Examples 28.3.1, 28.3.2 [GP via Sp] | planned | later *(proposal)* | No | |
| Point-biserial correlation | G\*Power Example 16.3, reproduced in Spower's vignette [GP via Sp] | planned | v2 *(proposal)* | No | |
| Tetrachoric, polychoric and polyserial correlation | Spower `p_r.cat()` [Sp]; G\*Power Example 31.3 (tetrachoric) [GP via Sp] | planned | later *(proposal)* | No | |
| One proportion against a constant (binomial or exact) | Spower `p_prop.test()` (`binom.test()`) [Sp]; G\*Power exact test, proportion: difference from constant (Example 4.3) [GP via Sp] | planned | v2 *(proposal)* | No | |
| Two independent proportions | Spower `p_prop.test()` [Sp]; G\*Power [GP via Sp] | done | MVP *(build guide)* | Yes: `test-validation-basic-tests.R` | No continuity correction (Departure 5) |
| Fisher's exact test for two proportions | Spower `p_prop.test(exact = TRUE)` [Sp]; G\*Power Fisher's exact test [GP, search] | planned | v2 *(proposal)* | No | |
| Two dependent proportions (McNemar) | Spower `p_mcnemar.test()` [Sp]; G\*Power Example 5.3 [GP via Sp] | planned | v2 *(proposal)* | No | |
| Chi-square test of independence | Spower `p_chisq.test()` [Sp]; G\*Power chi-square tests [GP, search] | done | MVP *(build guide)* | Yes: `test-validation-basic-tests.R` | |
| Chi-square goodness of fit | Spower `p_chisq.test(w, df)` or `P0`/`P` [Sp] | planned | v2 *(proposal)* | No | |
| Sign test, generic binomial test | G\*Power exact tests [GP, search] | planned | later *(proposal)* | No | Check in the manual |
| Variance tests (one-sample against a constant; two groups; Levene, Bartlett, Fligner) | Spower `p_var.test()` [Sp]; G\*Power Examples 26.3, 15.3 [GP via Sp] | not planned | later *(proposal)* | No | Rare as a study's main hypothesis in psychology |
| Scale tests (Ansari-Bradley, Mood) | Spower `p_scale()` [Sp] | not planned | later *(proposal)* | No | |
| Wilcoxon signed-rank and Mann-Whitney tests, with a chosen parent distribution | Spower `p_wilcox.test()` with `parent1`, `parent2` [Sp]; G\*Power Examples 22.1, 22.3, 23.3 (normal and Laplace parents) [GP via Sp] | planned | v2 *(proposal)* | No | Goes with non-normal data (below) |
| Kruskal-Wallis test | Spower `p_kruskal.test()` [Sp] | planned | later *(proposal)* | No | |
| Kolmogorov-Smirnov, Shapiro-Wilk, Mauchly's sphericity test | Spower `p_ks.test()`, `p_shapiro.test()`, `p_mauchly.test()` [Sp] | not planned | later *(proposal)* | No | Assumption checks rather than hypotheses |
| Generic t, F, chi-square and z tests from a noncentrality parameter | G\*Power "generic" tests [GP, search] | not planned | later *(proposal)* | No | The full-model builder and R script export are the route for unusual tests |
| Equivalence test (TOST) for t-tests | Spower, through a confidence-interval criterion (`is.CI_within()`; `SpowerIntro_logicals`, "Equivalence testing") [Sp]; Superpower, equivalence contrasts through `emmeans_power()` [SP] | planned | v2 *(build guide)* | No | |
| Precision (AIPE): n for a target CI width | Spower, precision criterion (`SpowerIntro_logicals`, "Precision criterion") [Sp] | planned | v2 *(build guide)* | No | |
| Type S and Type M errors | Spower (`Spower_TypeSM` vignette) [Sp] | planned | later *(proposal)* | No | |

## Linear and generalised linear regression

| Capability | Tool(s) | powerkit | Tier | Validated? | Notes |
| --- | --- | --- | --- | --- | --- |
| Multiple regression: R² against 0, or R² increase over a set of predictors (fixed predictors) | Spower `p_lm.R2(R2, k, R2_0, k.R2_0)` [Sp]; G\*Power Examples 13.1, 14.3 [GP via Sp] | planned | v2 *(proposal)* | No | |
| Multiple regression with random predictors | Spower `p_lm.R2(fixed = FALSE)` [Sp]; G\*Power Example 7.3 [GP via Sp] | planned | later *(proposal)* | No | |
| Simple linear regression slope | Spower `p_slr()` [Sp]; G\*Power Example 12.3 [GP via Sp] | planned | v2 *(proposal)* | No | |
| Regression for two groups (slopes or intercepts) | G\*Power Examples 17.3, 18.3, reproduced in Spower's vignette [GP via Sp] | planned | later *(proposal)* | No | Check in the manual |
| Any linear hypothesis in a linear or generalised linear model with fixed predictors | Spower `p_glm(formula, X, betas, test)`, tested with `car::lht()` [Sp] | not planned as a form | later *(proposal)* | No | A candidate backend for the full-model builder |
| Logistic regression | Spower `p_glm(family = binomial())` [Sp]; G\*Power z test, logistic regression [GP, search] | planned | v2 *(build guide)* | No | |
| Poisson regression | Spower `p_glm(family = poisson())` [Sp]; G\*Power z test, Poisson regression [GP, search] | planned | v2 *(build guide)* | No | |

## Factorial ANOVA

| Capability | Tool(s) | powerkit | Tier | Validated? | Notes |
| --- | --- | --- | --- | --- | --- |
| 2x2 between-participants ANOVA | Superpower `ANOVA_design("2b*2b")`, `ANOVA_exact()`, `ANOVA_power()` [SP]; G\*Power ANOVA: fixed effects, special, main effects and interactions [GP, search] | done | MVP *(build guide)* | Yes: `test-validation-anova-2x2-between.R` (full run passed) | |
| 2x2 mixed ANOVA (one factor between, one within) | Superpower `"2b*2w"` [SP]; G\*Power repeated measures, within-between interaction [GP, search] | done | MVP *(build guide)* | Yes: `test-validation-anova-2x2-mixed.R` (full run passed) | `ANOVA_exact()`, not `ANOVA_exact2()` (Departure 2) |
| 2x2 within-participants ANOVA | Superpower `"2w*2w"` [SP] | planned | v2 *(proposal)* | No | |
| One-way between ANOVA (k groups) | Superpower `"kb"`, `power_oneway_between()` [SP]; Spower `p_anova.test()` with unequal groups (`n.ratios`) and Welch (`var.equal = FALSE`) [Sp]; G\*Power Example 10.3 [GP via Sp] | planned | v2 *(proposal)* | No | |
| One-way within (repeated measures) ANOVA | Superpower `"kw"`, `power_oneway_within()` [SP]; G\*Power repeated measures, within factors [GP, search] | planned | v2 *(proposal)* | No | |
| Factorial designs beyond 2x2: up to three factors, 2 to 99 levels each, any mix of between and within | Superpower `ANOVA_design()` (e.g. `"2b*3w"`, `"2b*2b*2b"`), analytic `power_twoway_between()`, `power_threeway_between()` [SP] | planned | v2 for 2x3, 3x3 and 2x2x2 *(build guide lists 2x2x2)*; later for the rest *(proposal)* | No | |
| Unequal group sizes in between-participants designs | Superpower `ANOVA_power()` with an `n` vector, between designs only [SP]; Spower `p_anova.test(n.ratios)` [Sp] | not available | v2 *(proposal)* | No | Superpower stops for unequal n with a within factor, and `ANOVA_design()` builds data at max(n). Needs a test proving the sizes are used ([conventions](conventions.md), "Superpower and unequal group sizes") |
| Different SDs per cell | Superpower `sd` vector [SP] | done | MVP | Yes (2x2 tests) | 2x2 array of cell SDs |
| Correlations among repeated measures (full matrix) | Superpower `r` (single value or matrix) [SP] | partial | v2 *(proposal)* | Yes (2x2 mixed) | One `r`; a full matrix is needed once a within factor has more than two levels |
| Sphericity correction (Greenhouse-Geisser, Huynh-Feldt) | Superpower `ANOVA_power(correction = )` [SP]; G\*Power nonsphericity correction [GP, search] | not needed yet | v2 *(proposal)* | No | No effect with two-level within factors |
| MANOVA results for designs with within factors | Superpower `ANOVA_power()` (`manova_results`) [SP]; G\*Power MANOVA and Hotelling's T² [GP, search] | planned | later *(proposal)* | No | |
| Correction for multiple ANOVA effects | Superpower `ANOVA_power(p_adjust = )` [SP] | planned | v2 *(proposal)* | No | |
| Simple effects, pairwise comparisons and custom contrasts (emmeans), with their own corrections | Superpower `emm`, `emm_comp`, `contrast_type`, `emm_p_adjust`; `emmeans_power()` [SP] | planned | v2 *(proposal)* | No | |
| ANCOVA (one-way and factorial) and ANCOVA contrasts, including a pre–post design with the baseline as covariate | Superpower `power_oneway_ancova()`, `ANCOVA_analytic()` (cell means, SD, the covariates' R² `r2` and their number `n_cov`), `ANCOVA_contrast()` [SP]; G\*Power: the 2023 manual's contents list no ANCOVA chapter (checked by the maintainer's copy), although search results describe an ANCOVA option in the program [GP, search]. Also pwrss `power.f.ancova()` (Keppel and Shieh methods; see "Not covered by the five tools") | planned | v2 *(build guide)* | No | Decision tree E23. Needed for the pre–post route in the design finder (decision D2) and for the worked example in [decision-tree.md](decision-tree.md), section 4.3 |
| ANCOVA with covariates in a regression model (covariates in an interaction) | InteractionPoweR `power_interaction_r2_covs()` (analytic) [IP]; Spower `p_glm()` with covariates in the formula (fixed predictors) [Sp] | planned | v2 *(proposal)* | No | See also "Covariates" under regression interactions |
| Exact (empirical) and simulated power | Superpower `ANOVA_exact()` and `ANOVA_power()` [SP] | done | MVP | Yes (2x2 tests) | `options > method` |
| Means plot and power-by-n plot | Superpower `ANOVA_design(plot = TRUE)`, `plot_power()` [SP] | planned | MVP (phase 5) | No | The app draws these from the engine's results |
| Effect size entered as partial eta² or Cohen's f | G\*Power [GP, search]; Superpower `mu_from_ES()` (one-way) [SP] | planned | v2 *(proposal)* | No | As an effect-size helper that produces means |

## Regression interactions

| Capability | Tool(s) | powerkit | Tier | Validated? | Notes |
| --- | --- | --- | --- | --- | --- |
| Two-way interaction, continuous X and W, simulated | InteractionPoweR `power_interaction()` [IP] | done | MVP *(build guide)* | Tests written, full run not recorded: `test-validation-regression-interaction.R` | |
| Two-way interaction, analytic | InteractionPoweR `power_interaction_r2()` [IP] | partial | MVP | Same file | Used only to bracket n; reported results always come from simulation ([conventions](conventions.md), Known differences 1) |
| Reliability of X, W and Y | InteractionPoweR `rel.x1`, `rel.x2`, `rel.y` [IP] | done | MVP *(build guide)* | Same file (measurement-error published test TODO) | |
| Binary X or W | InteractionPoweR `k.x1 = 2` / `k.x2 = 2`, simulation only, split 50/50 [IP]; power4mome `x_fun` with `rbinary_rs()` [p4m] | planned | MVP: next phase (3b) | No | Maintainer's decisions in build guide section 8 |
| Ordinal X, W or Y (k levels) | InteractionPoweR `k.x1`, `k.x2`, `k.y`, `norm2ordinal()` [IP] | planned | v2 *(proposal)* | No | |
| Binary Y | InteractionPoweR `k.y = 2` (pseudo-R² reported) [IP, IP-dev] | planned | later *(proposal)* | No | |
| Covariates | InteractionPoweR `power_interaction_r2_covs()` with `generate.interaction.cov.input()` (analytic) [IP, IP-dev] | planned | v2 *(proposal)* | No | Analytic only, so powerkit would need a simulation route or a recorded departure |
| Three-way interaction | InteractionPoweR `power_interaction_3way_r2()` (analytic, with reliabilities), `cor.mat.3way()`, `simple.slopes.3way()` [IP] | planned | v2 *(proposal)* | No | Analytic only in 0.2.4 |
| Simple slopes: power and the distribution of simple slopes when the interaction is significant | InteractionPoweR `power_interaction(detailed_results = TRUE, q, ss.IQR)`, `test_interaction()`, `plot_simple_slope()` [IP, IP-dev] | planned | v2 *(proposal)* | No | |
| Interaction shape and crossover point distributions | InteractionPoweR `detailed_results`: `shape` (B3/B1: above 1 crossover, 1 knock-out, below 1 attenuated) and `crossover` [IP-dev, main vignette] | planned | v2 *(proposal)* | No | Useful on the confirmation and results screens |
| Stability (point and corridor of stability) | InteractionPoweR `run_pos_power_search()` [IP, IP-dev stability article] | planned | later *(proposal)* | No | |
| Power estimate from a fitted power curve | InteractionPoweR `power_estimate()` (polynomial fit) [IP] | not planned | — | — | powerkit has its own n search |
| Moderation with an X or W of three or more groups | No power function found in the five. InteractionPoweR's `k.x1`, `k.x2` make a variable discrete and **ordered** (binary or ordinal), not unordered categories [IP]; manymome documents multi-category moderators for analysis, not power | not planned yet | later *(proposal)* | No | Decision tree E30 |
| Interaction with two moderators | power4mome template `moderation_obs_two_ws` [p4m-dev] | planned | later *(proposal)* | No | |
| Interaction tested as an R² increase | G\*Power, linear multiple regression [GP, search] | — | — | — | Cross-check only; see [conventions](conventions.md), regression interaction table |

## Mediation

| Capability | Tool(s) | powerkit | Tier | Validated? | Notes |
| --- | --- | --- | --- | --- | --- |
| Simple mediation (PROCESS 4), Monte Carlo CI | power4mome `power4test()` with `test_indirect_effect()`, `q_power_mediation_simple()` [p4m]; Spower `p_mediation()` (Wald/Sobel test) [Sp] | done | MVP *(build guide)* | Tests written, full run not recorded: `test-validation-mediation-simple.R` | |
| Parallel mediation, two mediators | power4mome `q_power_mediation_parallel()` [p4m] | done | MVP *(build guide)* | Tests written, full run not recorded: `test-validation-mediation-parallel.R` | Residuals free to correlate (Departure 7) |
| Serial mediation, two mediators (PROCESS 6) | power4mome `q_power_mediation_serial()` [p4m] | done | MVP *(build guide)* | Tests written, full run not recorded: `test-validation-mediation-serial.R` | |
| Three or more mediators (parallel or serial) | power4mome: `q_power_mediation_parallel()` and `_serial()` take vectors of paths for p mediators; any model in lavaan syntax through `power4test()` [p4m] | planned | v2 *(proposal)* | No | |
| Several indirect effects at once (all, or at least k, significant) | power4mome `test_k_indirect_effects()`, `rejection_rates(collapse = "all_sig" / at_least_k)` [p4m] | planned | later *(proposal)* | No | |
| Nonparametric bootstrap CI | power4mome `ci_type = "boot"` [p4m] | not planned | later *(proposal)* | No | Monte Carlo CI by design (build guide section 5, speed rules) |
| Sobel (Wald) test | Spower `p_mediation(method = "wald")` [Sp] | not planned | — *(proposal)* | — | Less powerful than CI methods; could appear as a comparison only |
| Binary X in mediation | Spower `p_mediation(dichotomous.X = TRUE)` [Sp]; power4mome `rbinary_rs()` [p4m] | planned | MVP: next phase (3b) | No | |
| Effect sizes given as small, medium or large labels | power4mome `"s"`, `"m"`, `"l"` in `pop_es` [p4m] | not planned | — | — | powerkit requires a justified effect size (build guide section 4) |

## Moderated mediation

| Capability | Tool(s) | powerkit | Tier | Validated? | Notes |
| --- | --- | --- | --- | --- | --- |
| First-stage moderated mediation (PROCESS 7), index of moderated mediation | power4mome `test_index_of_mome()` [p4m]; template `mome_obs_a` [p4m-dev] | done | MVP *(build guide)* | Tests written, full run not recorded: `test-validation-modmed-process7.R` | |
| Second-stage moderated mediation (PROCESS 14) | power4mome, template `mome_obs_b` [p4m-dev] | done | MVP *(build guide)* | Tests written, full run not recorded: `test-validation-modmed-process14.R` | |
| Conditional indirect effects at chosen levels of W | power4mome `test_cond_indirect()`, `test_cond_indirect_effects()` [p4m] | planned | v2 *(proposal)* | No | Needed for the Donnelly et al. (2023) benchmark (build guide section 8) |
| Covariates in mediation or moderated mediation (e.g. a baseline score) | power4mome: the population model is any lavaan model (`power4test(model = )`), so covariates can be added as extra predictors in the model syntax [p4m]. The powerkit templates have fixed paths and no covariates | planned | v2 *(proposal)* | No | Not in the spec for any design. Needed for the worked example in [decision-tree.md](decision-tree.md), section 4.3 |
| Mediation with a multi-category X (three or more conditions) | **None of the five documents it.** power4mome's documented examples use a continuous or binary X [p4m, p4m-dev]; manymome 0.3.7, which power4mome uses for its tests, documents multi-category **moderators** (articles `mo_lm_cat_2w`, `mo_lm_cat_num_2w`; `cond_indirect(w_type = "categorical")`), not a multi-category X; Spower `p_mediation()` takes a continuous or dichotomous X only [Sp]. The analysis method (relative indirect effects with dummy-coded X) is Hayes and Preacher (2014, *British Journal of Mathematical and Statistical Psychology*, 67(3), 451–470, doi:10.1111/bmsp.12028) *(seen second-hand, to verify)* | not planned yet | later *(proposal)* | No | power4mome's `x_fun` requires a generated variable to be uncorrelated with the other exogenous variables. The dummy codes of one three-group factor are correlated, so `x_fun` can't represent them as they stand (Claude's inference from the documentation; to confirm with Shu Fai Cheung). Routes for now: a Spower user-written simulation, or the R script export |
| Further PROCESS models (8, 58, 59 and others) | power4mome: any model in lavaan syntax with product terms [p4m] | planned | v2 for 8, 58, 59 *(build guide)*; later for the rest *(proposal)* | No | No ready-made template in power4mome for these |

## Analysis types

| Capability | Tool(s) | powerkit | Tier | Validated? | Notes |
| --- | --- | --- | --- | --- | --- |
| A priori: required n for a target power | Spower (`n = NA` with `power`, `interval`) [Sp]; power4mome `n_from_power()`, `x_from_power(x = "n")` [p4m]; InteractionPoweR (vector of N, `power_estimate()`) [IP]; Superpower (`plot_power()` over n) [SP]; G\*Power [GP: to check] | done | MVP | Through each design's tests | Required n reported with its uncertainty interval |
| Post hoc / prospective: power at a fixed n | All five [SP, Sp, p4m, IP; GP: to check] | done | MVP | Through each design's tests | |
| Sensitivity: smallest detectable effect at a fixed n | Spower (effect argument `NA` with `interval`) [Sp]; power4mome `x_from_power(x = "es")` [p4m]; InteractionPoweR (vector of effect sizes; vignette "Finding the smallest detectable effect size") [IP-dev]; Superpower `morey_plot()` (power across effect sizes) [SP]; G\*Power [GP: to check] | partial | MVP for the remaining MVP designs *(proposal)* | No | 2x2 ANOVA only (`goal.type = "sensitivity"`) |
| Compromise: alpha and power from a chosen ratio of beta to alpha | Spower `beta_alpha` [Sp]; Superpower `ANOVA_compromise()`, `optimal_alpha()` (minimise or balance error rates, with prior odds and costs) [SP]; G\*Power [GP: to check] | planned | later *(proposal)* | No | |
| Criterion: alpha needed for a given power and n | Spower (`sig.level = NA`) [Sp]; G\*Power [GP: to check] | planned | later *(proposal)* | No | |
| Alpha that falls with n (standardised alpha) | Superpower `alpha_standardized()`, `power_standardized_alpha()` [SP] | not planned | later *(proposal)* | No | |
| Power curve (power by n) | Spower `SpowerCurve()` [Sp]; power4mome `power_curve()`, `power4test_by_n()` [p4m]; InteractionPoweR `plot_power_curve()` [IP]; Superpower `plot_power()` [SP] | done | MVP | Through each design's tests | `curve` in the result object |
| Several hypotheses in one study: combined required N, and joint power (all or any significant) | power4mome `rejection_rates(collapse = "all_sig" / "at_least_one_sig" / "at_least_k_sig")` [p4m]; a named list of tests in one `power4test()` call [p4m-dev only, 0.2.1.27]; Spower user-written experiments returning one TRUE/FALSE for several tests [Sp, `SpowerIntro`]; Superpower all ANOVA effects from one design, with `p_adjust` [SP] | not available | v2 *(proposal)* | No | One target test per spec today. Proposals (a study level; per-hypothesis forms versus whole-study simulation) in [decision-tree.md](decision-tree.md), section 4 |
| Power over a grid of conditions (several effect sizes or settings) | Spower `SpowerBatch()` [Sp]; power4mome `power4test_by_es()` [p4m]; InteractionPoweR (vectors of any argument) [IP] | partial | v2 *(proposal)* | No | Over n only |
| Effect-size helpers (convert reported t, F, r or means and SDs) | G\*Power effect-size dialogs [GP: to check] | planned | MVP (phase 5) *(build guide)* | No | |

## Data features

| Capability | Tool(s) | powerkit | Tier | Validated? | Notes |
| --- | --- | --- | --- | --- | --- |
| Binary predictors (X or W) | See regression interactions and mediation | planned | MVP: next phase (3b) | No | |
| Ordinal variables | InteractionPoweR `k.*` [IP]; power4mome `ordinal_variables()`, `cut_patterns()` (ordinal indicators) [p4m] | planned | v2 *(proposal)* | No | |
| Non-normal data | power4mome `x_fun` / `e_fun` with `rbeta_rs()`, `rexp_rs()`, `rlnorm_rs()`, `rt_rs()`, `runif_rs()`, `rpgnorm_rs()` [p4m]; `rig_rs()` for correlated non-normal variables [p4m-dev only]; Spower custom generators (`gen_fun`, `parent`) [Sp] | planned | v2 *(build guide: cross-cutting)* | No | |
| Missing data | power4mome `missing_values(prop, mech = "MCAR"/"MAR"/"MNAR")` through `process_data` [p4m]; by variable pattern, wave and attrition rate [p4m-dev only] | partial | v2 *(proposal)* | No | powerkit's `options > attrition` only scales n up to a recruitment target; it doesn't simulate missingness |
| Latent variables (number of indicators, reliability, loading differences) | power4mome `number_of_indicators`, `reliability`, `loading_difference` [p4m]; SAM [p4m-dev only] | planned | later *(build guide: SEM)* | No | |
| Measurement error in observed variables | InteractionPoweR `rel.*` [IP]; power4mome reliability through latent models [p4m] | partial | MVP for interactions; v2 for mediation *(proposal)* | Interactions: `test-validation-regression-interaction.R` | Not yet for mediation ([conventions](conventions.md)) |
| Multigroup models and tests of group equality | power4mome multigroup `pop_es`, `test_group_equal()` [p4m]; article `n_from_power_mediation_mg_obs_simple` [p4m-dev] | planned | later *(proposal)* | No | |
| Robust estimation (MLR) | power4mome, articles `n_from_power_mediation_mlr_*` [p4m-dev] | planned | later *(proposal)* | No | |
| Model misspecification (paths not truly zero) | power4mome `.beta_nil.`, `.fm.` [p4m-dev only] | not planned | later *(proposal)* | No | Development version only |
| Fit-measure power | power4mome `test_fit_measure()` [p4m-dev only] | not planned | later *(build guide: SEM)* | No | |
| Unequal group sizes (two groups) | Spower `n2_n1` [Sp]; G\*Power allocation ratio [GP, search] | done | MVP | Yes: `test-validation-basic-tests.R` (unequal groups) | `options > allocation_ratio`, two-group tests only |
| Unequal variances | Spower `var.equal`, `sds` [Sp]; Superpower cell SDs [SP] | partial | MVP | Yes (Welch t, 2x2 cell SDs) | |

## Bayesian approaches

| Capability | Tool(s) | powerkit | Tier | Validated? | Notes |
| --- | --- | --- | --- | --- | --- |
| Bayes factor as the decision rule, in simulation | Spower, user-written simulation returning a logical (example with `BayesFactor::ttestBF()`) [Sp, `SpowerIntro_logicals`] | planned | later *(build guide)* | No | Not a built-in function in Spower; the vignette shows how |
| Posterior probability as the decision rule | Spower `sig.direction = "above"` with a user-written simulation (example with rstanarm and bayestestR) [Sp] | planned | later *(proposal)* | No | |
| Region of practical equivalence (HDI + ROPE) | Spower vignette example [Sp] | planned | later *(proposal)* | No | |
| Bayes factor design analysis (BFDA), including sequential designs | None of the five as a built-in feature | planned | later *(build guide)* | No | The build guide names BFDA as a likely backend |
| Assurance (power averaged over a prior on the effect size) | Not found in the five tools' documentation | planned | later *(proposal)* | No | |

## Not covered by the five tools, and tools that could help

These are power analyses psychologists commonly need that none of the five
main tools covers well. The list of needs is the maintainer's and Claude's
judgement (several are already in the build guide, section 2). It is
**not** taken from documentation, so treat it as a proposal. For each need,
the candidate tools come from web searches and were then checked against
the package's own `DESCRIPTION`, `NAMESPACE` and help files, read from the
CRAN mirror on GitHub (`github.com/cran/<package>`) on 15 October 2026, or
from the tool's own GitHub repository where it isn't on CRAN.

- **CRAN status not checked.** The CRAN mirror on GitHub also keeps
  packages that CRAN has archived, and CRAN itself wasn't reachable from
  the build environment. Packages whose last release is several years old
  are marked *(last release YYYY)* and need their CRAN status checked
  before use.
- **Licences** are as their `DESCRIPTION` files state them. powerkit is
  GPL-3, so all of them can be called as backends.
- **Tiers are proposals.**

| Need | Why it matters | Candidate tools (version, licence) | Method | Tier | Notes |
| --- | --- | --- | --- | --- | --- |
| Mixed-effects models with participants and stimuli crossed | Experiments where everyone sees the same set of items; reviewers increasingly expect items as random effects (build guide section 2) | **simr** 1.0.11 (GPL ≥ 2): `powerSim()`, `powerCurve()`, `extend()`, and `makeLmer()` / `makeGlmer()` to build a model without pilot data. **mixpower** 1.1.1 (MIT): design-first LMM/GLMM simulation (Gaussian, binomial, Poisson, negative binomial), `mp_solve_sample_size()`, `mp_sensitivity()`, `mp_safeguard_effect()`, `mp_sesoi()`. **faux** 1.2.4 (MIT): simulates cross-classified data (`sim_mixed_cc()`, `add_random()`), no power function itself. **mixedpower** (GitHub `DejanDraschkow/mixedpower`, 0.1.0, GPL): power from pilot data and a fitted lme4 model | Simulation | v2 *(proposal)* | simr has the longest track record. mixpower is new (2026) and its design-first approach fits powerkit's spec, but it has less of a track record |
| Multilevel and cluster designs (classrooms, teams, cluster-randomised trials) | Studies run in schools, teams or clinics | **mlmpower** 1.0.11 (GPL-3): any number of within- and between-cluster effects and random slopes, specified by variance explained. **PowerUpR** 1.1.0 (GPL ≥ 3; last release 2021): multilevel randomised experiments, including moderated and mediated treatment effects. **clusterPower** 0.7.0 (GPL ≥ 2; last release 2021): cluster-randomised, stepped-wedge and cluster crossover trials. **powertools** 1.0.0 (MIT): cluster-randomised, multisite and individually randomised group treatment trials | Analytic and simulation | v2 *(proposal)* | Also offered by WebPower and PAMLj (Related tools) |
| Longitudinal: growth curves and time × treatment | Panel studies and intervention trials with several measurement occasions | **longpower** 1.0.27 (GPL ≥ 2): mixed models, GLS and GEE. **powerlmm** 0.4.0 (GPL ≥ 3; last release 2018): two- and three-level longitudinal models with dropout. **semPower** `semPower.powerLGCM()` | Analytic | later *(build guide)* | |
| Cross-lagged panel models | Common in developmental and social psychology | **powRICLPM** 0.2.1 (MIT): RI-CLPM and STARTS models by simulation (Mulder, 2023). **semPower** `semPower.powerCLPM()`, `semPower.powerRICLPM()` | Simulation (powRICLPM); analytic (semPower) | later *(build guide)* | |
| Intensive longitudinal / experience sampling (EMA) | Diary and EMA studies | **PowerAnalysisIL** (GitHub `ginettelafit/PowerAnalysisIL`, 0.1.0, GPL-2; Shiny app and R package; Lafit et al., 2021): group differences, level-2 predictors, multilevel autoregressive effects, with AR(1) errors | Simulation | later *(build guide)* | Last commit 2023 |
| SEM: CFA, model fit (RMSEA), measurement invariance, SEM parameters | Scale development, latent models | **semPower** 2.2.0 (LGPL): a priori, post hoc and compromise power, with functions for CFA, measurement invariance (`semPower.powerMI()`), bifactor models, regression, mediation, path models, CLPM, RI-CLPM, LGCM, autoregressive and ARMA models. **simsem** 0.5-17 (GPL ≥ 2): Monte Carlo SEM. **pwrSEM** (Shiny app, GitHub `yilinandrewang/pwrSEM`, GPL-3; Wang & Rhemtulla): power for SEM parameter estimates | Analytic (semPower); simulation (simsem, pwrSEM) | later *(build guide)* | power4mome covers latent mediation; semPower covers fit and invariance |
| Sequential designs (interim looks) | Efficient sampling; accepted in Registered Reports | **rpact** 4.4.0 (LGPL-3): group-sequential and adaptive designs, continuous and binary outcomes | Analytic and simulation | later *(build guide)* | Clinical-trial focus; would need a plain-language wrapper |
| Bayes factor design analysis, fixed-n and sequential | Growing use of Bayes factors in psychology | **BFDA** (GitHub `nicebread/BFDA`, 0.5.1, GPL ≥ 2; not on CRAN; Schönbrodt & Wagenmakers, 2018): `BFDA.sim()`, `SSD()`. **bfpwr** 0.1.6 (GPL-3; Pawel & Held, 2025): analytic power and sample size for z-test, t-test and normal-moment-prior Bayes factors | Simulation (BFDA); analytic (bfpwr) | later *(build guide)* | bfpwr is analytic, so much faster |
| Bayesian power and assurance (posterior decision rules, ROPE) | Bayesian analysis plans | **powerbrmsINLA** 1.3.0 (MIT): brms and INLA, direction / threshold / ROPE / Bayes factor rules, assurance, sequential designs. **bayesassurance** 0.1.0 (GPL ≥ 2; last release 2022) | Simulation | later *(proposal)* | Covers the "assurance" row above |
| Equivalence and non-inferiority tests | Showing an effect is negligible; increasingly requested in Registered Reports | **TOSTER** 0.8.6 (GPL-3; Lakens): `power_t_TOST()`, `powerTOSTone()`, `powerTOSTpaired()`, `powerTOSTtwo()`, `powerTOSTr()`, `power_twoprop()`, `power_eq_f()` (equivalence for F tests). **powertools**: non-inferiority by a margin with `prop.2samp(margin = )`, and in `ttest.2samp()` by subtracting the margin from `delta` | Analytic | v2 *(build guide)* | TOSTER is the established tool for this in psychology |
| Precision (AIPE): n for a target CI width | Estimation-focused planning (build guide section 2) | **MBESS** 5.0.1 (GPL-2/3; Kelley): `ss.aipe.smd()`, `ss.aipe.R2()`, `ss.aipe.reg.coef()`, `ss.aipe.rmsea()`, `ss.aipe.sem.path()`, `ss.aipe.c.ancova()` and others, each with a sensitivity version. **presize** 0.3.11 (GPL-3): precision-based sample sizes. **powertools** `ci.mean()`, `ci.meandiff()` | Analytic | v2 *(build guide)* | MBESS was written for the behavioural sciences |
| Planning from a published effect: bias- and uncertainty-corrected n | Published effects are inflated; specific to psychology's replication concerns | **BUCSS** 2.0.0 (GPL ≥ 3; Anderson, Kelley & Maxwell, 2017; Anderson & Kelley, 2024): t-tests, between, within and mixed ANOVA, ANCOVA, regression coefficients and R², correlation, MANOVA, chi-square difference between nested models; a simulation audit of achieved power. **mixpower** `mp_safeguard_effect()` | Analytic | v2 *(proposal)* | Fits powerkit's `effect_justification` (`prior_study` with an adjustment). BUCSS 2.0.0 was released on 13 October 2026, so it is very new |
| Replication studies: small telescopes | Planning and judging replications | **RSmallTelescopes** 1.0.4 (MIT; last release 2021): empirical small-telescopes analysis (Simonsohn, 2015). The "2.5 times the original n" rule gives about 80% power (Simonsohn, 2015) | Analytic | v2 *(proposal)* | BUCSS 2.0.0 also covers replications (Anderson & Kelley, 2024) |
| Several primary outcomes or hypotheses (all, any, or at least r significant, with correction) | Studies with several preregistered hypotheses | **powertools** `coprimary.t()`, `coprimary.z()` (all), `altprimary()` (any). **rPowerSampleSize** 1.0.2 (GPL > 2; last release 2018): at least r of m, with Bonferroni, Holm or Hochberg. **PUMP** 1.0.5 (GPL-3): multilevel randomised experiments with several outcomes and multiple-testing procedures. power4mome `rejection_rates(collapse = "all_sig")` (main table) | Analytic and simulation | v2 *(proposal)* | |
| Ordinal (Likert) outcome in a group comparison | A single Likert item as the outcome | **Hmisc** 5.3-0 (GPL ≥ 2): `popower()`, `posamsize()` (proportional odds, Whitehead, 1993). **powertools** `propodds()`. **BayesOrdDesign** 0.1.2 (GPL-2; last release 2022): Bayesian group-sequential designs for ordinal outcomes | Analytic | v2 *(proposal)* | |
| Power for a meta-analysis | Planning a meta-analysis or judging one | **metapower** 0.2.2 (GPL-2; last release 2021; Griffin, 2021): main effect, heterogeneity, subgroup and categorical moderator tests | Analytic | later *(proposal)* | Outside powerkit's single-study focus |
| Within-person mediation (repeated measures, EMA) | Experience-sampling and repeated-measures mediation (build guide section 2) | No dedicated, maintained package found. PowerUpR covers mediation only in cluster-randomised designs. Simulation with mlmpower or simr would need powerkit to write the indirect-effect test | Simulation | later *(build guide)* | A gap with no ready-made tool; powerkit shouldn't write the maths itself (CLAUDE.md), so it waits for a backend |
| Comparing two indirect effects, or an effect across groups | "Is the indirect effect stronger through M1 than M2?" | No power function found in the candidates. manymome (already installed with power4mome) can test differences between indirect effects, so power4mome could probably simulate it; to confirm with Shu Fai Cheung | Simulation | later *(proposal)* | |
| Broad analytic coverage as a cross-check | Independent reference values for validation | **pwrss** 1.3.3 (GPL ≥ 3; 14 October 2026): t, z, Welch and nonparametric tests, exact tests (Fisher, McNemar, binomial), ANOVA, ANCOVA (Keppel, Shieh) and mixed ANOVA, regression, logistic and Poisson regression, mediation (Sobel, joint, Monte Carlo), correlations (including Steiger), chi-square. **powertools** 1.0.0 (MIT; companion to Crespi, 2025) | Analytic | — | Useful as independent references for analytic-agreement tests rather than as backends |

## Related tools

These tools are not powerkit backends. Each summary comes from the tool's
own documentation or source, with the version read.

**PAMLj** (jamovi module; `pamlj/pamlj` on GitHub, version 1.2.0, commit
247d867). Its README and analysis definitions (`jamovi/*.a.yaml`) cover
correlation, t-tests (independent, paired, one-sample, with equivalence
tests), proportions, the general linear model (from partial eta², eta² or
standardised coefficients), factorial designs from partial eta² or from cell
means and SDs (between, within, mixed), generalised linear models (logistic,
ordinal, multinomial), mediation (simple, two or three parallel mediators,
two serial; joint-significance, Sobel and Monte Carlo tests), structural
equation models (analytic or Monte Carlo; ML, WLS, DWLS, ULS) and mixed
models (linear or logistic; solves for the number of clusters or the
cluster size). Each analysis solves for n, power or effect size, and the
README also lists the required alpha.
*Not offered by any of the five main tools:* power for mixed (multilevel)
models with a search over clusters or cluster size; ordinal and multinomial
logistic outcomes.

**WebPower** (R package 0.9.4, 13 October 2023, read from the CRAN mirror on
GitHub; also the engine behind the webpower.psychstat.org site). Its
functions cover correlation, proportions, t-tests (analytic and Monte
Carlo), one-way ANOVA (also with binary or count outcomes), two-way to k-way
ANOVA, repeated-measures ANOVA, linear, logistic and Poisson regression,
simple mediation (Sobel), moderated mediation (PROCESS models 7, 8, 14, 15
and 58: `wp.modmed.m7` and others), Monte Carlo SEM and mediation (including
bootstrap), SEM by chi-square or RMSEA, univariate and bivariate latent
change score models, longitudinal mixed models for repeated measures
(`wp.mmrm`), and cluster-randomised and multisite-randomised trials with two
or three arms.
*Not offered by any of the five main tools:* cluster- and
multisite-randomised trials; latent change score models; SEM power from
RMSEA; ready-made functions for PROCESS models 8, 15 and 58 (power4mome can
fit these as general lavaan models, without a template).

**pwranova** (R package 1.1.5, 26 July 2026, `mutopsy/pwranova` via the CRAN
mirror). It gives analytic power, required total n, alpha or minimal
detectable effect (partial eta² or Cohen's f) for every main effect and
interaction in between, within and mixed ANOVA designs. It allows any number
of factors, capped by default at six (`max_nfactor = 6`), and a
nonsphericity parameter (`epsilon`). It also covers planned contrasts
(`pwrcontrast()`), t-tests and correlation tests. Its news file records
comparisons with G\*Power.
*Not offered by any of the five main tools:* analytic power for factorial
designs with more than three factors from effect sizes alone. Superpower
handles up to three factors and works from means, SDs and correlations.
G\*Power's limits here were not checked.

**MorePower 6.0** (Campbell & Thompson, 2012, *Behavior Research Methods*,
44(4), 1255–1265, doi:10.3758/s13428-012-0186-0). **The paper and the
program's documentation could not be read in this session** (their hosts
were not reachable). The description below comes from the Superpower book's
appendix comparing the two tools [SP-book] and from the paper's abstract as
shown in search results. It needs checking against the paper before any row
depends on it. Per [SP-book]: standalone software for power analysis for
ANOVA, t-tests, correlations and tests of proportions, with at most 9 levels
per factor. Users solve for n, power or effect size. An ANOVA effect is
entered as partial eta², or as a test statistic (F, mean square for the
effect, or t). Unlike Superpower, it doesn't give all tests at once, simple
comparisons or corrections for multiple comparisons, and it doesn't take
means, SDs and correlations. Per the abstract: it also computes relational
confidence intervals for ANOVA effects and Bayesian posterior probabilities
for the null and alternative hypotheses (BIC-based).
*Not offered by any of the five main tools (to confirm from the paper):*
relational confidence intervals; BIC-based posterior probabilities for
ANOVA effects.

## Rows where the documentation was unclear

- **G\*Power (all rows).** The manual could not be read in this session.
  Rows tagged [GP via Sp] use the manual's example numbers as Spower's
  vignette cites them. Rows tagged [GP, search] rest on search-result views
  of the manual's contents. Chapter numbers differ between editions of the
  manual. Repeated-measures, MANOVA, ANCOVA and effect-size-dialog details
  in particular need checking.
- **MorePower.** Described from a secondary source and the abstract only
  (above).
- **InteractionPoweR three-way and covariate analyses.** Documented as
  analytic functions only. Whether a simulation route exists for them is not
  stated; none is exported in 0.2.4.
- **power4mome bootstrap and Boos-Zhang.** The CRAN documentation switches
  Boos and Zhang's method on automatically for some numbers of draws
  (Departure 8). How this interacts with the batching powerkit uses is
  documented in `docs/decisions.md`, not here.
- **Assurance.** None of the five documents it. That it is missing was
  inferred from searching their documentation, so it is not a definitive
  statement.
