# Validation: reliability and agreement.
# Backends: ICC.Sample.Size's calculateIccPower() (the ICC), Bonett and
# Wright's test with statpsych's size.test.cronbach() (Cronbach's alpha),
# kappaSize's PowerBinary() and Power3Cats() (kappa).
#   1. analytic agreement: an independent simulation of each design and
#      its test, written without the packages: the ICC by the exact F test
#      of a one-way random-effects ANOVA; Cronbach's alpha by the test of
#      ln(1 - alpha) with variance 2r / ((r - 1)(n - 2)), the test the
#      formula assumes; kappa for two raters by Donner and Eliasziw's
#      goodness-of-fit test of the three agreement patterns against kappa0
#      (the prevalence estimated, 1 df), the test kappaSize's formula
#      assumes
#   2. published examples: the packages' own help examples are checked in
#      test-backend-reliability.R; published worked examples are
#      placeholders, for the maintainer
#   3. Type I error: the formulas' power at the null value
# The formulas are large-sample approximations, so the simulation is
# allowed 0.03 beyond its Monte Carlo error (docs/decisions.md, 2 November
# 2026).
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

reliability_reps <- 4000L

reliability_validation_spec <- function(template, population, n, alternative = NULL, y = NULL) {
  validation_spec(
    design = "reliability",
    template = template,
    variables = list(Y = y %||% validation_variable("continuous", "Ratings")),
    population = population,
    target_test = c(
      switch(template,
        icc = list(effect = "icc", method = "icc_test"),
        cronbach_alpha = list(effect = "cronbach_alpha", method = "bonett_wright"),
        kappa = list(effect = "kappa", method = "kappa_chi_square")
      ),
      list(alpha = 0.05),
      if (!is.null(alternative)) list(alternative = alternative)
    ),
    seed = 6901,
    n = n
  )
}

estimate_from_hits <- function(hits) {
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / length(hits)))
}

# One-way random-effects ANOVA: F / F0 against the central F.
icc_by_hand <- function(icc, icc_null, k, n, one_sided, nrep, seed) {
  f0 <- (1 + (k - 1) * icc_null) / (1 - icc_null)
  df <- c(n - 1, n * (k - 1))
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    ratings <- matrix(stats::rnorm(n, sd = sqrt(icc)), n, k) + matrix(stats::rnorm(n * k, sd = sqrt(1 - icc)), n, k)
    means <- rowMeans(ratings)
    msb <- k * sum((means - mean(ratings))^2) / df[1]
    msw <- sum((ratings - means)^2) / df[2]
    ratio <- (msb / msw) / f0
    if (one_sided) {
      ratio > stats::qf(0.95, df[1], df[2])
    } else {
      ratio > stats::qf(0.975, df[1], df[2]) || ratio < stats::qf(0.025, df[1], df[2])
    }
  }, logical(1)))
  estimate_from_hits(hits)
}

# Parallel items with the item reliability that gives alpha.
alpha_by_hand <- function(alpha, alpha_null, r, n, one_sided, nrep, seed) {
  item_rel <- alpha / (r - alpha * (r - 1))
  se <- sqrt(2 * r / ((r - 1) * (n - 2)))
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    items <- matrix(stats::rnorm(n, sd = sqrt(item_rel)), n, r) + matrix(stats::rnorm(n * r, sd = sqrt(1 - item_rel)), n, r)
    a_hat <- r / (r - 1) * (1 - sum(apply(items, 2, stats::var)) / stats::var(rowSums(items)))
    z <- (log(1 - alpha_null) - log(1 - a_hat)) / se
    if (one_sided) z > stats::qnorm(0.95) else abs(z) > stats::qnorm(0.975)
  }, logical(1)))
  estimate_from_hits(hits)
}

# Two raters, a yes/no rating with prevalence p: the probabilities of both
# "no", one of each and both "yes" under kappa (the common correlation
# model); the goodness-of-fit test of the counts against kappa0's
# probabilities at the estimated prevalence, 1 df.
kappa_by_hand <- function(kappa, kappa_null, p, n, nrep, seed) {
  probs_at <- function(k, p) c((1 - p)^2 + k * p * (1 - p), 2 * (1 - k) * p * (1 - p), p^2 + k * p * (1 - p))
  probs <- function(k) probs_at(k, p)
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    counts <- stats::rmultinom(1, n, probs(kappa))[, 1]
    # The prevalence is estimated from the ratings, which leaves 1 df.
    p_hat <- (counts[2] + 2 * counts[3]) / (2 * n)
    expected <- n * probs_at(kappa_null, p_hat)
    sum((counts - expected)^2 / expected) > stats::qchisq(0.95, 1)
  }, logical(1)))
  estimate_from_hits(hits)
}

test_that("ICC: calculateIccPower() agrees with the simulated F test (analytic)", {
  skip_unless_full_validation()
  cases <- list(
    list(icc = 0.8, null = 0.6, k = 3, n = 27, one_sided = TRUE),
    list(icc = 0.7, null = 0.5, k = 2, n = 80, one_sided = FALSE)
  )
  for (case in cases) {
    spec <- reliability_validation_spec("icc", list(metric = "icc", icc = case$icc, icc_null = case$null, raters = case$k),
      case$n, alternative = if (case$one_sided) "greater" else NULL)
    reference <- icc_by_hand(case$icc, case$null, case$k, case$n, case$one_sided, reliability_reps, 97)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0.03)
  }
})

test_that("Cronbach's alpha: Bonett and Wright's test agrees with simulated scales (analytic)", {
  skip_unless_full_validation()
  cases <- list(
    list(a = 0.8, null = 0.7, r = 5, n = 139, one_sided = FALSE),
    list(a = 0.85, null = 0.75, r = 10, n = 80, one_sided = TRUE)
  )
  for (case in cases) {
    spec <- reliability_validation_spec("cronbach_alpha",
      list(metric = "cronbach_alpha", reliability = case$a, reliability_null = case$null, items = case$r),
      case$n, alternative = if (case$one_sided) "greater" else NULL)
    reference <- alpha_by_hand(case$a, case$null, case$r, case$n, case$one_sided, reliability_reps, 96)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0.03)
  }
})

test_that("kappa: kappaSize agrees with the simulated goodness-of-fit test (analytic)", {
  skip_unless_full_validation()
  y <- validation_variable("binary", "Diagnosis", levels = list("No", "Yes"))
  for (case in list(list(k = 0.6, null = 0.4, p = 0.3, n = 191), list(k = 0.5, null = 0.7, p = 0.5, n = 120))) {
    spec <- reliability_validation_spec("kappa",
      list(metric = "kappa", kappa = case$k, kappa_null = case$null, proportions = list(1 - case$p, case$p), raters = 2),
      case$n, y = y)
    reference <- kappa_by_hand(case$k, case$null, case$p, case$n, reliability_reps, 95)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0.03)
  }
})

test_that("ICC: power matches a published worked example (published)", {
  skip_unless_full_validation()
  # Source: Walter, S. D., Eliasziw, M., & Donner, A. (1998). Sample size
  # and optimal designs for reliability studies. Statistics in Medicine,
  # 17, 101-110 (maintainer: a table entry; page).
  icc <- TODO_PUBLISHED_VALUE # rho1
  icc_null <- TODO_PUBLISHED_VALUE # rho0
  raters <- TODO_PUBLISHED_VALUE # n (observations per subject)
  alpha <- TODO_PUBLISHED_VALUE # significance level (one-sided)
  power <- TODO_PUBLISHED_VALUE # power
  published_n <- TODO_PUBLISHED_VALUE # number of subjects as printed
  skip_if_todo(icc, icc_null, raters, alpha, power, published_n)

  spec <- reliability_validation_spec("icc", list(metric = "icc", icc = icc, icc_null = icc_null, raters = raters), NULL,
    alternative = "greater")
  spec$target_test$alpha <- alpha
  spec$goal <- list(type = "sample_size", power = power)
  expect_n_near(engine_function("run_spec")(spec)$n_required, published_n)
})

test_that("Cronbach's alpha: sample size matches Bonett and Wright's worked example (published)", {
  skip_unless_full_validation()
  # Source: Bonett, D. G., & Wright, T. A. (2015). Cronbach's alpha
  # reliability: Interval estimation, hypothesis testing, and sample size
  # planning. Journal of Organizational Behavior, 36, 3-15 (maintainer:
  # the sample-size example for a hypothesis test; page).
  reliability <- TODO_PUBLISHED_VALUE # planning value of alpha
  reliability_null <- TODO_PUBLISHED_VALUE # null value
  items <- TODO_PUBLISHED_VALUE # number of items
  alpha <- TODO_PUBLISHED_VALUE # significance level (two-sided)
  power <- TODO_PUBLISHED_VALUE # power
  published_n <- TODO_PUBLISHED_VALUE # sample size as printed
  skip_if_todo(reliability, reliability_null, items, alpha, power, published_n)

  spec <- reliability_validation_spec("cronbach_alpha",
    list(metric = "cronbach_alpha", reliability = reliability, reliability_null = reliability_null, items = items), NULL)
  spec$target_test$alpha <- alpha
  spec$goal <- list(type = "sample_size", power = power)
  expect_n_near(engine_function("run_spec")(spec)$n_required, published_n)
})

test_that("reliability formulas' rejection rate at the null value (Type I error)", {
  skip_unless_full_validation()
  # The spec checks refuse a sample size at the null value, but power at a
  # given n runs. The ICC and alpha formulas count one tail, so give alpha
  # (one-sided) or alpha / 2 (two-sided); kappaSize's test gives alpha.
  icc <- reliability_validation_spec("icc", list(metric = "icc", icc = 0.6, icc_null = 0.6, raters = 3), 50, alternative = "greater")
  expect_equal(engine_power(icc)$power, 0.05, tolerance = 1e-12)
  a <- reliability_validation_spec("cronbach_alpha", list(metric = "cronbach_alpha", reliability = 0.7, reliability_null = 0.7, items = 5), 50)
  expect_equal(engine_power(a)$power, 0.025, tolerance = 1e-12)
  y <- validation_variable("binary", "Diagnosis", levels = list("No", "Yes"))
  k <- reliability_validation_spec("kappa", list(metric = "kappa", kappa = 0.4, kappa_null = 0.4, proportions = list(0.7, 0.3), raters = 2), 100, y = y)
  expect_equal(engine_power(k)$power, 0.05, tolerance = 1e-6)
})
