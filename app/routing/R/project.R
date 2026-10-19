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

# --- The plan checker (optional feature, 19 October 2026) --------------------
# For a supervisor, reviewer or colleague given a saved project: what the
# plan says, in plain words, and the questions worth asking about it. It
# reads the saved file only (nothing is calculated here; "Open it in the
# app" reruns it), and the questions point to what the plan leaves
# unstated. They are prompts for a conversation, not a pass or fail.

# On the start screen, under "Open a saved project".
check_project_ui <- function() {
  div(
    class = "check-project mt-2",
    fileInput("check_project", "Or check a plan someone shared with you", accept = c(".json", "application/json"),
      buttonLabel = "Choose file…", placeholder = "a .powerkit.json file"),
    p(class = "small", "For supervisors, reviewers and colleagues: see what the plan assumes and what to ask about it, without changing it."),
    uiOutput("check_project_message")
  )
}

# The questions, from the saved answers (values) and result. Each is a
# plain sentence; character(0) when nothing stands out.
plan_questions <- function(values, result, alpha_default = 0.05) {
  v <- function(id) if (blank(values[[id]])) NULL else trimws(as.character(values[[id]]))
  out <- character()
  goal <- result$goal_type %||% v("goal") %||% ""
  if (is.null(v("just_source"))) {
    out <- c(out, "No reasoning is given for the effect size. Ask where the number comes from.")
  }
  type <- v("just_type") %||% ""
  if (identical(type, "none")) {
    out <- c(out, "The plan says no effect size could be justified, so it reports the smallest effect the study could detect. Ask whether effects that small would matter, and whether smaller ones would.")
  }
  if (identical(type, "pilot_study")) {
    out <- c(out, "The effect size comes from a pilot study. A pilot is usually small, so its estimate is uncertain. Ask how far the true effect could be from it, and what happens to the plan if it is smaller.")
  }
  if (identical(type, "prior_study")) {
    out <- c(out, sprintf("The effect size comes from a previous study%s. Ask how the adjustment was chosen and whether that study is like this one.",
      if (!is.null(v("just_adjustment"))) sprintf(", adjusted as follows: “%s”", v("just_adjustment")) else ""))
  }
  if (goal %in% c("sample_size", "sensitivity") && is.null(v("power_reason"))) {
    out <- c(out, "No reason is given for the target power. Ask why this chance of finding the effect was chosen.")
  }
  alpha <- suppressWarnings(as.numeric(v("alpha") %||% alpha_default))
  if (!is.na(alpha) && !isTRUE(all.equal(alpha, alpha_default)) && is.null(v("alpha_reason"))) {
    out <- c(out, sprintf("The significance level is %s rather than %s, with no reason given. Ask why.", format(alpha), format(alpha_default)))
  }
  if (!is.null(v("alternative")) && !identical(v("alternative"), "two_sided") && is.null(v("alternative_reason"))) {
    out <- c(out, "The test is one-sided, with no reason given. Ask why an effect in the other direction wouldn't count.")
  }
  if (identical(goal, "sample_size") && is.null(v("attrition"))) {
    out <- c(out, "There is no allowance for people who drop out or are excluded. Ask whether everyone recruited will be analysed.")
  }
  if (identical(v("claim"), "all")) {
    out <- c(out, "The claim needs every one of several tests to be significant. The chance that all of them succeed is lower than the power of each one. Ask whether the plan allows for that.")
  }
  out
}

# The checker screen for an opened project.
plan_check_ui <- function(tree, forms, project) {
  route <- project$route
  ep_id <- route$endpoint
  ep <- tree$endpoints[[ep_id]]
  values <- route$form_values %||% list()
  result <- project$result
  fields <- form_fields(form_groups(forms, ep_id, as.integer(route$form_k %||% 2L), route$start %||% list()))
  tool <- forms$tool_defaults[[forms$forms[[ep_id]]$tool]]
  questions <- plan_questions(values, result, tool[["alpha"]] %||% 0.05)
  quote <- function(label, id) if (!blank(values[[id]])) tags$li(tags$strong(label), " ", writeup_quote(values[[id]]))
  reasons <- list(quote("The effect size:", "just_source"), quote("The adjustment:", "just_adjustment"),
    quote("The target power:", "power_reason"), quote("The significance level:", "alpha_reason"),
    quote("A one-sided test:", "alternative_reason"))
  reasons <- Filter(Negate(is.null), reasons)
  div(
    class = "plan-check",
    h2(class = "h4", "Checking a shared plan"),
    p(class = "small", sprintf("Saved %s with powerkit %s. Nothing here changes the file.", project$saved %||% "(date unknown)", project$powerkit_version %||% "(unknown)")),
    h3(class = "h5", "What the plan is for"),
    p(tags$strong(ep$plain_name %||% ep_id), if (!is.null(ep$doc_name)) sprintf(" (%s)", ep$doc_name)),
    h3(class = "h5", "What it found"),
    if (is.null(result)) p("The file has no saved result. Open it in the app and press “Check my answers” to run it.") else
      p(result_sentences(project$spec, result)[["headline"]]),
    if (!is.null(result) && identical(result$goal_type, "power") && !is.null(result$curve$power)) {
      pw <- as.numeric(unlist(result$curve$power))[1]
      p(sprintf("If the effect is the size the plan assumes, a study like this would miss it about %d times in 100.", round(100 * (1 - pw))))
    },
    if (!is.null(result) && identical(result$goal_type, "sample_size")) {
      p(sprintf("If the effect is the size the plan assumes, a study like this would miss it about %d times in 100.", round(100 * (1 - project$spec$goal$power))))
    },
    h3(class = "h5", "Questions to ask"),
    if (length(questions)) tags$ul(class = "plan-questions", lapply(questions, tags$li)) else
      p("Nothing stood out in these checks."),
    p(class = "small", "These checks only look at what the plan states and leaves out. They can't tell whether the effect size, the design or the measures are right for the research question. They are prompts for a conversation, not a pass or fail."),
    h3(class = "h5", "The reasons given, in the author's words"),
    if (length(reasons)) tags$ul(reasons) else p("None."),
    h3(class = "h5", "Everything the plan entered"),
    tags$ul(class = "result-inputs", lapply(entered_lines(fields, values), tags$li)),
    if (length(project$notes)) tagList(h3(class = "h5", "About the file"), tags$ul(lapply(project$notes, tags$li))),
    div(class = "nav-buttons",
      pick_button("Open it in the app and rerun it", "check_open", class = "btn btn-primary"),
      pick_button("Start again", "home", class = "btn btn-link"))
  )
}
