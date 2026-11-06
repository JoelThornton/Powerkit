# Random-intercept cross-lagged panel model (panel / riclpm): Spower around
# powRICLPM, which simulates each study and fits the model with lavaan.
# The experiment, the spec checks, the check run and the exported script;
# accuracy is checked by test-validation-riclpm.R.

riclpm_test_spec <- function(n = 300, nrep = 100, effect = "cross_lagged_xy", ...) {
  spec <- example_spec("riclpm")
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = nrep, seed = 17)
  spec$target_test$effect <- effect
  changes <- list(...)
  for (k in names(changes)) spec$population[[k]] <- changes[[k]]
  spec
}

test_that("Phi has the outcomes in rows, and each effect names powRICLPM's first-lag parameter", {
  phi <- riclpm_phi(ar_x = 0.4, ar_y = 0.3, cl_xy = 0.15, cl_yx = 0.1)
  expect_equal(phi[2, 1], 0.15) # X (A) at one wave on Y (B) at the next
  expect_equal(phi[1, 2], 0.1)
  expect_equal(riclpm_parameter("cross_lagged_xy"), "wB2~wA1")
  expect_equal(riclpm_parameter("cross_lagged_yx"), "wA2~wB1")
  expect_equal(riclpm_parameter("autoregressive_x"), "wA2~wA1")
})

test_that("a large effect is found and a zero effect is rejected about alpha of the time", {
  skip_if_not_installed("powRICLPM")
  strong <- suppressWarnings(run_quietly(riclpm_test_spec(n = 400, autoregressive_x = 0.5)))
  expect_true(all(strong$check_run$ok))
  expect_true(all(c("powRICLPM", "lavaan") %in% names(strong$provenance$packages)))
  big <- suppressWarnings(run_quietly(riclpm_test_spec(n = 400, effect = "autoregressive_x", autoregressive_x = 0.5)))
  expect_gt(big$curve$power, 0.9)
  null <- suppressWarnings(run_quietly(riclpm_test_spec(n = 200, nrep = 200, cross_lagged_xy = 0)))
  expect_lt(null$curve$power, 0.12)
})

test_that("lagged effects that can't hold are refused in plain words", {
  spec <- riclpm_test_spec(autoregressive_x = 0.95, autoregressive_y = 0.95, cross_lagged_xy = 0.5, cross_lagged_yx = 0.5)
  expect_error(validate_spec(spec), "grow without limit", class = "powerkit_spec_error")
  spec <- riclpm_test_spec(autoregressive_x = 0.7, cross_lagged_yx = 0.6, within_correlation = 0.9)
  expect_error(validate_spec(spec), "can't all hold|grow without limit", class = "powerkit_spec_error")
  spec <- riclpm_test_spec()
  spec$population$waves <- 2L
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})

test_that("the R script reproduces the run", {
  skip_if_not_installed("powRICLPM")
  spec <- riclpm_test_spec()
  result <- suppressWarnings(run_quietly(spec))
  script <- export_script(spec, result)
  expect_true(any(grepl("powRICLPM::powRICLPM(", script, fixed = TRUE)))
  out <- utils::capture.output(eval(parse(text = script), envir = new.env()))
  expect_true(any(grepl("Reproduced powerkit's result.", out, fixed = TRUE)))
})

test_that("a correlation of exactly 0, read from JSON as an integer, is passed to powRICLPM as a double", {
  skip_if_not_installed("powRICLPM")
  est <- with_seed(3, riclpm_fit(n = 300L, waves = 4L, icc = 0.5, ri_cor = 0L, ar_x = 0.4, ar_y = 0.3, cl_xy = 0.1,
    cl_yx = 0L, within_cor = 0L, reliability = 1L, constraints = "none"))
  expect_false(is.null(est))
})
