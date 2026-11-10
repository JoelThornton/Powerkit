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
- [ ] Verify recommended sample sizes with fresh independent draws across
  representative sparse/imbalanced cases; simulated N carries uncertainty.
- [ ] Complete hosted checks and review, merge only when instructed, then
  verify the live app. No evidence badge is upgraded by this work.

References: [R prop.test](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/prop.test.html),
[R chisq.test](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/chisq.test.html).

Recorded evidence: [settings and numerical results](validation/2026-11-10-corrected-counts.json),
[standard validation summary](validation/2026-11-10-corrected-counts-summary.txt).
