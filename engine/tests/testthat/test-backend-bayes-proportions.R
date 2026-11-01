# The Bayes factor test of two proportions (backend-bayesfactor-proportions.R):
# BayesFactor's contingencyTableBF() (independent multinomial, rows fixed),
# power summed over every possible table.

prop_spec <- function(p1 = 0.4, p2 = 0.6, alternative = "two_sided", goal = list(type = "power", n = 100),
                      p_sd = NULL, threshold = NULL, a = NULL, ratio = 1) {
  spec <- example_spec("two_proportions")
  spec$population$p1 <- p1
  spec$population$p2 <- p2
  spec$population$p_sd <- p_sd
  spec$target_test <- Filter(Negate(is.null), list(effect = "proportion_difference", method = "bayes_factor",
    alternative = alternative, evidence_threshold = threshold, prior_concentration = a))
  spec$options <- list(allocation_ratio = ratio)
  spec$goal <- goal
  spec
}

package_bf10 <- function(y1, n1, y2, n2, a = 1) {
  table <- matrix(c(y1, n1 - y1, y2, n2 - y2), 2, byrow = TRUE)
  BayesFactor::extractBF(BayesFactor::contingencyTableBF(table, sampleType = "indepMulti",
    fixedMargin = "rows", priorConcentration = a))$bf
}

test_that("the closed form is contingencyTableBF()'s Bayes factor (JASP's default sampling plan)", {
  for (case in list(c(30, 50, 18, 50), c(5, 20, 12, 25), c(40, 60, 41, 60), c(0, 15, 9, 30), c(70, 70, 3, 40))) {
    for (a in c(1, 2.5)) {
      closed <- exp(bfprop_log_bf10_two(case[1], case[2], case[3], case[4], a))
      expect_equal(closed, package_bf10(case[1], case[2], case[3], case[4], a), tolerance = 1e-10)
    }
  }
})

test_that("the one-sided Bayes factor is JASP's: BF10 times the posterior over the prior probability of the side", {
  inputs <- bfprop_inputs(prop_spec(alternative = "greater"))
  y2 <- c(0, 10, 22, 30, 41, 50)
  by_sum <- bfprop_p_above(20, 50, y2, 50, 1)
  by_integration <- bfprop_p_above(20, 50, y2, 50, 1, exact = TRUE)
  expect_equal(by_sum$above, by_integration$above, tolerance = 1e-8)
  expect_equal(by_sum$below[2:4], by_integration$below[2:4], tolerance = 1e-6)
  expect_equal(bfprop_log_bf10(20, 50, y2, 50, inputs), bfprop_log_bf10_two(20, 50, y2, 50, 1) + by_sum$above - log(0.5))
  # The posterior probability, by simulation from the two Beta posteriors.
  set.seed(1)
  draws <- mean(stats::rbeta(2e5, 30 + 1, 20 + 1) > stats::rbeta(2e5, 20 + 1, 30 + 1))
  expect_equal(exp(bfprop_p_above(20, 50, 30, 50, 1)$above), draws, tolerance = 0.005)
  # A concentration that isn't a whole number is integrated.
  expect_equal(bfprop_p_above(20, 50, 30, 50, 2.5)$above, log(stats::integrate(function(x)
    stats::dbeta(x, 22.5, 32.5) * stats::pbeta(x, 32.5, 22.5, lower.tail = FALSE), 0, 1, rel.tol = 1e-10)$value), tolerance = 1e-8)
})

test_that("power is the chance of the tables whose BF10 reaches the threshold (every table scored by contingencyTableBF())", {
  skip_on_cran()
  inputs <- bfprop_inputs(prop_spec(0.3, 0.7, threshold = 6))
  n1 <- 15
  n2 <- 15
  by_package <- 0
  for (y1 in 0:n1) for (y2 in 0:n2) {
    if (package_bf10(y1, n1, y2, n2) >= 6) by_package <- by_package + stats::dbinom(y1, n1, 0.3) * stats::dbinom(y2, n2, 0.7)
  }
  expect_equal(bfprop_power(inputs, 30), by_package, tolerance = 1e-10)
  result <- run_spec(prop_spec(0.3, 0.7, threshold = 6, goal = list(type = "power", n = 30)))
  expect_equal(result$curve$power, by_package, tolerance = 1e-10)
  expect_identical(result$provenance$backend, "BayesFactor")
  expect_true(all(result$check_run$ok))
})

test_that("unequal groups are split as the z test splits them", {
  inputs <- bfprop_inputs(prop_spec(ratio = 2))
  expect_equal(bfprop_groups(inputs, 90), c(30, 60))
  result <- run_spec(prop_spec(ratio = 2, goal = list(type = "power", n = 90)))
  expect_true(all(result$check_run$ok))
})

test_that("'less' with the groups swapped is 'greater'", {
  up <- run_spec(prop_spec(0.4, 0.6, "greater"))
  down <- run_spec(prop_spec(0.6, 0.4, "less"))
  expect_equal(down$curve$power, up$curve$power, tolerance = 1e-9)
  expect_identical(up$bayes$hypotheses, "p1 = p2 against p2 > p1")
  # One-sided in the expected direction has more power than two-sided.
  expect_gt(up$curve$power, run_spec(prop_spec())$curve$power)
})

test_that("the beta design prior averages the binomial over each group's proportion", {
  probs <- bfprop_count_probs(20, 0.4, 0.1)
  d <- bfprop_design_prior(0.4, 0.1)
  by_integration <- vapply(0:20, function(y) {
    stats::integrate(function(p) stats::dbinom(y, 20, p) * stats::dbeta(p, d$a, d$b), 0, 1, rel.tol = 1e-10)$value
  }, numeric(1))
  expect_equal(probs, by_integration, tolerance = 1e-8)
  expect_equal(d$a / (d$a + d$b), 0.4)
  uncertain <- run_spec(prop_spec(p_sd = 0.1))
  expect_false(isTRUE(all.equal(uncertain$curve$power, run_spec(prop_spec())$curve$power)))
  expect_identical(uncertain$bayes$effect_sd, 0.1)
  expect_true(all(uncertain$check_run$ok))
})

test_that("the sample size is the smallest n reaching the target, and the no-effect side is reported", {
  result <- run_spec(prop_spec(goal = list(type = "sample_size", power = 0.8)))
  n <- result$n_required$n
  inputs <- bfprop_inputs(prop_spec())
  expect_gte(bfprop_power(inputs, n), 0.8)
  expect_lt(bfprop_power(inputs, n - 2), 0.8)
  expect_gte(result$bayes$evidence_for_null, 0)
  expect_lt(result$bayes$misleading_evidence, 0.01)
})

test_that("Departure 15's size for two proportions", {
  # Exactly p1 and p2 (powerkit's default) against a design prior equal to
  # JASP's analysis prior under the alternative (each proportion uniform,
  # Beta(1, 1): mean 0.5, SD 1/sqrt(12)), the analogue of bfpwr's default.
  # p1 = .4 against p2 = .6, two-sided, BF10 >= 10, 80%.
  n <- run_spec(prop_spec(goal = list(type = "sample_size", power = 0.8)))$n_required$n
  expect_equal(n, 354)
  uniform <- bfprop_inputs(prop_spec(0.5, 0.5, p_sd = 1 / sqrt(12)))
  expect_equal(unlist(bfprop_design_prior(0.5, 1 / sqrt(12))), c(a = 1, b = 1))
  expect_equal(bfprop_power(uniform, n), 0.753, tolerance = 1e-3)
})

test_that("Known difference 13: JASP's one-sided Bayes factor estimates the posterior probability from 10,000 draws", {
  # For 20 of 50 against 30 of 50, the exact posterior probability that
  # group 2's proportion is higher, against JASP's estimate from 10,000
  # posterior draws: the one-sided log BF10 differs by the log of their
  # ratio.
  exact <- exp(bfprop_p_above(20, 50, 30, 50, 1)$above)
  set.seed(2026)
  jasp_like <- replicate(200, mean(stats::rbeta(1e4, 31, 21) > stats::rbeta(1e4, 21, 31)))
  spread <- stats::sd(log(jasp_like / exact))
  expect_lt(spread, 0.002)
  expect_equal(mean(jasp_like), exact, tolerance = 1e-3)
})

test_that("the exported script reproduces each version", {
  for (spec in list(prop_spec(), prop_spec(alternative = "less", p1 = 0.6, p2 = 0.4),
    prop_spec(p_sd = 0.05, ratio = 2, goal = list(type = "power", n = 90)))) {
    result <- run_spec(spec)
    env <- new.env()
    utils::capture.output(eval(parse(text = export_script(spec, result)), envir = env))
    expect_equal(env$reproduced$power, env$powerkit_result$power, tolerance = 1e-6)
    if (!is.null(env$powerkit_result$n)) expect_identical(as.numeric(env$reproduced$n), as.numeric(env$powerkit_result$n))
  }
})

test_that("plain-word checks for the two-proportion Bayes factor settings", {
  expect_match(paste(population_problems(prop_spec(p_sd = 0.6)), collapse = " "), "too large")
  spec <- prop_spec(); spec$target_test$prior_scale <- 0.7
  expect_error(validate_spec(spec), "prior")
  spec <- prop_spec(); spec$options$proportions_formula <- "arcsine"
  expect_error(validate_spec(spec))
  spec <- example_spec("two_proportions"); spec$population$p_sd <- 0.1
  expect_error(validate_spec(spec))
  spec <- example_spec("two_proportions"); spec$target_test$prior_concentration <- 1
  expect_error(validate_spec(spec))
  spec <- prop_spec(); spec$target_test$prior_concentration <- 0.5
  expect_error(validate_spec(spec))
})
