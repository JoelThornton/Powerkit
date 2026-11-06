# Validation: the random-intercept cross-lagged panel model (powerkit's
# Spower experiment p_riclpm() around powRICLPM).
#   1. agreement with a simulation written separately: data drawn here in
#      base R (within-person parts with variance 1 and the lagged effects,
#      random intercepts with variance icc / (1 - icc)) and fitted with the
#      model written out in lavaan syntax as Hamaker, Kuiper and Grasman
#      (2015) give it, rather than powRICLPM's code; lavaan's Wald test of
#      the effect. Both are simulations of the same model, so no allowance
#      beyond Monte Carlo error.
#   2. published example: Mulder (refs.bib Mulder2023_powRICLPM); placeholder
#      for the maintainer
# Skipped unless POWERKIT_FULL_VALIDATION=true.

riclpm_spec <- function(case, seed) {
  validation_spec(
    design = "panel",
    template = "riclpm",
    variables = list(X = validation_variable("continuous", "X"), Y = validation_variable("continuous", "Y")),
    population = list(metric = "standardised", waves = case$waves, icc = case$icc, ri_correlation = case$ri_cor,
      autoregressive_x = case$ar_x, autoregressive_y = case$ar_y, cross_lagged_xy = case$cl_xy,
      cross_lagged_yx = case$cl_yx, within_correlation = case$within_cor, constraints = case$constraints),
    target_test = list(effect = case$effect, method = "wald_z", alpha = 0.05, alternative = "two_sided"),
    seed = seed,
    n = case$n
  )
}

riclpm_syntax <- function(waves, equal) {
  t <- seq_len(waves)
  lab <- function(name) if (equal) paste0(name, "*") else ""
  paste(c(
    sprintf("RIx =~ %s", paste0("1*x", t, collapse = " + ")),
    sprintf("RIy =~ %s", paste0("1*y", t, collapse = " + ")),
    sprintf("wx%d =~ 1*x%d", t, t), sprintf("wy%d =~ 1*y%d", t, t),
    sprintf("x%d ~~ 0*x%d", t, t), sprintf("y%d ~~ 0*y%d", t, t),
    sprintf("wx%d ~ %swx%d + %swy%d", t[-1], lab("axx"), t[-waves], lab("ayx"), t[-waves]),
    sprintf("wy%d ~ %swx%d + %swy%d", t[-1], lab("axy"), t[-waves], lab("ayy"), t[-waves]),
    sprintf("wx%d ~~ wy%d", t, t),
    sprintf("wx%d ~~ wx%d", t, t), sprintf("wy%d ~~ wy%d", t, t),
    "RIx ~~ RIx", "RIy ~~ RIy", "RIx ~~ RIy",
    "RIx ~~ 0*wx1 + 0*wy1", "RIy ~~ 0*wx1 + 0*wy1"
  ), collapse = "\n")
}

riclpm_by_hand <- function(case, nrep, seed) {
  phi <- matrix(c(case$ar_x, case$cl_yx, case$cl_xy, case$ar_y), 2, byrow = TRUE)
  within <- matrix(c(1, case$within_cor, case$within_cor, 1), 2)
  residual <- within - phi %*% within %*% t(phi)
  v <- case$icc / (1 - case$icc)
  between <- v * matrix(c(1, case$ri_cor, case$ri_cor, 1), 2)
  model <- riclpm_syntax(case$waves, identical(case$constraints, "lagged"))
  target <- switch(case$effect, cross_lagged_xy = c("wy2", "wx1"), cross_lagged_yx = c("wx2", "wy1"),
    autoregressive_x = c("wx2", "wx1"), autoregressive_y = c("wy2", "wy1"))
  p <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    w <- MASS::mvrnorm(case$n, c(0, 0), within)
    parts <- list(w)
    for (k in 2:case$waves) {
      w <- w %*% t(phi) + MASS::mvrnorm(case$n, c(0, 0), residual)
      parts[[k]] <- w
    }
    b <- MASS::mvrnorm(case$n, c(0, 0), between)
    d <- data.frame(vapply(parts, function(x) x[, 1], numeric(case$n)) + b[, 1],
      vapply(parts, function(x) x[, 2], numeric(case$n)) + b[, 2])
    names(d) <- c(paste0("x", seq_len(case$waves)), paste0("y", seq_len(case$waves)))
    fit <- tryCatch(suppressWarnings(lavaan::lavaan(model, data = d, meanstructure = TRUE, int.ov.free = TRUE)),
      error = function(e) NULL)
    if (is.null(fit) || !lavaan::lavInspect(fit, "converged")) return(NA_real_)
    pe <- lavaan::parameterEstimates(fit)
    pe$pvalue[pe$lhs == target[1] & pe$op == "~" & pe$rhs == target[2]]
  }, numeric(1)))
  ok <- p[!is.na(p)]
  list(power = mean(ok < 0.05), mcse = sqrt(mean(ok < 0.05) * (1 - mean(ok < 0.05)) / length(ok)))
}

test_that("random-intercept cross-lagged panel model: a model written separately gives the same power (simulation)", {
  skip_unless_full_validation()
  skip_if_not_installed("powRICLPM")
  cases <- list(
    list(waves = 4, icc = 0.5, ri_cor = 0.3, ar_x = 0.4, ar_y = 0.3, cl_xy = 0.15, cl_yx = 0.1, within_cor = 0.3,
      constraints = "none", effect = "cross_lagged_xy", n = 300),
    list(waves = 5, icc = 0.3, ri_cor = 0, ar_x = 0.3, ar_y = 0.5, cl_xy = 0.1, cl_yx = 0.1, within_cor = 0.2,
      constraints = "lagged", effect = "cross_lagged_yx", n = 200),
    list(waves = 3, icc = 0.6, ri_cor = 0.5, ar_x = 0.2, ar_y = 0.2, cl_xy = 0, cl_yx = 0.2, within_cor = 0,
      constraints = "none", effect = "autoregressive_x", n = 250)
  )
  for (i in seq_along(cases)) {
    spec <- riclpm_spec(cases[[i]], 7600L + i)
    spec$options$nrep <- 1000L
    reference <- riclpm_by_hand(cases[[i]], 1000L, 7610L + i)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  }
})

test_that("random-intercept cross-lagged panel model: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: Mulder, refs.bib Mulder2023_powRICLPM, the
  # illustrative power analysis: waves, ICC, lagged effects and the power
  # reported at a given N; table or figure, page).
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(n, published_power)
  case <- list(waves = 4, icc = 0.5, ri_cor = 0.3, ar_x = 0.2, ar_y = 0.3, cl_xy = 0.15, cl_yx = 0.1,
    within_cor = 0.3, constraints = "none", effect = "cross_lagged_xy", n = n)
  expect_power_near(engine_power(riclpm_spec(case, 7620L)), published_power)
})
