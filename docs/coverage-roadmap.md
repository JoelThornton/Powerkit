# Coverage roadmap

*Last updated: 30 October 2026.*

The master list of everything powerkit might cover: every test in
G\*Power 3.1.9.7's Tests menu (Part A), designs beyond G\*Power (Part B),
features that cut across tests (Part C) and what is out of scope (Part D).
It is a planning list, not a promise: nothing here is decided unless it
says so. The decisions it needs are in
[`judgement-calls.md`](judgement-calls.md), section G.

[`coverage.md`](coverage.md) stays the capability-by-capability inventory
of the foundation tools. This page is organised by what a user wants to
test, and links each row to an end point in
[`decision-tree.md`](decision-tree.md) (E1–E47).

## How to read the tables

| Column | Meaning |
| --- | --- |
| Test or design | Plain English. Part A uses G\*Power's menu names exactly, as listed by the maintainer from G\*Power 3.1.9.7 on 17 October 2026 |
| Source list | Where the row comes from: **GP** (G\*Power 3.1.9.7 Tests menu, maintainer's list); **ML** (the maintainer's list for Parts B–D, 17 October 2026); **UCLA** (the UCLA OARC test-selection table, cross-checked in [`routing-audit.md`](routing-audit.md)); **Audit** ([`routing-audit.md`](routing-audit.md)); **BG** ([build guide](build-guide.md), section 2) |
| powerkit end point | The card a user reaches today, or **none**. "none: reaches E*n*" means the routes lead to a card for a different analysis; "none: not reachable" means no answer names it (the safety net is always there). Routes are as recorded in the audit and the walkthroughs; *(inferred)* marks a route worked out for this page and not walked through |
| Status | Exactly one of: **Done** (validated and wired) · **Wired** (the app runs it, validation not finished) · **Validated, not wired** · **Planned** (phase named) · **Foundation tool can do it, not planned** · **No ready-made tool** · **Partly working** · **G\*Power covers it, powerkit doesn't** · **Unknown** (what to check) · **No ready-made tool** · **Out of scope** |
| Analysis types | **Now:** what powerkit offers today. **Could:** what the candidate backend's help documents. AP = a priori (required N); PN = power at a given N; S = sensitivity (smallest detectable effect); Co = compromise; Cr = criterion (alpha) |
| Candidate backend and function | Checked in the package's help pages (see Sources); otherwise "unknown" or "candidate" |
| Next step | What would move the row on |
| Blocking decision | An entry in [`judgement-calls.md`](judgement-calls.md), or — |

**"Wired"** means the app runs the calculation. E1–E9, E18, E23–E26 and
E48–E50 are wired (E1–E8 by PR #34, merged 17 October 2026; the rest
after it), and so are E10–E14, which run in two steps because their
simulations are slow: a rough preview, then the full run in the app for
power (E10 to E12) or an R script to run on the user's own computer
(E13 and E14, and a required N for all five). `forms.yaml` is the record
of which is which: its `calculates` list holds the end points that
compute directly, and its `simulations > endpoints` block holds the
preview-and-full-run ones. A test keeps this page from drifting from it
(`app/routing/tests/testthat/test-docs-match.R`).

**Foundation tools** are the packages powerkit is built on and credits:
Spower, Superpower, power4mome, InteractionPoweR, pwr (the analytic
default for E1–E6, PR #34) and pwrss (E5's z test for unequal groups,
maintainer's decision of 17 October 2026; before that it was used only
by validation, as a cross-check). Rows written before that date call
pwrss "not a foundation tool".

### Sources

Every function named below was found in the package's help pages
(`man/*.Rd`) in its CRAN source, at the version listed, opened on
17 October 2026 from cran.r-project.org. The packages were not installed
or run here, except pwr and pwrss (installed for the E4 comparison in
judgement call G6). Packages not on CRAN are
taken from [`coverage.md`](coverage.md), which read their GitHub sources on
15 October 2026; they are marked *(coverage.md)*.

| Package | Version | Package | Version |
| --- | --- | --- | --- |
| Spower | 0.7 | power4mome | 0.2.1 (and GitHub, commit 253f83e, for its articles) |
| Superpower | 0.2.4.1 | InteractionPoweR | 0.2.4 |
| pwr | 1.3-0 | pwrss | 1.3.3 |
| TOSTER | 0.8.6 | MBESS | 5.0.1 |
| simr | 1.0.11 | mixpower | 1.1.1 |
| faux | 1.2.4 | mlmpower | 1.0.11 |
| WebPower | 0.9.4 | powertools | 1.0.0 |
| semPower | 2.2.0 | simsem | 0.5-17 |
| longpower | 1.0.27 | powRICLPM | 0.2.1 |
| PITS | 0.1.0 | rpact | 4.4.0 |
| gsDesign | 3.11.0 | POSSA | 0.6.5 |
| bfpwr | 0.1.6 | powerbrmsINLA | 1.3.0 |
| BayesFactor | 0.9.12-4.8 | BUCSS | 2.0.0 |
| RSmallTelescopes | 1.0.4 | metapower | 0.2.2 |
| POMADE | 0.2.1 | Hmisc | 5.3-0 |
| pROC | 1.19.1 | MKpower | 1.1 |
| pmsampsize | 1.1.3 | presize | 0.3.11 |
| ICC.Sample.Size | 1.1 | irtpwr | 1.0.3 |
| irtsim | 0.2.0 | powerly | 1.10.0 |
| scan | 0.68.1 | powerSurvEpi | 0.1.5 |
| npsurvSS | 1.1.0 | kappaSize | 1.2 |
| twoCoprimary | 1.1.1 | rPowerSampleSize | 1.0.2 |
| PUMP | 1.0.5 | crt2power | 1.2.2 |
| powerlmm | 0.4.0 (CRAN archive; archived 2021) | mixedpower | 0.1.0 (GitHub only, commit 69680b3) |

## Part A: G\*Power 3.1.9.7 Tests menu (49 tests)

The 49 tests exactly as the maintainer listed them. None added from memory.

### Correlation and regression

| # | Test | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A1 | Correlation: bivariate normal model | GP; UCLA | E4 | Done (validated and wired) | Now: AP, PN. Could: AP, PN, S, Co, Cr (Spower); AP, PN, S, Cr (pwr) | Spower `p_r()`: simulates bivariate normal data and runs `cor.test()` (the exact t test of ρ = 0); Fisher's z when `rho` ≠ 0. pwr `pwr.r.test()`: Fisher's z with a bias correction under the alternative, critical value from t; ρ0 = 0 only. pwrss `power.exact.onecor()` (exact; cross-check) | Decided: keep Fisher's z (Departure 10, see note 1). ρ0 ≠ 0 is in Spower but not exposed, and its one-sided p-value has a flag (below) | — |
| A2 | Correlation: point biserial model | GP | E2 (the same test, with r converted to d; E2 takes d only) | Foundation tool can do it, not planned | Now: — (AP, PN through E2 with d). Could: AP, PN, S, Co, Cr | Spower `p_t.test(r = )` (its G\*Power examples vignette, Example 16.3) | Accept r on E2, or a card note | [G3][] |
| A3 | Correlation: tetrachoric model | GP | none: not reachable *(inferred)* | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | Spower `p_r.cat()` (tetrachoric, polychoric, polyserial; Example 31.3) | — | [G1][] |
| A4 | Two dependent Pearson r's (common index) | GP | E51 | Wired (in the app; the manual's required N reproduces in the engine's tests, Departure 12; values to transcribe) | Now: AP, PN (pwrss). Could: S, Co, Cr | **Engine: pwrss `power.z.twocors.steiger(common.index = TRUE, pooled = FALSE)`** (Steiger's z test, unpooled as G\*Power, Departure 12; template `overlapping_correlations`). Spower `p_2r()` (default test `"steiger1980"`; Example 28.3.2) | Transcribe manual example 28.3.2 (validation placeholders) | [G1][] |
| A5 | Two dependent Pearson r's (no common index) | GP | E51 | Wired (in the app; the manual's required N reproduces in the engine's tests, Departure 12; values to transcribe) | Now: AP, PN (pwrss). Could: S, Co, Cr | **Engine: pwrss `power.z.twocors.steiger(common.index = FALSE, pooled = FALSE)`** (template `nonoverlapping_correlations`). Spower `p_2r()` with `r.ad`, `r.bd`, `r.cd` (Example 28.3.1) | Transcribe manual example 28.3.1 (validation placeholders) | [G1][] |
| A6 | Two independent Pearson r's | GP | E49 | Wired (app PR in review; **checked against G\*Power's manual**, section 27: both of its example figures reproduce; values to transcribe) | Could: AP, PN, S, Co, Cr | **Engine: pwrss `power.z.twocors(rho1, rho2, n2, n.ratio)`** (Fisher's z test; template `two_correlations`). Spower `p_2r(r.ab, r.ab2, n2_n1)` (default test `"fisher1925"`; Example 27.3) | — | [G1][] |
| A7 | Linear bivariate regression: one group, size of slope | GP; UCLA | E4 (the test of a slope of 0 is the test of r = 0; audit) | Done (validated and wired) | Now: AP, PN (as r). Could: AP, PN, S, Co, Cr | Spower `p_slr(beta, sd_x, sd_y, beta0)` (Example 12.3); pwr `pwr.r.test()` for a slope of 0 | Accept slope and SDs on E4, or a card note; a non-zero null slope needs `p_slr()` | [G3][] |
| A8 | Linear bivariate regression: two groups, difference between intercepts | GP | none: not reachable *(inferred)* | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | Spower `p_glm()` with a user-written data generator (Examples 17.3 and 18.3 in Spower's vignette write one) | — | [G1][] |
| A9 | Linear bivariate regression: two groups, difference between slopes | GP | E15 (a yes/no W × continuous X interaction is a difference in slopes) | Wired (29 October 2026; simulated, groups 50/50; published value to transcribe) | Now: AP, PN (InteractionPoweR) | InteractionPoweR `power_interaction(k.x2 = 2)`: groups split 50/50 only. Spower `p_glm()` as A8 for unequal groups | Phase 3b; G\*Power allows unequal groups, InteractionPoweR doesn't | [E4][] |
| A10 | Linear multiple regression: fixed model, R² deviation from zero | GP; UCLA | E24 | Wired (matches G\*Power in the engine's tests, `test-backend-wave2.R`; not yet in the full validation run, where its published value is still a placeholder) | Engine: AP, PN (pwrss). Could: AP, PN, S, Co, Cr (Spower); AP, PN, S, Cr (pwr) | **Engine: pwrss `power.f.regression(r.squared.change, k.total, k.tested)`** (noncentrality f² × n, from its source). Spower `p_lm.R2(R2, k)` (Example 13.1); pwr `pwr.f2.test()` | G\*Power screenshots (wave 2 list below), then wire | [G1][] |
| A11 | Linear multiple regression: fixed model, R² increase | GP | E24 | Wired (matches G\*Power in the engine's tests, `test-backend-wave2.R`; not yet in the full validation run, where its published value is still a placeholder) | As A10 | **Engine: pwrss `power.f.regression()`, passed the partial R² (R²full − R²reduced) / (1 − R²reduced), so f² = ΔR² / (1 − R²full)**. Spower `p_lm.R2(R2, k, R2_0, k.R2_0)` (Example 14.3); pwr `pwr.f2.test(u = )` (its noncentrality f² × (u + v + 1) differs) | G\*Power screenshots (wave 2 list below), then wire | [G1][] |
| A12 | Linear multiple regression: fixed model, single regression coefficient | GP | E24 | Foundation tool can do it, not planned | As A10 | Spower `p_glm()` (one coefficient, tested with `car::lht()`); pwr `pwr.f2.test(u = 1)` | As A10 | [G1][] |
| A13 | Linear multiple regression: random model | GP | E24 | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | Spower `p_lm.R2(fixed = FALSE)` (Example 7.3) | — | [G1][] |
| A14 | Logistic regression | GP; UCLA | E27 | Wired (in the app; the G\*Power manual's examples reproduce when "R² other X" is 0, see conventions.md, Known difference 3, above it; values to transcribe) | Now: AP, PN (pwrss). Could: S, Co, Cr | **Engine: pwrss `power.z.logistic(method = "demidenko(vc)")`** (Wald z test of one predictor, a standardised score or a yes/no group, with other predictors through `r.squared.predictor`; design `logistic_regression`). Spower `p_glm(family = binomial())` | Transcribe the manual's examples (validation placeholders); settle Known difference 3 with G\*Power | — |
| A15 | Poisson regression | GP | E28 | Wired (in the app; checked against G\*Power's manual, values to transcribe) | Now: AP, PN (pwrss). Could: S, Co, Cr | **Engine: pwrss `power.z.poisson(method = "demidenko(vc)")`** (Wald z test of one predictor of a count outcome, a standardised score or a yes/no group, over a mean exposure, with other predictors through `r.squared.predictor`; design `poisson_regression`). Spower `p_glm(family = poisson())` | Transcribe the manual's examples (validation placeholders) | — |

**Note 1 (A1, the method for correlations).** The maintainer reports that
G\*Power uses the exact distribution of r below N = 10,000 by default and
Fisher's z above. powerkit's E4 uses pwr's formula by default (PR #34),
which uses Fisher's z (pwr's help: "These calculations use the Z' transformation of
correlation coefficient"). At N = 20–100 and r = .3–.5 the two differ by
at most 0.004 in power, and by 1 in the required N at r = .3 (the
comparison is judgement call
[G6](archive/judgement-calls-decided.md#g6-the-method-for-correlations-e4-and-for-two-proportions-e5);
the full parity tables are in [`gpower-parity.md`](gpower-parity.md)).
The maintainer decided on 17 October 2026 to keep Fisher's z, recorded as
Departure 10 in [`conventions.md`](conventions.md).

### Means

| # | Test | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A16 | One group: difference from constant | GP; UCLA | E1 | Done (validated and wired) | Now: AP, PN. Could: AP, PN, S, Co, Cr (Spower); AP, PN, S, Cr (pwr) | Spower `p_t.test(type = "one.sample")` (Example 20.3); pwr `pwr.t.test(type = "one.sample")` | — | — |
| A17 | One group: Wilcoxon | GP; UCLA (one-sample median) | E1 (test version) | Wired, 28 October 2026 (simulated; validation in progress) | Now: AP, PN. Could: S | **Engine: Spower `p_wilcox.test(type = "one.sample", parent1)`** (Examples 22.1, 22.3), normal or heavy-tailed scores | Transcribe G\*Power's values (Known difference 5) | — |
| A18 | Two dependent groups (matched pairs) | GP; UCLA | E3 | Done (validated and wired) | As A16 | Spower `p_t.test(type = "paired")` (Example 19.3); pwr `pwr.t.test(type = "paired")` | — | — |
| A19 | Two dependent groups: Wilcoxon | GP; UCLA | E3 (test version) | Wired, 28 October 2026 (simulated; validation in progress) | Now: AP, PN. Could: S | **Engine: Spower `p_wilcox.test(type = "paired")`** (Example 23.3), the differences drawn normal or heavy-tailed | As A17 | — |
| A20 | Two independent groups | GP; UCLA | E2 | Done (validated and wired) | As A16 | Spower `p_t.test(n2_n1)`; pwr `pwr.t.test()`, `pwr.t2n.test()` (unequal groups) | — | — |
| A21 | Two independent groups: Wilcoxon | GP; UCLA | E2 (test version) | Wired, 28 October 2026 (simulated; validation in progress) | Now: AP, PN. Could: S | **Engine: Spower `p_wilcox.test(type = "two.sample", n2_n1, parent1, parent2)`**, normal, skewed or heavy-tailed scores | As A17 | — |
| A22 | ANCOVA: main effects and interactions | GP; UCLA; BG | E23 | Wired: the one-way overall test, and from 28 October 2026 both main effects and the interaction with two factors (not yet checked against G\*Power) | Could: PN, AP (by a search over n) | **Engine (one or two factors, one or more covariates): pwrss `power.f.ancova.shieh()`** (Shieh's method; templates `oneway_ancova` and `factorial_ancova`; agrees with Superpower `power_oneway_ancova(type = "exact")` and `ANCOVA_analytic()` in tests). Superpower `ANCOVA_analytic()`, `power_oneway_ancova()`, `ANCOVA_contrast()`. Confirmed in G\*Power's menu (maintainer, 17 October 2026) | Name a phase | [C15][], [D7][] |
| A23 | ANOVA: one-way | GP; UCLA | E18 | Wired (matches G\*Power in the engine's tests, `test-backend-wave2.R`; not yet in the full validation run, where its published value is still a placeholder) | Engine: AP, PN (Superpower, exact). Could: S (not yet: which pattern to scale is open); AP, PN, S, Co, Cr (Spower); AP, PN, S, Cr (pwr) | **Engine: Superpower `ANOVA_design("kb")` + `ANOVA_exact()`** (equal groups, equal SDs; agrees with pwr `pwr.anova.test()` in a test). Also `power_oneway_between()`; Spower `p_anova.test(n.ratios, var.equal)` (Example 10.3) | G\*Power screenshots (wave 2 list below), then wire | [G1][] |
| A24 | ANOVA: main effects and interactions (two or more IVs) | GP; UCLA | E7 (2 x 2); E21 (two factors beyond 2 x 2), E56 (three factors, any mix of between and within), in the app 28 October 2026, validation in progress | Done (validated and wired) | Now: AP, PN, S (2 x 2); AP, PN (E21). Could: Co (Superpower `ANOVA_compromise()`) | Superpower `ANOVA_exact()`, `ANOVA_power()` (`"kb*mb"` for E21); `power_twoway_between()`, `power_threeway_between()` for larger designs | E21, E56: published values to transcribe | [G1][] |
| A25 | Repeated measures: between factors, ANOVA-approach | GP | E8 (the group effect in a 2 x 2 mixed design) | Done (validated and wired) | Now: AP, PN, S (2 x 2 mixed) | Superpower `ANOVA_exact()` (`"2b*2w"` and larger designs) | Larger designs: E21 | [G1][] |
| A26 | Repeated measures: between factors, MANOVA-approach | GP | none: not reachable | Unknown (check whether Superpower's `manova_results` includes the between-factor effect; its help says only that MANOVA results are given "if a within-subjects factor is included") | — | Superpower `ANOVA_exact()` / `ANOVA_power()`, element `manova_results` (candidate) | Check | [G1][] |
| A27 | Repeated measures: within factors, ANOVA-approach | GP; UCLA | E8 (2 x 2 mixed); E54 (one within factor, three or more levels; in the app 27 October 2026, validation in progress); E20 (two within factors, 2 x 2 or larger; in the app 28 October 2026, validation in progress) | Done (validated and wired) | Now: AP, PN, S (2 x 2 mixed's within effect); AP, PN (E54, E20) | Superpower `ANOVA_design("kw")` + `ANOVA_exact()` (E54; `power_oneway_within()` agrees in the engine's tests), `"kw*mw"` (E20); sphericity `correction` (GG, HF) in `ANOVA_power()`, not needed while one SD and one correlation give sphericity | E54, E20: published values to transcribe. Three within factors still to come | [G1][] |
| A28 | Repeated measures: within factors, MANOVA-approach | GP | E54, E20, E56 (beside the univariate F) | Wired (29 October 2026: the MANOVA approach's power, Pillai's trace, is shown beside the univariate F when the target effect involves a within factor with three or more levels, from the same `ANOVA_exact()` run; matches Superpower called directly; published values to transcribe) | Now: PN at the n planned for the univariate F | **Engine: Superpower `ANOVA_exact()`, element `manova_results`** | A sample size planned for the MANOVA approach itself | [G1][] |
| A29 | Repeated measures: within-between interactions, ANOVA-approach | GP | E8 (2 x 2); E55 (beyond 2 x 2, in the app 28 October 2026, validation in progress) | Done (validated and wired) | Now: AP, PN, S (2 x 2); AP, PN (E55) | Superpower `ANOVA_exact()` (`"2b*2w"`; `"kb*mw"` for E55) | E55: published value to transcribe | — |
| A30 | Repeated measures: within-between interactions, MANOVA-approach | GP | E55, E56 (beside the univariate F) | Wired (as A28, for an interaction with a within factor of three or more levels) | As A28 | As A28 | As A28 | [G1][] |
| A31 | Hotelling T², one group | GP | none: not reachable | Planned (`next.md` item 2, second in the maintainer's order of 30 October 2026; needs a decision on the package or simulation route) | — | unknown (none found in the foundation tools' help) | — | [G1][] |
| A32 | Hotelling T², two groups | GP | none: not reachable | Planned (`next.md` item 2, second in the maintainer's order of 30 October 2026; needs a decision on the package or simulation route) | — | unknown in the foundation tools. BUCSS `ss_buc_manova()` (two-group multivariate comparison, with bias correction) is a candidate | — | [G1][] |
| A33 | MANOVA: global effects | GP; UCLA | none: not reachable | Planned (`next.md` item 2, second in the maintainer's order of 30 October 2026; needs a decision on the package or simulation route) | — | unknown (Superpower's MANOVA output is for within factors only) | — | [C14][], [G1][] |
| A34 | MANOVA: special effects and interactions | GP | none: not reachable | Planned (`next.md` item 2, second in the maintainer's order of 30 October 2026; needs a decision on the package or simulation route) | — | unknown | — | [C14][], [G1][] |

### Proportions

| # | Test | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A35 | One group: difference from constant | GP; UCLA (binomial test) | E25 | Wired (matches G\*Power in the engine's tests, `test-backend-wave2.R`; not yet in the full validation run, where its published value is still a placeholder) | Engine: AP, PN (pwrss, exact). Could: AP, PN, S, Co, Cr (Spower); AP, PN, S, Cr (pwr) | **Engine: pwrss `power.exact.oneprop(prob, null.prob)`** (exact binomial). Spower `p_prop.test(prop, pi)` (Example 4.3); pwr `pwr.p.test()` (arcsine h, normal approximation) | G\*Power screenshots (wave 2 list below), then wire | [G1][] |
| A36 | One group: sign test | GP | none: reaches E1 or E3 *(inferred)* | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | candidate: Spower `p_prop.test(prop, pi = 0.5)` with the effect entered as the proportion of positive differences (inferred, not in Spower's help). powertools `signtest()` | Confirm the inference | [C10][] |
| A37 | Two dependent groups: McNemar | GP; UCLA | E26 | Wired (matches G\*Power in the engine's tests, `test-backend-wave2.R`; not yet in the full validation run, where its published value is still a placeholder) | Engine: AP, PN (pwrss, exact). Could: AP, PN, S, Co, Cr (Spower) | **Engine: pwrss `power.exact.mcnemar(prob10, prob01, method = "exact")`** (prob10 = yes in the second condition only). Spower `p_mcnemar.test(prop, OR, prop.disc)` (Example 5.3) | G\*Power screenshots (wave 2 list below), then wire | [G1][] |
| A38 | Two independent groups: Fisher's exact | GP; UCLA | E5 (test version) | Wired as E5's test version (app PR in review; not yet checked against G\*Power) | Could: AP, PN, S, Co, Cr | **Engine: pwrss `power.exact.fisher(method = "exact")`** (template `two_proportions`, `target_test > method = "fisher_exact"`). Spower `p_prop.test(exact = TRUE)` (`prop` as a matrix; `fisher.test()`). pwrss `power.exact.fisher()` (cross-check). Confirmed in G\*Power's menu (maintainer, 17 October 2026) | Decide judgement call 3.9 | [C11][] |
| A39 | Two independent groups: unconditional exact | GP | none: reaches E5 *(inferred)* | G\*Power covers it, powerkit doesn't | — | unknown (no unconditional exact test found in the foundation tools' help) | — | [G1][] |
| A40 | Two independent groups: inequality with offset, unconditional exact | GP | none: not reachable | G\*Power covers it, powerkit doesn't | — | unknown | — | [G1][] |
| A41 | Two independent groups: z-test | GP; UCLA (chi-square, two groups) | E5 | Done (validated and wired) | Now: AP, PN. Could: AP, PN, S, Co, Cr (Spower); AP, PN, S, Cr (pwr) | Spower `p_prop.test(prop = c(p1, p2), correct = FALSE)`; pwr `pwr.2p.test()`, `pwr.2p2n.test()` (Cohen's h, the arcsine transformation) | Default to a z test (maintainer, 17 October 2026): check base R's `power.prop.test()` against G\*Power's screenshots, then switch | G\*Power screenshots; the maintainer's yes |
| A42 | Multigroup: goodness-of-fit | GP; UCLA | E48 (own card, judgement call 3.7 decided 19 October 2026) | Wired (app PR in review; not yet checked against G\*Power) | Could: AP, PN, S, Co, Cr (Spower); AP, PN, S, Cr (pwr) | **Engine: pwrss `power.chisq.gof()`, with Cohen's w from `probs.to.w()`** (template `chi_square_gof`; agrees with pwr `pwr.chisq.test()` in a test). Spower `p_chisq.test(w, df)` or `P0`, `P`; pwr `pwr.chisq.test()`, `ES.w1()` | Check against G\*Power | [C9][] |

### Variances

| # | Test | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A43 | Variances: one group | GP | E52 | Wired (in the app, simulated: Known difference 4; values to transcribe) | Now: AP, PN (simulated). Could: AP, PN, S, Co, Cr | **Engine: Spower `p_var.test(vars, sigma2)`**, which runs `EnvStats::varTest()`, the chi-square test of G\*Power's section 26 | Transcribe the published values (Example 26.3) | [G1][] |
| A44 | Variances: two groups | GP | E53 | Wired (in the app, simulated, equal groups only: Known difference 4; values to transcribe) | Now: AP, PN (simulated, equal groups only). Could: AP, PN, S, Co, Cr | **Engine: Spower `p_var.test(vars = c(v1, v2))`**. Answered (25 October 2026): for two groups it runs `stats::var.test()`, the F test of G\*Power's section 15, whatever `test` says (Levene, Bartlett and Fligner are for three groups or more); `test = "Fligner"` is the one exception. Unequal groups fail in `gen_var.test()`, so an allocation ratio is refused (`upstream-questions.md`) | Transcribe the published values (Example 15.3) | [G1][] |

### Generic

| # | Test | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A45 | Generic: binomial | GP | none: not reachable | G\*Power covers it, powerkit doesn't | — | The same test as one proportion against a fixed value (A35): pwrss `power.binom.test()` gives the same power as `power.exact.oneprop()` (checked 18 October 2026). pwrss `power.binom.test()` (pwrss became a foundation tool on 17 October 2026, for E5's unequal groups) | coverage.md: not planned (the R script export is the route) | [G1][] |
| A46 | Generic: F | GP | E50 (only from "I know my analysis") | Wired (app PR in review; no sample size; not yet checked against G\*Power: the manual has no section for this generic test, so it needs the program itself) | — | **Engine: pwrss `power.f.test(ncp, df1, df2)`** (template `generic_test / f`). pwrss `power.f.test(ncp, df1, df2)`; Superpower `power.ftest()` (candidate: check its arguments) | As A45 | [G1][] |
| A47 | Generic: t | GP | E50 (only from "I know my analysis") | Wired (app PR in review; no sample size; **checked against G\*Power's manual**, section 25: its example reproduces to five decimals; value to transcribe) | — | **Engine: pwrss `power.t.test(ncp, df)`** (template `generic_test / t`). pwrss `power.t.test(ncp, df)` | As A45 | [G1][] |
| A48 | Generic: chi² | GP | E50 (only from "I know my analysis") | Wired (app PR in review; no sample size; not yet checked against G\*Power: the manual has no section for this generic test, so it needs the program itself) | — | **Engine: pwrss `power.chisq.test(ncp, df)`** (template `generic_test / chi_square`). pwrss `power.chisq.test()` | As A45 | [G1][] |
| A49 | Generic: z | GP | E50 (only from "I know my analysis") | Wired (app PR in review; no sample size; not yet checked against G\*Power: the manual has no section for this generic test, so it needs the program itself) | — | **Engine: pwrss `power.z.test(mean = ncp)`** (template `generic_test / z`). pwrss `power.z.test()` | As A45 | [G1][] |

## Part B: beyond G\*Power

Rows the maintainer listed (ML). "Unknown" where it isn't clear.

### Interactions

| # | Design | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B1 | Continuous × continuous | ML; BG | E9 | Done (validated and wired) | Now: AP, PN. Could: AP, PN, S (by grids over N and effect) | InteractionPoweR `power_interaction()`; `power_interaction_r2()` (analytic, brackets N) | Wire (draft PR from the other thread) | — |
| B2 | Binary × continuous | ML; BG | E15 | Wired (29 October 2026; simulated, 50/50 split; published value to transcribe) | Now: AP, PN, S | **Engine: InteractionPoweR `power_interaction(k.x1 or k.x2 = 2)`** (50/50 split only); the implied group difference by `psych::r2d()` | Transcribe a published example | [E4][], [E5][] |
| B3 | Binary × binary | ML | E7 (2 x 2 between ANOVA interaction) | Done (validated and wired) | Now: AP, PN, S | Superpower `ANOVA_exact()`; InteractionPoweR `k.x1 = 2, k.x2 = 2` as a cross-check (build guide, phase 3b c) | — | — |
| B4 | Categorical moderator with 3+ levels | ML; Audit | E30 | No ready-made tool | — | InteractionPoweR's `k.x1`/`k.x2` make ordered (binary or ordinal) variables, not unordered categories (coverage.md) | — | [A1][] |
| B5 | Three-way interaction | ML; BG | E31 | Wired (29 October 2026: InteractionPoweR's analytic `power_interaction_3way_r2()`, with reliabilities; matches it called directly; published value to transcribe) | Now: AP, PN | InteractionPoweR `power_interaction_3way_r2()` (analytic only), `cor.mat.3way()`; Superpower `power_threeway_between()` for three factors | coverage.md proposes v2 | — |
| B6 | Simple slopes | ML | none: no card asks (E9's target is the interaction) | Foundation tool can do it, not planned | Could: PN | InteractionPoweR `power_interaction(detailed_results = TRUE)`, `plot_simple_slope()`, `simple.slopes.3way()` | — | [B7][] |
| B7 | Curvilinear/quadratic effects | ML; Audit | none: reaches E4 | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | candidate: Spower `p_glm()` with a squared term in `formula` (inferred: `p_glm()` takes any formula) | Decide the card | [C12][] |

### Mediation

| # | Design | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B8 | Simple mediation | ML; BG | E10 | Done (validated and wired: a preview, then the full run in the app for power, or an R script for a required N) | Now: AP, PN. Could: AP, PN, S | power4mome `power4test()` with `test_indirect_effect()`; `q_power_mediation_simple()`; `x_from_power(x = "n")`, `x_from_power(x = "es")` | Wire | — |
| B9 | Parallel mediation | ML; BG | E11 | Done (validated and wired, as B8; two mediators) | As B8 | power4mome `q_power_mediation_parallel()` | Wire | — |
| B10 | Serial mediation | ML; BG | E12 | Done (validated and wired, as B8; two mediators) | As B8 | power4mome `q_power_mediation_serial()` | Wire | — |
| B11 | 3+ mediators | ML | E11, E12 (the spec takes up to M9 parallel, M4 serial) | Planned (validation; status.md "What's next", item 1; no phase) | As B8 | As B9, B10 | Validate with three or more | [B9][] |
| B12 | Binary X | ML; BG | E16 (one mediator); E11, E12 (two or more) | Wired (29 October 2026; simulated, the group split an input; published value to transcribe) | Now: AP, PN, S | **Engine: power4mome `x_fun` with `rbinary_rs(p1 = )`**; Spower `p_mediation(dichotomous.X = TRUE)` (Sobel/Wald test) | Transcribe a published example | [E4][] |
| B13 | Multi-category X | ML | E42 | No ready-made tool | — | none found (coverage.md) | — | — |
| B14 | Binary or count outcome | ML; Audit | E32 | No ready-made tool | — | none found among the five: `x_fun` on an endogenous variable sets its error term, so a binary Y isn't covered (build guide, phase 3b a). **Candidate, not checked:** powerMediation's Vittinghoff, Sen and McCulloch (2009) logistic and Poisson mediation functions (coverage.md) | Check the candidate against its own help files | — |
| B15 | With covariates | ML | none: reaches E10–E12, which have no covariates | Foundation tool can do it, not planned | Could: AP, PN, S | power4mome `power4test(model = )`: any lavaan model, so covariates can be added as predictors | Add covariates to the spec | [D7][] |
| B16 | Latent-variable mediation | ML; Audit | E37; entered as mediation, E10 | Foundation tool can do it, not planned | Could: AP, PN, S | power4mome `power4test()` with `number_of_indicators`, `reliability` (vignette "power4test_latent_mediation") | — | [C16][] |
| B17 | Longitudinal mediation | ML | E41 | No ready-made tool | — | none found among the five (coverage.md: within-person mediation). **Candidate, not checked:** semPower, whose cross-lagged functions are already named for B43; the open question is whether it can test a product of paths (coverage.md) | Check the candidate against its own help files | — |

### Moderated mediation

power4mome's documentation doesn't number PROCESS models. Its ready-made
templates (GitHub articles, commit 253f83e) are: simple, parallel and
serial mediation (observed and latent variables); moderation with one W
and with two Ws (`moderation_obs_simple`, `moderation_obs_two_ws`); and
simple moderated mediation with the a path moderated (`mome_obs_a`) or the
b path moderated (`mome_obs_b`). powerkit maps those two to PROCESS 7 and
14. Any other model can be written as lavaan model syntax for
`power4test(model = )`, which is how the rows below would be done.

| # | Design | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B18 | PROCESS 7 (first stage) | ML; BG | E13 | Done (validated and wired: a preview, then an R script for the full run) | Now: AP, PN. Could: AP, PN, S | power4mome `power4test()` with `test_index_of_mome()`; template `mome_obs_a` | Wire | — |
| B19 | PROCESS 14 (second stage) | ML; BG | E14 | Done (validated and wired: a preview, then an R script for the full run) | As B18 | As B18; template `mome_obs_b` | Wire | — |
| B20 | PROCESS 8, 58, 59 | BG | E38 | Planned (v2 in the build guide, section 2; no phase named) | Could: AP, PN, S | power4mome `power4test(model = )` (no template). WebPower `wp.modmed.m8()`, `wp.modmed.m58()` (not foundation tools) | Name a phase | — |
| B21 | Other PROCESS models | ML | E40 (two or more mediators); otherwise none | Partly working (29 October 2026: models 7 and 14 with two parallel mediators, the index through a chosen mediator, power4mome; models 8, 58 and 59 wait on an upstream question and a decision, E38) | Could: AP, PN, S | power4mome `power4test(model = )` (no template) | — | [E2][] |
| B22 | Moderated mediation with a binary X or W | BG | E17 | Planned (phase 3b) | Could: AP, PN, S | power4mome `x_fun` with `rbinary_rs()` | Phase 3b | [E4][] |
| B23 | Conditional indirect effects at chosen W | BG | none: reaches E13 or E14, which test the index | Foundation tool can do it, not planned | Could: AP, PN, S | power4mome `test_cond_indirect()`, `test_cond_indirect_effects()` | Needed for the Donnelly et al. (2023) benchmark | [B7][] |

### Other tests not in G\*Power

| # | Test | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B24 | Welch's t | ML | E2 (an option) | Done (validated and wired) | Now: AP, PN (Spower). Engine on request: AP, PN by formula (pwrss). Could: S, Co, Cr | Spower `p_t.test(var.equal = FALSE)` (default). **Engine, with `options > method = "exact"` only: pwrss `power.t.welch(d, var.ratio = 1, n.ratio)`** (wave 2, draft PR; the app still uses Spower) | G\*Power check of the formula (wave 2 list below) | — |
| B25 | Kruskal–Wallis | ML; UCLA | E18 (test version) | Wired, 28 October 2026 (simulated; validation in progress) | Now: AP, PN | **Engine: Spower `p_kruskal.test(n, k, means, gen_fun)`**, normal, skewed or heavy-tailed scores | Choose a published example | — |
| B26 | Friedman | ML; UCLA | none: reaches E54 | Unknown (no Friedman power function in the foundation tools or the 47 other packages opened; check further) | — | unknown | Search | [C10][] |
| B27 | Cochran's Q | ML | E26 (its card says no ready-made tool) | No ready-made tool | — | none found. **Candidate, not checked:** DescTools' `CochranQTest()` is the test, not its power, so it would support a custom simulation only, and a published power method would still be needed (coverage.md) | Check the candidate against its own help files | [C6][] |
| B28 | Factorial logistic regression | ML; UCLA | E47 | Wired (29 October 2026: two between-participants factors, equal cells, Spower's `p_glm(family = binomial())`, the Wald test of one effect with effect coding; matches Spower called directly and holds alpha; published value to transcribe) | Now: AP, PN | Could: AP, PN, S, Co, Cr | Spower `p_glm(family = binomial())` with factor terms | Phase 6 | [C7][], [A1][] |
| B29 | Ordinal regression | ML; UCLA | E29 | Wired (29 October 2026: two groups, powertools' `propodds()`; matches Hmisc's `popower()`; published value to transcribe. More groups or a measured predictor: not yet) | Now: AP, PN | Hmisc `popower()` (proportional odds); powertools `propodds()`. Neither is a foundation tool | Choose a backend | [C17][] |
| B30 | Negative binomial and zero-inflated counts | ML | E28 | Unknown (check whether Spower `p_glm()` accepts a negative-binomial family; zero-inflated: no candidate found) | — | MKpower `power.nb.test()` (negative binomial; not a foundation tool) | Check | — |
| B31 | Partial correlation | ML | none: reaches E4 or E24 *(inferred)* | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | Spower `p_glm()` (one coefficient with covariates); pwr `pwr.f2.test(u = 1)`. That this is the same test as a partial correlation is inferred | — | [D7][] |
| B32 | Planned contrasts and trend analysis within ANOVA | ML; BG | E19 | Wired (in the app; checked against G\*Power's manual, values to transcribe) | Now: AP, PN (pwrss). Could: S | **Engine: pwrss `power.t.contrasts()`** (the t test of a weighted combination of one factor's means, with `k.covariates = 0`; template `oneway_contrast`). Superpower `emmeans_power()` and `ANOVA_exact(emm = TRUE, contrast_type = )` computes the same contrast through emmeans and agrees with it | Transcribe the manual's three contrasts (validation placeholders) | [B7][] |

### Experimental structure

| # | Design | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B33 | Crossover and counterbalanced designs | ML | E3 or E8 *(inferred)* | Unknown (check whether an AB/BA crossover analysed with order as a factor matches E8's 2 x 2 mixed design) | — | candidate: Superpower `"2b*2w"`. powertools `crt.xo.cont()` covers cluster crossover trials only | Check | — |
| B34 | Many trials per participant (trials vs participants trade-off) | ML; BG | E33 | Wired (30 October 2026: two conditions within participants, items in one condition or both; simulated, Satterthwaite test, Departure 16; published value to transcribe) | Now: AP (in the app), PN (R script). Could: other designs (conditions between people, more conditions, trial-level predictors) | **Engine: simr `powerSim()` on `makeLmer()`**, `fixed("cond", "sa")`; simr `powerSim()`, `powerCurve()`; mixpower `mp_power()`, `mp_solve_sample_size()`; faux `sim_mixed_cc()` (data only); mixedpower `mixedpower()` *(GitHub only, 0.1.0)* | Transcribe a published example; more designs (E41) | — |
| B35 | Stimuli as a random factor | ML; BG | E33 | Wired (30 October 2026: two conditions within participants, items in one condition or both; simulated, Satterthwaite test, Departure 16; published value to transcribe) | Now: AP (in the app), PN (R script). Could: other designs (conditions between people, more conditions, trial-level predictors) | **Engine: simr `powerSim()` on `makeLmer()`**, `fixed("cond", "sa")`; As B34 | Transcribe a published example; more designs (E41) | — |

### Dependence

| # | Design | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B36 | Multilevel/nested | ML; BG; Audit | E34 | Planned (phase 6: mixed-effects) | Could: AP, PN | mlmpower `power_analysis()`; simr `powerSim()`; mixedpower `mixedpower()` *(GitHub only, 0.1.0)* | Phase 6 | — |
| B37 | Crossed random effects | ML; BG; Audit | E33 | Wired (30 October 2026: two conditions within participants, items in one condition or both; simulated, Satterthwaite test, Departure 16; published value to transcribe) | Now: AP (in the app), PN (R script). Could: other designs (conditions between people, more conditions, trial-level predictors) | **Engine: simr `powerSim()` on `makeLmer()`**, `fixed("cond", "sa")`; As B34 | Transcribe a published example; more designs (E41) | — |
| B38 | Mixed models with binary outcomes | ML | E33 or E34 | Planned (phase 6: mixed-effects) | Could: AP, PN | mixpower `mp_scenario_lme4_binomial()`; simr `powerSim()` (glmer models) | Phase 6 | — |
| B39 | Cluster-randomised | ML; Audit | E34 | Wired (score or yes/no outcome, two conditions, equal numbers of groups, a baseline score optional for a score; also multisite trials, people randomised within groups, and group treatment trials, only one condition in groups; matches powertools called directly and the design-effect calculation in the engine's tests; published values to transcribe) | Now: AP, PN, S (powertools). Could: more covariates, unequal numbers of groups | **Engine: powertools `crt.parallel.cont()` and `multisite.cont()`** (27 October 2026), `crt.parallel.bin()` and `multisite.bin()` (yes/no outcome, 28 October 2026), `irgtt.cont()` and `irgtt.bin()` (only one condition in groups, 28 October 2026). Also WebPower `wp.crt2arm()`, `wp.crt3arm()` | Next: simulated models (package decision) | — |
| B40 | Dyadic (APIM) | ML; Audit | E44 | Unknown (no APIM power function in the packages opened; check for a dedicated tool) | — | unknown | Search | [A5][], [C2][] |
| B41 | Growth curves | ML; BG; Audit | E35 | Planned (later in the build guide; no phase) | — | longpower `lmmpower()`, `power.mmrm()`; mlmpower `power_analysis()` with `within_time_predictor()`; powerlmm `study_parameters()`, `get_power()` *(archived on CRAN in 2021; 0.4.0)*; semPower `semPower.powerLGCM()`; WebPower `wp.lcsm()` | — | [A6][] |
| B42 | Diary/EMA and intensive longitudinal | ML; BG; Audit | E35 or E41 | Planned (later in the build guide; no phase) | — | PowerAnalysisIL *(coverage.md; GitHub, not on CRAN)* | — | [C3][] |
| B43 | Cross-lagged panel models (including random-intercept versions) | ML; BG | E35 | Planned (later in the build guide; no phase) | — | powRICLPM `powRICLPM()`; semPower `semPower.powerCLPM()`, `semPower.powerRICLPM()` | — | — |
| B44 | Segmented regression and interrupted time series | ML; Audit | E45 | Unknown (check PITS against the known-breakpoint case) | — | PITS `calculate_power()`, `run_its_power()` (single-site ITS). Estimated breakpoint: none found | Check PITS | [A2][], [A6][] |

### Latent and measurement

| # | Design | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B45 | SEM | ML; BG; Audit | E37 | Wired (model fit: the chi-square test of exact fit, power to reject a model with a given RMSEA, for a CFA described by its items and factors or any model given by its df; matches semPower called directly and the noncentral chi-square in base R in the engine's tests; published values to transcribe) | Now: AP, PN (semPower). Could: Co, the test of close fit, simulated power | **Engine: semPower `semPower.postHoc()` and `semPower.getDf()`** (27 October 2026). Also `semPower.aPriori()`, `semPower.compromise()`, `semPower.powerLav()`, `semPower.powerPath()`; simsem `sim()`; power4mome (latent models) | Next: the test of close fit (an open method choice), longitudinal invariance | [C18][] |
| B46 | CFA | ML; BG | E37 | Wired (the correlation between two factors against zero, and a latent slope against zero through `semPower.powerRegression()`, by the chi-square difference test; match semPower called directly in the engine's tests; published values to transcribe) | Now: AP, PN (semPower) | **Engine: semPower `semPower.powerCFA()`, `semPower.powerRegression()`** (29 October 2026) | Transcribe published examples (`test-validation-sem-latent.R`) | — |
| B47 | Measurement invariance | ML; BG | E37 | Wired (multigroup: one factor, two groups; longitudinal: one factor, two occasions, `semPower.powerLI()`, from 29 October 2026; metric against configural or scalar against metric, by the chi-square difference test; matches semPower called directly in the engine's tests; published values to transcribe) | Now: AP, PN (semPower). Could: several factors, groups or occasions | **Engine: semPower `semPower.powerMI()`** (29 October 2026) | Longitudinal invariance; several factors or groups | — |
| B48 | Latent interactions | ML | none: nearest E9 with reliabilities *(inferred)* | Unknown (no candidate found) | — | unknown | Search | — |
| B49 | Latent profile/class analysis | ML | none: not reachable | Unknown (no candidate found) | — | unknown | Search | — |
| B50 | Reliability (ICC) | ML; Audit | none: reaches E41, E4 or E46 | Unknown (decide the card; tools exist) | — | ICC.Sample.Size `calculateIccSampleSize()`; presize `prec_icc()`; MBESS `ss.aipe.reliability()`; kappaSize `PowerBinary()` (agreement) | Decide | [C4][] |
| B51 | IRT | ML; Audit | E37 (says IRT isn't covered) | Unknown (decide scope; tools exist) | — | irtpwr `irtpwr()`; irtsim `irt_simulate()` | Decide | — |
| B52 | Factor analysis sample size | ML; Audit | E37 (confirmatory); exploratory not reachable | Unknown (exploratory: no candidate found) | — | Confirmatory: semPower `semPower.powerCFA()`; the power of a CFA's test of fit is computed (B45, E37) | — | — |
| B53 | Network models | ML; Audit | none: not reachable | Unknown (decide scope; a tool exists) | — | powerly `powerly()` ("Sample Size Analysis for Psychological Networks") | Decide | — |

### Other goals

| # | Goal | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B54 | Equivalence (TOST) | ML; BG; Audit | E36 | Wired (in the app: two groups, paired, one sample by TOSTER's `power_t_TOST()`; a correlation by `power_z_cor()` and two proportions by `power_twoprop()`, 29 October 2026; published values to transcribe) | Now: AP, PN. Could: S, Co, Cr (Spower) | TOSTER `power_t_TOST()`, `powerTOSTone()`, `powerTOSTpaired()`, `powerTOSTtwo()`, `power_twoprop()`, `power_z_cor()`, `power_eq_f()`; Spower `is.CI_within()` (vignette "Equivalence testing") | Phase 6 | — |
| B55 | Non-inferiority | ML; Audit | E36 | Wired (29 October 2026: two groups, paired, one sample and two proportions, pwrss's one-sided tests against the margin, `power.t.student()` and `power.z.twoprops()`; matches pwrss called directly; published values to transcribe) | Now: AP, PN | **Engine: pwrss `power.t.student(margin, alternative = "one.sided")`, `power.z.twoprops(margin)`** | Transcribe published examples | — |
| B56 | Precision (CI width) | ML; BG; Audit | E46 | Planned (phase 6: AIPE) | Could: AP | MBESS `ss.aipe.smd()` and the other `ss.aipe.*()` functions; presize `prec_mean()`, `prec_meandiff()`; Spower precision criterion (vignette "Precision criterion", user-written) | Phase 6 | — |
| B57 | Group-sequential designs with interim analyses | ML; BG; Audit | none: not reachable | Planned (later in the build guide; no phase) | — | rpact `getDesignGroupSequential()`, `getSampleSizeMeans()`, `getPowerMeans()`; gsDesign `gsDesign()`; POSSA `sim()`, `pow()` | — | [C13][] |

### Bayesian

| # | Approach | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B58 | Bayes factor design analysis (fixed N) | ML; BG | E1, E2, E3 (test version, t-tests only; in the app 28 October 2026) | Wired (t-tests, by bfpwr's closed form; Known difference 6 and Departure 15; published value to transcribe) | Now: AP, PN | **Engine: bfpwr `powertbf01()`** (t-tests); later `powerbf01()`, `powerbf01()`, `powerbinbf01()`, `powernmbf01()`; Spower with a user-written experiment using `BayesFactor::ttestBF()` (vignette "Bayes Factors"); BFDA *(coverage.md; GitHub)* | — | [D3][], [G2][] |
| B59 | Sequential Bayes factors (expected and maximum N) | ML; BG | none: not reachable | Planned (later in the build guide; no phase) | — | BFDA `BFDA.sim()`, `SSD()` *(coverage.md; GitHub)*; powerbrmsINLA `brms_inla_power_sequential()` | — | [D3][], [G2][] |
| B60 | Assurance / expected power over a prior distribution of effects | ML | none: not reachable | Foundation tool can do it, not planned | Could: PN, AP (Spower: its example solves N with an effect drawn from a prior) | Spower `Spower()`: "For expected power computations, the arguments to the simulation experiment arguments can be specified as a function to reflect the prior uncertainty", for example `d = d_prior()` (help, Details and the "Expected Power" example). So Spower's expected power is power averaged over a prior on the effect, which is what this row asks. powerbrmsINLA `compute_assurance()` | Decide whether to offer it | [G2][] |
| B61 | Precision of posterior intervals | ML; BG | none: not reachable | Unknown (check powerbrmsINLA's precision functions) | — | candidate: powerbrmsINLA `plot_precision_assurance_curve()` | Check | [G2][] |
| B62 | Bayesian equivalence (ROPE) | ML | none: not reachable | Foundation tool can do it, not planned | Could: AP, PN | Spower with a user-written experiment (vignette "Bayesian approach to ROPEs (HDI + ROPE)") | — | [G2][] |

### Clinical and applied

| # | Design | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B63 | Diagnostic accuracy (sensitivity/specificity, ROC/AUC) | ML | none: not reachable | Unknown (decide scope; tools exist) | — | pROC `power.roc.test()`; MKpower `power.diagnostic.test()`; presize `prec_sens()`, `prec_auc()` | Decide | [G1][] |
| B64 | Prediction model development | ML | none: not reachable | Unknown (decide scope; a tool exists) | — | pmsampsize `pmsampsize()` | Decide | — |
| B65 | Single-case (N-of-1) designs | ML | none: reaches E45 or E35 (S2's "Independent people" covers one person) | Unknown (decide scope; a tool exists) | — | scan `power_test()` ("Empirical power analysis for single-case data") | Decide | — |
| B66 | Prevalence estimation | ML | E46 (precision) | Unknown (decide scope; a tool exists) | — | presize `prec_prop()` | Decide | — |
| B67 | Time-to-event | ML; Audit | E43 | Unknown (E43 says tools exist, unchecked) | — | Hmisc `cpower()`, `spower()`; powerSurvEpi `ssizeCT()`; npsurvSS `size_two_arm()`; gsDesign `gsSurvPower()` | Decide scope | [A1][] |

### Other

| # | Design | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B68 | Meta-analysis | ML; Audit | none: not reachable | Planned (`next.md` item 7: in scope since 30 October 2026; needs a decision on the package) | — | metapower `mpower()`; POMADE `power_MADE()` | Decide the package and the first tests | — |
| B69 | Replication-study power (e.g. small telescopes, safeguard power) | ML | none: not reachable | Unknown (decide whether this is an effect-size input option or its own card) | — | RSmallTelescopes `SmallTelescopes()`; BUCSS `ss_buc_*()` functions; mixpower `mp_safeguard_effect()` | Decide | [B2][] |

## Wave 2 (engine groundwork, 18 October 2026)

Five tests now run in the engine only: no route, card or form uses them
yet. Each is one backend call, checked against that backend called
directly (`engine/tests/testthat/test-backend-wave2.R`) and against the
maintainer's G\*Power screenshots (`gpower-parity.md`, "Wave 2"), which all match.

| Row | Spec (design / template) | Backend and function | Analytic? |
| --- | --- | --- | --- |
| A23 | `factorial_anova` / `oneway_between` | Superpower `ANOVA_exact()` | exact |
| A10 | `multiple_regression` / `r2_zero` | pwrss `power.f.regression()` | analytic (noncentral F) |
| A11 | `multiple_regression` / `r2_increase` | pwrss `power.f.regression()` (partial R²) | analytic (noncentral F) |
| A35 | `basic_test` / `one_proportion` | pwrss `power.exact.oneprop()` | exact binomial |
| A37 | `basic_test` / `mcnemar` | pwrss `power.exact.mcnemar(method = "exact")` | exact |
| B24 | `basic_test` / `independent_t`, `welch_t`, `options > method = "exact"` | pwrss `power.t.welch()` | analytic (Welch df) |

**Open points found while building it (none decided):**

- **Required N for exact tests of counts (A35, A37).** Their power goes
  up and down with N. The engine reports the smallest N that reaches the
  target (for the one-proportion example, 90). pwrss's own sample-size
  answer for the same inputs is 92, and power at 96 falls back to 0.799.
  For McNemar, the engine gives 129 and pwrss's sample-size call 130.
  G\*Power reports 90 for the one-proportion example, as the engine does
  (screenshot, 18 October 2026). For McNemar, G\*Power's screenshots
  used its default "faster approximation" (121; 0.7187 at N = 100), which
  neither pwrss method reproduces; its "exact (unconditional) power"
  option reports 129, as the engine does.
- **One-sided tests against the expected direction** can't be computed
  with these pwrss functions (they test in the direction of the
  effect), so the engine refuses them for A35, A37 and B24 by formula.
- **One-way sensitivity** (A23) isn't offered: which pattern of means to
  scale is open, as for E7 and E8's choice.
- **R² noncentrality (A10, A11).** pwrss uses f² × N; pwr's
  `pwr.f2.test()` uses f² × (u + v + 1), which is the same for R² against
  0 but differs for an increase. Settled: G\*Power's noncentrality is
  f² × N (9.8196 = 0.0588 × 167 on its screenshot), pwrss's convention,
  and the engine matches G\*Power to seven decimals.

**G\*Power screenshots received (18 October 2026).** One-way ANOVA (at
f = 0.279), R² against 0, R² increase and one proportion match the
engine to seven decimals, a priori N included (`test-backend-wave2.R`;
`gpower-parity.md`, "Wave 2"). McNemar with G\*Power's exact option matches
too (post hoc 0.6742876; a priori N = 129). All wave 2 G\*Power checks
are done. The one-way ANOVA at f = 0.2079 and the R² increase post hoc
are not needed (the cases sent already check the same calculations).

**G\*Power screens and inputs the maintainer was asked to send** (one
screenshot of each, showing the input and output panes, α = 0.05,
power 0.80 unless said; menu names as in the maintainer's list, Part A):

1. **A23, one-way ANOVA** (Means: "ANOVA: one-way"). A priori: effect size f = 0.2079 (from means 10, 11, 13, SD
   6; or use "Determine" with those means and n per group equal), 3
   groups. Then Post hoc: N = 120.
2. **A10, R² against 0** (Correlation and regression: "Linear multiple
   regression: fixed model, R² deviation from zero"). A priori: f² = 0.1111 (R² = 0.10), 5
   predictors. Then Post hoc: N = 100.
3. **A11, R² increase** (Correlation and regression: "Linear multiple
   regression: fixed model, R² increase"). A priori: f² = 0.0588 (R² 0.15
   full, 0.10 reduced, so (0.15 − 0.10) / (1 − 0.15)), 2 tested
   predictors, 5 total. Then Post hoc: N = 150.
4. **A35, one proportion** (Proportions: "One group: difference from
   constant", the exact binomial version). A priori: two tails,
   constant proportion 0.50, proportion 0.65. Please include the power
   plot or the note on non-monotone power if G\*Power shows one. Then Post
   hoc: N = 80, and one tail at N = 80.
5. **A37, McNemar** (Proportions: "Two dependent groups: McNemar").
   A priori: two tails, odds ratio 2.5 (0.25 / 0.10), proportion of
   discordant pairs 0.35 (the inputs G\*Power asks for are to be
   confirmed from the screenshot). Then Post hoc: N = 100.
6. **B24, Welch.** Whether G\*Power has a Welch test is unknown (not
   in the maintainer's Part A list as its own entry). If it has one: d =
   0.4, two tails, allocation N2/N1 = 2, Post hoc at N = 120 (40 + 80).
   If not, no screenshot is needed.

## Part C: features that cut across tests

| # | Feature | Current support | Status | Candidate approach | Blocking decision |
| --- | --- | --- | --- | --- | --- |
| C1 | Alpha correction for multiple tests | None: one target test per spec; the user can lower alpha by hand | Foundation tool can do it, not planned | Superpower `ANOVA_power(p_adjust = )` and `emm_p_adjust` for ANOVA effects and contrasts; elsewhere a corrected alpha passed to the backend | [G3][] |
| C2 | Several hypotheses in one study: power for each test separately (individual testing), for "at least one significant" (disjunction) or for "all significant" (conjunction) | The guided "plan my whole study" route, as an experimental option (27 October 2026): one simulation of correlation, interaction, mediation and moderated mediation analyses together (power4mome), giving each analysis's power and the joint power that all, or any, of the main analyses are significant. Elsewhere one target test per spec, at the alpha the user enters | Partly working (whole-study simulation, experimental; waits on a statistician's check, `next.md` item 11) | Simulation (foundation tools): power4mome 0.2.1 `rejection_rates(collapse = "none" / "all_sig" / "at_least_one_sig" / "at_least_k_sig")`; Spower 0.7 user-written experiments that return one TRUE/FALSE (its vignettes describe joint criteria); Superpower 0.2.4.1 `ANOVA_power(p_adjust = , emm_p_adjust = )` corrects ANOVA effects and contrasts but reports power per effect. Analytic (not foundation tools): powertools 1.0.0 `coprimary.z()`, `coprimary.t()` (all) and `altprimary()` (at least one; Bonferroni by passing alpha / K); twoCoprimary 1.1.1 (two co-primary endpoints, all); rPowerSampleSize 1.0.2 (at least r of m endpoints, with Bonferroni, Holm or Hochberg); PUMP 1.0.5 (multilevel randomised trials: individual, at least one, all); crt2power 1.2.2 (cluster trials with two co-primary outcomes). pwr 1.3-0: none found. G\*Power: to confirm from screenshots. Why joint power matters: Rubin (2021, author preprint, p. 7; opened) shows two conjunction tests "each tested with a power value of .80" give "a power level of .64" | [B6][], [D6][], [G3][], [G7][] |
| C3 | Attrition/missing-data inflation of N | `options > attrition` is asked on every input screen. Since 17 October 2026 (the maintainer's decision) the engine turns the analysed N into a number to recruit, each group's N / (1 − attrition) rounded up (`engine/R/recruitment.R`); the result screen shows both numbers with a caveat, and the exported script works it out too | Partly working (simple inflation only) | Missing data beyond attrition: power4mome `missing_values()`; mlmpower `MCAR()`, `MAR()`; longpower `power.mmrm()` (retention per group); powerlmm dropout patterns (`dropout_weibull()`, `dropout_manual()`; archived on CRAN). Mikael Rubin (2025, p. 14 of 15; opened) describes simple N inflation ("if you have 80% power to detect an effect for an N = 100, but expect 20% dropout, you could then say the target sample size is 120") as "a frequently applied heuristic", and adds: "this approach can be problematic given that there are different patterns of missing data and missing data are handled in different ways (i.e., listwise deletion, maximum likelihood, multiple imputation) depending on the modelling approach". He doesn't use the word "crude" (the maintainer's earlier paraphrase). His example multiplies by 1.2 (100 to 120); dividing by 1 − .20, as powerkit now does, gives 125. Handling missing data beyond simple inflation is not built | [G3][] |
| C4 | Unequal allocation ratios | Two-group tests (`options > allocation_ratio`); 2 x 2 between designs (E22, `options > cell_ratio`, 29 October 2026); larger factorial and mixed designs no | Done (validated and wired) | Spower `n2_n1`, `n.ratios`; pwr `pwr.t2n.test()`, `pwr.2p2n.test()`; Superpower `ANOVA_power()` with an n vector (between designs only) | [G3][] |
| C5 | Measurement unreliability | E9 (reliability of X, W, Y) | Done for E9 (validated and wired: its input screen has an optional group for all three reliabilities, each left empty for a perfectly reliable measure). Latent models for mediation are not offered | InteractionPoweR `rel.x1`, `rel.x2`, `rel.y`; power4mome latent models (`reliability`) for mediation | [B8][], [G3][] |
| C6 | Non-normal data and unequal variances (simulation option) | Unequal variances: Welch (E2), cell SDs (E7, E8). Non-normal data: none | Done (validated and wired; unequal variances only) | Spower `parent1`/`parent2` (Wilcoxon), `gen_fun`; power4mome `x_fun`/`e_fun` with `rbeta_rs()`, `rexp_rs()`, `rlnorm_rs()`, `rt_rs()`, `runif_rs()`, `rpgnorm_rs()` | [G3][] |
| C7 | Covariates | One-way ANCOVA (E23, one or more covariates as an R-squared) | Planned (v2 in the build guide for ANCOVA; no phase) | Superpower `ANCOVA_analytic()`; InteractionPoweR `power_interaction_r2_covs()`; power4mome lavaan models; Spower `p_glm()` | [D7][], [C15][] |
| C8 | One- vs two-tailed | Two-sided default; one-sided for basic tests | Done (validated and wired) | Spower `alternative`; pwr `alternative` | [B3][] |
| C9 | Effect-size input formats and conversion | One format per end point (d, d_z, r, proportions, cell probabilities, means and SDs, standardised paths, correlations) | Partly working (30 October 2026: a published t, F, r, d or odds ratio converted with effectsize on the one-sample, paired and two-group t-tests and the correlation; the ANOVA cards' f next, `next.md` item 1) | pwr `ES.h()`, `ES.w1()`, `ES.w2()`; Superpower `mu_from_ES()`; pwrss `means.to.d()`, `etasq.to.f()`, `f.to.rsq()` and others (cross-check package) | [B10][], [G3][] |
| C10 | Effect sizes from pilots or the literature (bias correction) | Safeguard power (Perugini, Gallucci and Costantini, 2014) for the one-sample, paired and two-group t-tests and the correlation: plan with the lower bound of a confidence interval around one earlier study's estimate (`engine/R/safeguard.R`, intervals from psych). Other designs: warnings only | Partly working (safeguard power for four designs) | BUCSS `ss_buc_*()`; mixpower `mp_safeguard_effect()` | [B2][], [A8][] |
| C11 | Power curves and sensitivity plots | `curve` in the result (power by N); a sensitivity goal on E1 to E9; the result screen's "explore" plot draws power against N (`explore_curve()`, `plotOutput("explore_plot")` in `app/routing/R/results.R`) | Done (validated and wired), except that whether a power curve is shown by default is still an undecided setting (`power_curve`) | Spower `SpowerCurve()`; power4mome `power_curve()`; InteractionPoweR `plot_power_curve()`; Superpower `plot_power()`, `morey_plot()`; pwr `plot.power.htest()` | [G3][] |
| C12 | Frequentist vs Bayesian framework | Frequentist only | Planned (later in the build guide: Bayesian design analysis; no phase) | See B58–B62 | [D3][], [G2][] |

## Part D: out of scope

Stated so they aren't mistaken for gaps.

| # | Item | Why | Source |
| --- | --- | --- | --- |
| D1 | Qualitative sample size (for example, saturation) | No statistical test or estimate to plan for | ML; build guide, section 2 ("Out of scope") |
| D2 | Anything without a statistical test or estimate to plan for | Power and precision need one | ML |
| D3 | Purely computational text studies (for example, topic models) | "has no agreed framework; leave it out rather than invent one" | Build guide, section 2 |
| D4 | Observed (post hoc) power from a study's own estimate, as a justification | Not a planning question; whether to warn or refuse is open | [B1][] (status Out of scope only if the maintainer decides so) |

## Summary

Counts are of the rows above. Parts A, B and C have 49, 69 and 12 rows.

Every line below was counted from the rows themselves (26 October 2026),
and they add up to all 130 rows. The table had been drifting: three
statuses the rows use ("Wired", "No ready-made tool" and "Partly
working") were missing from it altogether, so its lines covered only 125
rows, and four of the others were out by a few. The consistency test in
`app/routing/tests/testthat/test-repo-consistency.R` now counts the rows
and fails if a line here disagrees.

| Status | Part A | Part B | Part C | Total |
| --- | --- | --- | --- | --- |
| Done (validated and wired) | 10 | 8 | 5 | 23 |
| Wired (validation not finished) | 25 | 17 | 0 | 42 |
| Validated, not wired | 0 | 0 | 0 | 0 |
| Planned | 4 | 12 | 2 | 18 |
| Foundation tool can do it, not planned | 6 | 8 | 1 | 15 |
| No ready-made tool | 0 | 5 | 0 | 5 |
| Partly working | 0 | 1 | 4 | 5 |
| G\*Power covers it, powerkit doesn't | 3 | 0 | 0 | 3 |
| Unknown | 1 | 18 | 0 | 19 |
| Out of scope | 0 | 0 | 0 | 0 |

(Part D's four rows are out of scope by definition and aren't counted.)

**Cheapest additions** (a foundation tool already does it, and powerkit
needs only a routing change, a new field or an output it already has):

- **A2, A7: point-biserial r and the slope of a simple regression.** The
  same tests as E2 and E4 with the effect entered differently; an
  effect-size conversion on the existing cards.
- **A38: Fisher's exact test.** Spower's `p_prop.test(exact = TRUE)`, the
  same function E5 calls (judgement call 3.9).
- **A42: chi-square goodness-of-fit.** Spower's `p_chisq.test()` with
  `P0` and `P`, which E6 already calls (judgement call 3.7).
- **A35, A37: one proportion and McNemar.** Now wave 2 (engine
  groundwork with pwrss's exact tests); E25 and E26 already exist as
  honest cards.
- **A10–A13: multiple regression.** A10 and A11 are now wave 2 (pwrss's
  `power.f.regression()`); A12 and A13 could follow with Spower's
  `p_lm.R2()`; E24 exists.
- **B60: expected power over a prior.** Spower's documented "expected
  power", given a prior for the effect instead of a single value.

**What the current question tree can't reach.** Of the 118 rows in Parts
A and B:

- 69 (22 in Part A, 47 in Part B) reach a card for their own analysis:
  a running end point or an honest card, counting E2 and E4 for A2 and A7,
  which are the same tests entered differently;
- 18 (9 and 9) reach a card for a different analysis, for example a rank
  test reaching a t-test, a goodness-of-fit test reaching E6, or
  mediation with covariates reaching E10, which has none;
- 31 (18 and 13) aren't reachable: no answer names them, and only the
  safety net applies.

So 49 of the 118 rows (18 + 31) can't be reached as themselves. Rows marked
*(inferred)* were worked out for this page, not walked through.

**Multilevel and longitudinal candidates (added 17 October 2026).** The
maintainer notes that Mikael Rubin (2025, *International Journal of
Psychology*, doi:10.1002/ijop.70017; a different author from Mark Rubin)
names mlmpower, simr, longpower, powerlmm and mixedpower. **Checked
against the full text (opened 17 October 2026): it names all five.** All
five are rows of its Table 1, "R packages for multilevel power" (p. 6 of
15), spelt "MLMPower", "Longpower", "PowerLMM", "MixedPower" and "SimR".
Two are also named in the text:

- mlmpower: "The specification of features in the package mlmpower
  (Keller 2024) will be reviewed" (p. 2); the text also says "the
  MLMpower package (Enders et al. 2023)" (p. 6);
- simr: "for instance see simR, which focuses on model-based power
  analysis (Green and MacLeod 2016)" (p. 3).

longpower, powerlmm and mixedpower appear only in Table 1, with no
citation. Table 1's "Cons" column says PowerLMM and MixedPower are "Not
available on CRAN" and "Not recently supported", which matches what was
found below. The article also names pwr and InteractionPoweR ("interactionPoweR;
Baranger et al. 2023", p. 5). Each package was checked in its own source:
mlmpower 1.0.11, simr 1.0.11 and longpower 1.0.27 are on CRAN; powerlmm
was archived on CRAN on 7 June 2021 (0.4.0 read from the archive);
mixedpower isn't on CRAN (0.1.0 read from GitHub, DejanDraschkow/mixedpower,
commit 69680b3). They are added to rows B34, B36 and B41 as candidates;
their missing-data options are under C3.

**Tests named by an outside review that these rows don't cover (26 October
2026).** From a catalogue of psychology power analyses the maintainer
commissioned from a language model. Its frequency claims and effect-size
benchmarks are unsourced and are not used here; these are only the test
names worth checking, each **unverified** — no package, method or claim
below has been read against its documentation yet, so none is a batch
until it goes through
[`adding-a-test.md`](adding-a-test.md) section 2.

- **Pitman–Morgan test**: variances compared in a paired design. The
  natural sibling of A43 and A44. In the app since 29 October 2026 (E57,
  simulated with Spower's `p_r()` on the sum and difference of the paired
  scores).
- **Barnard's unconditional exact test** for a 2x2 table: an alternative
  to Fisher's exact test (E5's test version), said to be more powerful.
- **Cochran–Armitage trend test**: a linear trend in proportions across
  ordered groups (dose, age band).
- **Jonckheere–Terpstra trend test**: the rank-based equivalent for
  ordered alternatives across k groups.
- **Spearman's rho and Kendall's tau**: power for rank correlations. In
  the app since 29 October 2026 as a test version on E4 (Spower's
  `p_r(method =)`, normal scores).
- **Cronbach's alpha against a benchmark** (Bonett and Wright's formula):
  scale-development studies planning for a minimum internal consistency.
  B50 covers ICC and kappa but not alpha.
- **Multinomial logistic regression**, and **generalised estimating
  equations (GEE)** as an alternative to the mixed-model rows.
- **Stepped-wedge cluster trials** (Hussey and Hughes): clusters crossing
  over in stages, alongside B39's parallel cluster trial.
- **Competing risks (Fine–Gray)** beside the survival rows.
- **Comparing two ROC curves** (DeLong's test), where the ROC row covers
  one curve against a benchmark.
- **Welch's one-way ANOVA** for unequal variances, beside A23's omnibus F: in the app as E18's test version since 29 October 2026 (Spower, by simulation).
- **From a review of the tests psychologists most often report (29
  October 2026; `next.md` items 24 to 27):** the Brunner-Munzel test,
  the aligned rank transform for factorial designs, Quade's
  non-parametric ANCOVA, PERMANOVA; pairwise follow-ups after an ANOVA
  (Tukey's HSD, Games-Howell, Dunnett, simple effects; see C1); robust
  (HC3 or HC4) and quantile regression; McDonald's omega, Fleiss' kappa
  and Krippendorff's alpha beside B50; and signal detection sensitivity
  (d'). Effect-size formats users bring (d_rm, d_av, omega squared,
  generalised eta squared) belong to C9.
- **Average power under FDR control** (Jung; Liu and Hwang): the sample
  size at which a stated share of truly active channels or voxels is
  detected at q = .05. Different in kind from the per-test corrections in
  C7, and the honest way to plan a mass-univariate EEG or fMRI study.

Three product ideas from the same review, recorded in
[`decisions.md`](decisions.md) (26 October 2026) rather than here: a
safeguard-power adjuster for effect sizes taken from a pilot, a power
curve showing an optimistic and a conservative effect either side of the
expected one, and a downloadable synthetic data set for pre-registration.

**Flagged while writing this page:**

- Spower 0.7's `p_var.test()` (A43, A44): `two.tailed = FALSE` means
  "greater" whichever way the variances point, so a one-sided test of a
  *smaller* variance has no power unless `alternative` is passed (the
  version of G\*Power's Example 26.3 in Spower's own vignette hits this);
  and `gen_var.test()` fails outright for unequal groups, so the
  allocation-ratio case of Example 15.3 can't be simulated. powerkit
  always passes `alternative` and refuses an allocation ratio for A44.
  Reported in [`upstream-questions.md`](upstream-questions.md), with a
  reproducible example in `docs/upstream/spower-var-test.R`.
- Spower 0.7's `p_r()` with `rho` ≠ 0 always returns a two-sided p-value
  (`pnorm(abs(t), lower.tail = FALSE) * 2`), whatever `alternative` says
  (Spower source, `R/p_r.R`). powerkit doesn't use a non-zero ρ0 yet; if
  it does, one-sided tests against ρ0 would need a workaround or an
  upstream fix. Recorded in [`decisions.md`](decisions.md) (17 October
  2026); the question is listed in
  [`upstream-questions.md`](upstream-questions.md) (not yet raised).
- pwr's two-proportion functions (`pwr.2p.test()`, `pwr.2p2n.test()`) use
  Cohen's h (the arcsine transformation), which isn't the z test G\*Power
  lists (A41). The size of the difference is in
  [G6](archive/judgement-calls-decided.md#g6-the-method-for-correlations-e4-and-for-two-proportions-e5).
  The maintainer wants a z test as E5's default; base R's
  `power.prop.test()` is being checked against G\*Power first.

[A1]: judgement-calls.md#a1-naming-other-tools-on-not-covered-cards
[A2]: archive/judgement-calls-decided.md#a2-e45-says-no-ready-made-tool-but-pits-exists
[A5]: judgement-calls.md#a5-the-dyadic-cards-wording-e44
[A6]: judgement-calls.md#a6-the-segmented-regression-cards-points-and-e45-vs-e35
[A8]: judgement-calls.md#a8-the-reason-given-for-the-pilot-study-warning
[B1]: judgement-calls.md#b1-observed-power-judgement-call-31
[B2]: judgement-calls.md#b2-effect-size-benchmarks-and-bias-correction-judgement-call-32
[B3]: judgement-calls.md#b3-one-sided-tests-judgement-call-33
[B6]: judgement-calls.md#b6-power-for-several-hypotheses-in-one-study-judgement-call-35
[B7]: judgement-calls.md#b7-simple-effects-as-a-target-judgement-call-34
[B8]: archive/judgement-calls-decided.md#b8-reliability-for-e15s-score-variable
[B9]: judgement-calls.md#b9-three-or-more-parallel-mediators-open-question-10
[B10]: judgement-calls.md#b10-effect-sizes-on-the-input-screens
[C2]: judgement-calls.md#c2-matched-pairs-vs-dyads-open-question-19
[C3]: judgement-calls.md#c3-diary-studies-walkthrough-flag-f12
[C4]: judgement-calls.md#c4-reliability-studies-inter-rater-and-testretest
[C6]: judgement-calls.md#c6-several-categories-same-people
[C7]: judgement-calls.md#c7-factorial-yesno-outcome-through-q1s-moderation-answer
[C9]: judgement-calls.md#c9-chi-square-goodness-of-fit-judgement-call-37
[C10]: judgement-calls.md#c10-rank-based-tests-reaching-the-parametric-cards-judgement-call-38
[C11]: judgement-calls.md#c11-fishers-exact-test-reaching-the-large-sample-tests-judgement-call-39
[C12]: judgement-calls.md#c12-curvilinear-effects
[C13]: judgement-calls.md#c13-sequential-designs
[C14]: judgement-calls.md#c14-several-outcomes-manova
[C15]: judgement-calls.md#c15-covariates-other-than-a-baseline-in-a-two-group-comparison
[C16]: judgement-calls.md#c16-latent-variable-mediation-entered-as-mediation
[C17]: judgement-calls.md#c17-ratings-and-counts-beyond-differences-decision-d1
[C18]: judgement-calls.md#c18-sem-in-the-guided-route-walkthrough-flag-f8
[D3]: judgement-calls.md#d3-where-bayes-factors-enter-open-question-8
[D6]: judgement-calls.md#d6-consistency-between-hypotheses-open-question-12
[D7]: judgement-calls.md#d7-covariates-in-each-analysis-open-questions-13-and-15
[E2]: judgement-calls.md#e2-scripts-for-designs-powerkit-doesnt-run-open-question-7
[E4]: judgement-calls.md#e4-phase-3b-binary-x-and-w
[E5]: judgement-calls.md#e5-the-engine-still-accepts-reliabilities-for-a-binary-x-or-w
[G1]: judgement-calls.md#g1-scope-for-the-gpower-tests-powerkit-doesnt-run
[G2]: judgement-calls.md#g2-frequentist-or-bayesian-in-the-screening
[G3]: judgement-calls.md#g3-which-cross-cutting-features-belong-in-v1
[G7]: judgement-calls.md#g7-a-multiple-testing-correction-by-default
