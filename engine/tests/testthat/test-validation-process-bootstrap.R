# PROCESS-style OLS/casewise-percentile-bootstrap planning.
# These checks concern the named complete-data models, not PROCESS software
# equivalence, clustered data, logistic outcomes or every PROCESS setting.
# The archived software reference remains the maintainer's to supply.

test_that("OLS bootstrap matches an archived PROCESS software power reference", {
  skip_unless_full_validation()
  # Required archive: PROCESS version, complete specification, sample size,
  # bootstrap settings, replication count, seed and reported rejection rate.
  # Do not infer a numeric benchmark from a PROCESS model number.
  reference <- TODO_PUBLISHED_VALUE
  skip_if_todo(reference)
  expect_power_near(engine_power(validate_quietly(reference$spec)), reference$power,
    reference_nrep = reference$nrep)
})

for (case in c("simple", "binary_x_model7")) {
  test_that(paste("OLS percentile bootstrap: null calibration for", case), {
    skip_unless_full_validation()
    skip_if_not_installed("lmhelprs", "0.4.2")
    if (identical(case, "simple")) {
      spec <- mediation_spec("process_4", "M",
        paths = list("X->M" = 0, "M->Y" = .35, "X->Y" = .1),
        path = "X->M->Y", n = 250, seed = 2026111031, method = "ols_percentile_bootstrap")
    } else {
      spec <- moderated_mediation_spec("process_7",
        paths = list("X->M" = .3, "W->M" = .1, "XW->M" = 0, "M->Y" = .35, "X->Y" = .05),
        r_x_w = 0, n = 250, seed = 2026111032, method = "ols_percentile_bootstrap")
      spec$variables$X$type <- "binary"
      spec$variables$X$levels <- c("Control", "Treatment")
      spec$population$x_prob <- .5
    }
    # Scoped to 1,000 resamples per interval; the interface's 5,000-default
    # default is checked for translation; selected settings are reproduced separately.
    spec$options$nrep <- 2000L
    spec$options$ci_draws <- 1000L
    expect_type1_near(engine_power(spec), alpha = .05)
  })
}
