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

regression_f_templates <- c("r2_zero", "r2_increase", "single_coefficient")

# Whether a spec is one of these F tests with measured predictors.
regression_measured <- function(spec) {
  identical(spec$design, "multiple_regression") && isTRUE(spec$template %in% regression_f_templates) &&
    identical(spec$target_test$method, "f_test") &&
    !identical(spec$target_test$predictor_model, "fixed")
}

# Power of the F test of q tested predictors among k in all, with Cohen's
# f^2 for the tested set, at total sample size n, with multivariate normal
# predictors measured afresh in each sample.
regression_measured_power <- function(f2, n, k_total, k_tested, alpha) {
  df1 <- k_tested
  df2 <- n - k_total - 1
  if (df2 < 1) return(NA_real_)
  critical <- stats::qf(1 - alpha, df1, df2)
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
