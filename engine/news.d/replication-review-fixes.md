* Fixed: `replication_planning()` reported a goal as unreachable when any
  replication meets it. After a strong original, the pooled goal's chance
  is above 99.9% even for three people, so BayesRepDesign's sample-size
  search finds no root; the plan said "not reachable" (Shnabel et al.,
  2009, Study 1, F(1, 118) = 15.38, N = 120). The search now checks the
  smallest replication (three people, four for two groups or a
  correlation) and, when it already reaches the target power, returns
  `n = NA` with `reason = "any_size"` and that chance as `limit`. The
  Bayes factor goals do the same.
* `replication_planning()` takes a t-test original as its t statistic
  (`original_effect_type = "t"`) and a paired original as d_rm with the
  correlation between its two measurements (`original_effect_type =
  "d_rm"`, `original_r`), converted to the design's d by Lakens (2013):
  d = t sqrt(1/n1 + 1/n2) for two groups, d_z = t / sqrt(n) for pairs, and
  d_z = d_rm / sqrt(2(1 - r)). Papers report several kinds of
  repeated-measures d, which can differ from d_z by a factor of two or
  more. Another design's uncertainty can be an F with one numerator df
  (`original_f`), whose square root is its t. The inputs record what was
  entered, and the R script shows the conversion.
