# Participants to recruit, allowing for attrition (options > attrition).
#
# The spec's n is the number analysed. With attrition a (the proportion of
# those recruited who won't be analysed), each group's analysed size is
# divided by 1 - a and rounded up, and the groups are added up: the
# maintainer's decision of 17 October 2026 (docs/decisions.md). This is a
# common but crude heuristic: it ignores how missing data will be handled
# (Mikael Rubin, 2025, refs.bib RubinMikael2025_power).

# Group sizes for a total analysed n, as the backends split it (see
# spower_inputs() and group_split()); a single number for designs where
# everyone is in one group.
analysed_groups <- function(spec, n) {
  switch(
    spec$template,
    independent_t = ,
    two_proportions = ,
    two_correlations = ,
    two_variances = ,
    ordinal_two_groups = ,
    tost_independent = {
      ratio <- spec$options$allocation_ratio %||% 1
      n1 <- round(n / (1 + ratio))
      c(n1, n - n1)
    },
    "2x2_between" = if (unequal_cells(spec)) n * cell_ratio_vector(spec) / sum(cell_ratio_vector(spec)) else rep(n / 4, 4),
    "2x2_mixed" = n * trend_group_shares(spec) / sum(trend_group_shares(spec)),
    factorial_between = ,
    factorial = ,
    factorial_ancova = {
      cells <- length(spec$variables$A$levels) * length(spec$variables$B$levels)
      rep(n / cells, cells)
    },
    factorial_three = {
      groups <- three_factor_groups(spec)
      if (groups == 1) n else rep(n / groups, groups)
    },
    oneway_between = ,
    oneway_contrast = ,
    mixed = ,
    oneway_ancova = ,
    proportion_trend = {
      # Trend tests may have unequal groups (options > group_ratio).
      w <- trend_group_shares(spec)
      n * w / sum(w)
    },
    # Attrition within each group: every group's analysed size is divided.
    cluster_randomised = ,
    multisite = rep(spec$population$cluster_size, n / spec$population$cluster_size),
    # The grouped condition's groups, then the condition whose people take
    # part individually, as one group.
    group_treatment = c(rep(spec$population$cluster_size, n / spec$population$cluster_size / 2), n / 2),
    n
  )
}

# What each group is called, for messages and scripts.
group_unit <- function(spec) {
  switch(
    spec$template,
    independent_t = ,
    two_proportions = ,
    two_correlations = ,
    two_variances = ,
    tost_independent = "group",
    "2x2_between" = ,
    factorial_between = ,
    factorial_ancova = "cell",
    "2x2_mixed" = ,
    mixed = ,
    factorial_three = if (three_factor_groups(spec) == 1) NA_character_ else "group",
    oneway_between = ,
    oneway_contrast = ,
    oneway_ancova = ,
    proportion_trend = "group",
    cluster_randomised = ,
    multisite = ,
    group_treatment = "cluster",
    NA_character_
  )
}

# The recruitment target for n analysed, or NA when the spec gives no
# attrition (or attrition 0).
recruitment_target <- function(spec, n) {
  attrition <- spec$options$attrition %||% 0
  if (attrition <= 0 || length(n) != 1 || is.na(n)) {
    return(NA)
  }
  analysed <- analysed_groups(spec, n)
  # The small tolerance keeps exact quotients (90 / 0.9) from rounding up
  # through floating-point error.
  recruit <- ceiling(analysed / (1 - attrition) - 1e-9)
  list(
    attrition = attrition,
    n_analysed = n,
    groups_analysed = analysed,
    n_recruit = sum(recruit),
    groups_recruit = recruit,
    unit = group_unit(spec),
    rule = "each group's analysed n / (1 - attrition), rounded up"
  )
}
