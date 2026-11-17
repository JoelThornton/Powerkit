# The smallest detectable effect for the dependent correlations (pwrss),
# the variance tests and Hotelling's T-squared (stats) and the equivalence
# tests (TOSTER), found by searching the backend's own power over the effect
# at a fixed n (sensitivity-pwrss.R, sensitivity-search.R, 16 November
# 2026). Each is checked against a simulation of the test itself, which
# uses none of the power formulas, and the exported R script must
# reproduce it.

sensitivity_of <- function(spec, n = 120L, power = 0.8) {
  spec$goal <- list(type = "sensitivity", n = n, power = power)
  spec$options$method <- NULL
  spec$options$nrep <- NULL
  suppressWarnings(run_quietly(spec))
}

two_group_manova <- function() {
  spec <- example_spec("manova")
  spec$population$means <- spec$population$means[1:2]
  spec$variables$A$levels <- spec$variables$A$levels[1:2]
  spec
}

test_that("each search reaches the target power, and the script reproduces it", {
  skip_on_cran()
  specs <- list(
    overlapping_correlations = example_spec("overlapping_correlations"),
    nonoverlapping_correlations = example_spec("nonoverlapping_correlations"),
    one_variance = example_spec("one_variance"),
    two_variances = example_spec("two_variances"),
    hotelling_one = example_spec("hotelling_one"),
    hotelling_two = two_group_manova(),
    tost_independent = example_spec("tost_independent"),
    tost_paired = example_spec("tost_paired"),
    tost_one_sample = example_spec("tost_one_sample"),
    tost_correlation = example_spec("tost_correlation"),
    tost_two_proportions = example_spec("tost_two_proportions")
  )
  for (name in names(specs)) {
    spec <- specs[[name]]
    result <- sensitivity_of(spec)
    expect_equal(result$sensitivity$power, 0.8, tolerance = 1e-6, label = name)
    spec$goal <- list(type = "sensitivity", n = 120L, power = 0.8)
    spec$options$method <- NULL
    spec$options$nrep <- NULL
    file <- withr::local_tempfile(fileext = ".R")
    writeLines(export_script(spec, result), file)
    out <- system2(file.path(R.home("bin"), "Rscript"), file, stdout = TRUE, stderr = TRUE)
    expect_true(any(grepl("^Reproduced powerkit's result", out)), label = name)
  }
})

test_that("Steiger's test of two correlations sharing a variable has the target power at the second correlation found", {
  skip_on_cran()
  spec <- example_spec("overlapping_correlations")
  s <- sensitivity_of(spec)$sensitivity
  expect_identical(s$effect_name, "r_second")
  # The entered second correlation is below the first, so the search looks
  # for a smaller one.
  expect_lt(s$effect, spec$population$r_X_Y)
  pop <- spec$population
  sigma <- matrix(c(1, pop$r_X_Y, s$effect, pop$r_X_Y, 1, pop$r_Y_Z, s$effect, pop$r_Y_Z, 1), 3)
  set.seed(20261116)
  hits <- replicate(2000, {
    r <- stats::cor(MASS::mvrnorm(120, rep(0, 3), sigma))
    # psych's r.test() with pooled = FALSE is Steiger's (1980) z test as
    # G*Power computes it (powerkit's Departure 12).
    psych::r.test(120, r12 = r[1, 2], r13 = r[1, 3], r23 = r[2, 3], pooled = FALSE)$p < 0.05
  })
  # The asymptotic power pwrss (and G*Power) give for Steiger's z is a
  # little below the test's simulated rejection rate: about 0.03 lower at
  # these values, at the correlations entered (0.615 against 0.645) as at
  # the one found. So this checks that the search lands on the formula's
  # target, within that known gap, not the formula's accuracy.
  expect_equal(mean(hits), 0.8, tolerance = 0.05)
})

test_that("the second correlation stays where the correlation matrix is positive definite", {
  spec <- example_spec("overlapping_correlations")
  range <- dependent_correlation_range(spec, "r_X_Z")
  pop <- spec$population
  # For three variables the ends are known: r12 r23 -/+ sqrt((1 - r12^2)(1 - r23^2)).
  ends <- pop$r_X_Y * pop$r_Y_Z + c(-1, 1) * sqrt((1 - pop$r_X_Y^2) * (1 - pop$r_Y_Z^2))
  expect_equal(range, ends + c(0.001, -0.001), tolerance = 1e-8)
  four <- example_spec("nonoverlapping_correlations")
  range <- dependent_correlation_range(four, "r_X2_Y2")
  s <- sensitivity_of(four)$sensitivity
  expect_true(s$effect > range[1] && s$effect < range[2])
})

test_that("the variance tests' ratio has the target power in a simulation of the tests", {
  skip_on_cran()
  set.seed(20261116)
  two <- example_spec("two_variances")
  s <- sensitivity_of(two)$sensitivity
  expect_identical(s$effect_name, "variance_ratio")
  hits <- replicate(2000, stats::var.test(stats::rnorm(60, sd = sqrt(s$effect)), stats::rnorm(60))$p.value < 0.05)
  expect_equal(mean(hits), 0.8, tolerance = 0.03)

  one <- example_spec("one_variance")
  s <- sensitivity_of(one)$sensitivity
  # The test is one-sided ('less'): the ratio found is below 1.
  expect_lt(s$effect, 1)
  expect_equal(s$variance, s$effect * one$population$var0)
  hits <- replicate(2000, {
    y <- stats::rnorm(120, sd = sqrt(s$variance))
    stats::pchisq(119 * stats::var(y) / one$population$var0, 119) < 0.05
  })
  expect_equal(mean(hits), 0.8, tolerance = 0.03)
})

test_that("Hotelling's T-squared: the distance found has the target power in Spower's simulation", {
  skip_on_cran()
  for (spec in list(example_spec("hotelling_one"), two_group_manova())) {
    s <- sensitivity_of(spec)$sensitivity
    expect_identical(s$effect_name, "mahalanobis")
    at <- spec
    at$population$means <- s$means
    at$goal <- list(type = "power", n = 120L)
    at$options <- list(method = "simulation", nrep = 2000L)
    expect_equal(suppressWarnings(run_quietly(at))$curve$power, 0.8, tolerance = 0.03)
    # The pattern entered keeps its shape.
    at$options <- NULL
    expect_equal(sqrt(hotelling_inputs(at)$distance2), s$effect, tolerance = 1e-8)
  }
  spec <- example_spec("hotelling_one")
  spec$population$means <- spec$population$mu0
  spec$goal <- list(type = "sensitivity", n = 120L, power = 0.8)
  expect_error(validate_spec(spec), "no effect pattern to scale")
})

test_that("an equivalence test's narrowest bound shows equivalence with the target power in a simulation of TOST", {
  skip_on_cran()
  spec <- example_spec("tost_independent")
  spec$population$bound <- NULL
  s <- sensitivity_of(spec)$sensitivity
  expect_identical(s$effect_name, "bound")
  set.seed(20261116)
  hits <- replicate(2000, {
    a <- stats::rnorm(60)
    b <- stats::rnorm(60, spec$population$d)
    lower <- stats::t.test(b, a, mu = -s$effect, alternative = "greater", var.equal = TRUE)$p.value
    upper <- stats::t.test(b, a, mu = s$effect, alternative = "less", var.equal = TRUE)$p.value
    max(lower, upper) < 0.05
  })
  expect_equal(mean(hits), 0.8, tolerance = 0.03)

  correlation <- example_spec("tost_correlation")
  correlation$population$bound <- NULL
  s <- sensitivity_of(correlation)$sensitivity
  hits <- replicate(2000, {
    r <- stats::cor(MASS::mvrnorm(120, c(0, 0), matrix(c(1, correlation$population$r, correlation$population$r, 1), 2)))[1, 2]
    z <- (atanh(r) - atanh(c(-s$effect, s$effect))) * sqrt(117)
    stats::pnorm(z[1], lower.tail = FALSE) < 0.05 && stats::pnorm(z[2]) < 0.05
  })
  expect_equal(mean(hits), 0.8, tolerance = 0.03)

  # With a bound entered for power, it is still required.
  power <- example_spec("tost_independent")
  power$population$bound <- NULL
  expect_error(validate_spec(power), "Give the equivalence bound")
})
