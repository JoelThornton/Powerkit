# Welch's t-test by formula is the two-group card's default (Departure 21,
# docs/conventions.md): G*Power and pwr plan for Student's t-test. These
# tests show the size of the difference, from pwr's and pwrss's own
# functions.

welch_default_spec <- function(method, d, ratio, goal) {
  spec <- example_spec("independent_t")
  spec$options <- list(seed = 1L, allocation_ratio = ratio)
  spec$target_test$method <- method
  spec$population$d <- d
  spec$goal <- goal
  spec
}

test_that("Welch's t-test is worked out by pwrss's formula unless simulation is asked for", {
  spec <- welch_default_spec("welch_t", 0.4, 1, list(type = "power", n = 200L))
  result <- run_spec(spec)
  expect_equal(result$provenance$backend, "pwrss")
  expect_equal(result$provenance$method, "exact")
  spec$options$method <- "simulation"
  expect_equal(route_spec(validate_spec(spec))$name, "Spower")
})

test_that("with equal SDs and equal groups, Welch's test needs the same N as Student's", {
  for (d in c(0.2, 0.5, 0.8)) {
    goal <- list(type = "sample_size", power = 0.8)
    student <- run_spec(welch_default_spec("student_t", d, 1, goal))$n_required$n
    welch <- run_spec(welch_default_spec("welch_t", d, 1, goal))$n_required$n
    expect_equal(welch, student)
  }
  # And the same power: pwrss's Welch df are n - 2 here, as Student's.
  goal <- list(type = "power", n = 128L)
  expect_equal(run_spec(welch_default_spec("welch_t", 0.5, 1, goal))$curve$power,
    pwr::pwr.t.test(n = 64, d = 0.5)$power, tolerance = 1e-8)
})

test_that("with unequal groups, Welch's test needs a few more people than Student's", {
  goal <- list(type = "sample_size", power = 0.8)
  # Group 2 twice the size of group 1, d = 0.5: 144 for Student's (pwr), 147
  # for Welch's (pwrss); with three times the size, 172 against 176.
  expect_equal(run_spec(welch_default_spec("student_t", 0.5, 2, goal))$n_required$n, 144)
  expect_equal(run_spec(welch_default_spec("welch_t", 0.5, 2, goal))$n_required$n, 147)
  expect_equal(run_spec(welch_default_spec("student_t", 0.5, 3, goal))$n_required$n, 172)
  expect_equal(run_spec(welch_default_spec("welch_t", 0.5, 3, goal))$n_required$n, 176)
})

test_that("Welch's smallest detectable effect is the d at which pwrss's power reaches the target", {
  spec <- welch_default_spec("welch_t", 0.4, 2, list(type = "sensitivity", n = 120L, power = 0.8))
  spec$population$sd_ratio <- 1.5
  found <- run_spec(spec)$sensitivity
  expect_equal(found$power, 0.8, tolerance = 1e-8)
  at <- spec
  at$goal <- list(type = "power", n = 120L)
  at$population$d <- found$effect
  expect_equal(run_spec(at)$curve$power, 0.8, tolerance = 1e-8)
  # One-sided, in the other direction: a negative d.
  spec$target_test$alternative <- "less"
  spec$population$d <- -0.4
  expect_lt(run_spec(spec)$sensitivity$effect, 0)
  # Equal SDs and groups: Student's answer (pwr solves for d itself).
  equal <- welch_default_spec("welch_t", 0.4, 1, list(type = "sensitivity", n = 128L, power = 0.8))
  expect_equal(run_spec(equal)$sensitivity$effect, pwr::pwr.t.test(n = 64, power = 0.8)$d, tolerance = 1e-4) # pwr solves to about 1e-5
})

test_that("the script reproduces Welch's smallest detectable effect", {
  skip_on_cran()
  spec <- welch_default_spec("welch_t", 0.4, 2, list(type = "sensitivity", n = 120L, power = 0.8))
  spec$population$sd_ratio <- 1.5
  result <- run_spec(spec)
  path <- tempfile(fileext = ".R")
  writeLines(export_script(spec, result), path)
  env <- new.env()
  utils::capture.output(sys.source(path, envir = env))
  expect_equal(env$reproduced$effect, result$sensitivity$effect, tolerance = 1e-6)
})
