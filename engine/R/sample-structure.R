#' Describe what a sample size counts and when counts can be compared
#'
#' Describes a validated design specification. Equal compatibility keys
#' identify matching recorded sample structures, not proof that two
#' analyses use the same real population, eligibility criteria or missing-
#' data process. A common recruitment plan still needs those checks.
#'
#' @param spec A validated design specification.
#' @param n Optional: a total sample size, to describe how it is divided.
#' @return A list with `unit`, `note`, `n_step`, and `compatibility_key`.
#'   Unknown generic-test units have no compatibility key. With `n`, also
#'   `groups`: the number analysed in each group or cell, in the order the
#'   engine runs them (`NULL` when the sample isn't split into groups), with
#'   `group_labels` (the groups' level labels, or `NULL` when not known) and
#'   `group_unit` ("group" or "cell").
#' @export
#' @examples
#' spec <- read_spec(system.file("specs", "cluster_randomised.json", package = "powerkit"))
#' str(sample_structure(spec), max.level = 1)
sample_structure <- function(spec, n = NULL) {
  if (!is.list(spec) || is.null(spec$design) || is.null(spec$template)) {
    abort_spec("A sample description needs a validated design specification.")
  }
  unit <- if (identical(spec$design, "meta_analysis")) "studies" else
    if (identical(spec$design, "dyadic")) "pairs" else
      if (identical(spec$goal$unit, "items")) "items" else
        if (identical(spec$goal$unit, "observations")) "observations" else "participants"
  unknown <- identical(spec$design, "generic_test")
  if (unknown) unit <- "analysis units"
  allocation <- sample_allocation(spec)
  step <- allocation_step(allocation)
  # The outcome, and the test run on it, may differ across analyses of the
  # same people: a score and a yes/no outcome compared between the same
  # two groups share one sample (8 November 2026). Group and occasion
  # identities, the allocation and the grouping structure stay in the key.
  variables <- spec$variables[setdiff(names(spec$variables), "Y")]
  fixed <- c("cluster_size", "group_size", "groups_per_site", "assignment", "n_groups", "over",
    "items", "participants", "item_design", "raters", "occasions", "n_times", "measurements",
    "study_size", "effects_per_study")
  structure <- list(unit = unit, design = spec$design, variables = variables, allocation = allocation,
    attrition = spec$options$attrition %||% 0,
    fixed = spec$population[intersect(fixed, names(spec$population))])
  note <- switch(unit,
    pairs = "Pairs of people; two people per pair.",
    items = "Items; the number of participants is fixed separately.",
    studies = "Studies; participant counts within studies are specified separately.",
    "Each participant is counted once.")
  if (allocation$kind %in% c("clusters", "partially_grouped")) {
    note <- sprintf("N counts participants, with %s people per cluster; whole cluster and site allocations are retained.", format_number(allocation$size))
  }
  if (identical(unit, "observations")) {
    note <- sprintf("N counts observations, with each person measured on %s occasions; whole people are retained.", format_number(spec$population$cluster_size))
  }
  if (unknown) note <- "The sample unit is not identified by this generic test; its count is kept separate."
  out <- list(unit = unit, note = note, n_step = step,
    compatibility_key = if (unknown) NULL else spec_hash(structure))
  if (!is.null(n) && identical(allocation$kind, "weights")) {
    out$groups <- analysed_groups(spec, n)
    out$group_labels <- allocation_labels(spec, length(out$groups), allocation$unit)
    out$group_unit <- allocation$unit
  }
  out
}

# Labels for the groups or cells of sample_allocation(), in its order, or
# NULL. Cells of two factors are A's levels crossed with B's, B changing
# fastest (Superpower's order, as cell_ratio_vector() reads them).
allocation_labels <- function(spec, k, unit) {
  levels_of <- function(v) unlist(spec$variables[[v]]$levels)
  if (identical(unit, "cell") && length(levels_of("A")) * length(levels_of("B")) == k) {
    cells <- expand.grid(b = levels_of("B"), a = levels_of("A"), stringsAsFactors = FALSE)
    return(paste(cells$a, cells$b, sep = ", "))
  }
  for (v in c("W", "A", "X", "G")) {
    labels <- levels_of(v)
    if (length(labels) == k && !identical(spec$variables[[v]]$type, "within_factor")) return(as.character(labels))
  }
  NULL
}
