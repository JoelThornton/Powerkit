#' Describe what a sample size counts and when counts can be compared
#'
#' Describes a validated design specification. Equal compatibility keys
#' identify matching recorded sample structures, not proof that two
#' analyses use the same real population, eligibility criteria or missing-
#' data process. A common recruitment plan still needs those checks.
#'
#' @param spec A validated design specification.
#' @return A list with `unit`, `note`, `n_step`, and `compatibility_key`.
#'   Unknown generic-test units have no compatibility key.
#' @export
sample_structure <- function(spec) {
  if (!is.list(spec) || is.null(spec$design) || is.null(spec$template)) {
    abort_spec("A sample description needs a validated design specification.")
  }
  unit <- if (identical(spec$design, "meta_analysis")) "studies" else
    if (identical(spec$design, "dyadic")) "pairs" else
      if (identical(spec$goal$unit, "items")) "items" else "participants"
  unknown <- identical(spec$design, "generic_test")
  if (unknown) unit <- "analysis units"
  allocation <- sample_allocation(spec)
  step <- if (identical(allocation$kind, "weights")) integer_allocation_step(allocation$weights) else allocation$step %||% 1
  variables <- lapply(names(spec$variables), function(role) {
    variable <- spec$variables[[role]]
    # Outcomes may differ across analyses of the same design. Group and
    # occasion identities remain part of the sample structure.
    if (identical(role, "Y")) variable$label <- NULL
    variable
  })
  names(variables) <- names(spec$variables)
  fixed <- c("cluster_size", "group_size", "groups_per_site", "assignment", "n_groups", "over",
    "items", "participants", "item_design", "raters", "occasions", "n_times", "measurements",
    "study_size", "effects_per_study")
  structure <- list(unit = unit, design = spec$design, template = spec$template,
    variables = variables, allocation = allocation,
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
  if (unknown) note <- "The sample unit is not identified by this generic test; its count is kept separate."
  list(unit = unit, note = note, n_step = step,
    compatibility_key = if (unknown) NULL else spec_hash(structure))
}
