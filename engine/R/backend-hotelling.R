# Backend adapter: Hotelling's T-squared for one group against fixed
# values, or two groups (MANOVA with two groups), by its exact
# distribution, in base R's stats package.
#
# No package powerkit builds on computes this test's power, but its
# distribution under the alternative is published: Anderson (2003), An
# Introduction to Multivariate Statistical Analysis, 3rd ed., section 5.4
# (p. 186). If T^2 = N (xbar - mu0)' S^-1 (xbar - mu0) is based on a
# sample of N from N(mu, Sigma), then (T^2 / n) (N - p) / p, with
# n = N - 1, has the noncentral F distribution with p and N - p degrees of
# freedom and noncentrality N (mu - mu0)' Sigma^-1 (mu - mu0). So power is
# the chance that this noncentral F exceeds the critical value of the
# central F: stats::qf() and stats::pf(ncp = ). Two groups (section 5.3.4,
# equations 14 and 15): sqrt(N1 N2 / (N1 + N2)) (ybar1 - ybar2) takes the
# place of sqrt(N) (xbar - mu0) and S is pooled on N1 + N2 - 2 df, so the
# F has p and N1 + N2 - p - 1 df and noncentrality
# N1 N2 / (N1 + N2) (mu1 - mu2)' Sigma^-1 (mu1 - mu2). With two groups
# every MANOVA statistic (Pillai's trace included) is this same test.
# G*Power computes both the same way. CLAUDE.md allows a published
# closed-form result where no package has one (31 October 2026); the
# answers are checked against Spower's simulation of the same tests
# (test-backend-hotelling-exact.R), which stays available with
# options > method = "simulation".

hotelling_formula_test <- function(spec) {
  identical(spec$design, "basic_test") && (identical(spec$template, "hotelling_one") || manova_two_groups(spec))
}

# A one-factor MANOVA with two groups: two-sample Hotelling's T-squared.
manova_two_groups <- function(spec) {
  identical(spec$template, "manova") && length(spec$variables$A$levels) == 2 && is.null(spec$variables$B)
}

# The basic tests powerkit computes by a published formula in base R.
formula_test <- function(spec) {
  variance_formula_test(spec) || hotelling_formula_test(spec)
}

hotelling_backend <- function(spec, seed = NULL) {
  inputs <- hotelling_inputs(spec)
  step <- valid_n_step(spec)
  n_min <- step * ceiling(minimum_n(spec) / step)
  power_at <- function(n) hotelling_power(inputs, n)
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
    details = function(n) hotelling_details(inputs, n),
    check_run = function() hotelling_check_run(spec, inputs)
  )
}

# The covariance matrix of the outcomes: their SDs, and one correlation r
# between every pair (as the simulation draws them, manova_scores()).
hotelling_sigma <- function(sds, r) {
  p <- length(sds)
  correlation <- matrix(r, p, p)
  diag(correlation) <- 1
  correlation * outer(sds, sds)
}

hotelling_inputs <- function(spec) {
  pop <- spec$population
  two <- identical(spec$template, "manova")
  difference <- if (two) {
    means <- manova_means(spec)
    means[2, ] - means[1, ]
  } else {
    as.numeric(unlist(pop$means)) - as.numeric(unlist(pop$mu0))
  }
  sigma <- hotelling_sigma(as.numeric(unlist(pop$sds)), pop$r)
  list(
    alpha = spec$target_test$alpha,
    p = length(difference),
    groups = if (two) 2 else 1,
    # The squared Mahalanobis distance between the two groups' means, or of
    # the means from the fixed values.
    distance2 = as.numeric(t(difference) %*% solve(sigma, difference)),
    description = if (two) {
      "stats::pf() (two-sample Hotelling's T-squared by its noncentral F distribution, Anderson, 2003, sections 5.3.4 and 5.4)"
    } else {
      "stats::pf() (one-sample Hotelling's T-squared by its noncentral F distribution, Anderson, 2003, section 5.4)"
    }
  )
}

# Denominator df: N - p for one group, N1 + N2 - p - 1 for two.
hotelling_df <- function(inputs, n) c(inputs$p, n - inputs$p - (inputs$groups - 1))

# Noncentrality: N times the distance for one group; N1 N2 / (N1 + N2),
# with equal groups n / 4, for two.
hotelling_ncp <- function(inputs, n) {
  if (inputs$groups == 2) (n / 2)^2 / n * inputs$distance2 else n * inputs$distance2
}

hotelling_power <- function(inputs, n) {
  df <- hotelling_df(inputs, n)
  critical <- stats::qf(1 - inputs$alpha, df[1], df[2])
  stats::pf(critical, df[1], df[2], ncp = hotelling_ncp(inputs, n), lower.tail = FALSE)
}

hotelling_details <- function(inputs, n) {
  df <- hotelling_df(inputs, n)
  list(
    statistic = "F",
    df = as.numeric(df),
    critical = stats::qf(1 - inputs$alpha, df[1], df[2]),
    ncp = hotelling_ncp(inputs, n),
    actual_alpha = NA_real_,
    source = sprintf("powerkit's formula, %s", sub(" \\(.*$", "", inputs$description))
  )
}

# Check run: there is no simulated data, so the check confirms that the
# covariance matrix the formula uses has the spec's SDs and correlation.
hotelling_check_run <- function(spec, inputs) {
  pop <- spec$population
  sds <- as.numeric(unlist(pop$sds))
  sigma <- hotelling_sigma(sds, pop$r)
  recovered_sds <- sqrt(diag(sigma))
  recovered_r <- if (length(sds) > 1) mean(stats::cov2cor(sigma)[upper.tri(sigma)]) else NA_real_
  data.frame(
    parameter = c(sprintf("SD of Y%d the formula uses", seq_along(sds)), "correlation between two outcomes the formula uses"),
    specified = c(sds, pop$r),
    recovered = c(recovered_sds, recovered_r),
    ok = c(abs(recovered_sds - sds) < 1e-9, length(sds) == 1 || abs(recovered_r - pop$r) < 1e-9)
  )
}
