# Matching corrected count tests: review and checklist

10 November 2026. In the open review PR; not merged or deployed.

A power plan must match the analysis the researcher intends to run. R's
prop.test() applies continuity correction by default; chisq.test() does so
for 2 by 2 tables. Powerkit's existing uncorrected defaults remain available
and unchanged. Their names now say that they omit correction, and both
forms explain the possible mismatch before the calculation.

The selectable corrected versions call Spower's existing experiment
functions, which generate data and run those base-R tests. Powerkit adds no
new correction or power formula. This is about matching the intended test;
it is not a recommendation that continuity correction is always better.

Two proportions fix the two group sizes, including unequal allocation.
The contingency-table simulation fixes only total N, with varying margins.
It requires four population proportions: Cohen's w does not identify them.
Use the two-proportions route if the two group sizes are fixed in advance.

Invalid analyses count as unsuccessful studies in the reported power
rather than disappearing from the denominator. The result reports attempts,
valid analyses, failures, conditional power and successful-study probability.
Standalone exports reproduce the same seeds, batches and denominator.
Sparse counts may still make the approximation unsuitable; correction is
not Fisher's exact test and does not make an approximate test exact.

- [x] Expose correction choices without silently changing saved/default plans.
- [x] Name the analysis and sampling assumptions in inputs, results and methods.
- [x] Refuse uncorrected formula overrides, unsupported sensitivity goals,
  Cohen's-w-only corrected tables and tables larger than 2 by 2.
- [x] Show simulation-accuracy controls for both corrected methods.
- [x] Check direction and unequal allocation against independently generated
  observations analysed by base R.
- [x] Check sparse-study failures and run standalone exports to reproduce them.
- [x] Check both corrected sample-size routes and replay their fitted answers.
  This checks reproduction, not fresh independent confirmation of target power.
- [x] Compare 10,000-study power estimates against independent finite
  binomial enumeration (two-sided and both directions, unequal groups).
- [x] Compare the corrected proportion null rate with its finite reference,
  allowing the conservatism inherent in a discrete corrected test.
- [x] Compare fixed-total contingency power with an independent
  10,000-study multinomial simulation.
- [x] Archive the standard 6-pass/1-skip run and link the selected cases in
  the existing evidence registry, preserving the publication gap.
- [ ] Record an independently sourced published/software power benchmark.
- [x] Archive four independent recommended-N checks, including sparse/imbalanced
  examples and finite-reference shortfalls. This does not establish target attainment.
- [ ] Improve discrete-test search accuracy or independently verify final N in the
  engine; the smooth fitted interval does not cover all approximation error.
- [x] Run the corrected-count chunk on GitHub as well as locally (run
  42894057884, head cc0e107; six passes and one published-reference skip).
- [ ] Complete all remaining hosted checks and review, merge only when instructed, then
  verify the live app. No evidence badge is upgraded by this work.

References: [R prop.test](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/prop.test.html),
[R chisq.test](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/chisq.test.html).

Recorded evidence: [settings and numerical results](validation/2026-11-10-corrected-counts.json),
[standard validation summary](validation/2026-11-10-corrected-counts-summary.txt).

### Independent checks at the returned integer N

[Reproduction script](../scripts/check-corrected-sample-size.R) and
[settings, search output and independent results](validation/2026-11-10-corrected-sample-size.json).
The search used 5,000 replications per sampled N and an 80% target. Independent
two-proportion power uses finite binomial enumeration; tables use 20,000 fresh
multinomial draws analysed by base R, with invalid analyses unsuccessful.

| Selected case | Returned N | Independent power |
| --- | ---: | ---: |
| Proportions .50 versus .65, equal groups | 362 | .795469 |
| Proportions .05 versus .20, allocation 1:3 | 240 | .811082 |
| Moderate 2 by 2 association, varying margins | 362 | .802050 |
| Sparse 2 by 2 association, varying margins | 78 | .796100 |

These are four selected checks, not confirmation that every returned N reaches
80%. In the balanced-proportions case, the true finite-reference power even
falls below the fitted curve's lower power limit (.797147). That interval
describes the smooth fitted model, not all discreteness or model error.
Results and copied methods now say this, and offer a fixed-N power check.
A discretisation-aware search or independent final verification in the engine
remains needed before a strict target-attainment claim. Increasing simulation
replications alone cannot remove smooth-model error.
