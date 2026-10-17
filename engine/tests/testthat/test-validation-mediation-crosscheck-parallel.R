# Validation: an independent cross-check of parallel mediation (PROCESS
# model 4, two mediators), against simsem, which was written independently
# of power4mome. The same pattern as the simple-mediation cross-check
# (test-validation-mediation-crosscheck.R), joint test only: pwrss has no
# parallel or serial mediation.
#
# The joint-significance test (both paths of the target indirect effect
# significant) in power4mome and in simsem: the same test and estimator
# (lavaan ML z tests) on independently generated data, so the tolerance is
# the Monte Carlo interval only (no allowance). The power4mome side uses
# powerkit's own translation of the spec (power4mome_inputs(), including
# the mediators' residual covariance); the simsem side generates data from
# residual variances worked out separately (standardised_residuals()), so a
# mistake in powerkit's translation would show here too.
#
# This checks power4mome's data generation and model fitting, not its
# Monte Carlo confidence interval (powerkit's default test), which no
# independent tool computes for parallel mediation.
# See docs/validation-log.md ("Independent cross-check for mediation").
# Run as its own chunk: scripts/run-validation.R --only
# mediation_crosscheck_parallel. Skipped unless POWERKIT_FULL_VALIDATION=true.

parallel_crosscheck_designs <- list(
  # Power in the sensitive middle range (about .6 to .8).
  correlated_residuals = list(
    paths = list("X->M1" = 0.3, "X->M2" = 0.3, "M1->Y" = 0.2, "M2->Y" = 0.2, "X->Y" = 0.1),
    residual_r = 0.3, path = "X->M1->Y", n = 200, seed = 73001
  ),
  uncorrelated_residuals = list(
    paths = list("X->M1" = 0.25, "X->M2" = 0.4, "M1->Y" = 0.3, "M2->Y" = 0.15, "X->Y" = 0),
    residual_r = 0, path = "X->M2->Y", n = 300, seed = 74001
  )
)

for (name in names(parallel_crosscheck_designs)) {
  d <- parallel_crosscheck_designs[[name]]

  test_that(sprintf("cross-check, parallel mediation (%s): the joint test agrees in power4mome and simsem", name), {
    skip_unless_full_validation()
    skip_if_not_installed("simsem")
    skip_if_not_installed("power4mome")
    spec <- mediation_spec(
      "process_4", c("M1", "M2"),
      paths = d$paths,
      residual_correlations = list("M1<->M2" = d$residual_r),
      path = d$path, n = d$n, seed = d$seed
    )
    joint <- mediation_joint_crosscheck(spec, nrep = validation_nrep(), seed = d$seed + 2)
    # Same test and estimator, independent data generation: no allowance.
    expect_power_agrees_within(joint$power4mome, joint$simsem, allowance = 0)
  })
}
