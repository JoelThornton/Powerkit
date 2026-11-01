# Validation: trend tests, simulated with Spower by powerkit's own
# experiments. The Cochran-Armitage test of a trend in proportions
# (template proportion_trend, stats::prop.trend.test()) and the
# Jonckheere-Terpstra test of a trend in scores across groups in order
# (oneway_between with target_test > method "jonckheere_terpstra",
# PMCMRplus's jonckheereTest()). Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-trend.R) check
#      powerkit against Spower called directly with the same experiment
#   2. published examples: below, for the maintainer to choose and
#      transcribe
#   3. an independent simulation: below; power from a plain loop of
#      simulated studies, outside Spower, agrees with powerkit's
#   4. Type I error: below; with no trend the rejection rate is alpha
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

trend_validation_spec <- function(proportions, n, scores = NULL) {
  k <- length(proportions)
  spec <- example_spec("proportion_trend")
  spec$variables$X$levels <- as.list(paste("Group", seq_len(k)))
  spec$population$proportions <- as.list(proportions)
  spec$population$scores <- if (is.null(scores)) NULL else as.list(scores)
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 701, nrep = 10000)
  spec
}

jt_validation_spec <- function(means, n, shape = "normal") {
  spec <- example_spec("anova_oneway_between")
  spec$target_test$method <- "jonckheere_terpstra"
  spec$variables$A$levels <- as.list(paste("Group", seq_along(means)))
  spec$population <- list(metric = "standardised", means = as.list(means), sd = 1, score_shape = shape)
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 702, nrep = 10000)
  spec
}

within_mc <- function(a, b, nrep_a, nrep_b) {
  se <- sqrt(a * (1 - a) / nrep_a + b * (1 - b) / nrep_b)
  expect_lt(abs(a - b), 4 * se)
}

test_that("Cochran-Armitage test: matches a published sample-size calculation (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE. A published power or sample-size
  # calculation for the Cochran-Armitage test (for example a dose-response
  # design), for the maintainer to choose; note the scores it uses and
  # whether its groups are equal.
  proportions <- TODO_PUBLISHED_VALUE # proportion in each group, in order
  scores <- TODO_PUBLISHED_VALUE # each group's score
  alpha <- TODO_PUBLISHED_VALUE # two-sided alpha
  n_total <- TODO_PUBLISHED_VALUE # total sample size, equal groups
  power <- TODO_PUBLISHED_VALUE # Output: the power reported
  skip_if_todo(proportions, scores, alpha, n_total, power)

  spec <- trend_validation_spec(proportions, n_total, scores)
  spec$target_test$alpha <- alpha
  result <- run_spec(spec)
  expect_lt(abs(result$curve$power - power), 4 * result$curve$mcse + 0.01)
})

test_that("Cochran-Armitage test: a plain loop of simulated studies agrees with powerkit", {
  skip_unless_full_validation()
  result <- run_spec(trend_validation_spec(c(0.2, 0.25, 0.3, 0.35), 400, c(0, 1, 2, 3)))
  set.seed(711)
  loop <- mean(replicate(10000, {
    yes <- stats::rbinom(4, 100, c(0.2, 0.25, 0.3, 0.35))
    suppressWarnings(stats::prop.trend.test(yes, rep(100, 4), score = 0:3)$p.value) < 0.05
  }))
  within_mc(result$curve$power, loop, 10000, 10000)
})

test_that("Cochran-Armitage test: with no trend the rejection rate is alpha (Type I error)", {
  skip_unless_full_validation()
  result <- run_spec(trend_validation_spec(c(0.3, 0.3, 0.3), 300))
  expect_lt(abs(result$curve$power - 0.05), 4 * sqrt(0.05 * 0.95 / 10000))
})

test_that("Jonckheere-Terpstra test: matches a published power calculation (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE. A published power or sample-size
  # calculation for the Jonckheere-Terpstra test, for the maintainer to
  # choose; note the distribution of the scores it assumes.
  means <- TODO_PUBLISHED_VALUE # group means in SD units, in order
  alpha <- TODO_PUBLISHED_VALUE # two-sided alpha
  n_total <- TODO_PUBLISHED_VALUE # total sample size, equal groups
  power <- TODO_PUBLISHED_VALUE # Output: the power reported
  skip_if_todo(means, alpha, n_total, power)

  spec <- jt_validation_spec(means, n_total)
  spec$target_test$alpha <- alpha
  result <- run_spec(spec)
  expect_lt(abs(result$curve$power - power), 4 * result$curve$mcse + 0.01)
})

test_that("Jonckheere-Terpstra test: a plain loop of simulated studies agrees with powerkit", {
  skip_unless_full_validation()
  result <- run_spec(jt_validation_spec(c(0, 0.25, 0.5), 60, shape = "skewed"))
  set.seed(712)
  loop <- mean(replicate(10000, {
    groups <- lapply(c(0, 0.25, 0.5), function(m) m + (stats::rchisq(20, df = 10) - 10) / sqrt(20))
    PMCMRplus::jonckheereTest(groups)$p.value < 0.05
  }))
  within_mc(result$curve$power, loop, 10000, 10000)
})

test_that("Jonckheere-Terpstra test: with no trend the rejection rate is alpha (Type I error)", {
  skip_unless_full_validation()
  result <- run_spec(jt_validation_spec(c(0, 0, 0), 60, shape = "heavy_tailed"))
  expect_lt(abs(result$curve$power - 0.05), 4 * sqrt(0.05 * 0.95 / 10000))
})

# One-sided tests and unequal groups, against statistics written out here
# independently of the engine: the Cochran-Armitage z statistic (the signed
# square root of prop.trend.test()'s chi-square) and the Jonckheere-Terpstra
# statistic with its normal approximation for untied scores (the sum of
# the Mann-Whitney counts over every ordered pair of groups, with mean
# (N^2 - sum n_i^2) / 4 and variance (N^2 (2N + 3) - sum n_i^2 (2 n_i + 3)) / 72).

ca_z <- function(yes, sizes, scores) {
  p_bar <- sum(yes) / sum(sizes)
  s_bar <- sum(sizes * scores) / sum(sizes)
  sum(yes * (scores - s_bar)) / sqrt(p_bar * (1 - p_bar) * sum(sizes * (scores - s_bar)^2))
}

jt_z <- function(groups) {
  k <- length(groups)
  j <- 0
  for (a in seq_len(k - 1)) for (b in (a + 1):k) j <- j + sum(outer(groups[[a]], groups[[b]], "<"))
  n <- lengths(groups)
  big_n <- sum(n)
  (j - (big_n^2 - sum(n^2)) / 4) / sqrt((big_n^2 * (2 * big_n + 3) - sum(n^2 * (2 * n + 3))) / 72)
}

test_that("Cochran-Armitage test, one-sided with unequal groups: the z statistic in a plain loop agrees with powerkit", {
  skip_unless_full_validation()
  spec <- trend_validation_spec(c(0.2, 0.25, 0.3, 0.35), 396, c(0, 1, 2, 3))
  spec$target_test$alternative <- "greater"
  spec$options$group_ratio <- list(2, 1, 1, 2)
  result <- run_spec(spec)
  sizes <- c(132, 66, 66, 132)
  set.seed(713)
  loop <- mean(replicate(10000, {
    yes <- stats::rbinom(4, sizes, c(0.2, 0.25, 0.3, 0.35))
    ca_z(yes, sizes, 0:3) > stats::qnorm(0.95)
  }))
  within_mc(result$curve$power, loop, 10000, 10000)
})

test_that("Cochran-Armitage test, one-sided with unequal groups: with no trend the rejection rate is alpha (Type I error)", {
  skip_unless_full_validation()
  spec <- trend_validation_spec(c(0.3, 0.3, 0.3), 300)
  spec$target_test$alternative <- "less"
  spec$options$group_ratio <- list(1, 1, 3)
  result <- run_spec(spec)
  expect_lt(abs(result$curve$power - 0.05), 4 * sqrt(0.05 * 0.95 / 10000))
})

test_that("Jonckheere-Terpstra test, one-sided with unequal groups: the statistic in a plain loop agrees with powerkit", {
  skip_unless_full_validation()
  spec <- jt_validation_spec(c(0, 0.25, 0.5), 80)
  spec$target_test$alternative <- "greater"
  spec$options$group_ratio <- list(1, 1, 2)
  result <- run_spec(spec)
  set.seed(714)
  loop <- mean(replicate(10000, {
    groups <- Map(function(m, n) m + stats::rnorm(n), c(0, 0.25, 0.5), c(20, 20, 40))
    jt_z(groups) > stats::qnorm(0.95)
  }))
  within_mc(result$curve$power, loop, 10000, 10000)
})

test_that("Jonckheere-Terpstra test, one-sided with unequal groups: with no trend the rejection rate is alpha (Type I error)", {
  skip_unless_full_validation()
  spec <- jt_validation_spec(c(0, 0, 0), 80, shape = "skewed")
  spec$target_test$alternative <- "less"
  spec$options$group_ratio <- list(2, 1, 1)
  result <- run_spec(spec)
  expect_lt(abs(result$curve$power - 0.05), 4 * sqrt(0.05 * 0.95 / 10000))
})
