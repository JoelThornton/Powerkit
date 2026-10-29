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
#
# A correlation (template tost_correlation): TOSTER::power_z_cor() with
# alternative = "equivalence", rho the expected correlation and null the
# bound (TOSTER tests -bound and +bound), the two one-sided z tests on
# Fisher's z scale. Two proportions (tost_two_proportions):
# TOSTER::power_twoprop() with alternative = "equivalence", p1 and p2 and
# null the bound on p2 - p1; n is per group, the two groups equal.

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
  if (spec$template %in% c("tost_correlation", "tost_two_proportions")) {
    return(toster_z_backend(spec, inputs))
  }
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
  alpha <- spec$target_test$alpha
  if (identical(spec$template, "tost_correlation")) {
    return(list(fun = "power_z_cor", args = function(n) {
      list(n = n, rho = pop$r, null = pop$bound, alpha = alpha, alternative = "equivalence")
    }))
  }
  if (identical(spec$template, "tost_two_proportions")) {
    return(list(fun = "power_twoprop", args = function(n) {
      list(p1 = pop$p1, p2 = pop$p2, n = n / 2, null = pop$bound, alpha = alpha, alternative = "equivalence")
    }))
  }
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

# A correlation or two proportions: TOSTER's z tests.
toster_z_backend <- function(spec, inputs) {
  step <- valid_n_step(spec)
  power_at <- function(n) {
    out <- call_backend("TOSTER", quietly(do.call(getExportedValue("TOSTER", inputs$fun), inputs$args(n))))
    out$power
  }
  list(
    name = "TOSTER",
    packages = "TOSTER",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = paste0("TOSTER::", inputs$fun)),
    n_step = step,
    exact_min_n = step * ceiling(minimum_n(spec) / step),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() toster_check_run(spec, inputs)
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
  if (!is.null(inputs$fun)) {
    passed <- if (identical(inputs$fun, "power_z_cor")) {
      data.frame(parameter = c("expected correlation passed to TOSTER (rho)", "equivalence bound passed to TOSTER (null)"),
                 specified = c(pop$r, pop$bound), recovered = c(args$rho, args$null))
    } else {
      data.frame(parameter = c("p1 passed to TOSTER", "p2 passed to TOSTER", "equivalence bound passed to TOSTER (null)", "people per group at n = 100"),
                 specified = c(pop$p1, pop$p2, pop$bound, 50), recovered = c(args$p1, args$p2, args$null, args$n))
    }
    passed$ok <- mapply(function(a, b) isTRUE(all.equal(a, b)), passed$specified, passed$recovered)
    return(passed)
  }
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
  if (!is.null(inputs$fun)) {
    return(toster_z_script(spec, result, inputs))
  }
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

# The R script for the equivalence of a correlation or of two proportions.
toster_z_script <- function(spec, result, inputs) {
  pop <- spec$population
  correlation <- identical(inputs$fun, "power_z_cor")
  values <- if (correlation) {
    sprintf("rho <- %s # the expected true correlation", r_code(pop$r))
  } else {
    c(
      sprintf("p1 <- %s # the expected proportion in group 1", r_code(pop$p1)),
      sprintf("p2 <- %s # the expected proportion in group 2", r_code(pop$p2))
    )
  }
  call <- if (correlation) {
    "  power_z_cor(n = n_total, rho = rho, null = bound, alpha = alpha, alternative = \"equivalence\")$power"
  } else {
    c(
      "  # TOSTER takes the size of each group; the two groups are equal.",
      "  power_twoprop(p1 = p1, p2 = p2, n = n_total / 2, null = bound, alpha = alpha, alternative = \"equivalence\")$power"
    )
  }
  c(
    script_header(spec, result, "TOSTER", paste0("TOSTER::", inputs$fun)),
    "library(TOSTER)",
    "",
    "# Inputs ----",
    values,
    sprintf("bound <- %s # equivalence bounds -bound and +bound%s", r_code(pop$bound), if (correlation) "" else ", on the difference p2 - p1"),
    goal_inputs(spec, result),
    "",
    "# Power of the two one-sided tests at a total sample size.",
    "power_at <- function(n_total) {",
    call,
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}
