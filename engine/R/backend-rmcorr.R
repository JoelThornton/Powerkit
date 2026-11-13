# Backend adapter: the repeated-measures correlation (rmcorr), by the exact
# distribution of r at its effective sample size (pwrss).
#
# The repeated-measures correlation (Bakdash and Marusich, 2017, refs.bib
# Bakdash2017_rmcorr) is the association of two scores within people: an
# analysis of covariance with a separate intercept for each person and one common slope, so it is the
# partial correlation of the two scores controlling for the N - 1 person
# dummies. Its t test has N(k - 1) - 1 degrees of freedom for N people
# measured k times. A partial correlation controlling for q variables has
# the distribution of a Pearson correlation in a sample q smaller, so the
# test's power is a Pearson correlation's at n = N(k - 1) + 1, the
# "effective sample size" rmcorr's documentation tells researchers to give
# G*Power or the pwr package. powerkit uses the exact distribution of r at
# that n (pwrss's power.exact.onecor(), as the correlation card does)
# rather than Fisher's z (rmcorr's own power.rmcorr() example); the check
# against simulated studies analysed with rmcorr::rmcorr() is in
# test-backend-rmcorr.R and test-validation-rmcorr.R.
#
# Assumed, as by the analysis itself: one within-person slope shared by
# everyone (people differ only in their averages), normal residuals, and
# measurements independent within a person once their average is removed.
# A slope that varies between people needs a multilevel model with random
# slopes, which the card says.

rmcorr_test <- function(spec) {
  identical(spec$design, "basic_test") && identical(spec$template, "repeated_measures_correlation")
}

# The effective sample size for N people measured k times: the Pearson
# sample size with the same degrees of freedom, N(k - 1) - 1 + 2.
rmcorr_effective_n <- function(n, k) n * (k - 1) + 1

rmcorr_backend <- function(spec, seed = NULL) {
  inputs <- rmcorr_inputs(spec)
  power_at <- function(n) rmcorr_power(inputs, n)
  list(
    name = "pwrss",
    packages = "pwrss",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = inputs$description),
    n_step = 1,
    exact_min_n = minimum_n(spec),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = function(n, power) rmcorr_sensitivity(inputs, n, power),
    details = function(n) rmcorr_details(inputs, n),
    check_run = function() rmcorr_check_run(spec, seed)
  )
}

rmcorr_inputs <- function(spec) {
  pop <- spec$population
  list(
    r = pop$r,
    k = as.integer(pop$measurements),
    alpha = spec$target_test$alpha,
    alternative = spec$target_test$alternative %||% "two_sided",
    description = paste0(
      "pwrss::power.exact.onecor() at the effective sample size N(k - 1) + 1 ",
      "(the exact distribution of r, with the repeated-measures correlation's N(k - 1) - 1 degrees of freedom)"
    )
  )
}

# Power for N people. pwrss's one-sided test looks in the direction of rho
# (a test pointing the other way is refused in the spec checks); at rho = 0
# exactly it stops (pwrss 1.3.3), where power is alpha, so the smallest
# positive number stands in, as for the correlation card.
rmcorr_power <- function(inputs, n, r = inputs$r) {
  out <- pwrss::power.exact.onecor(
    rho = if (isTRUE(r == 0)) .Machine$double.eps else r, null.rho = 0,
    n = rmcorr_effective_n(n, inputs$k), alpha = inputs$alpha,
    alternative = if (inputs$alternative == "two_sided") "two.sided" else "one.sided",
    verbose = 0
  )
  as.numeric(out$power)
}

# The smallest repeated-measures correlation with the target power at N
# people, searched with the same power call. Two-sided, it has the sign of
# the specified r (positive if none); one-sided, the sign the test looks for.
rmcorr_sensitivity <- function(inputs, n, target) {
  direction <- switch(inputs$alternative,
    two_sided = if (isTRUE(inputs$r < 0)) -1 else 1, greater = 1, less = -1)
  power_at <- function(r) rmcorr_power(inputs, n, direction * r)
  limit <- 1 - 1e-9
  if (power_at(limit) < target) {
    abort_run("No correlation reaches the target power with this many people and measurements: add people or measurements.")
  }
  r <- stats::uniroot(function(r) power_at(r) - target, lower = 1e-9, upper = limit, tol = 1e-10)$root
  list(effect = direction * r, effect_name = "r", effect_description = "repeated-measures correlation r",
    power = power_at(r))
}

rmcorr_details <- function(inputs, n) {
  df <- rmcorr_effective_n(n, inputs$k) - 2
  tail <- if (inputs$alternative == "two_sided") inputs$alpha / 2 else inputs$alpha
  list(
    statistic = "t",
    df = df,
    critical = stats::qt(1 - tail, df),
    ncp = NA_real_,
    actual_alpha = NA_real_,
    source = sprintf("pwrss::power.exact.onecor() at the effective sample size %d", as.integer(rmcorr_effective_n(n, inputs$k)))
  )
}

# Data for N people measured k times with a common within-person slope:
# each person's average on X and Y drawn independently (any spread leaves
# r_rm unchanged), then within-person deviations with correlation r. X's
# deviations from the person's average and Y's own noise both keep (k - 1)
# / k of their variance after centring, so the population r_rm is r.
rmcorr_simulated_data <- function(n, k, r) {
  person <- rep(seq_len(n), each = k)
  x <- stats::rnorm(n)[person] + stats::rnorm(n * k)
  within_x <- x - stats::ave(x, person)
  y <- stats::rnorm(n)[person] + r * within_x + sqrt(1 - r^2) * stats::rnorm(n * k)
  data.frame(participant = factor(person), x = x, y = y)
}

# The repeated-measures correlation of a data set: the correlation of the
# two scores after removing each person's average, which equals rmcorr's
# estimate (the partial correlation given the person dummies).
rmcorr_estimate <- function(data) {
  stats::cor(data$x - stats::ave(data$x, data$participant), data$y - stats::ave(data$y, data$participant))
}

# Check run: one large simulated study recovers the specified correlation.
rmcorr_check_run <- function(spec, seed = NULL) {
  inputs <- rmcorr_inputs(spec)
  people <- max(1000, ceiling(20000 / inputs$k))
  data <- with_seed(seed %||% 1L, rmcorr_simulated_data(people, inputs$k, inputs$r))
  recovered <- rmcorr_estimate(data)
  data.frame(
    parameter = "repeated-measures correlation r",
    specified = inputs$r, recovered = recovered,
    ok = abs(recovered - inputs$r) < 0.02
  )
}
