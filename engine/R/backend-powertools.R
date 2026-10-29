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
#   yes/no outcome      population > metric "proportion", either design:
#                       powertools::crt.parallel.bin() or multisite.bin(),
#                       the z test of the log odds ratio from a mixed-effects
#                       logistic model with a random intercept for the group
#                       (cluster-randomised) or a random effect of the
#                       condition across groups (multisite). Both multiply
#                       the variance by 1.2 (their source; the help pages
#                       don't say why: docs/upstream-questions.md). No
#                       smallest detectable effect: powertools can't solve
#                       for the proportions.
#
#   group treatment     cluster_trial/group_treatment: people are randomised
#   trial               one by one, and those in the second condition receive
#                       it in groups (an individually randomised group
#                       treatment trial), so only that condition is
#                       clustered. powertools::irgtt.cont(): the t test with
#                       Satterthwaite degrees of freedom, the grouped
#                       condition's variance inflated by 1 + (m - 1) * ICC;
#                       or, for a yes/no outcome, irgtt.bin(): the z test of
#                       the difference in proportions with the same design
#                       effect. The same number of people in each condition,
#                       the same total SD in both (Theta = 1).
#
# A baseline score (population > baseline_r2_within, and for a
# cluster-randomised trial baseline_r2_between) is passed as one covariate:
# crt.parallel.cont()'s ncov = 1, RsqW and RsqB (degrees of freedom J - 3),
# or multisite.cont()'s Rsq. In crt.parallel.cont()'s design effect,
# 1 + (m (1 - RsqB) - 1) ICC - m RsqW (1 - 2 ICC) / (m - 1), RsqB scales the
# between-group variance and RsqW the within-group variance, so they are
# the shares of each that the baseline explains (its help page calls them
# shares of the total variance: docs/upstream-questions.md).
#
# The spec's n is the total number of participants analysed: n / m groups
# of m (population > cluster_size). In a cluster-randomised trial half the
# groups are in each condition, so the valid sizes are multiples of 2m; in
# a multisite trial every group has both conditions, so they are multiples
# of m; in a group treatment trial, n / 2 people are in J = n / (2m) groups
# and n / 2 people take part individually, so they are multiples of 2m.
# Functions and arguments were checked in
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
    sensitivity = if (is_binary_cluster(spec)) NULL else function(n, power) powertools_sensitivity(spec, n, power),
    check_run = function() powertools_check_run(spec)
  )
}

is_multisite <- function(spec) identical(spec$template, "multisite")

is_group_treatment <- function(spec) identical(spec$template, "group_treatment")

is_binary_cluster <- function(spec) identical(spec$population$metric, "proportion")

has_baseline <- function(spec) !is.null(spec$population$baseline_r2_within)

powertools_function_name <- function(spec) {
  paste0(
    if (is_multisite(spec)) "multisite" else if (is_group_treatment(spec)) "irgtt" else "crt.parallel",
    if (is_binary_cluster(spec)) ".bin" else ".cont"
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
  sides <- if (alternative == "two_sided") 2 else 1
  if (is_group_treatment(spec)) {
    # irgtt's m and J are the grouped (second) condition's group size and
    # number of groups; n is the number of people in the first condition.
    common <- list(m = m, J = n / m / 2, n = n / 2)
    effect <- if (is_binary_cluster(spec)) {
      list(p1 = pop$p1, p2 = pop$p2, icc = pop$icc)
    } else {
      list(delta = delta, sd = 1, icc = pop$icc, Theta = 1)
    }
    return(c(common, effect, list(alpha = spec$target_test$alpha, sides = sides, v = FALSE)))
  }
  if (is_binary_cluster(spec)) {
    # Yes/no outcome. crt.parallel.bin()'s J is the number of groups in
    # both conditions together, as is multisite.bin()'s.
    common <- list(
      m = m, J = n / m, pc = pop$p1, pt = pop$p2, sigma.u = pop$sigma_u,
      alpha = spec$target_test$alpha, sides = sides, v = FALSE
    )
    extra <- if (is_multisite(spec)) list(alloc.ratio = 1) else list(m.sd = pop$cluster_size_sd %||% 0)
    return(c(common[1], extra, common[-1]))
  }
  if (is_multisite(spec)) {
    return(list(
      m = m, m.sd = pop$cluster_size_sd %||% 0,
      alloc.ratio = 1, J = n / m,
      delta = delta, sd = 1,
      icc0 = pop$icc, icc1 = pop$icc_effect, Rsq = pop$baseline_r2_within %||% 0,
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
    ncov = if (has_baseline(spec)) 1 else 0,
    RsqB = pop$baseline_r2_between %||% 0, RsqW = pop$baseline_r2_within %||% 0,
    alpha = spec$target_test$alpha,
    sides = sides,
    v = FALSE
  )
}

powertools_call <- function(args, spec) {
  fun <- getExportedValue("powertools", powertools_function_name(spec))
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
#
# For a group treatment trial, irgtt.cont() solves for delta with a normal
# approximation (its help page: "other quantities ... are solved for using
# normal approximation"), while its power uses the t distribution with
# Satterthwaite df; at a few dozen groups that d falls several points short
# of the target power. powerkit finds n from the t-based power, so it finds
# d from the same power the same way (docs/conventions.md, "Group treatment
# trials").
powertools_sensitivity <- function(spec, n, power) {
  power_at_delta <- function(delta) {
    powertools_call(utils::modifyList(powertools_args(spec, n, delta = delta), list(power = NULL)), spec)
  }
  found <- if (is_group_treatment(spec)) {
    stats::uniroot(function(delta) power_at_delta(delta) - power, c(1e-6, 20), tol = 1e-10)$root
  } else {
    args <- powertools_args(spec, n, delta = NULL)
    args$power <- power
    powertools_call(args, spec)
  }
  negative <- isTRUE(spec$population$d < 0) || identical(spec$target_test$alternative, "less")
  reached <- power_at_delta(found)
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
  if (is_group_treatment(spec)) {
    args <- powertools_args(spec, 20 * m)
    effect_row <- if (is_binary_cluster(spec)) {
      row("proportions passed to powertools (p1, p2)", c(pop$p1, pop$p2), c(args$p1, args$p2))
    } else {
      row("size of d passed to powertools (delta, with sd = 1)", abs(pop$d), args$delta / args$sd)
    }
    return(rbind(
      effect_row,
      row("ICC of the grouped condition passed to powertools (icc)", pop$icc, args$icc),
      row("group size passed to powertools (m)", m, args$m),
      row("at 10 groups in the grouped condition: its groups, and the people taking part individually (J, n)", c(10, 10 * m), c(args$J, args$n))
    ))
  }
  if (is_binary_cluster(spec)) {
    groups <- if (is_multisite(spec)) 10 else 20
    args <- powertools_args(spec, groups * m)
    return(rbind(
      row("proportions passed to powertools (pc, pt)", c(pop$p1, pop$p2), c(args$pc, args$pt)),
      row("SD on the log-odds scale passed to powertools (sigma.u)", pop$sigma_u, args$sigma.u),
      row("group size passed to powertools (m)", m, args$m),
      row(sprintf("groups in all at %s groups (J)", groups), groups, args$J)
    ))
  }
  if (is_multisite(spec)) {
    args <- powertools_args(spec, 10 * m)
    return(rbind(
      row("size of d passed to powertools (delta, with sd = 1)", abs(pop$d), args$delta / args$sd),
      row("ICC of the group means passed to powertools (icc0)", pop$icc, args$icc0),
      row("ICC of the effect across groups passed to powertools (icc1)", pop$icc_effect, args$icc1),
      row("group size passed to powertools (m)", m, args$m),
      row("SD of group sizes passed to powertools (m.sd)", pop$cluster_size_sd %||% 0, args$m.sd),
      row("groups and split within each at 10 groups (J, alloc.ratio)", c(10, 1), c(args$J, args$alloc.ratio)),
      row("baseline score's R-squared passed to powertools (Rsq)", pop$baseline_r2_within %||% 0, args$Rsq)
    ))
  }
  rbind(
    row("size of d passed to powertools (delta, with sd = 1)", abs(pop$d), args$delta / args$sd),
    row("ICC passed to powertools (icc1, icc2)", c(pop$icc, pop$icc), c(args$icc1, args$icc2)),
    row("group size passed to powertools (m)", m, args$m),
    row("SD of group sizes passed to powertools (m.sd)", pop$cluster_size_sd %||% 0, args$m.sd),
    row("groups per condition at 20 groups in all (J1, J.ratio)", c(10, 1), c(args$J1, args$J.ratio)),
    row("baseline score passed to powertools (ncov, RsqW, RsqB)",
        c(as.numeric(has_baseline(spec)), pop$baseline_r2_within %||% 0, pop$baseline_r2_between %||% 0),
        c(args$ncov, args$RsqW, args$RsqB))
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
#' trial). In a group treatment trial only the second condition is
#' grouped (powertools' `irgtt.cont()` and `irgtt.bin()`). The effective
#' sample size is `n` divided by the design effect.
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
#'   and `effective_n`, and `outcome` ("score" or "yes/no"). For a yes/no
#'   outcome, powertools gives no design effect in these terms, so `icc`,
#'   `icc_effect`, `design_effect` and `effective_n` are `NA`, and
#'   `sigma_u` (otherwise `NA`) is the SD on the log-odds scale. For a
#'   group treatment trial (template `group_treatment`, only the second
#'   condition grouped), `assignment` is "one_condition", `clusters` counts
#'   the groups in that condition, `grouped_design_effect` (otherwise `NA`)
#'   is its design effect 1 + (group size - 1) * ICC, and `design_effect`
#'   is the factor for the whole trial: that design effect weighted by the
#'   grouped condition's share of the variance of the difference (a half
#'   for a score). `baseline` is `TRUE` when a baseline score is adjusted
#'   for; `design_effect` then includes the adjustment, as powertools
#'   computes it, and `design_effect_without_baseline` (otherwise `NA` for
#'   the yes/no and group treatment designs) is the factor without it.
#' @export
cluster_summary <- function(spec, n) {
  if (!identical(spec$design, "cluster_trial") || length(n) != 1 || is.na(n)) {
    return(NULL)
  }
  pop <- spec$population
  m <- pop$cluster_size
  m_sd <- pop$cluster_size_sd %||% 0
  multisite <- is_multisite(spec)
  if (is_group_treatment(spec)) {
    # Only the second condition is grouped: its variance is multiplied by
    # 1 + (m - 1) ICC, as in irgtt.cont() and irgtt.bin(). Over the whole
    # trial, the factor is that design effect weighted by the grouped
    # condition's share of the variance of the difference (a half for a
    # score with the same SD in both conditions).
    grouped <- 1 + (m - 1) * pop$icc
    share <- if (is_binary_cluster(spec)) {
      v2 <- pop$p2 * (1 - pop$p2)
      v2 / (v2 + pop$p1 * (1 - pop$p1))
    } else {
      1 / 2
    }
    design_effect <- 1 + share * (grouped - 1)
    return(list(
      assignment = "one_condition",
      cluster_size = m,
      clusters = n / m / 2,
      clusters_per_condition = NA_real_,
      icc = pop$icc, icc_effect = NA_real_,
      relative_efficiency = 1, design_effect = design_effect, effective_n = n / design_effect,
      outcome = if (is_binary_cluster(spec)) "yes/no" else "score", sigma_u = NA_real_,
      grouped_design_effect = grouped,
      baseline = FALSE, design_effect_without_baseline = NA_real_
    ))
  }
  if (is_binary_cluster(spec)) {
    return(list(
      assignment = if (multisite) "people" else "groups",
      cluster_size = m,
      clusters = n / m,
      clusters_per_condition = if (multisite) NA_real_ else n / m / 2,
      icc = NA_real_, icc_effect = NA_real_,
      relative_efficiency = NA_real_, design_effect = NA_real_, effective_n = NA_real_,
      outcome = "yes/no", sigma_u = pop$sigma_u, grouped_design_effect = NA_real_,
      baseline = FALSE, design_effect_without_baseline = NA_real_
    ))
  }
  re_icc <- if (multisite) pop$icc_effect else pop$icc
  re <- if (m_sd > 0) {
    call_backend("powertools", quietly(powertools::re.clustsize.cont(m = m, m.sd = m_sd, icc = re_icc)))
  } else {
    1
  }
  # With a baseline score, the factor as powertools computes it: multisite
  # trials divide d by sqrt(1 - Rsq), which is the same as multiplying the
  # variance by 1 - Rsq; cluster-randomised trials use crt.parallel.cont()'s
  # adjusted design effect (see the header).
  r2w <- pop$baseline_r2_within %||% 0
  r2b <- pop$baseline_r2_between %||% 0
  unadjusted <- if (multisite) {
    (1 - pop$icc + (m - 1) * pop$icc_effect) / re
  } else {
    (1 + (m - 1) * pop$icc) / re
  }
  design_effect <- if (multisite) {
    unadjusted * (1 - r2w)
  } else {
    (1 + (m * (1 - r2b) - 1) * pop$icc - m * r2w * (1 - 2 * pop$icc) / (m - 1)) / re
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
    effective_n = n / design_effect,
    outcome = "score", sigma_u = NA_real_, grouped_design_effect = NA_real_,
    baseline = has_baseline(spec), design_effect_without_baseline = unadjusted
  )
}

# The R script for a clustered design: the same powertools call as
# powerkit's, with the values written out.
powertools_script <- function(spec, result) {
  if (identical(spec$design, "ordinal_regression")) return(propodds_script(spec, result))
  if (is_group_treatment(spec)) return(powertools_script_group_treatment(spec, result))
  if (is_binary_cluster(spec)) return(powertools_script_binary(spec, result))
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
      if (has_baseline(spec)) "Rsq = baseline_r2_within # share of the outcome's variance the baseline score explains",
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
      if (has_baseline(spec)) c(
        "ncov = 1 # the baseline score",
        "RsqB = baseline_r2_between # share of the variance between groups' averages it explains",
        "RsqW = baseline_r2_within # share of the variance within groups it explains"
      ),
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
    if (has_baseline(spec)) sprintf("baseline_r2_within <- %s # baseline score: R-squared within groups", r_code(pop$baseline_r2_within)),
    if (has_baseline(spec) && !multisite) sprintf("baseline_r2_between <- %s # baseline score: R-squared between groups' averages", r_code(pop$baseline_r2_between)),
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

# The R script for a clustered design with a yes/no outcome. It also
# prints powertools' own table for judging the SD on the log-odds scale
# (crt.varexplore() or ms.varexplore()).
powertools_script_binary <- function(spec, result) {
  pop <- spec$population
  lv <- function(i) comment_text(unlist(spec$variables$X$levels)[i])
  alternative <- spec$target_test$alternative %||% "two_sided"
  sides <- if (alternative == "two_sided") 2 else 1
  multisite <- is_multisite(spec)
  fun <- powertools_function_name(spec)
  explore <- if (multisite) "ms.varexplore" else "crt.varexplore"
  args <- c(
    if (multisite) "m = cluster_size # participants in each group, both conditions" else
      "m = cluster_size # participants in each group (the average, if sizes vary)",
    if (multisite) "alloc.ratio = 1 # half of each group in each condition" else
      "m.sd = cluster_size_sd # SD of the group sizes (0: all the same size)",
    "J = n_total / cluster_size # number of groups, both conditions together",
    "pc = p1", "pt = p2",
    "sigma.u = sigma_u",
    "alpha = alpha",
    sprintf("sides = %s # %s", sides, if (sides == 2) "two-sided test" else "one-sided, in the direction of the specified effect")
  )
  c(
    script_header(spec, result, "powertools", paste0("powertools::", fun, "()")),
    "library(powertools)",
    "",
    "# Inputs ----",
    sprintf("p1 <- %s # proportion of 'yes' in %s", r_code(pop$p1), lv(1)),
    sprintf("p2 <- %s # proportion of 'yes' in %s", r_code(pop$p2), lv(2)),
    sprintf("sigma_u <- %s # SD on the log-odds scale: %s", r_code(pop$sigma_u),
            if (multisite) "how much the effect varies between groups" else "how much the groups' proportions differ"),
    sprintf("cluster_size <- %s # participants analysed in each group%s", r_code(pop$cluster_size), if (multisite) ", half in each condition" else ""),
    if (!multisite) sprintf("cluster_size_sd <- %s # SD of the group sizes", r_code(pop$cluster_size_sd %||% 0)),
    goal_inputs(spec, result),
    "",
    "# How plausible is sigma_u? powertools' table of the range in which",
    if (multisite) "# about 95% of the groups' odds ratios would lie, for SDs from 0.1 to 1." else
      "# about 95% of the groups' proportions would lie, for SDs from 0.1 to 1.",
    sprintf("%s(pc = p1, pt = p2)", explore),
    "",
    "# Power at a total sample size (groups x group size), from powertools'",
    "# formula (a z test of the log odds ratio).",
    "power_at <- function(n_total) {",
    paste0("  ", c(paste0(fun, "("), paste0("    ", ensure_commas(args)), "  )")),
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}

# The R script for a group treatment trial (only the second condition
# delivered in groups), a score or a yes/no outcome.
powertools_script_group_treatment <- function(spec, result) {
  pop <- spec$population
  lv <- function(i) comment_text(unlist(spec$variables$X$levels)[i])
  alternative <- spec$target_test$alternative %||% "two_sided"
  sides <- if (alternative == "two_sided") 2 else 1
  binary <- is_binary_cluster(spec)
  fun <- powertools_function_name(spec)
  call_lines <- function(delta, power = NULL) {
    args <- c(
      sprintf("m = cluster_size # participants in each group of %s", lv(2)),
      sprintf("J = n_total / cluster_size / 2 # groups in %s", lv(2)),
      sprintf("n = n_total / 2 # people in %s, taking part individually", lv(1)),
      if (binary) c("p1 = p1", "p2 = p2") else c(sprintf("delta = %s", delta), "sd = 1 # so delta is Cohen's d"),
      sprintf("icc = icc # ICC in %s", lv(2)),
      if (!binary) "Theta = 1 # the same total SD in both conditions",
      "alpha = alpha",
      if (!is.null(power)) sprintf("power = %s", power),
      sprintf("sides = %s # %s", sides, if (sides == 2) "two-sided test" else "one-sided, in the direction of the specified effect")
    )
    c(paste0(fun, "("), paste0("    ", ensure_commas(args)), "  )")
  }
  inputs <- if (binary) c(
    sprintf("p1 <- %s # proportion of 'yes' in %s", r_code(pop$p1), lv(1)),
    sprintf("p2 <- %s # proportion of 'yes' in %s", r_code(pop$p2), lv(2))
  ) else {
    sprintf("d <- %s # Cohen's d: (mean in %s minus mean in %s) / the outcome's total SD", r_code(pop$d), lv(2), lv(1))
  }
  power_fun <- if (binary) c(
    "power_at <- function(n_total) {",
    paste0("  ", call_lines(NULL)),
    "}"
  ) else c(
    "# Its one-sided test runs in the direction of a positive delta, so the",
    "# size of d is passed.",
    "power_at <- function(n_total, d_value = d) {",
    paste0("  ", call_lines("abs(d_value)")),
    "}"
  )
  goal_lines <- if (spec$goal$type == "sensitivity") {
    s <- result$sensitivity
    c(
      "# Smallest detectable effect ----",
      "# The d at which power_at() reaches the target power. (irgtt.cont() can",
      "# also solve for delta itself, but by a normal approximation, which",
      "# gives a smaller d with less than the target power.) It takes the",
      "# direction of the effect you specified.",
      "found <- uniroot(function(delta) power_at(n_total, delta) - target_power, c(1e-6, 20), tol = 1e-10)$root",
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
    inputs,
    sprintf("icc <- %s # intraclass correlation in %s: share of the outcome's variance between its groups", r_code(pop$icc), lv(2)),
    sprintf("cluster_size <- %s # participants analysed in each group of %s", r_code(pop$cluster_size), lv(2)),
    goal_inputs(spec, result),
    "",
    sprintf("# Power at a total sample size: half in %s, in groups of", lv(2)),
    sprintf("# cluster_size, and half in %s, taking part individually.", lv(1)),
    power_fun,
    "",
    goal_lines,
    comparison_section()
  )
}

# Ordinal outcome, two groups (ordinal_regression/ordinal_two_groups):
# powertools::propodds(), the proportional-odds comparison of two groups by
# Whitehead's method (its help, Details), two-sided. powertools wants
# group 1's shares ordered from best to worst and an odds ratio above 1;
# power depends on the odds ratio only through |log(OR)|, so an odds ratio
# below 1 is passed as its reciprocal, and the shares are passed as given
# (the order only fixes which direction "higher" means, and power is the
# same either way). Group 1's size is n1, with n.ratio = n2 / n1.
propodds_backend <- function(spec) {
  inputs <- propodds_inputs(spec)
  step <- valid_n_step(spec)
  power_at <- function(n) propodds_power(inputs, n)
  list(
    name = "powertools",
    packages = c("powertools", "Hmisc"),
    methods = "exact",
    default_method = "exact",
    functions = c(exact = "powertools::propodds"),
    n_step = step,
    exact_min_n = step * ceiling(minimum_n(spec) / step),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() propodds_check_run(spec, inputs)
  )
}

propodds_inputs <- function(spec) {
  pop <- spec$population
  or <- pop$odds_ratio
  list(
    pC = as.numeric(unlist(pop$probabilities)),
    OR = if (or < 1) 1 / or else or,
    ratio = spec$options$allocation_ratio %||% 1,
    alpha = spec$target_test$alpha
  )
}

propodds_power <- function(inputs, n) {
  n1 <- round(n / (1 + inputs$ratio))
  call_backend("powertools", quietly(powertools::propodds(
    pC = inputs$pC, OR = inputs$OR, n1 = n1, n.ratio = (n - n1) / n1, alpha = inputs$alpha
  )))
}

# Check run: there is no simulated data, so the check confirms the odds
# ratio powertools works with, recovered from its own verbose output: the
# cumulative odds of group 2's shares (pT, from Hmisc::pomodm()) against
# group 1's, at every cut-point.
propodds_check_run <- function(spec, inputs) {
  out <- call_backend("powertools", quietly(powertools::propodds(
    pC = inputs$pC, OR = inputs$OR, n1 = 100, alpha = inputs$alpha, v = TRUE
  )))
  cum <- function(p) cumsum(p)[-length(p)]
  odds <- function(q) q / (1 - q)
  # powertools' group 2 is shifted towards the first categories (its "best").
  recovered <- odds(cum(out$pT)) / odds(cum(inputs$pC))
  data.frame(
    parameter = c(
      "shares of group 1 (sum)",
      sprintf("odds ratio at cut-point %d (powertools' group 2)", seq_along(recovered))
    ),
    specified = c(1, rep(inputs$OR, length(recovered))),
    recovered = c(sum(out$pC), recovered),
    # pT is rounded to 3 decimals in powertools' output.
    ok = c(abs(sum(out$pC) - 1) < 1e-9, abs(log(recovered) - log(inputs$OR)) < 0.05)
  )
}

# The R script for an ordinal outcome in two groups: powertools::propodds().
propodds_script <- function(spec, result) {
  inputs <- propodds_inputs(spec)
  levels <- comment_text(unlist(spec$variables$Y$levels))
  c(
    script_header(spec, result, "powertools", "powertools::propodds"),
    "library(powertools)",
    "",
    "# Inputs ----",
    sprintf("pC <- %s # group 1's share in each category: %s", r_code(inputs$pC), paste(levels, collapse = ", ")),
    sprintf(
      "OR <- %s # the odds ratio between the groups%s",
      r_code(inputs$OR),
      if (spec$population$odds_ratio < 1) sprintf(" (you gave %s; power is the same for an odds ratio and its reciprocal, and powertools needs one above 1)", format_number(spec$population$odds_ratio)) else ""
    ),
    sprintf("ratio <- %s # size of group 2 relative to group 1", r_code(inputs$ratio)),
    goal_inputs(spec, result),
    "",
    "# Power of the proportional-odds comparison (Whitehead's method, two-sided)",
    "# at a total sample size.",
    "power_at <- function(n_total) {",
    "  n1 <- round(n_total / (1 + ratio))",
    "  propodds(pC = pC, OR = OR, n1 = n1, n.ratio = (n_total - n1) / n1, alpha = alpha)",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}
