# The Bayes factor test of one proportion (backend-bfpwr-binomial.R): bfpwr's
# binomial Bayes factor, two-sided and directional, and JASP's one-sided
# test against a point null.

bin_spec <- function(alternative = "two_sided", one_sided_null = NULL, p = 0.65, p_sd = NULL, goal = list(type = "power", n = 80)) {
  spec <- example_spec("one_proportion")
  spec$target_test$method <- "bayes_factor"
  spec$target_test$alpha <- NULL
  spec$target_test$alternative <- alternative
  spec$target_test$one_sided_null <- one_sided_null
  spec$population$p <- p
  spec$population$p_sd <- p_sd
  spec$goal <- goal
  spec
}

# The Bayes factor from its definition: the marginal likelihood under the
# beta prior (truncated to `side` for a one-sided test) over the likelihood
# at p0, integrated numerically. Independent of bfpwr.
bf10_by_definition <- function(x, n, p0, a = 1, b = 1, side = c("both", "greater", "less")) {
  side <- match.arg(side)
  range <- switch(side, both = c(0, 1), greater = c(p0, 1), less = c(0, p0))
  mass <- stats::pbeta(range[2], a, b) - stats::pbeta(range[1], a, b)
  marginal <- stats::integrate(function(t) stats::dbinom(x, n, t) * stats::dbeta(t, a, b) / mass,
    range[1], range[2], rel.tol = 1e-10)$value
  marginal / stats::dbinom(x, n, p0)
}

test_that("the one-sided Bayes factor against a point null is the ratio of marginal likelihoods", {
  for (alternative in c("greater", "less")) {
    inputs <- bfbin_inputs(bin_spec(alternative))
    for (x in c(10, 25, 40, 52, 60)) {
      expect_equal(bfbin_point_one_sided_bf10(x, 80, inputs), bf10_by_definition(x, 80, 0.5, side = alternative),
        tolerance = 1e-6, info = paste(alternative, x))
    }
  }
  inputs <- bfbin_inputs(bin_spec("greater"))
  inputs$prior_a <- 3
  inputs$prior_b <- 2
  inputs$p0 <- 0.3
  expect_equal(bfbin_point_one_sided_bf10(20, 50, inputs), bf10_by_definition(20, 50, 0.3, 3, 2, "greater"), tolerance = 1e-6)
})

test_that("bfpwr's two-sided Bayes factor is the same ratio, so its power is the sum over the passing outcomes", {
  expect_equal(1 / bfpwr::binbf01(30, 80, p0 = 0.5, type = "point"), bf10_by_definition(30, 80, 0.5), tolerance = 1e-6)
  result <- run_quietly(bin_spec())
  bf10 <- vapply(0:80, bf10_by_definition, numeric(1), n = 80, p0 = 0.5)
  expect_equal(result$curve$power, sum(stats::dbinom(0:80, 80, 0.65)[bf10 >= 10]), tolerance = 1e-8)
  expect_equal(result$bayes$evidence_for_null, sum(stats::dbinom(0:80, 80, 0.5)[1 / bf10 > 10]), tolerance = 1e-8)
  expect_equal(result$bayes$misleading_evidence, sum(stats::dbinom(0:80, 80, 0.5)[bf10 >= 10]), tolerance = 1e-8)
})

test_that("the one-sided tests: JASP's (the default) and bfpwr's directional test", {
  point <- run_quietly(bin_spec("greater"))
  bf10 <- vapply(0:80, bf10_by_definition, numeric(1), n = 80, p0 = 0.5, side = "greater")
  expect_equal(point$curve$power, sum(stats::dbinom(0:80, 80, 0.65)[bf10 >= 10]), tolerance = 1e-8)
  expect_match(point$bayes$hypotheses, "p = 0.5 against p > 0.5", fixed = TRUE)
  directional <- run_quietly(bin_spec("greater", "directional"))
  expect_equal(directional$curve$power, bfpwr::pbinbf01(k = 1 / 10, n = 80, p0 = 0.5, type = "direction", dp = 0.65))
  expect_match(directional$bayes$hypotheses, "p <= 0.5 against p > 0.5", fixed = TRUE)
  # Fewer "yes" than p0 mirrors more "yes" than 1 - p0.
  for (null in list(NULL, "directional")) {
    less <- run_quietly(bin_spec("less", null, p = 0.35))
    greater <- run_quietly(bin_spec("greater", null, p = 0.65))
    expect_equal(less$curve$power, greater$curve$power, tolerance = 1e-10)
  }
})

test_that("uncertainty about the proportion: a beta design prior with that mean and SD", {
  design <- bfbin_design_prior(0.65, 0.1)
  expect_equal(design$a / (design$a + design$b), 0.65)
  expect_equal(sqrt(design$a * design$b / ((design$a + design$b)^2 * (design$a + design$b + 1))), 0.1)
  probs <- bfbin_outcome_probabilities(30, 0.65, 0.1)
  by_integration <- vapply(0:30, function(x) stats::integrate(function(t) stats::dbinom(x, 30, t) * stats::dbeta(t, design$a, design$b), 0, 1)$value, numeric(1))
  expect_equal(probs, by_integration, tolerance = 1e-7)
  exact <- run_quietly(bin_spec())
  uncertain <- run_quietly(bin_spec(p_sd = 0.1))
  # Averaging over the design prior changes the chance (here it raises it:
  # at n = 80 the chance is still rising steeply with the effect).
  expect_false(isTRUE(all.equal(uncertain$curve$power, exact$curve$power)))
  expect_equal(uncertain$curve$power, bfpwr::pbinbf01(k = 1 / 10, n = 80, p0 = 0.5, type = "point", dp = NA, da = design$a, db = design$b))
  one_sided <- run_quietly(bin_spec("greater", p_sd = 0.1))
  bf10 <- vapply(0:80, bf10_by_definition, numeric(1), n = 80, p0 = 0.5, side = "greater")
  expect_equal(one_sided$curve$power, sum(bfbin_outcome_probabilities(80, 0.65, 0.1)[bf10 >= 10]), tolerance = 1e-8)
})

test_that("the sample size is the smallest that reaches the target, as for the exact binomial test", {
  result <- run_quietly(bin_spec("greater", goal = list(type = "sample_size", power = 0.8)))
  n <- result$n_required$n
  power_at <- function(m) bfbin_power(bfbin_inputs(bin_spec("greater")), m)
  expect_gte(power_at(n), 0.8)
  expect_true(all(vapply(4:(n - 1), power_at, numeric(1)) < 0.8))
})

test_that("the exported script reproduces each version", {
  for (s in list(bin_spec(goal = list(type = "sample_size", power = 0.8)), bin_spec("greater", p_sd = 0.05),
                 bin_spec("less", "directional", p = 0.35, goal = list(type = "sample_size", power = 0.8)))) {
    result <- run_quietly(s)
    script <- export_script(s, result)
    env <- new.env()
    out <- utils::capture.output(eval(parse(text = script), envir = env))
    expect_true(any(grepl("Reproduced powerkit's result", out, fixed = TRUE)))
  }
})

test_that("the settings are checked in plain words", {
  s <- bin_spec(p_sd = 0.6)
  expect_match(paste(population_problems(s), collapse = " "), "too large for a proportion")
  s <- bin_spec(one_sided_null = "point")
  expect_match(paste(population_problems(s), collapse = " "), "one-sided test only")
  s <- bin_spec()
  s$target_test$prior_scale <- 0.707
  expect_match(paste(population_problems(s), collapse = " "), "beta analysis prior")
  t_spec <- example_spec("one_sample_t")
  t_spec$target_test$method <- "bayes_factor"
  t_spec$target_test$alpha <- NULL
  t_spec$target_test$prior_a <- 2
  expect_match(paste(population_problems(t_spec), collapse = " "), "belong to the Bayes factor test of one proportion")
  plain <- example_spec("one_proportion")
  plain$population$p_sd <- 0.1
  expect_match(paste(population_problems(plain), collapse = " "), "only used by the Bayes factor test of one proportion")
})

test_that("Departure 15's size for a proportion: exactly p against bfpwr's default design prior", {
  # bfpwr's default design prior is the analysis prior itself (dp = NA,
  # da = a, db = b): a uniform proportion. powerkit plans for exactly p.
  result <- run_quietly(bin_spec(goal = list(type = "sample_size", power = 0.8)))
  expect_equal(result$n_required$n, 161)
  bfpwr_default <- function(n) bfpwr::pbinbf01(k = 1 / 10, n = n, p0 = 0.5, type = "point", dp = NA, da = 1, db = 1)
  expect_equal(round(bfpwr_default(161), 3), 0.765)
  sizes <- 4:400
  expect_equal(sizes[which(vapply(sizes, bfpwr_default, numeric(1)) >= 0.8)[1]], 229)
})
