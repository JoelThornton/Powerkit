# A study plan any card can join (judgement call D5, decided 30 October
# 2026). "Plan my whole study" covers independent people measured once or
# twice; a nested, repeated-measures or dyadic study finds its analyses
# one card at a time, so after a result any card can add it to one shared
# plan. Each analysis is powered on its own card; the plan lists them,
# names the largest sample size, and says that the chance of all of them
# being significant together is not calculated. The engine writes and
# reads the plan file (write_study_plan(), read_study_plan()).

# One analysis in the plan, from a calculation shown on a result screen.
plan_entry <- function(tree, endpoint, calc, route) {
  result <- calc$result
  goal <- result$goal_type
  list(
    endpoint = endpoint,
    label = tree$endpoints[[endpoint]]$label %||% endpoint,
    headline = result_sentences(calc$spec, result)[["headline"]],
    goal = goal,
    n = if (identical(goal, "sample_size")) result$n_required$n,
    # Cluster trials count groups, not people, so their N isn't compared
    # with the others'.
    comparable = !identical(calc$spec$design, "cluster_trial"),
    spec = calc$spec,
    result = result,
    route = route
  )
}

# The same analysis, opened again from a saved study plan file.
plan_entry_from_project <- function(tree, project) {
  endpoint <- project$route$endpoint %||% ""
  result <- project$result
  goal <- result$goal_type
  list(
    endpoint = endpoint,
    label = tree$endpoints[[endpoint]]$label %||% project$spec$template,
    headline = NULL,
    goal = goal,
    n = if (identical(goal, "sample_size")) result$n_required$n,
    comparable = !identical(project$spec$design, "cluster_trial"),
    project = project
  )
}

# The analyses to hand to write_study_plan(). An analysis opened from a
# file is saved again from what was read.
plan_analyses <- function(entries) {
  lapply(entries, function(e) {
    if (!is.null(e$project)) {
      list(spec = e$project$spec, route = e$project$route)
    } else {
      list(spec = e$spec, result = e$result, route = e$route)
    }
  })
}

study_plan_file_name <- function() "powerkit-study-plan.powerkit.json"

# Under a result, in "Save and share".
study_plan_bar_ui <- function(entries, in_plan) {
  k <- length(entries)
  div(class = "study-plan-bar nav-buttons mt-2",
    if (in_plan) span(class = "study-plan-added", role = "status", "Added to your study plan.")
    else actionButton("plan_add", "Add this to my study plan", class = "btn btn-outline-primary"),
    if (k > 0) actionLink("plan_view", sprintf("See your study plan (%d %s)", k, if (k == 1) "analysis" else "analyses")))
}

# The study plan screen.
study_plan_ui <- function(entries) {
  comparable <- Filter(function(e) e$comparable && !is.null(e$n), entries)
  largest <- if (length(comparable)) comparable[[which.max(vapply(comparable, function(e) e$n, numeric(1)))]]
  esc <- function(x) htmltools::htmlEscape(x)
  tagList(
    h2("Your study plan"),
    p("Each analysis is powered on its own card. Add every analysis your study's conclusions rest on."),
    if (length(entries) == 0) p("Your plan is empty. After a result, press “Add this to my study plan”.")
    else tags$ol(class = "study-plan-list", lapply(entries, function(e) tags$li(
      tags$strong(e$label),
      if (!is.null(e$headline)) p(class = "small", e$headline)
      else if (!is.null(e$n)) p(class = "small", sprintf("Sample size from the saved result: %s.", whole(e$n)))
      else p(class = "small", "Opened from a saved plan: open it as a project to see its result.")))),
    if (!is.null(largest)) p(class = "lead", HTML(sprintf(
      "The largest sample size in your plan is <strong>N = %s</strong>, for %s. With that many, each analysis whose sample size is counted in people reaches the power its card asked for.",
      whole(largest$n), esc(largest$label)))),
    if (any(!vapply(entries, function(e) e$comparable, logical(1)))) p(class = "small",
      "A cluster-randomised trial counts groups, not people, so its number is not compared with the others."),
    if (length(entries) >= 2) p(class = "study-plan-joint text-muted",
      "Each analysis has the power its card shows. The chance that all of them are significant in the same study is lower, and powerkit doesn't calculate it for these designs yet. If your conclusion needs every one of them, say so in your plan and consider a higher target power for each."),
    div(class = "nav-buttons",
      actionButton("plan_more", "Add another analysis", class = "btn btn-primary"),
      if (length(entries)) downloadButton("download_study_plan", "Save study plan", class = "btn btn-outline-primary"),
      if (length(entries)) actionLink("plan_clear", "Start a new plan")),
    p(class = "small", "“Add another analysis” starts “Help me choose”, which finds the next analysis from your study's description. Save study plan keeps every analysis in one file; open it from the start screen.")
  )
}
