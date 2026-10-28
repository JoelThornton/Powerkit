# Conventions: what the established tools do, and what powerkit does

powerkit follows the established tools' conventions by default (CLAUDE.md).
That is a rule against diverging *silently*, not a claim that the usual tools
are right: G\*Power is criticised in the methods literature, and the packages
powerkit calls have their own faults
([`upstream-questions.md`](upstream-questions.md)). Where a better method
exists, powerkit uses it and the difference is recorded below, shown on the
result screen and stated in the methods paragraph — which is how powerkit can
be both more defensible than the familiar tool and honest about it.
This file records, design by design, what each tool does by default (the test,
how the effect size is defined, and settings that change the answer) and what
powerkit does. **Every departure from an established tool is listed in
"Departures" below**, with the size of the difference and the test that shows
it. Where powerkit follows one established tool but another gives a
different answer, the difference is listed in "Known differences".

On the result screen, a departure that changes the answer a user would
compare (for example, a different required N from G\*Power's) is in view
under "How it was calculated", with a pointer from the answer. One that
leaves the answer practically unchanged (no difference, or under 0.01 in
power while matching G\*Power) is folded there instead
(`app/routing/forms.yaml`, `departures_folded`; decisions.md, 28 October
2026). The methods paragraph states every departure.

## How to read this file

- Each entry says where it was checked. Anything not verified from
  documentation or source code says **to check**. Fill these in from the
  tools' manuals or source, citing the page or file.
- "Not covered" means the tool has no function for that design. This was
  verified for Superpower from its exported functions (Superpower 0.2.4.1).
- Sources used so far:
  - **[SP-src]** Superpower 0.2.4.1, installed source: function defaults,
    `Superpower_options()`, exported functions.
  - **[SP-vig]** Superpower vignette "More ANOVA designs"
    (`vignettes/more_anova_designs.Rmd`), which reproduces several G*Power
    analyses. G*Power entries marked [SP-vig] are what this vignette reports
    about G*Power, not checked in G*Power itself.
  - **[SP-intro]** Superpower vignette "Introduction to Superpower"
    (`vignettes/intro_to_superpower.Rmd`).
  - **[SP-book]** The Superpower book, chapter "Mixed
    ANOVA", section 5.1, footnote, as reported by the maintainer. Not read
    directly here (no web access).
  - **[Spower-src]** Spower 0.6.4, installed source and help pages
    (`p_t.test()`, `gen_t.test()`, `p_r()`, `p_prop.test()`,
    `p_chisq.test()`, `Spower()`), checked in build phase 3; and Spower
    0.7 (CRAN, 16 October 2026), its source compared file by file with
    0.6.4's on 17 October 2026.
  - **[IP-src]** InteractionPoweR 0.2.4, installed source and help pages
    (`power_interaction()`, `power_interaction_r2()`,
    `generate_interaction()`, `test_interaction()`), phase 3.
  - **[p4m-src]** power4mome 0.2.1 (with manymome and lavaan 0.7.3),
    installed source and help pages (`power4test()`,
    `test_indirect_effect()`, `test_index_of_mome()`, `rejection_rates()`,
    `q_power_mediation()`, `Rs_bz_supported()`), phase 3.
  - **[IP-web]** InteractionPoweR's website (dbaranger.github.io/InteractionPoweR):
    home page and the articles "The InteractionPoweR Package" and
    "Questions & Errors", read on 2026-10-13.
  - **[GP-man]** The G\*Power 3.1 manual, edition of 1 June 2023 (PDF
    supplied by the maintainer, 25 October 2026). Sections and page
    numbers refer to that edition. Entries marked [GP via Sp] or
    [GP, search] were taken at second hand before it was available and
    have not all been rechecked against it. Read so far: sections 3 to 6
    (the exact correlation and proportion tests), 10 and 11 (fixed-effects
    ANOVA), 13 and 14 (multiple regression), 19 to 21 (the t-tests), 29
    (logistic regression) and 30 (Poisson regression). **The manual is
    incomplete by its own account**, and has no section on
    repeated-measures ANOVA, the two-independent-proportions z test, the
    chi-square test of independence, ANCOVA or mediation, so some entries
    below can only be settled in the program itself.
  - **[powerkit]** this repository (`engine/R/`, `docs/decisions.md`).
- The pwrss documentation was not available when this file was written (no
  network access to CRAN or the web), so its entries are mostly still
  **to check**; the G*Power entries are being filled in from [GP-man] as
  the sections are read.

## Basic tests

### One-sample, independent and paired t-tests

| Tool | Test | Effect size | Settings that change the answer |
| --- | --- | --- | --- |
| G*Power | One sample: "t test: Means - difference from constant", H0 central t(N - 1), H1 noncentral with delta = d sqrt(N) [GP-man, 20, pp. 50-51]. Independent: "Means - difference between two independent means (two groups)", Student's t, which "assumes the variances in both populations to be equal"; H0 central t(N - 2), H1 noncentral with delta = d sqrt(n1 n2 / (n1 + n2)) [GP-man, 21, pp. 52-53], so maintainer's decision D7 in `docs/design-finder.md` is confirmed. Paired: "Means - difference between two dependent means (matched pairs)", H0 central t(N - 1), H1 noncentral with delta = d_z sqrt(N) [GP-man, 19, pp. 48-49] | One sample: d = (mu - mu0) / sigma. Independent: d = (mu1 - mu2) / sigma, with Cohen's (1969) small .2, medium .5, large .8; the effect-size drawer can pool unequal SDs as sqrt((sigma1^2 + sigma2^2) / 2), which Cohen says not to use when the group sizes differ substantially. Paired: d_z = \|mu_z\| / sigma_z = \|mu_x - mu_y\| / sqrt(sigma_x^2 + sigma_y^2 - 2 rho sigma_x sigma_y), and the drawer computes d_z from the two means, SDs and their correlation [GP-man, 19.1, 20.1, 21.1] | Tails (one or two). **All three tests have no options** [GP-man, 19.2, 20.2, 21.2]. The allocation ratio N2/N1 is not described in the manual's section on the two-group test, but unequal n1 and n2 enter the noncentrality as above. For the matched-pairs test, "Total sample size" is the number of pairs (df = N - 1), which for the repeated measures powerkit supports is the number of participants. Validated against GPower 2.0 [GP-man, 19.6, 20.6, 21.6] |
| Superpower | Not covered as a t-test (no t-test function [SP-src]). A two-level `ANOVA_design` gives the equivalent F-test; for two within conditions with r = .5, d equals d_z [SP-vig]. | | |
| pwrss | to check | to check | to check |
| InteractionPoweR | Not covered (interactions only): to check | | |
| power4mome | Not covered: to check | | |
| Spower | `p_t.test()`: `t.test()` on simulated normal data; Student's by default (`var.equal = TRUE`), Welch's with `var.equal = FALSE`; two-sided by default [Spower-src] | `d` is the standardised mean of the **first** group (two-sample) or first time point (paired); the other is 0, both with SD 1. For paired data the two time points are drawn **independently**, so the differences have SD sqrt(2) and Spower's `d` is sqrt(2) * d_z [Spower-src] | One-sided tests: `alternative` (`"two.sided"`, `"greater"`, `"less"`; Spower 0.7), or `two.tailed = FALSE`, which means `"greater"` in Spower's orientation (group 1 minus group 2). Spower 0.6.4's `two.tailed = FALSE` halved the two-sided p-value regardless of direction (Departure 4, retired); `n` is group 1's size (pairs, for paired data), `n2_n1` the allocation ratio [Spower-src] |
| **powerkit** | **By default, pwr's formula** (Departure 9): `pwr.t.test()` (one-sample; paired, with d_z; two equal groups) or `pwr.t2n.test()` (unequal groups), Student's only. **On request, and for Welch's:** Spower's `p_t.test()`; one-sided tests pass `alternative`, translated to Spower's orientation (for two-sample and paired tests powerkit's `"greater"` is Spower's `"less"`). Student's or Welch's as the spec says; the finder pre-selects Student's (decision D7) [powerkit] | `d` = (mean of group 2 - mean of group 1) / SD; `dz` = mean of (second condition - first) / SD of the differences, stated when a paired spec is printed. Passed to Spower as -d and -sqrt(2) * d_z [powerkit] | `alternative`: two-sided by default, or `greater` / `less` ("greater" = the effect is positive); `allocation_ratio`; `goal.n` is the total |

### Correlation, two proportions, chi-square test of independence

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | Correlation: "Exact: Correlation - difference from constant (one sample case)", the bivariate normal model, computed either from the exact distribution of the sample correlation (Barabesi & Greco, 2002) or from the Fisher z large-sample approximation, H1 N((Fz(rho) - Fz(rho0)) / sigma, 1) with sigma = sqrt(1 / (N - 3)) [GP-man, 3, pp. 9-10]. Two proportions: the manual (1 June 2023) documents only the exact tests - one proportion against a constant (binomial, 4, pp. 11-13), McNemar (5, pp. 14-16) and Fisher's exact test (6, pp. 17-18) - and has **no section on the two-independent-proportions z test** or on the chi-square test of independence | Correlation: the alternative correlation rho with the null value rho0 (the effect is rho - rho0; rho0 = 0 is a special case), with Cohen's (1969) small .1, medium .3, large .5, and a drawer to get \|rho\| from r-squared. One proportion: g = pi - pi0, entered as a difference, ratio or odds ratio. McNemar: the odds ratio pi12 / pi21 **and** the proportion of discordant pairs pi_D = pi12 + pi21. Fisher: the two proportions directly [GP-man, 3.1, 4.1, 5.1, 6.2] | Correlation: **"Use exact distribution if N < x" (with a threshold) or "Use large sample approximation (Fisher Z)"**; the critical value is named r for the exact procedure and z for the approximation. The manual's own example of the size of the difference: for rho0 = .8, rho = .3, N = 8, two-sided alpha .05 the exact power is 0.482927 and the approximation 0.422599; at N near 1,928 the two differ by one person [GP-man, 3.2, 3.3]. One proportion and McNemar: **alpha balancing in two-sided tests**, three options, "Assign alpha/2 to both sides" by default; McNemar also chooses exact unconditional power or a faster approximation, and its N is the number of pairs [GP-man, 4.2, 5.2]. Fisher: "no options" in 6.3, although 6.6.1 describes three asymptotically equivalent two-sided statistics, which one is used by default being unstated; its large-sample approximation is a **continuity-corrected** pooled z test [GP-man, 6.3, 6.6] |
| Superpower | Not covered [SP-src] | | |
| pwrss | to check | to check | to check |
| InteractionPoweR | Not covered: to check | | |
| power4mome | Not covered: to check | | |
| Spower | `p_r()`: `cor.test()` (Pearson, exact t test against 0); `p_prop.test()`: `prop.test()`; `p_chisq.test()`: `chisq.test()`, which for a matrix of cell probabilities is the test of independence (its null pattern `P0` is then not used) [Spower-src] | `r`; `prop` (one per group); `P` (cell probabilities) [Spower-src] | Yates' continuity correction on by default (`correct = TRUE`) in `p_prop.test()` and `p_chisq.test()`; `n` is per group for `p_prop.test()` and the total for `p_chisq.test()` [Spower-src] |
| **powerkit** | **By default, a formula** (Departure 9): `pwr.r.test()` (Fisher's z approximation); for two proportions the z test with pooled variance under the null, as G*Power (Departure 11): base R's `stats::power.prop.test(strict = TRUE)` for equal groups and `pwrss::power.z.twoprops(std.error = "pooled")` for unequal groups, or on request `pwr.2p2n.test()` with Cohen's h = ES.h(p2, p1) (arcsine approximation), none with a continuity correction; and `pwr.chisq.test()` with Cohen's w = ES.w2(P) and df = (rows - 1)(columns - 1). **On request:** Spower's `p_r()`, `p_prop.test()` and `p_chisq.test()`; one-sided correlation and proportions tests pass `alternative` (for two proportions powerkit's `"greater"`, p2 > p1, is Spower's `"less"`; the chi-square test is two-sided only) [powerkit] | `r`; `p1`, `p2` ("greater" = p2 > p1); a table of cell probabilities | **No continuity correction** (`correct = FALSE`), as in G*Power (maintainer's decision 6; Departure 5) |

### Two dependent correlations (one group): common index or none

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | "Correlations: Two dependent Pearson r's", common index (ρ_ab against ρ_ac) or no common index (ρ_ab against ρ_cd): the tests Z1\* and Z2\* of Dunn and Clark (1969), Eqns (11) and (12) in Steiger (1980) [GP-man, section 28, pp. 66-69] | ρ_ab is the correlation under H0 and ρ_ac (or ρ_cd) the one under H1; the remaining correlations describe how the two depend on each other [GP-man, 28.1, p. 66] | tails; alpha. **Under H0 it sets the H1 correlation equal to the H0 one** (ρ_ac = ρ_ab, or ρ_cd = ρ_ab) when computing their covariance [GP-man, 28.5.3, p. 69] |
| pwrss | `power.z.twocors.steiger()`: Steiger's (1980) z test on Fisher's z scale; `common.index = TRUE` compares rho12 with rho13, `FALSE` compares rho12 with rho34 (pwrss 1.3.3 source, `R/correlations.R`) | `rho12`, `rho13`, `rho23` (and `rho14`, `rho24`, `rho34` with no common index) | **`pooled = TRUE` by default**: the covariance of the two correlations under the null uses their average; with `FALSE` it uses the specified values (source) |
| Spower | `p_2r()`, simulation; default test `"steiger1980"` [Sp] | `r.ab`, `r.ac`, `r.bc` (and `r.ad`, `r.bd`, `r.cd`) | — |
| **powerkit** | pwrss's `power.z.twocors.steiger()` by formula, templates `overlapping_correlations` (X with Y against X with Z) and `nonoverlapping_correlations` (X1 with Y1 against X2 with Y2); no simulation option yet (engine only, not in the app) [powerkit] | `r_X_Y`, `r_X_Z`, `r_Y_Z`; or `r_X1_Y1`, `r_X2_Y2` and the four others. "greater" = the second compared correlation is larger | **`pooled = FALSE`, as G\*Power** (Departure 12). A one-sided test runs in the direction of the specified difference, as for two independent correlations |
### Two independent correlations, and the generic tests

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | Two independent r's: "z test: Correlation - inequality of two independent Pearson r's". H0 is N(0, 1) and H1 is N(q/s, 1) with s = sqrt(1/(N1 - 3) + 1/(N2 - 3)) [GP-man, 27, 27.5, pp. 65-66]. Generic t: "t test: Generic case", the central t(df) against the noncentral t(df, delta); it has **no a priori analysis**, "the reason being that there is no definite association between N and df" [GP-man, 25, 25.5, p. 63]. The manual has no section for the generic F, chi-square or z test | Two independent r's: q = z1 - z2, the difference of the Fisher-transformed correlations, with Cohen's (1969) small .1, medium .3, large .5; an effect-size drawer converts between q and the pair of correlations [GP-man, 27.1]. Generic t: the noncentrality delta itself [GP-man, 25.1] | Both "have no options" [GP-man, 25.2, 27.2]. Two independent r's takes the two sample sizes separately, or an allocation ratio N2/N1 for an a priori analysis. One-sided generic t: the critical value takes the sign of delta. Validated against Cohen (1969, chap. 4) and GPower 2.0 respectively [GP-man, 25.6, 27.6] |
| pwrss | Two independent r's: `power.z.twocors()`, Fisher's z test. Generic tests: `power.t.test()`, `power.f.test()`, `power.chisq.test()`, `power.z.test()`, each taking a noncentrality and degrees of freedom | The two correlations themselves, not q; a noncentrality for the generic tests | **`n.ratio` is n1 / n2**, the inverse of powerkit's `allocation_ratio` (n2 / n1), and the adapter inverts it [powerkit, `backend-pwrss.R`] |
| **powerkit** | pwrss's `power.z.twocors()` and the four generic functions, by formula; no simulation option (two correlations: engine and app, E49; generic tests: E50, from "I know my analysis" only) [powerkit] | `r1` and `r2`; `ncp` with `df` (or `df1` and `df2`) | `allocation_ratio` is n2 / n1 and `goal.n` is the total, so a published pair of group sizes is entered as their sum with their ratio. A generic test has no sample size: the curve has one row with `n` `NA`. Both reproduce the manual's worked examples: power 0.7263517 against 0.726352 and a required 168 against 84 per group (27.3), and 0.2245240 against 0.224525 (25.3), the last agreeing to five decimals and differing in the sixth |
### Variance tests (one group, two groups)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | One group: the chi-square test. (N - 1)s^2/sigma0^2 is central chi-square with N - 1 df under H0, and the same distribution scaled by sigma^2/sigma0^2 under H1 (section 26.5) [GP-man]. Two groups: the F test. s1^2/s0^2 is central F with N1 - 1 and N0 - 1 df under H0, scaled by sigma1^2/sigma0^2 under H1 (section 15.5) [GP-man] | The variance ratio var1/var0; the effect-size drawer works it out from two variances. Ratios in [0.999, 1.001] are refused (sections 26.1, 15.1) [GP-man] | Tails (one or two); allocation ratio N2/N1 (two groups, section 15.3) [GP-man] |
| Spower | `p_var.test()`: one variance plus `sigma2` goes to `EnvStats::varTest()` (the chi-square test); two variances go to `stats::var.test()` (the F test), whatever `test` says, unless `test = "Fligner"`. `test` (Levene, Bartlett, Fligner) is for three groups or more [Spower-src] | `vars` (one variance, or one per group), `sigma2` (the value tested against) [Spower-src] | `alternative`, or `two.tailed`; `two.tailed = FALSE` means `"greater"` whichever way the variances point, so a test of a **smaller** variance needs `alternative = "less"` (`docs/upstream-questions.md`). `n` is one group's size and `n.ratios` the group sizes' ratios, but unequal ratios fail in `gen_var.test()` (`docs/upstream-questions.md`) [Spower-src] |
| pwr, pwrss, Superpower, InteractionPoweR, power4mome | Not covered: none of them exports a power function for a variance (their exported functions, checked 25 October 2026) | | |
| **powerkit** | Spower's `p_var.test()`, simulated: no package powerkit builds on has a formula for either test, and powerkit doesn't write the maths itself (CLAUDE.md), so these two templates have no exact method (Known difference 4) [powerkit] | `var` and `var0` (one group: the expected variance and the fixed value it is compared with); `var1` and `var2` (two groups, in the order the groups are listed). Power depends on the ratio alone | `alternative`: two-sided by default, or `greater` / `less` ("greater" = the variance, or group 1's variance, is the larger one), always passed on to Spower; `goal.n` is the total, split into two equal groups for the two-group test. **An allocation ratio is refused** for the two-group test while Spower can't draw unequal groups |

## Factorial ANOVA

### 2 x 2 between-participants

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | "F test: Fixed effects ANOVA - special, main effects and interactions", for any main effect or interaction of a factorial design. H0 central F(df1, N - k), H1 noncentral with lambda = f^2 N, where df1 is the effect's own df and **k is the total number of cells in the design** (4 for a 2 x 2). Equal cell sizes, normality and equal variances are assumed throughout [GP-man, 11, 11.5, pp. 26-30]. One-way (powerkit's E18) is section 10: the same lambda = f^2 N with df1 = k - 1, df2 = N - k [GP-man, 10.5, p. 25] | Cohen's f = sigma_m / sigma, where sigma_m is the SD of the effect being tested - for an interaction, of the cell residuals after subtracting the main effects, **as a root mean square over all of that effect's residuals, not over its df** - and sigma is the common within-cell SD. Equivalently eta^2 = f^2 / (1 + f^2). Cohen's (1969) small .10, medium .25, large .40 [GP-man, 11.1, 11.3.1] | Inputs are f, the numerator df and the number of groups; **the test has no options** [GP-man, 11.2]. Validated against GPower 2.0, and the manual's worked example reproduces SPSS's observed power exactly [GP-man, 11.3.1, 11.6] |
| Superpower | `ANOVA_exact()`: one data set with exactly the specified means and SDs (`mvrnorm(empirical = TRUE)`), analysed once [SP-intro]. `ANOVA_power()`: simulation, `nsims = 1000` by default [SP-src]. `power_twoway_between()`: analytic [SP-src]. | Input is cell means, SD(s) and n per cell; output reports partial eta squared and Cohen's f [SP-src] | `alpha_level` .05, `correction` "none", `liberal_lambda` FALSE, `emm` FALSE (`Superpower_options()` [SP-src]). `ANOVA_exact()` needs n per cell greater than the number of cells (n ≥ 5 for 2x2); for smaller n the vignette points to `ANOVA_exact2()` [SP-intro]. |
| pwrss | to check | to check | to check |
| InteractionPoweR | Not covered (regression interactions; see below) | | |
| power4mome | Not covered: to check | | |
| Spower | to check | to check | to check |
| **powerkit** | `ANOVA_exact()` by default; `ANOVA_power()` with `options > method = "simulation"` [powerkit] | Cell means and SD(s) in the user's units, or standardised; sensitivity reports the smallest detectable effect in the user's units and as Superpower's Cohen's f [powerkit] | Superpower's defaults above. `ANOVA_exact()` is run under the run's seed (see Departures). `goal.n` is the total number analysed and must be a multiple of 4. |

### 2 x 2 mixed (one factor between, one within)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | "ANOVA: Repeated measures, within-between interaction" [SP-vig]. **The manual has no section on any repeated-measures ANOVA** (edition of 1 June 2023; it says of itself that it "is not yet complete"), so nothing below can be settled from it [GP-man, contents] | Cohen's f; whether the correlation among repeated measures is a separate field or folded into f depends on the setting below | **Effect size specification (Options button).** With "As in SPSS" the "Corr among rep measures" field disappears and the correlation is folded into f; in the vignette's one-factor within-participants example, f = 0.25 becomes f = 0.7024394 [SP-vig]. **Which setting produced the 91.25% within-between example is to check (maintainer to verify in G*Power itself, as the manual does not cover this test)**; the sources disagree (see Departure 2). The name of the default option, and whether it is the default, is also to check. |
| Superpower | `ANOVA_exact()`, `ANOVA_exact2()`, `ANOVA_power()` as above. The vignette's own within-between example calls `ANOVA_exact2()` [SP-vig]. | As above, plus a correlation `r` between repeated measures [SP-src] | As above |
| pwrss | to check | to check | to check |
| InteractionPoweR | Not covered | | |
| power4mome | Not covered: to check | | |
| Spower | to check | to check | to check |
| **powerkit** | `ANOVA_exact()` by default; `ANOVA_power()` on request [powerkit] | Cell means, SD(s) and `r` | Reproduces the 91.25% and 98.98% that [SP-vig] reports from G*Power's within-between interaction; the G*Power setting behind those values is to check (see Departure 2). `goal.n` is the total number analysed and must be even. Equal group sizes only (see "Superpower and unequal group sizes" below). |

### Planned comparisons (contrasts)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | No contrast screen of its own: a contrast is entered into "F test: Fixed effects ANOVA - special, main effects and interactions" as an effect size f with "Numerator df" 1 and "Number of groups" the number of levels [GP-man, 11.3.3, p. 29] | f = sigma_m / sigma, where sigma_m = \|C\| / sqrt(N * sum(c_i^2 / n_i)) for the contrast C = sum(c_i * mu_i); the manual tabulates sigma_m, f and eta-squared for three contrasts of one example [GP-man, 11.3.3] | Weights are entered only through f, so G\*Power never sees them. Validated against GPower 2.0 [GP-man, 11.6] |
| Superpower | `ANOVA_exact(emm = TRUE, contrast_type = )` and `emmeans_power()`: the contrast is computed by emmeans on one exact data set [SP-src] | emmeans contrast families (`"poly"` for trends, `"pairwise"`, ...), not arbitrary weights | Power is returned as a percentage. Agrees with pwrss and with the manual: for the manual's example its "poly" contrasts give 0.514737 (linear) and 0.0579695 (quadratic) [powerkit, `test-backend-formula-tests.R`] |
| pwrss | `power.t.contrasts()`: a t test of each row of a contrast matrix (t^2 = F with numerator df 1, so the same test G\*Power computes) | `mu.vector`, `sd.vector`, `n.vector` and `contrast.matrix` | `k.covariates` **defaults to 1**, which spends a denominator degree of freedom a plain one-way design doesn't have; `adjust.alpha` offers none (the default), Tukey, Bonferroni, Holm, Hochberg, Hommel, BH, BY and fdr. No one-sided option |
| **powerkit** | pwrss's `power.t.contrasts()` by formula, with `k.covariates = 0` and `r.squared = 0`; no simulation option yet (in the app since 26 October 2026, E19) [powerkit] | The means, the within-group SD and `target_test > weights`, one per level, adding up to 0. The weights' scale doesn't matter, which a unit test checks | **One contrast at a time**, `adjust.alpha = "none"` (pwrss's own default), equal groups, and two-sided only because pwrss's function has no one-sided option. Not a departure: the arguments are pwrss's defaults except `k.covariates`, which is 0 because the design has no covariates |

### Superpower and unequal group sizes (2 x 2 between and mixed)

Checked by running Superpower 0.2.4.1 under R 4.3.3 [SP-src].

- **`ANOVA_design()`** accepts unequal `n` for `"2b*2w"` (e.g.
  `n = c(20, 30)`) and for `"2b*2b"` (e.g. `n = c(10, 20, 30, 40)`), with no
  error or warning. It stores the vector (`n = n_vec`) but then sets
  `n <- max(n)` and builds the design's data at that size: for
  `n = c(20, 30)` in `"2b*2w"`, 30 per cell. So, without a message, the
  design object's data describe a balanced design at the largest group size.
- **The power functions** then behave as follows:

  | Design | Function | What happens |
  | --- | --- | --- |
  | `"2b*2w"`, `n = c(20, 30)` | `ANOVA_exact()` | Stops: "the condition has length > 1". This is an R error from comparing a vector `n`, not a message about unequal groups. |
  | `"2b*2w"`, `n = c(20, 30)` | `ANOVA_exact2()` | Warns "Unequal n designs can only be passed to ANOVA_power", then stops: "non-conformable arguments". |
  | `"2b*2w"`, `n = c(20, 30)` | `ANOVA_power()` | Stops: "Unequal group sizes are not possible when the design contains within factors". |
  | `"2b*2b"`, `n = c(10, 20, 30, 40)` | `ANOVA_exact()` | Stops: "the condition has length > 1". |
  | `"2b*2b"`, `n = c(10, 20, 30, 40)` | `ANOVA_power()` | Runs. With means 0, 0.5, 0, 0 and SD 1, interaction power was 18.4% (2,000 simulations), against 33.85% for 40 per cell. So it does not simply use the largest size, but whether it uses the unequal sizes correctly has not been validated. |

  So in this version, a mixed design with unequal groups is not supported by
  any of Superpower's power functions. The balanced-at-the-largest-size
  behaviour is in `ANOVA_design()`, and would reach a result only through
  code that used the design object's data or `n` directly.
- **powerkit today:** this cannot reach Superpower. The `factorial_anova`
  spec has no group sizes: `goal.n` is split into 4 equal cells
  (`2x2_between`) or 2 equal groups (`2x2_mixed`), an `n` that doesn't split
  evenly is rejected, and `options > allocation_ratio` is rejected for any
  design other than the two-group tests [powerkit, `engine/R/spec-checks.R`].
  The engine passes Superpower a single per-cell `n` [powerkit,
  `engine/R/backend-superpower.R`].
- **Requirement for any future unequal-n support:** it must include a test
  proving that the unequal sizes are actually used (for example, that the
  result differs from the balanced design at `max(n)` and matches the
  independent reference). It must also be validated against an independent
  reference before it is offered (decision N3 in `docs/design-finder.md`).

## Regression interaction (two-way)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | "F test: Multiple Regression - special (increase of R²), fixed model": the interaction is one tested predictor added to X and W. The fixed (conditional) model is explicit - Y = X beta + e "with fixed and known predictor variables" - which **confirms** what "Known differences", 1 assumed. H0 central F(q, N - m - 1), H1 noncentral with lambda = f² N, where q is the number of tested predictors (1 for a two-way interaction) and m the total number [GP-man, 14, 14.5, pp. 36-38] | f² = (R²full - R²reduced) / (1 - R²full), with Cohen's (1988) small .02, medium .15, large .35; a drawer computes it from the two variances or a partial R² [GP-man, 14.1] | **No options** [GP-man, 14.2]. Validated against GPower 2.0 and PASS; it differs slightly from Cohen's (1988) tables because Cohen approximates lambda downwards [GP-man, 14.6] |
| Superpower | Not covered [SP-src] | | |
| pwrss | to check | to check | to check |
| InteractionPoweR | Simulation, `power_interaction()`: OLS `lm(y ~ x1 + x2 + x1x2)`, t test of the product of the **observed** x1 and x2; analytic, `power_interaction_r2()`, valid for continuous, normally distributed variables. Neither is presented as the primary method (see "Not departures" below) [IP-src, IP-web] | Correlations `r.x1.y`, `r.x2.y`, `r.x1x2.y`, `r.x1.x2` among the true scores (x2 is the moderator) [IP-src] | `rel.x1`, `rel.x2`, `rel.y` (default 1); `k.x1`, `k.x2`, `k.y` make variables binary or ordinal; no seed argument (uses R's generator on one core) [IP-src] |
| power4mome | to check (moderation is in scope per the build guide) | to check | to check |
| Spower | to check | to check | to check |
| **powerkit** | `power_interaction()` (simulation). The analytic `power_interaction_r2()` only brackets the required n in the sample-size search; reported power and n always come from simulation, and no analytic option is offered (see "Known differences", 1) [powerkit] | Correlations `r_X_Y`, `r_W_Y`, `r_XW_Y`, `r_X_W`, InteractionPoweR's parametrisation (X = x1, W = x2) [powerkit] | Reliabilities per variable. Binary X or W: not available yet |

## Logistic regression (one predictor)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | "Z test: Multiple Logistic Regression": the Wald z test of one coefficient, by an enumeration procedure (Lyles, Lin & Williamson, 2007) or one of two large-sample approximations, Demidenko (2007) with or without variance correction and Hsieh, Bloch & Larsen (1998). The manual recommends Demidenko "as standard procedure", and its simulations found Demidenko with variance correction the most accurate; its worked examples nonetheless select Hsieh [GP-man, section 29, pp. 70-74] | Odds ratio (or two probabilities); "Pr(Y=1\|X=1) H0" = p1, the probability of an event under H0; "R² other X", applied as N' = N / (1 − R²) after Hsieh et al. [GP-man, 29.1, p. 70] | X distribution: normal (with "X parm µ", "X parm σ"), binomial (with "X parm π"), and five others. Variance correction factor: 0.75 lognormal, 0.85 binomial, 1 otherwise [GP-man, 29.6.2, p. 72] |
| pwrss | `power.z.logistic()`: Wald z test of one coefficient; `method = "demidenko(vc)"` by default (Demidenko, 2007, with variance correction: factor 0.85 for a binary X, 1 for a normal X), or `"demidenko"`, `"hsieh"`; its help says the formulas "are validated using G\*Power and tables in the PASS documentation" (pwrss 1.3.3, `R/regression.logistic.R`) | `odds.ratio` (or `prob`, `beta1`) for a one-unit increase in X; `base.prob`, the probability when X = 0 | `r.squared.predictor`; `distribution` (normal with mean 0, SD 1 by default; Bernoulli with `prob`) |
| Spower | `p_glm(family = binomial())`, simulation [Sp] | coefficients | — |
| **powerkit** | pwrss's `power.z.logistic(method = "demidenko(vc)")`, its default, by formula; no simulation option yet (in the app since 26 October 2026, E27) [powerkit] | `odds_ratio`: per SD for a score X (X standardised: pwrss's normal distribution with mean 0, SD 1), or the second level against the first for a yes/no X; `base_prob` at X's mean or in X's first level | `x_prob` (yes/no X; 0.5 if omitted); `r2_other_predictors` (0 if omitted). A one-sided test runs in the direction of the odds ratio. Not a departure: pwrss's own default throughout, and the same procedure the manual recommends. With "R² other X" = 0 powerkit reproduces all three of the manual's procedures exactly; above 0 see "Known differences", 3 |

## Poisson regression (one predictor)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | "Z tests: Poisson Regression": the Wald z test of one coefficient, by the enumeration procedure of Lyles, Lin & Williamson (2007) or one of two large-sample approximations, Demidenko (2007) with or without variance correction and Signorini (1991). The manual recommends Demidenko "as the standard procedure" and says Signorini's "is problematic and should not be used; it is only included to allow checks of published results referring to this widespread procedure"; its worked example nonetheless prints the Signorini output, giving the others' sample sizes in the text [GP-man, section 30, pp. 75-80] | "Exp(β1)", the rate ratio for a one-unit increase in X; "Base rate exp(β0)", the rate when X = 0; "Mean exposure", the exposure time t; "R² other X", in the mean of the H1 distribution as N(1 − R²) [GP-man, 30.5.2, p. 77, equations (16) to (18)] | X distribution: normal (with "X parm µ", "X parm σ"), binomial (with "X parm π"), and five others. Variance correction factor: 0.75 lognormal, 1 otherwise [GP-man, 30.5.2, p. 77] |
| pwrss | `power.z.poisson()`: Wald z test of one coefficient; `method = "demidenko(vc)"` by default (Demidenko, 2007, with variance correction), or `"demidenko"`, `"signorini"`, of which its help says the first "is more precise"; its formulas "are validated using Monte Carlo simulation, G\*Power, and tables in the PASS documentation" (pwrss 1.3.3, `R/regression.poisson.R`). Its correction factor is 0.75 for a lognormal X and 1 for every other distribution, the logistic function's 0.85 for a binary X being commented out — which is G\*Power's rule for this test | `rate.ratio` (or `base.rate` with `beta1`) for a one-unit increase in X; `base.rate`, the rate when X = 0 | `mean.exposure` (1 by default); `r.squared.predictor`; `distribution` (normal with mean 0, SD 1 by default; Bernoulli with `prob`) |
| Spower | `p_glm(family = poisson())`, simulation [Sp] | coefficients | — |
| **powerkit** | pwrss's `power.z.poisson(method = "demidenko(vc)")`, its default, by formula; no simulation option yet (in the app since 26 October 2026, E28) [powerkit] | `rate_ratio`: per SD for a score X (X standardised: pwrss's normal distribution with mean 0, SD 1), or the second level against the first for a yes/no X; `base_rate` at X's mean or in X's first level, per unit of exposure | `mean_exposure` (1 if omitted); `x_prob` (yes/no X; 0.5 if omitted); `r2_other_predictors` (0 if omitted). A one-sided test runs in the direction of the rate ratio. Not a departure: pwrss's own default throughout, and the same procedure the manual recommends. powerkit's procedure gives the manual's N for its worked example (649), and pwrss's other two methods give the manual's other two (655, 697) [GP-man, 30.3, p. 77]; powerkit also reproduces, to the three decimals printed, all five rows of the manual's Table 2 whose X distribution it has (three normal, two binomial) [GP-man, 30.4, p. 78]. The manual's only "R² other X" above 0 figure for this test is for Signorini's procedure, which pwrss reproduces as well (774) |

## Equivalence tests (two one-sided tests, TOST)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| TOSTER | `power_t_TOST()`: the exact power of the two one-sided t tests for one, two and paired samples, by Owen's Q function or direct integration of the bivariate noncentral t distribution, "inspired by the PowerTOST package"; its help cites Phillips (1990) and Diletti, Hauschke and Steinijans (1991), and notes that the function "is limited" and points to PowerTOST for more options (TOSTER 0.8.6 help) | `delta`, the true difference in means (0 by default), and `sd` (for paired samples, the SD of the differences); `eqb`, one bound (taken as minus and plus) or two | `alpha` has no default in `power_t_TOST()`; `t_TOST()`, the test itself, defaults to 0.05 for each one-sided test. `n` is per group, or a vector of the two group sizes |
| **powerkit** | TOSTER's `power_t_TOST()` by formula, no simulation option (in the app since 27 October 2026, E36) [powerkit] | `d` (or `dz` for paired data) with `sd = 1`, and `bound`, the same on each side, in the same SD units; or the means, SD and bound in the outcome's own units, divided by the same SD (the SD of the differences for paired data) | alpha for each one-sided test, 0.05 by default as in `t_TOST()`; the two tests together are the 1 − 2α confidence interval lying inside the bounds. Group sizes in the ratio the user gives. Not a departure: TOSTER's own calculation throughout |

G\*Power 3.1 has no equivalence test for means, so there is no G\*Power
convention to follow here (`coverage-roadmap.md`, row B54, found none).
Only symmetric bounds are offered: TOSTER takes asymmetric ones, and the
app may add them later.

## Cluster-randomised trials (whole groups assigned to two conditions)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for clustered designs | — | — |
| powertools | `crt.parallel.cont()`: the variance of the difference between conditions is inflated by the design effect 1 + (m − 1) × ICC per condition (with covariates, a version adjusted for them), divided by a relative efficiency when group sizes vary (`re.clustsize.cont()`, an approximation the package warns can fail when sizes vary a lot); the test is a noncentral t (one-sided) or F with 1 and J − 2 − covariates degrees of freedom (two-sided), J being the total number of groups. Solves for power, groups in the first condition, the ratio of groups, group size, alpha or the difference (powertools 1.0.0, `R/crt.parallel.cont.R`, opened 27 October 2026) | `delta` / `sd`, with `sd` the outcome's total SD (between and within groups) | `m`, `m.sd`, `J1`, `J.ratio`, `icc1`, `icc2`, `ncov`, `RsqB`, `RsqW`, `alpha`, `sides` (2 by default) |
| **powerkit** | powertools' `crt.parallel.cont()`, by formula; no simulation option (E34, from 27 October 2026) [powerkit] | `d` over the outcome's total SD, as powertools defines it. A source that standardises by the within-group SD gives a larger d for the same difference | The same number of groups in each condition (`J.ratio = 1`), one ICC for both conditions, no covariates; `cluster_size_sd` for varying group sizes (0 if omitted). The total n is a whole number of groups. A one-sided test runs in the direction of d. Not a departure: powertools' own method and defaults, and no established psychology tool computes this design for comparison. The result also reports the design effect and the effective sample size (n / design effect), from the same formula powertools uses |

## Multisite trials (people randomised to two conditions within each group)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for clustered designs | — | — |
| powertools | `multisite.cont()`: the variance of the average difference between conditions is c × (1 − icc0 + (4m/c − 1) × icc1) / N, with c = (1 + r)² / r for allocation ratio r within each group, so 4 × (1 − icc0 + (m − 1) × icc1) / N for half in each; divided by a relative efficiency when group sizes vary (`re.clustsize.cont()` with icc1); the test is a noncentral t (one-sided) or F with 1 and J − 1 df (two-sided). `icc0` is the share of the total variance between the groups' means, `icc1` the share from the effect varying between groups (powertools 1.0.0 help and source, R/multisite.cont.R) | `delta / sd`, sd the outcome's total SD | `alloc.ratio = 1`, `m.sd = 0`, `Rsq = 0`, `alpha = 0.05`, `sides = 2` |
| **powerkit** | powertools' `multisite.cont()`, by formula; no simulation option (E34, from 27 October 2026) [powerkit] | `d` over the outcome's total SD, as for the cluster-randomised trial | Half of each group in each condition (`alloc.ratio = 1`), no covariates; `cluster_size` is the people in each group, both conditions together; `icc` is passed as `icc0` and `icc_effect` as `icc1`. The reported design effect is the factor above relative to an individually randomised trial of the same size (1 − icc0 + (m − 1) × icc1, over the relative efficiency): below 1 when the effect is the same in every group. No departure from powertools |

## Structural equation model fit (the chi-square test of exact fit, by RMSEA)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for structural equation models | — | — |
| semPower | `semPower.postHoc()` and `semPower.aPriori()` with `effect.measure = "RMSEA"`: F0 = RMSEA² × df (`getF.RMSEA()`), noncentrality (N − 1) × F0 (`getNCP()`), and power is the chance that the noncentral chi-square on the model's df exceeds the central chi-square's critical value at alpha, so the null hypothesis is exact fit (RMSEA = 0). No test of close fit. `semPower.getDf()` counts a model's df by fitting its lavaan syntax (semPower 2.2.0, `R/postHoc.R`, `R/aPriori.R`, `R/effectSizes.R`, help for `semPower.getDf()`, opened 27 October 2026) | RMSEA of the population misfit | `alpha` must be given (no default); `fittingFunction = "ML"` |
| **powerkit** | semPower's `semPower.postHoc()` by formula; no simulation option (E37, from 27 October 2026) [powerkit] | `rmsea` | The model is given by its df, or, for a CFA, by its number of items and factors, each item on one factor and the factors correlated; the df are then counted by `semPower.getDf()` with the items split as evenly as possible (the split does not change the df). The required N is powerkit's own search over whole N with semPower's power, which agrees with `semPower.aPriori()`'s `requiredN` (unit tests). Not a departure: semPower's own method and defaults, and no established psychology tool computes this for comparison. Alpha 0.05 is offered as the usual level because semPower has none |

The test of close fit (the null hypothesis RMSEA no more than 0.05,
rather than exact fit) is in the methods literature on RMSEA-based power
but not in semPower; whether powerkit should offer it is a method choice
for the maintainer, not yet made.

## Mediation (PROCESS 4, 6) and moderated mediation (PROCESS 7, 14)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | Not covered: to check | | |
| Superpower | Not covered [SP-src] | | |
| pwrss | to check (the build guide names `power.z.mediation`, a z test of the indirect effect) | to check | to check |
| InteractionPoweR | Not covered: to check | | |
| power4mome | `power4test()` with `test_indirect_effect()` or `test_index_of_mome()`: Monte Carlo (default) or nonparametric bootstrap CI, significant if the CI excludes 0; the model is fitted with lavaan (ML) by default [p4m-src] | Standardised coefficients (`pop_es`, "lhs ~ rhs: value", or "s"/"m"/"l" labels). Observed variables have variance 1, and a product of two standardised variables has variance 1 + r^2. Between two endogenous variables, `~~` sets their **residual covariance** [p4m-src, checked by simulation] | `R` (draws per CI): no default in `power4test()` (no CI without it); 1,000 in `q_power_mediation()`; 100 in `gen_mc()` / `gen_boot()`. Boos and Zhang's method switches on automatically for R in 39, 79, ..., 359 (Departure 8). A residual covariance not written in the model is fixed at 0 (lavaan) [p4m-src] |
| Spower | to check (the build guide says Spower covers mediation) | to check | to check |
| **powerkit** | power4mome's `power4test()` with its test functions, CI level 1 - alpha, CI rule (`test_method = "ci"`); lavaan ML fit (Departure 6) [powerkit] | Standardised paths keyed `From->To`; residual **correlations** for parallel mediators (converted to power4mome's covariance) [powerkit] | `options > ci_draws`, default power4mome's 1,000 (`q_power_mediation()`); parallel mediators' residuals always free to correlate, as in PROCESS (Departure 7); Boos and Zhang off (Departure 8). Binary X or W and measurement error: not available yet |

## Departures

Each departure must also be shown on the results screen, stated in the
methods paragraph, and covered by a test showing the size of the difference
(CLAUDE.md).

### 1. Required N for 2 x 2 interactions: exact F test, not Sommet et al.'s z approximation

- **Established convention:** Sommet, Weissman, Cheutin & Elliot (2023)
  compute N = 4 (z_alpha + z_beta)² / d², rounded up, with z rounded to two
  decimals and d = (d_simple1 − d_simple2) / 2 (their Equation 5; Equation 8
  gives N = 1,024 for d = 0.175).
- **powerkit:** the smallest N at which the exact F test reaches the target
  power (`ANOVA_exact()`).
- **Size:** 260 vs 256 for the reversed interaction (d = 0.35); 1,028 vs
  1,024 for the fully attenuated interaction (d = 0.175); both at α = .05 and
  power .80. powerkit's N is 4 participants (one per cell) larger.
- **Test:** `engine/tests/testthat/test-validation-anova-2x2-between.R`,
  "2x2 crossover interaction" and "2x2 attenuated interaction". Each checks
  that Sommet et al.'s formula reproduces their published N from the spec's
  effect, and that powerkit's exact N is 260 / 1,028 and at least the
  published N.
- **Shown to users / in the methods paragraph:** shown on the result screen (phase 5, part 1, 17 October 2026; `app/routing/forms.yaml`, `departures`). Stated in the full version of the write-up (18 October 2026).

### 2. Mixed designs: `ANOVA_exact()`, not `ANOVA_exact2()`

- **Established convention:** Superpower offers both. Its vignette uses
  `ANOVA_exact2()` for the within-between example and describes it as giving
  "a more accurate estimate of power" over a wider range of sample sizes
  [SP-intro, SP-vig].
- **powerkit:** uses `ANOVA_exact()`, which reproduces the values [SP-vig]
  reports from G*Power's "ANOVA: Repeated measures, within-between
  interaction" (table below), and matches simulation.
- **Which G*Power setting gave those values: to check (maintainer to verify in
  G*Power).** The two Superpower sources disagree, and neither is claimed
  here until it is verified:
  - [SP-vig] does not name the setting for the within-between example; its
    settings are shown only in a screenshot (`screenshots/gpower_5.png`,
    not in the installed package). For the preceding one-factor
    within-participants example, it presents "As in SPSS" as an extra step
    taken after the settings it used ("We click the 'Options' button, and
    check the radio button next to 'As in SPSS'"), which suggests those
    settings were not "As in SPSS". An earlier version of this file
    extended that to the within-between example; that was an inference, not
    something the vignette states.
  - [SP-book] says G*Power was set to "As in SPSS" for the 91.25% example.
- **Size** (2b*2w, means −0.25, 0.25, 0.25, −0.25, SD 1, n = 23 per group,
  α = .05; run with Superpower 0.2.4.1):

  | r | `ANOVA_exact()` | `ANOVA_exact2()` | G*Power, as reported in [SP-vig] |
  | --- | --- | --- | --- |
  | 0.5 | 91.2498% | 90.4745% | 91.25% |
  | 0.7 | 98.9847% | 98.8079% | 98.98% |

  Why `ANOVA_exact2()` differs is **to check** (from Superpower's source or
  its authors).
- **Test:** the mixed published-value tests in
  `engine/tests/testthat/test-validation-anova-2x2-mixed.R` check
  `ANOVA_exact()` against 0.9125 (G*Power) and 0.9898467 (Superpower book
  Table 5.4). **There is no test yet that shows the `ANOVA_exact2()` values
  above**, which CLAUDE.md now requires; it belongs in `engine/tests/` (to
  do).
- **Shown to users / in the methods paragraph:** shown on the result screen (phase 5, part 1, 17 October 2026; `app/routing/forms.yaml`, `departures`). Stated in the full version of the write-up (18 October 2026).

### 3. `ANOVA_exact()` is run under the run's seed

- **Established convention:** Superpower's `ANOVA_exact()` builds its data
  set with the random-number generator, so repeated calls differ at about the
  15th decimal place [powerkit, `docs/decisions.md`].
- **powerkit:** builds the design first (`ANOVA_design()` also draws random
  numbers), then runs `ANOVA_exact()` under the run's seed and restores the
  caller's RNG state. So exact results are identical for a given seed and
  equal a direct call (design, then `set.seed()`, then `ANOVA_exact()`).
  Before phase 3 the design was built lazily inside the seeded block, so
  results differed from a direct call at about the 15th decimal place on
  Windows.
- **Size:** about 1e-15 in power, so this has no practical effect.
- **Test:** `engine/tests/testthat/test-run-spec.R`, "exact results are
  reproducible bit for bit and leave the RNG alone".
- **Shown to users / in the methods paragraph:** shown on the result screen for E7 and E8 (phase 5, part 1, 17 October 2026; `app/routing/forms.yaml`, `departures`). Stated in the full version of the write-up (18 October 2026).

### 4. One-sided basic tests (retired 17 October 2026: Spower 0.7 has the fix)

**Retired.** powerkit now uses Spower's own one-sided test. The number is
kept so later departures keep theirs.

- **What it was:** Spower 0.6.4's `two.tailed = FALSE` returned half the
  two-sided p-value whatever the direction of the observed effect
  (`p_t.test()`, `p_r()`, `p_prop.test()`) [Spower-src, 0.6.4], so with no
  effect it rejected about twice alpha (0.1022 against 0.0482, 5,000 seeded
  replications, alpha = .05). powerkit used Spower's generators with
  `t.test()`, `cor.test()` or `prop.test()` and `alternative` instead.
- **Upstream fix:** reported 13 October 2026 as
  [philchalmers/Spower#3](https://github.com/philchalmers/Spower/issues/3)
  and fixed by Phil Chalmers. **Spower 0.7 reached CRAN on 16 October
  2026.** Spower 0.7 has no NEWS file; the change was read from the source
  of 0.6.4 and 0.7 on CRAN [Spower-src]: each one-sided `p_*` function
  (`p_t.test()`, `p_r()`, `p_2r()`, `p_prop.test()`, `p_ks.test()`,
  `p_var.test()`, `p_wilcox.test()`, `p_scale()`) gains an `alternative`
  argument passed to the underlying test, `two.tailed = FALSE` becomes
  `alternative = "greater"` (`"less"` in `p_scale()`), and the line
  `p <- ifelse(two.tailed, p, p/2)` is gone.
- **powerkit now (Spower 0.7, `renv.lock`):** Spower's `p_t.test()`,
  `p_r()` and `p_prop.test()` with `alternative`, translated to Spower's
  orientation by `spower_alternative()`. Spower compares group 1 with
  group 2 (first time point with second; p1 with p2), and powerkit passes
  the effect with its sign reversed, so powerkit's `"greater"` (the effect
  is positive: group 2 higher, second condition higher, p2 > p1) is
  Spower's `"less"` for two-sample, paired and two-proportion tests. For
  one-sample t-tests and correlations the direction carries over.
- **Size of the change:** none in results. With the same seeds, every
  one-sided and two-sided basic test gives identical power under the old
  code with Spower 0.6.4 and the new code with Spower 0.7 (10 one-sided
  and 6 two-sided cases, 2,000 replications each; PR description,
  17 October 2026). The same data sets are analysed by the same test; only
  which function runs it changed.
- **Test:** `engine/tests/testthat/test-backend-spower.R`, "one-sided
  tests: powerkit and Spower's own one-sided test agree" (identical
  results with no effect and with an effect in the tested direction; with
  the effect in the wrong direction, neither powerkit nor Spower's
  `two.tailed = FALSE` counts it as significant) and "one-sided tests use
  the direction of the spec's effect" (the orientation mapping).
- **Shown to users / in the methods paragraph:** nothing to show now: no
  departure.

### 5. Two proportions and chi-square: no continuity correction (Spower applies one by default)

- **Established convention:** Spower's `p_prop.test()` and `p_chisq.test()`
  apply Yates' continuity correction by default (`correct = TRUE`)
  [Spower-src]. G*Power's z test and Pearson chi-square do not
  (maintainer's decision 6). **The G*Power manual cannot settle this**: its
  edition of 1 June 2023 has no section on the two-independent-proportions
  z test or on the chi-square test of independence. The one pooled z test
  for two proportions it does document is the large-sample approximation to
  Fisher's exact test, and that one **is** continuity corrected [GP-man,
  6.6.2, p. 17]. That is a different test from the z test G*Power offers
  separately, so it is a caution rather than evidence against decision 6;
  the maintainer can check the program itself.
- **powerkit:** no correction, and no option for one (maintainer's decision
  6), as in G*Power. This applies when Spower simulates (on request since
  17 October 2026); pwr's formulas, the default (Departure 9), have no
  continuity correction either.
- **Size:** two proportions, p1 = .50, p2 = .65, 170 per group,
  alpha = .05, the same 5,000 seeded data sets: power 0.8178 without the
  correction and 0.7894 with it (.028 lower). For the chi-square test it
  only matters for 2 x 2 tables.
- **Test:** `test-backend-spower.R`, "departure: no continuity correction,
  unlike Spower's default (correct = TRUE)", which also checks that
  powerkit's run equals the uncorrected value.
- **Shown to users / in the methods paragraph:** shown on the result screen (phase 5, part 1, 17 October 2026; `app/routing/forms.yaml`, `departures`). Stated in the full version of the write-up (18 October 2026).

### 6. Mediation fits: lavaan maximum likelihood, not PROCESS's OLS

- **Established convention:** PROCESS fits each equation by OLS.
- **powerkit:** fits the path model with lavaan (ML), power4mome's default,
  because power4mome's Monte Carlo confidence intervals need a lavaan fit
  (accepted by the maintainer, decision 12).
- **Size:** identical estimates. ML standard errors are the OLS ones times
  sqrt((n - k) / n), with k the number of coefficients in the equation
  including the intercept. At N = 50 they are 2.0% smaller for a (k = 2)
  and 3.0% smaller for b and c' (k = 3); at N = 200, 0.5% and 0.75%.
- **Test:** `test-backend-power4mome.R`, "departure: lavaan ML standard
  errors vs PROCESS's OLS, at N = 50" (checks the ratio to 1e-6).
- **Shown to users / in the methods paragraph:** shown on the result screen for E10–E14 (18 October 2026; `app/routing/forms.yaml`, `departures`). Stated in the full version of the write-up (18 October 2026).

### 7. Parallel mediators: residuals free to correlate (lavaan fixes them at 0)

- **Established convention:** PROCESS fits separate OLS regressions, which
  place no constraint on the mediators' residual covariance. lavaan, and so
  power4mome given a model without `M1 ~~ M2`, fixes it at 0 [p4m-src].
- **powerkit:** follows PROCESS (maintainer's decision 8): the fitted model
  always frees the residual covariance between parallel mediators, whatever
  its population value. This departs from lavaan's and power4mome's default
  model, not from PROCESS.
- **Size:** identical estimates. With a residual correlation of 0.4 and
  n = 200, fixing the covariance at 0 understates the standard errors of
  the M1->Y and M2->Y paths by about 10% (free / fixed = 1.111 for both,
  seeded data), so it would overstate power.
- **Test:** `test-backend-power4mome.R`, "departure: parallel mediators'
  residuals free to correlate, as in PROCESS".
- **Shown to users / in the methods paragraph:** shown on the result screen for E11 (parallel mediators) (18 October 2026; `app/routing/forms.yaml`, `departures`). Stated in the full version of the write-up (18 October 2026).

### 8. Boos and Zhang's (2000) method: off (power4mome switches it on for some R)

- **Established convention:** power4mome switches Boos and Zhang's method
  on automatically when the number of draws R is one of 39, 79, ..., 359.
  Each replication's test then uses a p-value rule instead of the
  confidence interval, and power4mome's own searches (e.g.
  `x_from_power()`) extrapolate rejection rates [p4m-src].
- **powerkit:** off, for validation and, until the user-facing choice is
  made, for every run (maintainer's decision 10). powerkit asks for the CI
  rule explicitly (`test_method = "ci"`), because power4mome's documented
  switch (`options(power4mome.bz = FALSE)`) does not reach its test
  functions in version 0.2.1 (`docs/decisions.md`).
- **Size:** none in powerkit's runs. At R = 39 both rules gave identical
  rejection rates on 100 seeded replications (at these R the p-value rule
  and the CI agree), and `power4test()` does not extrapolate. At any other
  R, including the default 1,000, the method is never used.
- **Test:** `test-backend-power4mome.R`, "departure: Boos-Zhang off makes
  no difference to power4test()'s rejection rate".
- **Upstream status:** reported 13 October 2026 as
  [sfcheung/power4mome#276](https://github.com/sfcheung/power4mome/issues/276); the `options(power4mome.bz = FALSE)` bug
  was confirmed and fixed by Shu Fai Cheung, who also checked the
  package's other `options()` / `getOption()` uses. On GitHub (power4mome
  0.2.1.33, 14 October 2026) all five test functions use `getOption()`.
  The fix is not on CRAN yet: CRAN is still 0.2.1, which predates the fix
  (checked 15 October 2026). Once a CRAN release includes the fix, record
  it here as "fixed upstream in version X".
- **powerkit keeps `test_method = "ci"` regardless.** Boos and Zhang off is
  the maintainer's decision (decision 10), not only a workaround for the
  bug, so the explicit argument stays after the fix reaches CRAN.
- **Shown to users / in the methods paragraph:** shown on the result screen for E10–E14 (18 October 2026; `app/routing/forms.yaml`, `departures`). Stated in the full version of the write-up (18 October 2026).

### 9. Basic tests (E1–E6): pwr's formula by default, not Spower's simulation

- **Established convention:** powerkit's earlier default, and the
  convention it followed, was simulation with Spower for every basic test
  (`Spower()` with `p_t.test()`, `p_r()`, `p_prop.test()`,
  `p_chisq.test()`) [Spower-src]. pwr gives the same tests by formula.
- **powerkit:** pwr's formula by default (maintainer's decision,
  17 October 2026; `docs/decisions.md`): exact where an exact answer
  exists (the t-tests, by the noncentral t; the chi-square test, by the
  noncentral chi-square), and no Monte Carlo noise. For a correlation
  (Fisher's z) and two proportions (a normal approximation: the z test by
  `power.prop.test()`, Departure 11, or Cohen's h) the formulas are
  approximations. Spower simulation stays available on request, and is
  used for Welch's t-test, which pwr doesn't cover. The two variance
  templates are basic tests that no formula backend covers at all, so they
  are always simulated and offer no exact method (Known difference 4).
- **Size:** the example designs below, alpha = .05 two-sided, formula
  against Spower simulation with 5,000 seeded replications (seed 9, one
  core). Every difference is within 2 Monte Carlo standard errors, so it
  is simulation noise; the formula removes it. The two-proportions row is
  `power.prop.test()`'s z test since Departure 11 (with pwr's Cohen's h it
  was 0.4911).

  | Test | n | Formula (pwr) | Simulation (Spower) | Difference |
  | --- | --- | --- | --- | --- |
  | One-sample t, d = 0.3 | 90 | 0.8038 | 0.8060 | +0.0022 |
  | Independent t (Student's), d = 0.4 | 200 | 0.8036 | 0.7954 | -0.0082 |
  | Paired t, d_z = 0.35 | 60 | 0.7601 | 0.7580 | -0.0021 |
  | Correlation, r = -0.2 | 120 | 0.5952 | 0.5926 | -0.0026 |
  | Two proportions, .6 vs .7 | 340 | 0.4892 | 0.4858 | -0.0034 |
  | Chi-square, 3 x 2 table (example spec) | 150 | 0.0855 | 0.0870 | +0.0015 |

- **Test:** `test-backend-pwr.R`, "departure: pwr's formula vs Spower's
  simulation (Departure 9)", which checks each size below.
- **Shown to users / in the methods paragraph:** shown on the result
  screen when the formula was used (`app/routing/forms.yaml`,
  `departures`). Stated in the full version of the write-up (18 October 2026).

### 10. Correlation (E4): Fisher's z, not G\*Power's exact method

- **Established convention:** G\*Power computes power for a correlation
  from the exact distribution of r by default, using "the algorithm
  described in Barabesi and Greco (2002)"; its Options dialog says "Use
  exact distribution if N <: 10000", and otherwise the Fisher z
  approximation (G\*Power 3.1 manual, June 1, 2023, section 3, pp. 9–10,
  supplied by the maintainer).
- **powerkit:** pwr's `pwr.r.test()` (pwr 1.3-0), whose help says "These
  calculations use the Z' transformation of correlation coefficient:
  Z'=arctanh(r) and a bias correction is applied". Kept as the default by
  the maintainer's decision of 17 October 2026 (`docs/decisions.md`).
  Spower simulation, which estimates the exact test's power, stays
  available.
- **Size:** two-sided, alpha .05, against pwrss 1.3.3's
  `power.exact.onecor()`, the exact method. It reproduces both of the
  manual's examples for this test to the printed precision: N = 1928 for
  ρ = .65 against ρ0 = .60, alpha = .05, power .95 (manual: 1928), and
  power 0.4829271 for ρ = .3 against ρ0 = .8, N = 8 (manual: 0.482927;
  section 3.3, p. 9). For
  r = .3 to .5 and N = 20 to 100 the power differs by at most 0.0038
  (N = 20, r = .5; one-sided, at most 0.0047). The required N for 80%
  power differs by at most 1: 85 rather than 84 at r = .3; the same at
  r = .4 (46) and r = .5 (29). The full table is in
  [`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md), G6.
- **Test:** `test-backend-pwr.R`, "departure: correlation by Fisher's z,
  not G\*Power's exact method (Departure 10)".
- **Shown to users / in the methods paragraph:** on E4's card (backend
  line) and on the result screen when the formula was used
  (`app/routing/forms.yaml`, `departures`). Stated in the full version of the write-up
  (18 October 2026).

### 11. Two proportions (E5): G\*Power's z test by `power.prop.test(strict = TRUE)` and pwrss

- **Established convention:** G\*Power 3.1.9.7's z test for two
  independent proportions ("Proportions: Difference between two
  independent proportions"), with its default options: no continuity
  correction, no arcsine transformation (maintainer's screenshots,
  17 October 2026, `docs/figures/gpower/`). It counts rejections in both
  tails. Base R's `power.prop.test()` (stats) computes the same z test
  (pooled variance under the null, unpooled under the alternative, no
  continuity correction; its help and source), but its default,
  `strict = FALSE`, leaves out the opposite tail, and it takes one n for
  both groups.
- **powerkit:** `power.prop.test(strict = TRUE)` for equal groups, and
  pwrss 1.3.3's `power.z.twoprops(std.error = "pooled")` for unequal
  groups (maintainer's decisions, 17 October 2026; `docs/decisions.md`).
  When the user chooses it (`options > proportions_formula = "arcsine"`),
  pwr's `pwr.2p2n.test()` with Cohen's h, powerkit's earlier default.
  Group sizes keep the exact ratio the user gives (as for every
  two-group design), and the required N is the smallest such N whose
  power reaches the target.
- **Size:**
  - Against G\*Power, equal groups: none to seven decimals (p1 = .10,
    p2 = .25, two-sided, alpha .05: power 0.2344921 at 20 per group; 164
    per group for 95% power, actual power 0.9502464).
  - `strict = TRUE` against `power.prop.test()`'s default: 0.2344921
    against 0.2339595 at 20 per group.
  - Against powerkit's earlier default (Cohen's h), same example: 0.2478
    at 20 per group; 160 rather than 164 per group for 95% power. The
    table in [`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md), G6, has more
    cases (largest gap 0.018 in power, 3 per group for 80% power).
  - Unequal groups, pwrss against G\*Power: the same power at the same
    group sizes (0.9498668 at 123 and 247, p1 = .10, p2 = .25). The
    required N can differ by a few: for 95% power at N2/N1 = 2, G\*Power
    gives 123 + 247 = 370, whose power (0.9498668) is just under the
    target and whose groups aren't exactly 1 : 2; powerkit gives 124 + 248
    = 372 (123 + 246 gives 0.9496). Cohen's h, the earlier choice for
    unequal groups, gave 360, 10 fewer than G\*Power. pwrss's values at
    1 : 1, 1 : 2 and 1 : 3 in both directions are in the tests; G\*Power's
    for those inputs are to confirm from the maintainer's screenshots.
  - One-sided tests: `power.prop.test()` and pwrss use |p1 − p2|, so for a
    one-sided test against the specified difference powerkit takes the
    two-sided power at 2 × alpha minus the one-sided power (the tail away
    from the difference).
- **Test:** `test-backend-pwr.R`, "two proportions: the z test equals
  G\*Power's (Departure 11)", "departure: both tails counted (strict =
  TRUE), and the size of the change from the arcsine (Departure 11)",
  "two proportions in unequal groups use pwrss's z test, as G\*Power
  (Departure 11)", "two proportions: pwrss at 1:1, 1:2 and 1:3, both
  directions", "departure: unequal groups keep the exact ratio, so N can
  differ from G\*Power's by a few (Departure 11)", and the two one-sided
  direction tests.
- **Shown to users / in the methods paragraph:** on E5's card (backend
  line) and on the result screen when the formula was used
  (`app/routing/forms.yaml`, `departures`). Stated in the full version of the write-up
  (18 October 2026).

### 12. Two dependent correlations: G\*Power's unpooled Steiger test, not pwrss's pooled default

**The maintainer's decision, 25 October 2026** (`docs/decisions.md`).

- **Established convention:** G\*Power's test of two dependent
  correlations (common index or none) is Steiger's (1980) z test. Under
  H0 it computes the covariance of the two correlations with the H1
  correlation set equal to the H0 one, ρ_ac = ρ_ab (or ρ_cd = ρ_ab)
  [GP-man, 28.5.3, p. 69]. Its required N for the manual's examples
  28.3.1 and 28.3.2 is 886 and 144 [GP-man, 28.3, p. 67]. pwrss 1.3.3's
  `power.z.twocors.steiger()`, the backend, defaults to `pooled = TRUE`:
  under the null it uses the *average* of the two compared correlations
  instead (`R/correlations.R`).
- **powerkit:** `pooled = FALSE`, whose source substitutes the H0
  correlation for the H1 one (its `# rho12 = rho13` branch) — the same
  rule the manual states — and which reproduces G\*Power's N for both
  examples.
- **Size:** the required N is about 1 to 4% larger than with pwrss's
  default. One-sided, alpha .05, 80% power: 144 against 139 (common
  index: .40 under H0 and .20 under H1, the third correlation .50) and 886
  against 875 (no common index: .10 under H0 and .20 under H1; the others
  .50, .40, -.40, .80). Both are the manual's own examples, and powerkit's
  power at those N matches its "actual power" to six decimal places for
  the common-index case (0.801161) and to about 6e-5 for the other
  (0.800156 against 0.800093).
- **Test:** `test-backend-formula-tests.R`, "departure: dependent
  correlations use G\*Power's unpooled test, not pwrss's pooled default
  (Departure 12)".
- **Shown to users:** on the result screen for two dependent correlations
  (E51) and in its methods paragraph (26 October 2026;
  `app/routing/forms.yaml`, `departures`, key "12").

### 13. Whole-study simulation (experimental): one population for every analysis, and joint power counted directly

**The maintainer's decision, 27 October 2026** (`docs/decisions.md`): built
as an experimental option, for a statistician's check
([`whole-study-method.md`](whole-study-method.md)).

- **Established convention:** each analysis is calculated on its own (G\*Power,
  pwr, InteractionPoweR, power4mome's templates), from inputs given in its
  own form, and the chance that several analyses all succeed is worked out
  from their separate powers as if they were unrelated (the guided plan's
  rule of thumb: about 89.4% each for two tests and 80% together).
- **powerkit (whole-study simulation only):** one population model,
  given as standardised paths, generates every simulated data set
  (power4mome); each planned analysis is fitted to the same data sets with
  its own model, and the joint power is the proportion of replications in
  which every main analysis (or, for "any", at least one) is significant.
  The separate input screens are unchanged.
- **Size:** each analysis's own power agrees with its separate calculation
  from the values the population implies, within simulation error (local
  runs of 2,000 to 4,000 replications: the correlation 48.4% against pwr's
  47.7%, simple mediation 71.8% against powerkit's own E10 run, 72.0%; the
  interaction 47.5% against InteractionPoweR's 49.2%, and a correlation
  whose outcome also depends on an interaction 76.5% against 77.6%; the
  last two are about 1.5 Monte Carlo standard errors apart and are a
  question for the statistician). The joint power differs where the
  analyses are related: for the correlation and simple mediation (a = b =
  .3, c' = .1, N = 100), both significant in 38.1% of replications against
  34.8% from the product of the separate powers, 3.3 points higher. For
  the correlation and an interaction they were unrelated (36.5% against
  36.4%).
- **Test:** `test-validation-whole-study-crosscheck.R` (full validation,
  chunk `whole_study`): each analysis against its separate calculation,
  the joint power above the product of the separate powers for related
  analyses, and Type I error with every path 0; `test-whole-study.R`: the
  joint counts' exact bookkeeping.
- **Shown to users:** on the whole-study result screen ("How this differs
  from calculating each analysis separately"; `app/routing/forms.yaml`,
  `departures`, key "13") and in its methods paragraph, which says the
  whole study was simulated.

## Known differences

powerkit follows an established tool here, but another established tool
gives a different answer. These are not departures. Users comparing tools
will notice them, though, so each entry states the size of the difference
and, like a departure, is shown on the results screen and stated in the
methods paragraph.

### 1. Regression interactions: fixed-model power is slightly higher than simulated power

- **What differs:** fixed-model regression power, such as G*Power's linear
  multiple regression and InteractionPoweR's analytic
  `power_interaction_r2()`, is slightly higher than simulated power for
  interactions. powerkit simulates (InteractionPoweR's
  `power_interaction()`), so it may need a few more participants than
  G*Power.
- **Size:** up to about 1.4 points of power, or about 3% of N, in the grid
  comparison (72 cells: N 50-500, r_XW_Y 0.05-0.20, reliability 0.7-1,
  r_X_W 0-0.3). The largest gap was at N = 200, r_XW_Y = 0.20,
  reliability 1, r_X_W = 0.3: 0.808 simulated vs 0.822 analytic. For 80%
  power there, the analytic method gives N = 190 and simulation about 196.
  On average the gap is 0.2 points (z = -5.49); it grows with the size of
  the interaction and is about zero at r_XW_Y = 0.05.
- **Likely causes (likely, not confirmed):** the analytic method treats the
  predictors as fixed, whereas in real samples X and W are random and their
  product is heavy-tailed, which lowers power on average; and possibly the
  df convention (`power_interaction_r2()` uses N - 3 denominator df, where
  Y ~ X + W + XW leaves N - 4) [IP-src].
- **G*Power:** the grid measured `power_interaction_r2()`, not G*Power.
  G*Power is expected to behave the same way, and the manual now confirms
  why: its R² increase test is the "fixed model", Y = X beta + e with
  "fixed and known predictor variables", with lambda = f² N on
  F(q, N - m - 1), so for a two-way interaction q = 1 and m = 3, giving
  N - 4 denominator df [GP-man, 14, 14.5, pp. 36-38]. The predictors being
  fixed is therefore established; how much power G*Power reports for these
  designs has still not been measured, because the grid did not run it.
- **Test:** `scripts/run-validation.R --only interaction_grid` (on demand;
  full results in `docs/decisions.md`).
- **Shown to users:** on E9's result screen, under "Where other established tools give a different answer" (18 October 2026; `app/routing/forms.yaml`, `known_differences`).
- **The smallest detectable effect is the exception (maintainer's decision, 19 October
  2026):** it comes from `power_interaction_r2()` (a search over the
  interaction's correlation with Y, the other correlations kept), because
  a simulation search would take minutes. So it follows the fixed-model
  convention, and the true smallest detectable effect may be slightly
  larger. The result screen, the methods sentence (`known_differences`
  and `known_differences_methods`, key "1 sensitivity") and the R script
  say so. Tests: `engine/tests/testthat/test-backend-interactionpower.R`
  (the search against `power_interaction_r2()` called directly) and
  `app/routing/tests/testthat/test-results.R` (the labels).
- **Methods paragraph (interaction designs), one sentence:** "Power was estimated by simulation, with the predictors drawn afresh in each simulated sample; fixed-model calculations such as G*Power's, which treat the predictors as fixed, give slightly higher power for interactions, so this sample size may be a few participants larger than G*Power's."
  To be added when the methods paragraph (`writeup.R`) is built in phases
  4-5.

### 2. Exact tests of counts (one proportion, McNemar, Fisher's exact test): the smallest N that reaches the target

*Moved from the departures (it was Departure 12) by the maintainer's
decision, 18 October 2026: G\*Power reports the same N as powerkit.
Wired into the app on 18 October 2026 (E25, E26).*

- **What differs:** for exact tests of counts, power goes up and down
  with N. powerkit and G\*Power report the smallest N that reaches the
  target; pwrss's own sample-size answer (`power.exact.oneprop(power = )`,
  `power.exact.mcnemar(power = )`) is a little larger.
- **Size:** for the example inputs, 90 (powerkit and G\*Power) against 92
  (pwrss) for one proportion (0.65 against 0.50, two tails), and 129
  against 130 for McNemar (0.25 and 0.10, two tails, G\*Power's exact
  option). At N = 90 the one-proportion power is 0.812, but it falls
  below 0.80 again at 91, 96 and others.
- **G\*Power:** maintainer's screenshots, 18 October 2026
  (`docs/figures/gpower/A35_one_proportion_a_priori.png`,
  `A37_mcnemar_a_priori_exact.png`). G\*Power's default McNemar option,
  the faster approximation, gives 121; powerkit matches its exact option.
- **Test:** `test-backend-wave2.R`, "exact tests of counts report the
  smallest n that reaches the target", "known difference: pwrss's own
  sample-size answer for exact tests of counts (Known difference 2)", and
  the G\*Power checks for one proportion and McNemar.
- **Fisher's exact test** (E5's option, 18 October 2026) is an exact test
  of counts too, and powerkit reports its smallest N in the same way. It
  hasn't been compared with G\*Power yet, and the size of the difference
  from pwrss's own sample-size answer hasn't been measured for it.
- **Shown to users:** on the result screen for one proportion (E25),
  McNemar's test (E26) and Fisher's exact test (E5), under "Where other established tools give a
  different answer" (18 October 2026; `app/routing/forms.yaml`,
  `known_differences`).
- **Methods paragraph:** to do with the write-up: a note that power for
  these tests goes up and down with N, so a slightly larger N can have
  lower power.

### 3. Logistic regression with other predictors ("R² other X" above 0)

- **What powerkit does:** pwrss's `power.z.logistic()` with Demidenko's
  variance correction, where `r.squared.predictor` enters the
  noncentrality as an effective sample size N(1 − R²). The required N is
  therefore the R² = 0 answer divided by (1 − R²).
- **The difference:** at R² = 0 powerkit reproduces every number the
  manual prints for its normal-X example: 337 (Demidenko with variance
  correction), 355 (without) and 317 (Hsieh et al.) [GP-man, 29.4, p. 71].
  At R² = 0.1 the manual reports 395 for "the procedure of Demidenko
  (2007) with variance correction" [GP-man, 29.4, p. 72], where powerkit
  gives 375 = 337 / 0.9. 395 is exactly 355 / 0.9, powerkit's answer with
  the variance correction switched off, so the two appear to differ in
  whether that correction still applies once R² is above 0. The manual's
  formulas (14) and (15) [GP-man, 29.6.2, p. 72] put R² in the mean of the
  H1 distribution only, which is what powerkit does and implies 375.
- **What Poisson regression suggests.** The same correction, in the same
  place in the formula, is used for Poisson regression, and there the
  manual's R² figure does match: for the swimmers example at R² = 0.1 it
  reports 774 with Signorini's procedure [GP-man, 30.3, p. 77], which is
  that procedure's own R² = 0 answer (697) with the correction applied
  inside its formula, and pwrss's `"signorini"` method gives 774 too. So
  G*Power appears to apply R² within whichever procedure produced the
  R² = 0 answer, as powerkit does, which is what the logistic figure of
  395 (Demidenko with variance correction, but 355 / 0.9) does not do.
- **Not resolved here.** G*Power itself has not been run; the manual's own
  validation notes record a deviation from PASS for this case as well
  [GP-man, 29.7, p. 73]. The maintainer has G*Power and can settle it
  (`docs/decisions.md`, 25 October 2026). Until then powerkit's answer for
  R² above 0 may be a few per cent smaller than G*Power's.
- **Test:** none yet; the validation placeholders
  (`test-validation-logistic-regression.R`) say to prefer an example with
  "R² other X" = 0.
- **Shown to users:** on logistic regression's result screen (E27) and in
  its methods paragraph, only when "R² other X" is above 0 (26 October
  2026; `app/routing/forms.yaml`, `known_differences` and
  `known_differences_if_above_zero`). Test: `test-results.R`, "logistic
  regression runs on pwrss, with Known difference 3 only when other
  predictors overlap".
### 4. Variance tests: simulated, where G\*Power uses an exact formula

- **What differs:** G\*Power computes both variance tests from their exact
  distributions (the chi-square test of one variance, section 26.5 of its
  manual; the F test of two, section 15.5), so it reports one number.
  powerkit simulates them with Spower's `p_var.test()`, because no package
  powerkit builds on has a formula for either and powerkit doesn't write
  the maths itself (CLAUDE.md). Its answer therefore carries Monte Carlo
  error, and two runs with different seeds differ slightly.
- **Size:** the error is the Monte Carlo error alone, not a difference in
  the test: about 0.013 of power at the default 1,000 replications and
  about 0.004 at 10,000 (at 80% power). Run at 10,000 replications, the two
  examples in the manual (sections 26.3 and 15.3) came out +0.003 and
  -0.005 from G\*Power's exact values, each within about one Monte Carlo
  standard error. Required sample sizes can differ by a participant or two
  for the same reason.
- **Test:** `engine/tests/testthat/test-validation-variance-tests.R` holds
  the two published examples (values to transcribe) and the direct-call and
  Type I error checks; `test-backend-spower.R` checks the translation and
  that no exact method is offered.
- **Shown to users:** on the result screens for one variance (E52) and two
  variances (E53), under "Where other established tools give a different
  answer" (26 October 2026; `app/routing/forms.yaml`, `known_differences`).
- **Methods paragraph:** "Power was estimated by simulation, so it carries
  Monte Carlo error, whereas G\*Power computes this test exactly."
  (`known_differences_methods`, key "4").

## Not departures, but worth stating

- **Default method for 2 x 2 designs:** exact (`ANOVA_exact()`), with
  simulation on request. This matches G*Power and the published values
  [powerkit, `docs/decisions.md`].
- **Sample size convention:** `goal.n` is the total number of participants
  analysed (Superpower's `n` is per cell or group; powerkit converts)
  [powerkit].
- **ANCOVA:** Superpower has `ANCOVA_analytic()` and `power_oneway_ancova()`
  [SP-src]. These may serve the ANCOVA route for pre–post designs (decision
  D2 in `docs/design-finder.md`); whether they match G*Power is to check.
  The engine's one-way ANCOVA (18 October 2026, not yet in the app) uses
  pwrss's `power.f.ancova.shieh()`, Shieh's (2020) method, which
  Superpower's `power_oneway_ancova(type = "exact")` also uses (its help
  names Keppel's approach as the approximate one); a test shows the two
  agree. Whether it matches G*Power's ANCOVA is still to check.
- **Unequal group sizes (2 x 2 between and mixed).** powerkit's 2 x 2
  templates require equal group sizes; unequal groups are "coming later"
  (decisions D5, N1 and N3 in `docs/design-finder.md`). See "Superpower and
  unequal group sizes" above.
- **Paired designs: d_z is the second condition minus the first**, in the
  order of X's levels (maintainer's decision 5). G*Power's d_z is the mean
  difference over the SD of the differences [SP-vig]; the direction only
  matters for one-sided tests. It is stated when a paired spec is printed,
  and must be on the app's confirmation and results screens.
- **Residual correlations, not covariances.** The spec gives parallel
  mediators' residual correlations; power4mome's `M1 ~~ M2` value is a
  residual covariance, so powerkit converts, multiplying by
  sqrt((1 - R^2 of M1)(1 - R^2 of M2)). Same population, different
  parametrisation; the check run recovers the correlation on every run.
- **Product terms.** powerkit's validator and power4mome agree: a product
  of two standardised variables with correlation r has variance 1 + r^2,
  and its path coefficient applies to the raw product [p4m-src, checked by
  simulation].
- **Sample size search for simulated designs:** powerkit's own
  `search_n()` (a probit fit to simulated power, with a 95% interval for
  n), not Spower's or power4mome's own searches, so every design reports n
  the same way [powerkit].
- **Default method for every design except the 2 x 2 ANOVAs:** simulation,
  with `options > nrep` replications (default 1,000) [powerkit].
- **Regression interactions: simulated power, not analytic.**
  InteractionPoweR presents neither method as primary: its DESCRIPTION
  names `power_interaction_r2()` (analytic) and `power_interaction()`
  (simulation) together as "the primary functions"; its main article
  introduces the analytic method first; its home page recommends the
  analytic web app for beginners [IP-src, IP-web]. So simulating follows
  one of InteractionPoweR's two primary methods and is not a departure.
  powerkit reports simulated power only; after the grid comparison the
  maintainer decided not to offer the analytic method (`docs/decisions.md`).
  The difference between the two is in "Known differences", 1.
- **power4mome calls are seeded with `set.seed()` as well as `iseed`.**
  For a model with a product term (PROCESS models 7 and 14),
  `power4test()` standardises the population by Monte Carlo (100,000
  draws, its `n_std`) before `iseed` takes effect, from whatever state R's
  random-number generator is in [p4m-src: `ptable_pop()`, `psi_std()`,
  `psi_std_monte_carlo()`]. powerkit runs each call with the generator
  seeded by the call's own seed, so a result depends only on the seed and
  batch size. The method is unchanged (the standardisation is a
  100,000-draw Monte Carlo estimate either way); only which draws it uses
  is fixed, so there is no systematic difference to measure. Models
  without a product term are standardised analytically and are unaffected.
  Test: `test-backend-power4mome.R`, "with a product term, a batch's
  result depends only on its seed" [powerkit, `docs/decisions.md`].
- **Exported scripts reproduce powerkit's procedure.** `export_script()`
  calls the backend package directly, with powerkit's seeds and batches,
  and for a sample-size goal powerkit's own search (above), not the
  backend's. It adds no method of its own, so it gives powerkit's numbers
  with the same package versions. Tests: `test-export-script.R`, one per
  end point E1-E14 [powerkit].
