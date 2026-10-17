# Validation: an independent cross-check of serial mediation (PROCESS
# model 6, two mediators), against simsem, which was written independently
# of power4mome. The same pattern as the simple-mediation cross-check
# (test-validation-mediation-crosscheck.R), joint test only: pwrss has no
# parallel or serial mediation.
#
# The joint-significance test (all three paths of X -> M1 -> M2 -> Y
# significant) in power4mome and in simsem: the same test and estimator
# (lavaan ML z tests) on independently generated data, so the tolerance is
# the Monte Carlo interval only (no allowance). The power4mome side uses
# powerkit's own translation of the spec (power4mome_inputs()); the simsem
# side generates data from residual variances worked out separately
# (standardised_residuals()).
#
# This checks power4mome's data generation and model fitting, not its
# Monte Carlo confidence interval (powerkit's default test), which no
# independent tool computes for serial mediation.
# See docs/validation-log.md ("Independent cross-check for mediation").
# Run as its own chunk: scripts/run-validation.R --only
# mediation_crosscheck_serial. Skipped unless POWERKIT_FULL_VALIDATION=true.

serial_crosscheck_designs <- list(
  # Power in the sensitive middle range (about .6 to .8).
  all_paths = list(
    paths = list("X->M1" = 0.3, "X->M2" = 0.1, "M1->M2" = 0.3, "M1->Y" = 0.1, "M2->Y" = 0.3, "X->Y" = 0.05),
    n = 110, seed = 75001
  ),
  no_direct_paths = list(
    paths = list("X->M1" = 0.4, "X->M2" = 0, "M1->M2" = 0.2, "M1->Y" = 0, "M2->Y" = 0.25, "X->Y" = 0),
    n = 250, seed = 76001
  )
)

for (name in names(serial_crosscheck_designs)) {
  d <- serial_crosscheck_designs[[name]]

  test_that(sprintf("cross-check, serial mediation (%s): the joint test agrees in power4mome and simsem", name), {
    skip_unless_full_validation()
    skip_if_not_installed("simsem")
    skip_if_not_installed("power4mome")
    spec <- mediation_spec(
      "process_6", c("M1", "M2"),
      paths = d$paths,
      path = "X->M1->M2->Y", n = d$n, seed = d$seed
    )
    joint <- mediation_joint_crosscheck(spec, nrep = validation_nrep(), seed = d$seed + 2)
    # Same test and estimator, independent data generation: no allowance.
    expect_power_agrees_within(joint$power4mome, joint$simsem, allowance = 0)
  })
}
