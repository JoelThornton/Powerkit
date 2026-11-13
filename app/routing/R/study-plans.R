# Named study plans (docs/saving-projects.md, "Study plans", 13 November
# 2026). A researcher can keep several plans, one per study, each with a
# name, a description and its analyses (R/study-plan.R holds one plan's
# entries and page). Plans are kept in the browser and saved as files or
# links; powerkit stores nothing. These functions are pure: the server in
# app.R keeps the plans in state$plans (a list keyed by plan id) and wires
# inputs to them.
#
# A plan is list(id, name, description, entries, changed, saved_at,
# saved_how, too_large): saved_how is NULL, "file" or "link"; each entry is
# plan_entry()'s list plus key, role and note.

plan_roles <- c(primary = "Primary", secondary = "Secondary", check = "Check")
plan_name_max <- 120L
plan_description_max <- 2000L
plan_note_max <- 1000L

plan_random_hex <- function(n) paste(sample(c(0:9, letters[1:6]), n, replace = TRUE), collapse = "")
plan_new_id <- function() plan_random_hex(16)
plan_new_key <- function() plan_random_hex(12)

# "13 Nov 2026", with no leading zero on the day.
plan_date_words <- function(date) sub("^0", "", format(as.Date(date), "%d %b %Y"))

plan_default_name <- function(date = Sys.Date(), prefix = "Study plan") {
  sprintf("%s, %s", prefix, plan_date_words(date))
}

# Free text from a user: one trimmed string, at most `max` characters.
plan_clean_text <- function(x, max) {
  if (!is.character(x) || length(x) != 1L || is.na(x)) return("")
  x <- trimws(x)
  if (nchar(x) > max) substr(x, 1L, max) else x
}

new_plan <- function(name = NULL, now = Sys.time()) {
  clean <- plan_clean_text(name %||% "", plan_name_max)
  list(id = plan_new_id(), name = if (nzchar(clean)) clean else plan_default_name(as.Date(now)),
    description = "", entries = list(), changed = now, saved_at = NULL, saved_how = NULL, too_large = FALSE)
}

plan_touch <- function(plan, now) {
  plan$changed <- now
  plan
}

plan_entry_hash <- function(entry) {
  entry$result$provenance$spec_hash %||% entry$project$result$provenance$spec_hash %||% NA_character_
}

plan_has_result <- function(plan, hash) {
  if (!is.character(hash) || length(hash) != 1L || is.na(hash)) return(FALSE)
  any(vapply(plan$entries, function(e) identical(plan_entry_hash(e), hash), logical(1)))
}

plan_entry_index <- function(plan, key) {
  i <- which(vapply(plan$entries, function(e) identical(e$key, key), logical(1)))
  if (length(i)) i[[1]] else NA_integer_
}

plan_default_role <- function(plan) if (length(plan$entries)) "secondary" else "primary"

# Adds an analysis, unless the same result is already in the plan.
plan_add_entry <- function(plan, entry, now = Sys.time(), allow_duplicate = FALSE) {
  if (!allow_duplicate && plan_has_result(plan, plan_entry_hash(entry))) return(plan)
  entry$key <- entry$key %||% plan_new_key()
  entry$role <- if (isTRUE(entry$role %in% names(plan_roles))) entry$role else plan_default_role(plan)
  entry$note <- plan_clean_text(entry$note %||% "", plan_note_max)
  plan$entries <- c(plan$entries, list(entry))
  plan_touch(plan, now)
}

# Replaces an analysis with a new result, keeping its place, role and note.
plan_update_entry <- function(plan, key, entry, now = Sys.time()) {
  i <- plan_entry_index(plan, key)
  if (is.na(i)) return(plan)
  old <- plan$entries[[i]]
  entry$key <- old$key; entry$role <- old$role; entry$note <- old$note
  plan$entries[[i]] <- entry
  plan_touch(plan, now)
}

plan_remove_entry <- function(plan, key, now = Sys.time()) {
  i <- plan_entry_index(plan, key)
  if (is.na(i)) return(plan)
  plan$entries <- plan$entries[-i]
  plan_touch(plan, now)
}

plan_edit <- function(plan, name = NULL, description = NULL, now = Sys.time()) {
  if (!is.null(name)) {
    clean <- plan_clean_text(name, plan_name_max)
    if (nzchar(clean)) plan$name <- clean
  }
  if (!is.null(description)) plan$description <- plan_clean_text(description, plan_description_max)
  plan_touch(plan, now)
}

plan_edit_entry <- function(plan, key, role = NULL, note = NULL, now = Sys.time()) {
  i <- plan_entry_index(plan, key)
  if (is.na(i)) return(plan)
  if (isTRUE(role %in% names(plan_roles))) plan$entries[[i]]$role <- role
  if (!is.null(note)) plan$entries[[i]]$note <- plan_clean_text(note, plan_note_max)
  plan_touch(plan, now)
}

plan_mark_saved <- function(plan, how = c("file", "link"), now = Sys.time()) {
  plan$saved_how <- match.arg(how)
  plan$saved_at <- now
  plan
}

plan_unsaved <- function(plan) is.null(plan$saved_at) || plan$changed > plan$saved_at

# The plan's file text ("" for an empty plan or one that can't be written).
plan_to_text <- function(plan, write = engine_function("write_study_plan")) {
  if (!length(plan$entries) || is.null(write)) return("")
  analyses <- plan_analyses(plan$entries)
  tryCatch(write(analyses, id = plan$id, name = plan$name,
    description = if (nzchar(plan$description %||% "")) plan$description),
    error = function(e) "")
}

# A plan from file text, or NULL when the text isn't a readable plan.
plan_from_text <- function(tree, text, read = engine_function("read_study_plan"), now = Sys.time()) {
  if (!is.character(text) || length(text) != 1L || !nzchar(text) || nchar(text) > 5e6 || is.null(read)) return(NULL)
  file <- tryCatch(read(text), error = function(e) NULL)
  if (is.null(file) || !length(file$analyses)) return(NULL)
  saved_date <- tryCatch(as.Date(substr(file$saved %||% "", 1L, 10L)), error = function(e) NA)
  plan <- new_plan(file$name %||% plan_default_name(if (is.na(saved_date)) as.Date(now) else saved_date), now = now)
  if (is.character(file$id) && grepl("^[0-9a-f]{16}$", file$id)) plan$id <- file$id
  plan$description <- plan_clean_text(file$description %||% "", plan_description_max)
  for (i in seq_along(file$analyses)) {
    entry <- plan_entry_from_project(tree, file$analyses[[i]])
    role <- file$roles[[i]] %||% NA_character_
    entry$role <- if (!is.na(role) && role %in% names(plan_roles)) role else NULL
    entry$note <- if (is.na(file$notes[[i]] %||% NA)) "" else file$notes[[i]]
    # Everything in the file is kept, even a result it holds twice.
    plan <- plan_add_entry(plan, entry, now = now, allow_duplicate = TRUE)
  }
  plan$changed <- now
  plan_mark_saved(plan, "file", now = now)
}

# The browser's old single plan (key powerkit-study-plan), as a named plan
# that has not been saved to a file.
plans_migrate_legacy <- function(tree, text, read = engine_function("read_study_plan"), now = Sys.time()) {
  plan <- plan_from_text(tree, text, read = read, now = now)
  if (is.null(plan)) return(NULL)
  plan$name <- "My study plan"
  plan$saved_at <- NULL
  plan$saved_how <- NULL
  plan
}

# What makes two copies of a plan the same work: not when they were saved.
plan_content <- function(plan) {
  list(plan$name, plan$description %||% "",
    lapply(plan$entries, function(e) list(plan_entry_hash(e), e$role, e$note %||% "")))
}

# Adds an opened plan to the browser's plans without overwriting any:
# the same plan unchanged opens the copy already there; a different
# version is kept beside it under a new id and name.
plans_open <- function(plans, incoming, now = Sys.time()) {
  # A plan here with the same description and analyses is this plan,
  # whatever its id or name (a copy made by an earlier open, or a file
  # with no id, which gets a new one each time it is read).
  same_work <- function(p) identical(plan_content(p)[-1], plan_content(incoming)[-1])
  existing <- plans[[incoming$id]]
  if (!is.null(existing) && identical(plan_content(existing), plan_content(incoming))) {
    return(list(plans = plans, id = existing$id, message = NULL))
  }
  match <- Filter(same_work, plans)
  if (length(match)) return(list(plans = plans, id = match[[1]]$id, message = NULL))
  if (is.null(existing)) {
    plans[[incoming$id]] <- incoming
    return(list(plans = plans, id = incoming$id, message = NULL))
  }
  incoming$id <- plan_new_id()
  suffix <- sprintf(" (opened %s)", plan_date_words(as.Date(now)))
  incoming$name <- paste0(substr(incoming$name, 1L, plan_name_max - nchar(suffix)), suffix)
  plans[[incoming$id]] <- incoming
  list(plans = plans, id = incoming$id,
    message = sprintf("You already had a different version of this plan, so both are kept: the one you opened is “%s”.", incoming$name))
}

# The browser's copy of one plan (key powerkit-study-plan:<id>): the plan
# file's text, with when it changed and when and how it was last saved.
plan_browser_record <- function(plan, write = engine_function("write_study_plan")) {
  text <- plan_to_text(plan, write = write)
  # A plan with no analyses has no file yet (a plan file needs one), so
  # its name and description are kept on their own.
  if (!nzchar(text) && length(plan$entries)) return("")
  num <- function(t) if (is.null(t)) NULL else as.numeric(t)
  as.character(jsonlite::toJSON(list(format = "powerkit-plan-in-browser", version = 1L,
    id = plan$id, name = plan$name, description = plan$description %||% "",
    changed = num(plan$changed), saved_at = num(plan$saved_at), saved_how = plan$saved_how,
    file = if (nzchar(text)) text),
    auto_unbox = TRUE, digits = NA, null = "null"))
}

plan_from_browser_record <- function(tree, record, read, now) {
  rec <- tryCatch(jsonlite::parse_json(record, simplifyVector = FALSE), error = function(e) NULL)
  if (!is.list(rec) || !identical(rec$format, "powerkit-plan-in-browser")) return(NULL)
  if (is.character(rec$file) && nzchar(rec$file)) {
    plan <- plan_from_text(tree, rec$file, read = read, now = now)
    if (is.null(plan)) return(NULL)
  } else {
    if (!is.character(rec$id) || !grepl("^[0-9a-f]{16}$", rec$id)) return(NULL)
    plan <- new_plan(rec$name, now = now)
    plan$id <- rec$id
    plan$description <- plan_clean_text(rec$description %||% "", plan_description_max)
  }
  time <- function(x) if (is.numeric(x) && length(x) == 1L) as.POSIXct(x, origin = "1970-01-01", tz = "UTC")
  plan$changed <- time(rec$changed) %||% now
  plan$saved_at <- time(rec$saved_at)
  plan$saved_how <- if (!is.null(plan$saved_at) && isTRUE(rec$saved_how %in% c("file", "link"))) rec$saved_how
  plan
}

# Everything the browser kept, read once a session starts: the index, each
# plan's record and, from before plans had names, the single plan. A record
# that can't be read is left out; the others are kept. `migrated` is the id
# of the plan made from the old single plan, if one was made.
plans_from_browser <- function(tree, saved, read = engine_function("read_study_plan"), now = Sys.time()) {
  plans <- list()
  migrated <- NULL
  if (!is.list(saved)) return(list(plans = plans, current = NULL, migrated = NULL))
  # Every record kept loads; the index gives only the order and the
  # current plan (another tab, or a failed index write, can leave a plan
  # out of it).
  ids <- unique(c(unlist(saved$index$ids, use.names = FALSE), names(saved$records)))
  for (id in ids) {
    record <- saved$records[[id]]
    if (!is.character(record)) next
    plan <- tryCatch(plan_from_browser_record(tree, record, read, now), error = function(e) NULL)
    if (!is.null(plan)) plans[[plan$id]] <- plan
  }
  legacy <- saved$legacy
  if (is.character(legacy) && length(legacy) == 1L && nzchar(legacy)) {
    moved <- tryCatch(plans_migrate_legacy(tree, legacy, read = read, now = now), error = function(e) NULL)
    hashes <- function(p) vapply(p$entries, plan_entry_hash, character(1))
    if (!is.null(moved) && !any(vapply(plans, function(p) identical(hashes(p), hashes(moved)), logical(1)))) {
      plans[[moved$id]] <- moved
      migrated <- moved$id
    }
  }
  current <- saved$index$current
  if (!is.character(current) || !current %in% names(plans)) current <- if (length(plans)) names(plans)[[length(plans)]]
  list(plans = plans, current = current, migrated = migrated)
}

# The file name for "Save plan": the plan's name, made safe for a file.
plan_file_name <- function(plan) {
  slug <- tolower(gsub("[^A-Za-z0-9]+", "-", plan$name %||% ""))
  slug <- substr(gsub("^-+|-+$", "", slug), 1L, 60L)
  slug <- gsub("-+$", "", slug)
  sprintf("powerkit-%s.powerkit.json", if (nzchar(slug)) slug else "study-plan")
}

# An analysis in a plan as a project, to open on its card: its own project
# when it came from a file, or one written from its spec, result and route.
plan_entry_project <- function(entry, write = engine_function("write_project"), read = engine_function("read_project")) {
  if (!is.null(entry$project)) return(entry$project)
  read(write(entry$spec, entry$result, route = entry$route %||% list()))
}

# The Study plans page: every plan kept in this browser, and the ways to
# start or open one.
plans_list_ui <- function(plans, current = NULL) {
  unsaved <- Filter(function(p) length(p$entries) > 0 && plan_unsaved(p), plans)
  row <- function(plan) {
    k <- length(plan$entries)
    largest <- plan_largest_entry(plan$entries)
    tags$li(class = paste("plans-row", if (identical(plan$id, current)) "plans-row-current"),
      tags$button(type = "button", class = "btn btn-link plans-row-name",
        onclick = sprintf("Shiny.setInputValue('plans_view_plan', %s, {priority: 'event'})", js_string(plan$id)),
        plan$name),
      span(class = "plans-row-facts small",
        paste(c(if (k == 1) "1 analysis" else sprintf("%d analyses", k),
          if (!is.null(largest)) sprintf("largest comparable N = %s", whole(largest$n))), collapse = " · ")),
      span(class = "small", plan_status_ui(plan)))
  }
  tagList(
    h2("Study plans"),
    p(class = "plans-keep-note", "Kept in this browser only, which can be cleared without warning. Save each plan to your computer, or copy its link, to keep it."),
    if (!length(plans)) div(class = "plan-empty result-card",
      p(tags$strong("You have no study plans yet.")),
      p("A study plan keeps the analyses one study rests on: each powered on its own card, with the study's name and description, saved together in one file."),
      tags$ul(
        tags$li("Start one here with “New study plan”, then add analyses to it."),
        tags$li("Or calculate any analysis and press “Add this to my study plan” under its result: a plan is made for it."),
        tags$li("“Plan my whole study”, on the start screen, plans several analyses of one study together."))),
    if (length(plans)) tags$ul(class = "plans-list", lapply(rev(plans), row)),
    div(class = "nav-buttons",
      actionButton("plans_new", "New study plan", class = "btn btn-primary")),
    div(class = "open-project mt-3",
      fileInput("plans_open_file", "Open a saved plan", accept = c(".json", "application/json", ".zip", "application/zip"),
        buttonLabel = "Choose file…", placeholder = "a .powerkit.json file"),
      uiOutput("plans_open_message")),
    if (length(plans)) p(class = "small plans-forget",
      tags$a(href = "#", role = "button", id = "plans_forget_link",
        onclick = sprintf("if (confirm(%s)) Shiny.setInputValue('plans_forget_all', Date.now(), {priority: 'event'}); return false;",
          js_string(paste0("Remove every study plan from this browser?",
            if (length(unsaved)) sprintf(" %d %s not been saved to a file and will be gone.", length(unsaved),
              if (length(unsaved) == 1) "plan has" else "plans have") else ""))),
        "Remove every plan from this browser"),
      " (for a shared computer).")
  )
}
