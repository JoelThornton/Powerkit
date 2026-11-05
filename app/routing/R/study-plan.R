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

plan_entry_sample <- function(entry) entry$sample %||% plan_sample(entry$spec %||% entry$project$spec)

plan_counts_compatible <- function(entries) {
  if (!length(entries)) return(FALSE)
  keys <- lapply(entries, function(entry) plan_entry_sample(entry)$compatibility_key)
  all(vapply(keys, function(key) is.character(key) && length(key) == 1L && nzchar(key), logical(1))) &&
    length(unique(unlist(keys))) == 1L
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
    sample = plan_sample(calc$spec),
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
    sample = plan_sample(project$spec),
    project = project
  )
}

# The analyses to hand to write_study_plan(). An analysis opened from a
# file is saved again from what was read.
plan_analyses <- function(entries) {
  lapply(entries, function(e) {
    if (!is.null(e$project)) {
      e$project
    } else {
      list(spec = e$spec, result = e$result, route = e$route)
    }
  })
}

study_plan_file_name <- function() "powerkit-study-plan.powerkit.json"

# The specs of the plan's analyses.
plan_specs <- function(entries) lapply(entries, function(e) e$spec %||% e$project$spec)

# Joint power is offered when every analysis compares the same randomised
# groups on a different outcome (independent t-tests, cluster-randomised
# trials or multisite trials), the designs PUMP covers; the engine's joint_power() checks the
# rest and says plainly when it can't calculate.
joint_power_offered <- function(entries) {
  if (length(entries) < 2) return(FALSE)
  templates <- vapply(plan_specs(entries), function(s) s$template %||% "", character(1))
  if (any(vapply(plan_specs(entries), function(s) identical(s$template, "independent_t") &&
      !identical(s$target_test$method %||% "student_t", "student_t"), logical(1)))) return(FALSE)
  length(unique(templates)) == 1 && templates[[1]] %in% c("independent_t", "cluster_randomised", "multisite")
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
    detail = sprintf("Each on its own: %s. Calculated by PUMP %s (pump_power(), design %s, %s simulated test statistics, seed %s), each test at its own significance level. %s Cite PUMP: Hunter, Miratrix and Porter (2024), Journal of Statistical Software 108(6), its own citation().",
      each, calc$provenance$packages$PUMP, calc$design, format(calc$provenance$tnum, big.mark = ","), calc$provenance$seed,
      joint_power_difference(calc$design)))
}

# How PUMP's power for each outcome can differ from its card's
# (docs/conventions.md, Known difference 14).
joint_power_difference <- function(design) {
  if (identical(design, "d1.1_m1c")) {
    return("PUMP pools the two groups' variances, so an independent t-test's power can differ slightly from its card's Welch test.")
  }
  "PUMP draws each test statistic as a central t shifted by its expected size, as PowerUp! does, where the card uses the noncentral t, so with few groups each outcome's power here is a little below its card's (about 3 points with 10 groups; under 1 point from 20)."

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
  known_n <- function(e) is.numeric(e$n) && length(e$n) == 1L && is.finite(e$n) && e$n > 0
  comparable <- if (plan_counts_compatible(entries) && all(vapply(entries, known_n, logical(1)))) entries else list()
  largest <- if (length(comparable)) comparable[[which.max(vapply(comparable, function(e) e$n, numeric(1)))]]
  esc <- function(x) htmltools::htmlEscape(x)
  k <- length(entries)
  item <- function(e, i) {
    sets <- !is.null(largest) && identical(e, largest)
    sample <- plan_entry_sample(e)
    tags$li(class = paste("plan-item", if (sets) "plan-item-sets"),
      div(class = "plan-item-body",
        tags$strong(class = "plan-item-name", e$label),
        if (sets) tags$span(class = "plan-item-tag", "Largest comparable requirement"),
        if (!is.null(e$headline)) p(class = "small", e$headline)
        else if (!is.null(e$n)) p(class = "small", sprintf("Sample size from the saved result: %s.", whole(e$n)))
        else p(class = "small", "Opened from a saved plan: open it as a project to see its result."),
        p(class = "small", sample$note)),
      if (!is.null(e$n)) div(class = "plan-item-n",
        tags$span(class = "plan-item-n-value", whole(e$n)),
        tags$span(class = "plan-item-n-unit", paste(sample$unit, "needed"))),
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
        tags$span(class = "result-figure-label", paste("largest requirement in", plan_entry_sample(largest)$unit)),
        tags$span(class = "result-figure-sub", if (k == 1) "from your one analysis so far" else sprintf("the largest of your %d analyses", k))),
      p(class = "plan-hero-text", HTML(sprintf(
        "The largest comparable requirement is <strong>N = %s</strong>, for %s. The recorded sample units and design structures match. A common recruitment plan also needs the same population, eligibility, allocation and measurement schedule; the maximum alone does not establish those.",
        whole(largest$n), esc(largest$label))))),
    if (k > 0) tags$ol(class = "study-plan-list", Map(item, entries, seq_along(entries))),
    if (k > 1 && !length(comparable)) p(class = "plan-note",
      "These analyses have different or incomplete sample requirements. Their counts are kept separate; there is no single study-wide sample size here. Participants, pairs, items and studies cannot be compared just by taking the largest number. Matching units also need compatible allocation and measurement schedules."),
    if (joint_power_offered(entries)) joint_power_ui(entries)
    else if (k >= 2) p(class = "study-plan-joint plan-note",
      "Each analysis has the power its card shows. The chance that all of them are significant in the same study is lower, and powerkit doesn't calculate it for these designs yet. If your conclusion needs every one of them, say so in your plan and consider a higher target power for each."),
    div(class = "nav-buttons",
      actionButton("plan_more", "Add another analysis", class = "btn btn-primary"),
      if (k) download_button("download_study_plan", "Save study plan", class = "btn btn-outline-primary"),
      if (k) actionLink("plan_clear", "Start a new plan")),
    p(class = "small", "\u201cAdd another analysis\u201d starts \u201cHelp me choose\u201d, which finds the next analysis from your study's description. Save study plan keeps every analysis in one file; open it from the start screen.")
  )
}
