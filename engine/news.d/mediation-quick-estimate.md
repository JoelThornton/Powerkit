* Simple mediation (one mediator, `template` "process_4") gains a quick
  estimate: `target_test > method` "joint_significance", the test that
  counts the indirect effect when both paths are significant, with power
  from pwrss's `power.z.mediation(method = "joint")` formula. It is
  instant and gives a sample size, which the simulated Monte Carlo
  interval cannot do in the app. It is optimistic: with paths of .3 and
  N = 100 it gives 75.0% power, against 72.4% for a simulation of the
  joint-significance test with regressions and 71.1% for powerkit's
  simulated Monte Carlo interval (2,000 replications). powerkit passes R-squared of Y with the
  2 a b c' term, which pwrss's default leaves out.
