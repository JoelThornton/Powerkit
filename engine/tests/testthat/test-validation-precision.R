# Validation: precision planning (design "precision"). Backends: MBESS
# (ss.aipe.smd(), ss.aipe.sm(), ci.smd(), ci.sm(), ss.aipe.reg.coef()) and
# presize (prec_cor(), prec_meandiff(), prec_or(), prec_icc(),
# prec_prop()). Build guide section 6:
#   1. published examples (placeholders for the maintainer)
#   2. simulated studies of the planned size, each interval computed here
#      from its formula without MBESS or presize: the median width is the
#      width planned for, and with assurance the share of intervals no
#      wider than the target is the assurance asked for
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

precision_validation_spec <- function(name, ...) {
  spec <- unclass(read_spec(system.file("specs", paste0(name, ".json"), package = "powerkit"), validate = FALSE))
  changes <- list(...)
  for (path in names(changes)) spec[[strsplit(path, ".", fixed = TRUE)[[1]]]] <- changes[[path]]
  spec
}

# The noncentral t interval for a standardised effect, by inverting
# pt() with uniroot(): `scale` turns the noncentrality into the effect
# (sqrt(n1 n2 / (n1 + n2)) for two groups, sqrt(n) for one). The limits
# lie well within 10 of t at these sample sizes. pt() warns that "full
# precision may not have been achieved" for a noncentral t at large df;
# its error is far below the 0.005 tolerance used here, so the warning is
# silenced.
nct_interval <- function(t, df, scale, level = 0.95) {
  tail <- (1 - level) / 2
  limit <- function(p) {
    stats::uniroot(function(ncp) suppressWarnings(stats::pt(t, df, ncp)) - p, c(t - 10, t + 10), tol = 1e-8)$root
  }
  c(limit(1 - tail), limit(tail)) / scale
}

simulated_d_widths <- function(n_per_group, d, nrep, seed) {
  set.seed(seed)
  vapply(seq_len(nrep), function(i) {
    x <- stats::rnorm(n_per_group)
    y <- stats::rnorm(n_per_group, d)
    t <- stats::t.test(y, x, var.equal = TRUE)$statistic
    diff(nct_interval(t, 2 * n_per_group - 2, sqrt(n_per_group / 2)))
  }, numeric(1))
}

# 1. Published examples ------------------------------------------------------------

test_that("Cohen's d, two groups: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer, for example the worked example
  #   of Kelley and Rausch's accuracy-in-parameter-estimation method for
  #   the standardised mean difference. Transcribe d, the confidence
  #   level, the full width, the assurance (NULL if none) and the sample
  #   size per group from the source, not from MBESS.
  d <- TODO_PUBLISHED_VALUE
  level <- TODO_PUBLISHED_VALUE
  width <- TODO_PUBLISHED_VALUE
  assurance <- TODO_PUBLISHED_VALUE
  published_n_per_group <- TODO_PUBLISHED_VALUE
  skip_if_todo(d, level, width, assurance, published_n_per_group)
  goal <- list(type = "precision", width = width)
  if (!is.null(assurance)) goal$assurance <- assurance
  spec <- precision_validation_spec("precision_two_groups", population.d = d, target_test.alpha = 1 - level, goal = goal)
  expect_equal(engine_function("run_spec")(spec)$precision$n, 2 * published_n_per_group)
})

test_that("a proportion: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (a precision-based sample size
  #   for a proportion with Wilson's interval). Transcribe the proportion,
  #   the confidence level, the full width and the sample size.
  p <- TODO_PUBLISHED_VALUE
  level <- TODO_PUBLISHED_VALUE
  width <- TODO_PUBLISHED_VALUE
  published_n <- TODO_PUBLISHED_VALUE
  skip_if_todo(p, level, width, published_n)
  spec <- precision_validation_spec("precision_proportion", population.p = p, target_test.alpha = 1 - level,
    goal = list(type = "precision", width = width))
  expect_equal(engine_function("run_spec")(spec)$precision$n, published_n)
})

test_that("a standardised regression coefficient: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer, for example Kelley and
  #   Maxwell's worked example of accuracy in parameter estimation for a
  #   regression coefficient. Transcribe the population R-squared, the
  #   predictor's R-squared with the others, the number of predictors, the
  #   coefficient, the confidence level, the full width and the sample size.
  r2 <- TODO_PUBLISHED_VALUE
  r2_predictor <- TODO_PUBLISHED_VALUE
  predictors <- TODO_PUBLISHED_VALUE
  b <- TODO_PUBLISHED_VALUE
  level <- TODO_PUBLISHED_VALUE
  width <- TODO_PUBLISHED_VALUE
  published_n <- TODO_PUBLISHED_VALUE
  skip_if_todo(r2, r2_predictor, predictors, b, level, width, published_n)
  spec <- precision_validation_spec("precision_regression_coefficient", population.r2 = r2,
    population.r2_predictor = r2_predictor, population.predictors = predictors, population.b = b,
    target_test.alpha = 1 - level, goal = list(type = "precision", width = width))
  expect_equal(engine_function("run_spec")(spec)$precision$n, published_n)
})

test_that("an ICC: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (a precision-based sample size
  #   for an ICC, such as Bonett's). Transcribe the ICC, the number of
  #   ratings of each subject, the confidence level, the full width and the
  #   number of subjects.
  icc <- TODO_PUBLISHED_VALUE
  raters <- TODO_PUBLISHED_VALUE
  level <- TODO_PUBLISHED_VALUE
  width <- TODO_PUBLISHED_VALUE
  published_n <- TODO_PUBLISHED_VALUE
  skip_if_todo(icc, raters, level, width, published_n)
  spec <- precision_validation_spec("precision_icc", population.icc = icc, population.raters = raters,
    target_test.alpha = 1 - level, goal = list(type = "precision", width = width))
  expect_equal(engine_function("run_spec")(spec)$precision$n, published_n)
})

# 2. Simulated intervals ------------------------------------------------------------

test_that("Cohen's d, two groups: the median simulated interval has the planned width", {
  skip_unless_full_validation()
  result <- engine_function("run_spec")(precision_validation_spec("precision_two_groups"))
  n <- result$precision$n / 2
  widths <- simulated_d_widths(n, 0.5, 4000, seed = 601)
  expect_equal(stats::median(widths), result$precision$width, tolerance = 0.005)
  expect_lte(result$precision$width, 0.4)
})

test_that("Cohen's d with assurance 0.8: about 80% of simulated intervals are no wider than the target", {
  skip_unless_full_validation()
  spec <- precision_validation_spec("precision_two_groups", goal = list(type = "precision", width = 0.4, assurance = 0.8))
  result <- engine_function("run_spec")(spec)
  widths <- simulated_d_widths(result$precision$n / 2, 0.5, 4000, seed = 602)
  share <- mean(widths <= 0.4)
  # 4,000 studies: Monte Carlo SE about 0.6 percentage points.
  expect_gt(share, 0.8 - 0.025)
  expect_lt(share, 0.8 + 0.05)
  # Without assurance, about half are wider.
  plain <- engine_function("run_spec")(precision_validation_spec("precision_two_groups"))
  expect_lt(mean(simulated_d_widths(plain$precision$n / 2, 0.5, 4000, seed = 603) <= 0.4), 0.65)
})

test_that("a standardised mean (one group): the median simulated interval has the planned width", {
  skip_unless_full_validation()
  spec <- precision_validation_spec("precision_two_groups")
  spec$template <- "one_group"
  spec$variables <- list(Y = list(type = "continuous", label = "Anxiety"))
  result <- engine_function("run_spec")(spec)
  n <- result$precision$n
  set.seed(604)
  widths <- vapply(seq_len(4000), function(i) {
    y <- stats::rnorm(n, 0.5)
    t <- stats::t.test(y)$statistic
    diff(nct_interval(t, n - 1, sqrt(n)))
  }, numeric(1))
  expect_equal(stats::median(widths), result$precision$width, tolerance = 0.005)
})

test_that("a correlation: the median simulated Fisher z interval has the planned width", {
  skip_unless_full_validation()
  result <- engine_function("run_spec")(precision_validation_spec("precision_correlation"))
  n <- result$precision$n
  set.seed(605)
  z <- stats::qnorm(0.975)
  widths <- vapply(seq_len(4000), function(i) {
    x <- stats::rnorm(n)
    y <- 0.3 * x + sqrt(1 - 0.09) * stats::rnorm(n)
    r <- stats::cor(x, y)
    diff(tanh(atanh(r) + c(-1, 1) * z / sqrt(n - 3)))
  }, numeric(1))
  expect_equal(stats::median(widths), result$precision$width, tolerance = 0.005)
})

test_that("a proportion, Wilson's interval: the median simulated interval has the planned width", {
  skip_unless_full_validation()
  result <- engine_function("run_spec")(precision_validation_spec("precision_proportion"))
  n <- result$precision$n
  z <- stats::qnorm(0.975)
  set.seed(606)
  phat <- stats::rbinom(10000, n, 0.3) / n
  widths <- 2 * z * sqrt(phat * (1 - phat) / n + z^2 / (4 * n^2)) / (1 + z^2 / n)
  expect_equal(stats::median(widths), result$precision$width, tolerance = 0.002)
})

# The estimates added on 1 November 2026: each interval computed here from
# its textbook formula, without presize or MBESS, for studies of the size
# planned. The odds ratio uses Woolf's logit interval, which presize's
# independence-smoothed interval (the default) adjusts only slightly at
# these group sizes; the ICC the exact F interval for the one-way ICC,
# which presize's width (Bonett's approximation) approximates.

test_that("a mean difference in raw units: the median simulated t interval has the planned width", {
  skip_unless_full_validation()
  result <- engine_function("run_spec")(precision_validation_spec("precision_mean_difference"))
  n <- result$precision$n / 2
  set.seed(607)
  widths <- vapply(seq_len(4000), function(i) {
    x <- stats::rnorm(n, 0, 12)
    y <- stats::rnorm(n, 5, 12)
    diff(stats::t.test(y, x, var.equal = TRUE)$conf.int)
  }, numeric(1))
  expect_equal(stats::median(widths), result$precision$width, tolerance = 0.01)
  expect_lte(result$precision$width, 6)
})

test_that("an odds ratio: the median simulated logit interval has the planned width", {
  skip_unless_full_validation()
  result <- engine_function("run_spec")(precision_validation_spec("precision_odds_ratio"))
  n <- result$precision$n / 2
  z <- stats::qnorm(0.975)
  set.seed(608)
  treated <- stats::rbinom(4000, n, 0.45)
  control <- stats::rbinom(4000, n, 0.3)
  log_or <- log(treated / (n - treated)) - log(control / (n - control))
  se <- sqrt(1 / treated + 1 / (n - treated) + 1 / control + 1 / (n - control))
  widths <- exp(log_or + z * se) - exp(log_or - z * se)
  expect_equal(stats::median(widths), result$precision$width, tolerance = 0.02)
  # The odds ratio is the second group's odds over the first's.
  expect_equal(result$precision$effect, (0.45 / 0.55) / (0.3 / 0.7))
})

test_that("an ICC: the median simulated F interval has the planned width", {
  skip_unless_full_validation()
  result <- engine_function("run_spec")(precision_validation_spec("precision_icc"))
  n <- result$precision$n
  k <- 3
  set.seed(609)
  widths <- vapply(seq_len(4000), function(i) {
    y <- stats::rnorm(n, 0, sqrt(0.7)) + matrix(stats::rnorm(n * k, 0, sqrt(0.3)), n, k)
    between <- k * stats::var(rowMeans(y))
    within <- sum((y - rowMeans(y))^2) / (n * (k - 1))
    f <- between / within
    f_lower <- f / stats::qf(0.975, n - 1, n * (k - 1))
    f_upper <- f * stats::qf(0.975, n * (k - 1), n - 1)
    (f_upper - 1) / (f_upper + k - 1) - (f_lower - 1) / (f_lower + k - 1)
  }, numeric(1))
  expect_equal(stats::median(widths), result$precision$width, tolerance = 0.02)
})

test_that("a standardised regression coefficient: the median simulated interval has the planned width", {
  skip_unless_full_validation()
  result <- engine_function("run_spec")(precision_validation_spec("precision_regression_coefficient"))
  n <- result$precision$n
  # Four standardised predictors: X1 shares 20% of its variance with the
  # other three (their scaled sum); Y = 0.25 X1 + g X2 + error, with g
  # chosen so that R-squared is 0.3.
  shared <- sqrt(0.2) / sqrt(3)
  g <- (-2 * 0.25 * shared + sqrt((2 * 0.25 * shared)^2 + 4 * (0.3 - 0.25^2))) / 2
  set.seed(610)
  widths <- vapply(seq_len(4000), function(i) {
    others <- matrix(stats::rnorm(n * 3), n)
    x1 <- sqrt(0.2) * rowSums(others) / sqrt(3) + sqrt(0.8) * stats::rnorm(n)
    y <- 0.25 * x1 + g * others[, 1] + sqrt(0.7) * stats::rnorm(n)
    d <- as.data.frame(scale(cbind(y, x1, others)))
    diff(stats::confint(stats::lm(y ~ ., data = d))["x1", ])
  }, numeric(1))
  expect_equal(stats::median(widths), result$precision$width, tolerance = 0.01)
})
