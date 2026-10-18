# Project files: "Save project" and "Open a saved project".
#
# The app never builds the file itself: it hands the spec, the result and
# the route to the engine's write_project(), and opens files with
# read_project(). The route is how the user reached the input screen, so
# opening a project puts them back on the same screen with the same
# values. Nothing is stored by the app; the file stays with the user.

# The route part of a project, from the app's state (a list or
# reactiveValues read with isolate()).
project_route <- function(state, form_values) {
  list(
    app = "routing-prototype",
    route = state$route,
    start = state$start,
    endpoint = state$endpoint,
    came_from = state$came_from,
    ctx = state$ctx,
    history = lapply(state$history, function(h) list(node = h$node, answer = h$answer, ctx = h$ctx)),
    form_k = state$form_k,
    form_values = form_values
  )
}

# What to put back into the app's state when a project is opened, or a
# plain-English problem (a string) if it can't be reopened here.
restore_from_project <- function(route, tree, forms) {
  if (!identical(route$app, "routing-prototype")) {
    return("This project wasn't saved from the app, so there is no screen to reopen. You can still run it with powerkit's read_project() and reproduce_project().")
  }
  endpoint <- route$endpoint
  if (is.null(endpoint) || is.null(tree$endpoints[[endpoint]]) || !form_calculates(forms, endpoint)) {
    return("This project is for a calculation this version of the app doesn't offer.")
  }
  list(
    screen = "form",
    route = route$route %||% "choose",
    start = route$start %||% list(),
    endpoint = endpoint,
    came_from = route$came_from %||% "node",
    ctx = route$ctx %||% list(),
    history = route$history %||% list(),
    form_k = as.integer(route$form_k %||% 2L),
    form_values = route$form_values %||% list(),
    node = NULL
  )
}

# The notice shown on the input screen after a project is opened.
project_opened_ui <- function(project) {
  saved <- project$result
  div(
    class = "alert alert-info", role = "status",
    tags$strong("Project opened."),
    sprintf(" Saved %s with powerkit %s.", project$saved, project$powerkit_version),
    if (!is.null(saved)) " Press \u201cCheck my answers\u201d to reproduce the saved result; it should match exactly." else " Press \u201cCheck my answers\u201d to run it.",
    if (length(project$notes) > 0) tags$ul(lapply(project$notes, tags$li))
  )
}

project_file_name <- function(endpoint) {
  sprintf("powerkit-%s-project.powerkit.json", endpoint)
}

# On the start screen: open a file saved earlier.
open_project_ui <- function() {
  div(
    class = "open-project mt-4",
    fileInput("open_project", "Or open a saved project", accept = c(".json", "application/json"),
      buttonLabel = "Choose file…", placeholder = "a .powerkit.json file"),
    uiOutput("open_project_message")
  )
}
