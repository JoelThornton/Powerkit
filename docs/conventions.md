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
| **powerkit** | **By default, pwr's formula**: `pwr.t.test()` (one-sample; paired, with d_z; two equal groups) or `pwr.t2n.test()` (unequal groups), Student's only. **Two groups:** Welch's t-test by default (Departure 21), by pwrss's `power.t.welch()`. **On request:** Spower's `p_t.test()`; one-sided tests pass `alternative`, translated to Spower's orientation (for two-sample and paired tests powerkit's `"greater"` is Spower's `"less"`). Student's or Welch's as the spec says; the two-group card pre-selects Welch's (Departure 21) [powerkit] | `d` = (mean of group 2 - mean of group 1) / SD; `dz` = mean of (second condition - first) / SD of the differences, stated when a paired spec is printed. Passed to Spower as -d and -sqrt(2) * d_z [powerkit] | `alternative`: two-sided by default, or `greater` / `less` ("greater" = the effect is positive); `allocation_ratio`; `goal.n` is the total |

### Correlation, two proportions, chi-square test of independence

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | Correlation: "Exact: Correlation - difference from constant (one sample case)", the bivariate normal model, computed either from the exact distribution of the sample correlation (Barabesi & Greco, 2002) or from the Fisher z large-sample approximation, H1 N((Fz(rho) - Fz(rho0)) / sigma, 1) with sigma = sqrt(1 / (N - 3)) [GP-man, 3, pp. 9-10]. Two proportions: the manual (1 June 2023) documents only the exact tests - one proportion against a constant (binomial, 4, pp. 11-13), McNemar (5, pp. 14-16) and Fisher's exact test (6, pp. 17-18) - and has **no section on the two-independent-proportions z test** or on the chi-square test of independence | Correlation: the alternative correlation rho with the null value rho0 (the effect is rho - rho0; rho0 = 0 is a special case), with Cohen's (1969) small .1, medium .3, large .5, and a drawer to get \|rho\| from r-squared. One proportion: g = pi - pi0, entered as a difference, ratio or odds ratio. McNemar: the odds ratio pi12 / pi21 **and** the proportion of discordant pairs pi_D = pi12 + pi21. Fisher: the two proportions directly [GP-man, 3.1, 4.1, 5.1, 6.2] | Correlation: **"Use exact distribution if N < x" (with a threshold) or "Use large sample approximation (Fisher Z)"**; the critical value is named r for the exact procedure and z for the approximation. The manual's own example of the size of the difference: for rho0 = .8, rho = .3, N = 8, two-sided alpha .05 the exact power is 0.482927 and the approximation 0.422599; at N near 1,928 the two differ by one person [GP-man, 3.2, 3.3]. One proportion and McNemar: **alpha balancing in two-sided tests**, three options, "Assign alpha/2 to both sides" by default; McNemar also chooses exact unconditional power or a faster approximation, and its N is the number of pairs [GP-man, 4.2, 5.2]. Fisher: "no options" in 6.3, although 6.6.1 describes three asymptotically equivalent two-sided statistics, which one is used by default being unstated; its large-sample approximation is a **continuity-corrected** pooled z test [GP-man, 6.3, 6.6] |
| Superpower | Not covered [SP-src] | | |
| pwrss | to check | to check | to check |
| InteractionPoweR | Not covered: to check | | |
| power4mome | Not covered: to check | | |
| Spower | `p_r()`: `cor.test()` (Pearson, exact t test against 0); `p_prop.test()`: `prop.test()`; `p_chisq.test()`: `chisq.test()`, which for a matrix of cell probabilities is the test of independence (its null pattern `P0` is then not used) [Spower-src] | `r`; `prop` (one per group); `P` (cell probabilities) [Spower-src] | Yates' continuity correction on by default (`correct = TRUE`) in `p_prop.test()` and `p_chisq.test()`; `n` is per group for `p_prop.test()` and the total for `p_chisq.test()` [Spower-src] |
| **powerkit** | **By default, a formula** (Departure 9): for a correlation the exact distribution of r, as G*Power, by `pwrss::power.exact.onecor()` (pwr's `pwr.r.test()`, Fisher's z, on request; Departure 10, retired); for two proportions the z test with pooled variance under the null, as G*Power (Departure 11): base R's `stats::power.prop.test(strict = TRUE)` for equal groups and `pwrss::power.z.twoprops(std.error = "pooled")` for unequal groups, or on request `pwr.2p2n.test()` with Cohen's h = ES.h(p2, p1) (arcsine approximation), none with a continuity correction; and `pwr.chisq.test()` with Cohen's w = ES.w2(P) and df = (rows - 1)(columns - 1). **On request:** Spower's `p_r()`, `p_prop.test()` and `p_chisq.test()`; one-sided correlation and proportions tests pass `alternative` (for two proportions powerkit's `"greater"`, p2 > p1, is Spower's `"less"`; the chi-square test is two-sided only) [powerkit] | `r`; `p1`, `p2` ("greater" = p2 > p1); a table of cell probabilities | **No continuity correction** (`correct = FALSE`), as in G*Power (maintainer's decision 6; Departure 5) |

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
### Repeated-measures (within-person) correlation (from 13 November 2026)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| rmcorr | `rmcorr()`: the analysis of covariance with a separate intercept for each person and one common slope; its t test has N(k - 1) - 1 degrees of freedom for N people measured k times (Bakdash and Marusich, 2017, `Bakdash2017_rmcorr`). Its documentation plans power by giving G\*Power or pwr's `pwr.r.test()` the "effective sample size" N(k - 1) + 1, the Pearson sample size with the same degrees of freedom; its own example uses `pwr.r.test()` (Fisher's z) | r_rm, the within-person correlation | — |
| G\*Power | No repeated-measures correlation; used as rmcorr's documentation says, its exact correlation test at n = N(k - 1) + 1 [GP-man, 3] | ρ | tails; alpha |
| **powerkit** | The exact distribution of r at the effective sample size, by pwrss's `power.exact.onecor()`, as the correlation card (E4) does; template `repeated_measures_correlation`, card E76 [powerkit] | `r` and `measurements` (k, at least 2); the sample size is the number of people | One-sided tests run in the direction of r. **Not a departure**: G\*Power's exact test at rmcorr's effective n. pwr's Fisher's z, in rmcorr's example, differs by about 0.0002 in power (rmcorr's 0.8157 against 0.8159 at N = 100, k = 3, r = .2; `test-backend-rmcorr.R`). Assumes one slope shared by everyone; a slope that varies between people needs a multilevel model with random slopes (the card says so) |
### Small telescopes for replications (from 8 November 2026, 0.47.0)

- **What it is:** Simonsohn's (2015, `Simonsohn2015_telescopes`) plan for
  a replication of one original study: d33 (r33 for a correlation) is the
  effect the original study had 33% power to detect with its own sample
  size (two-sided, at the significance level the original study used,
  0.05 unless the user says otherwise; from 0.47.2, before which the
  card's alpha was used, see below), and the replication is planned so
  that, if the true effect is zero, a one-sided test can show the effect
  is smaller than d33. Offered on the one-sample, paired and two-group
  t-tests and the correlation, beside safeguard power, when the effect
  comes from a previous study (`effect_justification > small_telescopes`).
- **powerkit:** d33 from pwr (`pwr.t.test()`, `pwr.t2n.test()`,
  `pwr.r.test()` at `power = 1/3`); the replication's test from pwrss
  (`power.t.student(d = 0, margin = d33, alternative = "one.sided")`,
  Student's t-test as in the method, and `power.z.onecor(rho = 0,
  null.rho = r33)`). No package implements the planning
  (RSmallTelescopes analyses a finished replication), so the method is
  composed from these two packages' functions; no new maths is written.
- **Not a departure:** G\*Power and the other tools have no
  small-telescopes option. The result matches Simonsohn's rule of thumb of
  about 2.5 times the original sample: 51 per group for an original 20 per
  group, 75 for an original 30 in a paired design and 103 for a
  correlation from an original 40 (`test-small-telescopes.R`).
- **Two significance levels (0.47.2):** d33 uses the original study's
  level, the replication's test the card's. With one alpha for both, a
  replication at .005 got d33 = 0.79 instead of 0.50 for an original of
  20 per group, and 38 per group instead of 96 (`test-small-telescopes.R`).
- **What a result shows:** a result below d33 means a study the size of
  the original could not reliably have detected an effect that small; it
  doesn't show the original was a false positive (Simonsohn, 2015, p.
  567), and it bears on the original only as far as the replication
  recreated its conditions. The result says so, and its "How sure can you
  be?" section shows the power if the true effect is a quarter, half or
  three quarters of d33 rather than 0 (59%, 35% and 15% for an original
  of 20 per group and a replication of 51 per group at alpha .05, against
  80% for a true effect of 0).

### Variance tests (one group, two groups)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | One group: the chi-square test. (N - 1)s^2/sigma0^2 is central chi-square with N - 1 df under H0, and the same distribution scaled by sigma^2/sigma0^2 under H1 (section 26.5) [GP-man]. Two groups: the F test. s1^2/s0^2 is central F with N1 - 1 and N0 - 1 df under H0, scaled by sigma1^2/sigma0^2 under H1 (section 15.5) [GP-man] | The variance ratio var1/var0; the effect-size drawer works it out from two variances. Ratios in [0.999, 1.001] are refused (sections 26.1, 15.1) [GP-man] | Tails (one or two); allocation ratio N2/N1 (two groups, section 15.3) [GP-man] |
| Spower | `p_var.test()`: one variance plus `sigma2` goes to `EnvStats::varTest()` (the chi-square test); two variances go to `stats::var.test()` (the F test), whatever `test` says, unless `test = "Fligner"`. `test` (Levene, Bartlett, Fligner) is for three groups or more [Spower-src] | `vars` (one variance, or one per group), `sigma2` (the value tested against) [Spower-src] | `alternative`, or `two.tailed`; `two.tailed = FALSE` means `"greater"` whichever way the variances point, so a test of a **smaller** variance needs `alternative = "less"` (`docs/upstream-questions.md`). `n` is one group's size and `n.ratios` the group sizes' ratios, but unequal ratios fail in `gen_var.test()` (`docs/upstream-questions.md`) [Spower-src] |
| pwr, pwrss, Superpower, InteractionPoweR, power4mome | Not covered: none of them exports a power function for a variance (their exported functions, checked 25 October 2026) | | |
| **powerkit** | Since 31 October 2026, the exact distributions above, as G\*Power computes them, with base R's `stats::pchisq()` and `stats::pf()` (`backend-variance.R`; CLAUDE.md allows a published closed-form result where no package has one). Spower's `p_var.test()` simulates the same tests with `options > method` "simulation". Known difference 4 is retired [powerkit] | `var` and `var0` (one group: the expected variance and the fixed value it is compared with); `var1` and `var2` (two groups, in the order the groups are listed). Power depends on the ratio alone | `alternative`: two-sided by default, or `greater` / `less` ("greater" = the variance, or group 1's variance, is the larger one), `goal.n` is the total. The formula takes an allocation ratio for the two-group test, keeping the ratio exact (G\*Power's own example with N2/N1 = 2 gives 148 and 295, N = 443; powerkit 148 and 296, N = 444); the simulation is refused one while Spower can't draw unequal groups |

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
| **powerkit** | `ANOVA_exact()` by default; `ANOVA_power()` on request [powerkit] | Cell means, one SD or one per cell, and `r`: one correlation, or (from 1 November 2026) one per group, which Superpower takes as the whole correlation matrix (0 between groups; `test-backend-factorial-covariance.R`) | Reproduces the 91.25% and 98.98% that [SP-vig] reports from G*Power's within-between interaction; the G*Power setting behind those values is to check (see Departure 2). `goal.n` is the total number analysed and must be even. Equal group sizes only (see "Superpower and unequal group sizes" below). |

### One-way repeated measures (one within factor, three or more levels)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | "ANOVA: Repeated measures, within factors". **The manual has no section on any repeated-measures ANOVA** [GP-man, contents], so its inputs and defaults (the nonsphericity correction, the effect-size setting) are to check in G*Power itself | Cohen's f, with the correlation among repeated measures as a separate field unless "As in SPSS" is chosen (see the 2 x 2 mixed row above) [SP-vig] | To check (maintainer, in G*Power) |
| Superpower | `ANOVA_exact()` on the design `"kw"` (for example `"3w"`), and `ANOVA_power()` for simulation [SP-src]; `power_oneway_within()` computes the same test from the design object [SP-src] | Condition means, SD(s) and a correlation `r` between repeated measures [SP-src] | `correction` defaults to `"none"` (`Superpower_options()`), for both `ANOVA_exact()` and `ANOVA_power()` [SP-src] |
| **powerkit** | `ANOVA_exact()` by default; `ANOVA_power()` with `options > method = "simulation"` [powerkit] | Condition means in the user's units or standardised, one SD and one correlation for every pair of conditions, or (from 31 October 2026, means in the user's units) an SD per condition and a correlation per pair, the upper triangle row by row as `ANOVA_design()` takes it | Superpower's default, no sphericity correction, unless `target_test > correction` asks for `"GG"` or `"HF"`, which Superpower applies (`ANOVA_exact(correction =)`, `ANOVA_power(correction =)`). With one SD and one correlation the covariance matrix has compound symmetry, sphericity holds and the corrections change nothing; with unequal ones they matter: for means 0, 0.3, 0.5, SDs 1, 1.2, 1.5 and correlations 0.8, 0.5, 0.6 at n = 30, 56.1% uncorrected, 47.6% with Greenhouse-Geisser, 48.6% with Huynh-Feldt (`test-backend-anova-within-covariance.R`). The default follows Superpower and G\*Power's epsilon of 1, so it is not a departure. The MANOVA approach is shown beside the F test (from 29 October 2026). `goal.n` is the number of participants, each in every condition, at least 5. Agrees with `power_oneway_within()` in `test-backend-oneway-within.R` |

### Mixed designs beyond 2 x 2 (one between factor, one within factor)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | "ANOVA: Repeated measures, within-between interaction" (and "between factors", "within factors" for the main effects). The manual has no section on them [GP-man, contents]; see the 2 x 2 mixed row above | As the 2 x 2 mixed row | To check (maintainer, in G*Power) |
| Superpower | `ANOVA_exact()` on the design `"kb*mw"` (for example `"2b*3w"`), `ANOVA_power()` for simulation [SP-src]. `ANOVA_exact()` refuses a design whose n per group is not greater than the number of cells ("n <= the product of the factors") [SP-src] | Cell means, SD(s) and `r` | `correction` `"none"` by default [SP-src] |
| **powerkit** | As the 2 x 2 mixed design: `ANOVA_exact()` by default, `ANOVA_power()` on request [powerkit] | Cell means (one row per group), one SD and one correlation between every pair of the within factor's levels, or (from 1 November 2026, means in the user's units) an SD per cell and a correlation per pair of the within factor's levels, the same in every group | Superpower's default, no sphericity correction, unless `target_test > correction` asks for `"GG"` or `"HF"`. With one SD and one correlation sphericity holds and the corrections change nothing; with unequal ones they matter: for the interaction with SDs 6, 7, 8 and 6, 8, 10 and correlations 0.6, 0.4, 0.6 at n = 40, 26.7% uncorrected, 25.0% with Greenhouse-Geisser, 25.6% with Huynh-Feldt, and the MANOVA approach 26.2% (`test-backend-factorial-covariance.R`). Not a departure: the default follows Superpower and G\*Power's epsilon of 1. Equal groups only; `goal.n` is the total, a multiple of the number of groups. Exact power needs more people per group than cells, and at least 5 [powerkit, `engine/R/backend-superpower.R`] |

### Two-factor designs: both between (beyond 2 x 2) or both within

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | Both between: "ANOVA: Fixed effects, special, main effects and interactions", from f and the numerator df [GP-man, contents]. Both within: "ANOVA: Repeated measures, within factors", which takes one within factor; a second within factor has to be folded into it by hand. The manual has no section on repeated measures [GP-man, contents] | f (both between); f with the correlation among repeated measures and the nonsphericity correction epsilon (within) | To check (maintainer, in G*Power) |
| Superpower | `ANOVA_exact()` on the design `"kb*mb"` (both between, for example `"2b*3b"`) or `"kw*mw"` (both within, for example `"2w*3w"`), `ANOVA_power()` for simulation [SP-src]. For a between design `n` is per cell | Cell means, SD(s) and `r` | `correction` `"none"` by default [SP-src] |
| **powerkit** | As the mixed designs: `ANOVA_exact()` by default, `ANOVA_power()` on request [powerkit] | Cell means (one row per level of the first factor), **one** SD; for the within design one correlation between every pair of cells, or (from 1 November 2026) an SD per cell and a correlation per pair of cells, the upper triangle row by row as `ANOVA_design()` takes it | Both between: no correction is needed. Both within: Superpower's default, no sphericity correction, unless `target_test > correction` asks for `"GG"` or `"HF"` (not a departure; `test-backend-factorial-covariance.R`). Both between: 2 x 2 uses its own template (E7, which also takes an SD per cell); equal cells, `goal.n` is the total, a multiple of the number of cells. Both within: 2 x 2 and larger; the correlation must be above -1 / (cells - 1) for one correlation to fit every pair. Exact power needs more people per cell than cells, and at least 5 [powerkit, `engine/R/backend-superpower.R`, `engine/R/spec-checks.R`] |

### Planned comparisons (contrasts)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | No contrast screen of its own: a contrast is entered into "F test: Fixed effects ANOVA - special, main effects and interactions" as an effect size f with "Numerator df" 1 and "Number of groups" the number of levels [GP-man, 11.3.3, p. 29] | f = sigma_m / sigma, where sigma_m = \|C\| / sqrt(N * sum(c_i^2 / n_i)) for the contrast C = sum(c_i * mu_i); the manual tabulates sigma_m, f and eta-squared for three contrasts of one example [GP-man, 11.3.3] | Weights are entered only through f, so G\*Power never sees them. Validated against GPower 2.0 [GP-man, 11.6] |
| Superpower | `ANOVA_exact(emm = TRUE, contrast_type = )` and `emmeans_power()`: the contrast is computed by emmeans on one exact data set [SP-src] | emmeans contrast families (`"poly"` for trends, `"pairwise"`, ...), not arbitrary weights | Power is returned as a percentage. Agrees with pwrss and with the manual: for the manual's example its "poly" contrasts give 0.514737 (linear) and 0.0579695 (quadratic) [powerkit, `test-backend-formula-tests.R`] |
| pwrss | `power.t.contrasts()`: a t test of each row of a contrast matrix (t^2 = F with numerator df 1, so the same test G\*Power computes) | `mu.vector`, `sd.vector`, `n.vector` and `contrast.matrix` | `k.covariates` **defaults to 1**, which spends a denominator degree of freedom a plain one-way design doesn't have; `adjust.alpha` offers none (the default), Tukey, Bonferroni, Holm, Hochberg, Hommel, BH, BY and fdr. No one-sided option |
| **powerkit** | pwrss's `power.t.contrasts()` by formula, with `k.covariates = 0` and `r.squared = 0`; no simulation option yet (in the app since 26 October 2026, E19) [powerkit] | The means, the within-group SD and `target_test > weights`, one per level, adding up to 0. The weights' scale doesn't matter, which a unit test checks | **One contrast at a time**, `adjust.alpha = "none"` (pwrss's own default), equal groups, and two-sided only because pwrss's function has no one-sided option. Not a departure: the arguments are pwrss's defaults except `k.covariates`, which is 0 because the design has no covariates |

### Superpower and unequal group sizes (2 x 2 between and mixed)

Checked by running Superpower 0.2.4.1 under R 4.3.3 [SP-src], and again
with Superpower 0.2.4.1 under R 4.5.3 on 29 October 2026.

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
- **powerkit (from 29 October 2026, 0.23.0):** the 2 x 2 between design
  takes `options > cell_ratio`, the relative size of each cell; `goal.n` is
  split in that ratio and must give whole cells. Power is simulated with
  `ANOVA_power()` and one `n` per cell, which tests each effect with
  Superpower's Type III sums of squares (afex's default), as SPSS and
  jamovi do; the exact method and the smallest detectable effect are
  refused, because `ANOVA_exact()` takes equal cells only. The check run
  reads the means and SDs back from an equal-cell data set (the sizes
  don't change them), and the simulated data download keeps each cell's
  own size rather than `ANOVA_design()`'s largest one [powerkit,
  `engine/R/backend-superpower.R`, `engine/R/simulated-data.R`]. Equal cells
  are unchanged: one per-cell `n`, `ANOVA_exact()` by default.
- **powerkit, mixed designs (from 1 November 2026):** the 2 x 2 mixed and
  larger mixed designs take `options > group_ratio`, the relative size of
  each group (A's levels). Since no Superpower function takes unequal
  groups in a mixed design, power is simulated with Spower: each data set
  draws every group's scores at its own size from `ANOVA_design()`'s means
  and covariances (`SimDesign::rmvnorm()`), and is analysed with
  `afex::aov_car()`, Type III sums of squares, with the sphericity
  correction asked for (`p_mixed_anova()`). That is the analysis Superpower
  itself runs on simulated data, so at equal groups it agrees with
  `ANOVA_exact()`. The exact method and the smallest detectable effect are
  refused, as for unequal cells. Not a departure: G\*Power's
  repeated-measures analysis takes equal groups only [powerkit,
  `engine/R/backend-superpower.R`;
  `test-validation-anova-mixed-unequal.R`].
- **Validation (decision N3):** the independent reference is pwrss's
  `power.f.ancova.shieh()` with one covariate that explains nothing
  (`r.squared = 0`; pwrss requires at least one covariate), which differs
  from the ANOVA by one error degree of freedom. With means 20, 18, 30 and
  24, SD 8 and cells of 100, 100, 50 and 50, Superpower gave 53.6% for the
  interaction (2,000 simulations) and Shieh's formula 52.8%; balanced
  cells of 100 would give more, so the unequal sizes are used
  (`test-backend-anova-unequal.R`; at 10,000 replications in
  `test-validation-anova-unequal.R`).

### Rank correlations and the Pitman-Morgan test (from 29 October 2026, 0.22.0)

- **Spearman's rho and Kendall's tau** are simulated with Spower's
  `p_r(method = "spearman" / "kendall")`, which runs `cor.test()` on
  bivariate normal scores (Spower's `gen_r()`). The correlation entered is
  the Pearson correlation of those scores, not rho or tau themselves (for
  normal scores rho is slightly smaller than r). G\*Power has no rank
  correlation test; the only established alternative is an asymptotic
  approximation, which powerkit would have to write itself. From 31
  October 2026 the scores can be skewed or heavy-tailed too, as for the
  rank location tests: powerkit's generator (`shaped_pair_scores()`, passed
  to `p_r()` as `gen_fun`) draws the first score in the chosen shape and
  the second as r times the first plus sqrt(1 - r^2) times another draw of
  that shape, so Pearson's correlation is r; the second score's shape is
  close to the chosen one, not exactly it. Normal scores keep Spower's
  `gen_r()`. Spearman's rho with r = -0.2 and 60 people: 29.3% power on
  normal scores, 40.3% on heavy-tailed ones (300 replications).
- **Friedman's test** (from 31 October 2026), the rank-based one-way
  repeated-measures test, is simulated with Spower and powerkit's own
  experiment, `p_friedman()`, calling `stats::friedman.test()`. Each score
  is the condition's mean in SD units, the person's own level (normal,
  variance r) and a deviation in the chosen shape (variance 1 - r), so
  every score has SD 1, any two conditions correlate r, and the conditions
  differ only by a shift; r must therefore be at least 0. G\*Power has no
  Friedman test, and no package powerkit builds on has a power function
  for it (roadmap B26). With normal deviations the scores are exactly the
  multivariate normal the repeated-measures ANOVA assumes, which the
  validation file uses for an independent check
  (`test-validation-friedman.R`).
- **The Pitman-Morgan test** of two paired variances is simulated with
  Spower's `p_r()` on the sum and the difference (first minus second) of
  bivariate normal paired scores with the two variances and their
  correlation: cov(sum, difference) = var1 − var2, so the test of zero
  correlation is the test of equal variances. A one-sided test predicting
  "positive" says the first measurement's variance is the larger, as for
  the two-group variance test. G\*Power has no paired variance test.

### Welch's one-way ANOVA and the MANOVA approach (from 29 October 2026, 0.21.0)

- **Welch's F** (groups whose SDs differ) is a test version on the
  one-way ANOVA card, simulated with Spower's
  `p_anova.test(var.equal = FALSE)`, which runs `stats::oneway.test()` on
  groups drawn with each group's mean and SD. Since 8 November 2026 it is
  the card's default, recorded as Departure 22 (G\*Power and Superpower
  plan for the classical F test). Each group's SD is given in the
  outcome's own units, since there is no single SD to standardise by; with
  one SD for every group the means can also be in SD units.
- **The MANOVA approach** to a repeated-measures effect (Pillai's trace,
  no sphericity assumed) is reported beside the univariate F, from the
  same `Superpower::ANOVA_exact()` run (`manova_results`), when the
  target effect involves a within factor with three or more levels (with
  two, the two tests agree). The univariate F stays the headline, as in
  G\*Power's repeated-measures tests. The sample size is planned for the
  univariate F; the MANOVA power is at that n.

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

**A correlation and two proportions (from 29 October 2026, 0.21.0).**
TOSTER's `power_z_cor(alternative = "equivalence")` is the two one-sided
z tests of a correlation on Fisher's z scale (an approximation, as the
correlation test is), and `power_twoprop(alternative = "equivalence")`
the two one-sided z tests of p2 − p1, with `n` per group (TOSTER 0.8.6
help). powerkit passes the expected correlation (`rho`) or proportions and
the bound (`null`, which TOSTER takes as minus and plus), with alpha for
each one-sided test; two proportions are planned for equal groups,
because `power_twoprop()` takes one group size. The required n agrees
with TOSTER's own solution for n, rounded up (unit tests). Not a
departure: TOSTER's own calculation.

**Non-inferiority (from 29 October 2026, 0.22.0; t-tests corrected 11
November 2026).** G\*Power plans non-inferiority as a one-sided test
against the margin (the t tests with a shifted null). For the t-tests
powerkit does the same: the margin is a fixed amount in the outcome's own
units, the analysis is an ordinary one-sided t-test of the difference from
−margin (`t.test(mu = -margin)`), and its power is that of a one-sided
t-test of the expected effect plus the margin against 0. pwrss's
`power.t.student()` computes it, given `d = effect + margin` and
`margin = 0`. Until 11 November 2026 powerkit passed the margin through
pwrss's own `margin` argument, which holds the margin fixed in SD units
(a noncentral t under the null); that is a different test with slightly
higher power, and it returned sample sizes about two smaller than the
shifted test needs (one sample, margin 0.3, one-sided alpha .025, 80%
power: 88 rather than 90, which pwr's one-sided t-test and a simulation of
`t.test(mu = -0.3)` both confirm). Two proportions still use
`power.z.twoprops()` with `margin`, where the margin is a difference in
proportions and no such distinction arises. The effect is passed with
better as positive; powerkit refuses an expected effect at or beyond the
margin. Group 2 is the new condition. The usual one-sided alpha in
non-inferiority trials is 0.025; the example specs use 0.025. The
minimum-effect test versions of the t-test cards follow the same shifted
test from 12 November 2026 (Known difference 10, retired): a one-sided
test passes pwrss d = effect - margin on the tested side and margin = 0;
a two-sided test adds both tails at alpha / 2, the far tail (a
significant result beyond the margin on the wrong side) from pwr's
one-sided t-test, which pwrss's one-sided test cannot give.

**Group sizes given as a ratio (from 11 November 2026).** powerkit plans
whole groups in the ratio entered, so the total moves in steps (2 for
equal groups, 3 for 1 : 2). A ratio typed as a rounded decimal is exact
only in very large steps (0.67 is 67 : 100, a step of 167), which made the
sample size search overshoot (167 where about 133 are needed). When the
exact split needs a step above 50, powerkit plans the simplest
whole-number split that rounds to the ratio as entered (2 : 3 for 0.67,
1 : 3 for 0.33, 19 : 26 for 1.37) and says so on the result and in the
methods paragraph. G\*Power instead searches every total and rounds each
group; powerkit's answer can be a few people higher because the total
still moves in steps of the simplified split.

## Cluster-randomised trials (whole groups assigned to two conditions)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for clustered designs | — | — |
| powertools | `crt.parallel.cont()`: the variance of the difference between conditions is inflated by the design effect 1 + (m − 1) × ICC per condition (with covariates, a version adjusted for them), divided by a relative efficiency when group sizes vary (`re.clustsize.cont()`, an approximation the package warns can fail when sizes vary a lot); the test is a noncentral t (one-sided) or F with 1 and J − 2 − covariates degrees of freedom (two-sided), J being the total number of groups. Solves for power, groups in the first condition, the ratio of groups, group size, alpha or the difference (powertools 1.0.0, `R/crt.parallel.cont.R`, opened 27 October 2026) | `delta` / `sd`, with `sd` the outcome's total SD (between and within groups) | `m`, `m.sd`, `J1`, `J.ratio`, `icc1`, `icc2`, `ncov`, `RsqB`, `RsqW`, `alpha`, `sides` (2 by default) |
| **powerkit** | powertools' `crt.parallel.cont()`, by formula; no simulation option (E34, from 27 October 2026) [powerkit] | `d` over the outcome's total SD, as powertools defines it. A source that standardises by the within-group SD gives a larger d for the same difference | The same number of groups in each condition (`J.ratio = 1`), one ICC for both conditions; no covariates, or one baseline score (from 28 October 2026: `ncov = 1`, `RsqW` = `baseline_r2_within`, `RsqB` = `baseline_r2_between`, which powertools' formula applies to the within-group and between-group variance respectively, so they are the shares of each that the baseline explains; its help page calls them shares of the total variance, `upstream-questions.md`). The screen starts `baseline_r2_between` at the within-group value when left empty, and the write-up states both; `cluster_size_sd` for varying group sizes (0 if omitted). The total n is a whole number of groups. A one-sided test runs in the direction of d. Not a departure: powertools' own method and defaults, and no established psychology tool computes this design for comparison. The result also reports the design effect and the effective sample size (n / design effect), from the same formula powertools uses |

## Multisite trials (people randomised to two conditions within each group)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for clustered designs | — | — |
| powertools | `multisite.cont()`: the variance of the average difference between conditions is c × (1 − icc0 + (4m/c − 1) × icc1) / N, with c = (1 + r)² / r for allocation ratio r within each group, so 4 × (1 − icc0 + (m − 1) × icc1) / N for half in each; divided by a relative efficiency when group sizes vary (`re.clustsize.cont()` with icc1); the test is a noncentral t (one-sided) or F with 1 and J − 1 df (two-sided). `icc0` is the share of the total variance between the groups' means, `icc1` the share from the effect varying between groups (powertools 1.0.0 help and source, R/multisite.cont.R) | `delta / sd`, sd the outcome's total SD | `alloc.ratio = 1`, `m.sd = 0`, `Rsq = 0`, `alpha = 0.05`, `sides = 2` |
| **powerkit** | powertools' `multisite.cont()`, by formula; no simulation option (E34, from 27 October 2026) [powerkit] | `d` over the outcome's total SD, as for the cluster-randomised trial | Half of each group in each condition (`alloc.ratio = 1`); no covariates, or one baseline score (`Rsq` = `baseline_r2_within`, from 28 October 2026); `cluster_size` is the people in each group, both conditions together; `icc` is passed as `icc0` and `icc_effect` as `icc1`. The reported design effect is the factor above relative to an individually randomised trial of the same size (1 − icc0 + (m − 1) × icc1, over the relative efficiency): below 1 when the effect is the same in every group. No departure from powertools |

## Yes/no outcomes in clustered designs

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for clustered designs | — | — |
| powertools | `crt.parallel.bin()` and `multisite.bin()`: a z test of the log odds ratio between conditions, its variance from the binomial variance in each condition plus the between-group variance `sigma.u`² (for a cluster-randomised trial, the SD of the groups' random intercepts; for a multisite trial, the SD of the effect across groups), both on the log-odds scale, and multiplied by 1.2. The help pages do not give a source for the factor 1.2 (`upstream-questions.md`). Two-sided power is `pnorm(gamma / sqrt(var) - z)`, ignoring the far tail (powertools 1.0.0 help and source, R/crt.parallel.bin.R and R/multisite.bin.R, opened 28 October 2026) | `pc` and `pt`, the proportions in the two conditions | `m`, `m.sd` (cluster-randomised only), `J`, the total number of groups, `alloc.ratio` (multisite only), `sigma.u`, `alpha = 0.05`, `sides = 2` |
| **powerkit** | powertools' `crt.parallel.bin()` and `multisite.bin()`, by formula; no simulation option (E34, from 28 October 2026) [powerkit] | `p1` and `p2`, the proportion of "yes" in each condition, and `sigma_u` on the log-odds scale; there is no ICC for this outcome | The same number of groups in each condition, or half of each group in each condition (`alloc.ratio = 1`). Groups of the same size only: `cluster_size_sd` is refused, because the relative-efficiency adjustment for varying sizes (`re.clustsize.bin()`) appears to contain a typo (`upstream-questions.md`). No smallest detectable effect, since the functions cannot solve for the proportions. The exported script prints powertools' `crt.varexplore()` or `ms.varexplore()` table, to help judge `sigma_u`. Not a departure: powertools' own method, including its factor 1.2, and no established psychology tool computes this design for comparison. The factor's size is Known difference 16 |

## Group treatment trials (only one condition delivered in groups)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for clustered designs | — | — |
| powertools | `irgtt.cont()`: people are randomised individually, and those in the intervention condition are treated in J groups of m. The variance of the difference is Theta × sd² × (1 + (m − 1) × ICC) / (mJ) + sd² / n, n being the control condition's size; power by the noncentral t (one-sided) or F with 1 df (two-sided) on Satterthwaite degrees of freedom. Other quantities (J, m, n, delta, alpha) are "solved for using normal approximation" (its help page), that is, with 10,000 df. `irgtt.bin()`: the z test of the difference in proportions, the intervention condition's binomial variance multiplied by the same design effect (powertools 1.0.0 help and source, R/irgtt.cont.R and R/irgtt.bin.R, opened 28 October 2026) | `delta / sd`, with `sd` the outcome's total SD; or `p1` (control) and `p2` (intervention) | `icc = 0`, `Theta = 1`, `alpha = 0.05`, `sides = 2` |
| **powerkit** | powertools' `irgtt.cont()` and `irgtt.bin()`, by formula (E34, from 28 October 2026) [powerkit] | `d` over the outcome's total SD, taken to be the same in both conditions (`Theta = 1`); or `p1` and `p2`. The ICC is the grouped condition's | The same number of people in each condition (`n = mJ`); condition 2 is the grouped one. The sample size is found from the t-based power, as for every design, so it is a whole number of groups. **The smallest detectable d is also found from that power** (by root-finding), not from `irgtt.cont()`'s own solver for delta (Departure 14): at 20 groups of 8 and 160 people treated individually (ICC 0.05), powertools' normal approximation gives d = 0.340, which has 77.1% power by its own power formula; powerkit gives d = 0.352, with 80% (`test-backend-powertools.R`). With an ICC of 0, the Satterthwaite df still count the groups, so power is a little below an ordinary t test of the same size (0.935 against 0.946 at d = 0.4 and 160 per condition). No smallest detectable effect for a yes/no outcome, since `irgtt.bin()` can't solve for the proportions |

## Structural equation model fit (the chi-square test of exact fit, by RMSEA)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for structural equation models | — | — |
| semPower | `semPower.postHoc()` and `semPower.aPriori()` with `effect.measure = "RMSEA"`: F0 = RMSEA² × df (`getF.RMSEA()`), noncentrality (N − 1) × F0 (`getNCP()`), and power is the chance that the noncentral chi-square on the model's df exceeds the central chi-square's critical value at alpha, so the null hypothesis is exact fit (RMSEA = 0). No test of close fit. `semPower.getDf()` counts a model's df by fitting its lavaan syntax (semPower 2.2.0, `R/postHoc.R`, `R/aPriori.R`, `R/effectSizes.R`, help for `semPower.getDf()`, opened 27 October 2026) | RMSEA of the population misfit | `alpha` must be given (no default); `fittingFunction = "ML"` |
| **powerkit** | semPower's `semPower.postHoc()` by formula; no simulation option (E37, from 27 October 2026) [powerkit] | `rmsea` | The model is given by its df, or, for a CFA, by its number of items and factors, each item on one factor and the factors correlated; the df are then counted by `semPower.getDf()` with the items split as evenly as possible (the split does not change the df). The required N is powerkit's own search over whole N with semPower's power, which agrees with `semPower.aPriori()`'s `requiredN` (unit tests). Not a departure: semPower's own method and defaults, and no established psychology tool computes this for comparison. Alpha 0.05 is offered as the usual level because semPower has none |

## Structural equation model fit: the tests of close and not-close fit

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for structural equation models | — | — |
| semPower | Exact fit only (above) | — | — |
| WebPower | `wp.sem.rmsea()`: MacCallum, Browne and Sugawara's (1996) tests (the reference in its help). Close fit (`type = "close"`): the critical value from the noncentral chi-square with noncentrality (N − 1) × df × rmsea0², power from the noncentral chi-square at rmsea1; not-close fit (`type = "notclose"`): the lower critical value at rmsea0, power the chance of falling below it at rmsea1 (WebPower 0.9.4 source, read 2 November 2026) | `rmsea0` (the null value) and `rmsea1` (the population RMSEA) | `alpha` 0.05; no default for `rmsea0` |
| **powerkit** | WebPower's `wp.sem.rmsea()` by formula (E37, from 2 November 2026), with the df counted as for the test of exact fit [powerkit] | `rmsea` (the population RMSEA) and `rmsea_null` | `rmsea_null` 0.05 by default, the null value commonly used with these tests (for example in semTools' `findRMSEApower()` help). No test is preselected (from 13 November 2026): the screen asks what the test should do, listing not-close fit first as the route for showing that a model fits well enough, because power for exact or close fit is the chance of rejecting the model. The engine's spec default is still exact fit. At `rmsea_null` 0 the test of close fit is semPower's test of exact fit (tested to 1e-8, and in the check run). Not a departure |

## Measurement invariance, factor correlations and latent slopes (the chi-square difference test)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for structural equation models | — | — |
| semPower | `semPower.powerMI()`, `semPower.powerCFA()` and `semPower.powerRegression()` build the population covariance matrix (and means, for scalar invariance) from loadings, factor correlations, slopes and intercepts, fit the model with and without the restriction to it with lavaan (ML), and take the minimum of the fit function (F0; one per group for invariance) as the effect. Power is `semPower.postHoc()` on F0 with the restriction's df (`comparison = "restricted"`, or for invariance the previous level: configural for metric, metric for scalar): the chance that the noncentral chi-square exceeds the central critical value. Factors are standardised; for invariance the factor variance (and mean) is fixed in the first group only (`singleGroupIdent = TRUE`), as lavaan does. Item residual variances default to whatever makes each item's variance 1 (semPower 2.2.0 help for the three functions and `semPower.genSigma()`, opened 29 October 2026) | Loadings and the parameter restricted: the second group's loadings or intercepts, the factor correlation, the slope | `alpha` must be given; `comparison = "restricted"`; `singleGroupIdent = TRUE`; `nullWhich = 1` (the first slope) |
| **powerkit** | semPower's own functions, by formula; no simulation option (E37, from 29 October 2026); over two occasions, `semPower.powerLI()` with the factor's correlation between occasions as `Phi` and semPower's default autocorrelated residuals (0.22.0) [powerkit] | Invariance: the loading of the items that differ in group 2, or their intercept shift in item SDs. Factor correlation: `r`. Latent regression: the tested slope | One factor and two groups for invariance, with the items that differ at the end of the list (their position doesn't change the misfit); the same loading for every item of a factor; for a latent regression, the same number of items and loading for every factor and one correlation for every pair of predictors. powerkit calls each function once and finds power at other n through `semPower.postHoc()` with the same F0 and df, which is what the function computes at that n (unit tests, to 1e-8), so the sample size search doesn't refit the models at each step; the required N agrees with each function's own a-priori `requiredN` (unit tests). Not a departure: semPower's own method and defaults. The latent paths design uses `semPower.powerRegression()`, semPower's convenience function for one latent outcome on several latent predictors, rather than `semPower.powerPath()`, which takes a full matrix of paths |

## Mediation (PROCESS 4, 6) and moderated mediation (PROCESS 7, 14)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G*Power | Not covered: to check | | |
| Superpower | Not covered [SP-src] | | |
| pwrss | `power.z.mediation()` (pwrss 1.3.3): z tests of the indirect effect from the paths' large-sample standard errors, `method` "sobel" (the default), "aroian", "goodman", "joint" (both paths significant: the product of the two z-test powers) or "monte.carlo" (a Monte Carlo interval from the paths' sampling distributions, simulated); sample size by formula for Sobel, Aroian and Goodman only. powerkit uses "joint" for simple mediation's quick estimate (from 12 November 2026; `backend-mediation-joint.R`) [powerkit] | Unstandardised paths with the SDs of X, M and Y (all 1 for standardised paths), and R-squared of M and Y; with them left out, pwrss's R-squared of Y is b^2 + c'^2, without the 2 a b c' term (powerkit passes both) | `alpha` .05, two-sided |
| InteractionPoweR | Not covered: to check | | |
| power4mome | `power4test()` with `test_indirect_effect()` or `test_index_of_mome()`: Monte Carlo (default) or nonparametric bootstrap CI, significant if the CI excludes 0; the model is fitted with lavaan (ML) by default [p4m-src] | Standardised coefficients (`pop_es`, "lhs ~ rhs: value", or "s"/"m"/"l" labels). Observed variables have variance 1, and a product of two standardised variables has variance 1 + r^2. Between two endogenous variables, `~~` sets their **residual covariance** [p4m-src, checked by simulation] | `R` (draws per CI): no default in `power4test()` (no CI without it); 1,000 in `q_power_mediation()`; 100 in `gen_mc()` / `gen_boot()`. Boos and Zhang's method switches on automatically for R in 39, 79, ..., 359 (Departure 8). A residual covariance not written in the model is fixed at 0 (lavaan) [p4m-src] |
| Spower | to check (the build guide says Spower covers mediation) | to check | to check |
| **powerkit** | power4mome's `power4test()` with its test functions, CI level 1 - alpha, CI rule (`test_method = "ci"`); lavaan ML fit (Departure 6) [powerkit] | Standardised paths keyed `From->To`; residual **correlations** for parallel mediators (converted to power4mome's covariance) [powerkit] | `options > ci_draws`, default power4mome's 1,000 (`q_power_mediation()`); parallel mediators' residuals always free to correlate, as in PROCESS (Departure 7); Boos and Zhang off (Departure 8). Binary X or W and measurement error: not available yet |

## Participants and items in two conditions (crossed random effects, E33)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for crossed random effects | — | — |
| simr | `powerSim()` simulates data sets from a model built with `makeLmer()` (fixed effects, `VarCorr`, `sigma`) and refits each with lme4; `fixed(xname, method)` tests one fixed effect [simr help] | The model's own parameters, in the outcome's units | `fixed()`'s default `method = "z"` treats the t statistic as normal (its help calls it an asymptotic approximation for models not fitted with `glmer`); `"sa"` is lmerTest's Satterthwaite t test, `"kr"` Kenward-Roger. A data set whose fit or test fails counts as not significant |
| **powerkit** | simr's `powerSim()` with `fixed("cond", "sa")` (E33, from 30 October 2026) [powerkit] | The difference between conditions and the SDs of participants' intercepts and condition slopes (with their correlation), items' intercepts (and slopes, with items in both conditions) and the residual, in the outcome's units; the condition coded -0.5 and 0.5 | `y ~ cond + (1 + cond \| participant) + (1 \| item)`, every participant responding to every item; items in one condition each (half per condition) or in both. With the conditions between participants (X a between factor, from 31 October 2026), `y ~ cond + (1 \| participant) + (1 \| item)` (or `(1 + cond \| item)` with items in both conditions), half the participants in each condition, each responding to every item or to their condition's half. `goal.n` is the number of participants, the number of items fixed. The Satterthwaite test is Departure 16 |

With a yes/no outcome on each trial (E33, from 1 November 2026) the model
is a logistic mixed model (simr's `makeGlmer()`, lme4's `glmer()`), each
condition's probability that of a typical participant and item and every
SD on the log-odds scale. The default test is glmer's Wald z test, simr's
default for a numeric predictor; the likelihood-ratio test is offered.
With powerkit's yes/no example (70% and 80% correct, 40 items, 30
participants; 1,000 simulated data sets) they give 67.8% and 65.9%.

## Participants and items: a predictor measured on each item (E67)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for crossed random effects | — | — |
| simr | `powerSim()` on a model built with `makeLmer()` or `makeGlmer()`; `fixed(xname, method)`, `method = "z"` by default [simr help] | The model's own parameters | — |
| **powerkit** | simr's `powerSim()` with `fixed("x", "sa")` for a score, or `fixed("x", "z")` (default) or `"lr"` for a yes/no outcome (E67, from 1 November 2026) [powerkit] | The effect per SD of the item score, the SDs of participants' intercepts and slopes and of items beyond the score, and the residual SD, in the outcome's units (log odds for yes/no) | `y ~ x + (1 + x \| participant) + (1 \| item)`, x evenly spread across the items (normal quantiles, centred, SD 1), every participant responding to every item. The Satterthwaite test is Departure 16 |

With the predictor measured on each trial (from 1 November 2026) each
participant meets every value once, rotated across the items, and the
model gains the items' slopes on X: `y ~ x + (1 + x | participant) + (1 +
x | item)`, tested as for an item predictor.

## Three levels: people in groups in larger groups (E68)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for three-level designs | — | — |
| simr | `powerSim()` on a model built with `makeLmer()`; `fixed(xname, method)`, `method = "z"` by default [simr help] | The model's own parameters | — |
| **powerkit** | simr's `powerSim()` with `fixed("cond", "sa")` (E68, from 1 November 2026) [powerkit] | Cohen's d over the outcome's total SD, with the sites' and groups' shares of the variance (intraclass correlations) and the effect's variation across sites or groups as shares of it | `y ~ cond + (1 \| site) + (1 \| site:group)`, with `(1 + cond \| site)` when the condition is assigned below the sites and its effect varies, and `(1 + cond \| site:group)` when it is assigned to people; cond coded -0.5 and 0.5; equal group and site sizes; the first half of what is assigned in the first condition. The Satterthwaite test is Departure 16; with few sites and a small varying effect it can be conservative (3.1% at alpha .05 with classes assigned in 8 schools, 3.65% in an independent simulation) |

With a yes/no outcome (E68, from 1 November 2026) the model is a logistic
mixed model (simr's `makeGlmer()`, lme4's `glmer()`): each condition's
chance of 'yes' for a typical site and group, and the SDs of the sites'
and groups' intercepts (and of the effect, where it can vary) on the
log-odds scale in place of the shares of variance. The test is glmer's
Wald z test, simr's default for a two-condition predictor, or the
likelihood ratio; not a departure.

## The same people measured more than once: counts, yes/no and ordered categories (E75)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for generalised mixed models | — | — |
| simr | `powerSim()` on a model built with `makeGlmer()` (any glmer family); `fixed(xname, method)`, `"lr"` by default for a factor, `"chisq"` its Wald chi-square through car [simr help] | The model's own parameters | — |
| ordinal | `clmm()`: a cumulative link mixed model, logit link and flexible thresholds by default, `logit P(Y <= j) = theta_j - X beta - u` [ordinal help] | The model's own parameters: thresholds and log odds ratios | — |
| **powerkit** | Poisson and yes/no: simr's `powerSim()` on `makeGlmer()` with `fixed("cond", "lr")` (default) or `fixed("cond", "chisq")`. Negative binomial: Spower running `p_repeated_nb()`, lme4's `glmer.nb()` (theta estimated), with the same two tests. Ordered categories: Spower running `p_repeated_ordinal()`, ordinal's `clmm()` with the logit link, the likelihood-ratio test or the Wald chi-square test of cond's coefficients (E75, from 14 November 2026) [powerkit] | Each condition's expected count (or chance of 'yes') for a typical person, the SD of the person intercepts on the log (log-odds) scale, and for a negative binomial count the overdispersion k (variance mu + k mu^2; lme4's theta is 1 / k). For ordered categories, a typical person's share of answers in each category in the first condition (setting the thresholds) and each condition's odds ratio of a higher category (proportional odds) | `y ~ cond + (1 \| person)`, cond a factor in treatment coding; every person in every condition, or the people split equally between the conditions; `measurements` per person in each condition. A data set whose fit fails counts as not significant, as simr counts it |

simr cannot build or refit a negative binomial mixed model (its families
are glmer's), so the negative binomial version draws each person's
intercept and then each count with `stats::rnbinom()` and fits
`glmer.nb()` in a Spower simulation. With two conditions the Wald
chi-square test has the same p-value as glmer's Wald z test. The
likelihood-ratio test is the default, as on the many-conditions card for
yes/no trials (E63), for the reason lme4's help on p-values gives; not a
departure, since G\*Power has no such test.

Ordered categories are planned on the scale `clmm()` reports: an odds
ratio above 1 means higher categories (ordinal's sign convention, the
coefficient entering as `theta_j - X beta`), the same direction as the
proportional-odds card for two groups (E29). Each simulated answer is
drawn from the cumulative logits given the person's intercept; a data set
with every answer in one category, or whose fit fails, counts as not
significant.

## Moderated mediation with W on both links or the direct path (E38)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No mediation | — | — |
| power4mome | `power4test()` on any lavaan model; no ready-made test of the difference between conditional indirect effects [power4mome help] | Standardised paths | Fits with lavaan; adds covariances among the exogenous variables and products |
| **powerkit** | power4mome's `power4test()` with powerkit's `test_cond_indirect_diff()`, manymome's `cond_indirect_diff()`: the indirect effect at W = w_values[2] minus that at w_values[1], tested by its Monte Carlo confidence interval (E38, from 1 November 2026) [powerkit] | Standardised paths, the interactions XW -> M, MW -> Y and XW -> Y as the model has them | One mediator; W standardised, so its values are SDs from its mean (-1 and 1 by default). For models 58 and 59 the fitted model leaves out power4mome's residual covariance of M with W (not estimable when W predicts M). Departures 6 (lavaan, not OLS) and 8 (the CI rule) apply as for models 7 and 14 |

## Moderated mediation with a yes/no X or W (E17)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| PROCESS | The index of moderated mediation with a 0/1 variable as it is coded | Unstandardised coefficients | — |
| power4mome | `x_fun` with `rbinary_rs()`: a yes/no variable rescaled to mean 0 and SD 1 [power4mome help] | Standardised paths | — |
| **powerkit** | power4mome with `rbinary_rs()` for X, W or both (E17, from 1 November 2026); with a yes/no W, the difference between the two groups' conditional indirect effects, the index times the distance between W's two rescaled values (manymome treats a two-valued W as categorical) [powerkit] | Standardised paths, per SD of a yes/no variable | A yes/no X or W uncorrelated with the other predictor. Departures 6 and 8 apply as for models 7 and 14 |

## Meta-analysis with several effects per study (E61, POMADE)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No meta-analysis | — | — |
| POMADE | `power_MADE()`: the test of the average effect under a working model, with `model = "CHE"` and `var_df = "RVE"` by default [POMADE help] | The average effect, with tau, omega and rho | Study sizes and numbers of effects may be drawn from distributions; balanced by default when given single values |
| **powerkit** | POMADE's `power_MADE()` with its defaults, the CHE model and the RVE test (E61, from 1 November 2026) [powerkit] | Cohen's d or r (on Fisher's z), tau, omega and rho on the same scale | Every study the same size with the same number of effects; each effect's sampling variance a typical study's, as metapower computes it (`4/n + d^2/(2n)`, or `1/(n - 3)` for r). Not a departure |

## Meta-analysis: a score moderator and the test of heterogeneity (E61)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No meta-analysis | — | — |
| metapower | `mod_power()` for a categorical moderator only; `homogen_power()` for heterogeneity, which disagrees with simulation (`upstream-questions.md`) [metapower help] | d or r, I-squared | — |
| **powerkit** | A score moderator: metafor's `rma(mods = ~ x)` simulated with Spower, the Hartung-Knapp test by default (Departure 18) or z. Heterogeneity: Cochran's Q from metafor's fixed-effect `rma()`, simulated with Spower (E61, from 1 November 2026) [powerkit] | d or r (Fisher's z), the slope per SD of the moderator, I-squared | The moderator standardised across the studies (normal quantiles, a fixed design); every study the same size, its sampling variance as metapower computes it |

## Dyadic data: actor and partner effects (E44)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for dyadic data | — | — |
| apimpower | A web app for APIM power; not callable from R, not compared | — | — |
| **powerkit** | power4mome's `power4test()` on the APIM, fitted with lavaan (maximum likelihood), the effect tested by `test_parameters()`, lavaan's Wald z test (E44, from 1 November 2026) [powerkit] | Standardised actor and partner paths, the correlation of the members' X and the residual correlation of their Y | Y1 ~ X1 + X2 and Y2 ~ X2 + X1, X1 ~~ X2, Y1 ~~ Y2; with indistinguishable members the actor paths are constrained equal, and so are the partner paths. Several effects can be tested together (joint power: every one significant in the same simulated study). Optionally (5 November 2026) a pair-level moderator W predicts each Y and moderates each actor effect (X1 x W on Y1, X2 x W on Y2), constrained equal across members when they are indistinguishable; each Y's residual variance comes from the products' moments (the two products correlate r_x + r_xw^2) and is supplied with power4mome's standardisation off, as for PROCESS models 58 and 59. With few pairs lavaan's Wald z test of the moderation is liberal (7.2% at alpha .05 with 60 pairs, 5.1% with 200; `test-validation-apim-moderation.R`). `goal.n` is the number of pairs. Not a departure: no established tool computes this design for comparison |

## Bayes factor test of one proportion (E25)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No Bayes factor tests | — | — |
| JASP (Bayesian binomial test; analysis only, no planning) | Two-sided: p = p0 against p != p0, a Beta(a, b) prior; one-sided: p = p0 against p > p0 (or < p0), the prior truncated to that side | — | Beta(1, 1) by default |
| bfpwr | `binbf01()`, `pbinbf01()`: the two-sided test (`type = "point"`, the same Bayes factor as JASP's) and a directional test (`type = "direction"`: p <= p0 against p > p0) | A fixed proportion, or a truncated beta design prior (by default the analysis prior) | Beta(1, 1) by default; power summed over the outcomes 0 to n |
| **powerkit** | Two-sided and the directional test from bfpwr's `pbinbf01()`; the one-sided test against a point null, JASP's, from bfpwr's two-sided Bayes factor times the ratio of the posterior to the prior probability of that side, summed over the outcomes 0 to n (E25, from 1 November 2026) [powerkit] | The expected proportion, exactly, or a beta design prior with its mean and an SD (`population > p_sd`) | Beta(1, 1) by default; one-sided: JASP's test by default (`target_test > one_sided_null` "point"), bfpwr's as "directional". Not a departure from JASP, which has no planning; Departure 15 is the design prior's default |

## Bayes factor test of a correlation (E4)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No Bayes factor tests | — | — |
| JASP (Bayesian correlation; analysis only, no planning) | Pearson's rho = 0 against rho != 0 (or one side, the prior truncated to it), a stretched beta prior on rho; exact Bayes factor (jaspRegression's bstats, Ly, Marsman and Wagenmakers, 2018) | — | Prior width 1 (uniform) by default |
| BayesFactor | `correlationBF()`: the same Bayes factor; one-sided by `nullInterval` | — | `rscale` "medium" (1/3) by default |
| **powerkit** | BayesFactor's `correlationBF()`, which rises with r (or |r|), so strong evidence is exactly a sample correlation past a critical value, found by root-finding; its chance from the exact distribution of r for bivariate normal scores (SuppDists' `pPearson()`), with no simulation (E4, from 1 November 2026) [powerkit] | The expected correlation, exactly, or a stretched beta design prior with its mean and an SD (`population > r_sd`) | Prior width 1 by default, JASP's (Known difference 12); Departure 15 is the design prior's default. The one-sided Bayes factor comes from `correlationBF()`'s interval method, within 0.1% of the exact value JASP computes (tested) |

## Bayes factor test of two proportions (E5)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No Bayes factor tests | — | — |
| JASP (Bayesian contingency tables; analysis only, no planning) | Independence in a 2 x 2 table, by BayesFactor's `contingencyTableBF()`; one-sided ("Group one > Group two"): BF10 times the posterior probability of that direction, estimated from 10,000 posterior draws, over 0.5 | — | "Indep. multinomial, rows fixed" and prior concentration 1 by default |
| BayesFactor | `contingencyTableBF()`: Gunel and Dickey's Bayes factors for four sampling plans | — | `priorConcentration` 1; the sampling plan has no default |
| **powerkit** | `contingencyTableBF()` with JASP's sampling plan (independent multinomial, group sizes fixed), in its closed form for a 2 x 2 table so that every possible table can be scored (equal to `contingencyTableBF()` to ten digits, tested and in the check run); power summed exactly over the tables; one-sided by JASP's rule with the posterior probability calculated exactly (E5, from 1 November 2026) [powerkit] | Each group's expected proportion, exactly, or a beta design prior on each with its mean and an SD (`population > p_sd`) | Prior concentration 1 by default, JASP's and BayesFactor's; Departure 15 is the design prior's default; Known difference 13 for the one-sided test. "greater" means group 2's proportion is the higher, as for the z test |

## Bayes factor test of a contingency table (E6)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No Bayes factor tests | — | — |
| JASP (Bayesian contingency tables; analysis only, no planning) | Independence in an r x c table, by BayesFactor's `contingencyTableBF()` | — | "Indep. multinomial, rows fixed" and prior concentration 1 by default; Poisson, joint multinomial and columns fixed offered for any table, hypergeometric for 2 x 2 only |
| BayesFactor | `contingencyTableBF()`: Gunel and Dickey's Bayes factors for four sampling plans | — | `priorConcentration` 1; the sampling plan has no default |
| **powerkit** | `contingencyTableBF()` with the sampling plan chosen, JASP's by default; each simulated study's table drawn from the cell probabilities with the total n (multinomial), simulated with Spower (E6, from 2 November 2026) [powerkit] | The proportion in each cell | Rows fixed and prior concentration 1 by default, JASP's; the hypergeometric plan not offered. The no-association side simulated with the same number of studies. Not a departure |

## Bayes factor one-way ANOVA (E18)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No Bayes factor tests | — | — |
| JASP (Bayesian ANOVA; analysis only, no planning) | BayesFactor's `anovaBF()`: the model with the factor against the null model; a Cauchy prior on the standardised group effects (Rouder, Morey, Speckman and Province, 2012, the reference in `anovaBF()`'s help) | — | "r scale fixed effects" 0.5 by default (jaspAnova, `inst/qml/common/bayesian/AdditionalOptions.qml`) |
| BayesFactor | `anovaBF()` on the data; `oneWayAOV.Fstat()` from the F statistic of a balanced one-way design, the same Bayes factor | — | `rscaleFixed` "medium", 1/2, by default [BayesFactor help] |
| **powerkit** | BayesFactor's `oneWayAOV.Fstat()`, which rises with F, so strong evidence is exactly an F past a critical value, found by root-finding; its chance from the noncentral F (k - 1 and n - k df, noncentrality f^2 n, as for the F test), with no simulation (E18, from 2 November 2026) [powerkit] | The group means and one SD (Cohen's f) | r scale 0.5 by default, JASP's and BayesFactor's; equal groups. `oneWayAOV.Fstat()` equals `anovaBF()` on the data (tested, and in every run's check run). Not a departure |

## Sequential Bayes factor designs (Labs)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No Bayes factor tests | — | — |
| BFDA (Schönbrodt and Wagenmakers, 2018; on GitHub only, not compared) | Monte Carlo simulation of the Sequential Bayes Factor design, the JZS t-test Bayes factor at every look | d, fixed or drawn from a design prior | A first look at `n_min`, then after every participant (or every few), thresholds for H1 and H0, an optional maximum N |
| **powerkit** | `bayes_sequential()`: the same procedure, simulated by powerkit with bfpwr's `tbf01()` (the JZS Bayes factor, a Cauchy analysis prior) at every look (Labs, from 1 November 2026) [powerkit] | d (d_z for pairs), the true effect drawn from a normal design prior for every simulated study, and again with no effect | `n_min`, `step`, `n_max`, a BF10 threshold for an effect and a BF01 threshold for no effect (may differ), one- or two-sided; 2,000 simulated studies under each (seed 1) in the app. Each look's thresholds are found as values of t, which gives the same decisions as computing the Bayes factor every time (tested). Not a departure: it follows the published procedure, whose examples it reproduces to within about a percentage point |

## Replication planner (Labs)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No replication planning; a replication is planned as an ordinary test with the original's effect | — | — |
| BayesRepDesign (Pawel, Consonni & Held, 2026) | `ssdSig()`, `ssdMeta()`, `ssdEqu()`, `ssdTOST()`, `ssdBFr()`, `ssdBFs()` and their `pors*()` chances, on the normal-normal hierarchical model: the effect estimate is normal with a known standard error | The original estimate and its standard error; a design prior (`designPrior()`, conditional, predictive or empirical Bayes) with a heterogeneity SD `tau` | Levels as the user passes them; `se2n(se, unitSD = 2)` turns a standard error into a total sample size for a standardised mean difference |
| **powerkit** | `replication_planning()` (Labs, from 8 November 2026): every goal judged against the original's effect is BayesRepDesign's, under all three design priors; small telescopes is the card's own pwr and pwrss calculation (above), so the two agree [powerkit] | d (two groups, one sample), d_z (pairs) or r (on Fisher's z); the original's standard error from the paper's equation 9 for two groups, 1/sqrt(n) for one sample or pairs, 1/sqrt(n - 3) for r | The paper's worked levels: the two-trials rule at one-sided alpha/2, the pooled estimate at (alpha/2)^2, agreement by a (1 - 2 alpha) interval for the difference, Bayes factors at 1/threshold (10 by default), and TOST at alpha (BayesRepDesign's `level` set to 2 alpha, because `porsTOST()` uses `qnorm(1 - level/2)`; `upstream-questions.md`). `tau` applies to the uncertain and shrunk priors only: the conditional prior is a point mass. Two equal groups in the replication |

**The normal approximation against the t-test cards.** With the "as
reported" prior and no heterogeneity, the significance goal is a classical
power analysis, but by the normal approximation, where the t-test cards use
the t distribution. For an original d = 0.7, BayesRepDesign gives 66 in
total (33 per group) and a t-test power analysis (pwr) 68: the planner asks
for slightly fewer people at small samples, and the difference shrinks as
the sample grows. This follows the method's published form rather than
mixing two models in one table; it is stated on the result and in the
methods paragraph ("the normal-normal hierarchical model"), and
`engine/tests/testthat/test-replication-planning.R` ("as reported, the
significance goal is a power analysis by the normal approximation") shows
its size. An independent simulation of Student's t-tests, with true effects
drawn from the uncertain prior, agrees with the planner's chance to within
3 percentage points at 60 per group (same file).

## Effects that vary between studies (t-test cards)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No allowance for heterogeneity: the true effect is the same in every study | — | — |
| Kenny and Judd (2019) | Their formula for a t-test when each study's true effect is drawn from a normal distribution with mean mu and SD tau: q = se0 / sqrt(se0^2 + tau^2), critical t = q t_crit (the "effective alpha"), noncentrality mu / sqrt(se0^2 + tau^2), with the usual df; their appendix gives it as an R function, and they note a conventional power program gives the same answer when given the effective alpha and the adjusted effect | d (the average effect) and tau, both in d | Representative tau 0.05, 0.125 and 0.20 (small, medium, large); they argue zero should not be the default |
| **powerkit** | pwr's own t-test power (`pwr.t.test()`, `pwr.t2n.test()`) given Kenny and Judd's effective alpha as `sig.level` and q times the average effect as `d`, which gives their noncentrality (E1, E2 and E3, from 8 November 2026) [powerkit] | d (d_z for pairs), the average across studies, and tau, optional | se0 = sqrt(1/n1 + 1/n2) for two groups of any sizes, sqrt(1/n) for one sample or pairs (the two-equal-groups case is theirs; the others follow the same rule). Student's t-test, or Welch's with equal SDs, by formula only; not with small telescopes. Empty or 0 is the usual analysis, unchanged |

**Size and checks.** Kenny and Judd's worked example (mu 0.3, tau 0.2, 50
per group) gives power .375 against .318 with no heterogeneity, and an
effective alpha of about .16; powerkit reproduces both, and their appendix
function. For 80% power at d = 0.3, two equal groups, the total sample size
is 352 with no variation, 376 with tau 0.05, 522 with 0.125 and 830 with
0.20. Below a power of one half, variation raises power rather than
lowering it, as Kenny and Judd show. An independent simulation that draws
every study's true effect agrees within 2.5 percentage points for all three
designs, and with the effective alpha (`engine/tests/testthat/test-heterogeneity.R`).
Welch's test with equal SDs is planned by the same formula: on the
two-group card its power with equal SDs is Student's (0.318 for both in
the example, pwrss), so this is not a departure. With tau = 0 the answer
is the card's usual one. The cards start at tau = 0.05, which is
Departure 23.

## Correlations that vary between studies (correlation card)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No allowance for heterogeneity: the true correlation is the same in every study | — | — |
| McShane and Böckenholt (2014) | Appendix B: the estimate is normal with its usual sampling variance plus the between-study variance tau^2, while the test's critical region is the usual one; for a correlation, on Fisher's z, sampling variance 1 / (n - 3) | r (the average correlation) and tau, on Fisher's z | Heterogeneity set relative to the within-study variance (Pigott's small, medium, large) |
| **powerkit** | pwr's `pwr.r.test()` (Fisher's z approximation) given the significance level and correlation that scale both its critical z and its z for r by q = se0 / sqrt(se0^2 + tau^2), se0 = 1 / sqrt(n - 3): the analogue of Kenny and Judd's effective alpha and adjusted effect, which gives the normal model's power exactly (E4, from 8 November 2026) [powerkit] | r, the average across studies, and tau on Fisher's z, optional | Pearson's test by formula only; not for rank correlations or the Bayes factor test. Small, medium and large tau are 0.025, 0.075 and 0.125, Kenny and Judd's 25% of r = .1, .3 and .5. Empty or 0 is the usual analysis, unchanged |

**Size and checks.** With tau = 0 the answer is `pwr.r.test()`'s. With
tau > 0 it equals the normal model on Fisher's z written out directly, to
1e-8, for three cases, and an independent simulation that draws each
study's true correlation (Fisher's z normal around atanh(r) with SD tau)
and runs `cor.test()` agrees within 2.5 percentage points (r = .3, tau
0.1, n = 100: .784 against .781), and with the effective alpha at r = 0.
The card starts at tau = 0.025, which is Departure 24.

**The range on the results screen** (t-test and correlation cards). The
result also gives the goal's answer (power, the people needed or the
smallest detectable average effect) with no, small, medium and large
variation and with the value entered, so the starting value is a visible
assumption. For d = 0.3, two equal groups and 80% power: 352, 376, 522
and 830 people.

## Participants and items in three or more conditions (E63)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for crossed random effects | — | — |
| simr | `powerSim()` on a model built with `makeLmer()`; for a factor, `fixed(xname)` tests by a likelihood ratio by default [simr help] | The model's own parameters | — |
| **powerkit** | simr's `powerSim()` with lmerTest's Satterthwaite F test of cond (`anova(ddf = "Satterthwaite")`), or one pair's Satterthwaite t test (`contest()`) adjusted for all the pairs by `p.adjust()`, Holm by default (E63, from 31 October 2026) [powerkit] | Each condition's mean, and the SDs of participants' averages, of their condition effects (one SD for every condition), of items' averages and of the residual, in the outcome's units | `y ~ cond + (1 \| participant) + (1 \| participant:cond) + (1 \| item)`, cond in treatment coding; items split equally between the conditions or in every condition (then optionally `(1 \| item:cond)`). With the conditions between participants (X a between factor), the participants are split equally and the participant term is `(1 \| participant)` alone. The Satterthwaite tests are Departure 16, Holm's default Departure 17 |


With a yes/no outcome (from 1 November 2026) the default test of the
conditions is the likelihood-ratio test, simr's default for a factor,
with glmer's Wald chi-square test (simr's "chisq", through car) offered;
a pair is tested by car's Wald test of its contrast or by the likelihood
ratio against the model in which the pair shares a mean. With three
conditions (70%, 80% and 75%), 60 items and 30 participants, over 1,000
simulated data sets: 58.3% with the likelihood ratio and 61.7% with Wald;
with no difference (2,000 data sets), 5.65% and 6.2% at alpha .05.

## People within groups, predictors at both levels (two-level model, E62)

| Tool | Test | Effect size | Settings |
| --- | --- | --- | --- |
| G\*Power | No test for multilevel models | — | — |
| simr | `powerSim()` on a model built with `makeLmer()`, as for E33; `fixed(xname, method)` tests one fixed effect, `method = "z"` by default [simr help] | The model's own parameters | — |
| **powerkit** | simr's `powerSim()` with `fixed(term, "sa")`, the term `x`, `w` or `x:w` (E62, from 31 October 2026) [powerkit] | Each effect per SD of its predictor (X standardised within groups, W across groups), the SDs of the groups' intercepts and X slopes with their correlation, and the residual SD, in the outcome's units | `y ~ x + w + x:w + (1 + x \| group)`, groups of equal size; `goal.n` is the number of people, a whole number of groups. The Satterthwaite test is Departure 16 |

With a yes/no outcome (E62, from 1 November 2026) the model is a logistic
mixed model (simr's `makeGlmer()`, lme4's `glmer()`): the chance of 'yes'
for a typical group at the average X and W, and every effect and SD on the
log-odds scale. The test is glmer's Wald z test, simr's default for a
numeric predictor, or the likelihood ratio; not a departure.

With the groups in sites (E62, from 1 November 2026) the model gains a
predictor Z on each site, its interaction with X, and the sites' random
intercepts and X slopes, `y ~ x + w + z + x:w + x:z + (1 + x | site) +
(1 + x | site:group)`, tested as at two levels (Satterthwaite's t test,
Departure 16, or for a yes/no outcome glmer's Wald z test or the
likelihood ratio).

## Effect-size conversion (a published t, F, r, d, odds ratio or risk ratio)

| Tool | t or F into d or d_z | Two groups of different sizes | Other conversions |
| --- | --- | --- | --- |
| G\*Power | No conversion from a test statistic | — | The effect-size drawers work from means and SDs [GP-man, 19.1, 20.1, 21.1] |
| effectsize 1.0.3 | `t_to_d()`: d = 2t / sqrt(df) for two groups, d_z = t / sqrt(df) with `paired = TRUE`; `F_to_d()` is the same with t = sqrt(F) (installed source, 31 October 2026) | Not taken: `t_to_d()` has no group sizes, so equal groups are assumed | `r_to_d()`, `d_to_r()` (with `n1`, `n2`), `oddsratio_to_d()`, `t_to_r()`, `F_to_r()`, `F_to_eta2()` |
| psych 2.6.9 | `t2d()`: d = t / sqrt(n1) for one group or pairs, d = 2t / sqrt(n) for two equal groups of n in all (installed source, 31 October 2026) | d = t sqrt(1 / n1 + 1 / n2) | — |
| **powerkit** | psych's `t2d()`, with n = df + 1 for one group or pairs and n = df + 2 for two groups (from 0.24.1; 0.24.0 used effectsize's `t_to_d()` and `F_to_d()`) [powerkit] | The published group sizes, when given (`conversion > n1`, `n2`), with the error df no more than n1 + n2 - 2 | effectsize, as listed |

These are the definitions: a one-sample or paired t is the mean (of the
differences) over its standard error, sd / sqrt(n), so d = t / sqrt(n)
exactly; for two groups the standard error is sd sqrt(1 / n1 + 1 / n2).
They are Lakens's (2013) equations 7 and 2, the first after Rosenthal
(1991), with 2t / sqrt(N) when only the total is known (refs.bib,
`Lakens2013_effectsizes`, checked against the full text).
effectsize's `t_to_d()` puts the error df where n belongs, which gives a
slightly larger d, and assumes equal groups. Its size, from
`test-effect-conversion.R`: one group of 20 with t = 3 gives 0.671 here
against 0.688 (2.6% larger); two equal groups of 20 give 0.949 against
0.973; groups of 10 and 30 give 1.095 against 0.973, which ignores the
sizes. Under 0.3% with 200 people. The result screen and the write-up
name the function used. A plan saved by 0.24.0 keeps the value it was
converted to, and the result says so.

Two proportions take an odds ratio or a risk ratio with group 1's
proportion p1 and convert it into group 2's proportion, which the test
then uses as if entered. An odds ratio goes through effectsize's
`oddsratio_to_riskratio(OR, p0 = p1)`, times p1, which is the definition
p2 = OR p1 / (1 - p1 + OR p1) (odds2 = OR odds1); a risk ratio gives
p2 = RR p1. G\*Power's two-proportion test takes the two proportions
only, so there is nothing to diverge from; the result and the methods
paragraph give group 1's proportion, the ratio and group 2's proportion.
An odds ratio from a logistic model with covariates is conditional and
usually further from 1 than the groups' marginal odds ratio, which the
input screen's help says.

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
- **Shown to users / in the methods paragraph:** shown on the result screen for E7 and E8 (phase 5, part 1, 17 October 2026; `app/routing/forms.yaml`, `departures`), among the minor differences. Left out of the methods paragraph since 7 November 2026 (maintainer's decision; `docs/decisions.md`): a difference of about 1e-15 is not one a reader of the paper needs, so the paragraph names only departures that can change a number.

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
- **powerkit:** the existing default remains uncorrected (maintainer's
  decision 6); the formula and requested simulation agree on this choice.
  The 10 November open review PR adds explicit corrected variants:
  `z_test_corrected` uses Spower's `p_prop.test(correct = TRUE)` with
  fixed group sizes; `pearson_chi_square_corrected` uses
  `p_chisq.test(correct = TRUE)` with a fixed total and varying margins.
  Both support simulated power and required N; they refuse sensitivity
  and uncorrected-formula overrides. The contingency option requires a
  full 2 by 2 population table, not Cohen's w. Failed analyses remain in
  the attempted-study denominator and are reported. This departure is
  hidden for corrected tests and tables larger than 2 by 2.
  Sources: [R prop.test documentation](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/prop.test.html)
  and [R chisq.test documentation](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/chisq.test.html).
  The correction is a choice to match the planned analysis, not a claim
  that it makes sparse-data approximations exact or is always preferable.
- **Size:** two proportions, p1 = .50, p2 = .65, 170 per group,
  alpha = .05, the same 5,000 seeded data sets: power 0.8178 without the
  correction and 0.7894 with it (.028 lower). For the chi-square test it
  only matters for 2 x 2 tables.
- **Test:** `test-backend-spower.R`, "departure: no continuity correction,
  unlike Spower's default (correct = TRUE)", which also checks that
  powerkit's run equals the uncorrected value.
- **Shown to users / in the methods paragraph:** shown on the result screen (phase 5, part 1, 17 October 2026; `app/routing/forms.yaml`, `departures`). Stated in the full version of the write-up (18 October 2026).

### 6. Mediation fits: lavaan maximum likelihood, not PROCESS's OLS

**10 November 2026:** this departure concerns the ML methods only. The
explicit OLS + percentile-bootstrap method fits each equation by OLS and
does not show this departure. Its scope and pending PROCESS-software
comparison are in [process-style-planning.md](process-style-planning.md).

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

### 9. Basic tests (E1–E6): pwr's formula by default (retired 7 November 2026: not a departure)

**Retired.** Using pwr's formula is pwr's own default and G\*Power's
practice, so it departs from no established tool; it was recorded as a
departure only from powerkit's own earlier default, Spower's simulation.
The number is kept so later departures keep theirs, and the comparison is
kept under "Not departures, but worth stating" ("Basic tests: a formula,
not simulation"). The result screen and the methods paragraph no longer
list it (maintainer's decision, 7 November 2026; `docs/decisions.md`).

### 10. Correlation (E4): Fisher's z, not G\*Power's exact method (retired 12 November 2026: the exact method is the default)

**Retired.** From 12 November 2026 powerkit plans a Pearson correlation
from the exact distribution of r, by pwrss 1.3.3's `power.exact.onecor()`,
as G\*Power does, so there is no departure (`docs/decisions.md`, "Exact
method for the correlation"). pwr's Fisher's z stays as a choice
(`options > correlation_formula = "fisher_z"`), and the result then
carries a note with the size of the difference (key "10" in
`app/routing/forms.yaml`). A correlation that varies between studies
(Departure 24) is still planned on Fisher's z, where that method is
defined. Reason for the change: the approximation's accuracy statement
below holds for mid-sized correlations only; for r = .9 and N = 6 Fisher's
z gives 77.2% power where the exact figure is 81.6%, and asks for a seventh
person. pwrss's one-sided call stops at a correlation of exactly 0
(`docs/upstream-questions.md`); powerkit passes the smallest positive
number there, where the power is alpha. Test: `test-backend-pwr.R`,
"correlation: the exact method by default, Fisher's z on request". The
entry as it stood:


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
- **Test:** `test-backend-pwr.R`, "correlation: the exact method by
  default, Fisher's z on request (Departure 10, retired)".
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

- **Separate calculations:** an individual analysis's power does not
  establish the chance that several tests all succeed. Multiplying their
  powers requires independent decisions; joint methods can instead model
  dependence. Powerkit's existing independent-test guided rule uses about
  89.4% for each of two tests to target 80% together, conditional on both
  tests reaching their targets under a common population. This is not a
  claim that other tools must assume independence or lack joint methods.
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
  question for the statistician). With X as two groups (31 October 2026;
  10,000 replications, N = 120, a moderator W and an interaction), the
  group comparison had 79.1% power against pwr's t test at the implied d,
  81.0%: the same kind of gap, since the outcome also depends on the
  interaction the comparison leaves out (within the cross-check
  allowance, and a question for the statistician); Type I error 4.8%
  and 5.1% for the two tests with every path 0. Measured twice (31
  October 2026; 10,000 replications, N = 120, the first measurement B
  with a path of .6 to Y, a moderator and an interaction), the
  comparison adjusted for B had 82.7% power against powerkit's ANCOVA
  card (E23, pwrss's `power.f.ancova.shieh()`) at the implied values,
  83.9%: the same kind of gap; Type I error 4.9% and 4.5% with no effect.
  With non-randomised groups correlated with the moderator or the first
  measurement (5 November 2026; equal groups with r = .4, a quarter in
  the second group with r = -.3, and a first measurement; 10,000
  replications each), the group comparison's, the interaction's and the
  joint power all agree with a simulation written separately within the
  99.9% Monte Carlo interval; both are simulations of the same model, so
  this checks the exact moments and the population, not a departure.
  Experiments (6 November 2026): a factorial ANOVA's F tests read from the
  same simulated data sets (Superpower's `ANOVA_power()`, `sim_data`). In
  the 2 x 2 between example (N = 160, 4,000 replications) the main effect
  had 35.6% and the interaction 35.0% power against Superpower's exact
  34.9% for each on its own; both were significant together in 12.7% of
  studies, against 12.3% in a simulation written separately with
  `stats::aov()` and 12.2% if the two tests were unrelated: here the
  shared error term makes little difference, and the gain is that the
  joint chance is counted, not assumed. On the guided plan the effect of
  X is then the ANOVA's main effect of X, not the two-group t test its own
  card computes, which ignores the second factor.
  Every analysis adjusts Y for B, as the
  ANCOVA option the guided plan offers for two groups measured twice
  does, so this follows E23 rather than departing from it; the mixed
  ANOVA's group x time test (change scores, E8) is not simulated as a
  whole study. The joint power differs where the
  analyses are related: for the correlation and simple mediation (a = b =
  .3, c' = .1, N = 100), both significant in 38.1% of replications against
  34.8% from the product of the separate powers, 3.3 points higher. For
  the correlation and an interaction they were unrelated (36.5% against
  36.4%).
- **Test:** `test-validation-whole-study-crosscheck.R` (full validation,
  chunk `whole_study`; with `test-validation-whole-study-groups.R` for
  non-randomised groups): each analysis against its separate calculation,
  the joint power above the product of the separate powers for related
  analyses, and Type I error with every path 0; `test-whole-study.R`: the
  joint counts' exact bookkeeping.
- **Shown to users:** on the whole-study result screen ("How this differs
  from calculating each analysis separately"; `app/routing/forms.yaml`,
  `departures`, key "13") and in its methods paragraph, which says the
  whole study was simulated.

### 14. Group treatment trials: the smallest detectable d from the t-based power, not powertools' normal approximation

**The maintainer's decision, 28 October 2026** (`docs/decisions.md`).

- **Established convention:** powertools' `irgtt.cont()` computes power
  from the noncentral t (or F) distribution with Satterthwaite degrees of
  freedom, but solves for every other quantity, delta among them, "using
  normal approximation" (its help page), that is, with 10,000 degrees of
  freedom. The d it returns therefore has less than the target power by its
  own power formula.
- **powerkit:** the smallest detectable d is the value at which
  `irgtt.cont()`'s t-based power equals the target power, found by
  root-finding, as the required sample size already is (powerkit searches
  the power at whole numbers of groups, for every design).
- **Size:** at 20 groups of 8 and 160 people treated individually (ICC
  0.05, 80% power, two-sided α = .05), powertools gives d = 0.340, which
  has 77.1% power by its own formula; powerkit gives d = 0.352, with 80%.
  The gap narrows as the number of groups grows.
- **Test:** `test-backend-powertools.R`, "the smallest detectable d for a
  group treatment trial is powertools' own answer".
- **Shown to users:** on the result screen for this design's smallest
  detectable effect (`app/routing/forms.yaml`, `departures`, key "14") and
  in its methods paragraph.

### 15. Bayes factor t-tests: plan for exactly the effect entered, not bfpwr's default design prior

**Recommended, awaiting the maintainer's decision** (`docs/decisions.md`,
28 October 2026).

- **Established convention:** bfpwr's `powertbf01()` takes a normal
  "design prior" on the true effect, with SD `dpsd`, which by default is
  the analysis prior's scale (`dpsd = pscale`, 1/sqrt(2)): the true effect
  is spread as widely as the prior used to analyse the data. A usual power
  analysis (G\*Power, pwr, and powerkit's other designs) plans for one
  effect. bfpwr's own t-test example in its vignette ("Design with the
  *t*-test Bayes factor", `using-bfpwr`, 0.1.6) also plans for one
  effect (`dpm = 0.5`, `dpsd = 0`), and says a positive SD can be set "if
  parameter uncertainty is to be accounted for".
- **powerkit:** plans for exactly the effect entered (`population >
  effect_sd` 0) unless the user gives an SD for how unsure they are, so
  the Bayes factor version of a t-test answers the same question as the
  t-test it replaces.
- **Size:** for d = 0.5 and BF10 of at least 10 (two groups, two-sided,
  prior scale 0.707), 80% needs 120 per group with powerkit's default and
  372 per group with bfpwr's; at 120 per group bfpwr's default gives 67%
  (bfpwr 0.1.6).
- **Test:** `test-backend-bayes.R`, "the threshold, the prior's scale, the
  design prior and the direction reach bfpwr" (the design prior SD is
  passed through); the size above is from `ntbf01()` and `powertbf01()`
  with `dpsd` 0 and 1/sqrt(2).
- **Shown to users:** on the one-sample, paired and two-group result
  screens when the Bayes factor t-test is chosen and the SD is left at 0
  (`app/routing/forms.yaml`, `departures`, key "15"), and in the methods
  paragraph's full version.
- **The Bayes factor test of one proportion (1 November 2026):** the
  same choice. bfpwr's `pbinbf01()` takes a fixed proportion (`dp`) or,
  by default, a beta design prior equal to the analysis prior (`dp = NA`,
  `da = a`, `db = b`: a uniform proportion with JASP's Beta(1, 1)).
  powerkit plans for exactly the proportion entered unless the user gives
  an SD (`population > p_sd`, a beta design prior with that mean and SD).
  Size: for p = 0.65 against 0.5, two-sided, BF10 of at least 10, 80%
  needs 161 people with powerkit's default and 229 with bfpwr's; at 161,
  bfpwr's default gives 76.5% (`test-backend-bayes-binomial.R`,
  "Departure 15's size for a proportion"). Shown on the one-proportion
  result screen (E25) when the Bayes factor test is chosen and the SD is
  left at 0.
- **The Bayes factor test of a correlation (1 November 2026):** the same
  choice. No package plans this test; the analogue of bfpwr's default, a
  design prior equal to JASP's uniform analysis prior on rho, is a very
  different question (a correlation anywhere from -1 to 1). powerkit plans
  for exactly the correlation entered unless the user gives an SD
  (`population > r_sd`, a stretched beta design prior with that mean and
  SD). Size: for r = .3, two-sided, BF10 of at least 10, 80% needs 162
  people; at 162, the uniform design prior gives 76.4%
  (`test-backend-bayes-correlation.R`, "Departure 15's size for a
  correlation"). Shown on the correlation result screen (E4) when the
  Bayes factor test is chosen and the SD is left at 0.
- **The Bayes factor test of two proportions (1 November 2026):** the same
  choice. No package plans this test; the analogue of bfpwr's default, a
  design prior equal to JASP's analysis prior under the alternative (each
  group's proportion uniform), is a very different question. powerkit
  plans for exactly the proportions entered unless the user gives an SD
  (`population > p_sd`, a beta design prior on each group's proportion).
  Size: for .4 against .6, two-sided, BF10 of at least 10, 80% needs 354
  people; at 354, uniform design priors give 75.3%
  (`test-backend-bayes-proportions.R`, "Departure 15's size for two
  proportions"). Shown on the two-proportion result screen (E5) when the
  Bayes factor test is chosen and the SD is left at 0.
- **In Bayes mode (8 November 2026, the maintainer's decision):** the
  start screen's opt-in Bayes mode makes the design prior the default
  instead. Every "how unsure you are" field (the effect, the correlation,
  the proportions) starts empty and must be filled in before the plan
  runs; powerkit suggests no value, as on the results screen, and 0 still
  plans for exactly the value entered (then this departure is shown as
  usual). Outside Bayes mode nothing changes. `app/routing/R/bayes-mode.R`;
  `app/routing/tests/testthat/test-bayes-mode.R`.

### 16. Mixed models: Satterthwaite's t test, not simr's default z test

Decided by the maintainer on 30 October 2026 (`docs/decisions.md`).

- **Established convention:** simr's `fixed()` tests a fixed effect with
  `method = "z"` by default, treating the t statistic as standard normal,
  which its help calls an asymptotic approximation for models fitted with
  `lmer`.
- **powerkit:** `fixed("cond", "sa")`, lmerTest's Satterthwaite t test,
  which is the p-value most lme4 users report (through lmerTest) and
  allows for the small number of participants or items.
- **Size:** with powerkit's example (a 20 ms difference, SDs 60, 25, 30
  and 120 ms, 40 items in one condition each), on the same 1,000
  simulated data sets: at 20 participants, 25.0% with Satterthwaite and
  27.7% with z; at 40 participants, 39.6% and 42.0% (simr 1.0.11). The
  two-level model (E62, from 31 October 2026) uses the same test, where
  it matters most for the group-level effects: with powerkit's example
  (pupils in classes of 20; `inst/specs/mixed_two_level.json`) and 1,000
  simulated data sets, the group-level effect at 10 classes has 21.6%
  power with Satterthwaite and 31.4% with z, and at 40 classes 78.4% and
  80.6%; the cross-level interaction at 10 classes 16.2% and 22.6%. With
  three or more conditions (E63, from 31 October 2026) the F test of the
  conditions is lmerTest's Satterthwaite F rather than simr's default for
  a factor, a likelihood-ratio test: with powerkit's example
  (`inst/specs/crossed_conditions.json`) and 1,000 simulated data sets,
  21.5% against 22.9% at 20 participants, 31.1% against 32.3% at 40.
  With three levels (E68, from 1 November 2026) and whole schools
  assigned (powerkit's example, `inst/specs/mixed_three_level.json`:
  classes of 20, four classes per school), 17.2% against 23.6% at 12
  schools and 46.4% against 49.4% at 30 (1,000 simulated data sets).
  With a predictor measured on each item (E67, from 1 November 2026;
  powerkit's example, `inst/specs/item_predictor.json`: 60 items, a
  slope of -15 ms per SD of word frequency), 48.9% against 54.1% at 10
  participants and 80.1% against 81.6% at 30 (1,000 simulated data sets).
- **Test:** `test-backend-mixed-model.R`, "powerkit's simulation is simr's
  powerSim() with the Satterthwaite test, replication for replication";
  the size above is from `powerSim()` with each method on the same seed.
- **Shown to users:** on E33's, E62's, E63's, E68's and E67's result screens
  (`app/routing/forms.yaml`, `departures`, key "16"), and in the methods
  paragraph's full version. For E62, `test-backend-two-level.R`
  ("Satterthwaite's test is never more liberal than simr's z test")
  checks the direction on the same simulated data sets.

### 17. Pairwise comparisons: Holm's adjustment by default, not Superpower's none

Decided by the maintainer on 31 October 2026 (`docs/decisions.md`: Holm
and Bonferroni first); Holm's method as the default is powerkit's.

- **Established convention:** Superpower's `ANOVA_power()` reports the
  power of every pairwise t-test with `p_adjust = "none"` by default, and
  adjusts them together (`p.adjust(paired_p, method = p_adjust)`, Superpower
  0.2.4.1) when asked.
- **powerkit:** the pairwise comparison option on the one-way ANOVA cards
  (E18, E54) adjusts by Holm's method unless the user chooses Bonferroni's
  or none, because a study analysed by several pairwise tests and reported
  without adjustment overstates its evidence. Holm's method never rejects
  less often than Bonferroni's.
- **Size:** for None against Praise in the one-way example (means 10, 11
  and 13, SD 6, 30 per group, three comparisons), 31.2% with Holm's
  adjustment, 30.1% with Bonferroni's and 47.8% with none (Superpower's
  `ANOVA_power()`, 10,000 replications each).
- **Test:** `test-backend-anova-pairwise.R`, "adjusting costs power: none,
  then Holm, then Bonferroni"; `test-validation-anova-pairwise.R` checks
  Bonferroni's power against `stats::power.t.test()` at alpha / 3.
- **Shown to users:** on the E18 and E54 result screens when pairwise
  comparisons are adjusted (`app/routing/forms.yaml`, `departures`, key
  "17"), and in the methods paragraph's full version; on E63's (three or
  more conditions with participants and items, from 31 October 2026),
  where the pair Neutral against Happy in powerkit's example has 25.0%
  power with Holm's adjustment, 24.4% with Bonferroni's and 38.3% with
  none at 40 participants (1,000 simulated data sets;
  `test-backend-crossed-conditions.R` checks the order on the same data
  sets).

### 18. Meta-analysis: the Hartung-Knapp test by default, not metapower's z test

Decided by the maintainer on 31 October 2026 (`docs/decisions.md`): the
Hartung-Knapp test for every number of studies, for consistency with one
preregistered test.

- **Established convention:** metapower's `mpower()` plans the
  random-effects average with a z test (Jackson and Turner's, 2017,
  method, after DerSimonian and Laird's tau^2).
- **powerkit:** under the random-effects model, E61 plans for the
  Hartung-Knapp(-Sidik-Jonkman) test unless the user chooses the z test:
  DerSimonian and Laird's tau^2, the variance
  sum(w (y - mean)^2) / ((k - 1) sum(w)) and a t test with k - 1 df,
  which "consistently results in more adequate error rates than the DL
  method, especially when the number of studies is small" (IntHout,
  Ioannidis & Borm, 2014, refs.bib `IntHout2014_hksj`). No package
  computes its power, so it is simulated: Spower with powerkit's
  experiment `p_meta_hk()`, fitting metafor's
  `rma(method = "DL", test = "knha")` to k simulated study estimates. The
  fixed-effect model keeps the z test.
- **Size:** less power, most with few studies: for d = 0.15, 40 per
  study, I-squared 0.5 and ten studies, about 16.5% against 21.4% with
  the z test. For subgroups (the test that kinds of study differ, from 1
  November 2026; 20 studies of 40, d = 0.2 against 0.5, I-squared 0.5):
  29.3% (2,000 simulated meta-analyses, Monte Carlo SE 1.0) against
  31.9% with metapower's `mod_power()`. For a moderator that is a score (a
  meta-regression, from 1 November 2026; d = 0.3 at the moderator's
  mean, a slope of 0.15 per SD, 40 per study, residual I-squared 0.3):
  17.95% against 22.0% with the z test at 10 studies, and 55.9% against
  58.75% at 30 (the same 2,000 simulated meta-analyses tested both ways,
  Monte Carlo SE 1.1); no package computes either, so both are
  simulated.
- **Test:** `test-backend-metapower.R`, "Hartung-Knapp power: the size of
  the difference", and for the moderator `test-backend-meta-more.R`; `test-validation-meta-analysis.R` checks the
  simulated power against a separately written simulation of IntHout et
  al.'s formulas, and the Type I error.
- **Shown to users:** on the E61 result screen when the Hartung-Knapp test
  is used (`app/routing/forms.yaml`, `departures`, key "18"), and in the
  methods paragraph's full version. Known difference 9 (metapower's
  rounding) then doesn't apply and isn't shown, nor for subgroups, whose
  `mod_power()` doesn't round. `test-validation-meta-subgroups.R` checks
  the subgroup test against metafor called directly and its Type I
  error.

### 19. Moderated mediation with a mediator in a later product: explicit population variances

For PROCESS models 58 and 59, the mediator contains XW and also appears
in MW. It is not jointly normal with W. Powerkit expands these products
as polynomials in the independent population variables, evaluates their
moments (Isserlis, 1918, doi:10.1093/biomet/12.1-2.134, for normal variables;
the weighted two-point moments for standardised binary variables), and
checks each equation's explained variance.

Power4mome 0.2.1's `psi_std_monte_carlo()` updates products before replacing
the mediator's old error values with its generated values. Its later
equation can therefore use an incorrect product during standardisation.
Its actual data generator updates products after replacing each outcome.
Powerkit supplies the correct residual variances as fixed values in the
population model and passes `standardized = FALSE`. The fitted analysis
model still estimates residual variances; they are not fixed to known
population values. Exported scripts use the same population.

With M=.3X+.5XW+sqrt(.66)e, independent standard-normal X, W and e,
Var(MW)=1.5 and Cov(MW,X)=.5. The predictor .4X+.4M+.5MW has variance
1.111, so a standardised Y with an independent residual is impossible.
The previous normal-product approximation gave .666 and accepted it.
`test-path-product-moments.R` checks this boundary, independent populations
with correlated X/W, and recovery from power4mome's actual generator.
Departure 19 is shown on the affected result and in the methods text.

### 20. Differential item functioning: both of each DIF item's parameters tested, not only those that differ (irtpwr's preset)

- **What differs:** irtpwr's `"DIF2PL"` preset builds its hypothesis from
  the parameters that differ in the population given, so an item that is
  only harder in the focal group is tested on its intercept alone (1 df).
  The test researchers usually run frees both of the item's parameters,
  its discrimination and its intercept: mirt's `DIF()` help (mirt 1.48)
  runs its omnibus tests with `which.par = c('a1', 'd')`, with tests of
  one parameter as follow-ups for flagged items. powerkit plans for that
  test by default (2 df per DIF item), through the preset with its
  hypothesis-building functions replaced (`backend-irtpwr.R`), and offers
  irtpwr's choice as `target_test > free_parameters = "differing"`.
- **Why** (the maintainer's decision, 5 November 2026; judgement call
  B19): a power analysis should be for the test that will be run;
  freeing only the difficulty is more powerful when only the difficulty
  differs but cannot detect a change in discrimination, so it is a
  narrower test than the usual one.
- **Size:** for the example spec (8 items, item 1 0.4 harder in the focal
  group) at 600 people, 53.6% (both parameters) against 64.1% (only the
  difficulty), by the likelihood-ratio statistic. When both parameters
  differ, the two choices are the same test.
- **Test:** `engine/tests/testthat/test-backend-irt.R`, "Departure 20:
  testing both of a DIF item's parameters (the default) costs power when
  only its difficulty differs"; both choices agree with simulated
  multigroup models in `test-validation-irt.R`.
- **Shown to users:** on the E71 result unless the user chose irtpwr's
  test (`app/routing/R/results.R`, `departures_for()`), and in the
  methods paragraph.

### 21. Two groups: Welch's t-test by default, not Student's (G\*Power and pwr)

- **Established convention:** G\*Power's two-group t-test and pwr's
  `pwr.t.test()` and `pwr.t2n.test()` plan for Student's t-test, which
  pools the two groups' variances; Spower's `p_t.test()` runs it unless
  `var.equal = FALSE`.
- **powerkit:** the two-group card (E2) plans for Welch's t-test unless the
  user chooses Student's, worked out by pwrss's formula
  (`power.t.welch()`, pwrss 1.3.3), with Spower's simulation on request
  (`options > method = "simulation"`). The smallest detectable effect and
  a justified alpha use the same formula: d searched with pwrss's power
  (`welch_sensitivity()`), and JustifyAlpha's `optimal_alpha()` on
  `power.t.welch()`.
- **Why** (the maintainer's decision, 7 November 2026, with
  `Delacre2017_welch`): Welch's test keeps the false-positive rate at
  alpha when the groups' spreads differ, above all when the smaller group
  has the larger spread, and loses almost nothing when they don't, so
  Delacre, Lakens and Leys (2017) recommend it by default; R's own
  `t.test()` runs it unless told otherwise. The formula, not a
  simulation, is the default because the two agree (the `welch_spreads`
  validation chunk) and the formula has no random error.
- **Size:** with equal spreads and equal groups the two tests need the same
  N (788, 128 and 52 for d = 0.2, 0.5 and 0.8 at 80% power: pwrss's Welch
  df are then n - 2, as Student's). With unequal groups Welch's needs a few
  more: 147 rather than 144 for d = 0.5 when group 2 is twice the size of
  group 1, and 176 rather than 172 when it is three times the size.
- **Test:** `engine/tests/testthat/test-welch-default.R`.
- **Shown to users:** on the E2 result whenever Welch's test is planned
  for (`app/routing/R/results.R`, `departures_for()`), and in the methods
  paragraph. The critical effect size is shown with Student's test only:
  Welch's critical d depends on the sample variances, so it has no single
  value before the data are in (`decisions.md`, 1 November 2026).

### 22. One-way ANOVA: Welch's F by default, not the classical F test (G\*Power and Superpower)

- **Established convention:** G\*Power's one-way ANOVA and Superpower's
  `ANOVA_exact()` plan for the classical F test, which assumes the same SD
  in every group.
- **powerkit:** the one-way ANOVA card (E18) plans for Welch's F
  (`stats::oneway.test(var.equal = FALSE)`) unless the user chooses the
  classical F test, from one SD for every group or an SD for each. No
  package gives Welch's F's power by formula; since 13 November 2026 it
  is worked out by Levy's noncentral F approximation, as Jan and Shieh
  (2014, `Jan2014_welch_anova`) recommend (`backend-welch-anova.R`), and
  simulated with Spower (`p_anova.test(var.equal = FALSE)`) on request.
  The smallest detectable effect scales the pattern of means until the
  formula reaches the target; when simulated (`welch_f_sensitivity()`),
  the scale is read from a probit curve of the simulated rejections,
  starting from the F test's exact answer, with a 95% interval.
- **Why** (the maintainer's decision, 8 November 2026, with
  `Delacre2019_welch_f`): Welch's F keeps the false-positive rate at
  alpha when the groups' SDs differ and loses little power when they
  don't, so Delacre, Leys, Mora and Lakens (2019) recommend it by default
  over the classical F test.
- **Size** (80% power, means 10, 11 and 13, three equal groups): with
  one SD of 6 the F test needs 228 and Welch's F 231 (95% interval 228 to
  234; 10,000 replications per point). With SDs 4, 6 and 9, Welch's F
  needs 300 (297 to 303); the F test can't take three SDs, and with their
  root mean square (6.66) it plans 279. With those SDs and 30 per group
  the classical F test's false-positive rate is about 6.1% against 5.3%
  for Welch's F; with groups of 45, 30 and 15, the smallest group having
  the largest SD, it is about 13.5% against 5.0% (20,000 simulated studies
  each, powerkit's own check, not a published figure).
- **Test:** `engine/tests/testthat/test-welch-anova-default.R`; the
  formula against Jan and Shieh's (2014) tables and Spower's simulation in
  `test-backend-welch-levy.R`; Welch's F (formula and simulation) against
  separately simulated `oneway.test()` studies, its false-positive rate
  and its smallest detectable effect in the `welch_spreads` validation
  chunk.
- **Shown to users:** on the E18 result whenever Welch's F is planned for
  (`app/routing/R/results.R`, `departures_for()`), and in the methods
  paragraph.

### 23. t-tests: optional variation between studies (default departure retired 10 November 2026)

**Current policy (maintainer, 10 November 2026):** new plans start with
this field empty, so the calculation concerns the entered effect. Nonzero
variation is an explicit optional scenario, not an automatic safety margin.
Its answer averages significance across differing study effects; it does
not establish that power at their average, or in every setting, reaches
the target. For two-sided tests either significant direction counts.
Saved nonzero values remain unchanged. The result retains the comparison
with no variation. The historical decision and numerical examples below
explain the option; they no longer describe the starting default.

- **Established convention:** G\*Power and pwr plan for a true effect that
  is exactly the same in the new study as the one entered.
- **powerkit:** the one-sample, two-group and paired t-test cards (E1, E2,
  E3) start "How much might the true effect vary between studies?" at an
  SD of 0.05 in d (d_z for pairs), Kenny and Judd's (2019) small value,
  and plan by their formula (above, "Effects that vary between studies").
  The effect entered is then the average across studies. Emptying the
  field, or 0, gives the usual analysis.
- **Why** (the maintainer's decision, 8 November 2026, with
  `Kenny2019_heterogeneity`): Kenny and Judd show that true effects vary
  between studies, that ignoring it understates the people needed when
  power is high, and argue that zero should not be the default.
- **Size** (d = 0.3, two equal groups, 80% power): 376 in total against
  352 without the variation; at 100 people, power .323 against .318.
- **Test:** `engine/tests/testthat/test-heterogeneity.R`, "Departure 23".
- **Shown to users:** on the t-test results whenever the variation is
  above 0 (`app/routing/R/results.R`, `departures_for()`), in the result's
  own sentence on the variation, and in the methods paragraph.

### 24. Correlation: optional variation between studies (default departure retired 10 November 2026)

**Current policy (maintainer, 10 November 2026):** new plans start with
this field empty, so the calculation concerns the entered effect. Nonzero
variation is an explicit optional scenario, not an automatic safety margin.
Its answer averages significance across differing study effects; it does
not establish that power at their average, or in every setting, reaches
the target. For two-sided tests either significant direction counts.
Saved nonzero values remain unchanged. The result retains the comparison
with no variation. The historical decision and numerical examples below
explain the option; they no longer describe the starting default.

- **Established convention:** G\*Power and pwr plan for a true
  correlation that is exactly the same in the new study as the one
  entered.
- **powerkit:** the correlation card (E4), with Pearson's test, starts
  "How much might the true correlation vary between studies?" at an SD of
  0.025 on Fisher's z, and plans by McShane and Böckenholt's normal model
  (above, "Correlations that vary between studies"). The correlation
  entered is then the average across studies. Emptying the field, or 0,
  gives the usual analysis.
- **Why** (the maintainer's decision, 8 November 2026, with
  `Kenny2019_heterogeneity` and `McShane2014_river`): the reasons for
  Departure 23 apply to correlations too. Kenny and Judd take 25% of a
  small, medium and large effect as small, medium and large variation,
  based on past meta-analyses and replication projects; for r = .1 that
  is 0.025 (Fisher's z is within 0.001 of r there).
- **Size** (80% power, two-sided alpha .05): r = .1 needs 904 people
  against 782 without the variation; r = .3 needs 86 against 85.
- **Test:** `engine/tests/testthat/test-heterogeneity.R`, "Departure 24".
- **Shown to users:** on the correlation result whenever the variation is
  above 0 (`app/routing/R/results.R`, `departures_for()`), in the result's
  own sentence and table on the variation, and in the methods paragraph.

### 25. Precision planning: assurance by default, not MBESS's expected width

- **Established convention:** MBESS's `ss.aipe.smd()`, `ss.aipe.sm()` and
  `ss.aipe.reg.coef()` plan for the expected width of the confidence
  interval unless `assurance` is given.
- **powerkit:** on the precision card (E46), for d, a standardised mean
  and a standardised regression coefficient (MBESS's routes), the target
  width is a width with a stated chance (assurance) by default. The
  chance starts empty, as target power does, and the user gives it and,
  optionally, why. "Only on average" is kept as a choice. presize's
  routes (correlations, proportions, raw mean differences, odds ratios
  and the ICC) have no assurance and are unchanged.
- **Why** (the maintainer's decision, 8 November 2026): an expected width
  is an average, so a study planned for it gets an interval wider than
  planned about half the time. The user is never told this unless they
  read MBESS's help. A width with a stated chance is what a researcher
  planning for precision means, as target power is for a test. Starting it
  empty, rather than at a pre-filled 80%, keeps the chance the user's to
  justify (`decisions.md`, 8 November 2026, on conventional values).
- **Size:** for a standardised regression coefficient of 0.2 (R-squared
  0.2, 0.1 with the other two predictors) and a width of 0.2, the
  expected width needs 349 people, while 80%, 90% and 95% assurance need
  373, 386 and 396. For d = 0.5 and a width of 0.4 the difference is
  small: 199 per group, against 201, 202 and 203.
- **Test:** `app/routing/tests/testthat/test-precision-width-meaning.R`,
  "an assurance plan shows Departure 25, compares 80%, 90% and 95%, and
  writes the reason up".
- **Shown to users:** on the precision result whenever the plan has an
  assurance (`app/routing/R/results.R`, `departures_for()`), with a line
  comparing the sample size on average and at 80%, 90% and 95%
  assurance, and in the methods paragraph.

### 26. Repeated measures with unequal SDs or correlations: the Greenhouse-Geisser correction by default, not Superpower's none

Decided by the maintainer on 11 November 2026 (`docs/decisions.md`,
"Sphericity correction by default"). It replaces "none by default" in the
decision of 1 November 2026.

- **Established convention:** Superpower's `ANOVA_exact()` and
  `ANOVA_power()` apply no sphericity correction unless asked
  (`correction = "none"`, Superpower 0.2.4.1). G\*Power's
  repeated-measures analysis takes a nonsphericity correction epsilon,
  1 by default, and one correlation for every pair.
- **powerkit:** when the SDs or correlations are entered as different on
  the one-way repeated-measures, mixed and two-factor within cards, the
  form's correction is Greenhouse-Geisser unless the user chooses
  Huynh-Feldt or none. Without sphericity the uncorrected F test does not
  hold its false-positive rate, so its power describes a test that is not
  valid, and statistics programs report the corrected test in that case.
  Choosing "none" then puts a warning above the answer. A spec written by
  hand without `target_test > correction` is still run uncorrected, as
  Superpower would.
- **Size:** three conditions, means 600, 620 and 650, SD 100, correlations
  .8, .5 and .2, 40 people: 68.4% power with the correction against 80.5%
  without, and 52 people rather than 40 for 80% power. In 40,000 simulated
  studies of that population (base R, with the F test and epsilon computed
  directly) the uncorrected test rejected a true null 6.7% of the time and
  the corrected test 4.8%; the corrected test's simulated power was 71.5%,
  so the corrected figure from `ANOVA_exact()` is an approximation, here
  about 3 points low. In the mixed-design check of
  `docs/validation-log.md` (7 to 10 November 2026) it was about 1.5 points
  high. The result screen says so and offers the simulation.
- **Test:** `test-backend-anova-within-covariance.R`, "departure: the size
  of the Greenhouse-Geisser correction".
- **Shown to users:** on the three cards' result screens when the
  correction is applied and a within-participants factor has three or more
  levels (`app/routing/forms.yaml`, `departures`, key "26"), and in the
  methods paragraph, which also names the correction.

### 27. Bland-Altman limits of agreement: the analysis simulated with MOVER intervals by default, not Lu et al.'s formula

Decided by the maintainer on 14 November 2026 (`docs/decisions.md`,
"Bland-Altman limits of agreement on E69").

- **Established convention:** the published sample-size method for the
  Bland-Altman limits of agreement is Lu et al.'s (2016) formula, which
  SimplyAgree provides as `blandPowerCurve()` (SimplyAgree 0.3.0): power
  1 - beta1 - beta2 from two noncentral t probabilities, for Bland and
  Altman's (1999) analysis, in which agreement is shown when the outer
  ends of the two-sided 95% confidence intervals of both limits lie within
  plus and minus the largest acceptable difference.
- **powerkit:** simulates the analysis the researcher will run. Spower
  draws each study's differences from a normal distribution with the
  bias and SD given, and SimplyAgree's `agreement_limit()` analyses it,
  with MOVER confidence intervals for the limits (Zou, 2013; its default,
  `loa_calc = "mover"`) unless the user chooses Bland and Altman's
  intervals (`"blandaltman"`). Lu et al.'s formula stays as a labelled
  quick option. `agreement_limit()`'s `alpha` is one-sided, so it is given
  alpha / 2, which makes its outer bounds those of two-sided 1 - alpha
  intervals, as Bland and Altman and Lu et al. report them. Two reasons:
  the formula approximates the analysis it plans for, and Bland and
  Altman's intervals are too narrow in small samples. With one population
  limit exactly at the margin, the analysis should show agreement 2.5% of
  the time; in 40,000 simulated studies, Bland and Altman's intervals did
  so 5.0% of the time at 30 subjects and 3.8% at 100, the MOVER intervals
  2.9% and 2.7%.
- **Size:** bias 0.5, SD of the differences 2.5, margin 8, 95% limits,
  alpha 0.05. The formula gives 80% power at 26 subjects (82.0%); the
  MOVER analysis has about 69% there (40,000 simulated studies) and needs
  33 subjects (powerkit, 1,000 studies per sample size). Against the
  analysis it describes, Bland and Altman's, the formula is off in both
  directions: 88.3% against 85.2% at 30 subjects for the example, and
  52.9% against 61.4% with no bias, an SD of 3.3, a margin of 8 and 100
  subjects.
- **Test:** `test-validation-agreement.R`, "the size of the difference
  between Lu et al.'s approximation and the analysis" (the departure's
  size) and "with one limit at the margin, agreement is shown about
  alpha / 2 of the time" (the MOVER intervals' error rate).
- **Shown to users:** on E69's result screen when the limits of agreement
  are simulated (`app/routing/forms.yaml`, `departures`, key "27"), in the
  choice notes for the calculation method, and in the methods paragraph,
  which names the intervals.

## Known differences

powerkit follows an established tool here, but another established tool
gives a different answer. These are not departures. Users comparing tools
will notice them, though, so each entry states the size of the difference
and, like a departure, is shown on the results screen and stated in the
methods paragraph.

### 1. Regression interactions: fixed-model and simulated-study power differ

- **What differs:** fixed-model regression power, such as G*Power's linear
  multiple regression and InteractionPoweR's analytic
  `power_interaction_r2()`, differs from power averaged over simulated
  studies with newly sampled predictors. The recorded grid below found
  higher analytic power from InteractionPoweR in its checked settings.
  This is not a universal ordering or bound, and the grid did not run
  G*Power itself. The input-route explanation, result and methods text
  distinguish the computations; analytic sensitivity is explicitly an
  approximation that needs a fixed-N simulation check.
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
### 4. Variance tests: simulated, where G\*Power uses an exact formula (retired 31 October 2026: powerkit computes them exactly too)

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

### 5. Rank tests: the rank test simulated, where G\*Power adjusts the t-test

- **What differs:** G\*Power plans its Wilcoxon signed-rank and
  Mann-Whitney tests from the t-test, adjusted by the rank test's
  efficiency for a chosen parent distribution. powerkit simulates the
  rank test itself with Spower's `p_wilcox.test()` (and the
  Kruskal-Wallis test with `p_kruskal.test()`), on scores of the shape
  the user chooses (normal, skewed or heavy-tailed), shifted by the
  effect. The answer carries Monte Carlo error, and for a given shape it
  need not equal the efficiency-adjusted figure.
- **Size:** not yet measured against G\*Power; the published comparisons
  in `test-validation-rank-tests.R` are placeholders for the maintainer to
  transcribe. Against the t-test powerkit showed before (normal scores,
  d = 0.5, 64 per group), the Mann-Whitney test has slightly less power,
  within 0.05; with heavy-tailed scores it has more. Both are pinned by
  the same file.
- **Test:** `engine/tests/testthat/test-validation-rank-tests.R` (chunk
  `rank`): published placeholders, direct Spower calls, Type I error, and
  the difference from the t-test; `test-backend-rank.R` checks the
  translation, the refusals and the exported script.
- **Shown to users:** on the one-sample, paired, two-group and one-way
  ANOVA result screens when the rank test is chosen, under "Where other
  established tools give a different answer" (`app/routing/forms.yaml`,
  `known_differences`, key "5").
- **Methods paragraph:** "Power for the rank test was estimated by
  simulating the test itself on scores of the assumed shape, rather than
  by adjusting the t-test's power for the test's efficiency as G\*Power
  does, so the two can give slightly different sample sizes."
  (`known_differences_methods`, key "5").

### 6. Bayes factor t-tests: bfpwr's closed form against simulated Bayes factors

- **What differs:** bfpwr computes the probability that the Bayes factor
  passes the threshold by treating the effect estimate as normally
  distributed with standard error 1 / sqrt(effective n) (`ptbf01()`'s
  source, bfpwr 0.1.6), a large-sample approximation to the t statistic.
  Simulating the Bayes factor itself, as BFDA does, uses the t statistic's
  own distribution.
- **Size:** close in larger samples (within simulation error in the
  validation checks from 100 people in one group, or 50 per group in two),
  and a little lower in small ones. For a one-sample test with d = 0.4 and
  BF10 of at least 10: 7.6% against about 11% simulated with 20 people,
  and 28.3% against about 30% with 40.
- **Test:** `engine/tests/testthat/test-validation-bayes-factor.R` (chunk
  `bayes`), "bfpwr's normal approximation gives a little less power than
  simulation" (one sample, 20 and 40 people), against Bayes factors from
  `bfpwr::tbf01()` on simulated t statistics.
- **Shown to users:** on the one-sample, paired and two-group result
  screens when the Bayes factor t-test is chosen (`app/routing/forms.yaml`,
  `known_differences`, key "6").
- **Methods paragraph:** "The probability of strong evidence was
  calculated in closed form, which treats the effect estimate as normally
  distributed; in small samples this gives slightly lower values than
  simulating the Bayes factor itself." (`known_differences_methods`, key
  "6").

### 7. Moderation by its R-squared change: G*Power's fixed-model formula, slightly above InteractionPoweR's

- **What differs:** given by its R-squared change, a two-way interaction's
  power comes from pwrss's `power.f.regression()`, the F test of the
  product term with Cohen's f^2 = R2_change / (1 - R2_full) and
  lambda = f^2 N on F(1, N - 4), as G*Power's R² increase test computes it
  [GP-man, 14, 14.5, pp. 36-38]. InteractionPoweR's own formula,
  `power_interaction_r2()`, divides the R-squared change by 1 - R2_reduced
  instead, and uses lambda = f^2 (N - 3) on N - 3 denominator df (its
  source, InteractionPoweR 0.2.4), so it gives slightly less power for the
  same interaction. Given by its correlations, powerkit simulates instead
  (Known difference 1), which is slightly lower again.
- **Size:** for r(X,Y) = r(W,Y) = r(X,W) = .2 and r(XW,Y) = .15 (an
  R-squared change of .0225 over .0667): 59.9% against 58.3% at N = 200,
  34.3% against 32.8% at N = 100 and 88.0% against 87.0% at N = 400.
- **Test:** `engine/tests/testthat/test-backend-interaction-r2.R`, "the
  R-squared change gives G*Power's fixed-model power, a little above
  InteractionPoweR's formula".
- **Shown to users:** on the moderation result screen when the interaction
  is given by its R-squared change (`app/routing/forms.yaml`,
  `known_differences`, key "7").
- **Methods paragraph:** "Power was calculated by the fixed-model formula
  for an R-squared increase, as in G*Power; InteractionPoweR's formula,
  and simulation with the predictors drawn afresh in each sample, give
  slightly lower power for the same interaction."
  (`known_differences_methods`, key "7").

### 14. Joint power: PUMP's shifted t gives a little less power than the card with few groups

- **What differs:** the study plan's joint power comes from PUMP's
  `pump_power()`, which draws each outcome's test statistic as a central
  multivariate t shifted by its noncentrality (PUMP 1.0.5's source:
  `mvtnorm::rmvt()` plus the shift), as PowerUp!'s formulas do. The cards
  for cluster-randomised and multisite trials use powertools, which takes
  the noncentral t. For an independent t-test PUMP pools the two groups'
  variances, where the card uses Welch's test.
- **Size:** for a multisite trial with d = 0.4, 20 people per group, ICC
  0.1 and ICC of the effect 0.05: 43.2% against the card's 45.9% with 10
  groups, 79.5% against 79.7% with 20, 98.0% against 98.2% with 40. The
  noncentrality is the same in both; only the distribution differs.
- **Test:** `engine/tests/testthat/test-joint-power.R`, "Known difference
  14: PUMP's power is a little below the card's with few groups".
- **Shown to users:** with the joint power on the study plan screen
  (`app/routing/R/study-plan.R`, `joint_power_difference()`).
- **Methods paragraph:** joint power has no methods paragraph of its own;
  the sentence shown with it states the difference, and the cards' methods
  paragraphs are unchanged.

### 16. Yes/no outcomes in clustered designs: powertools' unexplained factor 1.2 asks for more groups than simulation needs

- **What differs:** for a cluster-randomised or multisite trial with a
  yes/no outcome (E34), powertools' `crt.parallel.bin()` and
  `multisite.bin()` multiply the variance of the log odds ratio by 1.2,
  and their help pages give no source for the factor
  (`upstream-questions.md`, powertools question 1). Simulating the
  analysis researchers run (lme4's `glmer()` with a random intercept for
  groups, Wald z test) needs fewer groups: without the factor, the same
  formula agrees with that simulation closely.
- **Size:** proportions 0.30 and 0.45, groups of 20, SD of the groups' log
  odds 0.3: a cluster-randomised trial needs 28 groups with the factor and
  24 without it (formula power at 28 groups without it 86.7%; a 500-run
  `glmer()` simulation gave 87.8% at 28 and 83.8% at 24); a multisite
  trial with an effect SD of 0.3 needs 22 groups with the factor and 19
  without it (simulation 87.6% at 22). The test is in `engine/tests/testthat/test-backend-powertools.R`,
  "the factor 1.2 in powertools' yes/no formulas".
- **Why not a departure (yet):** the factor is powertools' own method,
  and removing it is a method choice that waits on the maintainer and on
  its source (`next.md`). Groups are the costliest unit in these trials,
  so the size is shown rather than left in this file.
- **Shown to users:** on E34 results with a yes/no outcome when whole
  groups, or people within groups, are randomised (`app/routing/forms.yaml`,
  `known_differences`, key "16"). Not for the group treatment trial,
  whose `irgtt.bin()` has no such factor.
- **Methods paragraph:** `known_differences_methods`, key "16".

### 17. Three-way regression interactions: the fixed-model formula gives more power than simulated studies

- **What differs:** the three-way interaction card (E31) uses
  InteractionPoweR's `power_interaction_3way_r2()`, the fixed-model
  formula for the R-squared change when XWZ is added; InteractionPoweR has
  no simulation for three-way models. Simulating studies with newly drawn
  predictors, as Known difference 1 does for two-way interactions, gives
  less power, and the gap is larger than for two-way models, presumably
  because the triple product is heavier-tailed still.
- **Size:** for the example (`regression_three_way.json`: b_XWZ 0.1, X's
  reliability 0.8), the formula's N for 80% is 853; simulated studies
  (lm() on new normal predictors, X observed with error) gave 76.2% at 853
  (3,000 runs), 80.6% at 940 and 82.8% at 1,000 (2,000 each), so about
  10% more people are needed. With X perfectly reliable: 88.5% by formula,
  85.5% simulated at 853. Test:
  `engine/tests/testthat/test-backend-three-way.R`, "simulated studies with
  random predictors have less power than the fixed-model formula".
- **Shown to users:** on every E31 result (`app/routing/forms.yaml`,
  `known_differences`, key "17").
- **Methods paragraph:** `known_differences_methods`, key "17".

## Not departures, but worth stating

- **One tail counted for some yes/no outcomes in clustered trials, and for
  Cox regression** (noted 8 November 2026). The normal-approximation
  formulas that powertools uses for yes/no outcomes in cluster-randomised,
  group-treatment and multisite trials, and powerSurvEpi's formula for a
  Cox regression predictor, count only the tail in the direction of the
  effect. With no effect they therefore report 2.5% power for a two-sided
  test at alpha = .05, where G*Power and powerkit's other two-sided
  formulas give 5%. At realistic effects the other tail adds almost
  nothing (about 0.1 percentage points at 20% power, and less above it), so the
  results stand; only power for very small effects is slightly
  understated. powerkit follows the packages, as the textbook formulas
  they implement do.

- **Basic tests (E1–E6): a formula, not simulation** (formerly Departure 9).

  - **Before 17 October 2026:** powerkit's default was simulation with Spower for every basic test
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
    templates have their own exact formula since 31 October 2026 (see
    "Variance tests"; Known difference 4 retired).
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
    simulation (Departure 9)", which checks each size above.
  - **Shown to users:** the result's software sentence names the formula
    ("base R's formula, ..., no simulation"); this is not listed as a
    departure (retired as Departure 9, 7 November 2026).

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
  agree. Whether it matches G*Power's ANCOVA is still to check. The
  two-way ANCOVA (template `factorial_ancova`, 28 October 2026) uses the
  same function with `factor.levels = c(k, m)`. Given no contrast matrix,
  pwrss tests only the highest interaction, so powerkit passes the rows of
  pwrss's own `factorial.contrasts()` (deviation coding) for the effect
  asked for: rows `A1`, ... for A, `B1`, ... for B, `A1:B1`, ... for the
  interaction. Each effect agrees with Superpower's `ANCOVA_analytic()`
  in a test [powerkit, `engine/R/backend-pwrss.R`].
  An ANCOVA given by its partial eta-squared (31 October 2026, as G*Power
  takes it) uses pwrss's `power.f.ancova()` with the number of covariates:
  G*Power's method, with the covariates fixed, lambda = f^2 N and error df
  N minus the groups minus the covariates. A published ANCOVA's partial
  eta-squared already allows for the covariates, so their R-squared isn't
  asked for. For the same population the two methods differ a little:
  81.3% from the means (Shieh) against 81.8% from partial eta-squared
  (G*Power) in the test example with 90 people, three groups and one
  covariate explaining 36% [powerkit, `test-backend-anova-eta.R`].
- **Repeated-measures and mixed ANOVA from a published partial
  eta-squared** (0.26.0). pwrss's `power.f.mixed.anova(rho.within = NA)`
  takes the noncentrality as f^2 x N, which is right for the G\*Power kind
  only after its correlation adjustment, and for a published value only
  with two measurements. A partial eta-squared as SPSS, R or JASP report
  it is the effect's sum of squares over the error sum of squares, so the
  noncentrality is f^2 x the error df: (N - groups) x (measurements - 1)
  for a within effect or the interaction, N - groups for the between
  effect. That is how Superpower's `ANOVA_exact()` relates the two, and
  how G\*Power's "As in SPSS" setting converts f (in Superpower's
  vignette, f = 0.25 with r = .8, three measurements and n = 20 becomes
  0.7024 [SP-vig]). powerkit rescales f^2 by error df / N before passing
  it, so powerkit agrees with Superpower and G\*Power rather than pwrss.
  Size of the difference: for three conditions (means 600, 620, 650, SD
  100, r = .6, 40 people; partial eta-squared 0.140), pwrss alone gives
  60.3%, powerkit and Superpower 88.8% (`test-backend-anova-eta.R`). Not a
  departure from the established tools, whose answer it now matches.
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
- **Time to event (E43): each package's own conventions, unchanged.**
  G\*Power has no survival tests, so the comparison users make is with
  the packages themselves, and powerkit calls them as they stand. The
  log-rank test is Hmisc's `cpower()`: exponential times in each group, so
  one hazard ratio throughout (the hazard ratio shown is the one the two
  proportions imply), recruitment at an even rate, and George and Desu's
  variance of the log hazard ratio from each group's expected events; two
  groups only, two-sided (its help). A measured score is powerSurvEpi's
  `powerEpiCont.default()`, Hsieh and Lavori's formula, with the hazard
  ratio per SD so the score's variance is 1. Its help calls the test
  two-sided, but its power is a single tail, `pnorm(sqrt(...) - z[1 -
  alpha/2])`, so at a hazard ratio of 1 it gives alpha / 2, not alpha;
  with any effect worth planning for the other tail adds well under 0.001.
  powerkit reports the package's number. Both formulas agree with
  simulated log-rank tests and Cox models within 0.02 at the sizes
  tested. Tests: `test-backend-survival.R`; `test-validation-survival.R`
  [powerkit, `docs/decisions.md`].
- **Reliability and agreement (E69): each package's conventions,
  unchanged.** G\*Power has no reliability tests. The ICC is
  ICC.Sample.Size's `calculateIccPower()`, Walter, Eliasziw and Donner's
  normal approximation to the F test of a one-way random-effects ICC, as
  the package computes it (one- or two-sided). Cronbach's alpha is Bonett
  and Wright's test of ln(1 - alpha), the test whose sample size
  statpsych's `size.test.cronbach()` gives; statpsych gives no power at a
  given n, so powerkit solves the same formula for power, and its
  smallest n for a power is statpsych's in every case tested. The
  formula's large-sample variance is a little small at typical sizes:
  for 5 items, alpha 0.8 against 0.7, two-sided, 85% power, it gives
  n = 139, where simulating parallel normal items (two runs of 20,000)
  gives 84.1% for Bonett's test of ln(1 - alpha) and 85.9% for the Feldt
  F interval statpsych's `ci.cronbach()` reports (13 November 2026). The
  shortfall, about a point for the test the formula plans, is
  statpsych's published method and is not shown on the result. Kappa is
  kappaSize's goodness-of-fit approach (two-sided), which gives a sample
  size, not rounded, for a power; powerkit's power at n is the power for
  which kappaSize gives n, and its sample size kappaSize's rounded up.
  The ICC and alpha formulas count only the tail in the effect's
  direction, so a two-sided test at the null value gives alpha / 2.
  Tests: `test-backend-reliability.R`; `test-validation-reliability.R`
  [powerkit, `docs/decisions.md`].
- **The Brunner-Munzel test (E2's test version): the effect when the
  spreads differ.** G\*Power has no Brunner-Munzel test, so nothing is
  departed from. Its point is that the groups may differ in spread, so the
  form asks for the ratio of the SDs (group 2 over group 1) as well as
  Cohen's d, and d is the mean difference over sqrt((SD1^2 + SD2^2) / 2),
  the average-variance standardiser, so that the same d means the same
  mean difference whatever the ratio. With a ratio of 1 the data are those
  of the Mann-Whitney version. Spower simulates both groups in the chosen
  shape and tests them with brunnermunzel's `brunnermunzel.test()` (the
  t approximation, not the permuted test). Tests:
  `test-backend-brunner-munzel.R`; `test-validation-brunner-munzel.R`
  [powerkit, `docs/decisions.md`].
- **Yuen's trimmed-means tests (E2's and E3's test version): WRS2's
  tests and default trimming.** G\*Power has no trimmed-means test, so
  nothing is departed from. powerkit follows WRS2 (Mair and Wilcox, 2020):
  20% trimmed from each end unless the user changes it (`yuen(tr = 0.2)`),
  Yuen's statistic with its Welch-type df for two groups and h - 1 df for
  paired measurements (h the number left after trimming). The effect is
  entered as for the t-test (Cohen's d or d_z, on means), and the scores
  are simulated in the chosen shape with that shift, as for the rank
  tests; for two groups the SD ratio is asked for, with d over
  sqrt((SD1^2 + SD2^2) / 2) as for the Brunner-Munzel test. With a
  symmetric shape the trimmed means differ by the same amount as the
  means; with skewed scores and unequal spreads they also differ when the
  means are equal, so the test's power then includes that difference.
  Yuen's paired test trims each measurement separately, so its power
  depends on the correlation between them, which the form asks for (no
  default: there is no neutral value); the paired t-test needs d_z alone.
  WRS2 gives two-sided p-values; a one-sided test uses Yuen's t in the
  t distribution with the same df. With no trimming the tests are Welch's
  t-test and the paired t-test (`test-validation-yuen.R` checks the paired
  case against pwr's exact power). Tests: `test-backend-yuen.R`;
  `test-validation-yuen.R` [powerkit, `docs/decisions.md`].
- **Negative binomial regression (E28's model choice): MASS's Wald test.**
  G\*Power has no negative binomial regression, so nothing is departed
  from. The counts are negative binomial with variance mu + k mu^2 (k is
  the overdispersion asked for; MASS's theta is 1 / k), with the same
  inputs as the Poisson regression otherwise: the predictor a standard
  normal score or a yes/no group of fixed size, another predictor (if
  any) overlapping with it by the R-squared given and without an effect
  of its own, as the Poisson formula assumes. Each simulated study is
  fitted by MASS's `glm.nb()`, and the test is the Wald z test of the
  predictor, one-sided if asked. With k near 0 the power is the Poisson
  formula's (pwrss), checked in the validation. Tests:
  `test-backend-negative-binomial.R`; `test-validation-negative-binomial.R`
  [powerkit, `docs/decisions.md`].
- **PERMANOVA (E59's test version): Euclidean distances between the
  standardised outcomes, where vegan defaults to Bray-Curtis.** G\*Power
  has no PERMANOVA. vegan's `adonis2()` uses Bray-Curtis dissimilarities
  by default, which are for ecological abundance data and need values of
  0 or more; for scores powerkit standardises each outcome in each data
  set and uses Euclidean distances, so that an outcome on a larger scale
  doesn't dominate, with vegan's default 999 permutations. Normal scores
  are multivariate normal, as for MANOVA; scores of another shape are each
  person's common level plus a deviation of that shape. With two factors
  the effect's sequential test (`by = "terms"`), equal to its marginal test
  with equal groups. Tests: `test-backend-permanova.R`;
  `test-validation-permanova.R` [powerkit, `docs/decisions.md`].
- **Growth curves (E35): Diggle and colleagues' formula, solved for power.**
  G\*Power has no growth-curve test. The covariance of a person's
  measurements comes from the random intercept and slope SDs, their
  correlation and the residual SD, as in `diggle.linear.power()`'s help
  example; the test is of the group x time interaction with that
  covariance known (a z test). longpower's power for a given n is found by
  root-finding that fails for small groups and returns about 0 for large
  ones, so powerkit finds the power whose required group size is the one
  asked about, from the same formula. Equal groups and complete data, as
  the formula assumes. Tests: `test-backend-growth.R`;
  `test-validation-growth.R` [powerkit, `docs/decisions.md`].
- **Moderation by a factor with three or more groups (E30): the F test of
  the X x group terms.** G\*Power's regression tests take an R-squared
  increase, not a correlation per group. In each group X is standard
  normal and Y has SD 1 and the correlation given with X, so the slopes are
  the correlations; each simulated study is fitted by `lm()` and the test
  compares the model with the X x group terms against the model without
  them (k - 1 df). Tests: `test-backend-group-moderator.R`;
  `test-validation-group-moderator.R` [powerkit, `docs/decisions.md`].
- **Moderation of a yes/no outcome (E32): the Wald z test of the product.**
  G\*Power has no logistic interaction test. Two scores X and W are
  standard normal with the correlation given; a yes/no X or W is coded 0
  and 1 and drawn on its own. The outcome is logistic in X, W and X x W,
  with the odds ratios given, so X's odds ratio is for W at its mean (or
  first group) and the interaction is a ratio of odds ratios. Each
  simulated study is fitted by `glm()` and the test is the Wald z test of
  the product's coefficient, as `summary()` reports it. Tests:
  `test-backend-logistic-interaction.R`;
  `test-validation-logistic-interaction.R` [powerkit, `docs/decisions.md`].
- **The Bayes factor of an effect in a two-factor between-participants
  ANOVA (E7, E21, E22), and since 5 November 2026 in the repeated-measures
  ANOVAs (E8, E54, E55, E20, participants a random factor with JASP's r
  scale of 1): JASP's inclusion Bayes factor.** G\*Power has no
  Bayes factors, so nothing is departed from. powerkit follows JASP's
  Bayesian ANOVA: BayesFactor's `anovaBF()` over the models that respect
  marginality, r scale 0.5, and the effect's inclusion Bayes factor across
  all models with uniform model priors (bayestestR's
  `bayesfactor_inclusion()`); across matched models is an option. Tests:
  `test-backend-bayes-anova.R`; `test-validation-bayes-factorial.R`
  [powerkit, `docs/decisions.md`].
- **Multinomial logistic regression (E70): the likelihood-ratio test by
  default.** G\*Power has no multinomial logistic regression, so nothing
  is departed from. The outcome's first category is the reference; the
  model's log odds of each other category against it are linear in the
  predictor, a standard normal score or a yes/no group of fixed size, and
  another predictor (if any) overlaps with it by the R-squared given
  without an effect of its own, as for logistic and Poisson regression.
  The effect is entered as the shares at two points or as odds ratios;
  both fix the same model. nnet's `multinom()` fits each simulated study.
  The default test is the likelihood-ratio test of the predictor, all its
  coefficients at once (K - 1 df), the test car's `Anova()` reports for a
  `multinom()` fit; the Wald z test of one category against the first is
  the alternative. A simulated study with nobody in some category can't
  be fitted and counts as not significant, as it would for the study.
  Tests: `test-backend-multinomial.R`; `test-validation-multinomial.R`
  [powerkit, `docs/decisions.md`].
- **Zero-inflated regression (E28's model choice): pscl's model with the
  predictor in both parts.** G\*Power has no zero-inflated regression, so
  nothing is departed from. Each person is an extra zero with probability
  plogis(qlogis(zero_prob) + log(zero_odds_ratio) x), and otherwise has a
  Poisson or negative binomial count with the base rate and rate ratio
  given, so the rate describes the people who could have an event (the
  count part), as in pscl's model; the predictor and any other predictor
  are drawn as for negative binomial regression. Each simulated study is
  fitted by pscl's `zeroinfl()` with the predictors in both parts (its
  default formula), and the test is the Wald z test of the predictor in the
  count part (the default) or the zero part, or the likelihood-ratio test
  of both (2 df). A simulated study with no zeros or no counts above 0, or
  whose fit fails, counts as not significant. Tests:
  `test-backend-zero-inflated.R`; `test-validation-zero-inflated.R`
  [powerkit, `docs/decisions.md`].
- **The aligned rank transform (E7, E21 and E22's test version): ARTool's
  Type III tests.** G\*Power has no aligned rank transform, so nothing is
  departed from. Each cell's scores are its mean plus its SD times a draw
  of the chosen shape, as the cell means and SDs are entered for the
  ANOVA. The test is ARTool's: `art()` aligns and ranks the scores for
  each effect, and the effect's F test is the Type III row its `anova()`
  reports (sum-to-zero contrasts), which powerkit reads through
  `artlm()` and car's `Anova(type = 3)` for the one effect tested; a test
  shows the two agree, with equal and unequal cells. Tests:
  `test-backend-art.R`; `test-validation-art.R` [powerkit,
  `docs/decisions.md`].
- **The aligned rank transform with a within-participants factor (E8, E55
  and E20's test version): ARTool's repeated measures model.** Nothing in
  G\*Power to depart from. Each person's scores are drawn as Friedman's
  test draws them: the cell's mean plus its SD times (sqrt(r) times the
  person's own level plus sqrt(1 - r) times a deviation of the chosen
  shape), so one correlation holds between any two of their scores (one
  per group in the 2 x 2 mixed design), and sphericity holds. ARTool's
  help analyses repeated measures with a random intercept for each person
  (`art(y ~ a * b + (1 | id))` and its `anova()`, Kenward-Roger F tests);
  with equal groups powerkit uses the error-term form ARTool also allows
  (`Error(id)`, `aov()`), which gives the same p-values in a balanced
  design (a test checks it) several times faster. With unequal groups,
  where `aov()`'s sequential sums of squares would differ from Type III for
  the within factor's main effect, powerkit uses the random-intercept
  model and car's `Anova(type = 3)` with Kenward-Roger F tests (pbkrtest).
  Tests: `test-backend-art-within.R`; `test-validation-art-within.R`
  [powerkit, `docs/decisions.md`].

### 8. MANOVA: simulated, where G\*Power uses a formula

- **What differs:** G\*Power computes Hotelling's T-squared for one or two
  groups exactly and MANOVA's global effect (Pillai's V) for three or more
  groups with an F approximation. powerkit simulates MANOVA with Spower
  and its own experiment, `p_manova()` (multivariate normal scores,
  `stats::manova()`, Pillai's trace), because no package powerkit builds
  on has a formula. The answer carries Monte Carlo error.
- **One and two groups (retired 31 October 2026):** Hotelling's
  T-squared, for one group against fixed values (E60) and for a MANOVA of
  two groups (E59), is now computed exactly, by its noncentral F
  distribution (Anderson, 2003, sections 5.3.4 and 5.4;
  `backend-hotelling.R`), as G\*Power computes it, under CLAUDE.md's rule
  on published formulas. The simulations (`p_hotelling_one()`,
  `p_manova()`) stay available on request, and this difference applies
  only to three or more groups, with the effect given by the means.
- **Pillai's V (12 November 2026):** a MANOVA given by Pillai's V instead
  of means is computed by G\*Power's own formula (Faul et al., 2007,
  Table 5, Pillai's V with the O'Brien and Shieh algorithm the paper
  recommends; `pillai_backend()`), so this difference doesn't apply to it.
  It agrees with Spower's simulation of the same MANOVA from means whose
  population V is known (`test-backend-pillai-v.R`), and with two groups
  it equals the exact Hotelling's T-squared. O'Brien and Shieh is
  G\*Power 3.1's default in its Options for this test (checked in G\*Power
  3.1, 12 November 2026); it can also be set to Muller and Peterson's
  (1984) algorithm, which the paper says underestimates power, and
  powerkit doesn't offer that.
- **Size:** with two groups, the Monte Carlo error alone: 0.393 simulated
  against 0.392 exact (pwrss's F test of R-squared, which equals two-group
  Hotelling's T-squared) for three outcomes correlated 0.4 and N = 100.
  With one group, the same: 0.620 simulated (500 replications) against
  0.6195 exact (pwrss's generic F test with noncentrality n times the
  Mahalanobis distance) for the example in `inst/specs/hotelling_one.json`
  at N = 40.
  With two factors (31 October 2026), each effect is simulated the same
  way, from `stats::manova(y ~ A * B)`; G\*Power's "special effects and
  interactions" MANOVA uses an approximation, not compared yet.
  With three or more groups, the gap between G\*Power's approximation and
  the simulated power is not measured yet; the G\*Power example in the
  validation file will measure it once transcribed.
- **Test:** `engine/tests/testthat/test-validation-manova.R` (two G\*Power
  examples to transcribe; the exact two-group check; a separately written
  simulation; Type I error), `test-validation-hotelling-one.R` (a G\*Power
  example to transcribe; the exact one-group check; Type I error),
  `test-backend-manova-oneway.R` and `test-backend-hotelling-one.R`.
- **Shown to users:** on the MANOVA result screen
  (E59) with three or more groups (`known_differences_if_groups_above`), under "Where
  other established tools give a different answer"
  (`app/routing/forms.yaml`, `known_differences`, key "8").
- **Methods paragraph:** "Power was estimated by simulation, so it carries
  Monte Carlo error; G\*Power computes Hotelling's T-squared exactly and
  Pillai's trace with an F approximation." (`known_differences_methods`,
  key "8").

### 9. Meta-analysis: metapower's rounding for r, and an estimated between-study variance

- **What differs:** for a correlation, metapower's `mpower()` rounds
  Fisher's z to two decimals before computing power. Under the
  random-effects model it uses Jackson and Turner's (2017) equation 9,
  which allows for the between-study variance being estimated; the
  formulas in Valentine, Pigott and Rothstein (2010) treat it as known.
  powerkit follows metapower, the package it calls, and states both. G\*Power
  has no meta-analysis.
- **Size:** the rounding moves power by up to about 1.3 points: 85.6%
  against 84.3% with the exact z for r = 0.25 in five studies of 30 (the
  largest over r .05 to .3, 30 to 100 per study, 5 to 20 studies and
  I-squared 0 to .75). In Valentine et al.'s random-effects example (d =
  0.15, 20 per group, 40 studies, moderate heterogeneity, one-sided) the
  paper gives 0.68 and powerkit 68.3%.
- **Not used:** metapower's power for the test of heterogeneity, which
  disagrees with simulation (`docs/upstream-questions.md`, metapower).
- **Applies only to metapower's z test:** the Hartung-Knapp test, the
  default since 31 October 2026 (Departure 18), is simulated from the
  exact Fisher's z and doesn't round.
- **Test:** `engine/tests/testthat/test-backend-metapower.R` (the rounding's
  size), `test-validation-meta-analysis.R` (simulated meta-analyses; the
  two Valentine et al. examples to transcribe).
- **Shown to users:** on the meta-analysis result screen (E61), under
  "Where other established tools give a different answer"
  (`app/routing/forms.yaml`, `known_differences`, key "9").
- **Methods paragraph:** `known_differences_methods`, key "9".

### 10. Minimum-effect tests: a margin in SD units, slightly below a margin in the outcome's units (retired 12 November 2026: powerkit plans the shifted test)

- **What differed:** from 31 October to 12 November 2026 a minimum-effect
  test (the t-test cards' test version "minimum_effect") was computed with
  pwrss's `power.t.student()` with its `margin` argument, which tests the
  t statistic against a noncentral t whose noncentrality is the margin
  divided by the standard error: the test of a smallest effect of interest
  held fixed in SD units. The test researchers run holds the margin fixed
  in the outcome's own units, `t.test(mu = margin)` or TOSTER's
  `t_TOST(hypothesis = "MET")`: a central t shifted by the margin. Its
  power is slightly higher, so the earlier sample sizes were a few too
  large. powerkit now plans the shifted test, as it does for
  non-inferiority (11 November 2026), and this is no longer a difference.
  G\*Power has no minimum-effect test.
- **Size, for the record:** for 57 per group, d = 0.5 and a margin of 0.2
  (one-sided, alpha .05): 47.9% now against 47.2% before; for 80% power,
  278 in total against 282. The smallest detectable d for 57 per group is
  0.6686 now, 0.6735 before.
- **Test:** `engine/tests/testthat/test-backend-minimum-effect.R`,
  "pwrss's own margin argument, a margin in SD units, gives slightly less
  power (Known difference 10, retired)" (the size), "the power is the
  exact power of t.test(mu = margin), a central t shifted by the margin"
  and "a simulation of t.test(mu = margin) agrees with the formula".
- **Shown to users:** no longer listed on any card; the note
  (`app/routing/forms.yaml`, `known_differences`, key "10") is kept for
  results saved before then.

### 11. Justified alpha: minimising the weighted errors by default, where G\*Power's compromise balances them

- **What differs:** a justified alpha (goal "justified_alpha", 31 October
  2026) is found with JustifyAlpha's `optimal_alpha()`, whose default,
  `error = "minimize"`, chooses the alpha that makes the weighted total of
  the two error rates smallest. G\*Power's compromise power analysis takes
  the ratio q = β/α and finds the alpha at which beta is q times alpha
  (`docs/decision-tree.md`, analysis types): the same as `optimal_alpha()`
  with `error = "balance"`, `costT1T2 = q` and `priorH1H0 = 1`. powerkit
  follows JustifyAlpha's default and offers the balanced version as a
  choice ("Make the weighted errors equal").
- **Size:** for d = 0.5 and 64 people in two equal groups (two-sided,
  equal weights), alpha is .184 (power 74.5%) when minimising and .221
  (power 77.8%) when balancing.
- **Test:** `engine/tests/testthat/test-backend-justify-alpha.R`,
  "minimising the weighted errors gives a lower alpha than balancing them,
  as G\*Power's compromise does (Known difference 11)".
- **Shown to users:** on the one-sample, paired, two-group and correlation
  result screens when the goal is a justified alpha
  (`app/routing/forms.yaml`, `known_differences`, key "11").
- **Methods paragraph:** `known_differences_methods`, key "11".

### 12. Bayes factor test of a correlation: JASP's prior width, where BayesFactor's default is narrower

- **What differs:** the Bayes factor is BayesFactor's `correlationBF()`,
  whose stretched beta prior on rho has width `rscale`, "medium" (1/3) by
  default. JASP's Bayesian correlation, which most psychologists analyse
  with, uses width 1 (a uniform prior on rho) by default. powerkit follows
  JASP and offers any width ("Prior width"); at the same width the two
  give the same two-sided Bayes factor (tested to eight digits against
  JASP's exact formula).
- **Size:** for r = .3, BF10 of at least 10 and 80% (two-sided), 162
  people at JASP's width and 146 at BayesFactor's default.
- **Test:** `engine/tests/testthat/test-backend-bayes-correlation.R`,
  "JASP's prior width (1) against BayesFactor's default (1/3): the size of
  the difference".
- **Shown to users:** on the correlation result screen when the Bayes
  factor test is chosen (`app/routing/forms.yaml`, `known_differences`,
  key "12").
- **Methods paragraph:** `known_differences_methods`, key "12".

### 13. One-sided Bayes factor test of two proportions: an exact posterior probability, where JASP estimates it

- **What differs:** JASP's one-sided Bayes factor for a 2 x 2 table is the
  two-sided one times the posterior probability that group 1's proportion
  is the higher (or the lower), over its prior probability, 0.5. JASP
  estimates that probability from 10,000 draws from the posterior
  (`BayesFactor::posterior()`), so its one-sided Bayes factor changes a
  little with the seed. powerkit uses the same rule with the probability
  integrated exactly from the two Beta posteriors. The two-sided Bayes
  factor is the same in both.
- **Size:** for 20 of 50 against 30 of 50, JASP's estimate of the
  probability varies by about 0.1% (SD of the log ratio below 0.002), and
  its average equals the exact value to three decimals.
- **Test:** `engine/tests/testthat/test-backend-bayes-proportions.R`,
  "Known difference 13: JASP's one-sided Bayes factor estimates the
  posterior probability from 10,000 draws".
- **Shown to users:** on the two-proportion result screen when the Bayes
  factor test is chosen (`app/routing/forms.yaml`, `known_differences`,
  key "13").
- **Methods paragraph:** `known_differences_methods`, key "13".

### 14. Mediation: a Monte Carlo interval, where PROCESS reports a percentile bootstrap

**10 November 2026:** the method is now selectable on the mediation forms.
The existing ML/Monte Carlo method remains available; a researcher planning
a regression/bootstrap analysis can choose OLS + casewise percentile
bootstrap. This known-difference note applies only to the Monte Carlo
choice. The historical timing below concerns ML bootstrapping and must not
be read as a timing estimate for the new OLS method. Numerical identity to
every PROCESS option is not established.

- **What differs:** powerkit plans mediation and moderated mediation for
  power4mome's Monte Carlo confidence interval of the indirect effect (or
  of the index), which draws the paths from their estimated sampling
  distribution. PROCESS, the software most researchers analyse with,
  reports a percentile bootstrap interval by default, which refits the
  model to resampled data. The two are different tests of the same
  effect. powerkit keeps the Monte Carlo interval because a bootstrap
  refits the model for every draw of every simulated study, which is far
  too slow to plan with (more than 15 seconds for each simulated study on
  one core, against about 0.4 seconds).
- **Size:** measured by
  `test-validation-mediation-crosscheck.R`, "the Monte Carlo interval's
  power matches the percentile bootstrap's" (simple mediation, a = b = 0.3,
  c' = 0.1, n = 100), in the weekly run of the `mediation_crosscheck`
  chunk. The first result is recorded in `validation-log.md`, "Independent
  cross-check for mediation".
- **Shown to users:** on every mediation result planned with the Monte
  Carlo interval (`app/routing/forms.yaml`, `known_differences`, key
  "14").
- **Methods paragraph:** `known_differences_methods`, key "14".

### 15. ANCOVA from adjusted means: Shieh's method treats the covariate as random, where G\*Power treats it as fixed

- **What differs:** the ANCOVA card (E23) plans from the adjusted group
  means with pwrss's `power.f.ancova.shieh()`, Shieh's (2020) method,
  which allows for the covariate being random, as it is in most studies
  (people arrive with their own before scores). G\*Power's ANCOVA treats
  the covariate as fixed (lambda = f^2 N, error df N minus the groups
  minus the covariates), which gives a little more power and so a slightly
  smaller sample size. This was recorded under "ANCOVA" above but not
  shown on the result until 12 November 2026.
- **Size:** for adjusted means 20, 18 and 16, SD 6 and one covariate
  explaining 36%, 81.3% (Shieh) against 81.8% (fixed) with 90 people
  (`engine/tests/testthat/test-backend-anova-eta.R`, "an ANCOVA from its
  means (Shieh's method) and from the same partial eta-squared (G*Power's)
  differ a little"). A pre-release comparison found 90 against
  G\*Power's 87 for a three-group example.
- **Shown to users:** on every E23 result (`app/routing/forms.yaml`,
  `known_differences`, key "15").
- **Methods paragraph:** `known_differences_methods`, key "15".

## All-tests sufficient power target under unknown dependence

For a claim requiring every one of k tests to succeed, let F_i denote
failure of test i. The union bound gives P(any F_i) <= sum P(F_i).
Consequently, making every marginal failure probability no larger than
(1 - target)/k is sufficient for P(all succeed) >= target. This yields
per-test power 1 - (1-target)/k. It can be conservative, and is distinct
from the independence rule target^(1/k). It never raises alpha.

Source: Blitzstein and Hwang (2019), doi:10.1201/9780429428357,
`BlitzsteinHwang2019_probability` in refs.bib; the union-bound statement
was independently checked in the online Probability Course textbook,
section 6.2.1. The formula above is its direct complement-event derivation.
The default independence option and older saved files retain their previous
rule. Result notes and methods text name the selected rule. For target .8
and two tests, the targets differ: .894427 under independence versus .9
without it. G*Power has no joint-claim planner to benchmark this bound;
individual test power continues to use its existing backend.

Tests independently simulate independent events and disjoint failure
couplings attaining the worst-case bound. A lower-bound guarantee needs
unconditional successful-test probabilities under a common stipulated
population. Conditional power among valid fits alone does not establish
that guarantee when fits fail; this rule does not fix missingness,
model misspecification or convergence problems.
## Simulation outcomes and denominator conventions

Simulation provenance records each recorded sample size's attempted,
valid, failed and successful decisions. Power4mome's reported rejection
rate conditions on valid analyses; simr's rate includes failed decisions
as unsuccessful attempts. These backend conventions are retained rather
than silently changing the planning result. The record also exposes
successful / valid and successful / attempted, with the former undefined
when no decisions are valid. Warnings alone are not classified as failed
simr decisions when a finite p-value is returned.

For example, 720 successes among 900 valid decisions in 1,000 attempts
mean 80% conditional success and 72% success per attempted study. Results
and copied methods identify both when failures occur. Monte Carlo precision
of a reported rate is separate from fitting failures. Historical saved
records without these counts do not receive invented zero-failure counts.


## Welch planning with unequal population SDs

For unequal-SD two-group Welch planning, the population difference is
`d_RMS = (mean2 - mean1) / sqrt((SD1^2 + SD2^2)/2)`. This fixed population
scale is independent of allocation. Equal SDs recover the existing d.
Raw inputs retain both means and SDs and derive d_RMS and SD2/SD1.

Spower 0.7's `p_t.test()` and `gen_t.test()` already accept `sds`; the
adapter passes both SDs in RMS units, and retains the existing sign
convention (group 1 has mean -d_RMS, group 2 has mean 0).
The pwrss 1.3.3 Welch formula instead defines d using the expected
sample-size-weighted pooled SD. At every actual allocation the adapter
uses pwrss's own `means.to.d()` to change units, and passes `var.ratio`
as SD1 squared / SD2 squared and `n.ratio` as n1/n2. No power formula is
reimplemented. Its Welch-Satterthwaite calculation is an approximation.

Sources checked 5 November 2026: pwrss 1.3.3 installed source of
`power.t.welch()` and `means.to.d()`, Spower 0.7 installed source of
`gen_t.test()`, and the author's help at
<https://metinbulus.github.io/pwrss/reference/means.student.welch.html>
and <https://metinbulus.github.io/pwrss/reference/means.to.d.html>.
Package citations remain available through citation().

The `welch_spreads` validation chunk compares the formula with separately
generated normal samples analysed by base R's Welch t-test at both
allocation orientations, and checks the actual simulation and null error
rate at 10,000 replications. Formula comparisons allow four Monte Carlo
standard errors plus 0.01 for the approximation. This is a scoped check,
not evidence for arbitrary shapes, missingness or all variance ratios.
G*Power's common-SD t-test is not an unequal-variance Welch benchmark.

The two SDs, standardisation and normal-score assumption appear in the
result/write-up and reproduction scripts. Point-biserial, test-statistic
conversion and safeguard shortcuts are refused for unequal-SD Welch
populations because their equal-SD inputs do not identify this effect.


## Planning decisions, scenarios and numerical accuracy

A directional scientific prediction does not determine whether the statistical
test is one- or two-sided. The form asks which directions count for the
precommitted decision and explains that rejecting in the opposite direction
need not support the prediction. Nonzero significance, exceeding a worthwhile
threshold, equivalence, precision and overall SEM fit versus a target path
are separate planning questions. No test formula changes in this interface
clarification. A minimum-effect test needs both the threshold and an expected
effect beyond it; ordinary power at that threshold does not test exceedance.

Simulation presets are 400, 1,000 and 10,000 repeated studies per sample-size
point (rough worst-case pointwise 95% margins of 5, 3 and 1 percentage points,
respectively, with valid independent decisions). They do not express parameter
uncertainty, convergence reliability or an adaptive search's accuracy. The
result's actual interval, valid/failed counts and denominator remain
controlling. Missing preset answers retain earlier replication settings;
custom counts are available only when selected. Expected precision width is
an average, not a maximum-width or probability guarantee; assurance is stated
separately where the backend supports it.

Basic-test simulations with more than 1,000 repetitions use the existing
background runner so the screen stays responsive and Cancel is available.
The usual short basic simulation keeps its direct route; formulas do not
start a simulation job merely because an accuracy choice was saved.

Input-source records are user assessments: reported, derived, assumed or
unknown. An unknown input has no number; changed values invalidate the match
to a recorded source. Named alternatives retain their input/source snapshots
in the same project/draft metadata. Formula comparisons validate every plan
before calculation and use existing engine calls; simulation alternatives
must be loaded and run separately. They do not add missing-data or arbitrary
score-shape support. The decision document uses the captured calculation,
not live edited inputs, and is a reviewable planning draft rather than a
registered preregistration.


Input guides are checked for every numeric/list/table field in the declared
forms. Specialist identifiers override keyword families: Cronbach's alpha is
not significance alpha, a hazard ratio mentioning a predictor SD is not an
SD input, negative-binomial overdispersion is not raw variance, and structural
extra-zero probability is not the observed zero fraction. Existing field help
retains model-specific parameterisations. Illustrations are not defaults or
recommended assumptions; binary and product-term coding/scaling follow the
selected model rather than a generic standardised-coefficient shortcut.

### All-tests-required planning default (10 November 2026)

New input screens use the existing unknown-dependence sufficient union-bound
target instead of assuming independent significance decisions. The product
rule remains an explicit option. This changes no significance level and does
not estimate actual joint power. Saved plans without a dependence field used
the historical product rule: reopening restores that explicit choice rather
than silently recalculating under the new default. For two tests and an 80%
joint target the new per-test target is 90%, versus sqrt(.8), approximately
89.44%, under independence. Results and methods identify the rule; every
required test must still be planned under common population assumptions.
The existing Blitzstein & Hwang (2019) source and engine implementation are
unchanged.
