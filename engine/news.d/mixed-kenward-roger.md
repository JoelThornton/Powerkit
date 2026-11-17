* New: `target_test > df_method` for the simr mixed models with a score
  (`crossed_two_condition`, `crossed_conditions`, `two_level`,
  `three_level`, `item_predictor`; cards E33, E41, E62, E63, E67, E68).
  "satterthwaite", the default, is lmerTest's Satterthwaite test, as
  before (Departure 16); "kenward_roger" tests each simulated study with
  Kenward and Roger's degrees of freedom: simr's `fixed(term, "kr")`
  (pbkrtest), or lmerTest's `anova()` and `contest()` with
  `ddf = "Kenward-Roger"` for three or more conditions. pbkrtest's version
  is recorded with the result, the exported script reproduces it, and a
  validation test in the mixed_model chunk checks it against
  `pbkrtest::KRmodcomp()` on independently simulated studies. A yes/no
  outcome refuses it.
