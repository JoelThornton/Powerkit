* New template `mediation / binary_mediator` (E39): mediation with a yes/no
  mediator, X two equal groups or a score, Y a score or yes/no. Spower runs
  `p_mediation_binm()`, which draws M from a logistic model and Y from a
  linear or logistic one and analyses each study with
  `regmedint::regmedint()` (regression-based causal mediation analysis,
  Valeri and VanderWeele 2013, now in refs.bib): significant when the
  natural indirect effect's delta-method p value is below alpha. Population
  fields `m_baseline`, `m_odds_ratio`, then `b` and `direct` (score Y) or
  `y_baseline`, `b_odds_ratio` and `direct_odds_ratio` (yes/no Y); method
  `delta_method`. Check run, spec checks, zero-effect check, group split
  rule, simulated-data code, R script and example spec
  `mediation_binary_mediator.json`. regmedint joins Suggests (sandwich and
  assertthat join renv.lock). New validation chunk `mediation_binm`:
  agreement with an independent simulation of the published formulas for
  each kind of X and Y, Type I error, and a published-example placeholder.
