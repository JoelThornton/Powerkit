# Backend adapter: structural equation models by formula, via semPower.
#
#   model fit   sem/model_fit: the power of the chi-square test of exact
#               model fit to reject a model whose misfit in the population
#               is a given RMSEA. semPower::semPower.postHoc() with
#               effect.measure = "RMSEA": the noncentrality is
#               (N - 1) * F0, with F0 = RMSEA^2 * df, and power is the
#               noncentral chi-square's chance of exceeding the central
#               chi-square's critical value on the model's df.
#
#   invariance  sem/invariance: measurement invariance of one factor
#               across two groups, the chi-square difference test of
#               metric invariance against the configural model, or of
#               scalar against metric. semPower::semPower.powerMI().
#   factor_correlation  sem/factor_correlation: the correlation between
#               two factors of a CFA, against zero (the chi-square
#               difference test of the model with it fixed at 0).
#               semPower::semPower.powerCFA(nullEffect = "cor = 0").
#   latent_regression   sem/latent_regression: one slope of a latent
#               outcome regressed on one to five latent predictors,
#               against zero. semPower::semPower.powerRegression(), which
#               builds the path model for semPower.powerLav().
#
# For the last three, semPower fits the model with and without the
# restriction to the population covariance matrix (with lavaan) once, at
# the group weights the spec implies, and the resulting minimum of the fit
# function (F0, one per group for invariance) does not depend on the total
# N. Power at each n is then semPower::semPower.postHoc() with
# effect.measure = "F0" on the restriction's df, which is what those
# functions compute at that n (checked in test-backend-sempower.R), without
# refitting the models at every step of the search.
#
# The model's degrees of freedom come from the spec, or, for a
# confirmatory factor analysis described by its number of items and
# factors, from semPower::semPower.getDf() applied to the lavaan model
# that describes it (each item loading on one factor, the factors
# correlated). How the items are split between the factors does not
# change the df, so they are split as evenly as possible.
#
# Functions and arguments were checked in semPower 2.2.0's help pages and
# sources (docs/conventions.md, "semPower").

sempower_backend <- function(spec, seed = NULL) {
  if (!identical(spec$template, "model_fit")) {
    return(sempower_restriction_backend(spec))
  }
  df <- sem_df(spec)
  power_at <- function(n) sempower_power(spec, n, df)
  list(
    name = "semPower",
    packages = c("semPower", if (sem_from_shape(spec)) "lavaan"),
    methods = "exact",
    default_method = "exact",
    functions = c(exact = "semPower::semPower.postHoc"),
    n_step = 1,
    exact_min_n = minimum_n(spec),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() sempower_check_run(spec, df)
  )
}

# Whether the df come from the number of items and factors (a CFA) rather
# than from the spec.
sem_from_shape <- function(spec) is.null(spec$population$df)

# The lavaan model for a CFA with `indicators` items on `factors`
# correlated factors, each item on one factor, split as evenly as
# possible (the earlier factors take any extra items).
sem_cfa_syntax <- function(indicators, factors) {
  per_factor <- rep(indicators %/% factors, factors) +
    c(rep(1L, indicators %% factors), rep(0L, factors - indicators %% factors))
  last <- cumsum(per_factor)
  first <- last - per_factor + 1
  lines <- vapply(seq_len(factors), function(f) {
    sprintf("f%d =~ %s", f, paste0("x", first[f]:last[f], collapse = " + "))
  }, character(1))
  paste(lines, collapse = "\n")
}

# The model's degrees of freedom: from the spec, or from semPower's own
# count for the CFA the spec describes.
sem_df <- function(spec) {
  pop <- spec$population
  if (!sem_from_shape(spec)) {
    return(pop$df)
  }
  syntax <- sem_cfa_syntax(pop$indicators, pop$factors)
  call_backend("semPower", quietly(semPower::semPower.getDf(syntax)))
}

sempower_power <- function(spec, n, df) {
  out <- call_backend("semPower", quietly(semPower::semPower.postHoc(
    effect = spec$population$rmsea, effect.measure = "RMSEA",
    alpha = spec$target_test$alpha, N = n, df = df
  )))
  out$power
}

# Check run: no simulated data, so the check confirms semPower receives
# the RMSEA and df, and that the noncentrality it uses at an example N of
# 200 is (N - 1) * RMSEA^2 * df.
sempower_check_run <- function(spec, df) {
  pop <- spec$population
  out <- call_backend("semPower", quietly(semPower::semPower.postHoc(
    effect = pop$rmsea, effect.measure = "RMSEA",
    alpha = spec$target_test$alpha, N = 200, df = df
  )))
  row <- function(parameter, specified, passed) {
    data.frame(
      parameter = parameter, specified = specified, recovered = passed,
      ok = isTRUE(all.equal(specified, passed))
    )
  }
  rbind(
    row("RMSEA passed to semPower (effect)", pop$rmsea, out$effect),
    row("degrees of freedom passed to semPower (df)", df, out$df),
    row("noncentrality semPower uses at N = 200", 199 * pop$rmsea^2 * df, out$ncp)
  )
}

# Invariance, a factor correlation, a latent slope: a restriction tested
# against the model without it.
sempower_restriction_backend <- function(spec) {
  base <- sem_restriction_fit(spec)
  weights <- sem_group_weights(spec)
  power_at <- function(n) {
    out <- call_backend("semPower", quietly(semPower::semPower.postHoc(
      effect = if (length(weights) > 1) as.list(base$fmin_groups) else base$fmin,
      effect.measure = "F0", alpha = spec$target_test$alpha,
      N = if (length(weights) > 1) as.list(n * weights) else n, df = base$df
    )))
    out$power
  }
  list(
    name = "semPower",
    packages = c("semPower", "lavaan"),
    methods = "exact",
    default_method = "exact",
    functions = c(exact = sem_function(spec)),
    # Invariance: whole groups in the allocation ratio.
    n_step = valid_n_step(spec),
    exact_min_n = minimum_n(spec),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() sem_restriction_check_run(spec, base, power_at)
  )
}

sem_function <- function(spec) {
  switch(
    spec$template,
    invariance = "semPower::semPower.powerMI",
    factor_correlation = "semPower::semPower.powerCFA",
    latent_regression = "semPower::semPower.powerRegression"
  )
}

# The share of the total N in each group: two groups in the ratio
# 1 : allocation_ratio for invariance, one group otherwise.
sem_group_weights <- function(spec) {
  if (!identical(spec$template, "invariance")) {
    return(1)
  }
  ratio <- spec$options$allocation_ratio %||% 1
  c(1, ratio) / (1 + ratio)
}

# The arguments semPower's function takes for the spec's model, without
# the type of power analysis.
sem_restriction_args <- function(spec) {
  pop <- spec$population
  switch(
    spec$template,
    invariance = {
      k <- pop$indicators
      differ <- seq.int(k - pop$noninvariant + 1, k)
      if (identical(pop$level, "metric")) {
        second <- rep(pop$loading, k)
        second[differ] <- pop$loading_group2
        list(
          comparison = "configural", nullEffect = "metric",
          loadings = list(list(rep(pop$loading, k)), list(second))
        )
      } else {
        tau2 <- rep(0, k)
        tau2[differ] <- pop$intercept_difference
        list(
          comparison = "metric", nullEffect = "scalar",
          loadings = list(rep(pop$loading, k)),
          tau = list(rep(0, k), tau2), Alpha = list(0, 0)
        )
      }
    },
    factor_correlation = list(
      comparison = "restricted", Phi = pop$r, nullEffect = "cor = 0",
      nIndicator = unlist(pop$indicators), loadM = unlist(pop$loadings)
    ),
    latent_regression = {
      k <- length(pop$slopes)
      list(
        comparison = "restricted", slopes = unlist(pop$slopes),
        corXX = if (k > 1) sem_predictor_correlations(k, pop$predictor_correlation %||% 0),
        nullEffect = "slope = 0", nullWhich = pop$tested %||% 1L,
        nIndicator = rep(pop$indicators, k + 1), loadM = pop$loading
      )
    }
  )
}

# The predictors' correlation matrix: the same correlation for every pair.
sem_predictor_correlations <- function(k, r) {
  m <- matrix(r, k, k)
  diag(m) <- 1
  m
}

# One call to semPower's function, at the group weights the spec implies
# (any N: the fit function's minimum doesn't depend on it).
sem_restriction_fit <- function(spec) {
  weights <- sem_group_weights(spec)
  reference <- 1000
  n <- if (length(weights) > 1) as.list(reference * weights) else reference
  fun <- getExportedValue("semPower", sub("^semPower::", "", sem_function(spec)))
  out <- call_backend("semPower", quietly(do.call(fun, c(
    list(type = "post-hoc", alpha = spec$target_test$alpha, N = n),
    sem_restriction_args(spec)
  ))))
  list(df = out$df, fmin = out$fmin, fmin_groups = out$fmin.g, reference = reference, power = out$power)
}

# Check run: no simulated data. The check confirms that semPower's own
# function and the shortcut through its F0 agree on power at the
# reference N, and that the restriction has the df expected.
sem_restriction_check_run <- function(spec, base, power_at) {
  # One restriction for a correlation or a slope. Invariance restricts
  # every loading (or intercept) but one: the second group's factor
  # variance (or mean) is freed in its place, as in lavaan.
  expected_df <- if (identical(spec$template, "invariance")) spec$population$indicators - 1 else 1
  row <- function(parameter, specified, recovered) {
    data.frame(
      parameter = parameter, specified = specified, recovered = recovered,
      ok = isTRUE(all.equal(specified, recovered, tolerance = 1e-6))
    )
  }
  rbind(
    row("degrees of freedom of the restriction", expected_df, base$df),
    row(sprintf("power at N = %d: semPower's function, and through its F0", base$reference), base$power, power_at(base$reference))
  )
}

#' The model behind a structural equation model's power analysis
#'
#' For a model-fit power analysis (design `sem`, template `model_fit`),
#' the model's degrees of freedom and, for a confirmatory factor analysis
#' described by its number of items and factors, the lavaan model semPower
#' counted them from. For the other templates (a restriction tested
#' against the model without it), the template and the restriction's
#' degrees of freedom.
#'
#' @param spec A validated spec with design `sem`.
#'
#' @return `NULL` for other designs. For `model_fit`, a list with
#'   `template`, `rmsea`, `df`, `indicators` and `factors` (`NULL` when the
#'   spec gives the df), and `model` (the lavaan model, or `NULL`).
#'   Otherwise a list with `template` and `df`.
#' @export
sem_summary <- function(spec) {
  if (!identical(spec$design, "sem")) {
    return(NULL)
  }
  pop <- spec$population
  if (!identical(spec$template, "model_fit")) {
    return(list(template = spec$template, df = sem_restriction_fit(spec)$df))
  }
  list(
    template = "model_fit",
    rmsea = pop$rmsea,
    df = sem_df(spec),
    indicators = pop$indicators,
    factors = pop$factors,
    model = if (sem_from_shape(spec)) sem_cfa_syntax(pop$indicators, pop$factors)
  )
}

# The R script for a model-fit power analysis: the same semPower calls as
# powerkit's, with the values written out.
sempower_script <- function(spec, result) {
  if (!identical(spec$template, "model_fit")) {
    return(sempower_restriction_script(spec, result))
  }
  pop <- spec$population
  df_lines <- if (sem_from_shape(spec)) {
    c(
      sprintf("# The model: %s items on %s correlated factors, each item on one factor.", pop$indicators, pop$factors),
      "# semPower counts its degrees of freedom with lavaan.",
      sprintf("model <- %s", r_code(sem_cfa_syntax(pop$indicators, pop$factors))),
      "df <- semPower.getDf(model)"
    )
  } else {
    sprintf("df <- %s # the model's degrees of freedom", r_code(pop$df))
  }
  c(
    script_header(spec, result, "semPower", "semPower::semPower.postHoc(effect.measure = \"RMSEA\")"),
    "library(semPower)",
    "",
    "# Inputs ----",
    sprintf("rmsea <- %s # the misfit (RMSEA) the test should detect", r_code(pop$rmsea)),
    df_lines,
    goal_inputs(spec, result),
    "",
    "# Power of the chi-square test of exact fit to reject a model whose",
    "# misfit in the population is rmsea, at a total sample size.",
    "power_at <- function(n_total) {",
    "  semPower.postHoc(",
    "    effect = rmsea, effect.measure = \"RMSEA\",",
    "    alpha = alpha, N = n_total, df = df",
    "  )$power",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}

# R code for one of semPower's arguments: lists (one element per group)
# and matrices as well as vectors.
sem_code <- function(x) {
  if (is.matrix(x)) {
    return(sprintf("matrix(%s, nrow = %d)", r_code(as.vector(x)), nrow(x)))
  }
  if (is.list(x)) {
    return(sprintf("list(%s)", paste(vapply(x, sem_code, character(1)), collapse = ", ")))
  }
  r_code(x)
}

# The R script for invariance, a factor correlation or a latent slope: one
# call to semPower's function for the population misfit (F0), then
# semPower.postHoc() at each n, as powerkit does.
sempower_restriction_script <- function(spec, result) {
  weights <- sem_group_weights(spec)
  args <- sem_restriction_args(spec)
  fun <- sub("^semPower::", "", sem_function(spec))
  arg_lines <- vapply(names(args), function(a) sprintf("  %s = %s", a, sem_code(args[[a]])), character(1))
  arg_lines <- paste0(arg_lines, c(rep(",", length(arg_lines) - 1), ""))
  two_groups <- length(weights) > 1
  c(
    script_header(spec, result, "semPower", sprintf("semPower::%s() and semPower::semPower.postHoc()", fun)),
    "library(semPower) # semPower fits the models with lavaan",
    "",
    "# Inputs ----",
    goal_inputs(spec, result),
    if (two_groups) sprintf("group_weights <- %s # each group's share of the total", r_code(weights)),
    "",
    "# The models with and without the restriction, fitted to the population",
    "# once: the minimum of the fit function (F0) doesn't depend on the total n.",
    sprintf("fit <- %s(", fun),
    sprintf("  type = \"post-hoc\", alpha = alpha, N = %s,", if (two_groups) "as.list(1000 * group_weights)" else "1000"),
    arg_lines,
    ")",
    "",
    "# Power of the chi-square difference test at a total sample size.",
    "power_at <- function(n_total) {",
    "  semPower.postHoc(",
    sprintf("    effect = %s, effect.measure = \"F0\",", if (two_groups) "as.list(fit$fmin.g)" else "fit$fmin"),
    sprintf("    alpha = alpha, N = %s, df = fit$df", if (two_groups) "as.list(n_total * group_weights)" else "n_total"),
    "  )$power",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}
