* `replication_bucss()` plans a three-factor ANOVA original (between,
  within or mixed) through BUCSS's general functions
  (`ss_buc_factorial_anova_general`, `ss_buc_rm_anova_general`,
  `ss_buc_mixed_anova_general`). New arguments `levels_c` and
  `between_factors` (a mixed design's between-subjects factors, 1 or 2);
  effects `factor_a`, `factor_b`, `factor_c`, `a_by_b`, `a_by_c`, `b_by_c`
  and `a_by_b_by_c`. An effect's degrees of freedom and a mixed design's
  between/within split follow from the factors it involves. The smallest-
  effect route does not cover three factors (no ANOVA card plans one from
  a partial eta-squared).
* App: the replication planner takes a third factor's levels, how many
  factors are between-subjects (mixed designs), and the five new effects.
