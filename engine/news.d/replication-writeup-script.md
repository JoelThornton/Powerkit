* `replication_planning_script()` takes `goal`, `also` and `prior`: the
  script then plans the main criterion's sample size under that belief
  and gives each other criterion's chance at it, with the functions and
  levels `replication_planning()` uses (tested to reproduce its numbers).
  Without them it gives every goal under every belief, as before.
* `replication_planning()` gains `alternative = "one.sided"`: the
  significance goal at alpha, one-sided in the original's direction, and
  the pooled goal at alpha squared. The default is unchanged
  (BayesRepDesign's two-trials rule at alpha / 2). The scripts name the
  level as `level`. The replication validation chunk checks the
  one-sided rules against its simulation of the method's model.
* Replication plans (app): the write-up adds a study design table for
  Registered Reports, one row per chosen criterion; the R script runs the
  chosen criteria only; a one-sided significance test can be chosen.
