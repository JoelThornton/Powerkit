# Validation: the Bayes factor test of one proportion (bfpwr's binomial
# Bayes factor; JASP's one-sided test against a point null).
#   1. a published example (placeholder for the maintainer)
#   2. agreement with simulation: the number of "yes" drawn from the design
#      (the proportion itself drawn from the beta design prior when there
#      is uncertainty), the Bayes factor of each simulated study computed
#      from its definition by numerical integration (not bfpwr), and the
#      share passing the threshold compared with powerkit's exact chance
#   3. the no-effect side, simulated the same way at p = p0
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

bin_validation_spec <- function(n, p, p0 = 0.5, alternative = "two_sided", one_sided_null = NULL, p_sd = NULL,
                                threshold = 10, prior_a = 1, prior_b = 1) {
  spec <- example_spec("one_proportion")
  spec$population$p <- p
  spec$population$p0 <- p0
  spec$population$p_sd <- p_sd
  spec$target_test <- Filter(Negate(is.null), list(effect = "proportion_vs_constant", method = "bayes_factor",
    alternative = alternative, evidence_threshold = threshold, prior_a = prior_a, prior_b = prior_b,
    one_sided_null = one_sided_null))
  spec$goal <- list(type = "power", n = n)
  spec
}

test_that("matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer: a published power or sample
  #   size for a binomial Bayes factor with a beta prior (for example, a
  #   worked example in a paper on Bayesian sample size for proportions).
  #   Transcribe p0, the expected proportion, the beta prior's a and b, the
  #   threshold, the hypotheses (two-sided or one-sided), n and the
  #   published chance of reaching the threshold.
  p0 <- TODO_PUBLISHED_VALUE
  p <- TODO_PUBLISHED_VALUE
  prior_a <- TODO_PUBLISHED_VALUE
  prior_b <- TODO_PUBLISHED_VALUE
  threshold <- TODO_PUBLISHED_VALUE
  alternative <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(p0, p, prior_a, prior_b, threshold, alternative, n, published_power)
  result <- engine_function("run_spec")(bin_validation_spec(n, p, p0, alternative, threshold = threshold,
    prior_a = prior_a, prior_b = prior_b))
  expect_equal(result$curve$power, published_power, tolerance = 0.005)
})

# The Bayes factor of x "yes" out of n from its definition.
bin_bf10 <- function(x, n, p0, a, b, side) {
  range <- switch(side, two_sided = c(0, 1), greater = c(p0, 1), less = c(0, p0))
  mass <- stats::pbeta(range[2], a, b) - stats::pbeta(range[1], a, b)
  stats::integrate(function(t) stats::dbinom(x, n, t) * stats::dbeta(t, a, b) / mass, range[1], range[2],
    rel.tol = 1e-9)$value / stats::dbinom(x, n, p0)
}

# bfpwr's directional test from its definition: H1 p > p0 against H0
# p <= p0, the beta prior truncated to each side.
bin_bf10_directional <- function(x, n, p0, a, b) {
  above <- stats::integrate(function(t) stats::dbinom(x, n, t) * stats::dbeta(t, a, b), p0, 1, rel.tol = 1e-9)$value /
    stats::pbeta(p0, a, b, lower.tail = FALSE)
  below <- stats::integrate(function(t) stats::dbinom(x, n, t) * stats::dbeta(t, a, b), 0, p0, rel.tol = 1e-9)$value /
    stats::pbeta(p0, a, b)
  above / below
}

simulate_bin <- function(nsim, n, p, p_sd, p0, threshold, side, directional, a = 1, b = 1, seed) {
  set.seed(seed)
  theta <- if (is.null(p_sd)) rep(p, nsim) else {
    size <- p * (1 - p) / p_sd^2 - 1
    stats::rbeta(nsim, p * size, (1 - p) * size)
  }
  x <- stats::rbinom(nsim, n, theta)
  bf <- vapply(0:n, function(k) if (directional) bin_bf10_directional(k, n, p0, a, b) else bin_bf10(k, n, p0, a, b, side), numeric(1))
  bf10 <- bf[x + 1]
  c(for_effect = mean(bf10 >= threshold), for_null = mean(1 / bf10 > threshold))
}

check_bin_case <- function(n, p, p_sd = NULL, alternative = "two_sided", one_sided_null = NULL, seed) {
  result <- engine_function("run_spec")(bin_validation_spec(n, p, alternative = alternative,
    one_sided_null = one_sided_null, p_sd = p_sd))
  directional <- identical(one_sided_null, "directional")
  sim <- simulate_bin(20000, n, p, p_sd, 0.5, 10, alternative, directional, seed = seed)
  se <- sqrt(sim[["for_effect"]] * (1 - sim[["for_effect"]]) / 20000)
  expect_lt(abs(result$curve$power - sim[["for_effect"]]), 4 * se + 1e-3)
  null <- simulate_bin(20000, n, 0.5, NULL, 0.5, 10, alternative, directional, seed = seed + 1)
  se_null <- sqrt(null[["for_null"]] * (1 - null[["for_null"]]) / 20000)
  expect_lt(abs(result$bayes$evidence_for_null - null[["for_null"]]), 4 * se_null + 1e-3)
  se_mis <- sqrt(max(null[["for_effect"]], 1e-3) / 20000)
  expect_lt(abs(result$bayes$misleading_evidence - null[["for_effect"]]), 4 * se_mis + 1e-3)
}

test_that("two-sided, exactly p: agrees with simulated Bayes factors", {
  skip_unless_full_validation()
  check_bin_case(120, 0.65, seed = 51)
})

test_that("one-sided against a point null (JASP's test), with uncertainty about p: agrees with simulation", {
  skip_unless_full_validation()
  check_bin_case(90, 0.62, p_sd = 0.08, alternative = "greater", seed = 52)
})

test_that("one-sided, fewer 'yes' than p0: agrees with simulation", {
  skip_unless_full_validation()
  check_bin_case(100, 0.38, alternative = "less", seed = 53)
})

test_that("bfpwr's directional test: agrees with simulation", {
  skip_unless_full_validation()
  check_bin_case(70, 0.66, alternative = "greater", one_sided_null = "directional", seed = 54)
})
