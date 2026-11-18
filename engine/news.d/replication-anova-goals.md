* Replication plans: an ANOVA original's effect with one numerator
  degree of freedom (a factor with two levels, or a 2 x 2 interaction)
  goes through every goal. `replication_planning()` takes
  `design = "anova_between"`, `"anova_within"` or `"anova_mixed"` with
  `levels_a`, `levels_b`, `effect` and the F (`original_f`) or partial
  eta-squared (`original_partial_eta`, `original_df_error`), and plans
  the two-mean comparison the effect is, t = sqrt(F) (Lakens, 2013), as a
  t-test original. BUCSS's correction beside the goals is the ANOVA's own
  function. The plan records the comparison and both sets of error
  degrees of freedom (`anova_effect`), and its script says how the F was
  read. An effect with several degrees of freedom is refused with a
  pointer to the two routes for it.
* New `replication_anova_smallest()`: the sample size for an ANOVA
  effect's F test from the smallest partial eta-squared that would
  matter, through the matching card's own calculation (`run_spec()`,
  pwrss), for effects with several degrees of freedom.
* `replication_bucss()` accepts a one-sided test for an ANOVA effect with
  one degree of freedom (F = t²), planned as for a t-test; an effect with
  several degrees of freedom is still refused one.
