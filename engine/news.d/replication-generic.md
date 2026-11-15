* `replication_planning()` gains `design = "generic"`: the goals table for
  any effect that is one number, from the original's estimate and its
  standard error (`original_se`), confidence interval (`original_ci`,
  `original_ci_level`) or test statistic (`original_statistic`), on the
  scale given by `scale` (`"none"`, `"log"` for ratios, `"fisher_z"` for
  correlations). The replication's standard error is the original's
  scaled by the square root of the sample-size ratio (BayesRepDesign's
  `se = unitSD / sqrt(n)`); small telescopes is not offered on this route.
  The exported R script reproduces the table. Tests show it equals the
  one-sample and paired routes exactly and give the size of the gap for
  two groups and a correlation, which keep their exact routes.
* forms.yaml: `replication_effects` lists every card's focal effect and
  scale for the replication goals (exact route, one effect, multi-df test
  pointed to its focal contrast, or none); the replication plan's card
  status and fields follow it.
