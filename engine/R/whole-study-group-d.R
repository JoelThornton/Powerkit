# Cohen's d for a two-group X (population > group_d): the standardised path
# X->Y (or X->M) that gives this d of the groups is found numerically,
# from the same large simulated data set as the implied values
# (whole_study_big_sample(), whole_study_group_d()), so no conversion
# formula is needed (8 November 2026). The mediator is found first, as the
# outcome's d depends on it.
whole_study_resolve_group_d <- function(spec, seed) {
  group_d <- spec$population$group_d %||% list()
  if (!length(group_d)) return(spec)
  model <- whole_study_model(spec)
  feasible <- function(s) length(whole_study_variance_problems(s, model)) == 0
  # Paths still to be found stand at 0 meanwhile.
  for (path in setdiff(paste0("X->", names(group_d)), names(spec$population$paths))) spec$population$paths[[path]] <- 0
  for (outcome in intersect(c("M", "Y"), names(group_d))) {
    path <- paste0("X->", outcome)
    target <- group_d[[outcome]]
    with_path <- function(b) {
      s <- spec
      s$population$paths[[path]] <- b
      s
    }
    # The largest path either way the other paths leave possible, kept a
    # little inside the edge, where the outcome's residual variance nears 0
    # and the data can't be drawn.
    edge <- function(sign) {
      lo <- 0
      hi <- 0.95
      if (feasible(with_path(sign * hi))) return(sign * hi)
      for (i in 1:30) {
        mid <- (lo + hi) / 2
        if (feasible(with_path(sign * mid))) lo <- mid else hi <- mid
      }
      sign * 0.95 * lo
    }
    d_at <- function(b) whole_study_group_d(whole_study_big_sample(whole_study_inputs(with_path(b)), seed), outcome)
    bounds <- c(edge(-1), edge(1))
    ends <- vapply(bounds, d_at, numeric(1))
    if (target < min(ends) || target > max(ends)) {
      abort_spec(sprintf(
        "A Cohen's d of %s on %s isn't possible with the other paths you gave: with them, d can be between about %s and %s.",
        format_number(target), var_label(spec, outcome), format_number(round(min(ends), 2)), format_number(round(max(ends), 2))))
    }
    found <- stats::uniroot(function(b) d_at(b) - target, bounds, f.lower = ends[1] - target, f.upper = ends[2] - target,
      tol = 1e-5)$root
    spec$population$paths[[path]] <- round(found, 6)
  }
  spec
}
