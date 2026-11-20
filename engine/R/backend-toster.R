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
# A correlation (template tost_correlation) and two proportions
# (tost_two_proportions) are not planned with TOSTER's own planning
# functions, which give wrong answers (docs/conventions.md, Departure 33):
# TOSTER 0.8.6's power_z_cor() never uses the expected correlation (its
# power is the power when the true correlation is 0), and power_twoprop()
# applies the distance to the nearer bound on both sides. powerkit plans
# the tests TOSTER runs, z_cor_test() and twoprop_test(), with pwrss: the
# correlation's two one-sided z tests on Fisher's z scale (SE 1 / sqrt(n -
# 3)) by pwrss::power.z.test() with alternative "two.one.sided", the
# statistic's mean atanh(r) sqrt(n - 3) and the bounds atanh(+-bound)
# sqrt(n - 3); the proportions' two one-sided Wald z tests (unpooled SE,
# as twoprop_test()) by pwrss::power.z.twoprops() with alternative
# "two.one.sided" and margins -bound and +bound on p2 - p1. n is per group
# for two proportions, the two groups equal.

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
    sensitivity = function(n, power) formula_search_sensitivity(spec, n, power),
    check_run = function() toster_check_run(spec, inputs)
  )
}

# The arguments to power_t_TOST() at total sample size n.
toster_inputs <- function(spec) {
  pop <- spec$population
  ratio <- allocation_ratio(spec)
  alpha <- spec$target_test$alpha
  # pwrss reads "two.one.sided" as equivalence only with the expected value
  # strictly inside the bounds; at a bound (allowed for power at a given n)
  # it is moved inside by a hair, where the power is alpha.
  inside <- function(value, bound) if (abs(value) >= bound) sign(value) * bound * (1 - 1e-9) else value
  if (identical(spec$template, "tost_correlation")) {
    return(list(fun = "power.z.test", args = function(n) {
      scale <- sqrt(n - 3)
      list(mean = atanh(inside(pop$r, pop$bound)) * scale, sd = 1, null.mean = atanh(c(-pop$bound, pop$bound)) * scale,
        null.sd = 1, alpha = alpha, alternative = "two.one.sided", plot = FALSE, verbose = 0)
    }))
  }
  if (identical(spec$template, "tost_two_proportions")) {
    return(list(fun = "power.z.twoprops", args = function(n) {
      # pwrss's difference is prob1 - prob2: group 2's proportion goes first.
      list(prob1 = pop$p1 + inside(pop$p2 - pop$p1, pop$bound), prob2 = pop$p1, margin = c(-pop$bound, pop$bound),
        n2 = n / 2, n.ratio = 1, alpha = alpha, alternative = "two.one.sided", std.error = "unpooled",
        ceil.n = FALSE, verbose = 0)
    }))
  }
  type <- toster_type(spec)
  delta <- if (identical(type, "paired")) pop$dz else pop$d
  sizes <- function(n) {
    if (!identical(type, "two.sample")) {
      return(n)
    }
    n1 <- floor(n / (1 + ratio) + 0.5)
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

# A correlation or two proportions: TOSTER's z tests, planned by pwrss.
toster_z_backend <- function(spec, inputs) {
  step <- valid_n_step(spec)
  power_at <- function(n) {
    out <- call_backend("pwrss", quietly(do.call(getExportedValue("pwrss", inputs$fun), inputs$args(n))))
    out$power
  }
  list(
    name = "pwrss",
    packages = "pwrss",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = paste0("pwrss::", inputs$fun)),
    n_step = step,
    exact_min_n = step * ceiling(minimum_n(spec) / step),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = function(n, power) formula_search_sensitivity(spec, n, power),
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
  pop <- spec$population
  # The smallest detectable effect searches the bound (sensitivity-search.R):
  # with none entered, the check is of the expected difference alone.
  searched <- is.null(pop$bound)
  if (searched) {
    spec$population$bound <- 1
    pop <- spec$population
    inputs <- toster_inputs(spec)
  }
  args <- inputs$args(100)
  keep <- function(passed) if (searched) passed[!grepl("bound", passed$parameter), , drop = FALSE] else passed
  if (!is.null(inputs$fun)) {
    passed <- if (identical(inputs$fun, "power.z.test")) {
      data.frame(parameter = c("expected correlation passed to pwrss (Fisher z of the statistic's mean, back-transformed)",
        "equivalence bound passed to pwrss (Fisher z, back-transformed)"),
        specified = c(pop$r, pop$bound), recovered = c(tanh(args$mean / sqrt(97)), tanh(args$null.mean[2] / sqrt(97))))
    } else {
      data.frame(parameter = c("p1 passed to pwrss (prob2)", "p2 passed to pwrss (prob1)", "equivalence bound passed to pwrss (margin)", "people per group at n = 100"),
                 specified = c(pop$p1, pop$p2, pop$bound, 50), recovered = c(args$prob2, args$prob1, args$margin[2], args$n2))
    }
    # A value at the bound is moved inside by a hair (toster_inputs()).
    passed$ok <- mapply(function(a, b) isTRUE(all.equal(a, b, tolerance = 1e-8)), passed$specified, passed$recovered)
    return(keep(passed))
  }
  specified <- if (identical(inputs$type, "paired")) pop$dz else pop$d
  name <- if (identical(inputs$type, "paired")) "d_z" else "d"
  row <- function(parameter, spec_value, passed) {
    data.frame(
      parameter = parameter, specified = spec_value, recovered = passed,
      ok = isTRUE(all.equal(spec_value, passed))
    )
  }
  keep(rbind(
    row(sprintf("expected difference (%s) passed to TOSTER (delta, with sd = 1)", name), specified, args$delta),
    row("lower equivalence bound passed to TOSTER", -pop$bound, args$eqb[1]),
    row("upper equivalence bound passed to TOSTER", pop$bound, args$eqb[2])
  ))
}

# The R script for an equivalence test: the same TOSTER call at each size
# powerkit computed (export_script()).
toster_script <- function(spec, result) {
  inputs <- toster_inputs(spec)
  if (!is.null(inputs$fun)) {
    return(toster_z_script(spec, result, inputs))
  }
  ratio <- allocation_ratio(spec)
  effect_name <- if (identical(inputs$type, "paired")) "d_z" else "d"
  n_lines <- switch(
    inputs$type,
    two.sample = c(
      sprintf("  n1 <- floor(n_total / (1 + %s) + 0.5) # group 1 (allocation 1 : %s)", r_code(ratio), format_number(ratio)),
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

# The R script for the equivalence of a correlation or of two proportions:
# the same pwrss call at each size powerkit computed.
toster_z_script <- function(spec, result, inputs) {
  pop <- spec$population
  correlation <- identical(inputs$fun, "power.z.test")
  args <- inputs$args(100)
  values <- if (correlation) {
    sprintf("rho <- %s # the expected true correlation", r_code(pop$r))
  } else {
    c(
      sprintf("p1 <- %s # the expected proportion in group 1", r_code(pop$p1)),
      sprintf("p2 <- %s # the expected proportion in group 2", r_code(pop$p2))
    )
  }
  at_bound <- if (correlation) abs(pop$r) >= pop$bound else abs(pop$p2 - pop$p1) >= pop$bound
  call <- if (correlation) {
    c(
      "  # TOSTER's z_cor_test(): two one-sided z tests on Fisher's z scale,",
      "  # standard error 1 / sqrt(n - 3), each at level alpha.",
      "  scale <- sqrt(n_total - 3)",
      if (at_bound) "  rho <- sign(rho) * bound * (1 - 1e-9) # pwrss needs the value strictly inside the bounds; the power is alpha",
      "  power.z.test(mean = atanh(rho) * scale, sd = 1, null.mean = atanh(c(-bound, bound)) * scale, null.sd = 1,",
      "    alpha = alpha, alternative = \"two.one.sided\", plot = FALSE, verbose = 0)$power"
    )
  } else {
    c(
      "  # TOSTER's twoprop_test(): two one-sided Wald z tests (unpooled",
      "  # standard error) of p2 - p1; pwrss's difference is prob1 - prob2, and",
      "  # n2 is the size of each group (equal groups).",
      if (at_bound) "  p2 <- p1 + sign(p2 - p1) * bound * (1 - 1e-9) # pwrss needs the difference strictly inside the bounds; the power is alpha",
      "  power.z.twoprops(prob1 = p2, prob2 = p1, margin = c(-bound, bound), n2 = n_total / 2, n.ratio = 1,",
      "    alpha = alpha, alternative = \"two.one.sided\", std.error = \"unpooled\", ceil.n = FALSE, verbose = 0)$power"
    )
  }
  c(
    script_header(spec, result, "pwrss", paste0("pwrss::", inputs$fun)),
    "library(pwrss)",
    "",
    "# Inputs ----",
    values,
    sprintf("bound <- %s # equivalence bounds -bound and +bound%s", r_code(pop$bound), if (correlation) "" else ", on the difference p2 - p1"),
    goal_inputs(spec, result),
    "",
    "# Power of the two one-sided tests at a total sample size. (powerkit",
    "# doesn't use TOSTER's planning functions here: power_z_cor() ignores the",
    "# expected correlation, and power_twoprop() applies the nearer bound's",
    "# distance to both sides; powerkit's Departure 33.)",
    "power_at <- function(n_total) {",
    call,
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}
