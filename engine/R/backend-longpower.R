# Backend adapter: growth curves (two groups, three or more occasions),
# by formula, via longpower.
#
# The model is the linear mixed model with a random intercept and slope
# for each person, and the test is of the group x time interaction: the
# difference between the groups' average rates of change. longpower's
# diggle.linear.power() computes its power by Diggle, Heagerty, Liang and
# Zeger's (2002) formula (Analysis of longitudinal data, section 2.4; cited
# by longpower's citation()), from the occasions' times and the covariance
# of a person's repeated measurements. powerkit builds that covariance from
# the random effects as longpower's own help example does: var(Y_j, Y_k) =
# sd_intercept^2 + t_j t_k sd_slope^2 + (t_j + t_k) cov(intercept, slope),
# plus the residual variance on the diagonal. Equal groups and complete
# data, which the formula assumes; attrition is allowed for by recruiting
# more (options > attrition), as for every design.

growth_inputs <- function(spec) {
  pop <- spec$population
  t <- as.numeric(unlist(pop$times))
  s_i <- pop$sd_intercept %||% 0
  s_s <- pop$sd_slope
  cov_is <- (pop$r_intercept_slope %||% 0) * s_i * s_s
  R <- outer(t, t, function(a, b) s_i^2 + a * b * s_s^2 + (a + b) * cov_is) + diag(pop$sd_residual^2, length(t))
  list(
    t = t, R = R, delta = pop$slope_difference, alpha = spec$target_test$alpha,
    alternative = spec$target_test$alternative %||% "two_sided",
    s_i = s_i, s_s = s_s, cov_is = cov_is, s_e = pop$sd_residual
  )
}

# The people per group diggle.linear.power() needs for a given power.
growth_n_for_power <- function(inputs, power) {
  longpower::diggle.linear.power(
    delta = abs(inputs$delta), t = inputs$t, sigma2 = 1, R = inputs$R, sig.level = inputs$alpha, power = power,
    alternative = if (inputs$alternative == "two_sided") "two.sided" else "one.sided"
  )$n[1]
}

# Power at n people in all. diggle.linear.power() given n finds the power by
# its own root-finding, which fails for small groups and returns about 0 for
# large ones (longpower 1.0.27; docs/upstream-questions.md), while its
# sample size for a given power is the formula itself. So the power is the
# one whose required group size is n / 2: the same formula, solved the
# other way.
growth_power <- function(inputs, n) {
  if (inputs$delta == 0) return(inputs$alpha)
  per <- n / 2
  low <- inputs$alpha + 1e-6
  high <- 1 - 1e-10
  if (growth_n_for_power(inputs, low) >= per) return(inputs$alpha)
  if (growth_n_for_power(inputs, high) <= per) return(1)
  stats::uniroot(function(p) growth_n_for_power(inputs, p) - per, c(low, high), tol = 1e-10)$root
}

growth_backend <- function(spec, seed = NULL) {
  inputs <- growth_inputs(spec)
  step <- valid_n_step(spec)
  power_at <- function(n) call_backend("longpower", growth_power(inputs, n))
  list(
    name = "longpower",
    packages = c("longpower"),
    methods = "exact",
    default_method = "exact",
    functions = c(exact = "longpower::diggle.linear.power"),
    n_step = step,
    exact_min_n = step * ceiling(minimum_n(spec) / step),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() growth_check_run(spec, inputs, seed)
  )
}

# Data for growth curves: n / 2 people in each group; each person's
# starting level and rate of change from the random effects (bivariate
# normal), the second group's average rate of change slope_difference
# higher, and the residuals. Long format: id, group (0, 1), time, y.
growth_data <- function(n, inputs) {
  per <- n / 2
  people <- 2 * per
  sigma <- matrix(c(inputs$s_i^2, inputs$cov_is, inputs$cov_is, inputs$s_s^2), 2)
  effects <- if (inputs$s_i == 0 && inputs$s_s == 0) matrix(0, people, 2) else SimDesign::rmvnorm(people, c(0, 0), sigma)
  group <- rep(c(0, 1), each = per)
  m <- length(inputs$t)
  data.frame(
    id = rep(seq_len(people), each = m),
    group = rep(group, each = m),
    time = rep(inputs$t, people),
    y = rep(effects[, 1], each = m) + rep(effects[, 2] + inputs$delta * group, each = m) * rep(inputs$t, people) +
      stats::rnorm(people * m, 0, inputs$s_e)
  )
}

# Check run: one large data set; the difference in average slopes by
# least squares within each person (each person's own slope, then the
# groups' means), and the covariance of a person's measurements against R.
growth_check_run <- function(spec, inputs, seed) {
  n <- 20000
  data <- with_seed(seed %||% 1L, growth_data(n, inputs))
  m <- length(inputs$t)
  tc <- inputs$t - mean(inputs$t)
  y <- matrix(data$y, ncol = m, byrow = TRUE)
  slopes <- as.vector(y %*% tc / sum(tc^2))
  group <- rep(c(0, 1), each = n / 2)
  d_hat <- mean(slopes[group == 1]) - mean(slopes[group == 0])
  se_d <- sqrt(stats::var(slopes[group == 1]) / (n / 2) + stats::var(slopes[group == 0]) / (n / 2))
  within <- y - outer(group * inputs$delta, inputs$t)
  cov_hat <- stats::cov(within)
  err <- max(abs(cov_hat - inputs$R) / sqrt((inputs$R^2 + outer(diag(inputs$R), diag(inputs$R))) / n))
  data.frame(
    parameter = c("difference in average rates of change (group 2 minus group 1)",
      "largest standardised difference between a simulated covariance and the one specified"),
    specified = c(inputs$delta, 0),
    recovered = c(d_hat, err),
    ok = c(abs(d_hat - inputs$delta) < 5 * se_d, err < 5)
  )
}

check_growth_curve <- function(spec) {
  problems <- character()
  t <- as.numeric(unlist(spec$population$times))
  if (any(diff(t) <= 0)) {
    problems <- c(problems, "'population > times' should be the occasions' times in increasing order, each later than the one before.")
  }
  if (!is.null(spec$options$allocation_ratio) && spec$options$allocation_ratio != 1) {
    problems <- c(problems, "Growth curves are calculated for equal groups, as Diggle and colleagues' formula assumes: remove 'options > allocation_ratio'.")
  }
  problems
}

growth_design_description <- function(spec, label, levels) {
  sprintf("growth curves: does the rate of change in %s differ between %s (%s), measured at times %s? Group x time in a linear mixed model with a random intercept and slope",
    label("Y"), label("G"), levels("G"), paste(format_number(as.numeric(unlist(spec$population$times))), collapse = ", "))
}

growth_script <- function(spec, result) {
  inputs <- growth_inputs(spec)
  c(
    script_header(spec, result, "longpower", "longpower::diggle.linear.power"),
    "library(longpower)",
    "",
    "# Inputs ----",
    goal_inputs(spec, result),
    sprintf("times <- %s # the occasions", r_code(inputs$t)),
    sprintf("slope_difference <- %s # group 2's average rate of change minus group 1's, per unit of time", r_code(inputs$delta)),
    sprintf("sd_intercept <- %s # SD of people's starting levels", r_code(inputs$s_i)),
    sprintf("sd_slope <- %s # SD of people's rates of change", r_code(inputs$s_s)),
    sprintf("r_intercept_slope <- %s # correlation of starting level and rate of change", r_code(spec$population$r_intercept_slope %||% 0)),
    sprintf("sd_residual <- %s # SD around each person's own line", r_code(inputs$s_e)),
    "",
    "# The covariance of a person's measurements, from the random effects, as",
    "# in longpower's help for diggle.linear.power().",
    "cov_is <- r_intercept_slope * sd_intercept * sd_slope",
    "R <- outer(times, times, function(a, b) sd_intercept^2 + a * b * sd_slope^2 + (a + b) * cov_is) +",
    "  diag(sd_residual^2, length(times))",
    "# diggle.linear.power()'s power for a given n uses its own root-finding,",
    "# which fails for small groups and gives about 0 for large ones (longpower",
    "# 1.0.27), so the power is found as the one whose required group size is",
    "# n_total / 2: the same formula, solved the other way.",
    "n_for_power <- function(power) {",
    sprintf("  diggle.linear.power(delta = abs(slope_difference), t = times, sigma2 = 1, R = R, sig.level = alpha, power = power, alternative = %s)$n[1]",
      r_code(if (inputs$alternative == "two_sided") "two.sided" else "one.sided")),
    "}",
    "power_at <- function(n_total) {",
    "  if (slope_difference == 0) return(alpha)",
    "  low <- alpha + 1e-6",
    "  high <- 1 - 1e-10",
    "  if (n_for_power(low) >= n_total / 2) return(alpha)",
    "  if (n_for_power(high) <= n_total / 2) return(1)",
    "  uniroot(function(p) n_for_power(p) - n_total / 2, c(low, high), tol = 1e-10)$root",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}
