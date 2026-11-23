# The smallest detectable effect for the formula tests pwrss computes
# (sensitivity-pwrss.R, 16 November 2026): pwrss's own power searched over
# the effect at a fixed n. Each is checked against a calculation that does
# not use pwrss (pwr, WebPower, a test's distribution from stats, or a
# simulation), and the exported R script must reproduce it.

sensitivity_of <- function(spec, n = 120L, power = 0.8) {
  spec$goal <- list(type = "sensitivity", n = n, power = power)
  spec$options$method <- NULL
  suppressWarnings(run_quietly(spec))
}

# The spec as run_spec() saw it, for export_script().
within_goal <- function(spec, n = 120L, power = 0.8) {
  spec$goal <- list(type = "sensitivity", n = n, power = power)
  spec$options$method <- NULL
  spec
}

test_that("each formula test's smallest effect reaches the target power, and the script reproduces it", {
  skip_on_cran()
  specs <- list(
    regression_r2_zero = example_spec("regression_r2_zero"),
    regression_r2_increase = example_spec("regression_r2_increase"),
    logistic_regression = example_spec("logistic_regression"),
    poisson_regression = example_spec("poisson_regression"),
    one_proportion = example_spec("one_proportion"),
    mcnemar = example_spec("mcnemar"),
    two_correlations = example_spec("two_correlations"),
    chi_square_gof = example_spec("chi_square_gof"),
    anova_oneway_contrast = example_spec("anova_oneway_contrast"),
    anova_oneway_ancova = example_spec("anova_oneway_ancova"),
    anova_factorial_ancova = example_spec("anova_factorial_ancova")
  )
  for (name in names(specs)) {
    spec <- specs[[name]]
    result <- sensitivity_of(spec)
    expect_equal(result$sensitivity$power, 0.8, tolerance = 1e-6, label = name)
    script <- export_script(within_goal(spec), result)
    file <- withr::local_tempfile(fileext = ".R")
    writeLines(script, file)
    out <- system2(file.path(R.home("bin"), "Rscript"), file, stdout = TRUE, stderr = TRUE)
    expect_true(any(grepl("^Reproduced powerkit's result", out)), label = name)
  }
})

# G*Power's F test of a regression coefficient or R-squared increase:
# noncentrality f^2 x N, with 'tested' and N - predictors - 1 df (the G*Power
# manual, "Linear multiple regression: Fixed model, R-squared increase").
# pwr's pwr.f2.test() takes f^2 x (u + v + 1), which equals f^2 x N only
# when every predictor is tested, so it is not the reference here.
gpower_f_power <- function(f2, n, tested, predictors) {
  df2 <- n - predictors - 1
  crit <- stats::qf(0.95, tested, df2)
  stats::pf(crit, tested, df2, ncp = f2 * n, lower.tail = FALSE)
}

test_that("one coefficient's smallest partial R-squared gives G*Power's F test its target power", {
  spec <- example_spec("regression_coefficient")
  spec$target_test$method <- "f_test"
  spec$target_test$predictor_model <- "fixed" # G*Power's fixed model (Departure 39)
  spec$population$variance_ratio <- NULL
  s <- sensitivity_of(spec, n = 100L)$sensitivity
  expect_equal(gpower_f_power(s$effect / (1 - s$effect), 100, 1, spec$population$predictors_total), 0.8, tolerance = 1e-6)
})

test_that("an ANOVA given by partial eta-squared finds Cohen's f as pwr does", {
  spec <- example_spec("anova_oneway_between")
  spec$population <- list(metric = "eta_squared", eta_squared = 0.06)
  s <- sensitivity_of(spec)$sensitivity
  expect_equal(s$effect_name, "eta_squared")
  f <- pwr::pwr.anova.test(k = 3, n = 40, power = 0.8, sig.level = 0.05)$f
  expect_equal(sqrt(s$effect / (1 - s$effect)), f, tolerance = 1e-3)
})

test_that("an interaction given by its R-squared change gives G*Power's F test its target power", {
  spec <- example_spec("regression_interaction")
  spec$population <- list(metric = "r2_change", r2_change = 0.02, r2_main = 0.1)
  for (role in c("X", "W", "Y")) spec$variables[[role]]$reliability <- NULL
  spec$reliability <- NULL
  s <- sensitivity_of(spec)$sensitivity
  expect_equal(gpower_f_power(s$effect / (1 - 0.1 - s$effect), 120, 1, 3), 0.8, tolerance = 1e-6)
})

test_that("goodness of fit finds Cohen's w as pwr does, whatever proportions were entered", {
  s <- sensitivity_of(example_spec("chi_square_gof"))$sensitivity
  expect_equal(s$effect_name, "w")
  expect_equal(s$effect, pwr::pwr.chisq.test(N = 120, df = 2, power = 0.8, sig.level = 0.05)$w, tolerance = 1e-4)
})

test_that("one proportion's smallest detectable proportion matches the exact binomial test's power from stats", {
  spec <- example_spec("one_proportion")
  s <- sensitivity_of(spec, n = 80L)$sensitivity
  expect_gt(s$effect, spec$population$p0)
  # The two-sided exact test's rejection region at p0 = 0.5, as
  # binom.test() would reject (each tail at most alpha / 2).
  n <- 80
  p0 <- spec$population$p0
  k <- 0:n
  lower <- k[stats::pbinom(k, n, p0) <= 0.025]
  upper <- k[stats::pbinom(k - 1, n, p0, lower.tail = FALSE) <= 0.025]
  power <- sum(stats::dbinom(c(lower, upper), n, s$effect))
  expect_equal(power, 0.8, tolerance = 1e-3)
  # No proportion is needed: empty means the fixed value, and the search
  # looks for an increase.
  spec$population$p <- spec$population$p0
  expect_equal(sensitivity_of(spec, n = 80L)$sensitivity$effect, s$effect, tolerance = 1e-8)
})

test_that("two correlations: group 2's correlation matches Fisher's z test's power from its normal approximation", {
  spec <- example_spec("two_correlations")
  s <- sensitivity_of(spec)$sensitivity
  expect_equal(s$effect_name, "r_group2")
  q <- abs(atanh(s$effect) - atanh(spec$population$r1)) / sqrt(2 / (60 - 3))
  z <- stats::qnorm(0.975)
  expect_equal(stats::pnorm(q - z) + stats::pnorm(-q - z), 0.8, tolerance = 1e-3)
})

test_that("a planned contrast's smallest value matches the contrast t test's noncentral t from stats", {
  spec <- example_spec("anova_oneway_contrast")
  s <- sensitivity_of(spec)$sensitivity
  w <- as.numeric(unlist(spec$target_test$weights))
  k <- length(w)
  ncp <- s$effect / (spec$population$sd * sqrt(sum(w^2 / (120 / k))))
  df <- 120 - k
  crit <- stats::qt(0.975, df)
  power <- stats::pt(crit, df, ncp, lower.tail = FALSE) + stats::pt(-crit, df, ncp)
  expect_equal(power, 0.8, tolerance = 1e-4)
  # The pattern entered keeps its shape.
  mu <- as.numeric(unlist(spec$population$means))
  expect_equal(s$means - mean(s$means), s$scale * (mu - mean(mu)), tolerance = 1e-8)
})

test_that("the ANCOVA keeps the pattern of adjusted means and power at it reaches the target", {
  spec <- example_spec("anova_oneway_ancova")
  s <- sensitivity_of(spec)$sensitivity
  mu <- as.numeric(unlist(spec$population$means))
  expect_equal(s$means - mean(s$means), s$scale * (mu - mean(mu)), tolerance = 1e-8)
  at <- spec
  at$population$means <- as.list(s$means)
  at$goal <- list(type = "power", n = 120L)
  expect_equal(suppressWarnings(run_quietly(at))$curve$power, 0.8, tolerance = 1e-6)
  # A zero pattern has nothing to scale.
  spec$population$means <- as.list(rep(18, 3))
  spec$goal <- list(type = "sensitivity", n = 120L, power = 0.8)
  expect_error(validate_spec(spec), "no effect pattern to scale")
})

test_that("logistic and Poisson regression find the ratio, checked against WebPower and a simulation", {
  skip_on_cran()
  spec <- example_spec("logistic_regression")
  s <- sensitivity_of(spec)$sensitivity
  expect_equal(s$effect_name, "odds_ratio")
  expect_gt(s$effect, 1)
  # The odds ratio needs no estimate: 1 (no effect) searches for an increase.
  spec$population$odds_ratio <- 1
  expect_equal(sensitivity_of(spec)$sensitivity$effect, s$effect, tolerance = 1e-8)
  p1 <- stats::plogis(stats::qlogis(0.3) + log(s$effect))
  # WebPower's wp.logistic() is Demidenko's (2007) method without the
  # variance correction pwrss applies by default, so it is a little lower.
  webpower <- WebPower::wp.logistic(n = 120, p0 = 0.3, p1 = p1, alpha = 0.05, family = "normal")$power
  expect_equal(webpower, 0.8, tolerance = 0.04)
  set.seed(20261116)
  hits <- replicate(1000, {
    x <- stats::rnorm(120)
    y <- stats::rbinom(120, 1, stats::plogis(stats::qlogis(0.3) + log(s$effect) * x))
    summary(stats::glm(y ~ x, family = stats::binomial))$coefficients[2, 4] < 0.05
  })
  expect_equal(mean(hits), 0.8, tolerance = 0.05)

  count <- example_spec("poisson_regression")
  r <- sensitivity_of(count)$sensitivity
  expect_equal(r$effect_name, "rate_ratio")
  # The entered rate ratio is below 1, so the search looks for a decrease.
  expect_lt(r$effect, 1)
  webpower <- WebPower::wp.poisson(n = 120, exp0 = 3, exp1 = r$effect, alpha = 0.05, family = "normal")$power
  expect_equal(webpower, 0.8, tolerance = 0.01)
})

test_that("McNemar's smallest change matches the exact test's power summed over the number who change", {
  spec <- example_spec("mcnemar")
  s <- sensitivity_of(spec, n = 100L)$sensitivity
  first <- spec$population$p_first_only
  second <- s$effect
  # The exact McNemar test is a binomial test of the changes, conditional
  # on how many change; its power at n sums over that number.
  power <- sum(vapply(0:100, function(d) {
    if (d == 0) return(0)
    k <- 0:d
    lower <- k[stats::pbinom(k, d, 0.5) <= 0.025]
    upper <- k[stats::pbinom(k - 1, d, 0.5, lower.tail = FALSE) <= 0.025]
    stats::dbinom(d, 100, first + second) * sum(stats::dbinom(c(lower, upper), d, second / (first + second)))
  }, numeric(1)))
  expect_equal(power, 0.8, tolerance = 0.01)
})
