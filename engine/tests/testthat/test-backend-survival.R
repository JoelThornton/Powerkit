# Time-to-event outcomes (E43): the log-rank test by Hmisc's cpower() and a
# Cox model's measured predictor by powerSurvEpi's powerEpiCont.default().
# The translation is checked against the packages called directly with the
# arguments written out by hand.

survival_spec <- function(name, goal, ...) {
  spec <- example_spec(name)
  spec$goal <- goal
  changes <- list(...)
  for (field in names(changes)) spec$population[[field]] <- changes[[field]]
  spec
}

test_that("the log-rank test runs on cpower(), exactly, and passes its check run", {
  result <- run_spec(survival_spec("survival_log_rank", list(type = "power", n = 300)))
  expect_equal(result$provenance$backend, "Hmisc")
  expect_equal(result$provenance$backend_function, "Hmisc::cpower")
  expect_equal(result$provenance$method, "exact")
  expect_true(all(result$check_run$ok))
  # cpower() takes group 1's proportion and the percentage reduction in it.
  direct <- Hmisc::cpower(tref = 12, n = 300, mc = 0.4, r = 37.5, accrual = 6, tmin = 12, alpha = 0.05, pr = FALSE)
  expect_equal(result$curve$power, unname(direct), tolerance = 1e-12)
})

test_that("the log-rank test's required n and unequal groups match cpower()", {
  result <- run_spec(example_spec("survival_log_rank"))
  n <- result$n_required$n
  power_at <- function(n) unname(Hmisc::cpower(12, n, 0.4, 37.5, 6, 12, alpha = 0.05, pr = FALSE))
  expect_gte(power_at(n), 0.8)
  expect_lt(power_at(n - 2), 0.8)
  expect_equal(n %% 2, 0)
  # Twice as many in the second group: cpower() given the two group sizes.
  spec <- survival_spec("survival_log_rank", list(type = "power", n = 300))
  spec$options$allocation_ratio <- 2
  direct <- Hmisc::cpower(12, mc = 0.4, r = 37.5, accrual = 6, tmin = 12, alpha = 0.05, nc = 100, ni = 200, pr = FALSE)
  expect_equal(run_spec(spec)$curve$power, unname(direct), tolerance = 1e-12)
  spec$goal$n <- 301
  expect_spec_problem(spec, "ratio 1 : 2")
})

test_that("the log-rank test is close to Freedman's formula (powerSurvEpi), a second package", {
  # Freedman (1982) counts events over the whole study as the probability
  # of an event in each group; with everyone followed for the same time
  # (no accrual) that is p_event. The two approximations differ a little.
  spec <- survival_spec("survival_log_rank", list(type = "power", n = 400), accrual = 0, follow_up = 12)
  hr <- log(1 - 0.25) / log(1 - 0.4)
  freedman <- powerSurvEpi::powerCT.default(nE = 200, nC = 200, pE = 0.25, pC = 0.4, RR = hr, alpha = 0.05)
  expect_equal(run_spec(spec)$curve$power, freedman, tolerance = 0.03)
})

test_that("a Cox model's measured predictor runs on powerEpiCont.default() and matches it, power and N", {
  spec <- survival_spec("survival_cox_predictor", list(type = "power", n = 350))
  result <- run_spec(spec)
  expect_equal(result$provenance$backend, "powerSurvEpi")
  expect_true(all(result$check_run$ok))
  direct <- powerSurvEpi::powerEpiCont.default(n = 350, theta = 0.75, sigma2 = 1, psi = 0.3, rho2 = 0.1, alpha = 0.05)
  expect_equal(result$curve$power, direct, tolerance = 1e-12)
  n <- run_spec(example_spec("survival_cox_predictor"))$n_required$n
  power_at <- function(n) powerSurvEpi::powerEpiCont.default(n, 0.75, 1, 0.3, 0.1, 0.05)
  expect_gte(power_at(n), 0.8)
  expect_lt(power_at(n - 1), 0.8)
  # Package's own sample size, rounded up.
  expect_equal(n, ceiling(powerSurvEpi::ssizeEpiCont.default(power = 0.8, theta = 0.75, sigma2 = 1, psi = 0.3, rho2 = 0.1, alpha = 0.05)), tolerance = 1)
})

test_that("the R scripts reproduce the runs", {
  for (name in c("survival_log_rank", "survival_cox_predictor")) {
    spec <- example_spec(name)
    out <- run_exported_script(spec, run_spec(spec))
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10, label = name)
  }
})

test_that("the spec checks refuse what the formulas can't do", {
  goal <- list(type = "power", n = 300)
  # No effect: no sample size reaches the target power (power at a fixed n
  # is the Type I error rate, which stays allowed).
  ss <- list(type = "sample_size", power = 0.8)
  expect_spec_problem(survival_spec("survival_log_rank", ss, p_event = list(0.3, 0.3)), "zero in this population")
  expect_spec_problem(survival_spec("survival_cox_predictor", ss, hazard_ratio = 1), "zero in this population")
  expect_equal(run_spec(survival_spec("survival_log_rank", goal, p_event = list(0.3, 0.3)))$curve$power, 0.05, tolerance = 1e-12)
  spec <- survival_spec("survival_log_rank", goal)
  spec$target_test$alternative <- "less"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  spec <- survival_spec("survival_log_rank", goal)
  spec$options$method <- "simulation"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})
