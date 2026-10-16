# Where each walkthrough scenario (scenarios.json) leads in each route,
# using the app's own routing functions (R/tree.R). Used by
# tests/testthat/test-walkthroughs.R and to build docs/walkthroughs.md.
# Routing only: nothing here calculates anything.

#' End point id reached by one route of a scenario.
walk_route <- function(tree, scenario, route) {
  plain <- vapply(tree$endpoints, function(e) e$plain_name, character(1))
  if (route == "choose") return(follow_answers(tree, unlist(scenario$choose), "choose"))
  step <- scenario[[route]]
  reached <- follow_answers(tree, unlist(step$answers), route)
  if (route == "known") {
    if (!identical(reached, "list")) return(reached)
    if (identical(step$pick, "safety")) return(tree$safety_net$endpoint)
    id <- names(plain)[plain == step$pick]
    if (length(id) != 1) stop(sprintf("'%s' is not on the end-point list.", step$pick))
    return(id)
  }
  if (!identical(reached, "guided")) return(reached)
  if (!is.null(step$`continue`)) {
    # Sent on to "Help me choose", keeping the screening answers.
    return(follow_answers(tree, c(unlist(step$answers), unlist(step$`continue`)), "choose"))
  }
  answers <- step$vars
  analysis <- analysis_by_id(tree, step$analysis)
  if (!analysis$id %in% vapply(applicable_analyses(tree, answers), function(a) a$id, character(1))) {
    stop(sprintf("Analysis '%s' isn't offered for these variables.", step$analysis))
  }
  res <- resolve_analysis(tree, analysis, answers, step$ask)
  res$endpoint %||% NA_character_
}

walk_scenario <- function(tree, scenario) {
  vapply(c("choose", "known", "guided"), function(r) walk_route(tree, scenario, r), character(1))
}

load_scenarios <- function(path) jsonlite::fromJSON(path, simplifyVector = FALSE)
