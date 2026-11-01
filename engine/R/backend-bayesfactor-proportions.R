# Backend adapter: the Bayes factor test of two groups' proportions, by
# exact calculation, via BayesFactor.
#
# The Bayes factor is BayesFactor's contingencyTableBF() (Morey & Rouder,
# the package's own citation()) for a 2 x 2 table under independent
# multinomial sampling with the groups' sizes fixed (sampleType =
# "indepMulti", fixedMargin = "rows"), the Gunel and Dickey (1974) Bayes
# factor, with prior concentration a (priorConcentration, default 1).
# These are the defaults of JASP's Bayesian contingency tables ("Indep.
# multinomial, rows fixed", "Prior concentration" 1; jaspFrequencies'
# ContingencyTablesBayesian.qml), which call contingencyTableBF() itself.
#
# For a 2 x 2 table with rows fixed, contingencyTableBF() has a closed
# form (its internal contingencyIndepMultinomial(), read from BayesFactor's
# source): under the alternative each group's proportion has its own
# Beta(a, a) prior, under the null both share a Beta(2a - 1, 2a - 1) one
# (the same Beta(1, 1) at JASP's a = 1), so, with b = 2a - 1,
#   BF10 = B(y1 + a, n1 - y1 + a) B(y2 + a, n2 - y2 + a) B(b, b)
#          / (B(a, a)^2 B(y1 + y2 + b, n1 + n2 - y1 - y2 + b)).
# powerkit scores every possible table with this closed form, because power
# sums over all of them and contingencyTableBF() takes one table at a time;
# test-backend-bayes-proportions.R and the check run confirm it equals
# contingencyTableBF() (decisions.md, 1 November 2026).
#
# A one-sided hypothesis follows JASP: BF+0 = BF10 * P(direction | data,
# alternative) / 0.5, with the posterior probability that group 2's
# proportion is the higher (or the lower) under the alternative's
# independent Beta(y + a, n - y + a) posteriors. JASP estimates that
# probability from 10,000 posterior draws; powerkit integrates it, so
# JASP's one-sided Bayes factor differs from powerkit's by JASP's Monte
# Carlo error (docs/conventions.md, Known difference 13).
#
# Power is the probability of the tables whose BF10 reaches the threshold:
# each group's count is binomial at its expected proportion, or, with an
# uncertainty `p_sd`, beta-binomial (each proportion drawn from a beta
# design prior with that mean and SD; the study's assurance, Departure 15).
# No random numbers are drawn.

bfprop_test <- function(spec) bayes_factor_test(spec) && identical(spec$template, "two_proportions")

bfprop_defaults <- list(prior_concentration = 1, p_sd = 0)

bfprop_inputs <- function(spec) {
  tt <- spec$target_test
  list(
    p1 = spec$population$p1, p2 = spec$population$p2,
    p_sd = spec$population$p_sd %||% bfprop_defaults$p_sd,
    threshold = tt$evidence_threshold %||% bayes_defaults$evidence_threshold,
    a = tt$prior_concentration %||% bfprop_defaults$prior_concentration,
    # "greater": group 2's proportion is the higher, as for the z test.
    alternative = bfpwr_alternative(spec),
    ratio = spec$options$allocation_ratio %||% 1
  )
}

# Group sizes at total n, as the z test splits them (pwr_inputs()).
bfprop_groups <- function(inputs, n) {
  n1 <- round(n / (1 + inputs$ratio))
  c(n1, n - n1)
}

# log BF10, two-sided, for y1 of n1 and each of y2 (a vector) of n2.
bfprop_log_bf10_two <- function(y1, n1, y2, n2, a) {
  b <- 2 * a - 1
  lbeta(y1 + a, n1 - y1 + a) + lbeta(y2 + a, n2 - y2 + a) - 2 * lbeta(a, a) -
    lbeta(y1 + y2 + b, n1 + n2 - y1 - y2 + b) + lbeta(b, b)
}

# The posterior probability, under the alternative, that group 2's
# proportion is above group 1's, for y1 and each of y2, on the log scale,
# with log(1 - P) too: list(above, below). p1 and p2 are independent
# Beta(y + a, n - y + a). With a whole-number a, P(p2 > x) is the chance of
# fewer than y2 + a successes in n2 + 2a - 1 trials at x, so averaging over
# p1, P(p2 > p1) is a beta-binomial lower tail (exact, a finite sum).
# Otherwise each one is integrated numerically.
bfprop_p_above <- function(y1, n1, y2, n2, a, exact = FALSE) {
  a1 <- y1 + a
  b1 <- n1 - y1 + a
  if (!exact && abs(a - round(a)) < 1e-12) {
    m <- n2 + 2 * a - 1
    i <- 0:m
    log_pmf <- lchoose(m, i) + lbeta(a1 + i, b1 + m - i) - lbeta(a1, b1)
    pmf <- exp(log_pmf - max(log_pmf))
    lower <- cumsum(pmf)
    upper <- rev(cumsum(rev(pmf)))
    k <- y2 + a
    shift <- max(log_pmf)
    return(list(above = log(lower[k]) + shift, below = log(upper[k + 1]) + shift))
  }
  p <- vapply(y2, function(y) {
    stats::integrate(function(x) stats::dbeta(x, a1, b1) * stats::pbeta(x, y + a, n2 - y + a, lower.tail = FALSE),
      0, 1, rel.tol = 1e-10, subdivisions = 500L)$value
  }, numeric(1))
  list(above = log(p), below = log1p(-p))
}

# log BF10 for the hypothesis in `inputs` (two-sided, or group 2 higher or
# lower), for y1 and each of y2.
bfprop_log_bf10 <- function(y1, n1, y2, n2, inputs) {
  two <- bfprop_log_bf10_two(y1, n1, y2, n2, inputs$a)
  if (identical(inputs$alternative, "two.sided")) return(two)
  side <- bfprop_p_above(y1, n1, y2, n2, inputs$a)
  two + (if (identical(inputs$alternative, "greater")) side$above else side$below) - log(0.5)
}

# The beta design prior with mean p and SD p_sd, as Beta(alpha, beta).
bfprop_design_prior <- function(p, p_sd) {
  size <- p * (1 - p) / p_sd^2 - 1
  list(a = p * size, b = (1 - p) * size)
}

# The chance of each count 0..n in a group of n at proportion p (binomial),
# or with a beta design prior of SD p_sd (beta-binomial: the binomial
# averaged over the prior).
bfprop_count_probs <- function(n, p, p_sd) {
  y <- 0:n
  if (p_sd == 0) return(stats::dbinom(y, n, p))
  d <- bfprop_design_prior(p, p_sd)
  exp(lchoose(n, y) + lbeta(y + d$a, n - y + d$b) - lbeta(d$a, d$b))
}

# The counts carrying all but a negligible share (below 1e-12) of a group's
# probability: the tables outside them are not scored.
bfprop_support <- function(probs) {
  keep <- which(probs > 1e-15)
  if (!length(keep)) return(integer())
  (min(keep):max(keep)) - 1L
}

# P(BF10 >= threshold) and P(BF10 <= 1 / threshold) at total n, at the
# expected proportions (p1, p2, p_sd), summed over every possible table.
bfprop_chances <- function(inputs, n, p1 = inputs$p1, p2 = inputs$p2, p_sd = inputs$p_sd) {
  g <- bfprop_groups(inputs, n)
  probs1 <- bfprop_count_probs(g[1], p1, p_sd)
  probs2 <- bfprop_count_probs(g[2], p2, p_sd)
  y1s <- bfprop_support(probs1)
  y2s <- bfprop_support(probs2)
  k <- log(inputs$threshold)
  for_effect <- 0
  for_null <- 0
  for (y1 in y1s) {
    lbf <- bfprop_log_bf10(y1, g[1], y2s, g[2], inputs)
    w <- probs1[y1 + 1] * probs2[y2s + 1]
    for_effect <- for_effect + sum(w[lbf >= k])
    for_null <- for_null + sum(w[lbf <= -k])
  }
  c(for_effect = min(1, for_effect), for_null = min(1, for_null))
}

bfprop_power <- function(inputs, n) bfprop_chances(inputs, n)[["for_effect"]]

bfprop_backend <- function(spec, seed = NULL) {
  inputs <- bfprop_inputs(spec)
  step <- valid_n_step(spec)
  power_at <- function(n) call_backend("BayesFactor", bfprop_power(inputs, n))
  list(
    name = "BayesFactor",
    packages = "BayesFactor",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = "BayesFactor::contingencyTableBF"),
    n_step = step,
    exact_min_n = step * ceiling(max(4, minimum_n(spec)) / step),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() bfprop_check_run(spec, inputs)
  )
}

# No effect: both groups at group 1's proportion (as the z test's
# smallest detectable effect keeps group 1's), exactly.
bfprop_null_side <- function(inputs, n) {
  at_null <- bfprop_chances(inputs, n, p2 = inputs$p1, p_sd = 0)
  list(evidence_for_null = at_null[["for_null"]], misleading_evidence = at_null[["for_effect"]])
}

# contingencyTableBF() on one table, as log BF10 (two-sided), or one-sided
# by JASP's rule with the exact posterior probability.
bfprop_package_log_bf10 <- function(y1, n1, y2, n2, inputs) {
  table <- matrix(c(y1, n1 - y1, y2, n2 - y2), 2, byrow = TRUE)
  bf <- call_backend("BayesFactor", quietly(BayesFactor::contingencyTableBF(
    table, sampleType = "indepMulti", fixedMargin = "rows", priorConcentration = inputs$a
  )))
  two <- bf@bayesFactor$bf[1]
  if (identical(inputs$alternative, "two.sided")) return(two)
  side <- bfprop_p_above(y1, n1, y2, n2, inputs$a, exact = TRUE)
  two + (if (identical(inputs$alternative, "greater")) side$above else side$below) - log(0.5)
}

bfprop_check_run <- function(spec, inputs) {
  row <- function(parameter, spec_value, passed) {
    data.frame(parameter = parameter, specified = spec_value, recovered = passed, ok = isTRUE(all.equal(spec_value, passed, tolerance = 1e-6)))
  }
  g <- bfprop_groups(inputs, 100)
  y <- round(g * c(inputs$p1, inputs$p2))
  package <- bfprop_package_log_bf10(y[1], g[1], y[2], g[2], inputs)
  closed <- bfprop_log_bf10(y[1], g[1], y[2], g[2], inputs)
  rows <- list(
    row("group 1's size at a total of 100, from the ratio of group 2's size to group 1's", round(100 / (1 + inputs$ratio)), g[1]),
    row(sprintf("log BF10 for the expected table at n = 100 (%d of %d and %d of %d): powerkit's closed form against contingencyTableBF()",
      y[1], g[1], y[2], g[2]), package, closed),
    row("prior concentration (priorConcentration)", inputs$a, inputs$a)
  )
  if (inputs$p_sd > 0) {
    d <- bfprop_design_prior(inputs$p1, inputs$p_sd)
    rows <- c(rows, list(
      row("uncertainty about group 1's proportion: the SD of its beta design prior", inputs$p_sd,
        sqrt(d$a * d$b / ((d$a + d$b)^2 * (d$a + d$b + 1))))
    ))
  }
  do.call(rbind, rows)
}

bfprop_hypotheses_words <- function(inputs) {
  switch(inputs$alternative,
    two.sided = "p1 = p2 against p1 != p2",
    greater = "p1 = p2 against p2 > p1",
    less = "p1 = p2 against p2 < p1")
}

# The R script for the two-proportion Bayes factor: the same calculation at
# each size powerkit computed (export_script()).
bfprop_script <- function(spec, result) {
  inputs <- bfprop_inputs(spec)
  c(
    script_header(spec, result, "BayesFactor", "BayesFactor::contingencyTableBF"),
    "library(BayesFactor)",
    "",
    "# Inputs ----",
    sprintf("p1 <- %s # the expected proportion of 'yes' in group 1", r_code(inputs$p1)),
    sprintf("p2 <- %s # and in group 2", r_code(inputs$p2)),
    sprintf("p_sd <- %s # uncertainty about each (SD of a beta design prior; 0 = exactly these)", r_code(inputs$p_sd)),
    sprintf("ratio <- %s # group 2's size divided by group 1's", r_code(inputs$ratio)),
    sprintf("threshold <- %s # strong evidence: BF10 at least this", r_code(inputs$threshold)),
    sprintf("a <- %s # prior concentration (JASP's default 1)", r_code(inputs$a)),
    sprintf("alternative <- %s # 'greater': group 2's proportion is the higher", r_code(inputs$alternative)),
    bayes_goal_inputs(spec),
    "",
    "# contingencyTableBF(sampleType = 'indepMulti', fixedMargin = 'rows') for",
    "# a 2 x 2 table, in closed form (Gunel and Dickey's Bayes factor), so",
    "# that every possible table can be scored. Check it on one table:",
    "# contingencyTableBF(matrix(c(30, 20, 18, 32), 2, byrow = TRUE),",
    "#   sampleType = 'indepMulti', fixedMargin = 'rows', priorConcentration = a)",
    "log_bf10_two <- function(y1, n1, y2, n2) {",
    "  b <- 2 * a - 1",
    "  lbeta(y1 + a, n1 - y1 + a) + lbeta(y2 + a, n2 - y2 + a) - 2 * lbeta(a, a) -",
    "    lbeta(y1 + y2 + b, n1 + n2 - y1 - y2 + b) + lbeta(b, b)",
    "}",
    "# One-sided, as JASP: BF10 times the posterior probability of the",
    "# direction over its prior probability, 0.5.",
    "p_above <- function(y1, n1, y2, n2) vapply(y2, function(y) {",
    "  integrate(function(x) dbeta(x, y1 + a, n1 - y1 + a) * pbeta(x, y + a, n2 - y + a, lower.tail = FALSE),",
    "    0, 1, rel.tol = 1e-10, subdivisions = 500L)$value",
    "}, numeric(1))",
    "log_bf10 <- function(y1, n1, y2, n2) {",
    "  two <- log_bf10_two(y1, n1, y2, n2)",
    "  if (alternative == \"two.sided\") return(two)",
    "  p <- p_above(y1, n1, y2, n2)",
    "  if (alternative == \"less\") p <- 1 - p",
    "  two + log(p) - log(0.5)",
    "}",
    "count_probs <- function(n, p) {",
    "  y <- 0:n",
    "  if (p_sd == 0) return(dbinom(y, n, p))",
    "  size <- p * (1 - p) / p_sd^2 - 1",
    "  exp(lchoose(n, y) + lbeta(y + p * size, n - y + (1 - p) * size) - lbeta(p * size, (1 - p) * size))",
    "}",
    "# The chance of a table whose BF10 reaches the threshold, summed over",
    "# every table with a non-negligible chance.",
    "power_at <- function(n) {",
    "  n1 <- round(n / (1 + ratio)); n2 <- n - n1",
    "  probs1 <- count_probs(n1, p1); probs2 <- count_probs(n2, p2)",
    "  y2s <- which(probs2 > 1e-15) - 1",
    "  total <- 0",
    "  for (y1 in which(probs1 > 1e-15) - 1) {",
    "    lbf <- log_bf10(y1, n1, y2s, n2)",
    "    total <- total + sum(probs1[y1 + 1] * probs2[y2s + 1][lbf >= log(threshold)])",
    "  }",
    "  total",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}

bfprop_design_description <- function(spec, label, levels) {
  inputs <- bfprop_inputs(spec)
  sprintf(
    "Bayes factor test of the proportion of %s between %s (%s and %s): %s, contingency table Bayes factor (independent multinomial, group sizes fixed) with prior concentration %s; strong evidence is BF10 of at least %s",
    label("Y"), label("X"), levels("X")[1], levels("X")[2], bfprop_hypotheses_words(inputs),
    format_number(inputs$a), format_number(inputs$threshold)
  )
}
