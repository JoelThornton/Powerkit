# Backend adapter: mediation with a yes/no or count outcome (mediation /
# binary_or_count_outcome, E32).
#
# M is a score; X is two groups (coded 0 and 1, equal groups) or a score
# (standardised, SD 1); Y is yes/no or a count. The models are the ones
# VanderWeele's regression-based causal mediation analysis fits (Valeri and
# VanderWeele, 2013), without an X-by-M interaction:
#   M = a X + e_M, e_M ~ N(0, 1)                        (M in its residual SD)
#   logit P(Y = 1) = log-odds0 + b M + c' X              (Y yes/no), or
#   log E(Y) = log(rate0) + b M + c' X                   (Y a count: Poisson,
#                                                         or negative binomial
#                                                         with variance
#                                                         mu + k mu^2).
# The tested effect is the natural indirect effect of X (from 0 to 1: the
# second group against the first, or one SD of X) through M, with the
# delta-method standard error, as regmedint::regmedint() computes them
# (its "pnie" row): a * b on the log odds-ratio scale (yes/no Y, an
# approximation the authors give for a rare outcome) or the log rate-ratio
# scale (count Y). Significant when its two-sided p value is below alpha.
#
# Spower runs the experiment p_mediation_yglm(): one study drawn from the
# models above and analysed by regmedint() with mreg = "linear" and yreg =
# "logistic", "poisson" or "negbin". A study whose models can't be fitted
# counts as not significant.
#
# The population (spec$population):
#   a              X's effect on M (second group against first, or per SD of
#                  X), in M's residual SD
#   y_baseline     Y yes/no: P(Y = yes) for the first group of X (or at X's
#                  mean) with M at 0 (its mean in the first group)
#   b_odds_ratio, direct_odds_ratio   Y yes/no: exp(b) per residual SD of M,
#                  and exp(c')
#   base_rate      Y a count: the mean count for the first group of X (or at
#                  X's mean) with M at 0
#   b_rate_ratio, direct_rate_ratio   Y a count: exp(b) and exp(c')
#   dispersion     Y a negative binomial count (method negative_binomial in
#                  population > count_model): k in variance mu + k mu^2

yglm_outcome <- function(spec) {
  if (identical(spec$variables$Y$type, "binary")) return("binary")
  if (identical(spec$population$count_model %||% "poisson", "negative_binomial")) "negbin" else "poisson"
}

yglm_inputs <- function(spec) {
  pop <- spec$population
  outcome <- yglm_outcome(spec)
  binary <- identical(outcome, "binary")
  list(
    x_binary = identical(spec$variables$X$type, "binary"),
    outcome = outcome,
    a = as.numeric(pop$a),
    # The outcome's starting point on its link scale: log odds or log mean.
    y0 = if (binary) stats::qlogis(as.numeric(pop$y_baseline)) else log(as.numeric(pop$base_rate)),
    b = log(as.numeric(if (binary) pop$b_odds_ratio else pop$b_rate_ratio)),
    direct = log(as.numeric((if (binary) pop$direct_odds_ratio else pop$direct_rate_ratio) %||% 1)),
    # 0 unless negative binomial; Spower reads NA as the value to solve for, so never NA.
    dispersion = if (identical(outcome, "negbin")) as.numeric(pop$dispersion) else 0,
    alpha = spec$target_test$alpha
  )
}

# One study's data: X (0/1 in two equal groups, in order, or a standard
# normal score), M (a score) and Y.
yglm_data <- function(n, x_binary, outcome, a, y0, b, direct, dispersion) {
  x <- if (x_binary) as.numeric(seq_len(n) > n / 2) else stats::rnorm(n)
  m <- a * x + stats::rnorm(n)
  eta <- y0 + b * m + direct * x
  y <- switch(outcome,
    binary = stats::rbinom(n, 1, stats::plogis(eta)),
    poisson = stats::rpois(n, exp(eta)),
    negbin = stats::rnbinom(n, size = 1 / dispersion, mu = exp(eta))
  )
  data.frame(X = x, M = m, Y = y)
}

yglm_yreg <- function(outcome) c(binary = "logistic", poisson = "poisson", negbin = "negbin")[[outcome]]

# regmedint's natural indirect effect: c(estimate, se, p), or NULL when
# the models can't be fitted.
yglm_nie <- function(data, outcome) {
  fit <- tryCatch(suppressWarnings(regmedint::regmedint(
    data = data, yvar = "Y", avar = "X", mvar = "M", cvar = NULL,
    a0 = 0, a1 = 1, m_cde = 0, c_cond = NULL,
    mreg = "linear", yreg = yglm_yreg(outcome),
    interaction = FALSE, casecontrol = FALSE
  )), error = function(e) NULL)
  if (is.null(fit)) return(NULL)
  est <- tryCatch(summary(fit)$summary_myreg, error = function(e) NULL)
  if (is.null(est) || !all(is.finite(est["pnie", c("est", "se", "p")]))) return(NULL)
  est["pnie", c("est", "se", "p")]
}

# The experiment Spower runs: one study, TRUE when the natural indirect
# effect is significant.
p_mediation_yglm <- function(n, x_binary, outcome, a, y0, b, direct, dispersion, alpha) {
  data <- yglm_data(n, x_binary, outcome, a, y0, b, direct, dispersion)
  nie <- yglm_nie(data, outcome)
  !is.null(nie) && nie[["p"]] < alpha
}

yglm_count <- function(inputs, n, nrep, seed) {
  args <- c(list(n = n), inputs[c("x_binary", "outcome", "a", "y0", "b", "direct", "dispersion", "alpha")])
  # Spower's sig.level is unused: the experiment returns its own decision.
  result <- spower_eval(as.name("p_mediation_yglm"), args, nrep, 0.05, seed)
  round(result$power * nrep)
}

yglm_backend <- function(spec, seed = NULL) {
  inputs <- yglm_inputs(spec)
  list(
    name = "Spower",
    packages = c("Spower", "SimDesign", "regmedint", if (identical(inputs$outcome, "negbin")) "MASS"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = sprintf(
      "Spower::Spower(p_mediation_yglm()) (regmedint::regmedint(mreg = \"linear\", yreg = \"%s\"): natural indirect effect, delta method)",
      yglm_yreg(inputs$outcome)
    )),
    n_step = if (inputs$x_binary) 2L else 1L,
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(chunk, chunk_seed) yglm_count(inputs, n, chunk, chunk_seed))
    },
    sensitivity = NULL,
    check_run = function() yglm_check_run(inputs, seed)
  )
}

# Check run: one large data set drawn as the experiment draws it gives back
# each regression coefficient within 5 of its standard errors.
yglm_check_run <- function(inputs, seed) {
  n <- 2L * ceiling(check_run_n() / 2)
  data <- with_seed(seed %||% 1L, yglm_data(n, inputs$x_binary, inputs$outcome, inputs$a, inputs$y0, inputs$b,
    inputs$direct, inputs$dispersion))
  coefs <- function(fit) summary(fit)$coefficients
  m_fit <- coefs(stats::lm(M ~ X, data = data))
  y_fit <- coefs(switch(inputs$outcome,
    binary = stats::glm(Y ~ M + X, family = stats::binomial(), data = data),
    poisson = stats::glm(Y ~ M + X, family = stats::poisson(), data = data),
    negbin = MASS::glm.nb(Y ~ M + X, data = data)
  ))
  x_name <- if (inputs$x_binary) "second group of X against the first" else "X, per SD"
  scale <- if (identical(inputs$outcome, "binary")) "log odds" else "log mean count"
  ratio <- if (identical(inputs$outcome, "binary")) "log odds ratio" else "log rate ratio"
  rows <- list(
    check_run_rows(sprintf("M: difference for the %s, in M's residual SD (path a)", x_name), inputs$a, m_fit["X", 1], m_fit["X", 2]),
    check_run_rows(sprintf("Y: %s at X = 0, M = 0 (baseline)", scale), inputs$y0, y_fit["(Intercept)", 1], y_fit["(Intercept)", 2]),
    check_run_rows(sprintf("Y: %s per SD of M, holding X (path b)", ratio), inputs$b, y_fit["M", 1], y_fit["M", 2]),
    check_run_rows(sprintf("Y: %s for the %s, holding M (direct effect)", ratio, x_name), inputs$direct, y_fit["X", 1], y_fit["X", 2])
  )
  check <- do.call(rbind, rows)
  rownames(check) <- NULL
  check
}

check_mediation_yglm <- function(spec) {
  pop <- spec$population
  binary <- identical(spec$variables$Y$type, "binary")
  problems <- character()
  needed <- c("a", if (binary) c("y_baseline", "b_odds_ratio") else c("base_rate", "b_rate_ratio"),
    if (!binary && identical(pop$count_model, "negative_binomial")) "dispersion")
  missing <- setdiff(needed, names(pop))
  if (length(missing)) {
    problems <- c(problems, sprintf("'population' needs %s for mediation with %s outcome.",
      paste(sprintf("'%s'", missing), collapse = ", "), if (binary) "a yes/no" else "a count"))
  }
  wrong <- intersect(names(pop), if (binary) c("base_rate", "b_rate_ratio", "direct_rate_ratio", "dispersion", "count_model") else
    c("y_baseline", "b_odds_ratio", "direct_odds_ratio"))
  if (!binary && !identical(pop$count_model, "negative_binomial")) wrong <- c(wrong, intersect(names(pop), "dispersion"))
  if (length(wrong)) {
    problems <- c(problems, sprintf("%s %s for %s outcome; remove %s.",
      paste(sprintf("'population > %s'", wrong), collapse = ", "), if (length(wrong) > 1) "aren't used" else "isn't used",
      if (binary) "a yes/no" else if (identical(pop$count_model, "negative_binomial")) "a count" else "a Poisson count",
      if (length(wrong) > 1) "them" else "it"))
  }
  if (!is.null(pop$y_baseline) && !(pop$y_baseline > 0 && pop$y_baseline < 1)) {
    problems <- c(problems, "'population > y_baseline' is a proportion, so it must lie between 0 and 1 (not 0 or 1).")
  }
  for (p in intersect(c("b_odds_ratio", "direct_odds_ratio", "b_rate_ratio", "direct_rate_ratio", "base_rate", "dispersion"), names(pop))) {
    if (!(pop[[p]] > 0)) problems <- c(problems, sprintf("'population > %s' must be above 0.", p))
  }
  if (any(vapply(spec$variables, function(v) !is.null(v$reliability), logical(1)))) {
    problems <- c(problems, "Measurement error ('reliability') isn't modelled for mediation with a yes/no or count outcome; remove it.")
  }
  if (!identical(spec$target_test$path %||% "X->M->Y", "X->M->Y")) {
    problems <- c(problems, "'target_test > path' is \"X->M->Y\" for this template: the natural indirect effect runs from X through M to Y.")
  }
  problems
}

# The tested effect for the zero-effect check: a * b (zero when either
# path is).
yglm_tested_effect <- function(spec) {
  inputs <- tryCatch(yglm_inputs(spec), error = function(e) NULL)
  if (is.null(inputs) || !length(inputs$a) || !length(inputs$b)) return(1)
  inputs$a * inputs$b
}

# The standalone script (export_script()).
mediation_yglm_script <- function(spec, result) {
  inputs <- yglm_inputs(spec)
  binary <- identical(inputs$outcome, "binary")
  header <- script_header(spec, result, "Spower", "Spower::Spower, regmedint::regmedint")
  x_line <- if (inputs$x_binary) "  X <- as.numeric(seq_len(n) > n / 2) # two equal groups: 0 the first, 1 the second" else
    "  X <- rnorm(n) # a score with SD 1"
  y_line <- switch(inputs$outcome,
    binary = "  Y <- rbinom(n, 1, plogis(qlogis(y_baseline) + log(b_odds_ratio) * M + log(direct_odds_ratio) * X))",
    poisson = "  Y <- rpois(n, base_rate * b_rate_ratio^M * direct_rate_ratio^X)",
    negbin = "  Y <- rnbinom(n, size = 1 / dispersion, mu = base_rate * b_rate_ratio^M * direct_rate_ratio^X)"
  )
  per_x <- if (inputs$x_binary) "(second group against the first)" else "(per SD)"
  c(
    header,
    "library(Spower)",
    "library(regmedint)",
    "",
    "# Inputs ----",
    sprintf("a <- %s # X's effect on M %s, in M's residual SD", r_code(inputs$a), per_x),
    if (binary) c(
      sprintf("y_baseline <- %s # chance that Y is yes when X and M are 0", r_code(stats::plogis(inputs$y0))),
      sprintf("b_odds_ratio <- %s # odds ratio of Y = yes per SD of M, holding X", r_code(exp(inputs$b))),
      sprintf("direct_odds_ratio <- %s # odds ratio of Y = yes for X %s, holding M", r_code(exp(inputs$direct)), per_x)
    ) else c(
      sprintf("base_rate <- %s # mean count when X and M are 0", r_code(exp(inputs$y0))),
      sprintf("b_rate_ratio <- %s # rate ratio per SD of M, holding X", r_code(exp(inputs$b))),
      sprintf("direct_rate_ratio <- %s # rate ratio for X %s, holding M", r_code(exp(inputs$direct)), per_x),
      if (identical(inputs$outcome, "negbin")) sprintf("dispersion <- %s # k: a count's variance is mu + k mu^2", r_code(inputs$dispersion))
    ),
    goal_inputs(spec, result),
    "",
    "# One simulated study: X, M and Y drawn from the models, then",
    "# regression-based causal mediation analysis (Valeri and VanderWeele,",
    "# 2013) by regmedint: TRUE when the natural indirect effect of X (0 to 1)",
    "# through M is significant by its delta-method test. Models that can't be",
    "# fitted count as not significant.",
    "p_mediation_yglm <- function(n) {",
    x_line,
    "  M <- a * X + rnorm(n)",
    y_line,
    "  fit <- tryCatch(suppressWarnings(regmedint(",
    "    data = data.frame(X, M, Y), yvar = \"Y\", avar = \"X\", mvar = \"M\", cvar = NULL,",
    "    a0 = 0, a1 = 1, m_cde = 0, c_cond = NULL,",
    sprintf("    mreg = \"linear\", yreg = \"%s\", interaction = FALSE, casecontrol = FALSE", yglm_yreg(inputs$outcome)),
    "  )), error = function(e) NULL)",
    "  if (is.null(fit)) return(FALSE)",
    "  p <- tryCatch(summary(fit)$summary_myreg[\"pnie\", \"p\"], error = function(e) NA)",
    "  isTRUE(p < alpha)",
    "}",
    "",
    "# One batch: significant results, and studies run.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  result <- Spower(p_mediation_yglm(n = batch_n), replications = batch_replications, parallel = FALSE, verbose = FALSE)",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, if (inputs$x_binary) 2L else 1L),
    comparison_section()
  )
}
