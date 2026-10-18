# Judgement calls: decided

*Moved here from [`judgement-calls.md`](../judgement-calls.md) on 18
October 2026, so that file holds only open questions. Each decision is
also recorded, dated, in [`decisions.md`](../decisions.md). Links inside
these entries are relative to `docs/`.*

### A2. E45 says "No ready-made tool", but PITS exists

**Decided 17 October 2026** (`decisions.md`): E45 now says "A recently
released package addresses the known-breakpoint case; powerkit hasn't
checked it." PITS isn't named on the card while A1 (open question 18) is
open; it is recorded in `card-sources.md` and `decision-tree.md`. Still
open: whether to name it (A1). E45's autocorrelation point (A6) was
decided later the same day. The entry is kept below as the record of the
options.


- **Question:** E45 (segmented regression, interrupted time series) says
  there is no ready-made tool. The CRAN package PITS 0.1.0 estimates
  power for interrupted time series by simulation, with a known
  breakpoint, a level change, a slope change and AR(1) autocorrelation
  (opened). What should E45 say?
- **Options:**
  - keep "No ready-made tool";
  - name PITS for a known breakpoint (with A1's wording rule);
  - split the card: known breakpoint (a tool exists) and estimated
    breakpoint (no ready-made tool found);
  - say "Established tools exist" (A1's neutral sentence).
- **What tools and sources do:**
  - PITS `calculate_power()` takes `n_pre`, `n_post`, `level_change`,
    `slope_change`, `sigma` and `rho` in [0, 1) (manual) (opened).
  - It doesn't cover a breakpoint estimated from the data, or negative
    autocorrelation.
  - chngpt tests an estimated change point with Monte Carlo or bootstrap
    p-values and has a data simulator, but no power function (opened).
- **Who might disagree, and why:**
  - PITS is new (version 0.1.0) and powerkit hasn't checked it. Some
    would wait for a track record before naming it.
  - Others would say the card is now inaccurate and should change.
- **Knock-on effects:**
  - Ties to A1 (naming tools) and to open question 17 (whether E45 and
    E35 share a card).
  - `coverage.md` has no PITS row yet.
  - `card-sources.md` marks the claim "contradicted".
- **Recorded in:** [`card-sources.md`](../card-sources.md), "Contradictions"
  (16 October 2026). No setting yet.

### A9. "Exact (analytic)" for Superpower's `ANOVA_exact()` (E7, E8)

**Decided 17 October 2026** (`decisions.md`): the cards now say "Exact
dataset (no repeated simulation)", following Superpower's help. The entry
is kept below as the record of the options.


- **Question:** E7 and E8 give the default method as "Exact (analytic)",
  and Q-test offers "Exact (analytic) or simulation". Superpower's
  documentation doesn't call `ANOVA_exact()` analytic. Keep the label, or
  reword it?
- **Options:**
  - keep "Exact (analytic)";
  - use Superpower's own terms, for example "Exact data set" or "Exact
    (one data set matching your inputs)";
  - name the function only.
- **What tools and sources do** (opened):
  - Superpower 0.2.4.1, `ANOVA_exact`: "Simulates an exact dataset (mu,
    sd, and r represent empirical, not population, mean and covariance
    matrix)".
  - The vignette: it "simulates one dataset that exactly matches the
    desired properties" and runs a single ANOVA on it.
  - Superpower uses "Analytic power calculation" for other functions, for
    example `power_oneway_between()`.
  - `conventions.md` describes the method in Superpower's terms.
- **Who might disagree, and why:**
  - "Analytic" signals to users that no random simulation error is
    involved, which is true of the result.
  - Others would keep to the package's own vocabulary, so that the card,
    the methods paragraph and the package documentation agree.
- **Knock-on effects:**
  - The Q-test card note and the method line change together.
  - The methods paragraph (phase 4) should use the same term.
  - `card-sources.md` marks the claim "contradicted".
- **Recorded in:** [`card-sources.md`](../card-sources.md), "Contradictions".
  No setting.

### G5. Showing the actual power at the rounded N

- **Question:** when powerkit reports a required N, does it also show the
  power that N actually gives (which is at or just above the target)?
- **Options:**
  - show it next to the required N;
  - show it only in the details or the exported script;
  - don't show it.
- **What tools and sources do:** G\*Power reports an actual power with the
  sample size (maintainer's list; screenshot to confirm). powerkit's
  result already holds it for exact results: the `curve` has the power
  at every N searched, including the one reported (`run_spec()` help).
  For simulation it is an estimate with its own Monte Carlo error.
- **Who might disagree, and why:**
  - Showing it helps users see how much rounding to whole people (and
    to equal groups) added.
  - For simulated results, a second number with its own interval can
    confuse more than it helps.
- **Knock-on effects:** the result screen's headline (B12, N rounding);
  the methods paragraph (G4).
- **Decided (maintainer, 17 October 2026):** show it on the result
  screen, labelled plainly ("With 64 per group, power is 80.1%."). Shown
  for exact results; not for a simulated N, which has no simulation at
  exactly that N (powerkit's default). `decisions.md`, 17 October 2026.
- **Recorded in:** this entry; [`gpower-parity.md`](../gpower-parity.md).

### G6. The method for correlations (E4), and for two proportions (E5)

- **Question:** E4's default is now pwr's formula, which uses Fisher's z.
  G\*Power uses the exact distribution below N = 10,000 by default
  (maintainer). Match G\*Power, or keep pwr and record a departure? The
  same question arises for E5, where pwr uses Cohen's h (the arcsine
  transformation) rather than a z test.
- **What pwr's help says:** `pwr.r.test()`: "These calculations use the
  Z' transformation of correlation coefficient: Z'=arctanh(r) and a bias
  correction is applied"; its source takes the critical value from the t
  distribution and the power from the normal approximation to Fisher's z
  (opened). `pwr.2p.test()` and `pwr.2p2n.test()` take Cohen's h
  (`ES.h()`).
- **Size of the difference, E4** (two-sided, alpha .05; pwr 1.3-0 against
  pwrss 1.3.3's `power.exact.onecor()`, which its help describes as the
  exact method of Barabesi and Greco (2002), "validated using G\*Power";
  not checked against G\*Power itself here):

  | N | r = .3: pwr | exact | r = .4: pwr | exact | r = .5: pwr | exact |
  | --- | --- | --- | --- | --- | --- | --- |
  | 20 | 0.2559 | 0.2539 | 0.4302 | 0.4303 | 0.6379 | 0.6417 |
  | 30 | 0.3712 | 0.3705 | 0.6075 | 0.6092 | 0.8250 | 0.8277 |
  | 40 | 0.4773 | 0.4774 | 0.7405 | 0.7423 | 0.9218 | 0.9228 |
  | 50 | 0.5716 | 0.5722 | 0.8339 | 0.8352 | 0.9670 | 0.9672 |
  | 60 | 0.6531 | 0.6540 | 0.8965 | 0.8972 | 0.9867 | 0.9866 |
  | 70 | 0.7222 | 0.7230 | 0.9369 | 0.9373 | 0.9948 | 0.9947 |
  | 80 | 0.7797 | 0.7804 | 0.9623 | 0.9624 | 0.9981 | 0.9980 |
  | 90 | 0.8267 | 0.8273 | 0.9778 | 0.9778 | 0.9993 | 0.9992 |
  | 100 | 0.8648 | 0.8652 | 0.9872 | 0.9871 | 0.9997 | 0.9997 |

  Largest difference 0.0038 (N = 20, r = .5). One-sided, the largest at
  N = 20, 50 and 100 was 0.0047 (N = 20, r = .5). Required N for 80%
  power: r = .3, pwr 85 (84.07 rounded up), exact 84; r = .4, 46 and 46;
  r = .5, 29 and 29. So powerkit's E4 can report one more participant
  than G\*Power at r = .3, and its power can differ in the third decimal,
  which the 3-decimal validation against G\*Power's published values
  would catch.
- **Size of the difference, E5** (two-sided, alpha .05, equal groups;
  pwr against pwrss's `power.z.twoprops()`, a normal-approximation z test,
  "validated via G\*Power and PASS documentation"; whether G\*Power's z
  test pools the variance is to confirm from a screenshot): with p1 = .10,
  p2 = .25, power 0.248 vs 0.235 at 20 per group and 0.523 vs 0.506 at 50
  (largest gap 0.018); required N for 80% power 97 vs 100 per group. With
  p1 = .30, p2 = .50 the gap is at most 0.008 and the N is 93 for both.
- **Options:**
  - keep pwr and record the difference as a departure (convention rules:
    `conventions.md`, results screen, methods paragraph, a test showing
    its size);
  - match G\*Power with an exact method from a backend that has one (for
    E4, pwrss `power.exact.onecor()`, not a foundation tool when this was written (it became one on 17 October 2026, for E5's unequal groups); or Spower's
    simulation, which estimates the exact test's power with Monte Carlo
    error);
  - keep pwr for E4 only below some size of difference, and switch for
    E5 (or the reverse).
- **Who might disagree, and why:**
  - Users checking powerkit against G\*Power will see different third
    decimals and, sometimes, one more participant.
  - pwr's help gives Cohen (1988) as the source of its formulas.
- **Knock-on effects:** Departure 9's wording; the G\*Power published-value
  tests for E4 and E5; the card's method line.
- **Decided (maintainer, 17 October 2026):**
  - E4: keep pwr's Fisher's z, recorded as Departure 10 in
    [`conventions.md`](../conventions.md) and shown on the card and the
    result screen.
  - **Checked against the G\*Power manual (17 October 2026):** the
    manual (June 1, 2023, section 3, pp. 9–10) confirms the exact method
    (Barabesi and Greco, 2002) with "Use exact distribution if N <:
    10000". pwrss's `power.exact.onecor()`, the reference used above,
    reproduces both of the manual's examples (N = 1928; power 0.482927),
    so the sizes in this entry are sizes against G\*Power's method. The
    manual has no section for E5's z test, so E5 still needs a
    screenshot.
  - E5: the default should be the z test (or chi-square) most
    psychologists run, not the arcsine. Base R's `power.prop.test()` is to
    be checked against G\*Power's "Two independent groups: inequality,
    z-test" first; the switch waits for the maintainer's yes.
  - **Checked against G\*Power screenshots (17 October 2026):** G\*Power
    3.1.9.7's "Proportions: Difference between two independent
    proportions" (z tests), with its default options (no continuity
    correction, no arcsine transformation), equals
    `power.prop.test(strict = TRUE)` to seven decimals: 0.2344921 at 20
    per group (p1 = .10, p2 = .25); 164 per group for 95% power, actual
    power 0.9502464. `strict = FALSE` gives 0.2339595, so G\*Power counts
    both tails. With N2/N1 = 2 G\*Power gives 123 + 247; `power.prop.test()`
    can't do unequal groups. Details: [`gpower-parity.md`](../gpower-parity.md), E5.
- **Recorded in:** this entry; [`gpower-parity.md`](../gpower-parity.md);
  [`coverage-roadmap.md`](../coverage-roadmap.md), note 1. The comparison
  scripts are in the PR description.
