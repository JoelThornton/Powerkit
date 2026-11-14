# Backend adapter: mediation with a condition of three or more groups
# (mediation / multicategorical, E42).
#
# X is k groups of equal size, coded as k - 1 dummy variables D2, ..., Dk
# against the first group (indicator coding, as PROCESS's mcx = 1 codes
# them). The model is simple mediation with each dummy in place of X:
#   M ~ D2 + ... + Dk
#   Y ~ M + D2 + ... + Dk
# so each group j has a relative indirect effect a_j b (its difference from
# the first group in M, times M's effect on Y) and a relative direct effect
# c'_j. power4mome draws each exogenous variable separately (x_fun), so it
# can't draw dummies that exclude each other; Spower runs the experiment
# p_mediation_mcx() instead, which draws each study and analyses it as
# power4mome analyses simple mediation:
#   - the model fitted by lavaan (maximum likelihood), and
#   - each relative indirect effect tested by its Monte Carlo confidence
#     interval, from manymome's draws of the parameters (manymome::do_mc(),
#     as power4mome's gen_mc() calls it), the percentile interval computed
#     from the draws as fast_mediation_test() computes it; significant when
#     the interval excludes 0.
#
# The population is standardised within groups: in every group M has SD 1
# and M and Y correlate b, with Y's SD also 1 within groups. So
# population > m_differences are Cohen's d of each group against the first
# on M, b is the within-group (standardised) path M -> Y, and
# direct_differences are each group's difference from the first in Y, in
# Y's within-group SD, holding M constant (c'_j). Each group's total
# difference in Y is a_j b + c'_j.
#
# The test is one group's relative indirect effect (target_test > group, a
# level of X other than the first), or, by default, all of them: the
# chance that every relative indirect effect is significant in the same
# study.

mcx_inputs <- function(spec) {
  pop <- spec$population
  levels <- unlist(spec$variables$X$levels)
  group <- spec$target_test$group %||% "all"
  list(
    levels = levels,
    a = as.numeric(unlist(pop$m_differences)),
    b = as.numeric(pop$b),
    direct = as.numeric(unlist(pop$direct_differences %||% as.list(rep(0, length(levels) - 1)))),
    tested = if (identical(group, "all")) seq_len(length(levels) - 1) else match(group, levels[-1]),
    group = group,
    alpha = spec$target_test$alpha,
    ci_draws = as.integer(spec$options$ci_draws %||% default_ci_draws("monte_carlo_ci"))
  )
}

mcx_dummies <- function(k) paste0("D", seq_len(k)[-1])

mcx_model <- function(k) {
  d <- paste(mcx_dummies(k), collapse = " + ")
  paste0("M ~ ", d, "\nY ~ M + ", d)
}

# One study's data: n people in k equal groups (in order), each person's
# M and Y.
mcx_data <- function(n, a, b, direct) {
  k <- length(a) + 1
  group <- ceiling(seq_len(n) / (n / k))
  dummies <- vapply(seq_len(k)[-1], function(j) as.numeric(group == j), numeric(n))
  dummies <- matrix(dummies, nrow = n, dimnames = list(NULL, mcx_dummies(k)))
  m <- c(0, a)[group] + stats::rnorm(n)
  y <- b * m + c(0, direct)[group] + stats::rnorm(n, sd = sqrt(1 - b^2))
  data.frame(dummies, M = m, Y = y)
}

mcx_fit <- function(data, k) {
  tryCatch(suppressWarnings(lavaan::sem(mcx_model(k), data = data, fixed.x = TRUE)), error = function(e) NULL)
}

# The Monte Carlo interval of each tested relative indirect effect, from
# manymome's draws: c(lower, upper) per tested group, as columns.
mcx_intervals <- function(fit, k, tested, draws, level) {
  mc <- manymome::do_mc(fit, R = draws, parallel = FALSE, progress = FALSE, compute_implied_stats = FALSE)
  est <- lavaan::parameterTable(fit)
  vapply(mcx_dummies(k)[tested], function(d) {
    nodes <- c(d, "M", "Y")
    t0 <- mc_path_effect(est, nodes)
    t <- vapply(mc, function(draw) mc_path_effect(draw$est, nodes), numeric(1))
    boot::boot.ci(list(t0 = t0, t = matrix(t, ncol = 1), R = length(t)), type = "perc", conf = level)$perc[4:5]
  }, numeric(2))
}

# The experiment Spower runs: one study, TRUE when every tested relative
# indirect effect's interval excludes 0. A fit that fails or doesn't
# converge counts as not significant, as power4mome counts it.
p_mediation_mcx <- function(n, a, b, direct, tested, draws, alpha) {
  k <- length(a) + 1
  # Draw the data before fitting: passed as a lazy argument they would be
  # drawn inside lavaan, after random numbers the exported script doesn't use.
  data <- mcx_data(n, a, b, direct)
  fit <- mcx_fit(data, k)
  if (is.null(fit) || !lavaan::lavInspect(fit, "converged")) return(FALSE)
  ci <- tryCatch(mcx_intervals(fit, k, tested, draws, 1 - alpha), error = function(e) NULL)
  if (is.null(ci)) return(FALSE)
  all(ci[1, ] > 0 | ci[2, ] < 0)
}

mcx_count <- function(inputs, n, nrep, seed) {
  args <- list(n = n, a = inputs$a, b = inputs$b, direct = inputs$direct, tested = inputs$tested,
    draws = inputs$ci_draws, alpha = inputs$alpha)
  # Spower's sig.level is unused: the experiment returns its own decision.
  result <- spower_eval(as.name("p_mediation_mcx"), args, nrep, 0.05, seed)
  round(result$power * nrep)
}

mcx_function <- function(inputs) {
  sprintf("Spower::Spower(p_mediation_mcx()) (lavaan::sem(), manymome::do_mc() Monte Carlo CI of %s)",
    if (identical(inputs$group, "all")) "every relative indirect effect" else
      sprintf("the relative indirect effect of %s", inputs$group))
}

mcx_backend <- function(spec, seed = NULL) {
  inputs <- mcx_inputs(spec)
  k <- length(inputs$levels)
  list(
    name = "Spower",
    packages = c("Spower", "SimDesign", "lavaan", "manymome", "boot"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = mcx_function(inputs)),
    n_step = k,
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(chunk, chunk_seed) mcx_count(inputs, n, chunk, chunk_seed))
    },
    sensitivity = NULL,
    check_run = function() mcx_check_run(inputs, seed)
  )
}

# Check run: one large data set drawn as the experiment draws it and fitted
# with lavaan gives back each path within 5 of its standard errors, and
# each group's d on M (from the group means and the pooled within-group
# SD).
mcx_check_run <- function(inputs, seed) {
  k <- length(inputs$levels)
  n <- k * ceiling(check_run_n() / k)
  data <- with_seed(seed %||% 1L, mcx_data(n, inputs$a, inputs$b, inputs$direct))
  fit <- call_backend("lavaan", mcx_fit(data, k))
  if (is.null(fit)) abort_run("The check run's mediation model could not be fitted.")
  est <- lavaan::parameterEstimates(fit)
  path <- function(lhs, rhs) est[est$lhs == lhs & est$op == "~" & est$rhs == rhs, , drop = FALSE]
  d <- mcx_dummies(k)
  a_rows <- do.call(rbind, lapply(d, function(x) path("M", x)))
  c_rows <- do.call(rbind, lapply(d, function(x) path("Y", x)))
  b_row <- path("Y", "M")
  others <- inputs$levels[-1]
  check <- rbind(
    check_run_rows(sprintf("%s minus %s in M (d, path to M)", others, inputs$levels[1]), inputs$a, a_rows$est, a_rows$se),
    check_run_rows("M -> Y (within-group standardised path b)", inputs$b, b_row$est, b_row$se),
    check_run_rows(sprintf("%s minus %s in Y, holding M (direct effect)", others, inputs$levels[1]),
      inputs$direct, c_rows$est, c_rows$se)
  )
  rownames(check) <- NULL
  check
}

check_mediation_mcx <- function(spec) {
  pop <- spec$population
  levels <- unlist(spec$variables$X$levels)
  k <- length(levels)
  problems <- character()
  if (k < 3) {
    problems <- c(problems, "X has two groups: that is mediation with a yes/no X (template \"process_4\" with X binary). This template is for three or more groups.")
  }
  a <- unlist(pop$m_differences)
  if (length(a) != k - 1) {
    problems <- c(problems, sprintf("'population > m_differences' has %d values, but X has %d groups besides the first (%s): give each one's d against %s.",
      length(a), k - 1, paste(levels[-1], collapse = ", "), levels[1]))
  }
  direct <- unlist(pop$direct_differences)
  if (length(direct) && length(direct) != k - 1) {
    problems <- c(problems, sprintf("'population > direct_differences' has %d values, but X has %d groups besides the first: give one for each, in order.",
      length(direct), k - 1))
  }
  if (!is.null(pop$b) && abs(pop$b) >= 1) {
    problems <- c(problems, "'population > b' is the within-group correlation of M and Y (the standardised path M -> Y), so it must lie between -1 and 1.")
  }
  group <- spec$target_test$group %||% "all"
  if (!identical(group, "all") && !group %in% levels[-1]) {
    problems <- c(problems, sprintf("'target_test > group' is \"%s\"; it must be one of X's groups after the first (%s), whose relative indirect effect against %s is tested, or \"all\".",
      group, paste(levels[-1], collapse = ", "), levels[1]))
  }
  if (any(vapply(spec$variables, function(v) !is.null(v$reliability), logical(1)))) {
    problems <- c(problems, "Measurement error ('reliability') isn't modelled for mediation with X in three or more groups; remove it.")
  }
  if (!identical(spec$target_test$path %||% "X->M->Y", "X->M->Y")) {
    problems <- c(problems, "'target_test > path' is \"X->M->Y\" for this template: the relative indirect effects run from X's groups through M to Y.")
  }
  problems
}

# The tested relative indirect effects, for the zero-effect check: the
# smallest of them in absolute value (all must be non-zero for "all").
mcx_tested_effect <- function(spec) {
  inputs <- tryCatch(mcx_inputs(spec), error = function(e) NULL)
  if (is.null(inputs) || anyNA(inputs$tested) || !length(inputs$a)) return(1)
  min(abs(inputs$a[inputs$tested] * inputs$b))
}

# The standalone script (export_script()).
mediation_mcx_script <- function(spec, result) {
  inputs <- mcx_inputs(spec)
  k <- length(inputs$levels)
  header <- script_header(spec, result, "Spower", "Spower::Spower, lavaan::sem, manymome::do_mc")
  c(
    header,
    "library(Spower)",
    "library(lavaan)",
    "library(manymome)",
    "",
    "# Inputs ----",
    sprintf("groups <- %s # X's groups; each one after the first is compared with the first", r_code(inputs$levels)),
    sprintf("m_differences <- %s # each later group's Cohen's d against the first on M", r_code(inputs$a)),
    sprintf("b <- %s # M -> Y within groups (standardised: M and Y have SD 1 in every group)", r_code(inputs$b)),
    sprintf("direct_differences <- %s # each later group's difference in Y holding M, in Y's within-group SD", r_code(inputs$direct)),
    sprintf("tested <- %s # which relative indirect effects must be significant (positions among the later groups)", r_code(inputs$tested)),
    sprintf("draws <- %s # Monte Carlo draws per confidence interval", r_code(inputs$ci_draws)),
    goal_inputs(spec, result),
    "",
    "k <- length(groups)",
    "dummies <- paste0(\"D\", 2:k)",
    "model <- paste0(\"M ~ \", paste(dummies, collapse = \" + \"), \"\\nY ~ M + \", paste(dummies, collapse = \" + \"))",
    "",
    "# The relative indirect effect of dummy d in one parameter table: its path",
    "# to M times M's path to Y.",
    "relative_indirect <- function(est, d) {",
    "  est$est[est$lhs == \"M\" & est$op == \"~\" & est$rhs == d] * est$est[est$lhs == \"Y\" & est$op == \"~\" & est$rhs == \"M\"]",
    "}",
    "",
    "# One simulated study: equal groups, each person's M and Y, the model",
    "# fitted by lavaan, and each tested relative indirect effect's Monte Carlo",
    "# percentile interval from manymome's draws. TRUE when every tested",
    "# interval excludes 0; a fit that fails counts as not significant.",
    "p_mediation_mcx <- function(n) {",
    "  group <- ceiling(seq_len(n) / (n / k))",
    "  data <- as.data.frame(sapply(2:k, function(j) as.numeric(group == j)))",
    "  names(data) <- dummies",
    "  data$M <- c(0, m_differences)[group] + rnorm(n)",
    "  data$Y <- b * data$M + c(0, direct_differences)[group] + rnorm(n, sd = sqrt(1 - b^2))",
    "  fit <- tryCatch(suppressWarnings(sem(model, data = data, fixed.x = TRUE)), error = function(e) NULL)",
    "  if (is.null(fit) || !lavInspect(fit, \"converged\")) return(FALSE)",
    "  # Draws that fail (a covariance matrix of the estimates that isn't",
    "  # positive definite, say) count as not significant too.",
    "  tryCatch({",
    "    mc <- do_mc(fit, R = draws, parallel = FALSE, progress = FALSE, compute_implied_stats = FALSE)",
    "    est <- parameterTable(fit)",
    "    all(vapply(dummies[tested], function(d) {",
    "      t0 <- relative_indirect(est, d)",
    "      t <- vapply(mc, function(draw) relative_indirect(draw$est, d), numeric(1))",
    "      ci <- boot::boot.ci(list(t0 = t0, t = matrix(t, ncol = 1), R = length(t)), type = \"perc\", conf = 1 - alpha)$perc[4:5]",
    "      ci[1] > 0 || ci[2] < 0",
    "    }, logical(1)))",
    "  }, error = function(e) FALSE)",
    "}",
    "",
    "# One batch: significant results, and studies run.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  result <- Spower(p_mediation_mcx(n = batch_n), replications = batch_replications, parallel = FALSE, verbose = FALSE)",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, k),
    comparison_section()
  )
}
