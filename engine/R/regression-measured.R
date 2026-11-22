# Linear regression's F tests with the predictors measured on each person
# (target_test > predictor_model "random", the default since 22 November
# 2026; Departure 39).
#
# G*Power's and pwrss's F tests for R-squared against 0, an R-squared
# increase and one coefficient (pwrss::power.f.regression()) treat the
# predictors as fixed: the noncentrality is lambda = f^2 N, the value it
# takes when the sample's predictors have exactly the population's
# covariances. When the predictors are measured, they differ from sample
# to sample, and the power is the fixed-predictor power averaged over the
# predictors' distribution (Shieh2007_random_regression;
# Gatsonis1989_multiple_correlation for R-squared against 0, G*Power's
# "random model"). For multivariate normal predictors that average is one
# integral: given the predictors, F is noncentral F(q, N - k - 1) with
# lambda = b' W b / sigma^2, where b are the tested coefficients and W the
# cross-products of the tested predictors after the intercept and the
# other k - q predictors are partialled out. W is Wishart with
# N - 1 - (k - q) degrees of freedom and the tested predictors' partial
# covariance matrix, so lambda is f^2 times a chi-square on N - 1 - (k - q)
# df, with f^2 Cohen's f^2 of the tested set (its partial R-squared over 1
# minus it). Power is then the noncentral F's tail at the critical value,
# integrated over that chi-square. No package powerkit builds on computes
# it (pwrss 1.3.3, MBESS 5.0.1 and WebPower 0.9.4 take the fixed model).
# Checked against simulated studies with predictors drawn afresh
# (test-backend-regression-measured.R, test-validation-formula-tests.R).
# G*Power's fixed model stays available (predictor_model "fixed").
#
# The card's Bayes factors take the same setting (22 November 2026). For
# R-squared against 0 (backend-bayesfactor-regression.R) the Bayes factor
# rises with F, so its power is the same integral with the F at which the
# Bayes factor reaches the threshold in place of the critical value. For
# an R-squared increase or one coefficient (backend-bayesfactor-r2change.R)
# each simulated study's two R-squared values are drawn with measured
# predictors (regression_measured_draw()).

regression_f_templates <- c("r2_zero", "r2_increase", "single_coefficient")

# The tests that take target_test > predictor_model: the F tests and the
# Bayes factors.
regression_predictor_methods <- c("f_test", "bayes_factor")

# Whether a spec is one of these tests with measured predictors.
regression_measured <- function(spec) {
  identical(spec$design, "multiple_regression") && isTRUE(spec$template %in% regression_f_templates) &&
    isTRUE(spec$target_test$method %in% regression_predictor_methods) &&
    !identical(spec$target_test$predictor_model, "fixed")
}

# Power of the F test of q tested predictors among k in all, with Cohen's
# f^2 for the tested set, at total sample size n, with multivariate normal
# predictors measured afresh in each sample.
regression_measured_power <- function(f2, n, k_total, k_tested, alpha) {
  df2 <- n - k_total - 1
  if (df2 < 1) return(NA_real_)
  regression_measured_tail(stats::qf(1 - alpha, k_tested, df2), f2, n, k_total, k_tested)
}

# The chance that the F statistic of the q tested predictors is above
# `critical`, with measured predictors: the noncentral F's tail averaged
# over its noncentrality, f^2 times a chi-square on N - 1 - (k - q) df.
regression_measured_tail <- function(critical, f2, n, k_total, k_tested) {
  df1 <- k_tested
  df2 <- n - k_total - 1
  if (f2 <= 0) return(stats::pf(critical, df1, df2, lower.tail = FALSE))
  m <- n - 1 - (k_total - k_tested)
  tail <- function(w) {
    dens <- stats::dchisq(w, m)
    dens * stats::pf(critical, df1, df2, ncp = f2 * w, lower.tail = FALSE)
  }
  lower <- stats::qchisq(1e-12, m)
  upper <- stats::qchisq(1e-12, m, lower.tail = FALSE)
  stats::integrate(tail, lower, upper, rel.tol = 1e-10, subdivisions = 1000L)$value
}

regression_measured_description <- function() {
  paste0(
    "stats::pf() averaged over stats::dchisq() (the F test with measured predictors: ",
    "fixed-predictor power averaged over normal predictors, Shieh 2007)"
  )
}

# The test's details at n: the F test's df and critical value. Its
# noncentrality varies from sample to sample, so its average is given,
# f^2 (N - 1 - (k - q)).
regression_measured_details <- function(f2, n, k_total, k_tested, alpha) {
  df <- c(k_tested, n - k_total - 1)
  list(
    statistic = "F",
    df = as.numeric(df),
    critical = stats::qf(1 - alpha, df[1], df[2]),
    ncp = NA_real_,
    actual_alpha = NA_real_,
    source = "powerkit's formula, stats::pf() averaged over stats::dchisq()"
  )
}

# The full and reduced models' R-squared in nrep studies of size n with
# measured, multivariate normal predictors: p in all, q of them tested;
# R-squared r2_full with all of them and r2_reduced without the tested
# ones. Any normal predictors can be rotated, within the reduced model's
# and the full model's column spaces, into independent standard normal
# ones without changing either sample R-squared, so take the kept
# predictors' part of the outcome, u, with variance r2_reduced, the
# tested predictors' part independent of them, v, with variance
# tau2 = r2_full - r2_reduced, and the error variance s2 = 1 - r2_full.
# Given the predictors, the sums of squares the reduced model explains,
# that the tested set adds, and the residual are independent noncentral
# chi-squares (in units of s2) on p - q, q and n - p - 1 df, with
# noncentralities |u + P v|^2 / s2 and |(I - P) v|^2 / s2, where P
# projects onto the kept predictors (after the mean). Over the
# predictors, |u|^2 is r2_reduced times a chi-square on n - 1, P v is
# normal on p - q dimensions with variance tau2 (so |u + P v|^2 is tau2
# times a noncentral chi-square on p - q df with noncentrality
# |u|^2 / tau2), and |(I - P) v|^2 is tau2 times a chi-square on
# n - 1 - (p - q) df, independent of P v. Checked against lm() on
# simulated data (test-backend-bayes-r2change.R).
regression_measured_draw <- function(n, nrep, p, q, r2_full, r2_reduced) {
  s2 <- 1 - r2_full
  tau2 <- r2_full - r2_reduced
  kept <- p - q
  a <- if (kept > 0) {
    u <- r2_reduced * stats::rchisq(nrep, n - 1)
    ncp_a <- if (tau2 > 0) tau2 * stats::rchisq(nrep, kept, ncp = u / tau2) else u
    stats::rchisq(nrep, kept, ncp = ncp_a / s2)
  } else {
    rep(0, nrep)
  }
  ncp_b <- tau2 * stats::rchisq(nrep, n - 1 - kept) / s2
  b <- stats::rchisq(nrep, q, ncp = ncp_b)
  e <- stats::rchisq(nrep, n - p - 1)
  total <- a + b + e
  list(full = (a + b) / total, reduced = a / total)
}

# Words for the design description.
regression_predictors_words <- function(measured) {
  if (isTRUE(measured)) "measured on each person" else "set by the design"
}
