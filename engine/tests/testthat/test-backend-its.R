# Interrupted time series (time_series / its): Spower around PITS's
# simulated series and nlme's gls(). The experiment, the Type I error
# reported beside the power, the search's limit, the check run and the
# exported script; accuracy is checked by test-validation-its.R.

its_test_spec <- function(n = 24, nrep = 200, effect = "level", method = "gls_reml", ...) {
  spec <- example_spec("its")
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = nrep, seed = 19)
  spec$target_test$effect <- effect
  spec$target_test$method <- method
  changes <- list(...)
  for (k in names(changes)) spec$population[[k]] <- changes[[k]]
  spec
}

test_that("the REML fit and PITS's own test both give p-values, and both changes can be tested together", {
  skip_if_not_installed("PITS")
  d <- with_seed(4, its_data(24, 24, 15, 0, -3, -0.2, 2.5, 0.4))
  for (test in c("level", "slope", "both")) {
    expect_true(is.finite(its_p_value(d, test, "gls_reml")), label = test)
    expect_equal(its_p_value(d, test, "gls_ml"), PITS::fit_its_model(d, test), label = test)
  }
})

test_that("the result reports the Type I error at the planned length, and the check run passes", {
  skip_if_not_installed("PITS")
  result <- suppressWarnings(run_quietly(its_test_spec()))
  expect_true(all(result$check_run$ok))
  expect_equal(result$type1$n, 24)
  expect_equal(result$type1$nrep, 200)
  expect_gt(result$type1$rate, 0)
  expect_lt(result$type1$rate, 0.2)
  expect_true(all(c("PITS", "nlme") %in% names(result$provenance$packages)))
  # Other designs carry no Type I error report.
  other <- suppressWarnings(run_quietly(example_spec("independent_t")))
  expect_null(other$type1)
})

test_that("PITS's maximum-likelihood test rejects more often with no effect than REML in a short series", {
  skip_if_not_installed("PITS")
  reml <- suppressWarnings(run_quietly(its_test_spec(n = 12, nrep = 400, n_pre = 12L, level_change = 0)))
  ml <- suppressWarnings(run_quietly(its_test_spec(n = 12, nrep = 400, method = "gls_ml", n_pre = 12L, level_change = 0)))
  expect_gt(ml$type1$rate, reml$type1$rate)
})

test_that("a target the points after the intervention can't reach stops with a plain reason", {
  skip_if_not_installed("PITS")
  spec <- its_test_spec(level_change = -0.5)
  spec$goal <- list(type = "sample_size", power = 0.9)
  expect_error(suppressWarnings(run_quietly(spec)), "measured against the trend before the intervention")
})

test_that("the R script reproduces the run", {
  skip_if_not_installed("PITS")
  spec <- its_test_spec()
  result <- suppressWarnings(run_quietly(spec))
  script <- export_script(spec, result)
  expect_true(any(grepl("PITS::simulate_its_data(", script, fixed = TRUE)))
  out <- utils::capture.output(eval(parse(text = script), envir = new.env()))
  expect_true(any(grepl("Reproduced powerkit's result.", out, fixed = TRUE)))
})
