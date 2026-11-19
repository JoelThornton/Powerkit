# One description of how a total analysed sample is divided, used by
# recruitment and its standalone reproduction code. It describes allocation,
# not a missing-data model: attrition is still a per-group planning heuristic.
sample_allocation <- function(spec) {
  weights <- function(w, unit = "group") list(kind = "weights", weights = as.numeric(w), unit = unit)
  single <- list(kind = "single", unit = NA_character_)
  template <- spec$template %||% ""
  if (identical(spec$design, "precision") && template %in% c("two_groups", "mean_difference", "odds_ratio")) {
    return(weights(c(1, 1)))
  }
  if (template %in% c("independent_t", "two_proportions", "two_correlations", "two_variances",
      "ordinal_two_groups", "log_rank", "tost_independent", "noninf_independent", "noninf_two_proportions")) {
    return(ratio_weights(spec))
  }
  if (identical(template, "tost_two_proportions")) return(weights(c(1, 1)))
  if (identical(spec$design, "signal_detection")) {
    return(if (identical(spec$variables$G$type, "binary")) weights(c(1, 1)) else single)
  }
  if (identical(template, "growth_curve")) return(ratio_weights(spec))
  if (identical(spec$design, "irt")) return(weights(c(1, 1)))
  if (identical(template, "invariance")) {
    if (identical(spec$population$over, "occasions")) return(single)
    k <- spec$population$n_groups %||% 2
    return(if (k == 2) ratio_weights(spec) else weights(rep(1, k)))
  }
  if (identical(template, "2x2_between")) {
    return(weights(if (unequal_cells(spec)) cell_ratio_vector(spec) else rep(1, 4), "cell"))
  }
  if (template %in% c("factorial_between", "factorial", "factorial_ancova")) {
    return(weights(rep(1, length(spec$variables$A$levels) * length(spec$variables$B$levels)), "cell"))
  }
  if (identical(template, "factorial_three")) {
    k <- three_factor_groups(spec)
    return(if (k == 1) single else weights(rep(1, k)))
  }
  if (identical(template, "manova")) return(weights(rep(1, manova_groups(spec))))
  if (template %in% c("oneway_between", "oneway_contrast", "mixed", "2x2_mixed", "oneway_ancova", "proportion_trend", "group_moderator")) {
    return(weights(trend_group_shares(spec)))
  }
  if (template %in% c("cluster_randomised", "multisite", "two_level", "three_level")) {
    m <- if (identical(template, "three_level")) spec$population$group_size else spec$population$cluster_size
    step <- switch(template,
      cluster_randomised = 2 * m,
      multisite = m,
      two_level = m * (spec$population$groups_per_site %||% 1),
      three_level = m * spec$population$groups_per_site * if (identical(spec$population$assignment, "site")) 2 else 1)
    return(list(kind = "clusters", size = m, step = step, unit = "cluster"))
  }
  if (identical(template, "group_treatment")) {
    return(list(kind = "partially_grouped", size = spec$population$cluster_size,
      step = 2 * spec$population$cluster_size, unit = "cluster"))
  }
  if (template %in% c("crossed_two_condition", "crossed_conditions")) {
    if (identical(spec$goal$unit, "items")) {
      return(if (identical(spec$population$item_design %||% "between", "within")) single else weights(c(1, 1), "condition"))
    }
    if (identical(spec$variables$X$type, "between_factor")) return(weights(rep(1, length(spec$variables$X$levels))))
  }
  if (identical(spec$design, "meta_analysis") && identical(template, "subgroups")) {
    return(weights(rep(1, length(spec$population$effects)), "subgroup"))
  }
  single
}

# Two groups in options > allocation_ratio. A rounded ratio
# (rounded_ratio()) splits every total, rounding the groups.
ratio_weights <- function(spec) {
  allocation <- list(kind = "weights", weights = as.numeric(c(1, allocation_ratio(spec))), unit = "group")
  if (!is.null(rounded_ratio(spec))) allocation$rounded <- TRUE
  allocation
}

# The step between totals that split into whole groups.
allocation_step <- function(allocation) {
  if (isTRUE(allocation$rounded)) return(1)
  if (identical(allocation$kind, "weights")) integer_allocation_step(allocation$weights) else allocation$step %||% 1
}

analysed_groups <- function(spec, n) {
  allocation <- sample_allocation(spec)
  if (isTRUE(allocation$rounded)) return(rounded_groups(n, allocation$weights[2]))
  switch(allocation$kind,
    weights = n * allocation$weights / sum(allocation$weights),
    clusters = rep(allocation$size, n / allocation$size),
    partially_grouped = c(rep(allocation$size, n / allocation$size / 2), n / 2),
    n)
}

group_unit <- function(spec) sample_allocation(spec)$unit

# Convert relative shares to the smallest whole allocation. Continued
# fractions recover simple integer ratios without scanning candidate totals
# or silently substituting a step of 1. Candidates are checked against the
# original group's validity rule by valid_n_step(). This is allocation
# arithmetic, not a new power approximation.
integer_allocation_step <- function(weights) {
  fail <- function() abort_run("This allocation is too precise to form manageable whole groups. Use simple relative group sizes, such as 1 : 2 or 2 : 3.")
  if (!length(weights) || any(!is.finite(weights)) || any(weights <= 0) || !is.finite(sum(weights))) fail()
  denominator <- function(x) {
    h0 <- 0; h1 <- 1; k0 <- 1; k1 <- 0; z <- x
    for (i in seq_len(100)) {
      a <- floor(z)
      h <- a * h1 + h0
      k <- a * k1 + k0
      if (!is.finite(k) || k > 1e9) break
      if (h > 0 && abs(h / k - x) <= 10 * .Machine$double.eps) return(k)
      remainder <- z - a
      if (remainder == 0) break
      h0 <- h1; h1 <- h; k0 <- k1; k1 <- k; z <- 1 / remainder
    }
    fail()
  }
  gcd <- function(a, b) {
    while (b != 0) { next_b <- a %% b; a <- b; b <- next_b }
    a
  }
  step <- 1
  for (k in vapply(weights / sum(weights), denominator, numeric(1))) {
    step <- step / gcd(step, k) * k
    if (!is.finite(step) || step > 1e9) fail()
  }
  step
}

# Standalone R, using the same layout as analysed_groups(). The total n
# remains a variable so that changing it also changes recruitment counts.
analysed_groups_code <- function(spec, total = "n_analysed") {
  allocation <- sample_allocation(spec)
  if (isTRUE(allocation$rounded)) {
    return(c(
      sprintf("# Groups rounded to whole people at this total, in the ratio 1 : %s.", r_code(allocation$weights[2])),
      sprintf("n_group1 <- floor(%s / (1 + %s) + 0.5)", total, r_code(allocation$weights[2])),
      sprintf("groups_analysed <- c(n_group1, %s - n_group1)", total)))
  }
  step <- allocation_step(allocation)
  split <- switch(allocation$kind,
    weights = {
      if (unequal_groups(spec)) {
        sprintf("groups_analysed <- %s * group_ratio / sum(group_ratio)", total)
      } else {
        w <- r_code(allocation$weights)
        sprintf("groups_analysed <- %s * %s / sum(%s)", total, w, w)
      }
    },
    clusters = sprintf("groups_analysed <- rep(%s, %s / %s)", r_code(allocation$size), total, r_code(allocation$size)),
    partially_grouped = sprintf("groups_analysed <- c(rep(%s, %s / %s / 2), %s / 2)", r_code(allocation$size), total, r_code(allocation$size), total),
    sprintf("groups_analysed <- %s # one group", total))
  c(sprintf("if (%s %%%% %s != 0) stop(\"The analysed sample size must retain the whole group allocation (a multiple of %s).\")", total, r_code(step), r_code(step)), split)
}

# The relative size of group 2 that a plan uses (options > allocation_ratio,
# 1 when absent). A ratio other than 1 is not met exactly at most totals:
# at each total the groups are rounded as a researcher would recruit them
# (rounded_groups()), and the search looks at every total (route_backend()
# then runs each backend at that total's exact whole-group ratio,
# spec_at_total()). A ratio carrying the attribute "exact" is such a
# whole-group ratio, used as it is.
allocation_ratio <- function(spec) {
  # The mark is read by rounded_ratio() only; arithmetic would carry it
  # into every value worked out from the ratio.
  as.numeric(spec$options$allocation_ratio %||% 1)
}

# Templates whose two groups are split by options > allocation_ratio.
ratio_split_template <- function(spec) {
  template <- spec$template %||% ""
  if (identical(spec$design, "precision")) return(FALSE)
  template %in% c("independent_t", "two_proportions", "two_correlations", "two_variances",
    "ordinal_two_groups", "log_rank", "tost_independent", "noninf_independent", "noninf_two_proportions",
    "growth_curve") ||
    (identical(template, "invariance") && !identical(spec$population$over, "occasions") &&
      (spec$population$n_groups %||% 2) == 2)
}

# The entered ratio when a two-group design's groups are rounded at each
# total, or NULL: equal groups (step 2) and an exact whole-group ratio
# are used as they are.
rounded_ratio <- function(spec) {
  ratio <- spec$options$allocation_ratio
  if (!is.numeric(ratio) || length(ratio) != 1 || !is.finite(ratio) || ratio <= 0 ||
      isTRUE(attr(ratio, "exact")) || isTRUE(all.equal(as.numeric(ratio), 1)) || !ratio_split_template(spec)) {
    return(NULL)
  }
  as.numeric(ratio)
}

# Whole group sizes at a total n for the ratio group 2 : group 1: group 1
# is n / (1 + ratio) rounded to the nearest person (a half rounds up) and
# group 2 the rest. Both groups grow with n, never shrink, so power still
# rises with the total.
rounded_groups <- function(n, ratio) {
  n1 <- floor(n / (1 + ratio) + 0.5)
  c(n1, n - n1)
}

# The spec as planned at a total n: the rounded groups' exact ratio,
# marked so that it is used as it is. Other specs are returned unchanged.
spec_at_total <- function(spec, n) {
  ratio <- rounded_ratio(spec)
  if (is.null(ratio) || !is.numeric(n) || length(n) != 1 || !is.finite(n)) return(spec)
  groups <- rounded_groups(n, ratio)
  if (any(groups < 1)) return(spec)
  spec$options$allocation_ratio <- structure(groups[2] / groups[1], exact = TRUE)
  spec
}

# For the result: the whole groups a plan with a rounded ratio used at n,
# with the ratio they achieve, or NULL when the groups are equal or the
# ratio was met exactly.
planned_allocation <- function(spec, n) {
  ratio <- rounded_ratio(spec)
  if (is.null(ratio) || !is.numeric(n) || length(n) != 1 || !is.finite(n)) return(NULL)
  groups <- rounded_groups(n, ratio)
  list(entered = ratio, ratio = groups[2] / groups[1], group1 = groups[1], group2 = groups[2],
    exact = isTRUE(all.equal(groups[2] / groups[1], ratio)))
}

# A backend for a design with a rounded ratio (rounded_ratio()): every
# total is valid, and each calculation at a total n runs the backend for
# that total's whole groups (spec_at_total()), so power is the power of
# the groups a researcher would recruit. `build` makes the backend for a
# spec; the backends at each total are kept, since a search asks again.
rounded_ratio_backend <- function(spec, build) {
  base <- build(spec)
  backends <- new.env(parent = emptyenv())
  at <- function(n) {
    key <- format(n, scientific = FALSE)
    if (is.null(backends[[key]])) {
      planned <- spec_at_total(spec, n)
      if (!isTRUE(attr(planned$options$allocation_ratio, "exact"))) {
        abort_run(sprintf("A total of %s can't be split into two groups in the ratio 1 : %s with at least one person in each.",
          format_number(n), format_number(rounded_ratio(spec))))
      }
      backends[[key]] <- build(planned)
    }
    backends[[key]]
  }
  # Every calculation that takes the total as its first argument.
  per_total <- function(name) {
    force(name)
    function(n, ...) at(n)[[name]](n, ...)
  }
  wrapped <- base
  for (name in names(base)) {
    f <- base[[name]]
    if (is.function(f) && identical(names(formals(f))[1], "n")) wrapped[[name]] <- per_total(name)
  }
  if (is.function(base$telescope$power_at)) {
    wrapped$telescope$power_at <- function(n, ...) at(n)$telescope$power_at(n, ...)
  }
  wrapped$n_step <- 1
  # The smallest total each backend at that total accepts.
  if (is.numeric(base$exact_min_n)) {
    n <- max(base$exact_min_n, 2)
    for (i in seq_len(1000)) {
      found <- tryCatch(at(n)$exact_min_n, powerkit_run_error = function(e) Inf)
      if (is.numeric(found) && found <= n) break
      n <- n + 1
    }
    wrapped$exact_min_n <- n
  }
  wrapped
}
