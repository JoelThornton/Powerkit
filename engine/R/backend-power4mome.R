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
    functions = c(simulation = sprintf("power4mome::power4test with power4mome::%s", inputs$test_name)),
    n_step = 1,
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) {
        power4mome_rejections(inputs, n, k, chunk_seed)
      })
    },
    sensitivity = NULL,
    check_run = function() power4mome_check_run(spec, inputs, seed)
  )
}

# A binary X or W, and measurement error (reliability), are methodological
# choices still to be made for these designs (docs/decisions.md, open
# questions), so they aren't offered yet.
check_power4mome_supported <- function(spec) {
  binary <- names(Filter(function(v) identical(v$type, "binary"), spec$variables))
  if (length(binary) > 0) {
    abort_not_available(sprintf(
      "Mediation designs with a yes/no (binary) %s aren't available yet; for now, treat %s as continuous.",
      quote_list(vapply(binary, function(v) var_label(spec, v), character(1)), "or"),
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
  if (spec$design == "mediation" && !isTRUE(model$serial) && length(model$mediators) > 1) {
    # The spec gives residual correlations; power4mome's value for
    # 'M1 ~~ M2' between endogenous variables is their residual covariance
    # (with all observed variables standardised). So each correlation is
    # multiplied by the residual SDs, sqrt(1 - R-squared), from the same
    # implied model the validator uses.
    residual_var <- 1 - implied_r_squared(spec, model)$r_squared
    pairs <- utils::combn(model$mediators, 2, simplify = FALSE)
    covariances <- vapply(pairs, function(p) paste(p, collapse = " ~~ "), character(1))
    pop_covariances <- vapply(pairs, function(p) {
      covariance <- lookup(p[1], p[2], residual = TRUE) *
        sqrt(residual_var[[p[1]]] * residual_var[[p[2]]])
      sprintf("%s ~~ %s: %s", p[1], p[2], format_pop_value(covariance))
    }, character(1))
  }
  if (spec$design == "moderated_mediation") {
    pop_covariances <- sprintf("X ~~ W: %s", format_pop_value(lookup("X", "W")))
  }

  if (spec$design == "mediation") {
    nodes <- trimws(strsplit(spec$target_test$path, "->", fixed = TRUE)[[1]])
    test_name <- "test_indirect_effect"
    test_args <- list(x = "X", m = nodes[-c(1, length(nodes))], y = "Y")
  } else {
    test_name <- "test_index_of_mome"
    test_args <- list(x = "X", m = "M", y = "Y", w = "W")
  }
  monte_carlo <- spec$target_test$method == "monte_carlo_ci"
  test_args$mc_ci <- monte_carlo
  test_args$boot_ci <- !monte_carlo
  test_args$level <- 1 - spec$target_test$alpha

  list(
    model = paste(c(regressions, covariances), collapse = "\n"),
    pop_es = paste(c(pop_paths, pop_covariances), collapse = "\n"),
    equations = model$equations,
    term = term,
    test_name = test_name,
    test_args = test_args,
    ci_type = if (monte_carlo) "mc" else "boot",
    ci_draws = spec$options$ci_draws %||% default_ci_draws()
  )
}

# Monte Carlo draws (or bootstrap resamples) per confidence interval, when
# the spec doesn't say.
default_ci_draws <- function() 1000L

format_pop_value <- function(x) format(as.numeric(x), digits = 15, scientific = FALSE)

# power4test() re-evaluates parts of its own call, so arguments are given
# as values (via do.call()), not as expressions to look up.
power4mome_call <- function(inputs, n, nrep, seed, ...) {
  args <- c(
    list(nrep = as.integer(nrep), model = inputs$model, pop_es = inputs$pop_es, n = n),
    list(...),
    list(iseed = seed, parallel = FALSE, progress = FALSE)
  )
  call_backend("power4mome", quietly(do.call(power4mome::power4test, args)))
}

# Rejections in `nrep` replications at n, and how many replications could
# be analysed (power4mome drops data sets whose model fails to fit).
# power4mome switches on Boos and Zhang's (2000) extrapolated rejection
# rates automatically for some small numbers of resamples (R <= 359); that
# is turned off so the reported power is always the plain rejection rate
# (docs/decisions.md, open questions).
power4mome_rejections <- function(inputs, n, nrep, seed) {
  old <- options(power4mome.bz = FALSE)
  on.exit(options(old))
  result <- power4mome_call(
    inputs, n, nrep, seed,
    R = inputs$ci_draws,
    ci_type = inputs$ci_type,
    test_fun = getExportedValue("power4mome", inputs$test_name),
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
  lookup <- correlation_lookup(spec)
  correlation_rows <- list()
  if (spec$design == "moderated_mediation") {
    correlation_rows <- list(correlation_row("X<->W", lookup("X", "W"), stats::cor(data$X, data$W)))
  }
  model <- path_model(spec)
  if (spec$design == "mediation" && !isTRUE(model$serial) && length(model$mediators) > 1) {
    residuals <- lapply(model$mediators, function(m) stats::residuals(stats::lm(data[[m]] ~ data$X)))
    names(residuals) <- model$mediators
    correlation_rows <- lapply(utils::combn(model$mediators, 2, simplify = FALSE), function(p) {
      correlation_row(
        sprintf("residual %s<->%s", p[1], p[2]),
        lookup(p[1], p[2], residual = TRUE),
        stats::cor(residuals[[p[1]]], residuals[[p[2]]])
      )
    })
  }
  check <- do.call(rbind, c(coefficient_rows, variance_rows, correlation_rows))
  rownames(check) <- NULL
  check
}
