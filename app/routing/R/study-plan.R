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
    project = project,
    # An analysis calculated from the guided plan, so that calculating it
    # again there updates it rather than adding another.
    plan_id = if (is.character(project$route$guided_analysis) && length(project$route$guided_analysis) == 1) project$route$guided_analysis
  )
}

# The analyses to hand to write_study_plan(). An analysis opened from a
# file is saved again from what was read.
plan_analyses <- function(entries) {
  lapply(entries, function(e) {
    a <- if (!is.null(e$project)) e$project else list(spec = e$spec, result = e$result, route = e$route)
    a$plan_role <- e$role
    a$plan_note <- if (nzchar(e$note %||% "")) e$note
    a
  })
}

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

# Two-group t-tests that would get joint power with Student's test: every
# analysis is one, and at least one uses Welch's (the card's default).
joint_power_needs_student <- function(entries) {
  specs <- plan_specs(entries)
  length(specs) >= 2 &&
    all(vapply(specs, function(s) identical(s$template, "independent_t") &&
      (s$target_test$method %||% "student_t") %in% c("student_t", "welch_t"), logical(1))) &&
    any(vapply(specs, function(s) identical(s$target_test$method, "welch_t"), logical(1)))
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

# An analysis calculated from "Plan my whole study" joins the study plan
# itself, replacing its own earlier result: one plan, not two.
plan_upsert <- function(plan, entry, now = Sys.time()) {
  same <- vapply(plan$entries, function(e) identical(e$plan_id, entry$plan_id), logical(1))
  if (any(same)) plan_update_entry(plan, plan$entries[[which(same)[1]]]$key, entry, now = now)
  else plan_add_entry(plan, entry, now = now)
}

# A JavaScript string literal for a confirm() or similar in an onclick
# attribute: any name or text, quotes and all, stays a string.
js_string <- function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE))

# In the top bar on every screen: the plans page, with how many plans
# there are and a marker when any has changes not saved to a file.
study_plans_chip_ui <- function(k, unsaved = FALSE) {
  tags$button(type = "button", class = "btn btn-sm share-page-btn study-plan-chip",
    title = "Your study plans: the analyses for each of your studies",
    onclick = "Shiny.setInputValue('plans_open_page', Date.now(), {priority: 'event'})",
    if (k > 0) sprintf("Study plans (%d)", k) else "Study plans",
    if (isTRUE(unsaved)) tagList(tags$span(class = "plan-unsaved-dot", `aria-hidden` = "true"),
      tags$span(class = "visually-hidden", ", some not saved to a file")))
}

# Under a result, in "Keep this result": add it to a plan (choosing which
# when there are several), or, for a result opened from a plan and then
# changed, update it there or add it as a new analysis.
study_plan_bar_ui <- function(plans, current, hash, origin = NULL, from_guided = FALSE, just_added = NULL) {
  esc_name <- function(id) plans[[id]]$name
  in_plan <- function(id) !is.null(plans[[id]]) && plan_has_result(plans[[id]], hash)
  see <- function(id) actionLink("plan_view", "See the study plan")
  save_note <- function(id) if (!is.null(plans[[id]]) && plan_unsaved(plans[[id]]))
    span(class = "plan-status-unsaved small", " It is only in this browser until you save it.")
  if (!is.null(just_added) && identical(just_added$hash, hash) && !is.null(plans[[just_added$plan]])) {
    return(div(class = "study-plan-bar nav-buttons mt-2",
      span(class = "study-plan-added", role = "status",
        sprintf("%s \u201c%s\u201d.", if (isTRUE(just_added$updated)) "Updated in" else "Added to", esc_name(just_added$plan)),
        save_note(just_added$plan)),
      see(just_added$plan)))
  }
  if (!is.null(origin)) {
    if (identical(origin$hash, hash)) {
      return(div(class = "study-plan-bar nav-buttons mt-2",
        span(class = "study-plan-added", role = "status", sprintf("From your plan \u201c%s\u201d.", esc_name(origin$plan))),
        see(origin$plan)))
    }
    return(div(class = "study-plan-bar nav-buttons mt-2",
      span(class = "small", sprintf("You opened this analysis from \u201c%s\u201d and changed it.", esc_name(origin$plan))),
      actionButton("plan_entry_update", "Update it in the plan", class = "btn btn-outline-primary"),
      actionButton("plan_entry_add_new", "Add it as a new analysis", class = "btn btn-outline-secondary")))
  }
  if (from_guided && !is.null(current) && in_plan(current)) {
    return(div(class = "study-plan-bar nav-buttons mt-2",
      span(class = "study-plan-added", role = "status",
        sprintf("This analysis is in your study plan \u201c%s\u201d, with the other analyses of your whole-study plan.", esc_name(current))),
      see(current)))
  }
  if (!is.null(current) && in_plan(current)) {
    return(div(class = "study-plan-bar nav-buttons mt-2",
      span(class = "study-plan-added", role = "status", sprintf("Already in \u201c%s\u201d.", esc_name(current))), see(current)))
  }
  ids <- names(plans)
  ordered <- c(intersect(current, ids), setdiff(ids, current))
  div(class = "study-plan-bar nav-buttons mt-2",
    actionButton("plan_add", "Add this to my study plan", class = "btn btn-outline-primary"),
    if (length(ids) >= 2) span(class = "plan-target",
      tags$label(`for` = "plan_target", class = "small", "Add to"),
      tags$select(id = "plan_target", class = "form-select form-select-sm",
        onchange = "Shiny.setInputValue('plan_target', this.value)",
        lapply(ordered, function(id) tags$option(value = id, plans[[id]]$name)),
        tags$option(value = "new", "A new plan")),
      tags$script(HTML(sprintf("Shiny.setInputValue('plan_target', %s);", js_string(ordered[[1]]))))))
}

# Whether a plan has been saved, said where the plan is shown. The
# browser's copy can be cleared without warning, so a plan that is only
# there says so.
plan_status_ui <- function(plan) {
  if (isTRUE(plan$too_large)) {
    return(span(class = "plan-status plan-status-unsaved", "This plan is too large to keep in this browser: save it to your computer."))
  }
  if (!plan_has_content(plan)) return(span(class = "plan-status", "No analyses yet."))
  if (plan_unsaved(plan)) {
    return(span(class = "plan-status plan-status-unsaved", "Only in this browser: save it to your computer."))
  }
  when <- format(plan$saved_at, "%Y-%m-%d %H:%M:%S UTC", tz = "UTC")
  span(class = "plan-status plan-status-saved",
    if (identical(plan$saved_how, "link")) "Copied as a link " else "Saved to a file ", saved_time_ui(when), ".")
}

# The largest comparable requirement among a plan's analyses, or NULL.
plan_largest_entry <- function(entries) {
  known_n <- function(e) is.numeric(e$n) && length(e$n) == 1L && is.finite(e$n) && e$n > 0
  comparable <- if (plan_counts_compatible(entries) && all(vapply(entries, known_n, logical(1)))) entries else list()
  if (length(comparable)) comparable[[which.max(vapply(comparable, function(e) e$n, numeric(1)))]]
}

# One analysis on its plan's page: what it found, its N, its role and
# note, and Open and Remove.
plan_item_ui <- function(e, sets = FALSE) {
  sample <- plan_entry_sample(e)
  key <- e$key
  note_id <- paste0("plan_note_", key)
  tags$li(class = paste("plan-item", if (sets) "plan-item-sets"),
    div(class = "plan-item-body",
      tags$strong(class = "plan-item-name", e$label),
      if (sets) tags$span(class = "plan-item-tag", "Largest comparable requirement"),
      if (!is.null(e$headline)) p(class = "small", e$headline)
      else if (!is.null(e$n)) p(class = "small", sprintf("Sample size from the saved result: %s.", whole(e$n))),
      p(class = "small", sample$note),
      if (nzchar(e$note %||% "")) p(class = "small plan-item-note", tags$strong("Note: "), e$note),
      div(class = "plan-item-controls",
        tags$button(type = "button", class = "btn btn-sm btn-outline-primary",
          onclick = sprintf("Shiny.setInputValue('plan_entry_open', %s, {priority: 'event'})", js_string(key)),
          `aria-label` = sprintf("Open %s", e$label), "Open"),
        tags$label(class = "small", `for` = paste0("plan_role_", key), "Role"),
        tags$select(id = paste0("plan_role_", key), class = "form-select form-select-sm plan-role",
          onchange = sprintf("Shiny.setInputValue('plan_entry_role', {key: %s, role: this.value}, {priority: 'event'})", js_string(key)),
          lapply(names(plan_roles), function(r) tags$option(value = r, selected = if (identical(e$role, r)) NA, plan_roles[[r]]))),
        tags$details(class = "plan-note-edit",
          tags$summary(class = "small", if (nzchar(e$note %||% "")) "Edit note" else "Add a note"),
          tags$label(class = "visually-hidden", `for` = note_id, sprintf("Note on %s", e$label)),
          tags$textarea(id = note_id, class = "form-control form-control-sm", rows = 2, maxlength = plan_note_max, e$note %||% ""),
          tags$button(type = "button", class = "btn btn-sm btn-outline-secondary mt-1",
            onclick = sprintf("Shiny.setInputValue('plan_entry_note', {key: %s, note: document.getElementById(%s).value}, {priority: 'event'})",
              js_string(key), js_string(note_id)), "Save note")),
        tags$button(type = "button", class = "btn btn-link btn-sm plan-remove",
          `aria-label` = sprintf("Remove %s from the plan", e$label),
          onclick = sprintf("if (confirm('Remove this analysis from your study plan?')) Shiny.setInputValue('plan_remove', %s, {priority: 'event'})", js_string(key)),
          "Remove"))),
    if (!is.null(e$n)) div(class = "plan-item-n",
      tags$span(class = "plan-item-n-value", whole(e$n)),
      tags$span(class = "plan-item-n-unit", paste(sample$unit, "needed"))))
}

# A plan's page on the Study plans page: its name and description, the
# largest comparable sample size, its analyses, and saving.
# On a plan's page: the guided whole-study plan it holds ("Plan my whole
# study"), the last whole-study simulation's result, and the way back to
# the guided screens.
plan_guided_ui <- function(record) {
  summary <- record$plan$ws_result
  ticked <- length(unlist(record$plan$ticked))
  div(class = "plan-guided result-card",
    h3(class = "h5", "Whole-study plan"),
    p(sprintf("Made with “Plan my whole study”: %s chosen, with the values you entered for each.",
      if (ticked == 1) "1 analysis" else sprintf("%d analyses", ticked))),
    if (is.list(summary)) p(class = "plan-guided-result", tags$strong("Last whole-study simulation: "), whole_study_summary_text(summary))
    else p(class = "small", "No whole-study simulation has been run for it yet."),
    actionButton("plan_open_guided", "Open the guided plan", class = "btn btn-outline-primary"))
}

# The plan page's and the study-wide document's wording on sample sizes.
plan_common_recruitment_caveat <- "The recorded sample units and design structures match. A common recruitment plan also needs the same population, eligibility, allocation and measurement schedule; the maximum alone does not establish those."
plan_incomparable_note <- "These analyses have different or incomplete sample requirements. Their counts are kept separate; there is no single study-wide sample size here. Participants, pairs, items and studies cannot be compared just by taking the largest number. Matching units also need compatible allocation and measurement schedules."

plan_page_ui <- function(plan, plans_n = 1L) {
  entries <- plan$entries
  k <- length(entries)
  largest <- plan_largest_entry(entries)
  esc <- function(x) htmltools::htmlEscape(x)
  unsaved <- plan_has_content(plan) && plan_unsaved(plan)
  saveable <- plan_has_content(plan)
  tagList(
    actionLink("plans_back", "‹ All study plans", class = "plans-back"),
    h2(class = "plan-title", plan$name),
    tags$details(class = "plan-rename",
      tags$summary(class = "small", "Rename"),
      textInput("plan_name", "Name of this plan", value = plan$name, width = "100%"),
      actionButton("plan_name_save", "Save name", class = "btn btn-sm btn-outline-secondary")),
    div(class = "plan-description",
      textAreaInput("plan_description", "About this study (optional)", value = plan$description %||% "", rows = 2, width = "100%",
        placeholder = "For example the question, the population and the design."),
      actionButton("plan_description_save", "Save description", class = "btn btn-sm btn-outline-secondary")),
    # Its own output (filled by the server), so that saving or copying a
    # link doesn't redraw the page under the share button.
    p(class = "plan-status-line", uiOutput("plan_status", inline = TRUE)),
    if (is.list(plan$guided)) plan_guided_ui(plan$guided),
    if (k == 0 && !is.list(plan$guided)) div(class = "plan-empty result-card",
      p(tags$strong("This plan has no analyses yet.")),
      tags$ol(
        tags$li("Press “Add an analysis” to find one with “Help me choose”, or use “I know my analysis”, and calculate its sample size."),
        tags$li("Under the result, press “Add this to my study plan”."),
        tags$li("Do the same for every analysis your conclusions rest on, then save the plan."))),
    if (k > 0) div(class = "plan-overview",
      h3(class = "h5", "Overview"),
      p(class = "plan-role-counts", plan_role_counts_text(entries))),
    if (!is.null(largest)) div(class = "result-hero plan-hero",
      div(class = "result-figure",
        tags$span(class = "result-figure-value", whole(largest$n)),
        tags$span(class = "result-figure-label", paste("largest requirement in", plan_entry_sample(largest)$unit)),
        tags$span(class = "result-figure-sub", if (k == 1) "from your one analysis so far" else sprintf("the largest of your %d analyses", k))),
      p(class = "plan-hero-text", HTML(sprintf(
        "The largest comparable requirement is <strong>N = %s</strong>, for %s. %s",
        whole(largest$n), esc(largest$label), esc(plan_common_recruitment_caveat))))),
    if (k > 0) tags$ol(class = "study-plan-list",
      lapply(entries, function(e) plan_item_ui(e, sets = !is.null(largest) && identical(e$key, largest$key)))),
    if (k > 1 && is.null(largest)) p(class = "plan-note", plan_incomparable_note),
    if (joint_power_offered(entries)) joint_power_ui(entries)
    else if (joint_power_needs_student(entries)) p(class = "study-plan-joint plan-note",
      "Each analysis has the power its card shows. The chance that all of them are significant in the same study is calculated for Student's t-test only (PUMP's test), and these analyses use Welch's: choose Student's test on each card to see it. If your conclusion needs every one of them, say so in your plan and consider a higher target power for each.")
    else if (k >= 2) p(class = "study-plan-joint plan-note",
      "Each analysis has the power its card shows. The chance that all of them are significant in the same study is lower, and powerkit doesn't calculate it for these designs yet. If your conclusion needs every one of them, say so in your plan and consider a higher target power for each."),
    div(class = "nav-buttons",
      if (saveable) download_button("download_study_plan", "Save plan", class = "btn btn-primary"),
      actionButton("plan_more", "Add an analysis", class = "btn btn-outline-primary"),
      if (saveable) share_link_ui("study_plan"),
      if (k) download_button("download_plan_bundle", "Download everything (.zip)", class = "btn btn-outline-primary")),
    p(class = "small", "Save plan keeps every analysis, with this plan's name, description, roles and notes, in one file: open it on the Study plans page or the start screen, on any computer. Copy a link puts the same inside a link; powerkit stores nothing, so anyone with the link can open it. Download everything adds a planning document for the whole study, the references, and each analysis's own documents and R script; the zip opens again as the plan."),
    p(class = "small plan-delete",
      tags$a(href = "#", role = "button", id = "plan_delete_link",
        onclick = sprintf("if (confirm(%s)) Shiny.setInputValue('plan_delete', Date.now(), {priority: 'event'}); return false;",
          js_string(paste0("Delete “", plan$name, "” from this browser?",
            if (unsaved) " It has not been saved to a file, so it will be gone." else ""))),
        "Delete this plan"))
  )
}
