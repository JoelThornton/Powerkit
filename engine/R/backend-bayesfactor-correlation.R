# Backend adapter: the Bayes factor test of a Pearson correlation, by exact
# calculation, via BayesFactor and SuppDists.
#
# The Bayes factor is BayesFactor's correlationBF() (Morey & Rouder, the
# package's own citation()), with a stretched beta analysis prior on rho
# of width `prior_width` (correlationBF(rscale = prior_width): rho is
# 2 * Beta(1 / w, 1 / w) - 1). The default width is 1, a uniform prior on
# rho: the default of JASP's Bayesian correlation ("Stretched beta prior
# width" 1, from jaspRegression's bstats::bcor.test(kappa = 1)).
# BayesFactor's own default is rscale = "medium", 1/3. With the same
# width, correlationBF()'s two-sided BF10 equals JASP's (bstats'
# bf10CorExact(), Ly, Marsman & Wagenmakers, 2018) and the Bayes factor
# integrated from the exact density of r; checked in
# test-backend-bayes-correlation.R. A one-sided hypothesis truncates the
# prior to that side, against rho = 0 (correlationBF(nullInterval =
# c(0, 1)), JASP's one-sided test).
#
# The Bayes factor depends on the data only through n and r, and rises
# with r (one-sided) or |r| (two-sided). So the study finds strong
# evidence (BF10 at least the threshold) exactly when r passes a critical
# value, found by root-finding on correlationBF(), and its chance is the
# probability of that r under the true correlation, from the exact
# distribution of the sample correlation of bivariate normal scores
# (SuppDists' pPearson()). No random numbers are drawn.
#
# The design prior is the expected correlation, exactly, or a stretched
# beta distribution with that mean and the SD the planner gives
# (population > r_sd), averaged over by numerical integration.

bfcor_test <- function(spec) bayes_factor_test(spec) && identical(spec$template, "correlation")

bfcor_defaults <- list(prior_width = 1, r_sd = 0)

bfcor_inputs <- function(spec) {
  tt <- spec$target_test
  list(
    r = spec$population$r, r_sd = spec$population$r_sd %||% bfcor_defaults$r_sd,
    threshold = tt$evidence_threshold %||% bayes_defaults$evidence_threshold,
    prior_width = tt$prior_width %||% bfcor_defaults$prior_width,
    alternative = bfpwr_alternative(spec)
  )
}

# n pairs of scores whose sample correlation is exactly r: what
# correlationBF() needs, since it takes data rather than n and r.
bfcor_data <- function(n, r) {
  x <- seq(-1, 1, length.out = n)
  x <- (x - mean(x)) / stats::sd(x)
  e <- sin(seq_len(n) * 1.7)
  e <- stats::residuals(stats::lm(e ~ x))
  e <- e / stats::sd(e)
  list(x = x, y = r * x + sqrt(1 - r^2) * e)
}

# log BF10 with n pairs, two-sided, or rho on the hypothesis' side against
# rho = 0. `s` is the sample correlation on the hypothesis' side: r, or -r
# for "less" (the "less" test at r is the "greater" one at -r).
bfcor_log_bf10 <- function(n, s, inputs) {
  d <- bfcor_data(n, s)
  interval <- if (identical(inputs$alternative, "two.sided")) NULL else c(0, 1)
  bf <- call_backend("BayesFactor", quietly(BayesFactor::correlationBF(
    d$y, d$x, rscale = inputs$prior_width, nullInterval = interval
  )))
  bf@bayesFactor$bf[1]
}

# The correlation on the hypothesis' side where log BF10 crosses
# `log_k`, searched on [lo, 0.98] (BF10 rises with r there). -Inf: every r
# passes; Inf: none does.
bfcor_root <- function(n, log_k, inputs, lo) {
  f <- function(r) bfcor_log_bf10(n, r, inputs) - log_k
  grid <- seq(lo, 0.98, by = 0.07)
  values <- vapply(grid, f, numeric(1))
  if (values[1] >= 0) return(-Inf)
  above <- which(values >= 0)
  if (!length(above)) return(Inf)
  i <- above[1]
  stats::uniroot(f, grid[c(i - 1, i)], f.lower = values[i - 1], f.upper = values[i], tol = 1e-8)$root
}

# The critical values at n, on the hypothesis' side: a correlation at or
# beyond `effect` gives strong evidence for the effect; one short of `null`
# (in |r| for two-sided) gives strong evidence for none.
bfcor_bounds <- function(inputs, n, which = c("effect", "null")) {
  lo <- if (identical(inputs$alternative, "two.sided")) 0 else -0.98
  k <- c(effect = log(inputs$threshold), null = -log(inputs$threshold))
  lapply(stats::setNames(nm = which), function(w) bfcor_root(n, k[[w]], inputs, lo))
}

# The stretched beta design prior with the planner's mean and SD: rho is
# 2 * Beta(a, b) - 1. NULL for exactly r.
bfcor_design_prior <- function(r, r_sd) {
  if (is.null(r_sd) || r_sd == 0) {
    return(NULL)
  }
  m <- (r + 1) / 2
  size <- m * (1 - m) / (r_sd / 2)^2 - 1
  list(a = m * size, b = (1 - m) * size)
}

# P(r at or beyond c on the hypothesis' side) at true correlation rho: r
# >= c for "greater", r <= -c for "less", |r| >= c for two-sided.
# Both tails come from pPearson()'s lower tail, by symmetry (P(r >= c | rho)
# = P(r <= -c | -rho)): its upper tail is less accurate (about 5e-5 at
# n = 100, against the integrated density).
bfcor_beyond <- function(c, n, rho, alternative) {
  if (is.infinite(c)) return(if (c < 0) 1 else 0)
  lower <- function(q, p) SuppDists::pPearson(q, n, p)
  upper <- function(q, p) lower(-q, -p)
  switch(alternative,
    greater = upper(c, rho),
    less = lower(-c, rho),
    two.sided = upper(c, rho) + lower(-c, rho))
}

# The chance at true correlation rho (or averaged over the design prior)
# of a sample correlation on the evidence side of `bounds`.
bfcor_chance <- function(inputs, n, bounds, for_effect, r = inputs$r, r_sd = inputs$r_sd) {
  at <- function(rho) {
    if (for_effect) return(bfcor_beyond(bounds$effect, n, rho, inputs$alternative))
    # Strong evidence for no effect: r short of the null bound.
    1 - bfcor_beyond(bounds$null, n, rho, inputs$alternative)
  }
  design <- bfcor_design_prior(r, r_sd)
  call_backend("SuppDists", if (is.null(design)) {
    at(r)
  } else {
    density <- function(rho) stats::dbeta((rho + 1) / 2, design$a, design$b) / 2
    stats::integrate(function(rho) vapply(rho, at, numeric(1)) * density(rho), -1, 1, rel.tol = 1e-8)$value
  })
}

bfcor_power <- function(inputs, n) {
  bfcor_chance(inputs, n, bfcor_bounds(inputs, n, "effect"), for_effect = TRUE)
}

bfcor_backend <- function(spec, seed = NULL) {
  inputs <- bfcor_inputs(spec)
  power_at <- function(n) bfcor_power(inputs, n)
  list(
    name = "BayesFactor",
    packages = c("BayesFactor", "SuppDists"),
    methods = "exact",
    default_method = "exact",
    functions = c(exact = "BayesFactor::correlationBF"),
    n_step = 1,
    exact_min_n = max(4, minimum_n(spec)),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() bfcor_check_run(spec, inputs)
  )
}

bfcor_null_side <- function(inputs, n) {
  bounds <- bfcor_bounds(inputs, n)
  list(
    evidence_for_null = bfcor_chance(inputs, n, bounds, for_effect = FALSE, r = 0, r_sd = 0),
    misleading_evidence = bfcor_chance(inputs, n, bounds, for_effect = TRUE, r = 0, r_sd = 0)
  )
}

bfcor_check_run <- function(spec, inputs) {
  row <- function(parameter, spec_value, passed) {
    data.frame(parameter = parameter, specified = spec_value, recovered = passed, ok = isTRUE(all.equal(spec_value, passed, tolerance = 1e-6)))
  }
  design <- bfcor_design_prior(inputs$r, inputs$r_sd)
  design_mean <- if (is.null(design)) inputs$r else 2 * design$a / (design$a + design$b) - 1
  design_sd <- if (is.null(design)) 0 else 2 * sqrt(design$a * design$b / ((design$a + design$b)^2 * (design$a + design$b + 1)))
  d <- bfcor_data(100, inputs$r)
  bound <- bfcor_bounds(inputs, 100, "effect")$effect
  rbind(
    row("expected correlation: the mean of the design prior", inputs$r, design_mean),
    row("uncertainty about it: the SD of the stretched beta design prior", inputs$r_sd, design_sd),
    row("the data correlationBF() is given have exactly the correlation r (n = 100)", inputs$r, stats::cor(d$x, d$y)),
    row("BF10 at the critical correlation for n = 100 is the threshold", inputs$threshold,
      if (is.finite(bound)) exp(bfcor_log_bf10(100, bound, inputs)) else inputs$threshold),
    row("width of the stretched beta analysis prior (rscale)", inputs$prior_width, inputs$prior_width)
  )
}

bfcor_hypotheses_words <- function(inputs) {
  switch(inputs$alternative,
    two.sided = "rho = 0 against rho != 0",
    greater = "rho = 0 against rho > 0",
    less = "rho = 0 against rho < 0")
}

# The R script for the correlation Bayes factor: the same calculation at
# each size powerkit computed (export_script()).
bfcor_script <- function(spec, result) {
  inputs <- bfcor_inputs(spec)
  c(
    script_header(spec, result, "BayesFactor", "BayesFactor::correlationBF"),
    "library(BayesFactor)",
    "library(SuppDists)",
    "",
    "# Inputs ----",
    sprintf("r <- %s # the expected correlation", r_code(inputs$r)),
    sprintf("r_sd <- %s # uncertainty about it (SD of a stretched beta design prior; 0 = exactly r)", r_code(inputs$r_sd)),
    sprintf("threshold <- %s # strong evidence: BF10 at least this", r_code(inputs$threshold)),
    sprintf("width <- %s # width of the stretched beta analysis prior (1 = uniform, JASP's default)", r_code(inputs$prior_width)),
    sprintf("alternative <- %s", r_code(inputs$alternative)),
    bayes_goal_inputs(spec),
    "",
    "# correlationBF() takes data: n pairs whose correlation is exactly r.",
    "exact_data <- function(n, r) {",
    "  x <- seq(-1, 1, length.out = n); x <- (x - mean(x)) / sd(x)",
    "  e <- residuals(lm(sin(seq_len(n) * 1.7) ~ x)); e <- e / sd(e)",
    "  list(x = x, y = r * x + sqrt(1 - r^2) * e)",
    "}",
    "# log BF10 at sample correlation s on the hypothesis' side (s = -r for",
    "# 'less': that test at r is the 'greater' one at -r).",
    "log_bf10 <- function(n, s) {",
    "  d <- exact_data(n, s)",
    "  interval <- if (alternative == \"two.sided\") NULL else c(0, 1)",
    "  correlationBF(d$y, d$x, rscale = width, nullInterval = interval)@bayesFactor$bf[1]",
    "}",
    "# BF10 rises with s: the s where it reaches the threshold.",
    "critical_r <- function(n) {",
    "  f <- function(r) log_bf10(n, r) - log(threshold)",
    "  grid <- seq(if (alternative == \"two.sided\") 0 else -0.98, 0.98, by = 0.07)",
    "  values <- vapply(grid, f, numeric(1))",
    "  if (values[1] >= 0) return(-Inf)",
    "  i <- which(values >= 0)[1]",
    "  if (is.na(i)) return(Inf)",
    "  uniroot(f, grid[c(i - 1, i)], tol = 1e-8)$root",
    "}",
    "# The chance of r beyond the critical value, from the exact distribution",
    "# of the sample correlation, averaged over the design prior if r_sd > 0.",
    "power_at <- function(n) {",
    "  c <- critical_r(n)",
    "  # Upper tails by symmetry from pPearson()'s lower tail, the more accurate.",
    "  beyond <- function(rho) {",
    "    if (is.infinite(c)) return(if (c < 0) 1 else 0)",
    "    switch(alternative,",
    "      greater = pPearson(-c, n, -rho),",
    "      less = pPearson(-c, n, rho),",
    "      two.sided = pPearson(-c, n, -rho) + pPearson(-c, n, rho))",
    "  }",
    "  if (r_sd == 0) return(beyond(r))",
    "  m <- (r + 1) / 2; size <- m * (1 - m) / (r_sd / 2)^2 - 1",
    "  density <- function(rho) dbeta((rho + 1) / 2, m * size, (1 - m) * size) / 2",
    "  integrate(function(rho) vapply(rho, beyond, numeric(1)) * density(rho), -1, 1, rel.tol = 1e-8)$value",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}

bfcor_design_description <- function(spec, label) {
  inputs <- bfcor_inputs(spec)
  sprintf(
    "Bayes factor test of the correlation between %s and %s: %s, with a stretched beta analysis prior of width %s; strong evidence is BF10 of at least %s",
    label("X"), label("Y"), bfcor_hypotheses_words(inputs), format_number(inputs$prior_width), format_number(inputs$threshold)
  )
}
