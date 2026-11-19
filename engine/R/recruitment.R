# Participants to recruit, allowing for attrition (options > attrition).
#
# The spec's n is the number analysed. With attrition a (the proportion of
# those recruited who won't be analysed), each group's analysed size is
# divided by 1 - a and rounded up, and the groups are added up: the
# maintainer's decision of 17 October 2026 (docs/decisions.md). This is a
# common but crude heuristic: it ignores how missing data will be handled
# (Mikael Rubin, 2025, refs.bib RubinMikael2025_power).

# Allocation and group labels are shared with reproduction scripts in
# sample-allocation.R.

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

#' Participants to recruit for a replication plan, allowing for attrition
#'
#' The replication plan's sample sizes are the numbers analysed. With
#' attrition `a` (the proportion of those recruited who won't be analysed),
#' each group's analysed size is divided by `1 - a` and rounded up, and the
#' groups are added up: the rule every powerkit card uses for its
#' recruitment target (`options > attrition`). It is a common but crude
#' heuristic that ignores how missing data will be handled (Rubin, 2025).
#'
#' @param n The total number analysed: a whole number.
#' @param groups The number of equal groups `n` is split into (2 for two
#'   groups; 1 for one group, pairs or a correlation).
#' @param attrition The proportion of those recruited who won't be
#'   analysed, at least 0 and below 1.
#' @return A list with `attrition`, `n_analysed`, `groups_analysed` (each
#'   group's analysed size), `n_recruit`, `groups_recruit` and `rule`; or
#'   `NULL` when `n` is missing.
#' @examples
#' replication_recruitment(434, groups = 2, attrition = 0.1)
#' @export
replication_recruitment <- function(n, groups = 1, attrition = 0) {
  one_number <- function(x) is.numeric(x) && length(x) == 1 && !is.na(x)
  if (!one_number(attrition) || attrition < 0 || attrition >= 1) {
    abort_run("The expected dropout should be a proportion: at least 0 and below 1, such as 0.1 for 10%.")
  }
  if (!one_number(groups) || groups < 1 || groups != round(groups)) abort_run("The number of groups should be a whole number, at least 1.")
  if (!one_number(n) || !is.finite(n)) return(NULL)
  analysed <- rep(n / groups, groups)
  # The small tolerance keeps exact quotients (90 / 0.9) from rounding up
  # through floating-point error, as recruitment_target() does.
  recruit <- ceiling(analysed / (1 - attrition) - 1e-9)
  list(attrition = attrition, n_analysed = n, groups_analysed = analysed,
    n_recruit = sum(recruit), groups_recruit = recruit,
    rule = "each group's analysed n / (1 - attrition), rounded up")
}
