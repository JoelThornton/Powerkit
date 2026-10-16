# Helpers for the routing data in tree.yaml. Pure functions: they read the
# tree and return values; no Shiny, no engine, no calculations.

`%||%` <- function(x, y) if (is.null(x)) y else x

#' Read the routing data.
load_tree <- function(path = "tree.yaml") {
  yaml::read_yaml(path, fileEncoding = "UTF-8")
}

is_endpoint_id <- function(id) grepl("^E", id)

#' A node that is never shown: it routes on a screening answer (`branch_on`).
is_automatic <- function(node) !is.null(node$branch_on)

#' Every target of a node: its options' `next`, or an automatic node's routes.
node_targets <- function(node) {
  if (is_automatic(node)) return(unname(unlist(node$routes)))
  vapply(node$options, function(o) o$`next` %||% NA_character_, character(1))
}

route_by_id <- function(tree, id) {
  Filter(function(r) identical(r$id, id), tree$routes$options)[[1]]
}

#' Where the screening's "continue" leads in a route: a node id, "list" or
#' "guided".
after_screening <- function(tree, route = "choose") route_by_id(tree, route)$after_screening

# Screening context ---------------------------------------------------------

#' The safety net offered on every question ("None of these fit / I'm not
#' sure").
safety_option <- function(tree) {
  list(label = tree$safety_net$label, `next` = tree$safety_net$endpoint, safety = TRUE)
}

#' The options shown on a question, given the screening answers so far
#' (`ctx`): those whose `when` matches, then the safety net.
visible_options <- function(tree, node, ctx = list(), safety = TRUE) {
  opts <- Filter(function(o) is.null(o$when) || matches(o$when, ctx), node$options)
  if (safety) opts <- c(opts, list(safety_option(tree)))
  opts
}

#' The context after choosing an option (its `sets`, if any).
apply_sets <- function(ctx, option) {
  if (is.null(option$sets)) return(ctx)
  utils::modifyList(ctx, option$sets)
}

#' Follow "continue" and automatic nodes from `id` until a shown question, an
#' end point, or a route screen ("list" or "guided"). Returns NA when an
#' automatic node has no route for the context.
resolve_target <- function(tree, id, ctx = list(), route = "choose") {
  seen <- character()
  repeat {
    if (is.na(id)) return(NA_character_)
    if (identical(id, "continue")) {
      id <- after_screening(tree, route)
      next
    }
    node <- tree$nodes[[id]]
    if (is.null(node) || !is_automatic(node)) return(id)
    if (id %in% seen) return(NA_character_)
    seen <- c(seen, id)
    value <- ctx[[node$branch_on]]
    id <- if (is.null(value)) NA_character_ else node$routes[[value]] %||% NA_character_
  }
}

#' Follow a list of answer labels from the start of the screening, as a user
#' would click them. Returns where they lead (an end point id, a question id,
#' or a route screen), or stops if a label isn't offered at that point.
follow_answers <- function(tree, labels, route = "choose") {
  ctx <- list()
  id <- resolve_target(tree, start_node(tree), ctx, route)
  for (label in labels) {
    node <- tree$nodes[[id]]
    if (is.null(node)) stop(sprintf("'%s' is answered after the route left the questions (at '%s').", label, id))
    opts <- visible_options(tree, node, ctx)
    chosen <- Filter(function(o) identical(o$label, label), opts)
    if (length(chosen) != 1) stop(sprintf("'%s' is not offered at '%s'.", label, id))
    ctx <- apply_sets(ctx, chosen[[1]])
    id <- resolve_target(tree, chosen[[1]]$`next`, ctx, route)
  }
  id
}

#' Problems with the "Help me choose" tree: options without a target,
#' targets that don't exist, nodes that can't be reached from the start, and
#' cycles. Returns a character vector (empty when all is well).
tree_problems <- function(tree) {
  nodes <- tree$nodes
  ids <- names(nodes)
  eps <- names(tree$endpoints)
  problems <- character()
  for (id in ids) {
    targets <- node_targets(nodes[[id]])
    if (length(targets) == 0) {
      problems <- c(problems, sprintf("Node '%s' has no options (a dead end).", id))
    }
    for (t in targets) {
      if (is.na(t)) {
        problems <- c(problems, sprintf("Node '%s' has an option with no 'next' (a dead end).", id))
      } else if (!t %in% c(ids, eps, "continue")) {
        problems <- c(problems, sprintf("Node '%s' points to '%s', which is neither a node nor an end point.", id, t))
      }
    }
  }
  start <- start_node(tree)
  reached <- reachable(tree, start)
  for (id in setdiff(ids, reached$nodes)) {
    problems <- c(problems, sprintf("Node '%s' can't be reached from '%s'.", id, start))
  }
  if (length(reached$cycle) > 0) {
    problems <- c(problems, sprintf("The tree has a cycle through '%s'.", reached$cycle[1]))
  }
  problems
}

#' The first question of every route: the screening.
start_node <- function(tree) tree$routes$screening_start

#' Nodes and end points reachable from `start`, by depth-first search.
#' Also reports any node met again on the current path (a cycle).
reachable <- function(tree, start) {
  seen_nodes <- character()
  seen_eps <- character()
  cycle <- character()
  visit <- function(id, path) {
    if (identical(id, "continue")) id <- after_screening(tree, "choose")
    if (is_endpoint_id(id)) {
      seen_eps <<- union(seen_eps, id)
      return(invisible())
    }
    if (id %in% path) {
      cycle <<- c(cycle, id)
      return(invisible())
    }
    seen_nodes <<- union(seen_nodes, id)
    node <- tree$nodes[[id]]
    if (is.null(node)) return(invisible())
    for (t in node_targets(node)) if (!is.na(t)) visit(t, c(path, id))
  }
  visit(start, character())
  # Every shown question offers the safety net.
  if (length(seen_nodes) > 0 && !is.null(tree$safety_net)) seen_eps <- union(seen_eps, tree$safety_net$endpoint)
  list(nodes = seen_nodes, endpoints = seen_eps, cycle = cycle)
}

#' Every complete path through a route, as a list of character vectors of
#' ids, following the screening context as a user would (automatic nodes
#' route on it; options are filtered by it). A path ends at an end point, at
#' the route's screen after the screening ("list" or "guided"), or, if
#' something is wrong, at a question with no options or at NA. The safety
#' net is left out (it is the same end point everywhere).
all_paths <- function(tree, route = "choose", start = start_node(tree)) {
  out <- list()
  walk <- function(id, path, ctx) {
    id <- resolve_target(tree, id, ctx, route)
    path <- c(path, id)
    node <- if (is.na(id)) NULL else tree$nodes[[id]]
    if (is.null(node) || id %in% path[-length(path)]) {
      out[[length(out) + 1]] <<- path
      return(invisible())
    }
    opts <- visible_options(tree, node, ctx, safety = FALSE)
    if (length(opts) == 0) {
      out[[length(out) + 1]] <<- path
      return(invisible())
    }
    for (o in opts) walk(o$`next`, path, apply_sets(ctx, o))
  }
  walk(start, character(), list())
  out
}

# Settings ---------------------------------------------------------------

setting_by_key <- function(tree, key) {
  Filter(function(s) identical(s$key, key), tree$settings)[[1]]
}

settings_shown_at <- function(tree, where) {
  Filter(function(s) where %in% unlist(s$shown_at), tree$settings)
}

is_decided <- function(setting) !is.null(setting$value)

#' Whether the guided route is offered (open question 11). Undecided means
#' it is shown, with a placeholder.
guided_route_enabled <- function(tree) {
  s <- setting_by_key(tree, "guided_route")
  !(is_decided(s) && identical(s$value, s$hides_guided_route_when))
}

# Guided route ------------------------------------------------------------

#' Does a set of variable answers satisfy a `when` / `requires` condition?
#' Each key must match; a list of values means "any of these".
matches <- function(condition, answers) {
  for (key in names(condition)) {
    allowed <- unlist(condition[[key]])
    if (is.null(answers[[key]]) || !answers[[key]] %in% allowed) return(FALSE)
  }
  TRUE
}

#' Analyses that fit the variables defined (their `requires` are met).
applicable_analyses <- function(tree, answers) {
  Filter(function(a) is.null(a$requires) || matches(a$requires, answers), tree$guided$analyses)
}

#' Route one analysis of the guided route. Returns a list with one of:
#' `endpoint` (an end point id), `ask` (a follow-up question whose options
#' each name an end point), or `unmapped` (no end point; with a package).
#' `ask_answer`, if given, is the label chosen for the follow-up question.
resolve_analysis <- function(tree, analysis, answers, ask_answer = NULL) {
  safety <- tree$safety_net$endpoint
  if (any(unlist(answers) == "notsure")) return(list(endpoint = safety))
  for (rule in analysis$rules) {
    if (!matches(rule$when, answers)) next
    if (!is.null(rule$endpoint)) return(list(endpoint = rule$endpoint))
    if (!is.null(rule$unmapped)) return(list(unmapped = rule$unmapped, package = rule$package))
    if (!is.null(rule$ask)) {
      if (identical(ask_answer, tree$safety_net$label)) return(list(endpoint = safety, asked = rule$ask))
      chosen <- Filter(function(o) identical(o$label, ask_answer), rule$ask$options)
      if (length(chosen) == 1) return(list(endpoint = chosen[[1]]$endpoint, asked = rule$ask))
      return(list(ask = rule$ask))
    }
  }
  list(unmapped = "No rule in tree.yaml matched these answers.", package = NULL)
}

#' Every combination of the guided route's variable answers.
all_variable_combinations <- function(tree) {
  opts <- lapply(tree$guided$variables, function(v) names(v$options))
  names(opts) <- vapply(tree$guided$variables, function(v) v$id, character(1))
  grid <- expand.grid(opts, stringsAsFactors = FALSE)
  lapply(seq_len(nrow(grid)), function(i) as.list(grid[i, , drop = FALSE]))
}

#' For the plan screen: relationships shared by two or more ticked analyses
#' (decision-tree.md 4.2).
shared_relationships <- function(tree, ticked) {
  out <- list()
  for (rel in tree$guided$shared_relationships) {
    sharing <- intersect(unlist(rel$`in`), ticked)
    if (length(sharing) >= 2) out[[length(out) + 1]] <- c(rel, list(sharing = sharing))
  }
  out
}

analysis_by_id <- function(tree, id) {
  Filter(function(a) identical(a$id, id), tree$guided$analyses)[[1]]
}

# End points ----------------------------------------------------------------

status_label <- function(status) {
  switch(
    status,
    runs_validated = "Runs in powerkit",
    runs_validation_in_progress = "Runs, validation in progress",
    coming_soon = "Coming soon",
    not_in_powerkit = "Not in powerkit yet",
    status
  )
}

endpoints_by_status <- function(tree) {
  eps <- tree$endpoints
  split(names(eps), vapply(eps, function(e) e$status, character(1)))
}
