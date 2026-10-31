# Validation: one-way MANOVA (Pillai's trace) and, with two groups,
# Hotelling's T-squared. Backend: with three or more groups, Spower
# simulation of powerkit's p_manova() experiment (multivariate normal
# scores, stats::manova()), as no package powerkit builds on has a formula
# for MANOVA power; G*Power uses an approximation for Pillai's trace there,
# so the published comparison allows for Monte Carlo error. With two
# groups, since 31 October 2026, the exact noncentral F of Hotelling's
# T-squared (Anderson, 2003, sections 5.3.4 and 5.4; backend-hotelling.R),
# as G*Power computes it.
# Build guide section 6:
#   1. published-example agreement with G*Power 3.1
#   2. agreement with an exact calculation (two groups: Hotelling's
#      T-squared as pwrss's F test of R-squared) and with a simulation
#      written out separately here
#   3. Type I error (simulation)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# `means` is a list with one vector per group; `sds` one SD per outcome.
manova_validation_spec <- function(means, sds, r, seed, n = NULL, target_power = NULL, alpha = 0.05) {
  v <- validation_variable
  p <- length(sds)
  outcomes <- stats::setNames(lapply(seq_len(p), function(j) v("continuous", paste("Outcome", j))), paste0("Y", seq_len(p)))
  validation_spec(
    design = "basic_test",
    template = "manova",
    variables = c(list(A = v("between_factor", "Group", levels = paste("Group", seq_along(means)))), outcomes),
    population = list(metric = "raw", means = means, sds = sds, r = r),
    target_test = list(effect = "main_effect_A", method = "pillai_trace", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power
  )
}

# 1. Published examples (G*Power 3.1) ------------------------------------------

test_that("Hotelling's T-squared, two groups: matches G*Power 3.1 (published)", {
  skip_unless_full_validation()
  # Source to transcribe: G*Power 3.1, "F tests - Hotelling's T2: Two group
  #   mean vector", a post hoc analysis (or its manual's worked example):
  #   the effect size (Mahalanobis distance Delta), the sample size of each
  #   group, the number of response variables, alpha and the power in the
  #   output. The test builds groups whose outcomes are uncorrelated with
  #   SD 1 and differ by Delta / sqrt(p) on each, whose Mahalanobis distance
  #   is Delta.
  delta <- TODO_PUBLISHED_VALUE # Effect size Delta
  n_group <- TODO_PUBLISHED_VALUE # Sample size group 1 (= group 2)
  p <- TODO_PUBLISHED_VALUE # Number of response variables
  alpha <- TODO_PUBLISHED_VALUE # alpha err prob
  published_power <- TODO_PUBLISHED_VALUE # Output: Power (1-beta err prob)
  skip_if_todo(delta, n_group, p, alpha, published_power)

  spec <- manova_validation_spec(list(rep(0, p), rep(delta / sqrt(p), p)), rep(1, p), 0,
    seed = 101, n = 2 * n_group, alpha = alpha)
  expect_power_near(engine_power(spec), published_power)
})

test_that("MANOVA global effect, three or more groups: matches G*Power 3.1 (published)", {
  skip_unless_full_validation()
  # Source to transcribe: G*Power 3.1, "F tests - MANOVA: Global effects",
  #   with the effect size set from means in its Determine panel: each
  #   group's mean on each response variable, the SD of each response and
  #   the correlation between them (the same for every pair), the sample
  #   size, alpha, Pillai V as the statistic and the power in the output.
  #   G*Power uses an F approximation to Pillai's trace here, so a small
  #   difference from the simulation is possible; if the test fails by a
  #   little, that is a known difference to record (docs/conventions.md),
  #   not a reason to change the value.
  means <- TODO_PUBLISHED_VALUE # Determine panel: list(c(group 1 means), c(group 2 means), ...)
  sds <- TODO_PUBLISHED_VALUE # Determine panel: SD of each response variable
  r <- TODO_PUBLISHED_VALUE # Determine panel: correlation between response variables
  total_n <- TODO_PUBLISHED_VALUE # Total sample size
  alpha <- TODO_PUBLISHED_VALUE # alpha err prob
  published_power <- TODO_PUBLISHED_VALUE # Output: Power (1-beta err prob)
  skip_if_todo(means, sds, r, total_n, alpha, published_power)

  spec <- manova_validation_spec(means, sds, r, seed = 102, n = total_n, alpha = alpha)
  expect_power_near(engine_power(spec), published_power)
})

# 2. Agreement with an exact calculation and a separate simulation ------------

test_that("Hotelling's T-squared: powerkit matches the exact power (pwrss's F test of R-squared)", {
  skip_unless_full_validation()
  skip_if_not_installed("pwrss")
  # Two-group Hotelling's T-squared is the F test of regressing the group
  # on the outcomes, with Cohen's f-squared = D^2 * n1 * n2 / N^2 (D^2 the
  # Mahalanobis distance between the means), so pwrss computes it exactly.
  means <- list(c(0, 0, 0, 0), c(0.3, 0.3, 0.1, 0))
  sds <- c(1, 1, 1, 1)
  r <- 0.3
  n <- 160
  correlation <- matrix(r, 4, 4)
  diag(correlation) <- 1
  d <- means[[2]] - means[[1]]
  f2 <- drop(t(d) %*% solve(correlation) %*% d) * (n / 2)^2 / n^2
  exact <- pwrss::power.f.regression(r.squared = f2 / (1 + f2), k.total = 4, n = n, alpha = 0.05, verbose = FALSE)$power
  spec <- manova_validation_spec(means, sds, r, seed = 201, n = n)
  expect_power_near(engine_power(spec), exact)
})

test_that("MANOVA, three groups: powerkit matches a simulation written out separately", {
  skip_unless_full_validation()
  skip_if_not_installed("Spower")
  skip_if_not_installed("MASS")
  means <- list(c(20, 18, 22), c(18, 16.5, 20), c(17, 16, 19))
  sds <- c(6, 5, 7)
  r <- 0.5
  # Written independently of powerkit's p_manova(): MASS::mvrnorm() and
  # car-free stats::manova(), Pillai's trace.
  sigma <- diag(sds) %*% (matrix(r, 3, 3) + diag(1 - r, 3)) %*% diag(sds)
  manova_by_hand <- function(n_group) {
    y <- do.call(rbind, lapply(means, function(m) MASS::mvrnorm(n_group, m, sigma)))
    g <- factor(rep(1:3, each = n_group))
    summary(stats::manova(y ~ g), test = "Pillai")$stats[1, "Pr(>F)"]
  }
  direct <- run_spower(quote(manova_by_hand(n_group = 60)), 0.05, validation_nrep(), 202,
    data = list(manova_by_hand = manova_by_hand))
  spec <- manova_validation_spec(means, sds, r, seed = 203, n = 180)
  expect_power_agrees(engine_power(spec), direct)
})

# 3. Type I error ---------------------------------------------------------------

test_that("MANOVA: Type I error is near alpha", {
  skip_unless_full_validation()
  spec <- manova_validation_spec(list(c(1, 2, 3), c(1, 2, 3), c(1, 2, 3)), c(1, 2, 3), 0.4, seed = 301, n = 90)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
