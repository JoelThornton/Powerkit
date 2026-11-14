# Validation: Yuen's trimmed-means tests, for two groups and for paired
# measurements.
# Backend: Spower simulation of powerkit's experiments p_yuen() and
# p_yuend(), which call WRS2's yuen() and yuend().
#   1. agreement with an independent simulation: the same scores drawn and
#      tested by Yuen's statistics written out from their definitions
#      (trimmed means, Winsorized variances and covariance, Yuen's df),
#      without the package
#   2. Type I error with heavy tails, unequal spreads and unequal groups
#   3. with no trimming, Yuen's paired test is the paired t-test: power
#      from pwr's exact formula
#   4. published example: placeholder, for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

yuen_validation_spec <- function(template, effect, n, shape, trim = 0.2, sd_ratio = NULL, r = NULL,
                                 ratio = 1, seed = 6301) {
  spec <- example_spec(template)
  spec$target_test$method <- "yuen"
  spec$target_test$trim <- trim
  spec$population$score_shape <- shape
  if (template == "paired_t") {
    spec$population$dz <- effect
    spec$population$r <- r
  } else {
    spec$population$d <- effect
    spec$population$sd_ratio <- sd_ratio
  }
  spec$goal <- list(type = "power", n = n)
  spec$options <- c(list(nrep = validation_nrep(), seed = seed), if (ratio != 1) list(allocation_ratio = ratio))
  spec <- validate_spec(spec)
  skip_if_no_backend(spec)
  spec
}

# A sample's trimmed mean, its Winsorized scores, and the number left
# after trimming (Wilcox, Introduction to Robust Estimation, sections 3.2
# and 5.3: g = floor(trim n) scores trimmed from each end).
trimmed <- function(x, trim) {
  n <- length(x)
  g <- floor(trim * n)
  sorted <- sort(x)
  low <- sorted[g + 1]
  high <- sorted[n - g]
  list(mean = mean(sorted[(g + 1):(n - g)]), winsorized = pmin(pmax(x, low), high), h = n - 2 * g)
}

# Yuen's test of two groups: d_j = (n_j - 1) s_wj^2 / (h_j (h_j - 1)),
# t = (trimmed mean 1 - trimmed mean 2) / sqrt(d_1 + d_2), and
# df = (d_1 + d_2)^2 / (d_1^2 / (h_1 - 1) + d_2^2 / (h_2 - 1)).
yuen_p_by_hand <- function(x, y, trim) {
  a <- trimmed(x, trim)
  b <- trimmed(y, trim)
  d1 <- (length(x) - 1) * stats::var(a$winsorized) / (a$h * (a$h - 1))
  d2 <- (length(y) - 1) * stats::var(b$winsorized) / (b$h * (b$h - 1))
  t <- (a$mean - b$mean) / sqrt(d1 + d2)
  df <- (d1 + d2)^2 / (d1^2 / (a$h - 1) + d2^2 / (b$h - 1))
  2 * stats::pt(-abs(t), df)
}

# Yuen's paired test: as above with the Winsorized covariance,
# d_12 = (n - 1) cov_w / (h (h - 1)), t = (tm_1 - tm_2) /
# sqrt(d_1 + d_2 - 2 d_12), df = h - 1.
yuend_p_by_hand <- function(x, y, trim) {
  a <- trimmed(x, trim)
  b <- trimmed(y, trim)
  n <- length(x)
  h <- a$h
  d1 <- (n - 1) * stats::var(a$winsorized) / (h * (h - 1))
  d2 <- (n - 1) * stats::var(b$winsorized) / (h * (h - 1))
  d12 <- (n - 1) * stats::cov(a$winsorized, b$winsorized) / (h * (h - 1))
  t <- (a$mean - b$mean) / sqrt(d1 + d2 - 2 * d12)
  2 * stats::pt(-abs(t), h - 1)
}

yuen_draw <- function(shape) {
  switch(shape,
    normal = function(n) stats::rnorm(n),
    skewed = function(n) (stats::rchisq(n, df = 10) - 10) / sqrt(20),
    heavy_tailed = function(n) stats::rt(n, df = 3) / sqrt(3))
}

yuen_by_hand <- function(d, sd_ratio, shape, trim, n1, n2, nrep, seed) {
  draw <- yuen_draw(shape)
  sd1 <- sqrt(2 / (1 + sd_ratio^2))
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    yuen_p_by_hand(sd1 * draw(n1), d + sd_ratio * sd1 * draw(n2), trim) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

yuend_by_hand <- function(dz, r, shape, trim, n, nrep, seed) {
  draw <- yuen_draw(shape)
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    level <- stats::rnorm(n)
    x <- sqrt(r) * level + sqrt(1 - r) * draw(n)
    y <- dz * sqrt(2 * (1 - r)) + sqrt(r) * level + sqrt(1 - r) * draw(n)
    yuend_p_by_hand(x, y, trim) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("Yuen: powerkit agrees with the tests written out (simulation)", {
  skip_unless_full_validation()
  # The statistics written out give WRS2's p-values.
  for (seed in 1:3) {
    x <- with_seed(seed, stats::rt(25, 3))
    y <- with_seed(seed + 10, 0.5 + 2 * stats::rt(40, 3))
    data <- data.frame(y = c(x, y), group = factor(rep(1:2, c(25, 40))))
    expect_equal(yuen_p_by_hand(x, y, 0.2), WRS2::yuen(y ~ group, data = data, tr = 0.2)$p.value, tolerance = 1e-8)
    expect_equal(yuend_p_by_hand(x, y[1:25], 0.1), WRS2::yuend(x, y[1:25], tr = 0.1)$p.value, tolerance = 1e-8)
  }
  cases <- list(
    list(d = 0.5, sd_ratio = 1, shape = "heavy_tailed", trim = 0.2, n = 120, ratio = 1),
    list(d = 0.4, sd_ratio = 2, shape = "skewed", trim = 0.1, n = 150, ratio = 2)
  )
  for (case in cases) {
    spec <- yuen_validation_spec("independent_t", case$d, case$n, case$shape, case$trim, sd_ratio = case$sd_ratio, ratio = case$ratio)
    n1 <- round(case$n / (1 + case$ratio))
    reference <- yuen_by_hand(case$d, case$sd_ratio, case$shape, case$trim, n1, case$n - n1, 4000L, 62)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  }
  cases <- list(
    list(dz = 0.35, r = 0.5, shape = "heavy_tailed", trim = 0.2, n = 60),
    list(dz = 0.3, r = 0.8, shape = "skewed", trim = 0.1, n = 50)
  )
  for (case in cases) {
    spec <- yuen_validation_spec("paired_t", case$dz, case$n, case$shape, case$trim, r = case$r)
    reference <- yuend_by_hand(case$dz, case$r, case$shape, case$trim, case$n, 4000L, 63)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  }
})

test_that("Yuen: Type I error with heavy tails, unequal spreads and group sizes (simulation)", {
  skip_unless_full_validation()
  # No difference, symmetric heavy-tailed scores (so the trimmed means are
  # equal too); group 2 three times as spread and twice as large.
  expect_type1_near(engine_power(yuen_validation_spec("independent_t", 0, 150, "heavy_tailed", sd_ratio = 3, ratio = 2)), alpha = 0.05)
  expect_type1_near(engine_power(yuen_validation_spec("paired_t", 0, 60, "heavy_tailed", r = 0.5)), alpha = 0.05)
})

test_that("Yuen: with no trimming, the paired test is the paired t-test (analytic)", {
  skip_unless_full_validation()
  # trim = 0 leaves the means, the variances and the covariance as they
  # are, so yuend() gives the paired t-test, whose power with normal
  # scores is pwr's exact noncentral-t result.
  spec <- yuen_validation_spec("paired_t", 0.4, 50, "normal", trim = 0, r = 0.5)
  reference <- pwr::pwr.t.test(n = 50, d = 0.4, type = "paired")$power
  expect_power_near(engine_power(spec), reference)
})

test_that("Yuen: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power or sample-size example for
  # Yuen's trimmed-means test; source, section, page).
  d <- TODO_PUBLISHED_VALUE
  trim <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(d, trim, n, published_power)
  spec <- yuen_validation_spec("independent_t", d, n, "normal", trim)
  expect_power_near(engine_power(spec), published_power)
})
