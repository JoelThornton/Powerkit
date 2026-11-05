# Exploratory factor analysis (factor_analysis / efa): the chance every
# factor's loadings are recovered, simulated with Spower around psych's
# fa(). The data, the matching, the experiment, the check run and the
# exported script; accuracy is checked by test-validation-efa.R.

efa_test_spec <- function(n = 150, nrep = 100, ...) {
  spec <- example_spec("efa")
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = nrep, seed = 13)
  changes <- list(...)
  for (k in names(changes)) spec$population[[k]] <- changes[[k]]
  spec
}

test_that("factors are matched one to one, whatever their order and sign", {
  true <- efa_loadings(3, 4, 0.7)
  shuffled <- true[, c(3, 1, 2)]
  shuffled[, 2] <- -shuffled[, 2]
  expect_equal(efa_matched_congruence(shuffled, true), c(1, 1, 1))
  # Two true factors can't both claim the same estimated factor.
  merged <- cbind(true[, 1] + true[, 2], true[, 3], 0)
  expect_lt(min(efa_matched_congruence(merged + 1e-9, true)), 0.95)
  expect_equal(nrow(efa_permutations(4)), 24)
})

test_that("strong loadings are recovered and weak ones at a small n are not", {
  skip_if_not_installed("GPArotation")
  strong <- suppressWarnings(run_quietly(efa_test_spec(n = 300, loading = 0.8)))
  expect_gt(strong$curve$power, 0.9)
  weak <- suppressWarnings(run_quietly(efa_test_spec(n = 40, loading = 0.3)))
  expect_lt(weak$curve$power, 0.1)
  expect_true(all(strong$check_run$ok))
  expect_match(strong$provenance$backend_function, "psych", fixed = TRUE)
  expect_true(all(c("psych", "GPArotation") %in% names(strong$provenance$packages)))
})

test_that("there is no alpha, and the congruence asked for is in range", {
  spec <- efa_test_spec()
  spec$target_test$alpha <- 0.05
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  spec <- efa_test_spec()
  spec$target_test$congruence <- 0.5
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})

test_that("the R script reproduces the run", {
  skip_if_not_installed("GPArotation")
  spec <- efa_test_spec()
  result <- suppressWarnings(run_quietly(spec))
  script <- export_script(spec, result)
  expect_true(any(grepl("psych::fa(", script, fixed = TRUE)))
  out <- utils::capture.output(eval(parse(text = script), envir = new.env()))
  expect_true(any(grepl("Reproduced powerkit's result.", out, fixed = TRUE)))
})
