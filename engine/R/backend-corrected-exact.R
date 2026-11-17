# Continuity-corrected tests of two proportions and of a 2 x 2 table,
# worked out exactly: power is the probability of every possible study
# result times whether R's own test rejects on it, summed over all results.
#
# The test is base R's: stats::prop.test(correct = TRUE) for two groups of
# fixed size, and stats::chisq.test(correct = TRUE) for a 2 x 2 table with
# a fixed total (the same statistic). corrected_prop_p() is that statistic
# and p-value written for many tables at once, checked against prop.test()
# and chisq.test() on every table in test-corrected-exact.R; no
# approximation to power is used. A result whose test can't be computed
# (an empty row or column) counts as not significant, as in the simulated
# route's denominator (corrected_count_rejections()).
#
# Power goes up and down with n for tests of counts, so the sample-size
# search checks every n below the bisection's answer (`sawtooth`), as for
# the exact binomial test. Simulation stays available (options > method
# "simulation"), with the fresh confirmation checks of confirm_count_search().

# The continuity-corrected test's statistic for the tables (x1 of n1, x2
# of n2), vectorised over x1, x2, n1 and n2, with the sign of p1hat -
# p2hat. As stats::prop.test(): the correction is min(0.5, |x1 - n1 * s /
# N|), and the statistic sums (|O - E| - correction)^2 / E over the four
# cells. NaN where a row or column is empty (no test).
corrected_prop_statistic <- function(x1, x2, n1, n2) {
  total <- n1 + n2
  s <- x1 + x2
  f <- total - s
  deviation <- abs(x1 - n1 * s / total)
  statistic <- (deviation - pmin(0.5, deviation))^2 * total^3 / (n1 * n2 * s * f)
  list(statistic = statistic, sign = sign(x1 / n1 - x2 / n2))
}

# p-values as prop.test() gives them: two-sided, the chi-square upper tail
# on 1 df; one-sided, the normal tail of sign * sqrt(statistic).
# `alternative` is prop.test's (about p1 - p2).
corrected_prop_p <- function(x1, x2, n1, n2, alternative = "two.sided") {
  st <- corrected_prop_statistic(x1, x2, n1, n2)
  if (identical(alternative, "two.sided")) {
    stats::pchisq(st$statistic, 1, lower.tail = FALSE)
  } else {
    stats::pnorm(st$sign * sqrt(st$statistic), lower.tail = identical(alternative, "less"))
  }
}

# Whether the test rejects at alpha, from the statistic against the same
# critical value (faster than a p-value for every table; the same decision).
corrected_prop_reject <- function(x1, x2, n1, n2, alpha, alternative = "two.sided") {
  st <- corrected_prop_statistic(x1, x2, n1, n2)
  ok <- is.finite(st$statistic)
  if (identical(alternative, "two.sided")) {
    ok & st$statistic > stats::qchisq(alpha, 1, lower.tail = FALSE)
  } else {
    z <- st$sign * sqrt(st$statistic)
    ok & if (identical(alternative, "less")) z < stats::qnorm(alpha) else z > stats::qnorm(alpha, lower.tail = FALSE)
  }
}

# The counts that carry all but a negligible share of a binomial's
# probability: below `tail` in each tail is left out (1e-10 by default, so
# power is exact to about 1e-9).
binomial_support <- function(n, p, tail = 1e-10) {
  if (p <= 0) return(0L)
  if (p >= 1) return(as.integer(n))
  seq.int(stats::qbinom(tail, n, p), stats::qbinom(tail, n, p, lower.tail = FALSE))
}

# The probability that the corrected test rejects with groups n1 and n2
# whose true proportions are p1 and p2: each pair of counts' probability
# times whether the test rejects on it. Attribute "covered": the
# probability of the pairs of counts summed over.
corrected_reject_probability <- function(n1, n2, p1, p2, alpha, alternative = "two.sided", tail = 1e-10) {
  if (n1 < 1 || n2 < 1) return(structure(0, covered = 1))
  x1 <- binomial_support(n1, p1, tail)
  x2 <- binomial_support(n2, p2, tail)
  w1 <- stats::dbinom(x1, n1, p1)
  w2 <- stats::dbinom(x2, n2, p2)
  reject <- matrix(corrected_prop_reject(rep(x1, times = length(x2)), rep(x2, each = length(x1)), n1, n2, alpha, alternative), length(x1))
  structure(sum(w1 * (reject %*% w2)), covered = sum(w1) * sum(w2))
}

# Exact power of the corrected two-proportion test with groups n1 and n2.
corrected_prop_power <- function(n1, n2, p1, p2, alpha, alternative = "two.sided") {
  as.numeric(corrected_reject_probability(n1, n2, p1, p2, alpha, alternative))
}

# Exact power of the corrected 2 x 2 chi-square test with a fixed total n
# and cell probabilities P (rows the X groups): the row totals are
# binomial, and given them each row's first column is binomial. A table
# with an empty row has no test and counts as not significant. With a
# larger `tail`, a quick lower and upper bound: the power over the tables
# summed, and that plus the probability of the tables left out.
corrected_table_power <- function(n, P, alpha, tail = 1e-10, bounds = FALSE) {
  row1 <- sum(P[1, ])
  q1 <- P[1, 1] / row1
  q2 <- P[2, 1] / sum(P[2, ])
  r <- binomial_support(n, row1, tail)
  wr <- stats::dbinom(r, n, row1)
  each <- lapply(r, function(n1) corrected_reject_probability(n1, n - n1, q1, q2, alpha, tail = tail))
  power <- sum(wr * vapply(each, as.numeric, numeric(1)))
  if (!bounds) return(power)
  covered <- sum(wr * vapply(each, attr, numeric(1), "covered"))
  c(lower = power, upper = power + (1 - covered))
}

# The exact route (the default). options > method "simulation" goes to
# spower_backend() instead (route.R), with the fresh confirmation checks of
# confirm_count_search().
corrected_exact_backend <- function(spec, seed = NULL) {
  pop <- spec$population
  alpha <- spec$target_test$alpha
  two_groups <- identical(spec$template, "two_proportions")
  ratio <- allocation_ratio(spec)
  alternative <- spower_alternative(spec$template, spec$target_test$alternative %||% "two_sided")
  power_at <- if (two_groups) {
    function(n) {
      n1 <- floor(n / (1 + ratio) + 0.5)
      corrected_prop_power(n1, n - n1, pop$p1, pop$p2, alpha, alternative)
    }
  } else {
    P <- probability_matrix(spec)
    function(n) corrected_table_power(n, P, alpha)
  }
  # A quick upper bound on the 2 x 2 test's power (the tables beyond 1e-4
  # in each tail counted as significant), to skip totals that can't reach
  # the target without working them out exactly.
  power_upper <- if (!two_groups) function(n) corrected_table_power(n, P, alpha, tail = 1e-4, bounds = TRUE)[["upper"]]
  step <- valid_n_step(spec)
  description <- if (two_groups) {
    sprintf("exact sum over every possible result of stats::prop.test(correct = TRUE%s), groups of fixed size",
      if (identical(alternative, "two.sided")) "" else sprintf(", alternative = \"%s\"", alternative))
  } else {
    "exact sum over every possible 2 x 2 table of stats::chisq.test(correct = TRUE), the total fixed"
  }
  list(
    name = "stats",
    packages = "stats",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = description),
    n_step = step,
    exact_min_n = step * ceiling(max(minimum_n(spec), 2) / step),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    sawtooth = TRUE,
    # The 2 x 2 test's power takes up to a second at each n, so the search
    # walks down from the bisection's answer only until power is 0.03 below
    # the target, twice the largest dip measured: at most 0.015
    # where power is above 0.3, over totals 10 to 300 for four tables from
    # a strong to a weak, rare association (test-corrected-exact.R checks
    # the walk against every smaller n). The two-group test is fast enough
    # to check every smaller n.
    sawtooth_window = if (!two_groups) 0.03,
    power_upper = power_upper,
    check_run = function() data.frame(parameter = character(), specified = numeric(), recovered = numeric(), ok = logical())
  )
}

# The standalone script for the exact route: the same functions, written
# out in full so the script needs only base R, then the goal as for other
# exact tests of counts.
corrected_exact_script <- function(spec, result) {
  backend <- corrected_exact_backend(spec)
  define <- function(name) c(paste(name, "<-", paste(deparse(get(name, mode = "function"), width.cutoff = 100L), collapse = "\n")), "")
  two_groups <- identical(spec$template, "two_proportions")
  alternative <- spower_alternative(spec$template, spec$target_test$alternative %||% "two_sided")
  c(
    script_header(spec, result, "stats", backend$functions[["exact"]]),
    "# Power is the probability of every possible result of the study times",
    "# whether R's continuity-corrected test rejects on it, summed: no",
    "# simulation, so no random error. The functions below give the test's",
    "# decision for many tables at once; on any one table it is the same as",
    if (two_groups) "# stats::prop.test(c(x1, x2), c(n1, n2), correct = TRUE)." else "# stats::chisq.test(table, correct = TRUE).",
    "",
    define("corrected_prop_statistic"), define("corrected_prop_reject"), define("binomial_support"),
    define("corrected_reject_probability"),
    if (two_groups) define("corrected_prop_power") else define("corrected_table_power"),
    goal_inputs(spec, result),
    if (two_groups) c(
      sprintf("p1 <- %s # proportion in group 1", r_code(spec$population$p1)),
      sprintf("p2 <- %s # proportion in group 2", r_code(spec$population$p2)),
      sprintf("allocation_ratio <- %s # group 2's size relative to group 1's", r_code(allocation_ratio(spec))),
      sprintf("alternative <- \"%s\" # prop.test's direction, about p1 - p2", alternative),
      "power_at <- function(n) {",
      "  n1 <- floor(n / (1 + allocation_ratio) + 0.5)",
      "  corrected_prop_power(n1, n - n1, p1, p2, alpha, alternative)",
      "}"
    ) else c(
      sprintf("P <- matrix(%s, nrow = 2, byrow = TRUE) # cell proportions, rows the groups", r_code(as.vector(t(probability_matrix(spec))))),
      "power_at <- function(n) corrected_table_power(n, P, alpha)"
    ),
    "",
    if (identical(spec$goal$type, "sample_size")) sawtooth_goal_section(spec, result) else pwr_goal_section(spec, result),
    comparison_section()
  )
}
