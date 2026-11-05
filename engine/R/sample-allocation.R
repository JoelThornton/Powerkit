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
    return(weights(c(1, spec$options$allocation_ratio %||% 1)))
  }
  if (identical(template, "tost_two_proportions")) return(weights(c(1, 1)))
  if (identical(template, "growth_curve") || identical(spec$design, "irt")) return(weights(c(1, 1)))
  if (identical(template, "invariance")) {
    if (identical(spec$population$over, "occasions")) return(single)
    k <- spec$population$n_groups %||% 2
    return(weights(if (k == 2) c(1, spec$options$allocation_ratio %||% 1) else rep(1, k)))
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

analysed_groups <- function(spec, n) {
  allocation <- sample_allocation(spec)
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
  step <- if (identical(allocation$kind, "weights")) integer_allocation_step(allocation$weights) else allocation$step %||% 1
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
