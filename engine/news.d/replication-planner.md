* New: `replication_planning()` and `replication_planning_script()`, for the
  Labs replication planner. For an original study's effect and sample size
  (two groups, one sample, pairs or a correlation), the replication's sample
  size for each goal Anderson and Maxwell (2016) describe, under three design
  priors (the original estimate as reported, with its uncertainty, and
  shrunk by empirical Bayes) and an optional between-study heterogeneity:
  a significant result in the original's direction, a significant pooled
  estimate, agreement with the original, the replication and sceptical Bayes
  factors (BayesRepDesign, Pawel, Consonni & Held, 2026), showing the effect
  is too small to matter (TOST, planned for no effect) and small telescopes
  (the card's own pwr and pwrss calculation). Goals no replication can reach
  report the highest chance reachable. BayesRepDesign is in Suggests, with a
  plain message when it is missing, and pinned in `renv.lock`.
* `porsTOST()` and `ssdTOST()` in BayesRepDesign 0.42 take the confidence
  interval's level (they use `qnorm(1 - level / 2)`), so the usual TOST at
  alpha is called with `level = 2 * alpha`, as `ssdEqu()` is; recorded in
  `docs/upstream-questions.md`.
* New references: Pawel, Consonni & Held (2026), Anderson & Maxwell (2016)
  and Kenny & Judd (2019), each checked against the published PDF.
