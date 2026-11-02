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
#   invariance  sem/invariance: measurement invariance of one or more
#               factors across two or more groups
#               (semPower::semPower.powerMI()) or over two or more
#               occasions in the same people (population > over
#               "occasions", semPower::semPower.powerLI(), with the
#               factors' correlations within and between occasions as
#               Phi), the chi-square difference test of metric invariance
#               against the configural model, or of scalar against metric.
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
#   close fit   sem/model_fit with target_test > method
#               "chi_square_close_fit" or "chi_square_not_close_fit":
#               MacCallum, Browne and Sugawara's (1996) tests (the
#               reference in WebPower's help), computed by WebPower's
#               wp.sem.rmsea(). Close fit: H0 RMSEA at most rmsea_null
#               (0.05 by default) against the population RMSEA above it;
#               the test rejects close fit. Not-close fit: H0 RMSEA at
#               least rmsea_null against the population RMSEA below it;
#               rejecting it supports close fit. Both use the noncentral
#               chi-square under H0 as well as under H1, with noncentrality
#               (N - 1) * df * RMSEA^2, so at rmsea_null 0 the test of close
#               fit is semPower's test of exact fit (checked in the check
#               run and in test-backend-sempower.R).
#
# Functions and arguments were checked in semPower 2.2.0's and WebPower
# 0.9.4's help pages and sources (docs/conventions.md, "semPower").

sempower_backend <- function(spec, seed = NULL) {
  if (!identical(spec$template, "model_fit")) {
    return(sempower_restriction_backend(spec))
  }
  if (sem_close_fit_test(spec)) {
    return(webpower_rmsea_backend(spec))
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
    details = function(n) sempower_details(sempower_post_hoc(spec, n, df), "semPower::semPower.postHoc"),
    check_run = function() sempower_check_run(spec, df)
  )
}

# The tests of close and not-close fit (WebPower).
sem_close_fit_test <- function(spec) {
  isTRUE(spec$target_test$method %in% c("chi_square_close_fit", "chi_square_not_close_fit"))
}

sem_rmsea_null <- function(spec) spec$population$rmsea_null %||% 0.05

webpower_rmsea_type <- function(spec) {
  if (identical(spec$target_test$method, "chi_square_not_close_fit")) "notclose" else "close"
}

webpower_rmsea_power <- function(spec, n, df, rmsea_null = sem_rmsea_null(spec)) {
  call_backend("WebPower", WebPower::wp.sem.rmsea(
    n = n, df = df, rmsea0 = rmsea_null, rmsea1 = spec$population$rmsea,
    alpha = spec$target_test$alpha, type = webpower_rmsea_type(spec)
  )$power)
}

webpower_rmsea_backend <- function(spec) {
  df <- sem_df(spec)
  power_at <- function(n) webpower_rmsea_power(spec, n, df)
  list(
    name = "WebPower",
    packages = c("WebPower", if (sem_from_shape(spec)) c("semPower", "lavaan")),
    methods = "exact",
    default_method = "exact",
    functions = c(exact = sprintf("WebPower::wp.sem.rmsea(type = \"%s\")", webpower_rmsea_type(spec))),
    n_step = 1,
    exact_min_n = minimum_n(spec),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() webpower_rmsea_check_run(spec, df)
  )
}

# Check run: WebPower receives the two RMSEAs and the df, and with the
# null RMSEA set to 0 its test of close fit gives semPower's power for the
# test of exact fit at an example N of 200 (two packages, one formula).
webpower_rmsea_check_run <- function(spec, df) {
  pop <- spec$population
  out <- call_backend("WebPower", WebPower::wp.sem.rmsea(
    n = 200, df = df, rmsea0 = sem_rmsea_null(spec), rmsea1 = pop$rmsea,
    alpha = spec$target_test$alpha, type = webpower_rmsea_type(spec)
  ))
  exact_webpower <- call_backend("WebPower", WebPower::wp.sem.rmsea(
    n = 200, df = df, rmsea0 = 0, rmsea1 = pop$rmsea, alpha = spec$target_test$alpha, type = "close"
  )$power)
  exact_sempower <- call_backend("semPower", quietly(semPower::semPower.postHoc(
    effect = pop$rmsea, effect.measure = "RMSEA", alpha = spec$target_test$alpha, N = 200, df = df
  )))$power
  row <- function(parameter, specified, passed, tolerance = 1e-8) {
    data.frame(parameter = parameter, specified = specified, recovered = passed,
      ok = isTRUE(all.equal(specified, passed, tolerance = tolerance)))
  }
  rbind(
    row("population RMSEA passed to WebPower (rmsea1)", pop$rmsea, out$rmsea1),
    row("RMSEA of the null hypothesis passed to WebPower (rmsea0)", sem_rmsea_null(spec), out$rmsea0),
    row("degrees of freedom passed to WebPower (df)", df, out$df),
    row("at a null RMSEA of 0, WebPower's power (N = 200) equals semPower's test of exact fit", exact_sempower, exact_webpower, 1e-6)
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

sempower_post_hoc <- function(spec, n, df) {
  call_backend("semPower", quietly(semPower::semPower.postHoc(
    effect = spec$population$rmsea, effect.measure = "RMSEA",
    alpha = spec$target_test$alpha, N = n, df = df
  )))
}

sempower_power <- function(spec, n, df) sempower_post_hoc(spec, n, df)$power

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
  post_hoc <- function(n) {
    call_backend("semPower", quietly(semPower::semPower.postHoc(
      effect = if (length(weights) > 1) as.list(base$fmin_groups) else base$fmin,
      effect.measure = "F0", alpha = spec$target_test$alpha,
      N = if (length(weights) > 1) as.list(n * weights) else n, df = base$df
    )))
  }
  power_at <- function(n) post_hoc(n)$power
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
    details = function(n) sempower_details(post_hoc(n), sem_function(spec)),
    check_run = function() sem_restriction_check_run(spec, base, power_at)
  )
}

sem_over_time <- function(spec) identical(spec$population$over, "occasions")

sem_function <- function(spec) {
  switch(
    spec$template,
    invariance = if (sem_over_time(spec)) "semPower::semPower.powerLI" else "semPower::semPower.powerMI",
    factor_correlation = "semPower::semPower.powerCFA",
    latent_regression = "semPower::semPower.powerRegression"
  )
}

# The share of the total N in each group: two groups in the ratio
# 1 : allocation_ratio (equal by default), three or more equal groups;
# one group otherwise.
sem_group_weights <- function(spec) {
  if (!identical(spec$template, "invariance") || sem_over_time(spec)) {
    return(1)
  }
  groups <- sem_invariance_groups(spec$population)
  if (groups > 2) {
    return(rep(1 / groups, groups))
  }
  ratio <- spec$options$allocation_ratio %||% 1
  c(1, ratio) / (1 + ratio)
}

# Invariance: the number of groups (2 by default), occasions (2) and
# factors (1).
sem_invariance_groups <- function(pop) pop$n_groups %||% 2L
sem_invariance_occasions <- function(pop) pop$n_occasions %||% 2L
sem_invariance_factors <- function(pop) pop$factors %||% 1L

# semPower's arguments for invariance. Every item loads `loading` on its
# factor; the first factor's last `noninvariant` items differ in the last
# group (or on the last occasion): their loading is `loading_group2`
# (metric) or their intercepts are shifted by `intercept_difference`
# (scalar). Across groups, the factors correlate `factor_correlation`.
# Over occasions, a factor correlates `stability` with itself on every
# other occasion, two factors `factor_correlation` on the same occasion,
# and two factors on different occasions the product of the two (the
# factor correlation matrix is the Kronecker product of the occasions'
# and the factors' matrices, so it is always a valid one). semPower's
# order is F1_T1, F2_T1, ..., F1_T2, ... (semPower.powerLI()'s help).
sem_invariance_args <- function(pop, over_time) {
  k <- pop$indicators
  n_factors <- sem_invariance_factors(pop)
  units <- if (over_time) sem_invariance_occasions(pop) else sem_invariance_groups(pop)
  differ <- seq.int(k - pop$noninvariant + 1, k)
  metric <- identical(pop$level, "metric")
  r_factors <- matrix(pop$factor_correlation %||% 0, n_factors, n_factors)
  diag(r_factors) <- 1
  # The loadings in one group or on one occasion: a list of factors.
  loadings_in <- function(unit) {
    lapply(seq_len(n_factors), function(f) {
      x <- rep(pop$loading, k)
      if (metric && f == 1 && unit == units) x[differ] <- pop$loading_group2
      x
    })
  }
  # The intercepts in one group or on one occasion: all items, factor by
  # factor.
  tau_in <- function(unit) {
    x <- rep(0, k * n_factors)
    if (unit == units) x[differ] <- pop$intercept_difference
    x
  }
  loadings <- lapply(seq_len(units), loadings_in)
  if (over_time) {
    r_time <- matrix(pop$stability, units, units)
    diag(r_time) <- 1
    phi <- kronecker(r_time, r_factors)
    # One factor: semPower takes one vector per occasion.
    if (n_factors == 1) loadings <- lapply(loadings, `[[`, 1)
    args <- list(Phi = phi, loadings = loadings)
  } else {
    args <- list(loadings = loadings)
    if (n_factors > 1) args$Phi <- rep(list(r_factors), units)
  }
  if (metric) {
    return(c(list(comparison = "configural", nullEffect = "metric"), args))
  }
  # Scalar: the loadings are the same everywhere.
  # (Across groups, one list of factors stands for every group.)
  args$loadings <- if (over_time) rep(list(if (n_factors == 1) rep(pop$loading, k) else loadings_in(0)), units) else loadings_in(0)
  c(
    list(comparison = "metric", nullEffect = "scalar"), args,
    list(tau = lapply(seq_len(units), tau_in), Alpha = rep(list(rep(0, n_factors)), units))
  )
}

# The arguments semPower's function takes for the spec's model, without
# the type of power analysis.
sem_restriction_args <- function(spec) {
  pop <- spec$population
  switch(
    spec$template,
    invariance = sem_invariance_args(pop, sem_over_time(spec)),
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

# The design in words, for the script's header and the methods paragraph.
sem_invariance_description <- function(spec) {
  pop <- spec$population
  over_time <- sem_over_time(spec)
  n_factors <- sem_invariance_factors(pop)
  where <- if (over_time) {
    sprintf("over %d occasions (stability %s)", sem_invariance_occasions(pop), format_number(pop$stability))
  } else {
    sprintf("across %d groups", sem_invariance_groups(pop))
  }
  factors <- if (n_factors == 1) {
    sprintf("one factor of %s items", pop$indicators)
  } else {
    sprintf("%d factors of %s items each (correlation %s)", n_factors, pop$indicators, format_number(pop$factor_correlation))
  }
  last <- if (over_time) "on the last occasion" else "in the last group"
  sprintf(
    "measurement invariance %s: chi-square difference test of %s invariance, %s (loading %s), %s of the first factor's items %s %s",
    where, pop$level, factors, pop$loading, pop$noninvariant,
    if (identical(pop$level, "metric")) sprintf("with loading %s", pop$loading_group2)
    else sprintf("with intercepts shifted by %s SD", pop$intercept_difference),
    last
  )
}

sem_invariance_df <- function(spec) {
  pop <- spec$population
  units <- if (sem_over_time(spec)) sem_invariance_occasions(pop) else sem_invariance_groups(pop)
  (units - 1) * sem_invariance_factors(pop) * (pop$indicators - 1)
}

# Check run: no simulated data. The check confirms that semPower's own
# function and the shortcut through its F0 agree on power at the
# reference N, and that the restriction has the df expected.
sem_restriction_check_run <- function(spec, base, power_at) {
  # One restriction for a correlation or a slope. Invariance restricts
  # every loading (or intercept) but one of each factor in every group or
  # occasion after the first: that group's factor variance (or mean) is
  # freed in its place, as in lavaan.
  expected_df <- if (identical(spec$template, "invariance")) sem_invariance_df(spec) else 1
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
    fit_test = switch(spec$target_test$method %||% "chi_square_exact_fit",
      chi_square_close_fit = "close", chi_square_not_close_fit = "not_close", "exact"),
    rmsea_null = if (sem_close_fit_test(spec)) sem_rmsea_null(spec),
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
  if (sem_close_fit_test(spec)) {
    return(webpower_rmsea_script(spec, result))
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

# The R script for the tests of close and not-close fit: WebPower's
# wp.sem.rmsea() at each n, as powerkit calls it.
webpower_rmsea_script <- function(spec, result) {
  pop <- spec$population
  type <- webpower_rmsea_type(spec)
  df_lines <- if (sem_from_shape(spec)) {
    c(
      sprintf("# The model: %s items on %s correlated factors, each item on one factor.", pop$indicators, pop$factors),
      "# semPower counts its degrees of freedom with lavaan.",
      sprintf("model <- %s", r_code(sem_cfa_syntax(pop$indicators, pop$factors))),
      "df <- semPower::semPower.getDf(model)"
    )
  } else {
    sprintf("df <- %s # the model's degrees of freedom", r_code(pop$df))
  }
  c(
    script_header(spec, result, "WebPower", sprintf("WebPower::wp.sem.rmsea(type = \"%s\")", type)),
    "library(WebPower)",
    "",
    "# Inputs ----",
    sprintf("rmsea <- %s # the model's RMSEA in the population", r_code(pop$rmsea)),
    sprintf("rmsea_null <- %s # the RMSEA of the null hypothesis (close fit: at most this; not-close fit: at least this)", r_code(sem_rmsea_null(spec))),
    df_lines,
    goal_inputs(spec, result),
    "",
    if (identical(type, "close")) {
      "# Power of the test of close fit (MacCallum, Browne and Sugawara, 1996) to reject close fit when the model's RMSEA is rmsea."
    } else {
      "# Power of the test of not-close fit (MacCallum, Browne and Sugawara, 1996) to reject not-close fit, supporting close fit, when the model's RMSEA is rmsea."
    },
    "power_at <- function(n_total) {",
    sprintf("  wp.sem.rmsea(n = n_total, df = df, rmsea0 = rmsea_null, rmsea1 = rmsea, alpha = alpha, type = \"%s\")$power", type),
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
