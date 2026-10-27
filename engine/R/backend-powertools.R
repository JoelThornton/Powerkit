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
#   multisite trial     cluster_trial/multisite: within each group, people
#                       are randomised to one of two conditions, half to
#                       each, and a score is compared between them.
#                       powertools::multisite.cont(): the t test (F with 1
#                       df when two-sided) of the average difference between
#                       the conditions, its variance set by the ICC of the
#                       group means (icc0) and of the effect across groups
#                       (icc1), divided by the relative efficiency when group
#                       sizes vary; degrees of freedom J - 1.
#
# The spec's n is the total number of participants analysed: n / m groups
# of m (population > cluster_size). In a cluster-randomised trial half the
# groups are in each condition, so the valid sizes are multiples of 2m; in
# a multisite trial every group has both conditions, so they are multiples
# of m. Functions and arguments were checked in
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
    functions = c(exact = paste0("powertools::", powertools_function_name(spec))),
    n_step = step,
    # The fewest groups powertools accepts: two in each condition (J1 >= 2)
    # or, multisite, two in all (J >= 2).
    exact_min_n = minimum_n(spec),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = function(n, power) powertools_sensitivity(spec, n, power),
    check_run = function() powertools_check_run(spec)
  )
}

is_multisite <- function(spec) identical(spec$template, "multisite")

powertools_function_name <- function(spec) {
  if (is_multisite(spec)) "multisite.cont" else "crt.parallel.cont"
}

# powertools' arguments at a total of n participants. delta is the size of
# d (sd = 1, so delta / sd is d): its one-sided test runs in the direction
# of a positive delta, and validate_spec() refuses a one-sided test
# pointing away from the specified effect, so the size alone is passed.
powertools_args <- function(spec, n, delta = abs(spec$population$d)) {
  pop <- spec$population
  m <- pop$cluster_size
  alternative <- spec$target_test$alternative %||% "two_sided"
  sides <- if (alternative == "two_sided") 2 else 1
  if (is_multisite(spec)) {
    return(list(
      m = m, m.sd = pop$cluster_size_sd %||% 0,
      alloc.ratio = 1, J = n / m,
      delta = delta, sd = 1,
      icc0 = pop$icc, icc1 = pop$icc_effect, Rsq = 0,
      alpha = spec$target_test$alpha,
      sides = sides,
      v = FALSE
    ))
  }
  list(
    m = m, m.sd = pop$cluster_size_sd %||% 0,
    J1 = n / m / 2, J.ratio = 1,
    delta = delta, sd = 1,
    icc1 = pop$icc, icc2 = pop$icc,
    alpha = spec$target_test$alpha,
    sides = sides,
    v = FALSE
  )
}

powertools_call <- function(args, spec) {
  fun <- if (is_multisite(spec)) powertools::multisite.cont else powertools::crt.parallel.cont
  call_backend("powertools", quietly(do.call(fun, args)))
}

powertools_power <- function(spec, n) {
  args <- powertools_args(spec, n)
  args$power <- NULL
  powertools_call(args, spec)
}

# The smallest detectable d: powertools solves for delta when it is left
# NULL. It is positive; it takes the sign of the specified d (or of the
# one-sided test's direction), positive if neither gives one.
powertools_sensitivity <- function(spec, n, power) {
  args <- powertools_args(spec, n, delta = NULL)
  args$power <- power
  found <- powertools_call(args, spec)
  negative <- isTRUE(spec$population$d < 0) || identical(spec$target_test$alternative, "less")
  reached <- powertools_call(utils::modifyList(powertools_args(spec, n, delta = found), list(power = NULL)), spec)
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
  if (is_multisite(spec)) {
    args <- powertools_args(spec, 10 * m)
    return(rbind(
      row("size of d passed to powertools (delta, with sd = 1)", abs(pop$d), args$delta / args$sd),
      row("ICC of the group means passed to powertools (icc0)", pop$icc, args$icc0),
      row("ICC of the effect across groups passed to powertools (icc1)", pop$icc_effect, args$icc1),
      row("group size passed to powertools (m)", m, args$m),
      row("SD of group sizes passed to powertools (m.sd)", pop$cluster_size_sd %||% 0, args$m.sd),
      row("groups and split within each at 10 groups (J, alloc.ratio)", c(10, 1), c(args$J, args$alloc.ratio))
    ))
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
#' For a clustered design (design `cluster_trial`), the numbers of groups
#' at a total of `n` participants, and how many independent participants
#' they are worth. For a cluster-randomised trial the design effect is
#' 1 + (group size - 1) * ICC, the factor by which powertools'
#' `crt.parallel.cont()` inflates the variance of the difference between
#' conditions when there are no covariates. For a multisite trial it is
#' 1 - ICC + (group size - 1) * ICC of the effect, the same factor in
#' powertools' `multisite.cont()` with half of each group in each
#' condition: below 1 when the effect is the same in every group, because
#' differences between the groups' averages cancel out. When group sizes
#' vary, either is divided by powertools' relative efficiency,
#' `re.clustsize.cont()` (with the ICC of the effect, for a multisite
#' trial). The effective sample size is `n` divided by the design effect.
#'
#' @param spec A validated spec with design `cluster_trial`.
#' @param n Total number of participants analysed.
#'
#' @return `NULL` for other designs; otherwise a list with `assignment`
#'   ("groups" for a cluster-randomised trial, "people" for a multisite
#'   trial), `cluster_size`, `clusters` (in all), `clusters_per_condition`
#'   (`NA` for a multisite trial, whose groups have both conditions), `icc`,
#'   `icc_effect` (`NA` for a cluster-randomised trial),
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
  multisite <- is_multisite(spec)
  re_icc <- if (multisite) pop$icc_effect else pop$icc
  re <- if (m_sd > 0) {
    call_backend("powertools", quietly(powertools::re.clustsize.cont(m = m, m.sd = m_sd, icc = re_icc)))
  } else {
    1
  }
  design_effect <- if (multisite) {
    (1 - pop$icc + (m - 1) * pop$icc_effect) / re
  } else {
    (1 + (m - 1) * pop$icc) / re
  }
  list(
    assignment = if (multisite) "people" else "groups",
    cluster_size = m,
    clusters = n / m,
    clusters_per_condition = if (multisite) NA_real_ else n / m / 2,
    icc = pop$icc,
    icc_effect = if (multisite) pop$icc_effect else NA_real_,
    relative_efficiency = re,
    design_effect = design_effect,
    effective_n = n / design_effect
  )
}

# The R script for a clustered design: the same powertools call as
# powerkit's, with the values written out.
powertools_script <- function(spec, result) {
  pop <- spec$population
  v <- spec$variables
  lv <- function(i) comment_text(unlist(v$X$levels)[i])
  alternative <- spec$target_test$alternative %||% "two_sided"
  sides <- if (alternative == "two_sided") 2 else 1
  multisite <- is_multisite(spec)
  fun <- powertools_function_name(spec)
  call_lines <- function(delta, power = NULL) {
    args <- if (multisite) c(
      "m = cluster_size # participants in each group, both conditions (the average, if sizes vary)",
      "m.sd = cluster_size_sd # SD of the group sizes (0: all the same size)",
      "alloc.ratio = 1 # half of each group in each condition",
      "J = n_total / cluster_size # number of groups",
      sprintf("delta = %s", delta), "sd = 1 # so delta is Cohen's d",
      "icc0 = icc # ICC of the group means",
      "icc1 = icc_effect # ICC of the effect: how much it varies between groups",
      "alpha = alpha",
      if (!is.null(power)) sprintf("power = %s", power),
      sprintf("sides = %s # %s", sides, if (sides == 2) "two-sided test" else "one-sided, in the direction of the specified effect")
    ) else c(
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
    c(paste0(fun, "("), paste0("    ", ensure_commas(args)), "  )")
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
    script_header(spec, result, "powertools", paste0("powertools::", fun, "()")),
    "library(powertools)",
    "",
    "# Inputs ----",
    sprintf("d <- %s # Cohen's d: (mean in %s minus mean in %s) / the outcome's total SD", r_code(pop$d), lv(2), lv(1)),
    sprintf("icc <- %s # intraclass correlation: share of the outcome's variance between groups", r_code(pop$icc)),
    if (multisite) sprintf("icc_effect <- %s # share of the outcome's variance from the effect varying between groups", r_code(pop$icc_effect)),
    sprintf("cluster_size <- %s # participants analysed in each group%s", r_code(pop$cluster_size), if (multisite) ", half in each condition" else ""),
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
