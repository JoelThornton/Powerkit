# Backend adapter: the Bayes factor for R-squared in a linear multiple
# regression (is R-squared greater than 0?), by exact calculation, via
# BayesFactor.
#
# The Bayes factor is BayesFactor's linear-regression Bayes factor of the
# model with all the predictors against the intercept-only model (Liang,
# Paulo, Molina, Clyde & Berger, 2008; Rouder & Morey, "Bayesian testing in
# regression", the references in regressionBF()'s help): the JZS prior, a Cauchy prior
# of scale r on the standardised coefficients. It depends on the data only
# through R-squared, the sample size and the number of predictors, and
# BayesFactor computes it from them with linearReg.R2stat(N, p, R2, rscale),
# which gives the same value as regressionBF() or lmBF() on the data
# (checked in the check run and in test-backend-bayes-regression.R). JASP's
# Bayesian linear regression uses the JZS prior with an r scale of 0.354
# by default ("r scale", jaspRegression's
# inst/qml/RegressionLinearBayesian.qml), BayesFactor's "medium" scale for
# continuous predictors (sqrt(2) / 4), so 0.354 is powerkit's default too.
#
# BF10 rises with R-squared, so BF10 reaches the threshold exactly when
# R-squared, or equivalently the F statistic of the regression, reaches
# the value at which BF10 equals it. Power is the probability of that F:
# the noncentral F with p and n - p - 1 df and noncentrality f^2 n, Cohen's
# f^2 = R2 / (1 - R2), as for the F test (pwrss's power.f.regression(),
# G*Power's "linear multiple regression: R2 deviation from zero"). No
# random numbers are drawn.

bfreg_test <- function(spec) {
  bayes_factor_test(spec) && identical(spec$design, "multiple_regression") && identical(spec$template, "r2_zero")
}

bfreg_defaults <- list(prior_scale = 0.354)

bfreg_inputs <- function(spec) {
  pop <- spec$population
  list(
    r2 = pop$r2, p = as.integer(pop$predictors),
    f2 = pop$r2 / (1 - pop$r2),
    threshold = bayes_threshold(spec),
    prior_scale = spec$target_test$prior_scale %||% bfreg_defaults$prior_scale
  )
}

# The R-squared of an F statistic `f_stat` with p and n - p - 1 df, and the
# other way round.
bfreg_r2_of_f <- function(f_stat, n, p) {
  f_stat * p / (f_stat * p + n - p - 1)
}

bfreg_f_of_r2 <- function(r2, n, p) {
  (r2 / p) / ((1 - r2) / (n - p - 1))
}

# log BF10 for the F statistic(s) `f_stat` at total sample size n.
bfreg_log_bf10 <- function(f_stat, n, inputs) {
  vapply(f_stat, function(x) {
    BayesFactor::linearReg.R2stat(N = n, p = inputs$p, R2 = bfreg_r2_of_f(x, n, inputs$p),
      rscale = inputs$prior_scale, simple = FALSE)[["bf"]]
  }, numeric(1))
}

# The F at which log BF10 equals `log_target`, or NA when no F reaches it
# (BF10 at F = 0 is already above it, for evidence for no effect).
bfreg_f_at <- function(log_target, n, inputs) {
  g <- function(x) bfreg_log_bf10(x, n, inputs) - log_target
  if (g(0) >= 0) return(NA_real_)
  upper <- 10
  while (g(upper) < 0) upper <- upper * 2
  stats::uniroot(g, c(0, upper), tol = 1e-10)$root
}

bfreg_df <- function(inputs, n) c(inputs$p, n - inputs$p - 1)

# The chance of strong evidence for an effect at total n, for an effect of
# size f2 (the spec's, by default).
bfreg_power <- function(inputs, n, f2 = inputs$f2) {
  f_star <- bfreg_f_at(log(inputs$threshold), n, inputs)
  if (is.na(f_star)) return(1)
  df <- bfreg_df(inputs, n)
  stats::pf(f_star, df[1], df[2], ncp = f2 * n, lower.tail = FALSE)
}

bfreg_backend <- function(spec, seed = NULL) {
  inputs <- bfreg_inputs(spec)
  power_at <- function(n) call_backend("BayesFactor", bfreg_power(inputs, n))
  list(
    name = "BayesFactor",
    packages = "BayesFactor",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = "BayesFactor::linearReg.R2stat"),
    n_step = 1L,
    exact_min_n = max(inputs$p + 3L, minimum_n(spec)),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() bfreg_check_run(spec, inputs)
  )
}

# No effect: the central F. Strong evidence for no effect is BF10 at most
# 1 / threshold (F at most the F where BF10 is that); misleading evidence is
# BF10 reaching the threshold.
bfreg_null_side <- function(inputs, n) {
  df <- bfreg_df(inputs, n)
  f_null <- bfreg_f_at(-log(inputs$threshold), n, inputs)
  list(
    evidence_for_null = if (is.na(f_null)) 0 else stats::pf(f_null, df[1], df[2]),
    misleading_evidence = bfreg_power(inputs, n, f2 = 0)
  )
}

bfreg_hypotheses_words <- function(inputs) {
  sprintf("R-squared of the %d predictors equal to 0 against greater than 0", inputs$p)
}

# A data set of size n whose regression has exactly R-squared r2 with p
# predictors: orthonormal, centred predictors and residuals (orthogonal
# polynomials, so no random numbers), scaled so that the predictors explain
# r2 of the outcome's variance.
bfreg_exact_data <- function(n, p, r2) {
  z <- stats::poly(seq_len(n), p + 1)
  x <- z[, seq_len(p), drop = FALSE]
  e <- z[, p + 1]
  y <- sqrt(r2) * rowSums(x) / sqrt(p) + sqrt(1 - r2) * e
  data.frame(y = y, x)
}

# Check run: regressionBF() on a data set with exactly the spec's R-squared
# (60 cases) gives the Bayes factor linearReg.R2stat() gives from its F,
# and R-squared is recovered from the data.
bfreg_check_run <- function(spec, inputs) {
  n <- max(60L, inputs$p + 10L)
  data <- bfreg_exact_data(n, inputs$p, inputs$r2)
  fit <- stats::lm(y ~ ., data = data)
  r2 <- summary(fit)$r.squared
  package <- call_backend("BayesFactor", quietly(BayesFactor::lmBF(
    stats::as.formula(paste("y ~", paste(setdiff(names(data), "y"), collapse = " + "))),
    data = data, rscaleCont = inputs$prior_scale, progress = FALSE
  )))
  from_f <- bfreg_log_bf10(bfreg_f_of_r2(r2, n, inputs$p), n, inputs)
  row <- function(parameter, spec_value, got, tolerance = 1e-6) {
    data.frame(parameter = parameter, specified = spec_value, recovered = got, ok = isTRUE(all.equal(spec_value, got, tolerance = tolerance)))
  }
  rbind(
    row(sprintf("R-squared of a data set built to have it exactly (%d cases)", n), inputs$r2, r2),
    row("log BF10 for that data set: lmBF() against linearReg.R2stat() from its F", BayesFactor::extractBF(package, logbf = TRUE)$bf[1], from_f, tolerance = 1e-4),
    row("r scale of the Cauchy prior on the standardised coefficients (rscaleCont)", inputs$prior_scale, inputs$prior_scale)
  )
}

# Spec checks for the Bayes factor for R-squared: no direction, and no
# Bayes factor setting that belongs to another test.
check_bayes_regression <- function(spec) {
  problems <- character()
  tt <- spec$target_test
  if (!is.null(tt$prior_width) || !is.null(tt$prior_a) || !is.null(tt$prior_b) || !is.null(tt$one_sided_null)) {
    problems <- c(problems, "The Bayes factor for R-squared has a Cauchy prior on the coefficients, set by 'target_test > prior_scale'; remove 'prior_width', 'prior_a', 'prior_b' and 'one_sided_null'.")
  }
  if (!is.null(spec$population$effect_sd)) {
    problems <- c(problems, "'population > effect_sd' isn't used by the Bayes factor for R-squared: the effect is the R-squared given.")
  }
  problems
}

# The R script for the Bayes factor for R-squared: the same calculation at
# each size powerkit computed (export_script()).
bfreg_script <- function(spec, result) {
  inputs <- bfreg_inputs(spec)
  c(
    script_header(spec, result, "BayesFactor", "BayesFactor::linearReg.R2stat"),
    "library(BayesFactor)",
    "",
    "# Inputs ----",
    sprintf("r2 <- %s # the expected R-squared of the model with all the predictors", r_code(inputs$r2)),
    sprintf("p <- %s # the number of predictors", r_code(inputs$p)),
    sprintf("threshold <- %s # strong evidence: BF10 at least this", r_code(inputs$threshold)),
    sprintf("rscale <- %s # r scale of the Cauchy prior on the standardised coefficients (JASP's default 0.354)", r_code(inputs$prior_scale)),
    bayes_goal_inputs(spec),
    "",
    "f2 <- r2 / (1 - r2) # Cohen's f-squared",
    "# BF10 from the F statistic of the regression at total sample size n:",
    "# the value regressionBF() or lmBF(rscaleCont = rscale) gives on the data.",
    "log_bf10 <- function(F, n) {",
    "  R2 <- F * p / (F * p + n - p - 1)",
    "  linearReg.R2stat(N = n, p = p, R2 = R2, rscale = rscale, simple = FALSE)[[\"bf\"]]",
    "}",
    "# BF10 rises with F: the F at which it reaches the threshold, and the",
    "# chance of an F at least that large (the noncentral F, as for the F test).",
    "power_at <- function(n_total) {",
    "  g <- function(F) log_bf10(F, n_total) - log(threshold)",
    "  if (g(0) >= 0) return(1)",
    "  upper <- 10",
    "  while (g(upper) < 0) upper <- upper * 2",
    "  f_star <- uniroot(g, c(0, upper), tol = 1e-10)$root",
    "  pf(f_star, p, n_total - p - 1, ncp = f2 * n_total, lower.tail = FALSE)",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}

bfreg_design_description <- function(spec, label) {
  inputs <- bfreg_inputs(spec)
  sprintf(
    "Bayes factor for R-squared in a linear regression of %s on %d predictors: %s, BayesFactor's linear-regression Bayes factor (JZS) with a Cauchy prior of r scale %s on the standardised coefficients; strong evidence is BF10 of at least %s",
    label("Y"), inputs$p, bfreg_hypotheses_words(inputs),
    format_number(inputs$prior_scale), format_number(inputs$threshold)
  )
}
