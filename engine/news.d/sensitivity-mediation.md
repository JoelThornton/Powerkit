* The smallest detectable indirect effect for simple, parallel and serial
  mediation (E10, E11, E12, E16), and the smallest index of moderated
  mediation for PROCESS models 7 and 14 (E13, E14, E17, E40), by the
  simulated search (`simulated_effect_sensitivity()`, with a 95% interval).
  The paths whose product is the effect tested are each multiplied by
  x^(1/k) for k paths, so the effect is x times the one entered and keeps
  its sign; every other path, correlation and residual correlation is kept.
  The search stops where an equation's R-squared would reach 0.99
  (`mediation_scale_limit()`). The difference between conditional indirect
  effects (E38) is not searched: its residual variances are given
  explicitly and change with every path. The exported script's
  `set_effect()` rebuilds power4mome's `pop_es` with the same arithmetic
  (`mediation_pop_es_script()`), including parallel mediators' residual
  covariances. Tests (`test-sensitivity-mediation.R`): the script's
  population values equal `power4mome_inputs()` at three sizes of the
  effect for every model, and simple mediation's answer is checked against
  a fresh simulation of 2,000 studies and reproduced by its script.
