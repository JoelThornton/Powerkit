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
    two_correlations = {
      ratio <- spec$options$allocation_ratio %||% 1
      n1 <- round(n / (1 + ratio))
      c(n1, n - n1)
    },
    "2x2_between" = rep(n / 4, 4),
    "2x2_mixed" = rep(n / 2, 2),
    oneway_between = ,
    oneway_ancova = {
      k <- length(spec$variables$A$levels)
      rep(n / k, k)
    },
    n
  )
}

# What each group is called, for messages and scripts.
group_unit <- function(spec) {
  switch(
    spec$template,
    independent_t = ,
    two_proportions = ,
    two_correlations = "group",
    "2x2_between" = "cell",
    "2x2_mixed" = ,
    oneway_between = ,
    oneway_ancova = "group",
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
