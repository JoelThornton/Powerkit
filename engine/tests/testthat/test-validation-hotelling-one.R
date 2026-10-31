# Validation: one-sample Hotelling's T-squared (one group's several
# outcomes against fixed values). Backend: since 31 October 2026, the
# noncentral F distribution of Anderson (2003, section 5.4) in base R
# (backend-hotelling.R), as G*Power computes it; Spower's simulation of
# powerkit's p_hotelling_one() experiment stays available as an option
# (test-backend-hotelling-one.R). Build guide section 6:
#   1. published-example agreement with G*Power 3.1
#   2. agreement with the exact calculation: Hotelling's T-squared F test
#      with p and n - p df and noncentrality n times the Mahalanobis
#      distance between the means and the fixed values (stats::mahalanobis()),
#      through pwrss's generic F test
#   3. Type I error (simulation)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

hotelling_one_validation_spec <- function(means, mu0, sds, r, seed, n = NULL, target_power = NULL, alpha = 0.05) {
  v <- validation_variable
  p <- length(sds)
  outcomes <- stats::setNames(lapply(seq_len(p), function(j) v("continuous", paste("Outcome", j))), paste0("Y", seq_len(p)))
  validation_spec(
    design = "basic_test",
    template = "hotelling_one",
    variables = outcomes,
    population = list(metric = "raw", means = means, mu0 = mu0, sds = sds, r = r),
    target_test = list(effect = "mean_vector", method = "hotelling_t2", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power
  )
}

# 1. Published examples (G*Power 3.1) ------------------------------------------

test_that("Hotelling's T-squared, one group: matches G*Power 3.1 (published)", {
  skip_unless_full_validation()
  # Source to transcribe: G*Power 3.1, "F tests - Hotelling's T2: One group
  #   mean vector", a post hoc analysis (or its manual's worked example):
  #   the effect size (Mahalanobis distance Delta), the total sample size,
  #   the number of response variables, alpha and the power in the output.
  #   The test builds outcomes that are uncorrelated with SD 1 and whose
  #   means differ from 0 by Delta / sqrt(p) each, whose Mahalanobis
  #   distance from 0 is Delta.
  delta <- TODO_PUBLISHED_VALUE # Effect size Delta
  total_n <- TODO_PUBLISHED_VALUE # Total sample size
  p <- TODO_PUBLISHED_VALUE # Number of response variables
  alpha <- TODO_PUBLISHED_VALUE # alpha err prob
  published_power <- TODO_PUBLISHED_VALUE # Output: Power (1-beta err prob)
  skip_if_todo(delta, total_n, p, alpha, published_power)

  spec <- hotelling_one_validation_spec(rep(delta / sqrt(p), p), rep(0, p), rep(1, p), 0,
    seed = 401, n = total_n, alpha = alpha)
  expect_power_near(engine_power(spec), published_power)
})

# 2. Agreement with the exact calculation ---------------------------------------

test_that("Hotelling's T-squared, one group: powerkit matches the exact F test", {
  skip_unless_full_validation()
  means <- c(22, 19, 24)
  mu0 <- c(20, 18, 21)
  sds <- c(6, 5, 7)
  r <- 0.5
  n <- 40
  sigma <- diag(sds) %*% (matrix(r, 3, 3) + diag(1 - r, 3)) %*% diag(sds)
  ncp <- n * stats::mahalanobis(means, mu0, sigma)
  exact <- pwrss::power.f.test(ncp = ncp, df1 = 3, df2 = n - 3, alpha = 0.05, plot = FALSE, verbose = FALSE)$power
  spec <- hotelling_one_validation_spec(means, mu0, sds, r, seed = 402, n = n)
  expect_power_near(engine_power(spec), exact)
})

# 3. Type I error ---------------------------------------------------------------

test_that("Hotelling's T-squared, one group: Type I error is near alpha", {
  skip_unless_full_validation()
  spec <- hotelling_one_validation_spec(c(1, 2, 3), c(1, 2, 3), c(1, 2, 3), 0.4, seed = 403, n = 30)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
