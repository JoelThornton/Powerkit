# Backend adapter: clustered designs by formula, via powertools.
#
#   cluster-randomised  cluster_trial/cluster_randomised: whole groups
#   trial               (classes, clinics, teams) are assigned to one of two
#                       conditions, the same number of groups in each, and a
#                       score is compared between them.
#                       powertools::crt.parallel.cont(): the t test (F with
#                       1 df when two-sided) of the difference between the
#                       conditions, its variance inflated by the design
#                       effect 1 + (m - 1) * ICC and, when group sizes vary,
#                       divided by powertools' relative efficiency
#                       (re.clustsize.cont()); degrees of freedom from the
#                       number of groups, J - 2.
#
# The spec's n is the total number of participants analysed: n / m groups
# of m (population > cluster_size), half of them in each condition, so the
# valid sizes are multiples of 2m. Functions and arguments were checked in
# powertools 1.0.0's help pages and sources (docs/conventions.md,
# "powertools").

powertools_backend <- function(spec, seed = NULL) {
  m <- spec$population$cluster_size
  step <- valid_n_step(spec)
  power_at <- function(n) powertools_power(spec, n)
  list(
    name = "powertools",
    packages = "powertools",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = "powertools::crt.parallel.cont"),
    n_step = step,
    # Two groups in each condition: the fewest powertools accepts (J1 >= 2).
    exact_min_n = 4 * m,
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = function(n, power) powertools_sensitivity(spec, n, power),
    check_run = function() powertools_check_run(spec)
  )
}

# powertools' arguments at a total of n participants. delta is the size of
# d (sd = 1, so delta / sd is d): its one-sided test runs in the direction
# of a positive delta, and validate_spec() refuses a one-sided test
# pointing away from the specified effect, so the size alone is passed.
powertools_args <- function(spec, n, delta = abs(spec$population$d)) {
  pop <- spec$population
  m <- pop$cluster_size
  alternative <- spec$target_test$alternative %||% "two_sided"
  list(
    m = m, m.sd = pop$cluster_size_sd %||% 0,
    J1 = n / m / 2, J.ratio = 1,
    delta = delta, sd = 1,
    icc1 = pop$icc, icc2 = pop$icc,
    alpha = spec$target_test$alpha,
    sides = if (alternative == "two_sided") 2 else 1,
    v = FALSE
  )
}

powertools_call <- function(args) {
  call_backend("powertools", quietly(do.call(powertools::crt.parallel.cont, args)))
}

powertools_power <- function(spec, n) {
  args <- powertools_args(spec, n)
  args$power <- NULL
  powertools_call(args)
}

# The smallest detectable d: powertools solves for delta when it is left
# NULL. It is positive; it takes the sign of the specified d (or of the
# one-sided test's direction), positive if neither gives one.
powertools_sensitivity <- function(spec, n, power) {
  args <- powertools_args(spec, n, delta = NULL)
  args$power <- power
  found <- powertools_call(args)
  negative <- isTRUE(spec$population$d < 0) || identical(spec$target_test$alternative, "less")
  reached <- powertools_call(utils::modifyList(powertools_args(spec, n, delta = found), list(power = NULL)))
  list(
    effect = if (negative) -found else found,
    effect_name = "d",
    power = reached,
    effect_description = "Cohen's d (the difference between the conditions / the outcome's total SD)"
  )
}

# Check run: no simulated data, so the check confirms powertools receives
# the values the spec gives, at an example size of 10 groups per condition.
powertools_check_run <- function(spec) {
  pop <- spec$population
  m <- pop$cluster_size
  args <- powertools_args(spec, 20 * m)
  row <- function(parameter, specified, passed) {
    data.frame(
      parameter = parameter, specified = specified, recovered = passed,
      ok = isTRUE(all.equal(specified, passed))
    )
  }
  rbind(
    row("size of d passed to powertools (delta, with sd = 1)", abs(pop$d), args$delta / args$sd),
    row("ICC passed to powertools (icc1, icc2)", c(pop$icc, pop$icc), c(args$icc1, args$icc2)),
    row("group size passed to powertools (m)", m, args$m),
    row("SD of group sizes passed to powertools (m.sd)", pop$cluster_size_sd %||% 0, args$m.sd),
    row("groups per condition at 20 groups in all (J1, J.ratio)", c(10, 1), c(args$J1, args$J.ratio))
  )
}

#' How the grouping changes a clustered design's sample size
#'
#' For a cluster-randomised trial (design `cluster_trial`), the numbers of
#' groups at a total of `n` participants, and how many independent
#' participants they are worth. The design effect is
#' 1 + (group size - 1) * ICC, the factor by which powertools'
#' `crt.parallel.cont()` inflates the variance of the difference between
#' conditions when there are no covariates; when group sizes vary it is
#' divided by powertools' relative efficiency, `re.clustsize.cont()`.
#' The effective sample size is `n` divided by the design effect.
#'
#' @param spec A validated spec with design `cluster_trial`.
#' @param n Total number of participants analysed.
#'
#' @return `NULL` for other designs; otherwise a list with `cluster_size`,
#'   `clusters` (in all), `clusters_per_condition`, `icc`,
#'   `relative_efficiency` (1 for groups of equal size), `design_effect`
#'   and `effective_n`.
#' @export
cluster_summary <- function(spec, n) {
  if (!identical(spec$design, "cluster_trial") || length(n) != 1 || is.na(n)) {
    return(NULL)
  }
  pop <- spec$population
  m <- pop$cluster_size
  m_sd <- pop$cluster_size_sd %||% 0
  re <- if (m_sd > 0) {
    call_backend("powertools", quietly(powertools::re.clustsize.cont(m = m, m.sd = m_sd, icc = pop$icc)))
  } else {
    1
  }
  design_effect <- (1 + (m - 1) * pop$icc) / re
  list(
    cluster_size = m,
    clusters = n / m,
    clusters_per_condition = n / m / 2,
    icc = pop$icc,
    relative_efficiency = re,
    design_effect = design_effect,
    effective_n = n / design_effect
  )
}

# The R script for a cluster-randomised trial: the same powertools call
# as powerkit's, with the values written out.
powertools_script <- function(spec, result) {
  pop <- spec$population
  v <- spec$variables
  lv <- function(i) comment_text(unlist(v$X$levels)[i])
  alternative <- spec$target_test$alternative %||% "two_sided"
  sides <- if (alternative == "two_sided") 2 else 1
  call_lines <- function(delta, power = NULL) {
    args <- c(
      "m = cluster_size # participants in each group (the average, if sizes vary)",
      "m.sd = cluster_size_sd # SD of the group sizes (0: all the same size)",
      "J1 = n_total / cluster_size / 2 # groups in the first condition",
      "J.ratio = 1 # the same number of groups in each condition",
      sprintf("delta = %s", delta), "sd = 1 # so delta is Cohen's d",
      "icc1 = icc", "icc2 = icc # the same ICC in both conditions",
      "alpha = alpha",
      if (!is.null(power)) sprintf("power = %s", power),
      sprintf("sides = %s # %s", sides, if (sides == 2) "two-sided test" else "one-sided, in the direction of the specified effect")
    )
    c("crt.parallel.cont(", paste0("    ", ensure_commas(args)), "  )")
  }
  goal_lines <- if (spec$goal$type == "sensitivity") {
    s <- result$sensitivity
    c(
      "# Smallest detectable effect ----",
      "# powertools finds the effect itself when delta is left NULL; it is",
      "# positive, and takes the direction of the effect you specified.",
      (function(cl) c(paste0("found <- ", cl[1]), cl[-1]))(call_lines("NULL", "target_power")),
      sprintf("d <- %sfound", if (s$effect < 0) "-" else ""),
      "power <- power_at(n_total, d)",
      "cat(sprintf(\"Smallest detectable effect: Cohen's d = %.4g (power %.4f)\\n\", d, power))",
      "",
      "reproduced <- list(effect = d, power = power)",
      sprintf("powerkit_result <- list(effect = %s, power = %s)", r_code(s$effect), r_code(s$power)),
      ""
    )
  } else {
    pwr_goal_section(spec, result)
  }
  c(
    script_header(spec, result, "powertools", "powertools::crt.parallel.cont()"),
    "library(powertools)",
    "",
    "# Inputs ----",
    sprintf("d <- %s # Cohen's d: (mean in %s minus mean in %s) / the outcome's total SD", r_code(pop$d), lv(2), lv(1)),
    sprintf("icc <- %s # intraclass correlation: share of the outcome's variance between groups", r_code(pop$icc)),
    sprintf("cluster_size <- %s # participants analysed in each group", r_code(pop$cluster_size)),
    sprintf("cluster_size_sd <- %s # SD of the group sizes", r_code(pop$cluster_size_sd %||% 0)),
    goal_inputs(spec, result),
    "",
    "# Power at a total sample size (groups x group size), from powertools'",
    "# formula. Its one-sided test runs in the direction of a positive delta,",
    "# so the size of d is passed.",
    "power_at <- function(n_total, d_value = d) {",
    paste0("  ", call_lines("abs(d_value)")),
    "}",
    "",
    goal_lines,
    comparison_section()
  )
}
