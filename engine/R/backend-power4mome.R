# Backend adapter: mediation (PROCESS models 4 and 6) and moderated
# mediation (PROCESS models 7 and 14) via power4mome.
#
# Power is simulated with power4mome::power4test(): data are generated from
# the standardised paths, the model is fitted with lavaan (power4mome's
# default; its Monte Carlo confidence intervals need a lavaan fit), and the
# indirect effect (test_indirect_effect()) or the index of moderated
# mediation (test_index_of_mome()) is tested with a Monte Carlo or
# percentile bootstrap confidence interval at level 1 - alpha.

power4mome_backend <- function(spec, seed = NULL) {
  check_power4mome_supported(spec)
  inputs <- power4mome_inputs(spec)
  list(
    name = "power4mome",
    packages = c("power4mome", "manymome", "lavaan"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = sprintf("power4mome::power4test with %s", if (identical(inputs$test_name, "test_cond_indirect_diff")) {
      "powerkit's test_cond_indirect_diff() (manymome::cond_indirect_diff())"
    } else sprintf("power4mome::%s", inputs$test_name))),
    n_step = 1,
    exact_min_n = minimum_n(spec),
    batch_size = power4mome_batch_size(inputs$ci_draws),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) {
        power4mome_rejections(inputs, n, k, chunk_seed)
      }, batch_size = power4mome_batch_size(inputs$ci_draws))
    },
    sensitivity = NULL,
    check_run = function() power4mome_check_run(spec, inputs, seed)
  )
}

# A yes/no X in mediation (E16) is drawn by power4mome's rbinary_rs(),
# rescaled to mean 0 and SD 1, so its paths are per SD of X (decided 29
# October 2026). A yes/no X or W in moderated mediation (E17) and
# measurement error (reliability) aren't offered yet. Treating a binary
# variable as continuous isn't suggested: it may give an inaccurate power
# estimate.
check_power4mome_supported <- function(spec) {
  binary <- names(Filter(function(v) identical(v$type, "binary"), spec$variables))
  if (spec$design == "mediation") binary <- setdiff(binary, "X")
  # A yes/no X or W in moderated mediation (E17, 1 November 2026): drawn
  # by rbinary_rs() as for E16's X, and checked against a separately
  # written simulation (test-validation-modmed-binary.R).
  if (spec$design == "moderated_mediation") binary <- setdiff(binary, c("X", "W"))
  if (length(binary) > 0) {
    abort_not_available(sprintf(
      "Mediation designs with a yes/no (binary) variable aren't available yet (%s %s yes/no). Treating %s as continuous may give an inaccurate power estimate.",
      quote_list(vapply(binary, function(v) var_label(spec, v), character(1)), "and"),
      if (length(binary) == 1) "is" else "are",
      if (length(binary) == 1) "it" else "them"
    ))
  }
  unreliable <- names(Filter(function(v) !is.null(v$reliability) && v$reliability < 1, spec$variables))
  if (length(unreliable) > 0) {
    abort_not_available(sprintf(
      "Mediation designs with measurement error ('reliability' for %s) aren't available yet; remove 'reliability' to assume perfectly reliable measures.",
      quote_list(vapply(unreliable, function(v) var_label(spec, v), character(1)), "and")
    ))
  }
  invisible(TRUE)
}

# Translate a validated spec into power4mome's inputs. Variables keep their
# spec roles as names (X, W, M, M1, ..., Y); product terms are written
# lavaan-style (XW -> X:W). Every path is given to power4mome, including
# zeros. Parallel mediators' residuals are free to correlate in the fitted
# model whatever their population value, as in PROCESS, which fits each
# equation separately by OLS.
power4mome_inputs <- function(spec) {
  model <- path_model(spec)
  term <- function(v) {
    if (v %in% names(model$products)) paste(model$products[[v]], collapse = ":") else v
  }
  regressions <- vapply(names(model$equations), function(outcome) {
    paste(outcome, "~", paste(vapply(model$equations[[outcome]], term, character(1)), collapse = " + "))
  }, character(1))
  paths <- spec$population$paths
  pop_paths <- unlist(lapply(names(model$equations), function(outcome) {
    vapply(model$equations[[outcome]], function(p) {
      sprintf("%s ~ %s: %s", outcome, term(p), format_pop_value(paths[[paste0(p, "->", outcome)]]))
    }, character(1))
  }), use.names = FALSE)

  covariances <- character()
  pop_covariances <- character()
  lookup <- correlation_lookup(spec)
  if (!isTRUE(model$serial) && length(model$mediators) > 1) {
    # The spec gives residual correlations; without a product term,
    # power4mome's value for 'M1 ~~ M2' between endogenous variables is
    # their residual covariance
    # (with all observed variables standardised). So each correlation is
    # multiplied by the residual SDs, sqrt(1 - R-squared), from the same
    # implied model the validator uses.
    residual_var <- 1 - implied_r_squared(spec, model)$r_squared
    pairs <- utils::combn(model$mediators, 2, simplify = FALSE)
    covariances <- vapply(pairs, function(p) paste(p, collapse = " ~~ "), character(1))
    # In a model with a product term (moderated mediation), power4mome
    # standardises the population by Monte Carlo and its 'M1 ~~ M2' value
    # is the residual correlation itself: checked by simulation with
    # power4mome 0.2.1 (100,000 cases: 0.3 and 0.6 came back as 0.30 and
    # 0.60, while the covariance 0.27 came back as 0.27, a correlation).
    # The check run recovers the residual correlation either way.
    pop_covariances <- vapply(pairs, function(p) {
      scale <- if (length(model$products) > 0) 1 else sqrt(residual_var[[p[1]]] * residual_var[[p[2]]])
      covariance <- lookup(p[1], p[2], residual = TRUE) * scale
      sprintf("%s ~~ %s: %s", p[1], p[2], format_pop_value(covariance))
    }, character(1))
  }
  if (spec$design == "moderated_mediation") {
    pop_covariances <- c(sprintf("X ~~ W: %s", format_pop_value(lookup("X", "W"))), pop_covariances)
  }

  if (spec$design == "mediation") {
    nodes <- trimws(strsplit(spec$target_test$path, "->", fixed = TRUE)[[1]])
    test_name <- "test_indirect_effect"
    test_args <- list(x = "X", m = nodes[-c(1, length(nodes))], y = "Y")
  } else if (identical(spec$variables$W$type, "binary")) {
    # A yes/no W (E17): manymome's index_of_mome() treats a moderator with
    # two values as categorical and stops, so the test is the difference
    # between the two groups' conditional indirect effects, at W's two
    # rescaled values. The indirect effect is linear in W (models 7 and
    # 14), so that difference is the index times the distance between the
    # values, from the same Monte Carlo draws: the same decision.
    p <- spec$population$w_prob %||% 0.5
    test_name <- "test_cond_indirect_diff"
    test_args <- list(x = "X", m = modmed_mediator(spec), y = "Y", w = "W",
      w_from = (0 - p) / sqrt(p * (1 - p)), w_to = (1 - p) / sqrt(p * (1 - p)))
  } else if (cond_indirect_difference(spec)) {
    w_values <- as.numeric(unlist(spec$target_test$w_values %||% list(-1, 1)))
    test_name <- "test_cond_indirect_diff"
    test_args <- list(x = "X", m = "M", y = "Y", w = "W", w_from = w_values[1], w_to = w_values[2])
  } else {
    test_name <- "test_index_of_mome"
    test_args <- list(x = "X", m = modmed_mediator(spec), y = "Y", w = "W")
  }
  monte_carlo <- spec$target_test$method == "monte_carlo_ci"
  test_args$mc_ci <- monte_carlo
  test_args$boot_ci <- !monte_carlo
  test_args$level <- 1 - spec$target_test$alpha
  # Significant if the confidence interval excludes 0 (see
  # power4mome_rejections() on Boos and Zhang's method).
  test_args$test_method <- "ci"

  list(
    model = paste(c(regressions, covariances), collapse = "\n"),
    # Models 58 and 59 (W on the M -> Y link): the fitted model is given
    # explicitly. power4mome's own adds a residual covariance of M with W,
    # which can't be estimated when W also predicts M (lavaan cannot
    # compute standard errors), so it is left out; the exogenous
    # variables and product terms covary freely, and M's residual with
    # the product of M and W, as power4mome writes them.
    fit_model = if (spec$design == "moderated_mediation" && spec$template %in% c("process_58", "process_59")) {
      exogenous <- c("X", "W", "X:W", "M:W")
      pairs <- utils::combn(exogenous, 2, simplify = FALSE)
      paste(c(regressions, "M ~~ M:W", vapply(pairs, function(p) paste(p, collapse = " ~~ "), character(1))), collapse = "\n")
    },
    pop_es = paste(c(pop_paths, pop_covariances), collapse = "\n"),
    # A yes/no X: the proportion in its second level, for rbinary_rs().
    x_prob = if (identical(spec$variables$X$type, "binary")) spec$population$x_prob %||% 0.5,
    w_prob = if (identical(spec$variables$W$type, "binary")) spec$population$w_prob %||% 0.5,
    equations = model$equations,
    term = term,
    test_name = test_name,
    test_args = test_args,
    ci_type = if (monte_carlo) "mc" else "boot",
    ci_draws = spec$options$ci_draws %||% default_ci_draws()
  )
}

# Monte Carlo draws (or bootstrap resamples) per confidence interval, when
# the spec doesn't say: power4mome's own default for a mediation power
# analysis, the `R` of q_power_mediation() (1,000 in power4mome 0.2.1).
# power4test() itself has no default (R = NULL makes no draws, so no CI
# test can run), and the low-level gen_mc() and gen_boot() default to 100.
default_ci_draws <- function() {
  as.integer(eval(formals(power4mome::q_power_mediation)$R))
}

# Most replications in one power4test() call. power4test() keeps every
# replication's data, fit and draws until it returns, so its memory grows
# with nrep; for PROCESS model 7 at n = 250 with 1,000 Monte Carlo draws,
# about 1.5 to 3 MB per replication (measured; docs/decisions.md, "Running
# power4mome simulations in batches"). 200 replications per call keep a
# batch well under 1 GB. Memory grows with the number of draws (n matters
# much less), so the batch shrinks in proportion above 1,000 draws.
power4mome_batch_size <- function(ci_draws = default_ci_draws()) {
  as.integer(max(10, floor(200 * 1000 / max(1000, ci_draws))))
}

format_pop_value <- function(x) format(as.numeric(x), digits = 15, scientific = FALSE)

# power4test() re-evaluates parts of its own call, so arguments are given
# as values (via do.call()), not as expressions to look up.
#
# The call also runs with R's random-number generator seeded (set.seed(seed)
# first, as well as iseed = seed). For a model with a product term (PROCESS
# models 7 and 14), power4test() standardises the population by Monte Carlo
# (100,000 draws, power4mome's n_std) before iseed takes effect, so those
# draws come from whatever state the generator is in. Unseeded, a call's
# result depended on the calls before it (the check run, earlier batches)
# and, on several cores, on how the batches were shared out. Seeded, each
# call depends only on its own seed. iseed alone still sets the simulated
# data sets, so models without a product term give the same results as
# before.
power4mome_call <- function(inputs, n, nrep, seed, ...) {
  args <- c(
    list(nrep = as.integer(nrep), model = inputs$model, pop_es = inputs$pop_es, n = n),
    if (!is.null(inputs$x_prob) || !is.null(inputs$w_prob)) list(x_fun = c(
      if (!is.null(inputs$x_prob)) list(X = list(power4mome::rbinary_rs, p1 = inputs$x_prob)),
      if (!is.null(inputs$w_prob)) list(W = list(power4mome::rbinary_rs, p1 = inputs$w_prob))
    )),
    if (!is.null(inputs$fit_model)) list(fit_model_args = list(model = inputs$fit_model)),
    list(...),
    list(iseed = seed, parallel = FALSE, progress = FALSE)
  )
  call_backend("power4mome", with_seed(seed, quietly(do.call(power4mome::power4test, args))))
}

# Rejections in `nrep` replications at n, and how many replications could
# be analysed (power4mome drops data sets whose model fails to fit).
# Boos and Zhang's (2000) method is off (a departure from power4mome's
# default; docs/conventions.md). power4mome switches it on automatically
# when R is one of its supported values (39, 79, ..., 359): each test then
# uses a p-value rule instead of the confidence interval. Its documented
# switch, options(power4mome.bz = FALSE), is not seen by the test
# functions in power4mome 0.2.1 (they check isFALSE(options(...)), which
# is always FALSE because options() returns a list), so powerkit asks for
# the CI rule explicitly (test_method = "ci", in power4mome_inputs()) and
# also sets the option, which power4mome's summaries do read.
power4mome_rejections <- function(inputs, n, nrep, seed) {
  old <- options(power4mome.bz = FALSE)
  on.exit(options(old))
  result <- power4mome_call(
    inputs, n, nrep, seed,
    R = inputs$ci_draws,
    ci_type = inputs$ci_type,
    test_fun = power4mome_test_fun(inputs$test_name),
    test_args = inputs$test_args
  )
  rates <- power4mome::rejection_rates(result)
  valid <- round(rates$pvalid[1] * nrep)
  c(round(rates$reject[1] * valid), valid)
}

# Check run: one large data set from power4mome's generator. Each equation
# is refitted by OLS: every path coefficient must match the spec, each
# observed variable must have variance 1 (paths are standardised), and the
# specified correlations (X with W; parallel mediators' residuals) must be
# recovered. The variance check also confirms that power4mome treats a
# product of two standardised variables as powerkit's validator does
# (variance 1 + r^2, not standardised).
power4mome_check_run <- function(spec, inputs, seed) {
  n <- check_run_n()
  sim <- power4mome_call(inputs, n, 1, seed, do_the_test = FALSE)
  data <- as.data.frame(power4mome::pool_sim_data(sim))
  backtick <- function(v) paste0("`", v, "`")
  paths <- spec$population$paths

  coefficient_rows <- lapply(names(inputs$equations), function(outcome) {
    preds <- inputs$equations[[outcome]]
    terms <- vapply(preds, inputs$term, character(1))
    fit <- stats::lm(stats::reformulate(backtick(terms), response = backtick(outcome)), data = data)
    # Coefficients after the intercept, in the formula's order.
    est <- summary(fit)$coefficients[-1, , drop = FALSE]
    check_run_rows(
      paste0(preds, "->", outcome),
      vapply(preds, function(p) as.numeric(paths[[paste0(p, "->", outcome)]]), numeric(1)),
      est[, "Estimate"],
      est[, "Std. Error"]
    )
  })

  observed <- c(path_model(spec)$exogenous, names(inputs$equations))
  variance_rows <- lapply(observed, function(v) {
    squares <- (data[[v]] - mean(data[[v]]))^2
    check_run_rows(sprintf("variance of %s", v), 1, mean(squares), stats::sd(squares) / sqrt(n))
  })

  correlation_row <- function(label, specified, recovered) {
    data.frame(
      parameter = label, specified = specified, recovered = recovered,
      ok = abs(atanh(recovered) - atanh(specified)) <= 5 / sqrt(n - 3)
    )
  }
  # A yes/no X: the share of people in its second level (rbinary_rs()
  # puts them above X's mean).
  split_row_for <- function(v, prob) {
    share <- mean(data[[v]] > 0)
    data.frame(
      parameter = sprintf("proportion in %s's second level", v), specified = prob, recovered = share,
      ok = abs(share - prob) <= 5 * sqrt(prob * (1 - prob) / n)
    )
  }
  split_rows <- c(if (!is.null(inputs$x_prob)) list(split_row_for("X", inputs$x_prob)),
    if (!is.null(inputs$w_prob)) list(split_row_for("W", inputs$w_prob)))
  lookup <- correlation_lookup(spec)
  correlation_rows <- list()
  if (spec$design == "moderated_mediation") {
    correlation_rows <- list(correlation_row("X<->W", lookup("X", "W"), stats::cor(data$X, data$W)))
  }
  model <- path_model(spec)
  if (!isTRUE(model$serial) && length(model$mediators) > 1) {
    residuals <- lapply(model$mediators, function(m) {
      terms <- vapply(inputs$equations[[m]], inputs$term, character(1))
      stats::residuals(stats::lm(stats::reformulate(backtick(terms), response = backtick(m)), data = data))
    })
    names(residuals) <- model$mediators
    correlation_rows <- c(correlation_rows, lapply(utils::combn(model$mediators, 2, simplify = FALSE), function(p) {
      correlation_row(
        sprintf("residual %s<->%s", p[1], p[2]),
        lookup(p[1], p[2], residual = TRUE),
        stats::cor(residuals[[p[1]]], residuals[[p[2]]])
      )
    }))
  }
  check <- do.call(rbind, c(coefficient_rows, variance_rows, correlation_rows, split_rows))
  rownames(check) <- NULL
  check
}

# The difference between two conditional indirect effects (PROCESS models
# 8, 58 and 59, E38; decided 1 November 2026): the indirect effect of X on
# Y through M at W = w_to minus that at W = w_from, from manymome's
# cond_indirect_effects() and cond_indirect_diff(), its Monte Carlo (or
# bootstrap) confidence interval at the same level as the other tests.
# power4mome has no test for it, so this is a test function in the shape
# power4mome's own take (test_cond_indirect()'s arguments and return
# value), given to power4test() as test_fun.
test_cond_indirect_diff <- function(fit = fit, x = NULL, m = NULL, y = NULL, w = NULL, w_from = -1, w_to = 1,
                                    mc_ci = TRUE, mc_out = NULL, boot_ci = FALSE, boot_out = NULL,
                                    check_post_check = TRUE, test_method = "ci", ..., fit_name = "fit",
                                    get_map_names = FALSE, get_test_name = FALSE) {
  map_names <- c(fit = fit_name, mc_out = if (fit_name != "fit") paste0(fit_name, "_mc_out") else "mc_out",
    boot_out = if (fit_name != "fit") paste0(fit_name, "_boot_out") else "boot_out")
  if (get_map_names) return(map_names)
  if (get_test_name) {
    return(sprintf("test_cond_indirect_diff: %s (%s = %s minus %s = %s)", paste(c(x, m, y), collapse = "->"), w, w_to, w, w_from))
  }
  if (boot_ci) mc_ci <- FALSE
  empty <- c(est = NA_real_, cilo = NA_real_, cihi = NA_real_, sig = NA_real_, pvalue = NA_real_)
  fit_ok <- !inherits(fit, "lavaan") || (lavaan::lavInspect(fit, "converged") &&
    (suppressWarnings(lavaan::lavInspect(fit, "post.check")) || !check_post_check))
  if (!fit_ok) return(empty)
  out <- tryCatch({
    # W as a number even when it takes two values (a yes/no W, rescaled):
    # manymome would otherwise treat it as categorical.
    levels <- manymome::mod_levels(w = w, fit = fit, w_type = "numeric", values = c(w_to, w_from))
    effects <- manymome::cond_indirect_effects(wlevels = levels, x = x, y = y, m = m, fit = fit, mc_ci = mc_ci, mc_out = mc_out,
      boot_ci = boot_ci, boot_out = boot_out, progress = FALSE, ...)
    # The rows follow manymome's order, so they are found by value.
    values <- levels[[1]]
    manymome::cond_indirect_diff(effects, from = which.min(abs(values - w_from)), to = which.min(abs(values - w_to)))
  }, error = function(e) e)
  if (inherits(out, "error")) return(empty)
  ci <- stats::confint(out)
  c(est = unname(stats::coef(out)), cilo = ci[1, 1], cihi = ci[1, 2], sig = as.numeric(ci[1, 1] > 0 || ci[1, 2] < 0), pvalue = NA_real_)
}

# The test function: power4mome's own, or powerkit's for the difference
# between conditional indirect effects.
power4mome_test_fun <- function(name) {
  if (identical(name, "test_cond_indirect_diff")) test_cond_indirect_diff else getExportedValue("power4mome", name)
}

cond_indirect_difference <- function(spec) {
  identical(spec$design, "moderated_mediation") && identical(spec$target_test$effect, "conditional_indirect_difference")
}
