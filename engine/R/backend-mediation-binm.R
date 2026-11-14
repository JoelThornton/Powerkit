# Backend adapter: mediation with a yes/no mediator (mediation /
# binary_mediator, E39).
#
# M is yes/no; X is two groups (coded 0 and 1, equal groups) or a score
# (standardised, SD 1); Y is a score or yes/no. The models are the ones
# VanderWeele's regression-based causal mediation analysis fits (Valeri and
# VanderWeele, 2013), without an X-by-M interaction:
#   logit P(M = 1) = a0 + a X
#   Y = b0 + b M + c' X + e, e ~ N(0, 1)          (Y a score), or
#   logit P(Y = 1) = b0 + b M + c' X              (Y yes/no).
# The tested effect is the natural indirect effect of X (from 0 to 1: the
# second group against the first, or one SD of X) through M, with the
# delta-method standard error, as regmedint::regmedint() computes them
# (its "pnie" row; without an interaction the pure and total natural
# indirect effects are the same). Significant when its two-sided p value is
# below alpha, which is when the delta-method confidence interval excludes
# 0. For a yes/no Y the effect is on the log odds-ratio scale.
#
# Spower runs the experiment p_mediation_binm(): one study drawn from the
# models above and analysed by regmedint(). A study whose models can't be
# fitted (no "yes" mediators in a group, say) counts as not significant.
#
# The population (spec$population):
#   m_baseline     P(M = yes) for the first group of X, or at X's mean
#   m_odds_ratio   the odds ratio of M = yes for X (second group against
#                  first, or per SD of X): exp(a)
#   b, direct      Y a score: the difference in Y between M yes and no
#                  holding X, and X's direct effect holding M, both in Y's
#                  residual SD (b and c' above)
#   y_baseline     Y yes/no: P(Y = yes) for the first group (or X's mean)
#                  with M = no
#   b_odds_ratio, direct_odds_ratio  Y yes/no: exp(b) and exp(c')

binm_inputs <- function(spec) {
  pop <- spec$population
  y_binary <- identical(spec$variables$Y$type, "binary")
  list(
    x_binary = identical(spec$variables$X$type, "binary"),
    y_binary = y_binary,
    m_baseline = as.numeric(pop$m_baseline),
    a = log(as.numeric(pop$m_odds_ratio)),
    # Unused for a score Y; not NA, which Spower would read as the value to solve for.
    y_baseline = if (y_binary) as.numeric(pop$y_baseline) else 0.5,
    b = if (y_binary) log(as.numeric(pop$b_odds_ratio)) else as.numeric(pop$b),
    direct = if (y_binary) log(as.numeric(pop$direct_odds_ratio %||% 1)) else as.numeric(pop$direct %||% 0),
    alpha = spec$target_test$alpha
  )
}

# One study's data: X (0/1 in two equal groups, in order, or a standard
# normal score), M (0/1) and Y.
binm_data <- function(n, x_binary, y_binary, m_baseline, a, y_baseline, b, direct) {
  x <- if (x_binary) as.numeric(seq_len(n) > n / 2) else stats::rnorm(n)
  m <- stats::rbinom(n, 1, stats::plogis(stats::qlogis(m_baseline) + a * x))
  y <- if (y_binary) {
    stats::rbinom(n, 1, stats::plogis(stats::qlogis(y_baseline) + b * m + direct * x))
  } else {
    b * m + direct * x + stats::rnorm(n)
  }
  data.frame(X = x, M = m, Y = y)
}

# regmedint's natural indirect effect: c(estimate, se, p), or NULL when
# the models can't be fitted.
binm_nie <- function(data, y_binary) {
  fit <- tryCatch(suppressWarnings(regmedint::regmedint(
    data = data, yvar = "Y", avar = "X", mvar = "M", cvar = NULL,
    a0 = 0, a1 = 1, m_cde = 0, c_cond = NULL,
    mreg = "logistic", yreg = if (y_binary) "logistic" else "linear",
    interaction = FALSE, casecontrol = FALSE
  )), error = function(e) NULL)
  if (is.null(fit)) return(NULL)
  est <- tryCatch(summary(fit)$summary_myreg, error = function(e) NULL)
  if (is.null(est) || !all(is.finite(est["pnie", c("est", "se", "p")]))) return(NULL)
  est["pnie", c("est", "se", "p")]
}

# The experiment Spower runs: one study, TRUE when the natural indirect
# effect is significant.
p_mediation_binm <- function(n, x_binary, y_binary, m_baseline, a, y_baseline, b, direct, alpha) {
  data <- binm_data(n, x_binary, y_binary, m_baseline, a, y_baseline, b, direct)
  nie <- binm_nie(data, y_binary)
  !is.null(nie) && nie[["p"]] < alpha
}

binm_count <- function(inputs, n, nrep, seed) {
  args <- inputs[c("x_binary", "y_binary", "m_baseline", "a", "y_baseline", "b", "direct", "alpha")]
  args <- c(list(n = n), args)
  # Spower's sig.level is unused: the experiment returns its own decision.
  result <- spower_eval(as.name("p_mediation_binm"), args, nrep, 0.05, seed)
  round(result$power * nrep)
}

binm_backend <- function(spec, seed = NULL) {
  inputs <- binm_inputs(spec)
  list(
    name = "Spower",
    packages = c("Spower", "SimDesign", "regmedint"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = sprintf(
      "Spower::Spower(p_mediation_binm()) (regmedint::regmedint(mreg = \"logistic\", yreg = \"%s\"): natural indirect effect, delta method)",
      if (inputs$y_binary) "logistic" else "linear"
    )),
    n_step = if (inputs$x_binary) 2L else 1L,
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(chunk, chunk_seed) binm_count(inputs, n, chunk, chunk_seed))
    },
    sensitivity = NULL,
    check_run = function() binm_check_run(inputs, seed)
  )
}

# Check run: one large data set drawn as the experiment draws it gives back
# each regression coefficient within 5 of its standard errors.
binm_check_run <- function(inputs, seed) {
  n <- 2L * ceiling(check_run_n() / 2)
  data <- with_seed(seed %||% 1L, binm_data(n, inputs$x_binary, inputs$y_binary, inputs$m_baseline, inputs$a,
    inputs$y_baseline, inputs$b, inputs$direct))
  coefs <- function(fit) summary(fit)$coefficients
  m_fit <- coefs(stats::glm(M ~ X, family = stats::binomial(), data = data))
  y_fit <- coefs(if (inputs$y_binary) stats::glm(Y ~ M + X, family = stats::binomial(), data = data) else stats::lm(Y ~ M + X, data = data))
  x_name <- if (inputs$x_binary) "second group of X against the first" else "X, per SD"
  rows <- list(
    check_run_rows("M: log odds of yes at X = 0 (baseline)", stats::qlogis(inputs$m_baseline), m_fit["(Intercept)", 1], m_fit["(Intercept)", 2]),
    check_run_rows(sprintf("M: log odds ratio for the %s (path a)", x_name), inputs$a, m_fit["X", 1], m_fit["X", 2])
  )
  rows <- c(rows, if (inputs$y_binary) {
    list(
      check_run_rows("Y: log odds of yes at X = 0, M = no (baseline)", stats::qlogis(inputs$y_baseline), y_fit["(Intercept)", 1], y_fit["(Intercept)", 2]),
      check_run_rows("Y: log odds ratio for M yes against no (path b)", inputs$b, y_fit["M", 1], y_fit["M", 2]),
      check_run_rows(sprintf("Y: log odds ratio for the %s, holding M (direct effect)", x_name), inputs$direct, y_fit["X", 1], y_fit["X", 2])
    )
  } else {
    list(
      check_run_rows("Y: difference for M yes against no, in residual SD (path b)", inputs$b, y_fit["M", 1], y_fit["M", 2]),
      check_run_rows(sprintf("Y: difference for the %s, holding M (direct effect)", x_name), inputs$direct, y_fit["X", 1], y_fit["X", 2])
    )
  })
  check <- do.call(rbind, rows)
  rownames(check) <- NULL
  check
}

check_mediation_binm <- function(spec) {
  pop <- spec$population
  y_binary <- identical(spec$variables$Y$type, "binary")
  problems <- character()
  needed <- c("m_baseline", "m_odds_ratio", if (y_binary) c("y_baseline", "b_odds_ratio") else "b")
  missing <- setdiff(needed, names(pop))
  if (length(missing)) {
    problems <- c(problems, sprintf("'population' needs %s for a yes/no mediator with %s outcome.",
      paste(sprintf("'%s'", missing), collapse = ", "), if (y_binary) "a yes/no" else "a score"))
  }
  wrong <- intersect(names(pop), if (y_binary) c("b", "direct") else c("y_baseline", "b_odds_ratio", "direct_odds_ratio"))
  if (length(wrong)) {
    problems <- c(problems, sprintf("%s %s for %s outcome; remove %s.",
      paste(sprintf("'population > %s'", wrong), collapse = ", "), if (length(wrong) > 1) "are" else "is",
      if (y_binary) "a score, not a yes/no" else "a yes/no, not a score", if (length(wrong) > 1) "them" else "it"))
  }
  for (p in intersect(c("m_baseline", "y_baseline"), names(pop))) {
    if (!(pop[[p]] > 0 && pop[[p]] < 1)) {
      problems <- c(problems, sprintf("'population > %s' is a proportion, so it must lie between 0 and 1 (not 0 or 1).", p))
    }
  }
  for (p in intersect(c("m_odds_ratio", "b_odds_ratio", "direct_odds_ratio"), names(pop))) {
    if (!(pop[[p]] > 0)) problems <- c(problems, sprintf("'population > %s' is an odds ratio, so it must be above 0.", p))
  }
  if (any(vapply(spec$variables, function(v) !is.null(v$reliability), logical(1)))) {
    problems <- c(problems, "Measurement error ('reliability') isn't modelled for mediation with a yes/no mediator; remove it.")
  }
  if (!identical(spec$target_test$path %||% "X->M->Y", "X->M->Y")) {
    problems <- c(problems, "'target_test > path' is \"X->M->Y\" for this template: the natural indirect effect runs from X through M to Y.")
  }
  problems
}

# The tested effect for the zero-effect check: a * b on the log-odds scale
# (zero when either path is).
binm_tested_effect <- function(spec) {
  inputs <- tryCatch(binm_inputs(spec), error = function(e) NULL)
  if (is.null(inputs) || !length(inputs$a) || !length(inputs$b)) return(1)
  inputs$a * inputs$b
}

# The standalone script (export_script()).
mediation_binm_script <- function(spec, result) {
  inputs <- binm_inputs(spec)
  header <- script_header(spec, result, "Spower", "Spower::Spower, regmedint::regmedint")
  x_line <- if (inputs$x_binary) "  X <- as.numeric(seq_len(n) > n / 2) # two equal groups: 0 the first, 1 the second" else
    "  X <- rnorm(n) # a score with SD 1"
  y_lines <- if (inputs$y_binary) {
    "  Y <- rbinom(n, 1, plogis(qlogis(y_baseline) + log(b_odds_ratio) * M + log(direct_odds_ratio) * X))"
  } else {
    "  Y <- b * M + direct * X + rnorm(n) # b and direct in Y's residual SD"
  }
  c(
    header,
    "library(Spower)",
    "library(regmedint)",
    "",
    "# Inputs ----",
    sprintf("m_baseline <- %s # chance that M is yes when X is 0", r_code(inputs$m_baseline)),
    sprintf("m_odds_ratio <- %s # odds ratio of M = yes for X %s", r_code(exp(inputs$a)), if (inputs$x_binary) "(second group against the first)" else "(per SD)"),
    if (inputs$y_binary) c(
      sprintf("y_baseline <- %s # chance that Y is yes when X is 0 and M is no", r_code(inputs$y_baseline)),
      sprintf("b_odds_ratio <- %s # odds ratio of Y = yes for M yes against no, holding X", r_code(exp(inputs$b))),
      sprintf("direct_odds_ratio <- %s # odds ratio of Y = yes for X, holding M", r_code(exp(inputs$direct)))
    ) else c(
      sprintf("b <- %s # difference in Y for M yes against no, holding X, in Y's residual SD", r_code(inputs$b)),
      sprintf("direct <- %s # difference in Y for X, holding M, in Y's residual SD", r_code(inputs$direct))
    ),
    goal_inputs(spec, result),
    "",
    "# One simulated study: X, M and Y drawn from the models, then",
    "# regression-based causal mediation analysis (Valeri and VanderWeele,",
    "# 2013) by regmedint: TRUE when the natural indirect effect of X (0 to 1)",
    "# through M is significant by its delta-method test. Models that can't be",
    "# fitted count as not significant.",
    "p_mediation_binm <- function(n) {",
    x_line,
    "  M <- rbinom(n, 1, plogis(qlogis(m_baseline) + log(m_odds_ratio) * X))",
    y_lines,
    "  fit <- tryCatch(suppressWarnings(regmedint(",
    "    data = data.frame(X, M, Y), yvar = \"Y\", avar = \"X\", mvar = \"M\", cvar = NULL,",
    "    a0 = 0, a1 = 1, m_cde = 0, c_cond = NULL,",
    sprintf("    mreg = \"logistic\", yreg = \"%s\", interaction = FALSE, casecontrol = FALSE", if (inputs$y_binary) "logistic" else "linear"),
    "  )), error = function(e) NULL)",
    "  if (is.null(fit)) return(FALSE)",
    "  p <- tryCatch(summary(fit)$summary_myreg[\"pnie\", \"p\"], error = function(e) NA)",
    "  isTRUE(p < alpha)",
    "}",
    "",
    "# One batch: significant results, and studies run.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  result <- Spower(p_mediation_binm(n = batch_n), replications = batch_replications, parallel = FALSE, verbose = FALSE)",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, if (inputs$x_binary) 2L else 1L),
    comparison_section()
  )
}
