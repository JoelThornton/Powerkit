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

#' The model behind a structural equation model's power analysis
#'
#' For a model-fit power analysis (design `sem`), the model's degrees of
#' freedom and, for a confirmatory factor analysis described by its number
#' of items and factors, the lavaan model semPower counted them from.
#'
#' @param spec A validated spec with design `sem`.
#'
#' @return `NULL` for other designs; otherwise a list with `rmsea`, `df`,
#'   `indicators` and `factors` (`NULL` when the spec gives the df), and
#'   `model` (the lavaan model, or `NULL`).
#' @export
sem_summary <- function(spec) {
  if (!identical(spec$design, "sem")) {
    return(NULL)
  }
  pop <- spec$population
  list(
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
