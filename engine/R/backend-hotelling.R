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
  variance_formula_test(spec) || hotelling_formula_test(spec) && !permanova_test(spec) || manova_by_v(spec)
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
      "stats::pf() (two-sample Hotelling's T-squared by its noncentral F distribution)"
    } else {
      "stats::pf() (one-sample Hotelling's T-squared by its noncentral F distribution)"
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

# MANOVA given by Pillai's V (12 November 2026): the effect as one number,
# Pillai's trace, as G*Power's "MANOVA: Global effects" and "Special
# effects and interactions" take it, instead of the groups' means. No
# package powerkit builds on computes this; the published approximation is
# Faul, Erdfelder, Lang and Buchner (2007, refs.bib Faul2007_gpower),
# Table 5, with the O'Brien and Shieh (1999) algorithm that paper
# recommends: with s = min(a, c) (a outcomes, c the effect's degrees of
# freedom), f^2(V) = V / (s - V); the test statistic is F with df1 = a c
# and df2 = s (N - r - a + s) (r the number of groups, every cell of a
# two-factor design), and noncentrality N s f^2(V). V is the population
# value, as G*Power treats it; a published sample V tends to be too large.
# With two groups (s = 1) this is the exact Hotelling's T-squared test
# above. The answers are checked against Spower's simulation of the same
# MANOVA from means whose population V is known
# (test-backend-pillai-v.R).
manova_by_v <- function(spec) {
  identical(spec$template, "manova") && identical(spec$population$metric, "pillai_v")
}

# The effect's degrees of freedom: groups - 1 for one factor; for two, the
# main effect's levels - 1 or the interaction's product.
manova_effect_df <- function(spec) {
  a <- length(spec$variables$A$levels)
  if (is.null(spec$variables$B)) return(a - 1)
  b <- length(spec$variables$B$levels)
  switch(spec$target_test$effect, main_effect_A = a - 1, main_effect_B = b - 1, interaction = (a - 1) * (b - 1))
}

pillai_inputs <- function(spec, v = spec$population$pillai_v) {
  outcomes <- length(manova_outcomes(spec))
  effect_df <- manova_effect_df(spec)
  s <- min(outcomes, effect_df)
  list(
    alpha = spec$target_test$alpha,
    v = v,
    s = s,
    outcomes = outcomes,
    effect_df = effect_df,
    groups = manova_groups(spec),
    f2 = v / (s - v),
    description = "stats::pf() (MANOVA's Pillai's V by the O'Brien and Shieh approximation, Faul et al., 2007)"
  )
}

pillai_df <- function(inputs, n) {
  c(inputs$outcomes * inputs$effect_df, inputs$s * (n - inputs$groups - inputs$outcomes + inputs$s))
}

pillai_ncp <- function(inputs, n) n * inputs$s * inputs$f2

pillai_power <- function(inputs, n) {
  df <- pillai_df(inputs, n)
  critical <- stats::qf(1 - inputs$alpha, df[1], df[2])
  stats::pf(critical, df[1], df[2], ncp = pillai_ncp(inputs, n), lower.tail = FALSE)
}

# The population value of Pillai's V for groups' means (one row per group,
# equal groups), the outcomes' covariance matrix and the effect tested:
# the sum of lambda / (1 + lambda) over the eigenvalues of Sigma^-1 H*,
# with H* the effect's between-groups matrix per person (Faul et al., 2007,
# p. 183). Used to check the formula against simulation and to show the V
# a table of means implies.
pillai_v_from_means <- function(means, sigma, effect = "main_effect_A", a_levels = nrow(means)) {
  b_levels <- nrow(means) / a_levels
  centred <- if (b_levels == 1) {
    sweep(means, 2, colMeans(means))
  } else {
    term <- apply(means, 2, function(x) {
      cells <- matrix(x, nrow = a_levels, byrow = TRUE)
      fitted <- switch(effect,
        main_effect_A = matrix(rowMeans(cells), a_levels, b_levels) - mean(cells),
        main_effect_B = matrix(colMeans(cells), a_levels, b_levels, byrow = TRUE) - mean(cells),
        interaction = cells - outer(rowMeans(cells), colMeans(cells), "+") + mean(cells))
      as.numeric(t(fitted))
    })
    term
  }
  h <- crossprod(centred) / nrow(means)
  values <- Re(eigen(solve(sigma, h), only.values = TRUE)$values)
  values <- pmax(values, 0)
  sum(values / (1 + values))
}

pillai_sensitivity <- function(spec, n, target) {
  inputs <- pillai_inputs(spec, v = NA_real_)
  power_at <- function(v) pillai_power(pillai_inputs(spec, v), n)
  upper <- inputs$s * (1 - 1e-9)
  if (power_at(upper) < target) {
    abort_run("No Pillai's V reaches the target power at this sample size: choose a larger sample.")
  }
  v <- stats::uniroot(function(v) power_at(v) - target, c(1e-10, upper), tol = 1e-10)$root
  list(effect = v, power = power_at(v), effect_name = "V", effect_description = "Pillai's V (the population value, as G*Power takes it)")
}

pillai_backend <- function(spec, seed = NULL) {
  inputs <- pillai_inputs(spec)
  step <- valid_n_step(spec)
  n_min <- step * ceiling(minimum_n(spec) / step)
  power_at <- function(n) pillai_power(inputs, n)
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
    sensitivity = function(n, power) pillai_sensitivity(spec, n, power),
    details = function(n) {
      df <- pillai_df(inputs, n)
      list(statistic = "F", df = as.numeric(df), critical = stats::qf(1 - inputs$alpha, df[1], df[2]),
        ncp = pillai_ncp(inputs, n), actual_alpha = NA_real_,
        source = "powerkit's formula, stats::pf() (Pillai's V, O'Brien and Shieh approximation; Faul et al., 2007)")
    },
    check_run = function() data.frame(
      parameter = c("Pillai's V the formula uses", "its f-squared, V / (s - V)"),
      specified = c(spec$population$pillai_v, spec$population$pillai_v / (inputs$s - spec$population$pillai_v)),
      recovered = c(inputs$v, inputs$f2),
      ok = c(TRUE, TRUE)
    )
  )
}
