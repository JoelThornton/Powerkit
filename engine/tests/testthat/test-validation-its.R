# Validation: interrupted time series (powerkit's Spower experiment p_its()
# around PITS's simulated series and nlme's gls()).
#   1. agreement with a simulation written separately: the series drawn
#      here in base R (the segmented line plus AR(1) errors started as
#      PITS's are) and fitted here with gls() by REML; no allowance beyond
#      Monte Carlo error
#   2. PITS's own test (method "gls_ml") against PITS's calculate_power()
#   3. published example: placeholder for the maintainer
# Skipped unless POWERKIT_FULL_VALIDATION=true.

its_spec <- function(case, seed, method = "gls_reml") {
  validation_spec(
    design = "time_series",
    template = "its",
    variables = list(Y = validation_variable("continuous", "Outcome")),
    population = list(metric = "raw", n_pre = case$n_pre, baseline = 10, pre_trend = case$pre_trend,
      level_change = case$level, slope_change = case$slope, sigma = case$sigma, rho = case$rho),
    target_test = list(effect = case$test, method = method, alpha = 0.05, alternative = "two_sided"),
    seed = seed,
    n = case$n_post
  )
}

its_by_hand <- function(case, nrep, seed) {
  p <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    total <- case$n_pre + case$n_post
    time <- seq_len(total)
    after <- as.integer(time > case$n_pre)
    since <- (time - case$n_pre) * after
    e <- stats::filter(stats::rnorm(total, 0, case$sigma * sqrt(1 - case$rho^2)), case$rho, method = "recursive")
    d <- data.frame(time = time, after = after, since = since,
      y = 10 + case$pre_trend * time + case$level * after + case$slope * since + as.numeric(e))
    fit <- tryCatch(nlme::gls(y ~ time + after + since, data = d, correlation = nlme::corAR1(form = ~time), method = "REML"),
      error = function(e) NULL)
    if (is.null(fit)) return(NA_real_)
    tt <- summary(fit)$tTable
    switch(case$test, level = tt["after", 4], slope = tt["since", 4],
      both = stats::anova(fit, Terms = c("after", "since"))[["p-value"]])
  }, numeric(1)))
  ok <- p[!is.na(p)]
  list(power = mean(ok < 0.05), mcse = sqrt(mean(ok < 0.05) * (1 - mean(ok < 0.05)) / length(ok)))
}

its_cases <- list(
  list(n_pre = 24, n_post = 24, pre_trend = 0, level = -3, slope = 0, sigma = 2.5, rho = 0.4, test = "level"),
  list(n_pre = 36, n_post = 24, pre_trend = 0.05, level = 0, slope = -0.2, sigma = 2, rho = 0.2, test = "slope"),
  list(n_pre = 12, n_post = 18, pre_trend = 0, level = -2, slope = -0.1, sigma = 1.5, rho = 0.6, test = "both")
)

test_that("interrupted time series: a simulation written separately gives the same power (simulation)", {
  skip_unless_full_validation()
  skip_if_not_installed("PITS")
  for (i in seq_along(its_cases)) {
    spec <- its_spec(its_cases[[i]], 7700L + i)
    spec$options$nrep <- 2000L
    reference <- its_by_hand(its_cases[[i]], 2000L, 7710L + i)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  }
})

test_that("interrupted time series: PITS's own test gives PITS's calculate_power() (simulation)", {
  skip_unless_full_validation()
  skip_if_not_installed("PITS")
  for (i in seq_along(its_cases)[1:2]) {
    case <- its_cases[[i]]
    spec <- its_spec(case, 7720L + i, method = "gls_ml")
    spec$options$nrep <- 2000L
    pits <- PITS::calculate_power(n_pre = case$n_pre, n_post = case$n_post, baseline = 10, level_change = case$level,
      slope_change = case$slope, sigma = case$sigma, rho = case$rho, test = case$test, n_sim = 2000L, seed = 7730L + i,
      pre_trend = case$pre_trend)
    reference <- list(power = pits$power, mcse = sqrt(pits$power * (1 - pits$power) / pits$n_converged))
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  }
})

test_that("interrupted time series: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power table for segmented
  # regression with AR(1) errors, such as Zhang, Wagner and Ross-Degnan
  # (2011), Table 1: points before and after, level or slope change,
  # autocorrelation and power; add the source to refs.bib first).
  n_post <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(n_post, published_power)
  case <- list(n_pre = n_post, n_post = n_post, pre_trend = 0, level = 1, slope = 0, sigma = 1, rho = 0.2, test = "level")
  expect_power_near(engine_power(its_spec(case, 7740L, method = "gls_ml")), published_power)
})
