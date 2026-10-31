# Backend adapter: the variance tests by their exact distributions, in base
# R's stats package.
#
# No package powerkit builds on has a formula for these tests, but their
# power follows directly from the distributions the G*Power 3.1 manual
# (June 1, 2023) gives in its implementation notes, which is how G*Power
# computes them:
#   one variance (section 26.5)  under H0, (N - 1) s^2 / sigma0^2 follows
#                                the central chi-square distribution with
#                                N - 1 df; under H1 the same distribution
#                                scaled by the ratio sigma^2 / sigma0^2
#   two variances (section 15.5) under H0, s1^2 / s2^2 follows the central
#                                F distribution with N1 - 1 and N2 - 1 df;
#                                under H1 the same distribution scaled by
#                                sigma1^2 / sigma2^2
# So power is the chance that the scaled statistic falls beyond the
# critical value(s): stats::pchisq() and stats::pf() at the critical
# values divided by the ratio. CLAUDE.md allows a published closed-form
# result where no package has one (31 October 2026); the answers are
# checked against the manual's own examples and against Spower's
# simulation of the same tests (test-backend-variance.R). Spower's
# simulation stays available with options > method = "simulation".
# A two-sided test puts alpha / 2 in each tail, as stats::var.test() and
# EnvStats::varTest() do. "greater" means the first variance (the expected
# one, or group 1's) is the larger.

# The variance tests powerkit computes by formula. The Pitman-Morgan test
# of two paired variances has no closed form here and stays simulated.
variance_formula_test <- function(spec) {
  identical(spec$design, "basic_test") && spec$template %in% c("one_variance", "two_variances")
}

variance_backend <- function(spec, seed = NULL) {
  inputs <- variance_inputs(spec)
  step <- valid_n_step(spec)
  n_min <- step * ceiling(minimum_n(spec) / step)
  power_at <- function(n) variance_power(inputs, n)
  list(
    name = "stats",
    packages = "stats",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = inputs$description),
    n_step = step,
    exact_min_n = n_min,
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    details = function(n) variance_details(inputs, n),
    check_run = function() variance_check_run(spec, inputs)
  )
}

variance_inputs <- function(spec) {
  pop <- spec$population
  ratio <- spec$options$allocation_ratio %||% 1
  alternative <- spec$target_test$alternative %||% "two_sided"
  one <- identical(spec$template, "one_variance")
  list(
    template = spec$template,
    alpha = spec$target_test$alpha,
    alternative = alternative,
    # The ratio of the variances under H1: the scale of the statistic.
    ratio = if (one) pop$var / pop$var0 else pop$var1 / pop$var2,
    df = if (one) {
      function(n) n - 1
    } else {
      function(n) {
        n1 <- round(n / (1 + ratio))
        c(n1 - 1, n - n1 - 1)
      }
    },
    statistic = if (one) "chi-square" else "F",
    description = if (one) {
      "stats::pchisq() (the chi-square test of one variance, as in the G*Power 3.1 manual, section 26)"
    } else {
      "stats::pf() (the F test of two variances, as in the G*Power 3.1 manual, section 15)"
    }
  )
}

# The critical value(s) of the statistic under H0, lower then upper (NA
# for a tail the test doesn't use).
variance_critical <- function(inputs, n) {
  df <- inputs$df(n)
  q <- function(p) {
    if (inputs$statistic == "F") stats::qf(p, df[1], df[2]) else stats::qchisq(p, df)
  }
  a <- inputs$alpha
  switch(
    inputs$alternative,
    two_sided = c(q(a / 2), q(1 - a / 2)),
    greater = c(NA_real_, q(1 - a)),
    less = c(q(a), NA_real_)
  )
}

# Power at total n: under H1 the statistic is the H0 distribution scaled
# by the variance ratio, so P(statistic > c) = P(H0 statistic > c / ratio).
variance_power <- function(inputs, n) {
  df <- inputs$df(n)
  p <- function(x, lower) {
    if (inputs$statistic == "F") {
      stats::pf(x, df[1], df[2], lower.tail = lower)
    } else {
      stats::pchisq(x, df, lower.tail = lower)
    }
  }
  critical <- variance_critical(inputs, n) / inputs$ratio
  below <- if (is.na(critical[1])) 0 else p(critical[1], TRUE)
  above <- if (is.na(critical[2])) 0 else p(critical[2], FALSE)
  below + above
}

variance_details <- function(inputs, n) {
  critical <- variance_critical(inputs, n)
  list(
    statistic = inputs$statistic,
    df = as.numeric(inputs$df(n)),
    critical = critical[!is.na(critical)],
    ncp = NA_real_,
    actual_alpha = NA_real_,
    source = sprintf("powerkit's formula, %s", sub(" \\(.*$", "", inputs$description))
  )
}

# Check run: there is no simulated data, so the check confirms that the
# ratio the formula uses is the one the spec's variances give.
variance_check_run <- function(spec, inputs) {
  pop <- spec$population
  specified <- if (identical(spec$template, "one_variance")) pop$var / pop$var0 else pop$var1 / pop$var2
  data.frame(
    parameter = "ratio of the variances the formula uses",
    specified = specified, recovered = inputs$ratio,
    ok = isTRUE(all.equal(specified, inputs$ratio))
  )
}
