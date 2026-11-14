# Replication plans (queue item 23, docs/saving-projects.md, "Replication
# plans"): a study plan that also holds a replication's planning. The
# pre-replication notes (Karhulahti, Martončik & Adamkovič, 2025) and the
# replication planner's fields, which lived in Labs, are kept in the plan's
# `replication` record; the original's analysis, planned on its own card
# in replication mode, is the plan's analysis. The plan is saved, shared
# and downloaded like any study plan. Nothing here calculates: the goals
# come from the engine's replication_planning(), as before.

replication_plan_format <- "powerkit-replication-plan"

# Every field the replication plan keeps: the notes' boxes and where the
# researcher landed, the notes' smallest-detectable-effect panel, and the
# planner's fields.
replication_notes_ids <- c(vapply(labs_fields, `[[`, "", "id"), "labs_outcome",
  "labs_test", "labs_n", "labs_p1", "labs_rows", "labs_cols", "labs_power", "labs_alpha")
replication_plan_field_ids <- c(replication_notes_ids, replication_field_ids)

# The planner's starting values, as its screen had them.
replication_field_defaults <- list(rep_design = "two_groups", rep_original_alpha = "0.05", rep_tau = "0",
  rep_alpha = "0.05", rep_power = "0.8", rep_threshold = "10", labs_power = "0.8", labs_alpha = "0.05")

# Fields as the record keeps them: known ids only, each one string, blanks
# left out.
replication_clean_fields <- function(fields) {
  if (!is.list(fields)) fields <- as.list(fields)
  # A named empty list, so that its JSON is {} rather than [].
  if (!length(fields) || is.null(names(fields))) return(stats::setNames(list(), character()))
  fields <- fields[intersect(names(fields), replication_plan_field_ids)]
  fields <- lapply(fields, function(x) paste(as.character(unlist(x)), collapse = "\n"))
  # Blanks and the starting values are left out: the screen restores them.
  keep <- vapply(names(fields), function(id) nzchar(trimws(fields[[id]])) && !identical(fields[[id]], replication_field_defaults[[id]]), logical(1))
  fields <- fields[keep]
  if (!length(fields)) return(stats::setNames(list(), character()))
  fields[order(names(fields))]
}

replication_record <- function(fields = list(), endpoint = NULL) {
  ep <- if (is.character(endpoint) && length(endpoint) == 1L && grepl("^E[0-9]+$", endpoint)) endpoint
  record <- list(format = replication_plan_format, version = 1L, fields = replication_clean_fields(fields))
  if (!is.null(ep)) record$endpoint <- ep
  record
}

# A record read from a file or the browser, or NULL when it isn't one.
replication_normalise <- function(record) {
  if (!is.list(record) || !identical(record$format, replication_plan_format)) return(NULL)
  replication_record(record$fields %||% list(), record$endpoint)
}

plan_is_replication <- function(plan) is.list(plan$replication)

new_replication_plan <- function(name = NULL, now = Sys.time()) {
  plan <- new_plan(name %||% plan_default_name(as.Date(now), "Replication plan"), now = now)
  plan$replication <- replication_record()
  plan
}

# Every field's value for the screen: the record's, else the starting one.
replication_values <- function(record) {
  fields <- record$fields %||% list()
  stats::setNames(lapply(replication_plan_field_ids, function(id) fields[[id]] %||% replication_field_defaults[[id]] %||% ""),
    replication_plan_field_ids)
}

# What a record holds, for telling two copies of a plan apart.
replication_content <- function(record) {
  if (!is.list(record)) return(NULL)
  r <- replication_record(record$fields, record$endpoint)
  as.character(jsonlite::toJSON(list(r$fields, r$endpoint), auto_unbox = TRUE, null = "null"))
}

# The fields (and the original's card) as they stand, kept in the plan,
# which counts as changed only when they do.
plan_set_replication <- function(plan, fields = NULL, endpoint = NULL, now = Sys.time()) {
  old <- plan$replication %||% replication_record()
  record <- replication_record(if (is.null(fields)) old$fields else fields,
    if (is.null(endpoint)) old$endpoint else endpoint)
  if (identical(replication_content(old), replication_content(record)) && is.list(plan$replication)) return(plan)
  plan$replication <- record
  plan_touch(plan, now)
}

# A replication plan with no calculated analysis yet: a plan file needs an
# analysis, so it is saved as the replication planner's file (which the
# version before this one opens in Labs), with the record and the plan's
# id, name and description beside it.
plan_replication_only_text <- function(plan) {
  record <- replication_record(plan$replication$fields, plan$replication$endpoint)
  file <- replication_file(record$fields, powerkit_version())
  file$replication <- record
  file$study_plan <- list(id = plan$id, name = plan$name, description = plan$description %||% "")
  as.character(jsonlite::toJSON(file, auto_unbox = TRUE, pretty = TRUE, null = "null", digits = NA))
}

# A replication planner file: one a replication plan saved before it had
# an analysis (it names the plan), or one the Labs planner saved, which
# becomes a new replication plan. NULL when the text isn't one.
plan_from_replication_text <- function(text, now = Sys.time()) {
  data <- tryCatch(jsonlite::parse_json(text, simplifyVector = FALSE), error = function(e) NULL)
  if (!is.list(data) || !identical(data$app, "powerkit-replication-planner") || !is.list(data$fields)) return(NULL)
  meta <- data$study_plan
  saved_date <- tryCatch(as.Date(substr(data$saved %||% "", 1L, 10L)), error = function(e) NA)
  if (is.na(saved_date)) saved_date <- as.Date(now)
  plan <- new_plan(if (is.list(meta)) meta$name else plan_default_name(saved_date, "Replication plan"), now = now)
  if (is.list(meta) && is.character(meta$id) && grepl("^[0-9a-f]{16}$", meta$id)) plan$id <- meta$id
  if (is.list(meta)) plan$description <- plan_clean_text(meta$description %||% "", plan_description_max)
  plan$replication <- replication_normalise(data$replication) %||% replication_record(data$fields)
  plan_mark_saved(plan, "file", now = now)
}

# The workspace on a replication plan's page: its sections, one at a time,
# in any order. Drawn once with the Study plans page and shown for a
# replication plan, so typing never redraws it; the server fills its
# fields from the plan when the plan opens, and keeps them in the plan.
replication_workspace_ui <- function(tree) {
  div(class = "replication-workspace",
    h3(class = "h4", "Planning the replication"),
    p(class = "small", "Fill the sections in any order and come back to them. Everything is kept in this plan: save the plan to keep it."),
    radioButtons("rep_section", NULL, choices = replication_sections, selected = "whether", inline = TRUE, width = "100%"),
    conditionalPanel("input.rep_section == 'whether'", replication_notes_ui(tree)),
    replication_planner_sections())
}

# Under "The original study": the original's analysis on its own card,
# which plans the replication for its design (12 November 2026).
replication_card_status_ui <- function(tree, plan) {
  ep <- plan$replication$endpoint
  entry <- if (length(plan$entries)) plan$entries[[1]]
  div(class = "rep-card-status form-group-box",
    h4(class = "h6", "Its analysis, on its own card"),
    if (is.null(ep)) tagList(
      p("Find the original study's design with the design finder's questions. Its card plans the replication's sample size for that design, with the effect labelled as the original's, and the result is kept in this plan."),
      actionButton("rep_find_design", "Find the original's design", class = "btn btn-primary"))
    else tagList(
      p(HTML(sprintf("The original's design: <strong>%s</strong>%s.", htmltools::htmlEscape(tree$endpoints[[ep]]$plain_name %||% ep),
        if (!is.null(entry)) sprintf(" (planned: %s)", htmltools::htmlEscape(plan_item_summary(entry))) else ""))),
      div(class = "nav-buttons",
        actionButton("rep_open_card", if (is.null(entry)) "Plan it on its card" else "Open its card again", class = "btn btn-primary"),
        actionButton("rep_find_design", "Choose a different design", class = "btn btn-outline-secondary"))))
}

# "N = 128" or the card's own goal, for one line.
plan_item_summary <- function(entry) {
  if (is.numeric(entry$n) && length(entry$n) == 1 && is.finite(entry$n)) sprintf("N = %s", whole(entry$n)) else entry$label %||% "calculated"
}

# The original's analysis, as its card planned it, for the write-up: what
# it found and the card's own methods paragraph. Nothing is recalculated.
replication_analysis_lines <- function(plan, tree, forms) {
  if (!length(plan$entries)) return(NULL)
  unlist(lapply(plan$entries, function(e) {
    text <- tryCatch(planning_methods_text(tree, forms, plan_entry_calc(e)), error = function(err) NULL)
    c(sprintf("- %s: %s", e$label, plan_item_summary(e)), "",
      text %||% "The methods paragraph for this analysis is in its own planning document.", "")
  }))
}

# On the card's input screen when replicating: each effect field says it
# takes the original study's effect (12 November 2026).
replication_effect_labels <- function(groups) {
  lapply(groups, function(g) {
    g$fields <- lapply(g$fields, function(f) {
      if (isTRUE(f$effect) && is.character(f$label) && !grepl("original study", f$label, fixed = TRUE)) {
        f$label <- paste0(f$label, ", as the original study reported it")
      }
      f
    })
    g
  })
}

# A replication plan's write-up from its record alone, as "Download
# everything" gives it: the goals table is calculated by the engine when
# the original study is filled in, as the workspace would.
replication_plan_report <- function(plan, tree, forms, engine = engine_function) {
  values <- replication_values(plan$replication)
  table <- if (!length(replication_missing(values))) {
    planner <- engine("replication_planning")
    if (!is.null(planner)) tryCatch(do.call(planner, replication_args(values)), error = function(e) NULL)
  }
  notes <- values[vapply(labs_fields, `[[`, "", "id")]
  replication_report(values, table, notes, values$labs_outcome, powerkit_version(),
    analyses = replication_analysis_lines(plan, tree, forms), title = plan$name)
}
