# Mediation with a two-group X (E16, E17): a path from X may be given as
# Cohen's d of the two groups (population > group_d) instead of a
# standardised path. "M" is the groups' difference in the mediator, "Y"
# their difference in the outcome overall (through the mediator as well as
# directly). As in the whole-study simulation (whole-study-group-d.R), the
# path that gives this d is found numerically, from a large data set drawn
# by power4mome with the same generator the power run uses, so no
# conversion formula is needed. The mediator's path is found first, since
# the outcome's d depends on it.

# Problems with population > group_d, for validate_spec().
group_d_problems <- function(spec) {
  group_d <- spec$population$group_d
  if (!length(group_d)) return(character())
  if (!identical(spec$variables$X$type, "binary")) {
    return("'population > group_d' is Cohen's d of X's two groups, so it applies only when X is two groups ('variables > X > type' \"binary\").")
  }
  model <- path_model(spec)
  by_d <- paste0("X->", names(group_d))
  missing <- setdiff(by_d, model_paths(model))
  if (length(missing)) {
    return(sprintf("'population > group_d' gives d for %s, which isn't a path from X in %s.",
      quote_list(missing, "and"), template_name(spec$template)))
  }
  both <- intersect(by_d, names(spec$population$paths))
  if (length(both)) {
    return(sprintf("Give either the path %s or Cohen's d of the groups ('population > group_d'), not both.", quote_list(both, "and")))
  }
  character()
}

# The spec with a small path, in the direction of each d (0 for d = 0),
# where group_d stands for one, so the other checks (a zero indirect
# effect, among them) can run before the paths are found at run time
# (resolve_group_d()). The placeholder never enters a calculation.
with_group_d_placeholders <- function(spec) {
  for (outcome in names(spec$population$group_d)) {
    spec$population$paths[[paste0("X->", outcome)]] <- 0.1 * sign(spec$population$group_d[[outcome]])
  }
  spec
}

# Cohen's d of X's two groups on `outcome`, with the pooled SD, in a data
# set where X has two values.
group_d_in_data <- function(data, outcome) {
  second <- data$X == max(data$X)
  y1 <- data[[outcome]][!second]
  y2 <- data[[outcome]][second]
  pooled <- sqrt(((length(y1) - 1) * stats::var(y1) + (length(y2) - 1) * stats::var(y2)) / (length(y1) + length(y2) - 2))
  (mean(y2) - mean(y1)) / pooled
}

# The spec with each path given by group_d found (and group_d kept, for the
# record). The search draws check_run_n() people per step with `seed`, so
# the same seed finds the same paths.
resolve_group_d <- function(spec, seed) {
  group_d <- spec$population$group_d
  if (!length(group_d)) return(spec)
  spec <- with_group_d_placeholders(spec)
  feasible <- function(s) length(population_problems(s)) == 0
  for (outcome in intersect(c("M", "Y"), names(group_d))) {
    path <- paste0("X->", outcome)
    target <- group_d[[outcome]]
    with_path <- function(b) {
      s <- spec
      s$population$paths[[path]] <- b
      s
    }
    # The largest path either way the other paths leave possible, kept a
    # little inside the edge, where the outcome's residual variance nears 0.
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
    d_at <- function(b) {
      sim <- power4mome_call(power4mome_inputs(with_path(b)), check_run_n(), 1, seed, do_the_test = FALSE)
      group_d_in_data(as.data.frame(power4mome::pool_sim_data(sim)), outcome)
    }
    bounds <- c(edge(-1), edge(1))
    ends <- vapply(bounds, d_at, numeric(1))
    if (target < min(ends) || target > max(ends)) {
      abort_spec(sprintf(
        "A Cohen's d of %s on %s isn't possible with the other paths you gave: with them, d can be between about %s and %s.",
        format_number(target), var_label(spec, outcome), format_number(round(min(ends), 2)), format_number(round(max(ends), 2))))
    }
    found <- stats::uniroot(function(b) d_at(b) - target, bounds, f.lower = ends[1] - target, f.upper = ends[2] - target,
      tol = 1e-4)$root
    spec$population$paths[[path]] <- round(found, 6)
  }
  spec
}

# For the result: the d entered and the path found for each, or NULL.
group_d_record <- function(spec) {
  group_d <- spec$population$group_d
  if (!length(group_d)) return(NULL)
  paths <- paste0("X->", names(group_d))
  list(entered = group_d, found_paths = spec$population$paths[paths])
}
