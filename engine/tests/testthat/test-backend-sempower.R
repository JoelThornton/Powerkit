# Structural equation model fit by formula (semPower's semPower.postHoc()
# with an RMSEA): the translation is checked against semPower called
# directly with the arguments written out by hand, against the noncentral
# chi-square written out in base R, and the degrees of freedom against
# lavaan's own count for the same model.

sem_spec <- function(goal, ...) {
  spec <- example_spec("sem_model_fit")
  spec$options <- list(seed = 7)
  spec$goal <- goal
  changes <- list(...)
  for (name in names(changes)) spec$population[[name]] <- changes[[name]]
  spec
}

# A model given by its df rather than by its items and factors.
sem_df_spec <- function(goal, df, rmsea = 0.05) {
  spec <- sem_spec(goal, rmsea = rmsea)
  spec$population$indicators <- NULL
  spec$population$factors <- NULL
  spec$population$df <- df
  spec
}

test_that("model fit runs on semPower, exactly, and passes its check run", {
  result <- run_spec(sem_spec(list(type = "power", n = 300)))
  expect_equal(result$provenance$backend, "semPower")
  expect_equal(result$provenance$backend_function, "semPower::semPower.postHoc")
  expect_equal(result$provenance$method, "exact")
  expect_true(all(result$check_run$ok))
  expect_true(all(c("semPower", "lavaan") %in% names(result$provenance$packages)))
  expect_equal(result$sem$df, 51)
  expect_equal(result$sem$indicators, 12)
})

test_that("power equals semPower::semPower.postHoc() called directly", {
  direct <- semPower::semPower.postHoc(
    effect = 0.05, effect.measure = "RMSEA", alpha = 0.05, N = 300, df = 51
  )$power
  expect_equal(run_spec(sem_spec(list(type = "power", n = 300)))$curve$power, direct)
  direct_df <- semPower::semPower.postHoc(
    effect = 0.08, effect.measure = "RMSEA", alpha = 0.01, N = 150, df = 20
  )$power
  spec <- sem_df_spec(list(type = "power", n = 150), df = 20, rmsea = 0.08)
  spec$target_test$alpha <- 0.01
  expect_equal(run_spec(spec)$curve$power, direct_df)
})

test_that("power agrees with the noncentral chi-square written out in base R", {
  # The test of exact fit: the noncentrality is (N - 1) * F0, with
  # F0 = RMSEA^2 * df, against the central chi-square's critical value.
  n <- 300; df <- 51; rmsea <- 0.05
  base <- stats::pchisq(stats::qchisq(0.95, df), df, ncp = (n - 1) * rmsea^2 * df, lower.tail = FALSE)
  expect_equal(run_spec(sem_spec(list(type = "power", n = n)))$curve$power, base, tolerance = 1e-12)
})

test_that("a CFA's degrees of freedom match lavaan's count and the usual formula", {
  # Each item on one factor, the factors correlated: p(p + 1) / 2 moments
  # minus p loadings, p residual variances and k(k - 1) / 2 factor
  # correlations (factor variances fixed at 1).
  count <- function(p, k) p * (p + 1) / 2 - 2 * p - k * (k - 1) / 2
  for (shape in list(c(12, 3), c(10, 3), c(6, 1), c(4, 2), c(20, 4))) {
    spec <- validate_spec(sem_spec(list(type = "power", n = 300), indicators = shape[1], factors = shape[2]))
    df <- sem_summary(spec)$df
    expect_equal(df, count(shape[1], shape[2]), label = paste(shape, collapse = " items, factors "))
    # lavaan's df for the same model fitted to a made-up covariance matrix.
    covariance <- matrix(0.3, shape[1], shape[1]) + diag(0.7, shape[1])
    dimnames(covariance) <- list(paste0("x", seq_len(shape[1])), paste0("x", seq_len(shape[1])))
    fit <- suppressWarnings(lavaan::cfa(sem_summary(spec)$model, sample.cov = covariance, sample.nobs = 500))
    expect_equal(df, unname(lavaan::fitMeasures(fit, "df")))
  }
})

test_that("the required N matches semPower.aPriori()", {
  result <- run_spec(sem_spec(list(type = "sample_size", power = 0.8)))
  direct <- semPower::semPower.aPriori(
    effect = 0.05, effect.measure = "RMSEA", alpha = 0.05, power = 0.8, df = 51
  )
  expect_equal(result$n_required$n, direct$requiredN)
  at <- result$curve$power[result$curve$n == result$n_required$n]
  below <- result$curve$power[result$curve$n == result$n_required$n - 1]
  expect_gte(at, 0.8)
  expect_lt(below, 0.8)
})

test_that("as the misfit shrinks, power falls towards alpha", {
  # semPower refuses an RMSEA of 0, so the Type I error rate is checked in
  # the limit.
  result <- run_spec(sem_spec(list(type = "power", n = 300), rmsea = 1e-6))
  expect_equal(result$curve$power, 0.05, tolerance = 1e-6)
})

test_that("the spec checks refuse what can't be computed", {
  spec <- sem_spec(list(type = "power", n = 300))
  spec$population$df <- 51
  expect_spec_problem(spec, "not both")
  expect_spec_problem(sem_spec(list(type = "power", n = 300), indicators = 5, factors = 3), "at least two items")
  expect_spec_problem(sem_spec(list(type = "power", n = 300), indicators = 3, factors = 1), "0 degrees of freedom")
  expect_spec_problem(sem_spec(list(type = "power", n = 10)), "at least 13")
  expect_error(validate_spec(sem_spec(list(type = "power", n = 300), rmsea = 0)), class = "powerkit_spec_error")
  spec <- sem_spec(list(type = "sensitivity", n = 300, power = 0.8))
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  spec <- sem_spec(list(type = "power", n = 300))
  spec$target_test$alternative <- "greater"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  spec <- sem_spec(list(type = "power", n = 300))
  spec$options$method <- "simulation"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})

test_that("attrition is allowed for", {
  spec <- sem_spec(list(type = "power", n = 300))
  spec$options$attrition <- 0.1
  r <- run_spec(spec)$recruitment
  expect_equal(r$n_recruit, 334)
})

test_that("the exported script reproduces each goal with semPower alone", {
  specs <- list(
    sem_spec(list(type = "power", n = 300)),
    sem_spec(list(type = "sample_size", power = 0.9)),
    sem_df_spec(list(type = "sample_size", power = 0.8), df = 24, rmsea = 0.08)
  )
  for (spec in specs) {
    result <- run_spec(spec)
    out <- run_exported_script(spec, result)
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10, info = spec$goal$type)
  }
})

# Invariance, a factor correlation, a latent slope: power is semPower's own
# function at each n, reached through its F0 and semPower.postHoc().

latent_spec <- function(name, goal, ...) {
  spec <- example_spec(name)
  spec$options <- list(seed = 7)
  spec$goal <- goal
  changes <- list(...)
  for (field in names(changes)) spec$population[[field]] <- changes[[field]]
  spec
}

scalar_spec <- function(goal, ...) {
  spec <- latent_spec("sem_invariance", goal, level = "scalar", intercept_difference = 0.3, ...)
  spec$population$loading_group2 <- NULL
  spec
}

test_that("each template runs on its semPower function, exactly, and passes its check run", {
  functions <- c(
    sem_invariance = "semPower::semPower.powerMI",
    sem_factor_correlation = "semPower::semPower.powerCFA",
    sem_latent_regression = "semPower::semPower.powerRegression"
  )
  for (name in names(functions)) {
    result <- run_spec(latent_spec(name, list(type = "power", n = 300)))
    expect_equal(result$provenance$backend_function, functions[[name]], info = name)
    expect_equal(result$provenance$method, "exact", info = name)
    expect_true(all(result$check_run$ok), info = name)
    expect_true(all(c("semPower", "lavaan") %in% names(result$provenance$packages)), info = name)
  }
})

test_that("power equals semPower's functions called directly", {
  n <- 300
  direct <- semPower::semPower.powerMI(
    type = "post-hoc", comparison = "configural", nullEffect = "metric",
    loadings = list(list(rep(0.7, 6)), list(c(0.7, 0.7, 0.7, 0.7, 0.5, 0.5))),
    alpha = 0.05, N = list(150, 150)
  )
  result <- run_spec(latent_spec("sem_invariance", list(type = "power", n = n)))
  expect_equal(result$curve$power, direct$power, tolerance = 1e-8)
  expect_equal(result$sem$df, direct$df)

  direct <- semPower::semPower.powerMI(
    type = "post-hoc", comparison = "metric", nullEffect = "scalar",
    loadings = list(rep(0.7, 6)), tau = list(rep(0, 6), c(0, 0, 0, 0, 0.3, 0.3)),
    Alpha = list(0, 0), alpha = 0.05, N = list(120, 180)
  )$power
  spec <- scalar_spec(list(type = "power", n = n))
  spec$options$allocation_ratio <- 1.5
  expect_equal(run_spec(spec)$curve$power, direct, tolerance = 1e-8)

  direct <- semPower::semPower.powerCFA(
    type = "post-hoc", Phi = 0.2, nIndicator = c(4, 5), loadM = c(0.6, 0.7),
    alpha = 0.05, N = n
  )$power
  expect_equal(run_spec(latent_spec("sem_factor_correlation", list(type = "power", n = n)))$curve$power, direct, tolerance = 1e-8)

  direct <- semPower::semPower.powerRegression(
    type = "post-hoc", slopes = c(0.2, 0.3), corXX = 0.3, nullWhich = 1,
    nIndicator = c(4, 4, 4), loadM = 0.6, alpha = 0.05, N = n
  )$power
  expect_equal(run_spec(latent_spec("sem_latent_regression", list(type = "power", n = n)))$curve$power, direct, tolerance = 1e-8)
})

test_that("the required N matches semPower's own a-priori search", {
  apriori <- semPower::semPower.powerCFA(
    type = "a-priori", Phi = 0.2, nIndicator = c(4, 5), loadM = c(0.6, 0.7), alpha = 0.05, power = 0.8
  )$requiredN
  expect_equal(run_spec(latent_spec("sem_factor_correlation", list(type = "sample_size", power = 0.8)))$n_required$n, apriori)
  apriori <- semPower::semPower.powerRegression(
    type = "a-priori", slopes = c(0.2, 0.3), corXX = 0.3, nullWhich = 1,
    nIndicator = c(4, 4, 4), loadM = 0.6, alpha = 0.05, power = 0.8
  )$requiredN
  expect_equal(run_spec(latent_spec("sem_latent_regression", list(type = "sample_size", power = 0.8)))$n_required$n, apriori)
  # Two equal groups: semPower's search is over whole groups too.
  apriori <- semPower::semPower.powerMI(
    type = "a-priori", comparison = "configural", nullEffect = "metric",
    loadings = list(list(rep(0.7, 6)), list(c(0.7, 0.7, 0.7, 0.7, 0.5, 0.5))),
    alpha = 0.05, power = 0.8, N = list(1, 1)
  )$requiredN
  expect_equal(run_spec(latent_spec("sem_invariance", list(type = "sample_size", power = 0.8)))$n_required$n, apriori)
})

test_that("with no difference to detect, power is alpha", {
  power <- run_spec(latent_spec("sem_factor_correlation", list(type = "power", n = 300), r = 0.001))$curve$power
  expect_lt(abs(power - 0.05), 0.001)
})

test_that("the spec checks refuse what can't be computed", {
  goal <- list(type = "power", n = 300)
  expect_spec_problem(latent_spec("sem_invariance", goal, noninvariant = 6), "At least one item must be the same")
  spec <- latent_spec("sem_invariance", goal)
  spec$population$intercept_difference <- 0.3
  expect_spec_problem(spec, "Metric invariance is about loadings")
  spec <- scalar_spec(goal)
  spec$population$loading_group2 <- 0.5
  expect_spec_problem(spec, "Scalar invariance is about intercepts")
  expect_spec_problem(latent_spec("sem_invariance", list(type = "sample_size", power = 0.8), loading_group2 = 0.7), "zero in this population")
  expect_spec_problem(latent_spec("sem_latent_regression", goal, tested = 3), "only 2 slopes")
  expect_spec_problem(latent_spec("sem_latent_regression", goal, slopes = list(0.7, 0.7)), "impossible")
  expect_spec_problem(latent_spec("sem_latent_regression", goal, slopes = list(0.1, 0.1, 0.1), predictor_correlation = -0.6), "contradict")
  expect_spec_problem(latent_spec("sem_factor_correlation", list(type = "power", n = 9)), "at least 10")
  spec <- latent_spec("sem_factor_correlation", goal)
  spec$options$allocation_ratio <- 2
  expect_spec_problem(spec, "only applies to two-group designs")
})

test_that("the exported script reproduces each template with semPower alone", {
  specs <- list(
    latent_spec("sem_invariance", list(type = "sample_size", power = 0.8)),
    scalar_spec(list(type = "power", n = 250)),
    latent_spec("sem_factor_correlation", list(type = "power", n = 300)),
    latent_spec("sem_latent_regression", list(type = "sample_size", power = 0.9), slopes = list(0.25))
  )
  for (spec in specs) {
    result <- run_spec(spec)
    out <- run_exported_script(spec, result)
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10, info = spec$template)
  }
})

test_that("invariance over two occasions runs on semPower.powerLI() and matches it, power and N", {
  spec <- latent_spec("sem_invariance", list(type = "power", n = 300), over = "occasions", stability = 0.6)
  result <- run_spec(spec)
  expect_equal(result$provenance$backend_function, "semPower::semPower.powerLI")
  expect_true(all(result$check_run$ok))
  phi <- matrix(c(1, 0.6, 0.6, 1), 2)
  direct <- semPower::semPower.powerLI(
    type = "post-hoc", comparison = "configural", nullEffect = "metric",
    loadings = list(rep(0.7, 6), c(0.7, 0.7, 0.7, 0.7, 0.5, 0.5)), Phi = phi, alpha = 0.05, N = 300
  )$power
  expect_equal(result$curve$power, direct, tolerance = 1e-8)
  spec$goal <- list(type = "sample_size", power = 0.8)
  apriori <- semPower::semPower.powerLI(
    type = "a-priori", comparison = "configural", nullEffect = "metric",
    loadings = list(rep(0.7, 6), c(0.7, 0.7, 0.7, 0.7, 0.5, 0.5)), Phi = phi, alpha = 0.05, power = 0.8
  )$requiredN
  expect_equal(run_spec(spec)$n_required$n, apriori)
  # Scalar invariance over occasions, and the script.
  spec <- scalar_spec(list(type = "power", n = 200), over = "occasions", stability = 0.5)
  out <- run_exported_script(spec, run_spec(spec))
  expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10)
  # Refusals.
  expect_spec_problem(latent_spec("sem_invariance", list(type = "power", n = 300), over = "occasions"), "stability")
  expect_spec_problem(latent_spec("sem_invariance", list(type = "power", n = 300), stability = 0.5), "only used for invariance over occasions")
  spec <- latent_spec("sem_invariance", list(type = "power", n = 300), over = "occasions", stability = 0.6)
  spec$options$allocation_ratio <- 2
  expect_spec_problem(spec, "no groups to split")
})

test_that("invariance across three or more groups, several factors and three or more occasions matches semPower", {
  goal <- list(type = "power", n = 300)
  loads <- c(0.7, 0.7, 0.7, 0.7, 0.5, 0.5)
  power_mi <- function(...) semPower::semPower.powerMI(type = "post-hoc", alpha = 0.05, ...)$power
  power_li <- function(...) semPower::semPower.powerLI(type = "post-hoc", alpha = 0.05, ...)$power
  # Three equal groups, the last one differing.
  spec <- latent_spec("sem_invariance", goal, n_groups = 3)
  result <- run_spec(spec)
  expect_true(all(result$check_run$ok))
  expect_equal(result$sem$df, 10)
  direct <- power_mi(
    comparison = "configural", nullEffect = "metric", N = list(100, 100, 100),
    loadings = list(list(rep(0.7, 6)), list(rep(0.7, 6)), list(loads))
  )
  expect_equal(result$curve$power, direct, tolerance = 1e-8)
  # Whole groups only; no allocation ratio with three groups.
  expect_false(group_split(spec)$valid(301))
  spec$options$allocation_ratio <- 2
  expect_spec_problem(spec, "equal in size")
  # Two correlated factors across two groups: the first factor's items differ.
  spec <- latent_spec("sem_invariance", goal, factors = 2, factor_correlation = 0.3)
  phi <- matrix(c(1, 0.3, 0.3, 1), 2)
  direct <- power_mi(
    comparison = "configural", nullEffect = "metric", N = list(150, 150), Phi = list(phi, phi),
    loadings = list(list(rep(0.7, 6), rep(0.7, 6)), list(loads, rep(0.7, 6)))
  )
  result <- run_spec(spec)
  expect_equal(result$curve$power, direct, tolerance = 1e-8)
  expect_equal(result$sem$df, 10)
  expect_spec_problem(latent_spec("sem_invariance", goal, factors = 2), "factor_correlation")
  expect_spec_problem(latent_spec("sem_invariance", goal, factor_correlation = 0.3), "two or more factors")
  # Scalar invariance, three groups, two factors.
  spec <- scalar_spec(goal, n_groups = 3, factors = 2, factor_correlation = 0.3)
  direct <- power_mi(
    comparison = "metric", nullEffect = "scalar", N = list(100, 100, 100), Phi = list(phi, phi, phi),
    loadings = list(rep(0.7, 6), rep(0.7, 6)),
    tau = list(rep(0, 12), rep(0, 12), c(0, 0, 0, 0, 0.3, 0.3, rep(0, 6))), Alpha = list(c(0, 0), c(0, 0), c(0, 0))
  )
  expect_equal(run_spec(spec)$curve$power, direct, tolerance = 1e-8)
  out <- run_exported_script(spec, run_spec(spec))
  expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10)
  # Three occasions, one factor: the same stability between every two.
  spec <- latent_spec("sem_invariance", goal, over = "occasions", stability = 0.5, n_occasions = 3)
  p3 <- matrix(0.5, 3, 3)
  diag(p3) <- 1
  direct <- power_li(
    comparison = "configural", nullEffect = "metric", N = 300, Phi = p3,
    loadings = list(rep(0.7, 6), rep(0.7, 6), loads)
  )
  result <- run_spec(spec)
  expect_equal(result$curve$power, direct, tolerance = 1e-8)
  expect_equal(result$sem$df, 10)
  # Two factors on two occasions: the factor correlations times the
  # stability between occasions (order F1_T1, F2_T1, F1_T2, F2_T2).
  spec <- latent_spec("sem_invariance", goal, over = "occasions", stability = 0.5, factors = 2, factor_correlation = 0.3)
  p4 <- matrix(c(1, 0.3, 0.5, 0.15, 0.3, 1, 0.15, 0.5, 0.5, 0.15, 1, 0.3, 0.15, 0.5, 0.3, 1), 4)
  direct <- power_li(
    comparison = "configural", nullEffect = "metric", N = 300, Phi = p4,
    loadings = list(list(rep(0.7, 6), rep(0.7, 6)), list(loads, rep(0.7, 6)))
  )
  expect_equal(run_spec(spec)$curve$power, direct, tolerance = 1e-8)
  out <- run_exported_script(spec, run_spec(spec))
  expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10)
  # The counts belong to the right kind of invariance.
  expect_spec_problem(latent_spec("sem_invariance", goal, n_occasions = 3), "only used for invariance over occasions")
  expect_spec_problem(latent_spec("sem_invariance", goal, over = "occasions", stability = 0.5, n_groups = 3), "only used for invariance across groups")
  # The smallest sample: more people than items in every group.
  expect_equal(minimum_n(latent_spec("sem_invariance", goal, n_groups = 3, factors = 2, factor_correlation = 0.3)), 3 * 13)
})

test_that("the tests of close and not-close fit come from WebPower, and close fit at a null RMSEA of 0 is semPower's exact fit", {
  spec <- example_spec("sem_model_fit")
  spec$population <- list(metric = "rmsea", rmsea = 0.08, df = 51)
  spec$target_test$method <- "chi_square_close_fit"
  spec$goal <- list(type = "power", n = 200)
  result <- run_spec(spec)
  expect_identical(result$provenance$backend, "WebPower")
  expect_equal(result$curve$power, WebPower::wp.sem.rmsea(n = 200, df = 51, rmsea0 = 0.05, rmsea1 = 0.08, alpha = 0.05, type = "close")$power)
  expect_true(all(result$check_run$ok))
  expect_identical(result$sem$fit_test, "close")
  expect_equal(result$sem$rmsea_null, 0.05)
  # The test of close fit with a null RMSEA of 0 is the test of exact fit.
  expect_equal(webpower_rmsea_power(spec, 200, 51, rmsea_null = 0),
    semPower::semPower.postHoc(effect = 0.08, effect.measure = "RMSEA", alpha = 0.05, N = 200, df = 51)$power, tolerance = 1e-8)
  # Not-close fit: the population RMSEA below the null value.
  spec$target_test$method <- "chi_square_not_close_fit"
  spec$population$rmsea <- 0.01
  spec$goal <- list(type = "sample_size", power = 0.8)
  found <- run_spec(spec)
  power_at <- function(n) WebPower::wp.sem.rmsea(n = n, df = 51, rmsea0 = 0.05, rmsea1 = 0.01, alpha = 0.05, type = "notclose")$power
  expect_gte(power_at(found$n_required$n), 0.8)
  expect_lt(power_at(found$n_required$n - 1), 0.8)
  expect_identical(found$sem$fit_test, "not_close")
})

test_that("the tests of close and not-close fit refuse an RMSEA on the wrong side", {
  spec <- example_spec("sem_model_fit")
  spec$target_test$method <- "chi_square_close_fit"
  spec$population$rmsea <- 0.04
  expect_spec_problem(spec, "test of close fit asks whether the model's RMSEA is above 0.05")
  spec$target_test$method <- "chi_square_not_close_fit"
  spec$population$rmsea <- 0.06
  expect_spec_problem(spec, "test of not-close fit asks whether the model's RMSEA is below 0.05")
  spec <- example_spec("sem_model_fit")
  spec$population$rmsea_null <- 0.05
  expect_spec_problem(spec, "used only by the tests of close and not-close fit")
})

test_that("the exported script reproduces the tests of close and not-close fit", {
  skip_unless_scripts_can_run()
  spec <- example_spec("sem_model_fit")
  spec$target_test$method <- "chi_square_close_fit"
  spec$population$rmsea <- 0.08
  spec$goal <- list(type = "power", n = 250)
  run <- expect_script_reproduces_power(spec, run_for_export(spec))
  expect_match(paste(run$script, collapse = "\n"), "wp.sem.rmsea", fixed = TRUE)
})
