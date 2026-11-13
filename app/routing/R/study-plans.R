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
  existing <- plans[[incoming$id]]
  if (is.null(existing)) {
    plans[[incoming$id]] <- incoming
    return(list(plans = plans, id = incoming$id, message = NULL))
  }
  if (identical(plan_content(existing), plan_content(incoming))) {
    return(list(plans = plans, id = existing$id, message = NULL))
  }
  incoming$id <- plan_new_id()
  incoming$name <- substr(sprintf("%s (opened %s)", incoming$name, plan_date_words(as.Date(now))), 1L, plan_name_max)
  plans[[incoming$id]] <- incoming
  list(plans = plans, id = incoming$id,
    message = sprintf("You already had a different version of this plan, so both are kept: the one you opened is “%s”.", incoming$name))
}
