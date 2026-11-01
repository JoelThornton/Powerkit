# The Bayes factor test of a correlation (backend-bayesfactor-correlation.R):
# BayesFactor's correlationBF(), power from the exact distribution of r.

cor_spec <- function(r = 0.3, alternative = "two_sided", goal = list(type = "power", n = 100), r_sd = NULL,
                     threshold = NULL, width = NULL) {
  spec <- example_spec("correlation")
  spec$population$r <- r
  spec$population$r_sd <- r_sd
  spec$target_test <- Filter(Negate(is.null), list(effect = "correlation", method = "bayes_factor",
    alternative = alternative, evidence_threshold = threshold, prior_width = width))
  spec$goal <- goal
  spec
}

# JASP's exact two-sided BF10 for Pearson's r with a stretched beta prior of
# width kappa (jaspRegression's bstats, bf10CorExact(); Ly, Marsman and
# Wagenmakers, 2018), written out as a check that does not use BayesFactor.
jasp_bf10 <- function(n, r, kappa = 1) {
  exp(lbeta(1 / kappa + (n - 1) / 2, 1 / 2) - lbeta(1 / kappa, 1 / 2) + (1 / kappa + 1 - n / 2) * log(1 - r^2) +
    log(Re(hypergeo::hypergeo(1 / kappa + 1 / 2, 1 / kappa + 1 / 2, 1 / kappa + n / 2, r^2))))
}

# BF10 from its definition: the exact density of r, averaged over the
# analysis prior (truncated to rho > 0 for one-sided), over its density at
# rho = 0.
bf10_by_definition <- function(n, r, kappa = 1, one_sided = FALSE) {
  prior <- function(rho) stats::dbeta((rho + 1) / 2, 1 / kappa, 1 / kappa) / 2
  lower <- if (one_sided) 0 else -1
  mass <- if (one_sided) stats::pbeta(0.5, 1 / kappa, 1 / kappa, lower.tail = FALSE) else 1
  f <- function(rho) vapply(rho, function(p) SuppDists::dPearson(r, n, p), numeric(1)) * prior(rho) / mass
  stats::integrate(f, lower, 1, rel.tol = 1e-10)$value / SuppDists::dPearson(r, n, 0)
}

test_that("correlationBF() gives JASP's two-sided Bayes factor at the same prior width", {
  skip_if_not_installed("hypergeo")
  inputs <- list(alternative = "two.sided", prior_width = 1)
  for (case in list(c(20, 0.3), c(50, 0.2), c(100, 0.25), c(30, 0.5), c(200, 0.1))) {
    for (w in c(1, 1 / 3)) {
      inputs$prior_width <- w
      bf <- exp(bfcor_log_bf10(case[1], case[2], inputs))
      expect_equal(bf, jasp_bf10(case[1], case[2], w), tolerance = 1e-8)
      expect_equal(bf, bf10_by_definition(case[1], case[2], w), tolerance = 1e-6)
    }
  }
})

test_that("the one-sided Bayes factor is the prior truncated to that side, against rho = 0", {
  inputs <- list(alternative = "greater", prior_width = 1)
  for (case in list(c(20, 0.3), c(100, 0.25), c(60, -0.1))) {
    bf <- exp(bfcor_log_bf10(case[1], case[2], inputs))
    # correlationBF()'s interval Bayes factor is within 0.1% of the
    # definition (JASP's is exact; see docs/conventions.md).
    expect_equal(bf, bf10_by_definition(case[1], case[2], one_sided = TRUE), tolerance = 1e-3)
  }
})

test_that("the data given to correlationBF() have exactly the correlation asked for", {
  for (r in c(-0.6, 0, 0.123, 0.9)) {
    d <- bfcor_data(37, r)
    expect_equal(stats::cor(d$x, d$y), r, tolerance = 1e-12)
  }
})

test_that("power is the chance of a correlation beyond the one where BF10 reaches the threshold", {
  inputs <- bfcor_inputs(cor_spec())
  bound <- bfcor_bounds(inputs, 100, "effect")$effect
  expect_equal(exp(bfcor_log_bf10(100, bound, inputs)), 10, tolerance = 1e-6)
  expect_lt(exp(bfcor_log_bf10(100, bound - 0.01, inputs)), 10)
  expect_gt(exp(bfcor_log_bf10(100, bound + 0.01, inputs)), 10)
  density <- function(r) vapply(r, function(x) SuppDists::dPearson(x, 100, 0.3), numeric(1))
  by_integration <- stats::integrate(density, bound, 1, rel.tol = 1e-10)$value +
    stats::integrate(density, -1, -bound, rel.tol = 1e-10)$value
  result <- run_spec(cor_spec())
  expect_equal(result$curve$power, by_integration, tolerance = 1e-7)
  expect_identical(result$provenance$backend, "BayesFactor")
  expect_true(all(c("BayesFactor", "SuppDists") %in% names(result$provenance$packages)))
})

test_that("'less' mirrors 'greater'", {
  up <- run_spec(cor_spec(0.25, "greater"))
  down <- run_spec(cor_spec(-0.25, "less"))
  expect_equal(down$curve$power, up$curve$power, tolerance = 1e-9)
  expect_equal(down$bayes$evidence_for_null, up$bayes$evidence_for_null, tolerance = 1e-9)
  expect_identical(up$bayes$hypotheses, "rho = 0 against rho > 0")
})

test_that("the stretched beta design prior averages power over correlations around r", {
  inputs <- bfcor_inputs(cor_spec(r_sd = 0.1))
  design <- bfcor_design_prior(0.3, 0.1)
  expect_equal(2 * design$a / (design$a + design$b) - 1, 0.3)
  expect_equal(2 * sqrt(design$a * design$b / ((design$a + design$b)^2 * (design$a + design$b + 1))), 0.1)
  bound <- bfcor_bounds(inputs, 100, "effect")$effect
  at <- function(rho) bfcor_beyond(bound, 100, rho, "two.sided")
  grid <- seq(-0.999, 0.999, length.out = 4001)
  weights <- stats::dbeta((grid + 1) / 2, design$a, design$b)
  by_grid <- sum(vapply(grid, at, numeric(1)) * weights) / sum(weights)
  uncertain <- run_spec(cor_spec(r_sd = 0.1))
  expect_equal(uncertain$curve$power, by_grid, tolerance = 1e-4)
  expect_false(isTRUE(all.equal(uncertain$curve$power, run_spec(cor_spec())$curve$power)))
  expect_identical(uncertain$bayes$effect_sd, 0.1)
})

test_that("the sample size is the smallest n reaching the target", {
  result <- run_spec(cor_spec(goal = list(type = "sample_size", power = 0.8)))
  n <- result$n_required$n
  inputs <- bfcor_inputs(cor_spec())
  expect_gte(bfcor_power(inputs, n), 0.8)
  expect_lt(bfcor_power(inputs, n - 1), 0.8)
  # With no effect: some chance of strong evidence for none, little of
  # misleading evidence for one.
  expect_gt(result$bayes$evidence_for_null, 0)
  expect_lt(result$bayes$misleading_evidence, 0.01)
})

test_that("JASP's prior width (1) against BayesFactor's default (1/3): the size of the difference", {
  # Known difference: powerkit takes JASP's default width; BayesFactor's
  # own default, rscale "medium", is 1/3 (docs/conventions.md, "Bayes factor
  # test of a correlation (E4)"). r = .3, BF10 >= 10, 80%.
  jasp <- run_spec(cor_spec(goal = list(type = "sample_size", power = 0.8)))$n_required$n
  medium <- run_spec(cor_spec(goal = list(type = "sample_size", power = 0.8), width = 1 / 3))$n_required$n
  expect_equal(jasp, 162)
  expect_equal(medium, 146)
})

test_that("Departure 15's size for a correlation", {
  # Exactly r (powerkit's default) against a design prior equal to JASP's
  # uniform analysis prior (stretched beta, a = b = 1: mean 0, SD 1/sqrt(3)),
  # the analogue of bfpwr's default. r = .3, BF10 >= 10, 162 people.
  uniform <- bfcor_inputs(cor_spec(r = 0, r_sd = 1 / sqrt(3)))
  expect_equal(unlist(bfcor_design_prior(0, 1 / sqrt(3))), c(a = 1, b = 1))
  expect_equal(bfcor_power(uniform, 162), 0.764, tolerance = 1e-3)
  expect_gte(bfcor_power(bfcor_inputs(cor_spec()), 162), 0.8)
})

test_that("the exported script reproduces each version", {
  for (spec in list(cor_spec(), cor_spec(-0.3, "less"), cor_spec(r_sd = 0.1, goal = list(type = "sample_size", power = 0.6)))) {
    result <- run_spec(spec)
    env <- new.env()
    utils::capture.output(eval(parse(text = export_script(spec, result)), envir = env))
    expect_equal(env$reproduced$power, env$powerkit_result$power, tolerance = 1e-6)
    if (!is.null(env$powerkit_result$n)) expect_identical(as.numeric(env$reproduced$n), as.numeric(env$powerkit_result$n))
  }
})

test_that("plain-word checks for the correlation's Bayes factor settings", {
  expect_match(paste(population_problems(cor_spec(r = 0.3, r_sd = 0.99)), collapse = " "), "too large for a correlation")
  spec <- cor_spec(); spec$population$score_shape <- "skewed"
  expect_match(paste(population_problems(spec), collapse = " "), "score_shape")
  spec <- cor_spec(); spec$target_test$prior_scale <- 0.7
  expect_error(validate_spec(spec), "prior")
  spec <- example_spec("correlation"); spec$population$r_sd <- 0.1
  expect_error(validate_spec(spec), "r_sd")
  spec <- example_spec("correlation"); spec$target_test$prior_width <- 1
  expect_error(validate_spec(spec))
  # The check run passes.
  expect_true(all(run_spec(cor_spec())$check_run$ok))
})
