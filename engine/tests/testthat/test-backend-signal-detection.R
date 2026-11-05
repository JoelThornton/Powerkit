# Signal detection: d' in two conditions or groups (signal_detection /
# dprime), simulated with Spower. The data generator, the estimate, the
# spec checks, the check run and the exported script; accuracy is checked
# by test-validation-signal-detection.R.

dprime_spec <- function(within = TRUE, n = 40, ...) {
  spec <- example_spec("dprime")
  if (!within) {
    spec$variables$G$type <- "binary"
    spec$population$r_dprime <- NULL
  }
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = 200, seed = 7)
  changes <- list(...)
  for (k in names(changes)) spec$population[[k]] <- changes[[k]]
  spec
}

test_that("d' is estimated with the log-linear correction, so perfect scores stay finite", {
  # Hautus (1995): 0.5 added to each count and 1 to each number of trials.
  expect_equal(dprime_estimate(40, 0, 40, 40), stats::qnorm(40.5 / 41) - stats::qnorm(0.5 / 41))
  expect_true(is.finite(dprime_estimate(40, 0, 40, 40)))
  expect_equal(dprime_estimate(20, 20, 40, 40), 0)
})

test_that("the paired and two-group versions run on Spower and pass their check runs", {
  for (within in c(TRUE, FALSE)) {
    result <- run_quietly(dprime_spec(within, n = if (within) 40 else 80))
    expect_equal(result$provenance$backend, "Spower")
    expect_match(result$provenance$backend_function, if (within) "paired t-test" else "Student's t-test", fixed = TRUE)
    expect_true(all(result$check_run$ok))
  }
})

test_that("with no difference the test rejects at about alpha, and more trials give more power", {
  null <- dprime_spec(n = 40, dprime = list(1.2, 1.2))
  null$options$nrep <- 2000
  expect_lt(abs(run_quietly(null)$curve$power - 0.05), 0.015)
  few <- run_quietly(dprime_spec(n = 30, trials_signal = 10, trials_noise = 10))$curve$power
  many <- run_quietly(dprime_spec(n = 30, trials_signal = 100, trials_noise = 100))$curve$power
  expect_gt(many, few)
})

test_that("the spec checks speak plainly, and two groups split evenly", {
  spec <- dprime_spec(within = FALSE)
  spec$population$r_dprime <- 0.5
  expect_spec_problem(spec, "belongs to the same people in both")
  odd <- dprime_spec(within = FALSE, n = 81)
  expect_spec_problem(odd, "split into 2 equal groups")
})

test_that("the R script reproduces the run", {
  spec <- dprime_spec()
  result <- run_quietly(spec)
  script <- export_script(spec, result)
  expect_true(any(grepl("p_dprime <- function", script, fixed = TRUE)))
  env <- new.env()
  out <- utils::capture.output(eval(parse(text = script), envir = env))
  expect_true(any(grepl("Reproduced powerkit's result.", out, fixed = TRUE)))
})
