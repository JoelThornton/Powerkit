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
#
# With drop-out over the occasions (population > retention: the share
# still in the study at each one) or unequal groups (options >
# allocation_ratio), powerkit uses longpower's
# hu.mackey.thomas.linear.power() instead: Hu, Mackey and Thomas's (2021)
# formula for random coefficient models with monotone missing data (the
# reference in longpower's help), which keeps everyone's data up to their
# last occasion. It assumes both groups start at the same level, as in a
# randomised trial; Diggle's lets each group have its own.

growth_inputs <- function(spec) {
  pop <- spec$population
  t <- as.numeric(unlist(pop$times))
  s_i <- pop$sd_intercept %||% 0
  s_s <- pop$sd_slope
  cov_is <- (pop$r_intercept_slope %||% 0) * s_i * s_s
  R <- outer(t, t, function(a, b) s_i^2 + a * b * s_s^2 + (a + b) * cov_is) + diag(pop$sd_residual^2, length(t))
  retention <- if (is.null(pop$retention)) rep(1, length(t)) else as.numeric(unlist(pop$retention))
  ratio <- spec$options$allocation_ratio %||% 1
  list(
    t = t, R = R, delta = pop$slope_difference, alpha = spec$target_test$alpha,
    alternative = spec$target_test$alternative %||% "two_sided",
    s_i = s_i, s_s = s_s, cov_is = cov_is, s_e = pop$sd_residual,
    r_is = pop$r_intercept_slope %||% 0, retention = retention, ratio = ratio,
    # The share whose last occasion is each one (longpower's p).
    last_visit = c(-diff(retention), retention[length(retention)]),
    hmt = !is.null(pop$retention) || !isTRUE(all.equal(ratio, 1))
  )
}

# Power at n people in all by Hu, Mackey and Thomas's formula: n1 in the
# first group, lambda = n1 / n2 (longpower's allocation ratio, the inverse
# of powerkit's n2 / n1).
growth_hmt_power <- function(inputs, n) {
  n1 <- n / (1 + inputs$ratio)
  longpower::hu.mackey.thomas.linear.power(
    n = n1, delta = abs(inputs$delta), t = inputs$t, lambda = 1 / inputs$ratio,
    sig2.i = inputs$s_i^2, cor.s.i = inputs$r_is, sig2.s = inputs$s_s^2, sig2.e = inputs$s_e^2,
    p = inputs$last_visit, sig.level = inputs$alpha,
    alternative = if (inputs$alternative == "two_sided") "two.sided" else "one.sided"
  )$power
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
  power_at <- function(n) call_backend("longpower", if (inputs$hmt) growth_hmt_power(inputs, n) else growth_power(inputs, n))
  list(
    name = "longpower",
    packages = c("longpower"),
    methods = "exact",
    default_method = "exact",
    functions = c(exact = if (inputs$hmt) "longpower::hu.mackey.thomas.linear.power" else "longpower::diggle.linear.power"),
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
  n1 <- round(n / (1 + (inputs$ratio %||% 1)))
  people <- n
  sigma <- matrix(c(inputs$s_i^2, inputs$cov_is, inputs$cov_is, inputs$s_s^2), 2)
  effects <- if (inputs$s_i == 0 && inputs$s_s == 0) matrix(0, people, 2) else SimDesign::rmvnorm(people, c(0, 0), sigma)
  group <- c(rep(0, n1), rep(1, n - n1))
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
  group <- data$group[seq(1, nrow(data), by = m)]
  d_hat <- mean(slopes[group == 1]) - mean(slopes[group == 0])
  se_d <- sqrt(stats::var(slopes[group == 1]) / sum(group == 1) + stats::var(slopes[group == 0]) / sum(group == 0))
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
  r <- spec$population$retention
  if (!is.null(r)) {
    r <- as.numeric(unlist(r))
    if (length(r) != length(t)) {
      problems <- c(problems, sprintf("'population > retention' needs one share for each occasion (%d), in the order of 'times'.", length(t)))
    } else if (!isTRUE(all.equal(r[1], 1)) || any(diff(r) > 1e-12)) {
      problems <- c(problems, "'population > retention' should start at 1 (everyone is measured at the first occasion) and never rise: someone who drops out misses every later occasion.")
    }
    if (!is.null(spec$options$attrition) && spec$options$attrition > 0) {
      problems <- c(problems, "'population > retention' already allows for drop-out over the occasions, and people who drop out are still analysed up to their last occasion: remove 'options > attrition'.")
    }
  }
  problems
}

growth_design_description <- function(spec, label, levels) {
  r <- spec$population$retention
  paste0(sprintf("growth curves: does the rate of change in %s differ between %s (%s), measured at times %s? Group x time in a linear mixed model with a random intercept and slope",
    label("Y"), label("G"), levels("G"), paste(format_number(as.numeric(unlist(spec$population$times))), collapse = ", ")),
    if (!is.null(r)) sprintf("; still in the study at each occasion: %s", paste(format_number(as.numeric(unlist(r))), collapse = ", ")) else "")
}

growth_script <- function(spec, result) {
  inputs <- growth_inputs(spec)
  if (inputs$hmt) return(growth_hmt_script(spec, result, inputs))
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

# The R script for Hu, Mackey and Thomas's formula (drop-out or unequal
# groups).
growth_hmt_script <- function(spec, result, inputs) {
  c(
    script_header(spec, result, "longpower", "longpower::hu.mackey.thomas.linear.power"),
    "library(longpower)",
    "",
    "# Inputs ----",
    goal_inputs(spec, result),
    sprintf("times <- %s # the occasions", r_code(inputs$t)),
    sprintf("slope_difference <- %s # group 2's average rate of change minus group 1's, per unit of time", r_code(inputs$delta)),
    sprintf("sd_intercept <- %s # SD of people's starting levels", r_code(inputs$s_i)),
    sprintf("sd_slope <- %s # SD of people's rates of change", r_code(inputs$s_s)),
    sprintf("r_intercept_slope <- %s # correlation of starting level and rate of change", r_code(inputs$r_is)),
    sprintf("sd_residual <- %s # SD around each person's own line", r_code(inputs$s_e)),
    sprintf("retention <- %s # the share still in the study at each occasion", r_code(inputs$retention)),
    sprintf("allocation_ratio <- %s # people in group 2 for each one in group 1", r_code(inputs$ratio)),
    "",
    "# longpower's p: the share whose last occasion is each one.",
    "last_visit <- c(-diff(retention), retention[length(retention)])",
    "",
    "# Hu, Mackey and Thomas's (2021) formula: everyone's data up to their last",
    "# occasion, both groups starting at the same level (a randomised trial).",
    "# longpower's n is group 1's size and lambda = n1 / n2.",
    "power_at <- function(n_total) {",
    "  n1 <- n_total / (1 + allocation_ratio)",
    "  hu.mackey.thomas.linear.power(",
    "    n = n1, delta = abs(slope_difference), t = times, lambda = 1 / allocation_ratio,",
    "    sig2.i = sd_intercept^2, cor.s.i = r_intercept_slope, sig2.s = sd_slope^2, sig2.e = sd_residual^2,",
    sprintf("    p = last_visit, sig.level = alpha, alternative = %s", r_code(if (inputs$alternative == "two_sided") "two.sided" else "one.sided")),
    "  )$power",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}
