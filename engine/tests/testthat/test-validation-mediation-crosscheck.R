# Validation: an independent cross-check of simple mediation (PROCESS
# model 4, one mediator), against tools written independently of
# power4mome. The other mediation validation tests compare powerkit with
# direct power4mome calls, which checks the wrapping but not power4mome
# itself; these compare it with pwrss and simsem.
#
# Which test is compared with which, and why differences are or aren't
# expected, is set out in docs/validation-log.md ("Independent cross-check
# for mediation"):
#   1. powerkit (power4mome, Monte Carlo CI) vs pwrss's Monte Carlo
#      interval test: the same test, but pwrss draws the estimates from
#      their large-sample sampling distributions instead of simulating data
#      (tolerance: Monte Carlo interval plus an allowance);
#   2. the joint-significance test (a and b both significant) in power4mome
#      and simsem: the same test and estimator (lavaan ML z tests) on
#      independently generated data (tolerance: Monte Carlo interval only);
#   3. both against pwrss's analytic joint test (Monte Carlo interval plus
#      the allowance).
# The allowance (crosscheck_allowance()) is proposed, for the maintainer to
# confirm. Run as its own chunk: scripts/run-validation.R --only
# mediation_crosscheck. Skipped unless POWERKIT_FULL_VALIDATION=true.

crosscheck_designs <- list(
  # Two designs with power in the sensitive middle range (about .6 to .8).
  equal_paths = list(a = 0.3, b = 0.3, c_prime = 0.1, n = 100, seed = 71001),
  unequal_paths = list(a = 0.2, b = 0.4, c_prime = 0, n = 200, seed = 72001)
)

for (name in names(crosscheck_designs)) {
  d <- crosscheck_designs[[name]]

  test_that(sprintf("cross-check (%s): powerkit's Monte Carlo CI matches pwrss's Monte Carlo interval test", name), {
    skip_unless_full_validation()
    skip_if_not_installed("pwrss")
    spec <- mediation_spec(
      "process_4", "M",
      paths = list("X->M" = d$a, "M->Y" = d$b, "X->Y" = d$c_prime),
      path = "X->M->Y", n = d$n, seed = d$seed
    )
    pwrss_mc <- pwrss_mediation(
      d$a, d$b, d$c_prime, d$n, alpha = 0.05, method = "monte.carlo",
      nrep = validation_nrep(), draws = validation_ci_draws(), seed = d$seed + 1
    )
    expect_power_agrees_within(engine_power(spec), pwrss_mc, crosscheck_allowance())
  })

  test_that(sprintf("cross-check (%s): the joint test agrees in power4mome, simsem and pwrss", name), {
    skip_unless_full_validation()
    skip_if_not_installed("pwrss")
    skip_if_not_installed("simsem")
    skip_if_not_installed("power4mome")
    p4m <- power4mome_joint(d$a, d$b, d$c_prime, d$n, alpha = 0.05, nrep = validation_nrep(), seed = d$seed + 2)
    sem <- simsem_joint(d$a, d$b, d$c_prime, d$n, alpha = 0.05, nrep = validation_nrep(), seed = d$seed + 3)
    analytic <- pwrss_mediation(d$a, d$b, d$c_prime, d$n, alpha = 0.05, method = "joint")
    # Same test and estimator, independent data generation: no allowance.
    expect_power_agrees_within(p4m, sem, allowance = 0)
    expect_power_agrees_within(p4m, analytic, crosscheck_allowance())
    expect_power_agrees_within(sem, analytic, crosscheck_allowance())
  })
}
