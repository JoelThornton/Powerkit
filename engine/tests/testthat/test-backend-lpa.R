# Latent profile analysis (mixture / lpa): the chance the BIC finds the
# right number of profiles, simulated with Spower around mclust. The data,
# the experiment, the spec checks, the check run and the exported script;
# accuracy is checked by test-validation-lpa.R.

lpa_test_spec <- function(n = 200, nrep = 100, ...) {
  spec <- example_spec("lpa")
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = nrep, seed = 11)
  changes <- list(...)
  for (k in names(changes)) spec$population[[k]] <- changes[[k]]
  spec
}

test_that("the experiment counts how often mclust's BIC chooses the right number", {
  skip_if_not_installed("mclust")
  # Well separated: found almost every time; no separation: one profile is
  # chosen, so the right number (3) almost never.
  clear <- suppressWarnings(run_quietly(lpa_test_spec(separation = 3)))
  expect_gt(clear$curve$power, 0.95)
  none <- suppressWarnings(run_quietly(lpa_test_spec(separation = 0)))
  expect_lt(none$curve$power, 0.05)
  expect_true(all(clear$check_run$ok))
  expect_match(clear$provenance$backend_function, "mclust", fixed = TRUE)
  expect_true("mclust" %in% names(clear$provenance$packages))
  # The experiment's own answer: 0 when found, 1 when not.
  set.seed(1)
  expect_true(p_lpa(300, 2, 6, 3, c(0.5, 0.5)) %in% c(0, 1))
})

test_that("shares must match the profiles and add up to 1; there is no alpha", {
  spec <- lpa_test_spec(shares = list(0.5, 0.5))
  expect_spec_problem(spec, "one share for each of the 3 profiles")
  spec <- lpa_test_spec(shares = list(0.5, 0.4, 0.2))
  expect_spec_problem(spec, "add up to 1")
  spec <- lpa_test_spec()
  spec$target_test$alpha <- 0.05
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})

test_that("the R script reproduces the run", {
  skip_if_not_installed("mclust")
  spec <- lpa_test_spec(separation = 0.9, nrep = 60)
  result <- suppressWarnings(run_quietly(spec))
  script <- export_script(spec, result)
  expect_true(any(grepl("mclust::mclustBIC", script, fixed = TRUE)))
  out <- utils::capture.output(eval(parse(text = script), envir = new.env()))
  expect_true(any(grepl("Reproduced powerkit's result.", out, fixed = TRUE)))
})
