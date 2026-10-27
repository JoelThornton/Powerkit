# Backend adapter: equivalence tests (two one-sided tests, TOST) by exact
# formula, via TOSTER.
#
# TOSTER::power_t_TOST() gives the exact power of TOST for one sample, two
# independent samples and paired samples. Its help (TOSTER 0.8.6) says the
# exact power comes from Owen's Q-function or direct integration of the
# bivariate noncentral t distribution, after the PowerTOST package, and
# cites Phillips (1990) and Diletti, Hauschke and Steinijans (1991).
#
# powerkit passes the effect and the bounds in SD units: delta = the
# expected difference (d, or d_z for paired data), sd = 1, and the bounds
# -bound and +bound (eqb = c(-bound, bound)). Each one-sided test is at
# level alpha, as TOST is defined (TOSTER's own default). n is per group
# for two samples (a vector of the two group sizes when they differ) and
# the number of people (or pairs) otherwise.

toster_type <- function(spec) {
  switch(
    spec$template,
    tost_independent = "two.sample",
    tost_paired = "paired",
    tost_one_sample = "one.sample"
  )
}

toster_backend <- function(spec, seed = NULL) {
  inputs <- toster_inputs(spec)
  step <- valid_n_step(spec)
  n_min <- step * ceiling(minimum_n(spec) / step)
  power_at <- function(n) toster_power(inputs, n)
  list(
    name = "TOSTER",
    packages = "TOSTER",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = "TOSTER::power_t_TOST"),
    n_step = step,
    exact_min_n = n_min,
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() toster_check_run(spec, inputs)
  )
}

# The arguments to power_t_TOST() at total sample size n.
toster_inputs <- function(spec) {
  pop <- spec$population
  ratio <- spec$options$allocation_ratio %||% 1
  type <- toster_type(spec)
  delta <- if (identical(type, "paired")) pop$dz else pop$d
  sizes <- function(n) {
    if (!identical(type, "two.sample")) {
      return(n)
    }
    n1 <- round(n / (1 + ratio))
    if (n1 == n - n1) n1 else c(n1, n - n1)
  }
  list(
    type = type,
    delta = delta,
    bound = pop$bound,
    alpha = spec$target_test$alpha,
    args = function(n) {
      list(
        n = sizes(n), delta = delta, sd = 1, eqb = c(-pop$bound, pop$bound),
        alpha = spec$target_test$alpha, type = type
      )
    }
  )
}

toster_power <- function(inputs, n) {
  out <- call_backend("TOSTER", quietly(do.call(TOSTER::power_t_TOST, inputs$args(n))))
  out$power
}

# Check run: there is no simulated data, so the check confirms TOSTER
# receives the expected difference and the bounds the spec gives.
toster_check_run <- function(spec, inputs) {
  args <- inputs$args(100)
  pop <- spec$population
  specified <- if (identical(inputs$type, "paired")) pop$dz else pop$d
  name <- if (identical(inputs$type, "paired")) "d_z" else "d"
  row <- function(parameter, spec_value, passed) {
    data.frame(
      parameter = parameter, specified = spec_value, recovered = passed,
      ok = isTRUE(all.equal(spec_value, passed))
    )
  }
  rbind(
    row(sprintf("expected difference (%s) passed to TOSTER (delta, with sd = 1)", name), specified, args$delta),
    row("lower equivalence bound passed to TOSTER", -pop$bound, args$eqb[1]),
    row("upper equivalence bound passed to TOSTER", pop$bound, args$eqb[2])
  )
}

# The R script for an equivalence test: the same TOSTER call at each size
# powerkit computed (export_script()).
toster_script <- function(spec, result) {
  inputs <- toster_inputs(spec)
  ratio <- spec$options$allocation_ratio %||% 1
  effect_name <- if (identical(inputs$type, "paired")) "d_z" else "d"
  n_lines <- switch(
    inputs$type,
    two.sample = c(
      sprintf("  n1 <- round(n_total / (1 + %s)) # group 1 (allocation 1 : %s)", r_code(ratio), format_number(ratio)),
      "  n2 <- n_total - n1",
      "  n <- if (n1 == n2) n1 else c(n1, n2) # TOSTER takes the size of each group"
    ),
    paired = "  n <- n_total # the number of people (pairs of measurements)",
    one.sample = "  n <- n_total"
  )
  c(
    script_header(spec, result, "TOSTER", "TOSTER::power_t_TOST"),
    "library(TOSTER)",
    "",
    "# Inputs ----",
    sprintf(
      "delta <- %s # the expected true difference, as %s (in SDs%s)",
      r_code(inputs$delta), effect_name, if (identical(inputs$type, "paired")) " of the differences" else ""
    ),
    sprintf("bound <- %s # equivalence bounds -bound and +bound, in the same SD units", r_code(inputs$bound)),
    goal_inputs(spec, result),
    "",
    "# Power of the two one-sided tests at a total sample size. Each one-sided",
    "# test is at level alpha, as TOST is defined.",
    "power_at <- function(n_total) {",
    n_lines,
    "  power_t_TOST(",
    sprintf("    n = n, delta = delta, sd = 1, eqb = c(-bound, bound), alpha = alpha, type = %s", r_code(inputs$type)),
    "  )$power",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}
