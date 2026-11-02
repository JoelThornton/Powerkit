# Input and output parity with G\*Power (E1–E14)

*Last updated: 25 October 2026.*

For each end point powerkit runs, what a user can enter and what they get
back, set against the matching G\*Power test. It records gaps; nothing
here changes what powerkit does.

**Parity here means what a researcher can enter and read, not that
G\*Power is the standard of correctness.** Where its method is the weaker
one, powerkit's answer should differ and say why
([`conventions.md`](conventions.md)); a "Gap" in the tables below is a
prompt to ask whether the thing is worth having, not an instruction to
copy it. The decisions it raises are judgement
calls G4–G6 in [`judgement-calls.md`](judgement-calls.md).

## Sources and limits

- **powerkit:** the input screens (`app/routing/forms.yaml`, and the
  fields every screen adds in `app/routing/R/forms.R`) and the result
  object (`run_spec()`'s help, `engine/R/run.R`), as on `main` after PR
  #34 (pwr's formula for E1–E6, Spower simulation as an option).
- **Backends:** the help pages of pwr 1.3-0, Spower 0.7, Superpower
  0.2.4.1, InteractionPoweR 0.2.4 and power4mome 0.2.1 (CRAN sources,
  opened 17 October 2026).
- **G\*Power:** the G\*Power 3.1 manual, version of June 1, 2023,
  supplied by the maintainer on 17 October 2026. Cells cite it as
  "section N, p. P". The manual's section titles are not the Tests-menu
  names used here, so each end point names the section it was matched
  to. No G\*Power program or screen was used; nothing here is written
  from memory of G\*Power.
- **G\*Power screenshots:** G\*Power 3.1.9.7, sent by the maintainer on
  17 October 2026 for the tests the manual doesn't cover. They are in
  [`figures/gpower/`](figures/gpower/), and cells cite them as
  "screenshot". Where a dialog is shown, the setting is as it was in the
  maintainer's copy; whether that is the program's default is said only
  where the screenshot shows a fresh dialog.
- **Not in the manual:** the manual says it "is not yet complete". It has
  no section for the z test of two independent proportions (E5), for a
  chi-square test of a contingency table (E6), or for repeated measures
  ANOVA (E8). The maintainer's screenshots now cover E5, E8 and the E4
  options dialog. E6 is still "to confirm (not in the 2023 manual;
  screenshot needed)".

**Marks** for powerkit's side:

| Mark | Meaning |
| --- | --- |
| **Has** | powerkit has it |
| **Not exposed** | the backend supports it, powerkit doesn't expose it |
| **Not possible** | not possible with this backend (for example, no noncentrality parameter from a simulation) |
| **n/a** | doesn't apply to this test |

**Common to every end point** (not repeated below): alpha (**Has**, default
0.05 from the backend's own default); target power for "the sample size I
need" (**Has**); N for "the power I'd have" (**Has**, total N); attrition
(asked and stored, but not yet applied: no recruitment target is shown); seed (**Has**,
for simulation). Sensitivity ("the smallest effect I could detect") is
**Has** for E7 and E8 only; for E1–E6 pwr supports it (any one argument
left `NULL` is solved for) and for E9–E14 the backends support it by a
search over effect sizes, so it is **Not exposed** there. Criterion (alpha
from power and N) is **Not exposed** for E1–E6 (pwr solves for
`sig.level`; Spower with `sig.level = NA`) and unknown for the rest.
Compromise is **Not exposed** for Spower (`beta_alpha`) and Superpower
(`ANOVA_compromise()`), and not offered by pwr; for E1-E4 it is
**Exposed** as the justified alpha (JustifyAlpha's `optimal_alpha()` on
pwr's power; its "balance" rule is the compromise analysis, 31 October
2026). G\*Power offers five
types of analysis: a priori, compromise, criterion, post hoc and
sensitivity (manual, section 1.1, p. 2).

**Outputs common to every end point:**

| Output | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Power | Yes: "Power (1-β err prob)" in post hoc results (for example section 11.3.1, p. 27) | Power at N | **Has** | |
| Required N | Yes: "Total sample size"; the two-group t test also shows "Sample size group 1" and "Sample size group 2" (section 1.2.3, p. 4) | Total N (and per group in the headline for two-group tests) | **Has** | |
| Actual power at the rounded N | Yes: "Actual power" in a priori results. Non-integer sample sizes "are always rounded up" (section 1.2.3, p. 4) | Shown for exact results ("With 64 per group, power is 80.1%."); not for a simulated N | **Has** (exact results) | Judgement call G5, decided 17 October 2026 |
| Noncentrality parameter | Yes for t tests (δ) and F tests (λ) (sections 1.2.3, 11, 14, 16, 19, 20). The exact correlation example shows none (section 3.3, p. 9) | "Technical details" on the result screen, where the package reports it | See each end point | Not returned by pwr's functions (their value is the arguments plus power, "method" and "note"); none for a simulation |
| Critical value | Yes: critical t (sections 16, 19, 20), critical F (sections 11, 14), lower and upper critical r (section 3.3, p. 9) | As above | See each end point | As above |
| df | Yes: df for t tests; numerator and denominator df for F tests (sections 11, 14, 19, 20). None in the exact correlation example (section 3.3) | As above | See each end point | pwr takes df as an input for the chi-square test only |

The result screen's "Technical details" (29 October 2026) show the
statistic, df, critical value and noncentrality wherever the package
reports them (pwrss and the generic tests, for example), and say so where
it doesn't: semPower's chi-square tests too since 1 November 2026, and the
correlation's critical t from Perugini et al.'s (2025) closed form, the
same critical t pwr uses. TOSTER and powertools return none.

## E1: one-sample t-test

Matching G\*Power test: Means, "One group: difference from constant".
Manual section 20, "t test: Means - difference from constant (one sample
case)", pp. 50–51.

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Tails | Yes: "Tail(s)", one or two (section 20.3, p. 50) | Two-sided, greater, less | **Has** | pwr and Spower `alternative` |
| Effect size | d = (μ − μ0)/σ (section 20.1, p. 50) | Cohen's d | **Has** | |
| Effect size from means and SD | Yes: the "Determine" drawer takes "Mean H0", "Mean H1" and "SD σ" (section 20.1, p. 50, Figure 27) | — | **Not exposed** | Spower `p_t.test()` takes `means` and `sds`; pwr takes d only |
| Non-zero null value | n/a: d is relative to μ0, which the drawer's "Mean H0" sets (section 20.1) | — | n/a | |
| Allocation | n/a | — | n/a | |
| Method | "This test has no options" (section 20.2, p. 50) | Formula (pwr) or simulation (Spower) | **Has** | |

Outputs: G\*Power shows noncentrality parameter δ, critical t, df, total
sample size and actual power (section 20.3, p. 50). powerkit:
noncentrality, critical value, df: **Not possible** (pwr `pwr.t.test()`
doesn't return them; Spower simulates).

## E2: independent-samples t-test

Matching G\*Power test: Means, "Two independent groups". Manual section
21, "t test: Means - difference between two independent means (two
groups)", p. 52 (no worked example there), and the two-group example in
section 1.2.3, p. 4.

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Tails | Yes: "Tail(s)" (section 1.2.3, p. 4) | Two-sided, greater, less | **Has** | |
| Effect size | d = (μ1 − μ2)/σ (section 21.1, p. 52) | Cohen's d | **Has** | |
| Effect size from means and SDs | Yes: the drawer has two options. "n1 != n2" takes "Mean group 1", "Mean group 2" and "SD σ within each group"; "n1 = n2" takes the two means and "SD σ group 1", "SD σ group 2" (section 21.1, p. 52, Figure 28) | — | **Not exposed** | Spower `p_t.test(means, sds)` |
| Effect size as r (point-biserial) | Separate test: section 16, "t test: Correlation - point biserial model", pp. 40–41, shown in the main window as "Correlation: Point biserial model" (Figure 1, p. 3). It takes total sample size only (section 16.3, p. 40) | — | **Exposed** (31 October 2026): E2 takes r (`population > metric` "point_biserial"), converted to d for the planned allocation, which gives the point-biserial model's power at any allocation | Spower `p_t.test(r = )` |
| Allocation ratio | Yes: "Allocation ratio N2/N1" (section 1.2.3, p. 4) | Size of group 2 / group 1 | **Has** | pwr `pwr.t2n.test()` |
| Unequal variances (Welch) | No: "The t-test assumes the variances in both populations to be equal", and "This test has no options" (sections 21.1 and 21.2, p. 52). With equal n the drawer can average two SDs as σ′ = √((σ1² + σ2²)/2) | Student or Welch | **Has** | Welch is simulation only (pwr has none) |
| Method | No options (section 21.2) | Formula or simulation | **Has** | |

Outputs: G\*Power shows noncentrality parameter δ, critical t, df,
sample size of each group, total sample size and actual power (section
1.2.3, p. 4). powerkit: noncentrality, critical value, df: **Not
possible**.

## E3: paired-samples t-test

Matching G\*Power test: Means, "Two dependent groups (matched pairs)".
Manual section 19, "t test: Means - difference between two dependent
means (matched pairs)", pp. 48–49.

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Tails | Yes: "Tail(s)" (section 19.3, p. 48) | Yes | **Has** | |
| Effect size | d_z = \|μz\|/σz (section 19.1, p. 48) | d_z | **Has** | |
| d_z from means, SDs and their correlation | Yes: the drawer works "from differences" ("Mean of difference", "SD of difference") or "from group parameters" ("Mean group 1", "Mean group 2", "SD group 1", "SD group 2", "Correlation between groups") (section 19.1, p. 48, Figure 25) | — | unknown | Spower `p_t.test()`'s `r` is a point-biserial correlation, not the correlation between the two measures; no d_z calculator found in pwr or Spower help |
| Method | "This test has no options" (section 19.2, p. 48) | Formula or simulation | **Has** | |

Outputs: G\*Power shows noncentrality parameter δ, critical t, df and
power (section 19.3, p. 48). powerkit: noncentrality, critical value,
df: **Not possible**.

## E4: Pearson correlation

Matching G\*Power test: Correlation and regression, "Correlation:
bivariate normal model". Manual section 3, "Exact: Correlation -
Difference from constant (one sample case)", pp. 9–10. The manual
doesn't give this test's Tests-menu name; it describes the test of ρ = ρ0
for "two bivariate normally distributed random variables", which is
matched here to "Correlation: bivariate normal model".

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Tails | Yes: "Tail(s)" (section 3.3, p. 9) | Yes | **Has** | |
| Effect size | "Correlation ρ H1" (section 3.3, p. 9) | r | **Has** | |
| Null value ρ H0 | Yes: "Correlation ρ H0"; the worked example uses 0.60 (section 3.3, p. 9) | 0 only | **Not exposed** with Spower (`p_r(rho = )`); **Not possible** with pwr (`pwr.r.test()` has no null value) | With Spower 0.7, a non-zero `rho` gives a two-sided p-value whatever `alternative` says (`R/p_r.R`) |
| Method | The options dialog offers "Use exact distribution if N < x" or "Use large sample approximation (Fisher Z)" (section 3.2, p. 9). The worked example sets x = 10000 (section 3.3). The dialog as it opened in the maintainer's copy has "use exact distribution if N < 10000" selected (screenshot `E4_options_default.png`), so G\*Power uses the exact method for any N below 10,000 | Formula (pwr: Fisher's z) or simulation (Spower: Monte Carlo of the exact t test of ρ = 0) | **Has** (both) | Size of the difference: judgement call G6. Fisher's z kept: Departure 10 (`conventions.md`) |

Outputs: G\*Power shows lower and upper critical r (or z when the
approximation is used), total sample size and actual power (sections 3.2
and 3.3, p. 9). powerkit: critical r, df: **Not possible** with pwr (it
uses a critical value internally but doesn't return it).

## E5: two proportions

Matching G\*Power test: z tests, "Proportions: Difference between two
independent proportions" (screenshots `E5_z_test_*.png`). The manual has
no section for it. G\*Power also has Fisher's exact test (Exact,
"Proportions: Inequality, two independent groups (Fisher's exact
test)"; section 6, p. 17, and screenshot `E5_fisher_exact_a_priori.png`),
which powerkit doesn't run.

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Tails | Yes: "Tail(s)" (screenshot) | Yes | **Has** | |
| Effect size | "Proportion p1" and "Proportion p2"; the options dialog can switch the input to "Cohen's effect size index h" (screenshot) | p1, p2 | **Has** | h as input: **Not exposed** |
| Allocation ratio | Yes: "Allocation ratio N2/N1" (screenshot) | Yes | **Has** | |
| Continuity correction | Option "Use continuity correction", off in the maintainer's copy (screenshot) | No correction (Departure 5) | **Not exposed** (Spower `correct = TRUE`) | Departure 5 matches G\*Power |
| Arcsine transformation | Option "Use arcsin transform", off in the maintainer's copy (screenshot) | Off by default; pwr's Cohen's h on request (`options > proportions_formula = "arcsine"`) | **Has** | Departure 11 |
| Exact test | Separate test. Fisher's exact test: effect size by "directly specifying the two proportions π1 and π2", and "This test has no options" (sections 6.2 and 6.3, p. 17). Its "Determine" drawer computes p1 from a difference, ratio or odds ratio (screenshot) | — | **Not exposed** (Spower `exact = TRUE`) | Judgement call 3.9. Screenshot values, one tail, p1 = .5, p2 = .6, α .05, power .95: 557 + 557 = 1114, actual power 0.9500348, actual α 0.0448913 |
| Method | z test with the default options (screenshot) | Formula, the same z test: `stats::power.prop.test(strict = TRUE)` for equal groups, `pwrss::power.z.twoprops(std.error = "pooled")` for unequal groups; or simulation (Spower: `prop.test()`) | **Has** | See the check below. Judgement call G6; Departure 11 |

**Check against base R (17 October 2026).** G\*Power's z test with its
default options equals `stats::power.prop.test(strict = TRUE)` (R 4.3.3)
to the seven decimals G\*Power shows. Two-sided, α = .05, p1 = .10, p2 =
.25:

| Case | G\*Power (screenshot) | `power.prop.test(strict = TRUE)` (powerkit's default with Departure 11) | `strict = FALSE` (its default) | pwr arcsine (powerkit's earlier default) |
| --- | --- | --- | --- | --- |
| Post hoc, 20 per group | 0.2344921 | 0.2344921 | 0.2339595 | 0.2477934 |
| A priori, power .95, equal groups | 164 + 164, actual power 0.9502464 | 164 per group; 0.9502464 at 164 | | 160 per group |
| A priori, power .95, N2/N1 = 2 | 123 + 247 = 370, actual power 0.9498668 | Equal groups only; pwrss (powerkit's choice for unequal groups) gives 0.9498668 at 123 and 247, and powerkit's required N is 372 (124 + 248) | | 120 + 240 = 360 |

- G\*Power counts rejections in both tails, as `strict = TRUE` does.
- With unequal groups, the same z test (pooled variance under the null,
  unpooled under the alternative) gives 0.9498668 at 123 and 247.
  `pwrss::power.z.twoprops(std.error = "pooled")` (pwrss 1.3.3)
  reproduces that power, but its a-priori answer is 124 + 247 = 371
  (power 0.9509). G\*Power's 123 + 247 is slightly under the target
  power (0.9498668 < .95), so G\*Power rounds the groups differently.

**Check of pwrss against G\*Power at unequal allocations (17 October
2026).** G\*Power 3.1.9.7 screenshots from the maintainer
([`figures/gpower/`](figures/gpower/), `E5_z_test_post_hoc_ratio*`,
`E5_z_test_a_priori_ratio3`, `E5_z_test_post_hoc_one_tail_n50`). α = .05,
n1 = 100 unless stated; "up" is p1 .10, p2 .25 and "down" is p1 .25, p2
.10. pwrss is `power.z.twoprops(std.error = "pooled")`, pwrss 1.3.3. All
are tests in `engine/tests/testthat/test-backend-pwr.R`.

| Case | G\*Power (screenshot) | pwrss / powerkit |
| --- | --- | --- |
| Post hoc, two tails, n2 = 200, up | 0.8960412 | 0.8960412 |
| Post hoc, two tails, n2 = 200, down | 0.9087742 | 0.9087742 |
| Post hoc, two tails, n2 = 300, up | 0.9292662 | 0.9292662 |
| Post hoc, two tails, n2 = 300, down | 0.9388485 | 0.9388485 |
| Post hoc, one tail, n2 = 200, up | 0.9473235 | 0.9473235 |
| A priori, two tails, power .80, N2/N1 = 3, up | 70 + 210 = 280, actual power 0.8003695 | 70 + 210 = 280; 0.8003695 at 280 |
| Post hoc, one tail, equal groups (50 + 50), p1 .5, p2 .6 | 0.2600887 | 0.2600887 (`power.prop.test(strict = TRUE)`) |

Every value agrees to the seven decimals G\*Power shows. The only
difference found is the a-priori rounding at 1 : 2 above (372 against
370; Departure 11).

Outputs: G\*Power shows critical z and power (post hoc) or the two group
sizes, total sample size and actual power (a priori) (screenshot).
powerkit: critical value: **Not possible** with pwr or
`power.prop.test()` (neither returns it).

## E6: chi-square test of independence

Matching G\*Power test: χ² tests, "Goodness-of-fit tests: Contingency
tables" (the maintainer's screenshot, G\*Power 3.1.9.7, 17 October 2026;
not in the 2023 manual).

**G\*Power reference (df 1):** post hoc, w = 0.3, α = .05, total N = 100,
df = 1 gives noncentrality λ = 9, critical χ² = 3.8414588 and power
0.8508388
([`figures/gpower/E6_contingency_post_hoc_df1.png`](figures/gpower/E6_contingency_post_hoc_df1.png)).
pwr's `pwr.chisq.test(w = 0.3, N = 100, df = 1, sig.level = 0.05)` gives
0.8508388, and `qchisq(0.95, 1)` is 3.8414588: the same to 7 decimals.
This is a G\*Power value, not a published one. **Still needed:** the same
inputs at df = 2 (pwr gives 0.7706831).

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Effect size | To confirm (not in the 2023 manual; screenshot needed): w | Cell probabilities | **Has** | pwr gets w from them (`ES.w2()`), a "Determine" from probabilities |
| Effect size as w | To confirm (not in the 2023 manual; screenshot needed) | — | **Not exposed** | pwr `pwr.chisq.test(w = )`; Spower `p_chisq.test(w = )` |
| df | To confirm (not in the 2023 manual; screenshot needed) | (rows − 1) × (columns − 1), from the table | **Has** (derived) | |
| Marginal proportions | To confirm (not in the 2023 manual; screenshot needed); from the maintainer's list | Implied by the cell probabilities | **Has** (implied) | |
| Tails | n/a | n/a | n/a | |
| Continuity correction (2 x 2) | To confirm (not in the 2023 manual; screenshot needed) | None: the engine passes `correct = FALSE` to Spower (`engine/R/backend-spower.R`); pwr has none | **Not exposed** (Spower `correct = TRUE`) | |

Outputs: noncentrality, critical value: **Not possible** with pwr; df is
known from the inputs.

## E7: 2 x 2 between-participants ANOVA

Matching G\*Power test: Means, "ANOVA: main effects and interactions (two
or more IVs)". Manual section 11, "F test: Fixed effects ANOVA - special,
main effects and interactions", pp. 26–30.

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Effect size | f = σm/σ (section 11.1, p. 26). The "Determine" drawer works "From Variances" ("Variance explained by special effect", "Error variance") or "Direct" ("Partial η²") (section 11.1, p. 27, Figure 12) | Four cell means and an SD (one or per cell), raw or in SD units | **Has** | Superpower works from means and SDs |
| Effect size as f or partial η² | Yes: f in the main window, partial η² through "Direct" (section 11.1, p. 27). G\*Power's partial η² is f²/(1 + f²) and "is not identical to the SPSS partial η²" (section 11.3.1, p. 27) | — | **Not exposed** | Superpower `mu_from_ES()` is one-way only; `power_twoway_between()` takes means (candidate) |
| Numerator df | Yes: "Numerator df", entered by the user (section 11.3.1, p. 27) | From the effect chosen (1 for each 2 x 2 effect) | n/a (always 1) | |
| Number of groups | Yes: "Number of groups", the "total number of groups in the design" (section 11.3.1, p. 27) | 4 (fixed) | **Has** (fixed) | |
| Effect tested | Main effect, interaction or planned comparison, set through f and the numerator df (sections 11.3.1 and 11.3.3, pp. 27–29) | A, B or A x B | **Has** | |
| Unequal group sizes | No group-size input: total sample size and number of groups only; denominator df = N − k and λ = f²N (section 11.5, p. 30). An a priori N need not be a multiple of the number of groups; the manual says to round up by hand (section 11.3.2, p. 29) | Equal | **Not exposed** (Superpower `ANOVA_power()` with an n vector, simulation only) | |
| Covariates | Separate test (ANCOVA); not in the 2023 manual | — | **Not exposed** (Superpower `ANCOVA_analytic()`) | |

Outputs: G\*Power shows noncentrality parameter λ, critical F,
denominator df, and power (post hoc) or total sample size and actual
power (a priori) (section 11.3, pp. 27–29). powerkit: Cohen's f and
partial η² are given for sensitivity results (**Has**). Noncentrality:
**Not exposed**: Superpower documents it as f² × error df and has a
`liberal_lambda` option; whether `ANOVA_exact()`'s `main_result` carries
it is to check. Critical value, df: **Not exposed** (in `aov_result`, an
`afex` object; to check).

## E8: 2 x 2 mixed ANOVA

Matching G\*Power tests: F tests, "ANOVA: Repeated measures,
within-between interaction" (and "between factors" for the group
effect); screenshot `E8_rm_within_between_options.png`. The manual has
no section for repeated measures ANOVA; it only lists "ANOVA: Repeated
measures, between factors" as a related test (section 10.4, p. 25).

| Input | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Effect size | "Effect size f", with a "Determine" drawer (screenshot) | Four cell means and an SD | **Has** | f as input: **Not exposed** |
| Effect-size convention | Options: "as in GPower 3.0" (selected in the maintainer's copy), "as in GPower 3.0 with implicit rho", "as in SPSS", "as in Cohen (1988) - recommended" (screenshot) | Means, SD and r | n/a | Superpower's reported Cohen's f is a different quantity from G\*Power's f; see the check below |
| Correlation among repeated measures | "Corr among rep measures" (screenshot) | One r | **Has** | |
| Number of groups, measurements | "Number of groups", "Number of measurements" (screenshot) | 2 and 2 (fixed) | **Has** (fixed) | |
| Nonsphericity correction ε | "Nonsphericity correction ε" (screenshot) | — | n/a with two levels | Superpower `correction` (GG, HF) for more levels |
| MANOVA approach | Separate test, "MANOVA: Repeated measures, within-between interaction", with Pillai V and O'Brien and Shieh's (1999) algorithm selected in the maintainer's copy (screenshot `E8_manova_within_between_options.png`) | — | **Not exposed** (`manova_results`) | Roadmap A28, A30. Screenshot: f(V) .25, α .05, power .80, 2 groups, 2 measurements: N 128, actual power 0.8014596 |
| Per-cell SDs | Not in the main window (screenshot) | One SD | **Not exposed** (Superpower `sd` vector) | |

**Check against Superpower (17 October 2026).** G\*Power, with "as in
GPower 3.0": f = .25, α .05, power .80, 2 groups, 2 measurements, r =
.5, ε = 1 gives λ 8.5, critical F 4.1490974, df 1 and 32, total N 34,
actual power 0.8070367 (screenshot). The same design in Superpower
0.2.4.1, `ANOVA_exact()` with `"2b*2w"`, means (1, 0, 0, 0), SD 1, r =
.5 and 17 per group (in G\*Power's convention f = .25: each interaction
effect is ±0.25 SD) gives interaction power 80.70367% and noncentrality
8.5, the same to the decimals shown. At 16 per group it gives 78.14%,
so the required N is also 34. Superpower reports Cohen's f = 0.515 for
this interaction, because its f comes from partial η² of the repeated
measures analysis, which includes the correlation; G\*Power's f = .25
doesn't. A user who copies f from one tool into the other gets a
different design.

Outputs: G\*Power shows noncentrality λ, critical F, numerator and
denominator df, total sample size and actual power (screenshot).
powerkit: as E7.

## E9: moderated regression (continuous × continuous)

Matching G\*Power test: none directly. "Linear multiple regression:
fixed model, R² increase" is the cross-check in
[`conventions.md`](conventions.md). Manual section 14, "F test: Multiple
Regression - special (increase of R²), fixed model", pp. 36–38.

| Input | G\*Power (R² increase) | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Effect size | f² = VS/VE (section 14.1, p. 36). The drawer works "From Variances" ("Variance explained by special effect", "Residual variance") or "Direct" ("Partial R²") (section 14.1, p. 36, Figure 18) | Correlations r_X_Y, r_W_Y, r_XW_Y, r_X_W | **Has** | InteractionPoweR's inputs |
| Number of predictors, tested and total | Yes: "Number of tested predictors" and "Total number of predictors" (section 14.3.1, p. 37) | 1 tested of 3 (fixed) | **Has** (fixed) | |
| Reliability of X, W, Y | n/a | Optional | **Has** | |
| Tails | n/a (F test; the alternative is directional, section 14, p. 36) | Two-sided | n/a | |
| Covariates | Through the predictor counts: a further set C counts toward "Total number of predictors" and lowers the residual variance (case 2, sections 14.1 and 14.3.2, pp. 36–37) | — | **Not exposed** (`power_interaction_r2_covs()`, analytic only) | |
| Binary or ordinal X, W | n/a | — | **Not exposed** (`k.x1`, `k.x2`; phase 3b) | |

Outputs: G\*Power shows noncentrality parameter λ, critical F, numerator
and denominator df, and power (section 14.3.1, p. 37). powerkit:
noncentrality, critical value: **Not possible** (simulation). Simple
slopes and interaction shape: **Not exposed** (`detailed_results =
TRUE`).

## E10–E14: mediation and moderated mediation

Matching G\*Power test: none.

| Input | powerkit | Mark | Note |
| --- | --- | --- | --- |
| Effect sizes | Standardised paths | **Has** | power4mome `pop_es` |
| Mediators | E11: up to 9 parallel; E12: up to 4 in sequence | **Has** | Validated with two |
| Residual correlations between mediators (E11) | Free | **Has** | Departure 7 |
| Moderator correlation with X (E13, E14) | c_X_W | **Has** | |
| Monte Carlo draws per CI (E10) | Yes | **Has** | |
| Test | Monte Carlo CI | **Has**; bootstrap **Not exposed** (`ci_type = "boot"`) | |
| Covariates | — | **Not exposed** (any lavaan model) | Roadmap B15 |
| Latent variables | — | **Not exposed** (`number_of_indicators`, `reliability`) | Roadmap B16 |

Outputs: power with its Monte Carlo interval (**Has**); noncentrality,
critical value, df: **Not possible** (simulation of a CI-based test).

## Wave 2 (engine only, 18 October 2026)

Maintainer's G\*Power 3.1 screenshots, 18 October 2026
(`docs/figures/gpower/`). α = .05. Checked in `test-backend-wave2.R`.

| Row | G\*Power test | Case | G\*Power | powerkit |
| --- | --- | --- | --- | --- |
| A23 | F tests, "ANOVA: Fixed effects, omnibus, one-way" | f = 0.279, 3 groups, a priori | N = 129, power 0.8072995 | 129, 0.8072995 |
| A23 | as above | post hoc, N = 120 | 0.7757040 | 0.7757040 |
| A10 | F tests, "Linear multiple regression: Fixed model, R² deviation from zero" | f² = 0.1111, 5 predictors, a priori | N = 122, power 0.8034946 | 122, 0.8034946 |
| A10 | as above | post hoc, N = 100 | 0.7013300 (λ = 11.11) | 0.7013300 |
| A11 | F tests, "Linear multiple regression: Fixed model, R² increase" | f² = 0.0588, 2 of 5 predictors, a priori | N = 167, power 0.8001440 (λ = 9.8196 = f² × N) | 167, 0.8001440 |
| A35 | Exact, "Proportion: Difference from constant (binomial test, one sample case)" | g = 0.15, constant 0.5, two tails, a priori | N = 90, power 0.8122881 | 90, 0.8122881 (pwrss's own answer: 92) |
| A35 | as above | post hoc, N = 80, two tails / one tail | 0.7235283 / 0.8540286 | 0.7235283 / 0.8540286 |
| A37 | Exact, "Proportions: Inequality, two dependent groups (McNemar)" | OR 2.5, discordant 0.35, two tails, **faster approximation** (G\*Power's default) | a priori N = 121 (0.8052775); post hoc N = 100: 0.7186706 | exact method: 129; 0.6742876 (pwrss "approximate": 0.7240580) |
| A37 | as above | **exact (unconditional) power**, post hoc, N = 100 | 0.6742876 | 0.6742876 |
| A37 | as above | exact option, a priori | N = 129, power 0.8030988 | 129, 0.8030988 (pwrss's own answer: 130) |

Notes:
- The one-way screenshots used f = 0.279 rather than the example's
  0.2079 (the "Determine" screenshot confirms means 10, 11, 13 with SD 6
  give 0.2078699). The test sets means that give f = 0.279.
- G\*Power's effect sizes were typed rounded (f² = 0.1111, 0.0588); the
  tests enter the same values, which is why they match to seven decimals.
- McNemar: G\*Power's Options offer "exact (unconditional) power if N <
  1000000" or the faster approximation. With the exact option (threshold
  left at 1000000), post hoc power and the a priori N match powerkit.
  With the threshold at N < 100, the a priori answer falls back to the
  approximation (121).

## Variance tests (engine only, 25 October 2026)

Matching G\*Power tests: Variance, "Difference from constant (one sample
case)" (manual section 26, p. 64) and "Inequality of two Variances"
(manual section 15, p. 39).

| Input or output | G\*Power | powerkit | Mark | Note |
| --- | --- | --- | --- | --- |
| Effect size | The ratio var1/var0, from the drawer's two variances; ratios in [0.999, 1.001] refused (sections 26.1, 15.1) | The two variances themselves (`var` and `var0`, or `var1` and `var2`); power depends on their ratio alone. A ratio of exactly 1 is refused as a zero effect | **Has** | Same information, entered as variances rather than a ratio |
| Test | Exact: central chi-square with N - 1 df, scaled by the ratio under H1 (section 26.5); central F with N1 - 1 and N0 - 1 df, scaled by the ratio (section 15.5) | The same two tests, simulated: `EnvStats::varTest()` and `stats::var.test()` through Spower's `p_var.test()` | **Has (simulated)** | Known difference 4 in [`conventions.md`](conventions.md): Monte Carlo error rather than an exact number, about 0.004 of power at 10,000 replications |
| Tails | One or two (sections 26, 15) | `alternative`: `two_sided`, `greater` or `less`, always passed to Spower | **Has** | Spower's own `two.tailed = FALSE` means "greater" whichever way the variances point, which is why powerkit passes the direction ([`upstream-questions.md`](upstream-questions.md)) |
| Allocation ratio N2/N1 (two groups) | Yes (section 15.3: N = 443, 148 and 295, at a ratio of 2) | Refused: Spower's `gen_var.test()` cannot draw unequal groups | **Gap** | Reported upstream; the groups are split equally until it is fixed ([`upstream-questions.md`](upstream-questions.md)) |
| Analysis types | A priori, post hoc, criterion, compromise, sensitivity | Power and sample size | **Gap** | As for every powerkit end point |
| Output | Critical values, df, actual power | Power with its Monte Carlo interval, or the required N with an uncertainty interval | **Differs** | powerkit reports no critical values |

The manual's two worked examples (sections 26.3 and 15.3) are set up as
validation tests in
`engine/tests/testthat/test-validation-variance-tests.R`, with the
published values left for the maintainer to transcribe
(`TODO_PUBLISHED_VALUE`). Run at 10,000 replications, powerkit's estimates
for those two examples came out +0.003 and -0.005 from the manual's exact
values, each within about one Monte Carlo standard error (0.004).

## Effect-size calculators ("Determine")

| End point | G\*Power drawer | powerkit | Backend support | Mark |
| --- | --- | --- | --- | --- |
| E1 | d from Mean H0, Mean H1 and SD σ (section 20.1, p. 50) | d only | Spower `p_t.test(means, sds)` | **Not exposed** |
| E2 | d from two means and one SD, or two means and two SDs with equal n (section 21.1, p. 52) | d only | Spower `p_t.test(means, sds)` | **Not exposed** |
| E3 | d_z from the mean and SD of the differences, or from two means, two SDs and their correlation (section 19.1, p. 48) | d_z only | None found for d_z | unknown |
| E4 | ρ H1 from the coefficient of determination r² (section 3.1, p. 9) | r | — | n/a |
| E5 | The z test takes p1 and p2 (or h, by option); Fisher's exact test's drawer computes p1 from a difference, ratio or odds ratio (screenshots) | From two proportions (h computed) | pwr `ES.h()` | **Has** |
| E6 | w (the maintainer's screenshot: "Effect size w", with a "Determine" button) | From cell probabilities (w computed) | pwr `ES.w2()`; `ES.w1()` for goodness-of-fit | **Has** |
| E7 | f from the effect and error variances, or from partial η² (section 11.1, p. 27) | From means and SDs (Superpower's input) | Superpower; f or partial η² as input: **Not exposed** | **Has** (means) |
| E8 | "Determine" drawer present; its contents not in the screenshot | From means and SDs (Superpower's input) | Superpower; f or partial η² as input: **Not exposed** | **Has** (means) |
| E9 | f² from the effect and residual variances, or from partial R² (section 14.1, p. 36). Only the omnibus R² test's drawer works from predictor correlations (section 13.1, p. 33) | From correlations | — | **Has** (correlations) |
| E10–E14 | No matching test | Standardised paths | power4mome | **Has** (paths) |

Conversions between formats (for example d from t, or f from partial η²)
are planned as phase 5 effect-size helpers ([`coverage.md`](coverage.md))
and are judgement call B10.
