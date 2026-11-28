# ANCOVA with covariates fixed by the design (target_test > covariate_model
# "fixed", 17 November 2026): the noncentrality N gamma^2, as G*Power takes
# it, through pwrss's power.f.ancova(). Shieh's method for measured
# covariates stays the default.

ancova_fixed_spec <- function(template = "anova_oneway_ancova", effect = "main_effect_A", n = 90L) {
  spec <- example_spec(template)
  spec$target_test$effect <- effect
  spec$target_test$covariate_model <- "fixed"
  spec$goal <- list(type = "power", n = n)
  spec
}

test_that("one factor with fixed covariates is pwrss's own Keppel method", {
  for (r2 in c(0, 0.36, 0.6)) for (n in c(45L, 90L, 150L)) {
    spec <- ancova_fixed_spec(n = n)
    spec$population$r2_covariates <- r2
    if (r2 == 0) spec$population$covariates <- 1L
    result <- run_quietly(spec)
    expect_identical(result$provenance$backend_function, "pwrss::power.f.ancova")
    expect_true(all(result$check_run$ok))
    k <- length(spec$variables$A$levels)
    keppel <- pwrss::power.f.ancova.keppel(
      mu.vector = as.numeric(unlist(spec$population$means)), sd.vector = rep(spec$population$sd, k),
      n.vector = rep(n / k, k), r.squared = r2, k.covariates = spec$population$covariates,
      verbose = 0, ceil.n = FALSE
    )$power
    expect_equal(result$curve$power, keppel, tolerance = 1e-10, label = paste(r2, n))
  }
})

test_that("two factors with fixed covariates use each effect's sum of squares of the adjusted cell means", {
  for (effect in c("main_effect_A", "main_effect_B", "interaction")) {
    spec <- ancova_fixed_spec("anova_factorial_ancova", effect, n = 120L)
    pop <- spec$population
    mu <- do.call(rbind, lapply(pop$means, function(row) as.numeric(unlist(row))))
    k <- nrow(mu)
    m <- ncol(mu)
    grand <- mean(mu)
    pattern <- switch(effect,
      main_effect_A = rep(rowMeans(mu) - grand, m),
      main_effect_B = rep(colMeans(mu) - grand, each = k),
      interaction = c(mu - outer(rowMeans(mu), colMeans(mu), "+") + grand))
    df1 <- switch(effect, main_effect_A = k - 1, main_effect_B = m - 1, interaction = (k - 1) * (m - 1))
    gamma2 <- sum(pattern^2) / (k * m * pop$sd^2 * (1 - pop$r2_covariates))
    df2 <- 120 - k * m - pop$covariates
    expected <- stats::pf(stats::qf(0.95, df1, df2), df1, df2, ncp = 120 * gamma2, lower.tail = FALSE)
    result <- run_quietly(spec)
    expect_true(all(result$check_run$ok), label = effect)
    expect_equal(result$curve$power, expected, tolerance = 1e-10, label = effect)
  }
})

test_that("fixed covariates give a little more power than Shieh's method, which stays the default", {
  fixed <- run_quietly(ancova_fixed_spec())$curve$power
  random <- ancova_fixed_spec()
  random$target_test$covariate_model <- NULL
  shieh <- run_quietly(random)
  expect_identical(shieh$provenance$backend_function, "pwrss::power.f.ancova.shieh")
  expect_gt(fixed, shieh$curve$power)
  expect_lt(fixed - shieh$curve$power, 0.02)
})

test_that("the exported scripts reproduce the power with fixed covariates", {
  for (template in c("anova_oneway_ancova", "anova_factorial_ancova")) {
    spec <- ancova_fixed_spec(template)
    expect_script_reproduces_power(spec, run_quietly(spec))
  }
})

test_that("the smallest detectable effect works with fixed covariates", {
  spec <- ancova_fixed_spec()
  spec$goal <- list(type = "sensitivity", n = 90L, power = 0.8)
  result <- run_quietly(spec)
  expect_true(is.finite(result$sensitivity$effect))
})

test_that("the covariate model is refused where it can't apply, in plain English", {
  bayes <- ancova_fixed_spec()
  bayes$target_test$method <- "bayes_factor"
  bayes$target_test$evidence_threshold <- 10
  bayes$target_test$alpha <- NULL
  expect_spec_problem(bayes, "The Bayes factor ANCOVA is simulated with covariates measured on each person")
  eta <- ancova_fixed_spec()
  eta$population <- list(metric = "eta_squared", eta_squared = 0.06, covariates = 1L)
  eta$target_test$covariate_model <- "random"
  expect_spec_problem(eta, "planned with the covariates fixed: ")
  eta$target_test$covariate_model <- "fixed"
  expect_valid_spec(eta)
  other <- example_spec("anova_oneway_between")
  other$target_test$covariate_model <- "fixed"
  expect_spec_problem(other, "describes an ANCOVA's covariates")
})
