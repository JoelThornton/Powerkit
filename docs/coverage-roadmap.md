# Coverage roadmap

*Last updated: 18 October 2026.*

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
| Status | Exactly one of: **Done** (validated and wired) · **Validated, not wired** · **Planned** (phase named) · **Foundation tool can do it, not planned** · **G\*Power covers it, powerkit doesn't** · **Unknown** (what to check) · **No ready-made tool** · **Out of scope** |
| Analysis types | **Now:** what powerkit offers today. **Could:** what the candidate backend's help documents. AP = a priori (required N); PN = power at a given N; S = sensitivity (smallest detectable effect); Co = compromise; Cr = criterion (alpha) |
| Candidate backend and function | Checked in the package's help pages (see Sources); otherwise "unknown" or "candidate" |
| Next step | What would move the row on |
| Blocking decision | An entry in [`judgement-calls.md`](judgement-calls.md), or — |

**"Wired"** means the app runs the calculation. E1–E8 are wired (PR #34,
merged 17 October 2026); E9–E14 run in the engine but the app shows
guidance only.

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
| A4 | Two dependent Pearson r's (common index) | GP | none: no answer fits; nearest E4 *(inferred)* | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | Spower `p_2r()` (default test `"steiger1980"` for overlapping correlations; Example 28.3.2). pwrss `power.z.twocors.steiger(common.index = TRUE)` (cross-check) | — | [G1][] |
| A5 | Two dependent Pearson r's (no common index) | GP | none: no answer fits; nearest E4 *(inferred)* | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | Spower `p_2r()` with `r.ad`, `r.bd`, `r.cd` (Example 28.3.1) | — | [G1][] |
| A6 | Two independent Pearson r's | GP | E49 | Wired (app PR in review; not yet checked against G\*Power) | Could: AP, PN, S, Co, Cr | **Engine: pwrss `power.z.twocors(rho1, rho2, n2, n.ratio)`** (Fisher's z test; template `two_correlations`). Spower `p_2r(r.ab, r.ab2, n2_n1)` (default test `"fisher1925"`; Example 27.3) | — | [G1][] |
| A7 | Linear bivariate regression: one group, size of slope | GP; UCLA | E4 (the test of a slope of 0 is the test of r = 0; audit) | Done (validated and wired) | Now: AP, PN (as r). Could: AP, PN, S, Co, Cr | Spower `p_slr(beta, sd_x, sd_y, beta0)` (Example 12.3); pwr `pwr.r.test()` for a slope of 0 | Accept slope and SDs on E4, or a card note; a non-zero null slope needs `p_slr()` | [G3][] |
| A8 | Linear bivariate regression: two groups, difference between intercepts | GP | none: not reachable *(inferred)* | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | Spower `p_glm()` with a user-written data generator (Examples 17.3 and 18.3 in Spower's vignette write one) | — | [G1][] |
| A9 | Linear bivariate regression: two groups, difference between slopes | GP | E15 (a yes/no W × continuous X interaction is a difference in slopes) | Planned (phase 3b) | Now: —. Could: AP, PN (InteractionPoweR, by a grid over N) | InteractionPoweR `power_interaction(k.x2 = 2)`: groups split 50/50 only. Spower `p_glm()` as A8 for unequal groups | Phase 3b; G\*Power allows unequal groups, InteractionPoweR doesn't | [E4][] |
| A10 | Linear multiple regression: fixed model, R² deviation from zero | GP; UCLA | E24 | Planned (wave 2: engine groundwork, draft PR; not wired) | Engine: AP, PN (pwrss). Could: AP, PN, S, Co, Cr (Spower); AP, PN, S, Cr (pwr) | **Engine: pwrss `power.f.regression(r.squared.change, k.total, k.tested)`** (noncentrality f² × n, from its source). Spower `p_lm.R2(R2, k)` (Example 13.1); pwr `pwr.f2.test()` | G\*Power screenshots (wave 2 list below), then wire | [G1][] |
| A11 | Linear multiple regression: fixed model, R² increase | GP | E24 | Planned (wave 2: engine groundwork, draft PR; not wired) | As A10 | **Engine: pwrss `power.f.regression()`, passed the partial R² (R²full − R²reduced) / (1 − R²reduced), so f² = ΔR² / (1 − R²full)**. Spower `p_lm.R2(R2, k, R2_0, k.R2_0)` (Example 14.3); pwr `pwr.f2.test(u = )` (its noncentrality f² × (u + v + 1) differs) | G\*Power screenshots (wave 2 list below), then wire | [G1][] |
| A12 | Linear multiple regression: fixed model, single regression coefficient | GP | E24 | Foundation tool can do it, not planned | As A10 | Spower `p_glm()` (one coefficient, tested with `car::lht()`); pwr `pwr.f2.test(u = 1)` | As A10 | [G1][] |
| A13 | Linear multiple regression: random model | GP | E24 | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | Spower `p_lm.R2(fixed = FALSE)` (Example 7.3) | — | [G1][] |
| A14 | Logistic regression | GP; UCLA | E27 | Planned (phase 6: GLMs) | Could: AP, PN, S, Co, Cr | Spower `p_glm(family = binomial())` | Phase 6 | — |
| A15 | Poisson regression | GP | E28 | Planned (phase 6: GLMs) | Could: AP, PN, S, Co, Cr | Spower `p_glm(family = poisson())` | Phase 6 | — |

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
| A17 | One group: Wilcoxon | GP; UCLA (one-sample median) | none: reaches E1 | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | Spower `p_wilcox.test(type = "one.sample", parent1)` (Examples 22.1, 22.3) | Decide judgement call 3.8 | [C10][] |
| A18 | Two dependent groups (matched pairs) | GP; UCLA | E3 | Done (validated and wired) | As A16 | Spower `p_t.test(type = "paired")` (Example 19.3); pwr `pwr.t.test(type = "paired")` | — | — |
| A19 | Two dependent groups: Wilcoxon | GP; UCLA | none: reaches E3 | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | Spower `p_wilcox.test(type = "paired")` (Example 23.3) | As A17 | [C10][] |
| A20 | Two independent groups | GP; UCLA | E2 | Done (validated and wired) | As A16 | Spower `p_t.test(n2_n1)`; pwr `pwr.t.test()`, `pwr.t2n.test()` (unequal groups) | — | — |
| A21 | Two independent groups: Wilcoxon | GP; UCLA | none: reaches E2 | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | Spower `p_wilcox.test(type = "two.sample", n2_n1, parent1, parent2)` | As A17 | [C10][] |
| A22 | ANCOVA: main effects and interactions | GP; UCLA; BG | E23 | Wired, one-way overall test only ( not yet checked against G\*Power) | Could: PN, AP (by a search over n) | **Engine (one-way, one or more covariates): pwrss `power.f.ancova.shieh()`** (Shieh's method; template `oneway_ancova`; agrees with Superpower `power_oneway_ancova(type = "exact")` in a test). Superpower `ANCOVA_analytic()`, `power_oneway_ancova()`, `ANCOVA_contrast()`. Confirmed in G\*Power's menu (maintainer, 17 October 2026) | Name a phase | [C15][], [D7][] |
| A23 | ANOVA: one-way | GP; UCLA | E18 | Planned (wave 2: engine groundwork, draft PR; not wired) | Engine: AP, PN (Superpower, exact). Could: S (not yet: which pattern to scale is open); AP, PN, S, Co, Cr (Spower); AP, PN, S, Cr (pwr) | **Engine: Superpower `ANOVA_design("kb")` + `ANOVA_exact()`** (equal groups, equal SDs; agrees with pwr `pwr.anova.test()` in a test). Also `power_oneway_between()`; Spower `p_anova.test(n.ratios, var.equal)` (Example 10.3) | G\*Power screenshots (wave 2 list below), then wire | [G1][] |
| A24 | ANOVA: main effects and interactions (two or more IVs) | GP; UCLA | E7 (2 x 2); E21 (larger) | Done (validated and wired) | Now: AP, PN, S (2 x 2). Could: Co (Superpower `ANOVA_compromise()`) | Superpower `ANOVA_exact()`, `ANOVA_power()`; `power_twoway_between()`, `power_threeway_between()` for larger designs | 2 x 2 only; 2 x 2 x 2 is in the build guide's MVP family with no phase | [G1][] |
| A25 | Repeated measures: between factors, ANOVA-approach | GP | E8 (the group effect in a 2 x 2 mixed design) | Done (validated and wired) | Now: AP, PN, S (2 x 2 mixed) | Superpower `ANOVA_exact()` (`"2b*2w"` and larger designs) | Larger designs: E21 | [G1][] |
| A26 | Repeated measures: between factors, MANOVA-approach | GP | none: not reachable | Unknown (check whether Superpower's `manova_results` includes the between-factor effect; its help says only that MANOVA results are given "if a within-subjects factor is included") | — | Superpower `ANOVA_exact()` / `ANOVA_power()`, element `manova_results` (candidate) | Check | [G1][] |
| A27 | Repeated measures: within factors, ANOVA-approach | GP; UCLA | E8 (2 x 2 mixed); E18 and E20 (honest cards) | Done (validated and wired) | Now: AP, PN, S (2 x 2 mixed's within effect) | Superpower `power_oneway_within()`, `ANOVA_design("kw")`, `"2w*2w"`; sphericity `correction` (GG, HF) in `ANOVA_power()` | One-way and 2 x 2 within: coverage.md proposes v2 | [G1][] |
| A28 | Repeated measures: within factors, MANOVA-approach | GP | none: not reachable | Foundation tool can do it, not planned | Could: PN | Superpower `ANOVA_exact()` / `ANOVA_power()`, element `manova_results` (given when a within factor is included) | Report `manova_results`, which E8 already computes | [G1][] |
| A29 | Repeated measures: within-between interactions, ANOVA-approach | GP | E8 | Done (validated and wired) | Now: AP, PN, S | Superpower `ANOVA_exact()` (`"2b*2w"`) | — | — |
| A30 | Repeated measures: within-between interactions, MANOVA-approach | GP | none: not reachable | Foundation tool can do it, not planned | Could: PN | As A28 | As A28 | [G1][] |
| A31 | Hotelling T², one group | GP | none: not reachable | G\*Power covers it, powerkit doesn't | — | unknown (none found in the foundation tools' help) | — | [G1][] |
| A32 | Hotelling T², two groups | GP | none: not reachable | G\*Power covers it, powerkit doesn't | — | unknown in the foundation tools. BUCSS `ss_buc_manova()` (two-group multivariate comparison, with bias correction) is a candidate | — | [G1][] |
| A33 | MANOVA: global effects | GP; UCLA | none: not reachable | G\*Power covers it, powerkit doesn't | — | unknown (Superpower's MANOVA output is for within factors only) | — | [C14][], [G1][] |
| A34 | MANOVA: special effects and interactions | GP | none: not reachable | G\*Power covers it, powerkit doesn't | — | unknown | — | [C14][], [G1][] |

### Proportions

| # | Test | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A35 | One group: difference from constant | GP; UCLA (binomial test) | E25 | Planned (wave 2: engine groundwork, draft PR; not wired) | Engine: AP, PN (pwrss, exact). Could: AP, PN, S, Co, Cr (Spower); AP, PN, S, Cr (pwr) | **Engine: pwrss `power.exact.oneprop(prob, null.prob)`** (exact binomial). Spower `p_prop.test(prop, pi)` (Example 4.3); pwr `pwr.p.test()` (arcsine h, normal approximation) | G\*Power screenshots (wave 2 list below), then wire | [G1][] |
| A36 | One group: sign test | GP | none: reaches E1 or E3 *(inferred)* | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | candidate: Spower `p_prop.test(prop, pi = 0.5)` with the effect entered as the proportion of positive differences (inferred, not in Spower's help). powertools `signtest()` | Confirm the inference | [C10][] |
| A37 | Two dependent groups: McNemar | GP; UCLA | E26 | Planned (wave 2: engine groundwork, draft PR; not wired) | Engine: AP, PN (pwrss, exact). Could: AP, PN, S, Co, Cr (Spower) | **Engine: pwrss `power.exact.mcnemar(prob10, prob01, method = "exact")`** (prob10 = yes in the second condition only). Spower `p_mcnemar.test(prop, OR, prop.disc)` (Example 5.3) | G\*Power screenshots (wave 2 list below), then wire | [G1][] |
| A38 | Two independent groups: Fisher's exact | GP; UCLA | E5 (test version) | Wired as E5's test version (app PR in review; not yet checked against G\*Power) | Could: AP, PN, S, Co, Cr | **Engine: pwrss `power.exact.fisher(method = "exact")`** (template `two_proportions`, `target_test > method = "fisher_exact"`). Spower `p_prop.test(exact = TRUE)` (`prop` as a matrix; `fisher.test()`). pwrss `power.exact.fisher()` (cross-check). Confirmed in G\*Power's menu (maintainer, 17 October 2026) | Decide judgement call 3.9 | [C11][] |
| A39 | Two independent groups: unconditional exact | GP | none: reaches E5 *(inferred)* | G\*Power covers it, powerkit doesn't | — | unknown (no unconditional exact test found in the foundation tools' help) | — | [G1][] |
| A40 | Two independent groups: inequality with offset, unconditional exact | GP | none: not reachable | G\*Power covers it, powerkit doesn't | — | unknown | — | [G1][] |
| A41 | Two independent groups: z-test | GP; UCLA (chi-square, two groups) | E5 | Done (validated and wired) | Now: AP, PN. Could: AP, PN, S, Co, Cr (Spower); AP, PN, S, Cr (pwr) | Spower `p_prop.test(prop = c(p1, p2), correct = FALSE)`; pwr `pwr.2p.test()`, `pwr.2p2n.test()` (Cohen's h, the arcsine transformation) | Default to a z test (maintainer, 17 October 2026): check base R's `power.prop.test()` against G\*Power's screenshots, then switch | G\*Power screenshots; the maintainer's yes |
| A42 | Multigroup: goodness-of-fit | GP; UCLA | E48 (own card, judgement call 3.7 decided 19 October 2026) | Wired (app PR in review; not yet checked against G\*Power) | Could: AP, PN, S, Co, Cr (Spower); AP, PN, S, Cr (pwr) | **Engine: pwrss `power.chisq.gof()`, with Cohen's w from `probs.to.w()`** (template `chi_square_gof`; agrees with pwr `pwr.chisq.test()` in a test). Spower `p_chisq.test(w, df)` or `P0`, `P`; pwr `pwr.chisq.test()`, `ES.w1()` | Check against G\*Power | [C9][] |

### Variances

| # | Test | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A43 | Variances: one group | GP | none: not reachable | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | Spower `p_var.test(vars, sigma2)` (Example 26.3) | coverage.md: not planned | [G1][] |
| A44 | Variances: two groups | GP | none: not reachable | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | Spower `p_var.test(vars = c(v1, v2))` (Example 15.3). Its `test` argument (Levene, Bartlett, Fligner) is documented for "multi-sample applications"; which test it runs for two groups, and whether that is G\*Power's F test, is unknown | Check against G\*Power before use | [G1][] |

### Generic

| # | Test | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A45 | Generic: binomial | GP | none: not reachable | G\*Power covers it, powerkit doesn't | — | The same test as one proportion against a fixed value (A35): pwrss `power.binom.test()` gives the same power as `power.exact.oneprop()` (checked 18 October 2026). pwrss `power.binom.test()` (pwrss became a foundation tool on 17 October 2026, for E5's unequal groups) | coverage.md: not planned (the R script export is the route) | [G1][] |
| A46 | Generic: F | GP | E50 (only from "I know my analysis") | Wired (app PR in review; no sample size; not yet checked against G\*Power) | — | **Engine: pwrss `power.f.test(ncp, df1, df2)`** (template `generic_test / f`). pwrss `power.f.test(ncp, df1, df2)`; Superpower `power.ftest()` (candidate: check its arguments) | As A45 | [G1][] |
| A47 | Generic: t | GP | E50 (only from "I know my analysis") | Wired (app PR in review; no sample size; not yet checked against G\*Power) | — | **Engine: pwrss `power.t.test(ncp, df)`** (template `generic_test / t`). pwrss `power.t.test(ncp, df)` | As A45 | [G1][] |
| A48 | Generic: chi² | GP | E50 (only from "I know my analysis") | Wired (app PR in review; no sample size; not yet checked against G\*Power) | — | **Engine: pwrss `power.chisq.test(ncp, df)`** (template `generic_test / chi_square`). pwrss `power.chisq.test()` | As A45 | [G1][] |
| A49 | Generic: z | GP | E50 (only from "I know my analysis") | Wired (app PR in review; no sample size; not yet checked against G\*Power) | — | **Engine: pwrss `power.z.test(mean = ncp)`** (template `generic_test / z`). pwrss `power.z.test()` | As A45 | [G1][] |

## Part B: beyond G\*Power

Rows the maintainer listed (ML). "Unknown" where it isn't clear.

### Interactions

| # | Design | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B1 | Continuous × continuous | ML; BG | E9 | Validated, not wired | Now: AP, PN. Could: AP, PN, S (by grids over N and effect) | InteractionPoweR `power_interaction()`; `power_interaction_r2()` (analytic, brackets N) | Wire (draft PR from the other thread) | — |
| B2 | Binary × continuous | ML; BG | E15 | Planned (phase 3b) | Could: AP, PN, S | InteractionPoweR `power_interaction(k.x1 = 2)` (50/50 split only) | Phase 3b | [E4][], [E5][] |
| B3 | Binary × binary | ML | E7 (2 x 2 between ANOVA interaction) | Done (validated and wired) | Now: AP, PN, S | Superpower `ANOVA_exact()`; InteractionPoweR `k.x1 = 2, k.x2 = 2` as a cross-check (build guide, phase 3b c) | — | — |
| B4 | Categorical moderator with 3+ levels | ML; Audit | E30 | No ready-made tool | — | InteractionPoweR's `k.x1`/`k.x2` make ordered (binary or ordinal) variables, not unordered categories (coverage.md) | — | [A1][] |
| B5 | Three-way interaction | ML; BG | E31 | Foundation tool can do it, not planned | Could: PN, AP (by grid) | InteractionPoweR `power_interaction_3way_r2()` (analytic only), `cor.mat.3way()`; Superpower `power_threeway_between()` for three factors | coverage.md proposes v2 | — |
| B6 | Simple slopes | ML | none: no card asks (E9's target is the interaction) | Foundation tool can do it, not planned | Could: PN | InteractionPoweR `power_interaction(detailed_results = TRUE)`, `plot_simple_slope()`, `simple.slopes.3way()` | — | [B7][] |
| B7 | Curvilinear/quadratic effects | ML; Audit | none: reaches E4 | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | candidate: Spower `p_glm()` with a squared term in `formula` (inferred: `p_glm()` takes any formula) | Decide the card | [C12][] |

### Mediation

| # | Design | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B8 | Simple mediation | ML; BG | E10 | Validated, not wired | Now: AP, PN. Could: AP, PN, S | power4mome `power4test()` with `test_indirect_effect()`; `q_power_mediation_simple()`; `x_from_power(x = "n")`, `x_from_power(x = "es")` | Wire | — |
| B9 | Parallel mediation | ML; BG | E11 | Validated, not wired (two mediators) | As B8 | power4mome `q_power_mediation_parallel()` | Wire | — |
| B10 | Serial mediation | ML; BG | E12 | Validated, not wired (two mediators) | As B8 | power4mome `q_power_mediation_serial()` | Wire | — |
| B11 | 3+ mediators | ML | E11, E12 (the spec takes up to M9 parallel, M4 serial) | Planned (validation; status.md "What's next", item 1; no phase) | As B8 | As B9, B10 | Validate with three or more | [B9][] |
| B12 | Binary X | ML; BG | E16 | Planned (phase 3b) | Could: AP, PN, S | power4mome `x_fun` with `rbinary_rs()`; Spower `p_mediation(dichotomous.X = TRUE)` (Sobel/Wald test) | Phase 3b | [E4][] |
| B13 | Multi-category X | ML | E42 | No ready-made tool | — | none found (coverage.md) | — | — |
| B14 | Binary or count outcome | ML; Audit | E32 | No ready-made tool | — | none found: `x_fun` on an endogenous variable sets its error term, so a binary Y isn't covered (build guide, phase 3b a) | — | — |
| B15 | With covariates | ML | none: reaches E10–E12, which have no covariates | Foundation tool can do it, not planned | Could: AP, PN, S | power4mome `power4test(model = )`: any lavaan model, so covariates can be added as predictors | Add covariates to the spec | [D7][] |
| B16 | Latent-variable mediation | ML; Audit | E37; entered as mediation, E10 | Foundation tool can do it, not planned | Could: AP, PN, S | power4mome `power4test()` with `number_of_indicators`, `reliability` (vignette "power4test_latent_mediation") | — | [C16][] |
| B17 | Longitudinal mediation | ML | E41 | No ready-made tool | — | none found (coverage.md: within-person mediation) | — | — |

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
| B18 | PROCESS 7 (first stage) | ML; BG | E13 | Validated, not wired | Now: AP, PN. Could: AP, PN, S | power4mome `power4test()` with `test_index_of_mome()`; template `mome_obs_a` | Wire | — |
| B19 | PROCESS 14 (second stage) | ML; BG | E14 | Validated, not wired | As B18 | As B18; template `mome_obs_b` | Wire | — |
| B20 | PROCESS 8, 58, 59 | BG | E38 | Planned (v2 in the build guide, section 2; no phase named) | Could: AP, PN, S | power4mome `power4test(model = )` (no template). WebPower `wp.modmed.m8()`, `wp.modmed.m58()` (not foundation tools) | Name a phase | — |
| B21 | Other PROCESS models | ML | E40 (two or more mediators); otherwise none | Foundation tool can do it, not planned | Could: AP, PN, S | power4mome `power4test(model = )` (no template) | — | [E2][] |
| B22 | Moderated mediation with a binary X or W | BG | E17 | Planned (phase 3b) | Could: AP, PN, S | power4mome `x_fun` with `rbinary_rs()` | Phase 3b | [E4][] |
| B23 | Conditional indirect effects at chosen W | BG | none: reaches E13 or E14, which test the index | Foundation tool can do it, not planned | Could: AP, PN, S | power4mome `test_cond_indirect()`, `test_cond_indirect_effects()` | Needed for the Donnelly et al. (2023) benchmark | [B7][] |

### Other tests not in G\*Power

| # | Test | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B24 | Welch's t | ML | E2 (an option) | Done (validated and wired) | Now: AP, PN (Spower). Engine on request: AP, PN by formula (pwrss). Could: S, Co, Cr | Spower `p_t.test(var.equal = FALSE)` (default). **Engine, with `options > method = "exact"` only: pwrss `power.t.welch(d, var.ratio = 1, n.ratio)`** (wave 2, draft PR; the app still uses Spower) | G\*Power check of the formula (wave 2 list below) | — |
| B25 | Kruskal–Wallis | ML; UCLA | none: reaches E18 | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | Spower `p_kruskal.test(n, k, means, n.ratios)` | Decide judgement call 3.8 | [C10][] |
| B26 | Friedman | ML; UCLA | none: reaches E18 | Unknown (no Friedman power function in the foundation tools or the 47 other packages opened; check further) | — | unknown | Search | [C10][] |
| B27 | Cochran's Q | ML | E26 (its card says no ready-made tool) | No ready-made tool | — | none found | — | [C6][] |
| B28 | Factorial logistic regression | ML; UCLA | E47 | Planned (phase 6: GLMs) | Could: AP, PN, S, Co, Cr | Spower `p_glm(family = binomial())` with factor terms | Phase 6 | [C7][], [A1][] |
| B29 | Ordinal regression | ML; UCLA | E29 | Planned (phase 6: GLMs include ordinal outcomes) | Could: AP, PN | Hmisc `popower()` (proportional odds); powertools `propodds()`. Neither is a foundation tool | Choose a backend | [C17][] |
| B30 | Negative binomial and zero-inflated counts | ML | E28 | Unknown (check whether Spower `p_glm()` accepts a negative-binomial family; zero-inflated: no candidate found) | — | MKpower `power.nb.test()` (negative binomial; not a foundation tool) | Check | — |
| B31 | Partial correlation | ML | none: reaches E4 or E24 *(inferred)* | Foundation tool can do it, not planned | Could: AP, PN, S, Co, Cr | Spower `p_glm()` (one coefficient with covariates); pwr `pwr.f2.test(u = 1)`. That this is the same test as a partial correlation is inferred | — | [D7][] |
| B32 | Planned contrasts and trend analysis within ANOVA | ML; BG | E19 | Foundation tool can do it, not planned | Could: PN | Superpower `emmeans_power()`, and `ANOVA_power(emm = TRUE, contrast_type = )` (emmeans contrast methods; which methods give trends: check emmeans' help) | — | [B7][] |

### Experimental structure

| # | Design | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B33 | Crossover and counterbalanced designs | ML | E3 or E8 *(inferred)* | Unknown (check whether an AB/BA crossover analysed with order as a factor matches E8's 2 x 2 mixed design) | — | candidate: Superpower `"2b*2w"`. powertools `crt.xo.cont()` covers cluster crossover trials only | Check | — |
| B34 | Many trials per participant (trials vs participants trade-off) | ML; BG | E33 | Planned (phase 6: mixed-effects) | Could: AP, PN | simr `powerSim()`, `powerCurve()`; mixpower `mp_power()`, `mp_solve_sample_size()`; faux `sim_mixed_cc()` (data only); mixedpower `mixedpower()` *(GitHub only, 0.1.0)* | Phase 6 | — |
| B35 | Stimuli as a random factor | ML; BG | E33 | Planned (phase 6: mixed-effects) | As B34 | As B34 | Phase 6 | — |

### Dependence

| # | Design | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B36 | Multilevel/nested | ML; BG; Audit | E34 | Planned (phase 6: mixed-effects) | Could: AP, PN | mlmpower `power_analysis()`; simr `powerSim()`; mixedpower `mixedpower()` *(GitHub only, 0.1.0)* | Phase 6 | — |
| B37 | Crossed random effects | ML; BG; Audit | E33 | Planned (phase 6: mixed-effects) | As B34 | As B34 | Phase 6 | — |
| B38 | Mixed models with binary outcomes | ML | E33 or E34 | Planned (phase 6: mixed-effects) | Could: AP, PN | mixpower `mp_scenario_lme4_binomial()`; simr `powerSim()` (glmer models) | Phase 6 | — |
| B39 | Cluster-randomised | ML; Audit | E34 | Planned (phase 6: mixed-effects) | Could: AP, PN, S | WebPower `wp.crt2arm()`, `wp.crt3arm()`; powertools `crt.parallel.cont()`, `crt.parallel.bin()` | Phase 6 | — |
| B40 | Dyadic (APIM) | ML; Audit | E44 | Unknown (no APIM power function in the packages opened; check for a dedicated tool) | — | unknown | Search | [A5][], [C2][] |
| B41 | Growth curves | ML; BG; Audit | E35 | Planned (later in the build guide; no phase) | — | longpower `lmmpower()`, `power.mmrm()`; mlmpower `power_analysis()` with `within_time_predictor()`; powerlmm `study_parameters()`, `get_power()` *(archived on CRAN in 2021; 0.4.0)*; semPower `semPower.powerLGCM()`; WebPower `wp.lcsm()` | — | [A6][] |
| B42 | Diary/EMA and intensive longitudinal | ML; BG; Audit | E35 or E41 | Planned (later in the build guide; no phase) | — | PowerAnalysisIL *(coverage.md; GitHub, not on CRAN)* | — | [C3][] |
| B43 | Cross-lagged panel models (including random-intercept versions) | ML; BG | E35 | Planned (later in the build guide; no phase) | — | powRICLPM `powRICLPM()`; semPower `semPower.powerCLPM()`, `semPower.powerRICLPM()` | — | — |
| B44 | Segmented regression and interrupted time series | ML; Audit | E45 | Unknown (check PITS against the known-breakpoint case) | — | PITS `calculate_power()`, `run_its_power()` (single-site ITS). Estimated breakpoint: none found | Check PITS | [A2][], [A6][] |

### Latent and measurement

| # | Design | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B45 | SEM | ML; BG; Audit | E37 | Planned (later in the build guide; no phase) | Could: AP, PN, Co (semPower) | semPower `semPower.aPriori()`, `semPower.postHoc()`, `semPower.compromise()`, `semPower.powerLav()`, `semPower.powerPath()`; simsem `sim()`; power4mome (latent models) | — | [C18][] |
| B46 | CFA | ML; BG | E37 | Planned (later in the build guide; no phase) | As B45 | semPower `semPower.powerCFA()` | — | — |
| B47 | Measurement invariance | ML; BG | E37 | Planned (later in the build guide; no phase) | As B45 | semPower `semPower.powerMI()` (multigroup), `semPower.powerLI()` (longitudinal) | — | — |
| B48 | Latent interactions | ML | none: nearest E9 with reliabilities *(inferred)* | Unknown (no candidate found) | — | unknown | Search | — |
| B49 | Latent profile/class analysis | ML | none: not reachable | Unknown (no candidate found) | — | unknown | Search | — |
| B50 | Reliability (ICC) | ML; Audit | none: reaches E41, E4 or E46 | Unknown (decide the card; tools exist) | — | ICC.Sample.Size `calculateIccSampleSize()`; presize `prec_icc()`; MBESS `ss.aipe.reliability()`; kappaSize `PowerBinary()` (agreement) | Decide | [C4][] |
| B51 | IRT | ML; Audit | E37 (says IRT isn't covered) | Unknown (decide scope; tools exist) | — | irtpwr `irtpwr()`; irtsim `irt_simulate()` | Decide | — |
| B52 | Factor analysis sample size | ML; Audit | E37 (confirmatory); exploratory not reachable | Unknown (exploratory: no candidate found) | — | Confirmatory: semPower `semPower.powerCFA()` | — | — |
| B53 | Network models | ML; Audit | none: not reachable | Unknown (decide scope; a tool exists) | — | powerly `powerly()` ("Sample Size Analysis for Psychological Networks") | Decide | — |

### Other goals

| # | Goal | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B54 | Equivalence (TOST) | ML; BG; Audit | E36 | Planned (phase 6: equivalence) | Could: AP, PN, S, Co, Cr (Spower) | TOSTER `power_t_TOST()`, `powerTOSTone()`, `powerTOSTpaired()`, `powerTOSTtwo()`, `power_twoprop()`, `power_z_cor()`, `power_eq_f()`; Spower `is.CI_within()` (vignette "Equivalence testing") | Phase 6 | — |
| B55 | Non-inferiority | ML; Audit | E36 | Planned (phase 6: equivalence) | Could: AP, PN | candidate: a one-sided test against the margin (Spower `p_t.test(mu = )`, inferred); powertools `prop.2samp(margin = )` (coverage.md) | Phase 6 | — |
| B56 | Precision (CI width) | ML; BG; Audit | E46 | Planned (phase 6: AIPE) | Could: AP | MBESS `ss.aipe.smd()` and the other `ss.aipe.*()` functions; presize `prec_mean()`, `prec_meandiff()`; Spower precision criterion (vignette "Precision criterion", user-written) | Phase 6 | — |
| B57 | Group-sequential designs with interim analyses | ML; BG; Audit | none: not reachable | Planned (later in the build guide; no phase) | — | rpact `getDesignGroupSequential()`, `getSampleSizeMeans()`, `getPowerMeans()`; gsDesign `gsDesign()`; POSSA `sim()`, `pow()` | — | [C13][] |

### Bayesian

| # | Approach | Source | powerkit end point | Status | Analysis types | Candidate backend and function | Next step | Blocking decision |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| B58 | Bayes factor design analysis (fixed N) | ML; BG | none: not reachable | Planned (later in the build guide; no phase) | — | bfpwr `powertbf01()`, `powerbf01()`, `powerbinbf01()`, `powernmbf01()`; Spower with a user-written experiment using `BayesFactor::ttestBF()` (vignette "Bayes Factors"); BFDA *(coverage.md; GitHub)* | — | [D3][], [G2][] |
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
| B68 | Meta-analysis | ML; Audit | none: not reachable | Unknown (decide scope: coverage.md calls it outside powerkit's single-study focus) | — | metapower `mpower()`; POMADE `power_MADE()` | Decide | — |
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
| C2 | Several hypotheses in one study: power for each test separately (individual testing), for "at least one significant" (disjunction) or for "all significant" (conjunction) | None: one target test per spec, at the alpha the user enters; E7 and E8 give power for one chosen effect with no correction | Foundation tool can do it, not planned | Simulation (foundation tools): power4mome 0.2.1 `rejection_rates(collapse = "none" / "all_sig" / "at_least_one_sig" / "at_least_k_sig")`; Spower 0.7 user-written experiments that return one TRUE/FALSE (its vignettes describe joint criteria); Superpower 0.2.4.1 `ANOVA_power(p_adjust = , emm_p_adjust = )` corrects ANOVA effects and contrasts but reports power per effect. Analytic (not foundation tools): powertools 1.0.0 `coprimary.z()`, `coprimary.t()` (all) and `altprimary()` (at least one; Bonferroni by passing alpha / K); twoCoprimary 1.1.1 (two co-primary endpoints, all); rPowerSampleSize 1.0.2 (at least r of m endpoints, with Bonferroni, Holm or Hochberg); PUMP 1.0.5 (multilevel randomised trials: individual, at least one, all); crt2power 1.2.2 (cluster trials with two co-primary outcomes). pwr 1.3-0: none found. G\*Power: to confirm from screenshots. Why joint power matters: Rubin (2021, author preprint, p. 7; opened) shows two conjunction tests "each tested with a power value of .80" give "a power level of .64" | [B6][], [D6][], [G3][], [G7][] |
| C3 | Attrition/missing-data inflation of N | `options > attrition` is asked on every input screen. Since 17 October 2026 (the maintainer's decision) the engine turns the analysed N into a number to recruit, each group's N / (1 − attrition) rounded up (`engine/R/recruitment.R`); the result screen shows both numbers with a caveat, and the exported script works it out too | Partly working (simple inflation only) | Missing data beyond attrition: power4mome `missing_values()`; mlmpower `MCAR()`, `MAR()`; longpower `power.mmrm()` (retention per group); powerlmm dropout patterns (`dropout_weibull()`, `dropout_manual()`; archived on CRAN). Mikael Rubin (2025, p. 14 of 15; opened) describes simple N inflation ("if you have 80% power to detect an effect for an N = 100, but expect 20% dropout, you could then say the target sample size is 120") as "a frequently applied heuristic", and adds: "this approach can be problematic given that there are different patterns of missing data and missing data are handled in different ways (i.e., listwise deletion, maximum likelihood, multiple imputation) depending on the modelling approach". He doesn't use the word "crude" (the maintainer's earlier paraphrase). His example multiplies by 1.2 (100 to 120); dividing by 1 − .20, as powerkit now does, gives 125. Handling missing data beyond simple inflation is not built | [G3][] |
| C4 | Unequal allocation ratios | Two-group tests (`options > allocation_ratio`); E7 between designs no | Done (validated and wired) | Spower `n2_n1`, `n.ratios`; pwr `pwr.t2n.test()`, `pwr.2p2n.test()`; Superpower `ANOVA_power()` with an n vector (between designs only) | [G3][] |
| C5 | Measurement unreliability | E9 (reliability of X, W, Y) | Validated, not wired | InteractionPoweR `rel.x1`, `rel.x2`, `rel.y`; power4mome latent models (`reliability`) for mediation | [B8][], [G3][] |
| C6 | Non-normal data and unequal variances (simulation option) | Unequal variances: Welch (E2), cell SDs (E7, E8). Non-normal data: none | Done (validated and wired; unequal variances only) | Spower `parent1`/`parent2` (Wilcoxon), `gen_fun`; power4mome `x_fun`/`e_fun` with `rbeta_rs()`, `rexp_rs()`, `rlnorm_rs()`, `rt_rs()`, `runif_rs()`, `rpgnorm_rs()` | [G3][] |
| C7 | Covariates | One-way ANCOVA (E23, one or more covariates as an R-squared) | Planned (v2 in the build guide for ANCOVA; no phase) | Superpower `ANCOVA_analytic()`; InteractionPoweR `power_interaction_r2_covs()`; power4mome lavaan models; Spower `p_glm()` | [D7][], [C15][] |
| C8 | One- vs two-tailed | Two-sided default; one-sided for basic tests | Done (validated and wired) | Spower `alternative`; pwr `alternative` | [B3][] |
| C9 | Effect-size input formats and conversion | One format per end point (d, d_z, r, proportions, cell probabilities, means and SDs, standardised paths, correlations) | Unknown (decide which formats; conversion is planned for phase 5 as effect-size helpers, coverage.md) | pwr `ES.h()`, `ES.w1()`, `ES.w2()`; Superpower `mu_from_ES()`; pwrss `means.to.d()`, `etasq.to.f()`, `f.to.rsq()` and others (cross-check package) | [B10][], [G3][] |
| C10 | Effect sizes from pilots or the literature (bias correction) | None (warnings only) | Unknown (decide the approach) | BUCSS `ss_buc_*()`; mixpower `mp_safeguard_effect()` | [B2][], [A8][] |
| C11 | Power curves and sensitivity plots | `curve` in the result (power by N); sensitivity for E7, E8 | Validated, not wired | Spower `SpowerCurve()`; power4mome `power_curve()`; InteractionPoweR `plot_power_curve()`; Superpower `plot_power()`, `morey_plot()`; pwr `plot.power.htest()` | [G3][] |
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

| Status | Part A | Part B | Part C | Total |
| --- | --- | --- | --- | --- |
| Done (validated and wired) | 10 | 2 | 3 | 15 |
| Validated, not wired | 0 | 6 | 2 | 8 |
| Planned | 9 | 25 | 3 | 37 |
| Foundation tool can do it, not planned | 18 | 12 | 2 | 32 |
| G\*Power covers it, powerkit doesn't | 11 | 0 | 0 | 11 |
| Unknown | 1 | 19 | 2 | 22 |
| No ready-made tool | 0 | 5 | 0 | 5 |
| Out of scope | 0 | 0 | 0 | 0 |

(Part D's four rows are out of scope by definition and aren't counted.)

**Cheapest additions** (a foundation tool already does it, and powerkit
needs only a routing change, a new field or an output it already has):

- **A28, A30: the MANOVA approach for within factors.** E8 already runs
  Superpower's `ANOVA_exact()`, which returns `manova_results` when a
  within factor is included. Reporting it is an output change.
- **A2, A7: point-biserial r and the slope of a simple regression.** The
  same tests as E2 and E4 with the effect entered differently; an
  effect-size conversion on the existing cards.
- **A38: Fisher's exact test.** Spower's `p_prop.test(exact = TRUE)`, the
  same function E5 calls (judgement call 3.9).
- **A17, A19, A21, B25: Wilcoxon and Kruskal–Wallis tests.** Spower's
  `p_wilcox.test()` and `p_kruskal.test()`; the routes already reach the
  parametric cards (judgement call 3.8).
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

**Flagged while writing this page:**

- Spower 0.7's `p_r()` with `rho` ≠ 0 always returns a two-sided p-value
  (`pnorm(abs(t), lower.tail = FALSE) * 2`), whatever `alternative` says
  (Spower source, `R/p_r.R`). powerkit doesn't use a non-zero ρ0 yet; if
  it does, one-sided tests against ρ0 would need a workaround or an
  upstream fix. Recorded in [`decisions.md`](decisions.md) (17 October
  2026); a draft note to Spower's author is in
  [`upstream-questions.md`](upstream-questions.md) (not sent).
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
[B8]: judgement-calls.md#b8-reliability-for-e15s-score-variable
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
