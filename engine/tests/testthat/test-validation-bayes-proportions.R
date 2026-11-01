# Validation: the Bayes factor test of two proportions (BayesFactor's
# contingencyTableBF(), independent multinomial with the group sizes fixed:
# JASP's default).
#   1. a published example (placeholder for the maintainer)
#   2. agreement with simulation: each group's count drawn for each
#      simulated study (its proportion first drawn from the beta design
#      prior when there is uncertainty), each study's Bayes factor computed
#      by contingencyTableBF() itself (one-sided: times the posterior
#      probability of the side, from 20,000 posterior draws, over 0.5, as
#      JASP does), and the share passing the threshold compared with
#      powerkit's exact chance
#   3. the no-effect side, simulated the same way with both groups at
#      group 1's proportion
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

prop_validation_spec <- function(n, p1, p2, alternative = "two_sided", p_sd = NULL, threshold = 10, a = 1, ratio = 1) {
  spec <- example_spec("two_proportions")
  spec$population$p1 <- p1
  spec$population$p2 <- p2
  spec$population$p_sd <- p_sd
  spec$target_test <- list(effect = "proportion_difference", method = "bayes_factor", alternative = alternative,
    evidence_threshold = threshold, prior_concentration = a)
  spec$options <- list(allocation_ratio = ratio)
  spec$goal <- list(type = "power", n = n)
  spec
}

test_that("matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer: a published power or sample
  #   size for the Bayes factor test of two proportions (a 2 x 2 table,
  #   independent multinomial sampling with the group sizes fixed, Gunel
  #   and Dickey's Bayes factor). Transcribe the two proportions, the
  #   prior concentration, the threshold, the hypotheses, the group sizes
  #   and the published chance of reaching the threshold.
  p1 <- TODO_PUBLISHED_VALUE
  p2 <- TODO_PUBLISHED_VALUE
  a <- TODO_PUBLISHED_VALUE
  threshold <- TODO_PUBLISHED_VALUE
  alternative <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(p1, p2, a, threshold, alternative, n, published_power)
  result <- engine_function("run_spec")(prop_validation_spec(n, p1, p2, alternative, threshold = threshold, a = a))
  expect_equal(result$curve$power, published_power, tolerance = 0.005)
})

# BF10 from contingencyTableBF(); one-sided by JASP's rule, with the
# posterior probability of the side estimated from draws.
validation_prop_bf10 <- function(y1, n1, y2, n2, a, side) {
  table <- matrix(c(y1, n1 - y1, y2, n2 - y2), 2, byrow = TRUE)
  bf <- BayesFactor::extractBF(BayesFactor::contingencyTableBF(table, sampleType = "indepMulti",
    fixedMargin = "rows", priorConcentration = a))$bf
  if (identical(side, "two_sided")) return(bf)
  above <- mean(stats::rbeta(2e4, y2 + a, n2 - y2 + a) > stats::rbeta(2e4, y1 + a, n1 - y1 + a))
  bf * (if (identical(side, "greater")) above else 1 - above) / 0.5
}

simulate_props <- function(nsim, n1, n2, p1, p2, p_sd, a, threshold, side, seed) {
  set.seed(seed)
  draw <- function(p) {
    if (is.null(p_sd)) return(rep(p, nsim))
    size <- p * (1 - p) / p_sd^2 - 1
    stats::rbeta(nsim, p * size, (1 - p) * size)
  }
  y1 <- stats::rbinom(nsim, n1, draw(p1))
  y2 <- stats::rbinom(nsim, n2, draw(p2))
  bf10 <- mapply(function(u, v) validation_prop_bf10(u, n1, v, n2, a, side), y1, y2)
  c(for_effect = mean(bf10 >= threshold), for_null = mean(1 / bf10 >= threshold))
}

check_prop_case <- function(n, p1, p2, p_sd = NULL, alternative = "two_sided", a = 1, ratio = 1, nsim = 4000, seed) {
  result <- engine_function("run_spec")(prop_validation_spec(n, p1, p2, alternative, p_sd = p_sd, a = a, ratio = ratio))
  n1 <- round(n / (1 + ratio))
  n2 <- n - n1
  sim <- simulate_props(nsim, n1, n2, p1, p2, p_sd, a, 10, alternative, seed)
  se <- sqrt(sim[["for_effect"]] * (1 - sim[["for_effect"]]) / nsim)
  expect_lt(abs(result$curve$power - sim[["for_effect"]]), 4 * se + 2e-3)
  null <- simulate_props(nsim, n1, n2, p1, p1, NULL, a, 10, alternative, seed + 1)
  se_null <- sqrt(max(null[["for_null"]] * (1 - null[["for_null"]]), 1e-3) / nsim)
  expect_lt(abs(result$bayes$evidence_for_null - null[["for_null"]]), 4 * se_null + 2e-3)
  se_mis <- sqrt(max(null[["for_effect"]], 1e-3) / nsim)
  expect_lt(abs(result$bayes$misleading_evidence - null[["for_effect"]]), 4 * se_mis + 2e-3)
}

test_that("two-sided, equal groups: agrees with simulated Bayes factors", {
  skip_unless_full_validation()
  check_prop_case(200, 0.3, 0.5, seed = 71)
})

test_that("two-sided, unequal groups and a prior concentration of 2: agrees with simulation", {
  skip_unless_full_validation()
  check_prop_case(240, 0.2, 0.4, a = 2, ratio = 2, seed = 72)
})

test_that("one-sided, with uncertainty about the proportions: agrees with simulation", {
  skip_unless_full_validation()
  check_prop_case(160, 0.35, 0.6, p_sd = 0.08, alternative = "greater", nsim = 2000, seed = 73)
})

test_that("one-sided in the other direction: agrees with simulation", {
  skip_unless_full_validation()
  check_prop_case(150, 0.6, 0.35, alternative = "less", nsim = 2000, seed = 74)
})
