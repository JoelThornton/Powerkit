# Backend adapter: the Bayes factor for an R-squared increase, or for one
# coefficient, in a linear multiple regression, simulated, via
# BayesFactor.
#
# The Bayes factor compares the model with all p predictors against the
# model without the q tested ones (docs/decisions.md, 15 November 2026):
# the comparison BayesFactor's regressionBF(whichModels = "top") reports,
# and the direct analogue of the F test of the increase. Each model's
# Bayes factor against the intercept-only model is BayesFactor's JZS
# linear-regression Bayes factor (Liang, Paulo, Molina, Clyde & Berger,
# 2008; Rouder & Morey, "Bayesian testing in regression", the references
# in regressionBF()'s help), with a Cauchy prior of r scale 0.354 on the
# standardised coefficients (JASP's default, BayesFactor's "medium"), and
# depends on the data only through that model's R-squared, so
# linearReg.R2stat(N, p, R2, rscale) gives it; the ratio of the two is the
# Bayes factor of the full model against the reduced one, which lmBF()
# gives on the data (checked in the check run and in
# test-backend-bayes-r2change.R).
#
# One simulated study needs only its two R-squared values. With fixed
# predictors, as for the F test (G*Power's "R-squared increase"), the sum
# of squares the reduced model explains, the sum the tested set adds and
# the residual sum are independent: noncentral chi-squares with p - q, q
# and n - p - 1 df, in units of the error variance (1 - R2 full), with
# noncentralities n R2 reduced / (1 - R2 full) and n (R2 full - R2
# reduced) / (1 - R2 full) (the F test's, Cohen's f-squared times n).
# R-squared full is the first two over the total, and R-squared reduced
# the first over it. With measured predictors, the default since 22
# November 2026 (Departure 39), the two noncentralities vary from study
# to study as the predictors do, and each study draws them first
# (regression_measured_draw(), regression-measured.R); predictors set by
# the design (target_test > predictor_model "fixed") keep the fixed draw. Each study's two log Bayes factors come from
# linearReg.R2stat(), interpolated (cubic spline) from its values at 64
# R-squared values spanning the batch's simulated studies (even steps in
# their log odds), which agrees with calling it for every study to 1e-3
# on the log scale, 0.1% of the Bayes factor (test-backend-bayes-r2change.R). Power is the share of studies whose
# Bayes factor reaches the threshold.

bfr2c_templates <- c("r2_increase", "single_coefficient")

bfr2c_test <- function(spec) {
  bayes_factor_test(spec) && identical(spec$design, "multiple_regression") && isTRUE(spec$template %in% bfr2c_templates)
}

bfr2c_inputs <- function(spec) {
  pop <- spec$population
  coefficient <- identical(spec$template, "single_coefficient")
  r2_reduced <- pop$r2_reduced %||% 0
  r2_full <- if (coefficient) r2_reduced + pop$partial_r2 * (1 - r2_reduced) else pop$r2_full
  list(
    coefficient = coefficient,
    r2_full = r2_full, r2_reduced = r2_reduced,
    p = as.integer(pop$predictors_total),
    q = if (coefficient) 1L else as.integer(pop$predictors_tested),
    threshold = bayes_threshold(spec),
    prior_scale = spec$target_test$prior_scale %||% bfreg_defaults$prior_scale,
    measured = regression_measured(spec)
  )
}

# log BF10 of a model with k predictors against the intercept-only model,
# for the R-squared values r2, at sample size n: linearReg.R2stat() at 64
# values spanning them (even steps in R-squared's log odds), interpolated
# by a cubic spline
# (exact for fewer than 64 distinct values).
bfr2c_log_bf <- function(r2, n, k, prior_scale) {
  if (k == 0) return(rep(0, length(r2)))
  exact <- function(x) vapply(x, function(v) BayesFactor::linearReg.R2stat(N = n, p = k, R2 = v,
    rscale = prior_scale, simple = FALSE)[["bf"]], numeric(1))
  distinct <- unique(r2)
  if (length(distinct) <= 64) return(exact(distinct)[match(r2, distinct)])
  # Even steps in the log odds of R-squared, where the log Bayes factor is
  # close to a straight line at large R-squared.
  grid <- stats::plogis(seq(stats::qlogis(min(r2)), stats::qlogis(max(r2)), length.out = 64))
  stats::splinefun(stats::qlogis(grid), exact(grid), method = "fmm")(stats::qlogis(r2))
}

# The two R-squared values of nrep studies of size n: with measured
# predictors, or with fixed ones.
bfr2c_draw <- function(inputs, n, nrep, r2_full = inputs$r2_full) {
  if (isTRUE(inputs$measured)) {
    return(regression_measured_draw(n, nrep, inputs$p, inputs$q, r2_full, inputs$r2_reduced))
  }
  error <- 1 - r2_full
  reduced_df <- inputs$p - inputs$q
  a <- if (reduced_df > 0) stats::rchisq(nrep, reduced_df, ncp = n * inputs$r2_reduced / error) else rep(0, nrep)
  b <- stats::rchisq(nrep, inputs$q, ncp = n * (r2_full - inputs$r2_reduced) / error)
  e <- stats::rchisq(nrep, n - inputs$p - 1)
  total <- a + b + e
  list(full = (a + b) / total, reduced = a / total)
}

# log BF10 of the full model against the reduced one, for drawn studies.
bfr2c_study_log_bf <- function(inputs, n, r2) {
  bfr2c_log_bf(r2$full, n, inputs$p, inputs$prior_scale) -
    bfr2c_log_bf(r2$reduced, n, inputs$p - inputs$q, inputs$prior_scale)
}

# Studies (of nrep) whose Bayes factor reaches the threshold ("effect") or
# whose reciprocal does ("null"), with the tested predictors adding
# r2_full - r2_reduced (r2_full = r2_reduced for no effect).
bfr2c_count <- function(inputs, n, nrep, seed, r2_full = inputs$r2_full, outcome = "effect") {
  with_seed(seed, {
    r2 <- bfr2c_draw(inputs, n, nrep, r2_full)
    log_bf <- call_backend("BayesFactor", bfr2c_study_log_bf(inputs, n, r2))
  })
  if (identical(outcome, "effect")) sum(log_bf >= log(inputs$threshold)) else sum(log_bf <= -log(inputs$threshold))
}

bfr2c_function <- function(inputs) {
  paste0(
    "BayesFactor::linearReg.R2stat() for the full and the reduced model, on each simulated study's two R-squared values",
    if (isTRUE(inputs$measured)) ", with predictors measured on each person (drawn afresh in each study, Shieh 2007)" else ""
  )
}

bfr2c_backend <- function(spec, seed = NULL) {
  inputs <- bfr2c_inputs(spec)
  list(
    name = "BayesFactor",
    packages = "BayesFactor",
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = bfr2c_function(inputs)),
    n_step = 1L,
    exact_min_n = max(inputs$p + 3L, minimum_n(spec)),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) bfr2c_count(inputs, n, k, chunk_seed))
    },
    null_side = function(n, nrep, seed) bfr2c_null_side(inputs, n, nrep, seed),
    sensitivity = NULL,
    check_run = function() bfr2c_check_run(spec, inputs, seed)
  )
}

# No effect: the tested predictors add nothing (R-squared full equal to
# reduced), the other predictors unchanged.
bfr2c_null_side <- function(inputs, n, nrep, seed) {
  list(
    evidence_for_null = bfr2c_count(inputs, n, nrep, seed + 1L, r2_full = inputs$r2_reduced, outcome = "null") / nrep,
    misleading_evidence = bfr2c_count(inputs, n, nrep, seed + 2L, r2_full = inputs$r2_reduced) / nrep,
    null_nrep = nrep
  )
}

bfr2c_hypotheses_words <- function(inputs) {
  if (inputs$coefficient) {
    return(sprintf("the model with all %d predictors against the model without the tested predictor", inputs$p))
  }
  sprintf("the model with all %d predictors against the model without the %d tested %s", inputs$p, inputs$q,
    if (inputs$q == 1) "predictor" else "predictors")
}

# A data set of size n with fixed, orthonormal predictors whose full and
# reduced models have exactly the given R-squared values (orthogonal
# polynomials, so no random numbers): the first p - q predictors carry the
# reduced model's share, the tested ones the increase.
bfr2c_exact_data <- function(n, p, q, r2_full, r2_reduced) {
  z <- stats::poly(seq_len(n), p + 1)
  x <- z[, seq_len(p), drop = FALSE]
  e <- z[, p + 1]
  kept <- seq_len(p - q)
  tested <- setdiff(seq_len(p), kept)
  y <- (if (length(kept)) sqrt(r2_reduced) * rowSums(x[, kept, drop = FALSE]) / sqrt(length(kept)) else 0) +
    sqrt(r2_full - r2_reduced) * rowSums(x[, tested, drop = FALSE]) / sqrt(q) + sqrt(1 - r2_full) * e
  data.frame(y = y, x)
}

# Check run: on a data set built to have exactly the spec's two R-squared
# values (60 cases or more), lmBF()'s Bayes factor of the full model over
# the reduced one equals the one the simulation computes from R-squared.
bfr2c_check_run <- function(spec, inputs, seed) {
  n <- max(60L, inputs$p + 10L)
  data <- bfr2c_exact_data(n, inputs$p, inputs$q, inputs$r2_full, inputs$r2_reduced)
  names(data)[-1] <- paste0("x", seq_len(inputs$p))
  kept <- names(data)[1L + seq_len(inputs$p - inputs$q)]
  fit <- function(terms) summary(stats::lm(stats::reformulate(if (length(terms)) terms else "1", "y"), data = data))$r.squared
  r2 <- list(full = fit(names(data)[-1]), reduced = if (length(kept)) fit(kept) else 0)
  bf <- function(terms) {
    if (!length(terms)) return(0)
    BayesFactor::extractBF(quietly(BayesFactor::lmBF(stats::reformulate(terms, "y"), data = data,
      rscaleCont = inputs$prior_scale, progress = FALSE)), logbf = TRUE)$bf[1]
  }
  package <- call_backend("BayesFactor", bf(names(data)[-1]) - bf(kept))
  from_r2 <- call_backend("BayesFactor", bfr2c_study_log_bf(inputs, n, list(full = r2$full, reduced = r2$reduced)))
  row <- function(parameter, specified, recovered, tolerance = 1e-6) {
    data.frame(parameter = parameter, specified = specified, recovered = recovered,
      ok = isTRUE(all.equal(specified, recovered, tolerance = tolerance)))
  }
  rbind(
    row(sprintf("R-squared of the full model, data set built to have it exactly (%d cases)", n), inputs$r2_full, r2$full),
    row("R-squared without the tested predictors, same data set", inputs$r2_reduced, r2$reduced),
    row("log BF of the full model over the reduced one: lmBF() against linearReg.R2stat() from the two R-squared values", package, from_r2, tolerance = 1e-4)
  )
}

# Spec checks for these Bayes factors: R-squared without the tested
# predictor for one coefficient, and no setting of another test.
check_bayes_r2change <- function(spec) {
  problems <- check_bayes_regression(spec)
  pop <- spec$population
  if (identical(spec$template, "single_coefficient")) {
    if (is.null(pop$r2_reduced)) {
      problems <- c(problems, paste(
        "The Bayes factor for one coefficient compares the model with all the predictors against the model without the tested one,",
        "and depends on both models' R-squared: give 'population > r2_reduced', the R-squared of the outcome on the other predictors (0 if there are none)."))
    }
    if (!is.null(pop$variance_ratio) || !is.null(pop$error_shape) || !is.null(pop$quantile)) {
      problems <- c(problems, "The Bayes factor for one coefficient assumes normal errors with the same spread everywhere; remove 'variance_ratio', 'error_shape' and 'quantile'.")
    }
  }
  if (!is.null(pop$r2_reduced) && pop$predictors_total == (if (identical(spec$template, "single_coefficient")) 1 else pop$predictors_tested %||% 0) && pop$r2_reduced > 0) {
    problems <- c(problems, "With no other predictors, 'population > r2_reduced' must be 0.")
  }
  problems
}

bfr2c_design_description <- function(spec, label) {
  inputs <- bfr2c_inputs(spec)
  sprintf(
    "Bayes factor for %s in a linear regression of %s, predictors %s: %s, the ratio of BayesFactor's linear-regression Bayes factors (JZS) with a Cauchy prior of r scale %s on the standardised coefficients, as regressionBF(whichModels = \"top\") reports it; R-squared %s with all the predictors and %s without the tested %s; the evidence threshold is BF10 of at least %s",
    if (inputs$coefficient) sprintf("the coefficient of %s", label("X")) else "an R-squared increase",
    label("Y"), regression_predictors_words(inputs$measured), bfr2c_hypotheses_words(inputs), format_number(inputs$prior_scale),
    format_number(inputs$r2_full), format_number(inputs$r2_reduced), if (inputs$q == 1) "predictor" else "predictors",
    format_number(inputs$threshold)
  )
}

# The R script: the same simulation at each size powerkit computed.
bfr2c_script <- function(spec, result) {
  inputs <- bfr2c_inputs(spec)
  prov <- result$provenance
  c(
    script_header(spec, result, "BayesFactor", bfr2c_function(inputs)),
    "library(BayesFactor)",
    "",
    "# Inputs ----",
    sprintf("r2_full <- %s # R-squared with all the predictors", r_code(inputs$r2_full)),
    sprintf("r2_reduced <- %s # R-squared without the tested predictor(s)", r_code(inputs$r2_reduced)),
    sprintf("p <- %s # predictors in the full model", r_code(inputs$p)),
    sprintf("q <- %s # predictors tested", r_code(inputs$q)),
    sprintf("threshold <- %s # evidence threshold: BF10 at least this", r_code(inputs$threshold)),
    sprintf("rscale <- %s # r scale of the Cauchy prior on the standardised coefficients (the package default, 0.354)", r_code(inputs$prior_scale)),
    bayes_goal_inputs(spec),
    sprintf("replications <- %s # simulated studies per sample size", r_code(prov$nrep)),
    sprintf("seed <- %s # powerkit's seed for this run", r_code(prov$seed)),
    "",
    "# log BF10 of a model with k predictors against none, from its R-squared:",
    "# the value regressionBF() or lmBF(rscaleCont = rscale) gives on the data.",
    "# Interpolated from 64 exact values, as powerkit does, to save time.",
    paste("log_bf <-", paste(deparse(bfr2c_log_bf, width.cutoff = 100L), collapse = "\n")),
    "",
    bfr2c_script_draw(inputs),
    "  bf <- log_bf((a + b) / total, batch_n, p, rscale) - log_bf(a / total, batch_n, p - q, rscale)",
    "  c(sum(bf >= log(threshold)), batch_replications)",
    "}",
    "",
    batch_section(result, "the simulation"),
    simulation_goal_section(spec, result, 1L),
    comparison_section()
  )
}

# The script's batch of simulated studies: fixed or measured predictors,
# drawn as the engine draws them.
bfr2c_script_draw <- function(inputs) {
  if (!isTRUE(inputs$measured)) {
    return(c(
      "# One batch of studies of size n with fixed predictors: the three",
      "# independent sums of squares (reduced model, the tested predictors'",
      "# increase, residual), then each study's two R-squared values and the",
      "# Bayes factor of the full model over the reduced one.",
      "run_batch <- function(batch_n, batch_replications, batch_seed) {",
      "  set.seed(batch_seed)",
      "  error <- 1 - r2_full",
      "  a <- if (p > q) rchisq(batch_replications, p - q, ncp = batch_n * r2_reduced / error) else rep(0, batch_replications)",
      "  b <- rchisq(batch_replications, q, ncp = batch_n * (r2_full - r2_reduced) / error)",
      "  e <- rchisq(batch_replications, batch_n - p - 1)",
      "  total <- a + b + e"
    ))
  }
  c(
    "# One batch of studies of size n with predictors measured on each person",
    "# (multivariate normal, drawn afresh in each study). Given the predictors,",
    "# the three sums of squares (reduced model, the tested predictors'",
    "# increase, residual) are independent noncentral chi-squares; their",
    "# noncentralities are drawn first, as the predictors vary. Then each",
    "# study's two R-squared values and the Bayes factor of the full model",
    "# over the reduced one.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  s2 <- 1 - r2_full",
    "  tau2 <- r2_full - r2_reduced",
    "  a <- if (p > q) {",
    "    u <- r2_reduced * rchisq(batch_replications, batch_n - 1)",
    "    ncp_a <- if (tau2 > 0) tau2 * rchisq(batch_replications, p - q, ncp = u / tau2) else u",
    "    rchisq(batch_replications, p - q, ncp = ncp_a / s2)",
    "  } else rep(0, batch_replications)",
    "  b <- rchisq(batch_replications, q, ncp = tau2 * rchisq(batch_replications, batch_n - 1 - (p - q)) / s2)",
    "  e <- rchisq(batch_replications, batch_n - p - 1)",
    "  total <- a + b + e"
  )
}
