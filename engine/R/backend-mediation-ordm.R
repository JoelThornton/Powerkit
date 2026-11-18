# Backend adapter: mediation with a mediator in ordered categories
# (mediation / ordinal_mediator, E39).
#
# The mediator is modelled as ordered categories cut from an underlying
# normal score (the latent-response formulation of an ordered probit
# model), the usual structural-equation treatment of an ordinal endogenous
# variable (lavaan's `ordered` argument, its default WLSMV estimator).
# X is two groups (coded 0 and 1, equal groups) or a score (standardised,
# SD 1); Y is a score or yes/no:
#   M* = a X + e_M, e_M ~ N(0, 1);  M = k when tau_(k-1) < M* <= tau_k
#   Y  = b M* + c' X + e_Y, e_Y ~ N(0, 1)        (Y a score), or
#   Y* = b M* + c' X + e_Y, Y = yes when Y* > tau_Y   (Y yes/no).
# The thresholds tau come from the mediator's category proportions when X
# is 0 (the first group, or X's average): tau_k = qnorm(p_1 + ... + p_k);
# for a yes/no Y, tau_Y = qnorm(1 - P(Y = yes | X = 0, M* = 0)). a, b and c'
# are in SDs of the underlying scores' residuals (and of Y's residual for a
# score Y).
#
# Each simulated study is analysed by lavaan::sem() with the mediator (and
# a yes/no Y) declared `ordered` and parameterization = "theta", which
# fixes those residual variances at 1, so the estimates are on the scale of
# the inputs. The tested effect is the indirect effect a * b, defined in
# the model, with lavaan's delta-method standard error; significant when
# its two-sided p value is below alpha. A study whose model doesn't
# converge (an empty category, say) counts as not significant.
#
# The population (spec$population):
#   m_probabilities  the mediator's category proportions when X is 0, in
#                    order (three or more, summing to 1)
#   a                X's effect on the mediator's underlying score (second
#                    group against first, or per SD of X), in its SD
#   b, direct        Y's change per SD of the mediator's underlying score
#                    holding X, and X's direct effect holding the mediator:
#                    in Y's residual SD for a score, on the underlying
#                    (probit) scale for yes/no
#   y_baseline       Y yes/no: P(Y = yes) when X is 0 and the mediator's
#                    underlying score is at its average

ordm_inputs <- function(spec) {
  pop <- spec$population
  y_binary <- identical(spec$variables$Y$type, "binary")
  list(
    x_binary = identical(spec$variables$X$type, "binary"),
    y_binary = y_binary,
    m_probabilities = as.numeric(unlist(pop$m_probabilities)),
    a = as.numeric(pop$a),
    b = as.numeric(pop$b),
    direct = as.numeric(pop$direct %||% 0),
    # Unused for a score Y; not NA, which Spower would read as the value to solve for.
    y_baseline = if (y_binary) as.numeric(pop$y_baseline) else 0.5,
    alpha = spec$target_test$alpha
  )
}

# The mediator's thresholds on its underlying score.
ordm_thresholds <- function(m_probabilities) {
  stats::qnorm(cumsum(m_probabilities)[-length(m_probabilities)])
}

# One study's data: X (0/1 in two equal groups, in order, or a standard
# normal score), M (1, 2, ...) and Y.
ordm_data <- function(n, x_binary, y_binary, m_probabilities, a, b, direct, y_baseline) {
  x <- if (x_binary) as.numeric(seq_len(n) > n / 2) else stats::rnorm(n)
  m_star <- a * x + stats::rnorm(n)
  m <- findInterval(m_star, ordm_thresholds(m_probabilities)) + 1L
  y_star <- b * m_star + direct * x + stats::rnorm(n)
  y <- if (y_binary) as.numeric(y_star > stats::qnorm(1 - y_baseline)) else y_star
  data.frame(X = x, M = m, Y = y)
}

ordm_model <- "M ~ a*X\nY ~ b*M + direct*X\nindirect := a*b"

# lavaan's estimates for a, b, direct and the indirect effect (columns
# est, se, pvalue), or NULL when the model can't be fitted.
ordm_fit <- function(data, y_binary) {
  # lavaan prints its variable table when it refuses the data (a category
  # nobody is in, say); that output is kept out of the run's.
  fit <- NULL
  utils::capture.output(fit <- tryCatch(suppressWarnings(lavaan::sem(ordm_model, data = data,
    ordered = c("M", if (y_binary) "Y"), parameterization = "theta")), error = function(e) NULL))
  if (is.null(fit) || !isTRUE(lavaan::lavInspect(fit, "converged"))) return(NULL)
  pe <- lavaan::parameterEstimates(fit)
  pe <- pe[match(c("a", "b", "direct", "indirect"), pe$label), c("est", "se", "pvalue")]
  rownames(pe) <- c("a", "b", "direct", "indirect")
  if (!all(is.finite(as.matrix(pe)))) return(NULL)
  pe
}

# The experiment Spower runs: one study, TRUE when the indirect effect is
# significant.
p_mediation_ordm <- function(n, x_binary, y_binary, m_probabilities, a, b, direct, y_baseline, alpha) {
  data <- ordm_data(n, x_binary, y_binary, m_probabilities, a, b, direct, y_baseline)
  est <- ordm_fit(data, y_binary)
  !is.null(est) && est["indirect", "pvalue"] < alpha
}

ordm_count <- function(inputs, n, nrep, seed) {
  args <- c(list(n = n), inputs[c("x_binary", "y_binary", "m_probabilities", "a", "b", "direct", "y_baseline", "alpha")])
  # Spower's sig.level is unused: the experiment returns its own decision.
  result <- spower_eval(as.name("p_mediation_ordm"), args, nrep, 0.05, seed)
  round(result$power * nrep)
}

ordm_backend <- function(spec, seed = NULL) {
  inputs <- ordm_inputs(spec)
  list(
    name = "Spower",
    packages = c("Spower", "SimDesign", "lavaan"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = sprintf(
      "Spower::Spower(p_mediation_ordm()) (lavaan::sem(ordered = %s, parameterization = \"theta\"): the indirect effect a*b, delta method)",
      if (inputs$y_binary) "c(\"M\", \"Y\")" else "\"M\""
    )),
    n_step = if (inputs$x_binary) 2L else 1L,
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(chunk, chunk_seed) ordm_count(inputs, n, chunk, chunk_seed))
    },
    sensitivity = NULL,
    check_run = function() ordm_check_run(inputs, seed)
  )
}

# Check run: one large data set drawn as the experiment draws it, fitted
# as each study is, gives back each path and the indirect effect within 5
# of their standard errors, and each category's share when X is 0 within 5
# of its binomial standard error.
ordm_check_run <- function(inputs, seed) {
  n <- 2L * ceiling(check_run_n() / 2)
  data <- with_seed(seed %||% 1L, ordm_data(n, inputs$x_binary, inputs$y_binary, inputs$m_probabilities, inputs$a,
    inputs$b, inputs$direct, inputs$y_baseline))
  est <- ordm_fit(data, inputs$y_binary)
  x_name <- if (inputs$x_binary) "the second group of X against the first" else "X, per SD"
  y_scale <- if (inputs$y_binary) "on the outcome's underlying scale" else "in the outcome's residual SD"
  path_row <- function(label, name, specified) {
    if (is.null(est)) return(data.frame(parameter = label, specified = specified, recovered = NA_real_, ok = FALSE))
    check_run_rows(label, specified, est[name, "est"], est[name, "se"])
  }
  baseline <- if (inputs$x_binary) data$M[data$X == 0] else NULL
  share_rows <- if (!is.null(baseline)) lapply(seq_along(inputs$m_probabilities), function(k) {
    p <- inputs$m_probabilities[k]
    check_run_rows(sprintf("Share of the mediator's category %d in the first group", k), p, mean(baseline == k),
      sqrt(p * (1 - p) / length(baseline)))
  })
  check <- do.call(rbind, c(share_rows, list(
    path_row(sprintf("Mediator's underlying score for %s, in its SD (path a)", x_name), "a", inputs$a),
    path_row(sprintf("Outcome per SD of the mediator's underlying score, %s (path b)", y_scale), "b", inputs$b),
    path_row(sprintf("Outcome for %s holding the mediator, %s (direct effect)", x_name, y_scale), "direct", inputs$direct),
    path_row("Indirect effect a * b", "indirect", inputs$a * inputs$b)
  )))
  rownames(check) <- NULL
  check
}

check_mediation_ordm <- function(spec) {
  pop <- spec$population
  y_binary <- identical(spec$variables$Y$type, "binary")
  problems <- character()
  needed <- c("m_probabilities", "a", "b", if (y_binary) "y_baseline")
  missing <- setdiff(needed, names(pop))
  if (length(missing)) {
    problems <- c(problems, sprintf("'population' needs %s for a mediator in ordered categories.",
      paste(sprintf("'%s'", missing), collapse = ", ")))
  }
  if (!y_binary && "y_baseline" %in% names(pop)) {
    problems <- c(problems, "'population > y_baseline' is for a yes/no outcome, not a score; remove it.")
  }
  p <- suppressWarnings(as.numeric(unlist(pop$m_probabilities)))
  if (length(p)) {
    if (length(p) < 3) {
      problems <- c(problems, "'population > m_probabilities' needs three or more categories; for a yes/no mediator use template 'binary_mediator'.")
    }
    if (anyNA(p) || any(p <= 0) || any(p >= 1)) {
      problems <- c(problems, "Each of the mediator's category proportions must lie between 0 and 1 (not 0 or 1).")
    } else if (abs(sum(p) - 1) > 1e-6) {
      problems <- c(problems, sprintf("The mediator's category proportions must add up to 1; they add up to %s.", format(sum(p), digits = 4)))
    }
    levels <- spec$variables$M$levels
    if (length(levels) && length(levels) != length(p)) {
      problems <- c(problems, sprintf("The mediator has %d categories but %d proportions; give one proportion for each category, in order.",
        length(levels), length(p)))
    }
  }
  if ("y_baseline" %in% names(pop) && !(pop$y_baseline > 0 && pop$y_baseline < 1)) {
    problems <- c(problems, "'population > y_baseline' is a proportion, so it must lie between 0 and 1 (not 0 or 1).")
  }
  if (any(vapply(spec$variables, function(v) !is.null(v$reliability), logical(1)))) {
    problems <- c(problems, "Measurement error ('reliability') isn't modelled for mediation with a mediator in ordered categories; remove it.")
  }
  if (!identical(spec$target_test$path %||% "X->M->Y", "X->M->Y")) {
    problems <- c(problems, "'target_test > path' is \"X->M->Y\" for this template: the indirect effect runs from X through M to Y.")
  }
  problems
}

# The tested effect for the zero-effect check: a * b.
ordm_tested_effect <- function(spec) {
  inputs <- tryCatch(ordm_inputs(spec), error = function(e) NULL)
  if (is.null(inputs) || !length(inputs$a) || !length(inputs$b)) return(1)
  inputs$a * inputs$b
}

# Simulated data for the "download simulated data" export.
sim_ordm_code <- function(spec, n) {
  inputs <- ordm_inputs(spec)
  lev <- function(v) {
    given <- unlist(spec$variables[[v]]$levels)
    if (length(given)) given else if (v == "M") as.character(seq_along(inputs$m_probabilities)) else c("No", "Yes")
  }
  c(
    if (inputs$x_binary) sprintf("X <- as.numeric(seq_len(%d) > %s) # two equal groups", n, r_code(n / 2)) else
      sprintf("X <- stats::rnorm(%d) # SD 1", n),
    sprintf("M_star <- %s * X + stats::rnorm(%d) # the mediator's underlying score", r_code(inputs$a), n),
    sprintf("M <- findInterval(M_star, %s) + 1L # its ordered categories", r_code(ordm_thresholds(inputs$m_probabilities))),
    sprintf("Y <- %s * M_star + %s * X + stats::rnorm(%d)", r_code(inputs$b), r_code(inputs$direct), n),
    if (inputs$y_binary) sprintf("Y <- as.numeric(Y > %s)", r_code(stats::qnorm(1 - inputs$y_baseline))),
    "simulated <- data.frame(",
    sprintf("  %s = %s,", sim_label(spec, "X"), if (inputs$x_binary) sprintf("factor(%s[X + 1], levels = %s)", r_code(lev("X")), r_code(lev("X"))) else "X"),
    sprintf("  %s = factor(%s[M], levels = %s),", sim_label(spec, "M"), r_code(lev("M")), r_code(lev("M"))),
    sprintf("  %s = %s", sim_label(spec, "Y"), if (inputs$y_binary) sprintf("factor(%s[Y + 1], levels = %s)", r_code(lev("Y")), r_code(lev("Y"))) else "Y"),
    ")"
  )
}

# The standalone script (export_script()).
mediation_ordm_script <- function(spec, result) {
  inputs <- ordm_inputs(spec)
  header <- script_header(spec, result, "Spower", "Spower::Spower, lavaan::sem")
  x_line <- if (inputs$x_binary) "  X <- as.numeric(seq_len(n) > n / 2) # two equal groups: 0 the first, 1 the second" else
    "  X <- rnorm(n) # a score with SD 1"
  ordered <- if (inputs$y_binary) "c(\"M\", \"Y\")" else "\"M\""
  c(
    header,
    "library(Spower)",
    "library(lavaan)",
    "",
    "# Inputs ----",
    sprintf("m_probabilities <- %s # the mediator's category proportions when X is 0, in order", r_code(inputs$m_probabilities)),
    sprintf("a <- %s # X's effect on the mediator's underlying score, in its SD %s", r_code(inputs$a),
      if (inputs$x_binary) "(second group against the first)" else "(per SD of X)"),
    sprintf("b <- %s # outcome per SD of the mediator's underlying score, holding X%s", r_code(inputs$b),
      if (inputs$y_binary) " (underlying probit scale)" else ", in the outcome's residual SD"),
    sprintf("direct <- %s # X's effect on the outcome, holding the mediator", r_code(inputs$direct)),
    if (inputs$y_binary) sprintf("y_baseline <- %s # chance that the outcome is yes when X is 0 and the mediator's underlying score is average",
      r_code(inputs$y_baseline)),
    goal_inputs(spec, result),
    "",
    "# One simulated study: the mediator's underlying score cut into ordered",
    "# categories, then the latent-response mediation model fitted by lavaan",
    "# (the mediator declared ordered, residual variances of the underlying",
    "# scores fixed at 1): TRUE when the indirect effect a*b is significant",
    "# by its delta-method test. A model that doesn't converge counts as not",
    "# significant.",
    "model <- \"M ~ a*X\\nY ~ b*M + direct*X\\nindirect := a*b\"",
    "p_mediation_ordm <- function(n) {",
    x_line,
    "  M_star <- a * X + rnorm(n)",
    "  M <- findInterval(M_star, qnorm(cumsum(m_probabilities)[-length(m_probabilities)])) + 1L",
    "  Y <- b * M_star + direct * X + rnorm(n)",
    if (inputs$y_binary) "  Y <- as.numeric(Y > qnorm(1 - y_baseline))",
    "  fit <- tryCatch(suppressWarnings(sem(model, data = data.frame(X, M, Y),",
    sprintf("    ordered = %s, parameterization = \"theta\")), error = function(e) NULL)", ordered),
    "  if (is.null(fit) || !isTRUE(lavInspect(fit, \"converged\"))) return(FALSE)",
    "  pe <- parameterEstimates(fit)",
    "  isTRUE(pe$pvalue[match(\"indirect\", pe$label)] < alpha)",
    "}",
    "",
    "# One batch: significant results, and studies run.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  result <- Spower(p_mediation_ordm(n = batch_n), replications = batch_replications, parallel = FALSE, verbose = FALSE)",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, if (inputs$x_binary) 2L else 1L),
    comparison_section()
  )
}
