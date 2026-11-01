# A study plan any card can join (judgement call D5, decided 30 October
# 2026). "Plan my whole study" covers independent people measured once or
# twice; a nested, repeated-measures or dyadic study finds its analyses
# one card at a time, so after a result any card can add it to one shared
# plan. Each analysis is powered on its own card; the plan lists them,
# names the largest sample size, and says that the chance of all of them
# being significant together is not calculated. The engine writes and
# reads the plan file (write_study_plan(), read_study_plan()).

# An analysis's name in the plan: the card's plain name, never its code.
plan_label <- function(tree, endpoint, fallback = "An analysis") {
  ep <- tree$endpoints[[endpoint]]
  ep$plain_name %||% ep$doc_name %||% ep$label %||% fallback
}

# The sample size an analysis asks for: a power result's N, or the N a
# precision result needs for its width.
plan_n <- function(result) {
  wants_n <- identical(result$goal_type, "sample_size") ||
    (identical(result$goal_type, "precision") && !is.na(result$precision$target_width %||% NA))
  if (wants_n && is.list(result$n_required)) result$n_required$n
}

# One analysis in the plan, from a calculation shown on a result screen.
plan_entry <- function(tree, endpoint, calc, route) {
  result <- calc$result
  goal <- result$goal_type
  words <- if (is_precision(calc$spec)) precision_sentences(calc$spec, result) else result_sentences(calc$spec, result)
  list(
    endpoint = endpoint,
    label = plan_label(tree, endpoint),
    headline = words[["headline"]],
    goal = goal,
    n = plan_n(result),
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
    label = plan_label(tree, endpoint),
    headline = NULL,
    goal = goal,
    n = plan_n(result),
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

# The specs of the plan's analyses.
plan_specs <- function(entries) lapply(entries, function(e) e$spec %||% e$project$spec)

# Joint power is offered when every analysis compares the same randomised
# groups on a different outcome (independent t-tests, or cluster-randomised
# trials), the designs PUMP covers; the engine's joint_power() checks the
# rest and says plainly when it can't calculate.
joint_power_offered <- function(entries) {
  if (length(entries) < 2) return(FALSE)
  templates <- vapply(plan_specs(entries), function(s) s$template %||% "", character(1))
  length(unique(templates)) == 1 && templates[[1]] %in% c("independent_t", "cluster_randomised")
}

# The largest sample size in the plan, which joint power is calculated at.
plan_largest_n <- function(entries) {
  n <- unlist(lapply(entries, function(e) e$n %||% e$spec$goal$n %||% e$project$spec$goal$n))
  if (length(n)) max(n)
}

joint_power_ui <- function(entries) {
  div(class = "study-plan-joint-power result-card",
    h3(class = "h5", "The chance that every analysis is significant"),
    p("Your analyses compare the same randomised groups on different outcomes, so powerkit can calculate the chance that all of them are significant in the same study, with PUMP. It depends on how strongly the outcomes are correlated."),
    numericInput("plan_rho", "Correlation between the outcomes (for example 0.3)", value = NA, min = -0.99, max = 0.99, step = 0.05),
    actionButton("plan_joint", "Calculate joint power", class = "btn btn-outline-primary"),
    uiOutput("plan_joint_result"))
}

joint_power_sentence <- function(calc, entries) {
  pct <- function(x) sprintf("%.0f%%", 100 * x)
  labels <- vapply(entries, function(e) e$label, character(1))
  each <- paste(sprintf("%s for %s", vapply(calc$each, pct, character(1)), labels), collapse = "; ")
  c(headline = sprintf("With N = %s and outcomes correlated %s, the chance that every analysis is significant is %s.",
      whole(calc$n), format(calc$rho), pct(calc$complete)),
    detail = sprintf("Each on its own: %s. Calculated by PUMP %s (pump_power(), design %s, %s simulated test statistics, seed %s), each test at its own significance level. PUMP pools the two groups' variances, so an independent t-test's power can differ slightly from its card's Welch test. Cite PUMP: Hunter, Miratrix and Porter (2024), Journal of Statistical Software 108(6), its own citation().",
      each, calc$provenance$packages$PUMP, calc$design, format(calc$provenance$tnum, big.mark = ","), calc$provenance$seed))
}

# Under a result, in "Write it up and save it".
study_plan_bar_ui <- function(entries, in_plan) {
  k <- length(entries)
  div(class = "study-plan-bar nav-buttons mt-2",
    if (in_plan) span(class = "study-plan-added", role = "status", "Added to your study plan.")
    else actionButton("plan_add", "Add this to my study plan", class = "btn btn-outline-primary"),
    if (k > 0) actionLink("plan_view", sprintf("See your study plan (%d %s)", k, if (k == 1) "analysis" else "analyses")))
}

# The study plan screen: the largest sample size first, then each
# analysis with its own N, which can be removed.
study_plan_ui <- function(entries) {
  comparable <- Filter(function(e) e$comparable && !is.null(e$n), entries)
  largest <- if (length(comparable)) comparable[[which.max(vapply(comparable, function(e) e$n, numeric(1)))]]
  esc <- function(x) htmltools::htmlEscape(x)
  k <- length(entries)
  item <- function(e, i) {
    sets <- !is.null(largest) && identical(e, largest)
    tags$li(class = paste("plan-item", if (sets) "plan-item-sets"),
      div(class = "plan-item-body",
        tags$strong(class = "plan-item-name", e$label),
        if (sets) tags$span(class = "plan-item-tag", "Sets the sample size"),
        if (!is.null(e$headline)) p(class = "small", e$headline)
        else if (!is.null(e$n)) p(class = "small", sprintf("Sample size from the saved result: %s.", whole(e$n)))
        else p(class = "small", "Opened from a saved plan: open it as a project to see its result.")),
      if (!is.null(e$n)) div(class = "plan-item-n",
        tags$span(class = "plan-item-n-value", whole(e$n)),
        tags$span(class = "plan-item-n-unit", if (e$comparable) "needed" else "groups needed")),
      tags$button(type = "button", class = "btn btn-link btn-sm plan-remove",
        `aria-label` = sprintf("Remove %s from the plan", e$label),
        onclick = sprintf("Shiny.setInputValue('plan_remove', %d, {priority: 'event'})", i), "Remove"))
  }
  tagList(
    h2("Your study plan"),
    p("Each analysis is powered on its own card. Add every analysis your study's conclusions rest on."),
    if (k == 0) div(class = "plan-empty result-card",
      p(tags$strong("Your plan is empty.")),
      tags$ol(
        tags$li("Find an analysis with \u201cHelp me choose\u201d or \u201cI know my analysis\u201d, and calculate its sample size."),
        tags$li("Under the result, press \u201cAdd this to my study plan\u201d."),
        tags$li("Do the same for every analysis your conclusions rest on, then save the plan."))),
    if (!is.null(largest)) div(class = "result-hero plan-hero",
      div(class = "result-figure",
        tags$span(class = "result-figure-value", whole(largest$n)),
        tags$span(class = "result-figure-label", "the sample size your study needs"),
        tags$span(class = "result-figure-sub", if (k == 1) "from your one analysis so far" else sprintf("the largest of your %d analyses", k))),
      p(class = "plan-hero-text", HTML(sprintf(
        "The largest sample size in your plan is <strong>N = %s</strong>, for %s. With that many, each analysis whose sample size is counted in people reaches the power (or precision) its card asked for.",
        whole(largest$n), esc(largest$label))))),
    if (k > 0) tags$ol(class = "study-plan-list", Map(item, entries, seq_along(entries))),
    if (any(!vapply(entries, function(e) e$comparable, logical(1)))) p(class = "small",
      "A cluster-randomised trial counts groups, not people, so its number is not compared with the others."),
    if (joint_power_offered(entries)) joint_power_ui(entries)
    else if (k >= 2) p(class = "study-plan-joint plan-note",
      "Each analysis has the power its card shows. The chance that all of them are significant in the same study is lower, and powerkit doesn't calculate it for these designs yet. If your conclusion needs every one of them, say so in your plan and consider a higher target power for each."),
    div(class = "nav-buttons",
      actionButton("plan_more", "Add another analysis", class = "btn btn-primary"),
      if (k) downloadButton("download_study_plan", "Save study plan", class = "btn btn-outline-primary"),
      if (k) actionLink("plan_clear", "Start a new plan")),
    p(class = "small", "\u201cAdd another analysis\u201d starts \u201cHelp me choose\u201d, which finds the next analysis from your study's description. Save study plan keeps every analysis in one file; open it from the start screen.")
  )
}
