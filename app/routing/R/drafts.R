# Drafts store editable answers, never a calculation or evidence record.
# They are deliberately separate from engine project/plan files.
write_draft <- function(route, file) {
  route$form_values <- lapply(route$form_values, function(x) {
    if (is.null(x) || !length(x) || anyNA(x)) "" else as.character(x)
  })
  record <- list(format = "powerkit-draft", version = 1L,
    saved_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC", tz = "UTC"), route = route)
  jsonlite::write_json(record, file, auto_unbox = TRUE, pretty = TRUE, null = "null")
  invisible(record)
}

read_draft_record <- function(path) {
  if (!file.exists(path) || file.info(path)$size > 5e6) return(NULL)
  record <- tryCatch(jsonlite::read_json(path, simplifyVector = FALSE), error = function(e) NULL)
  if (!is.list(record) || !identical(record$format, "powerkit-draft")) NULL else record
}

restore_draft <- function(record, tree, forms) {
  bad <- "This draft cannot be reopened by this version of Powerkit."
  if (!is.list(record) || !identical(record$format, "powerkit-draft") || !identical(as.character(record$version), "1")) return(bad)
  route <- record$route
  if (!is.list(route) || !is.list(route$form_values) || (length(route$form_values) && is.null(names(route$form_values))) ||
      !is.list(route$start %||% list()) || !is.list(route$ctx %||% list()) || !is.list(route$history %||% list())) return(bad)
  k <- suppressWarnings(as.numeric(route$form_k %||% 2L))
  if (length(k) != 1 || !is.finite(k) || k < 1 || k > 100 || k != floor(k)) return(bad)
  route$form_k <- as.integer(k)
  values <- route$form_values
  for (id in names(values)) {
    x <- values[[id]]
    if (is.list(x)) {
      if (any(vapply(x, is.list, logical(1)))) return(bad)
      x <- unlist(x, use.names = FALSE)
    }
    if (length(x) > 10000 || !is.atomic(x)) return(bad)
    values[id] <- list(if (is.null(x) || !length(x) || anyNA(x)) "" else as.character(x))
  }
  route$form_values <- values
  restored <- tryCatch(restore_from_project(route, tree, forms), error = function(e) bad)
  if (is.character(restored)) return(restored)
  fields <- tryCatch(form_fields(form_groups(forms, restored$endpoint, restored$form_k, restored$start)), error = function(e) NULL)
  if (is.null(fields) || !all(names(values) %in% vapply(fields, `[[`, "", "id"))) return(bad)
  # Validate history structure before it can drive a Back action.
  if (length(restored$history) > 500 || any(!vapply(restored$history, function(h) {
    is.list(h) && is.character(h$node) && length(h$node) == 1 && h$node %in% names(tree$nodes) &&
      is.character(h$answer) && length(h$answer) == 1 && is.list(h$ctx %||% list())
  }, logical(1)))) return(bad)
  restored$calc <- NULL
  restored$long_spec <- NULL
  restored
}

draft_opened_ui <- function(saved_at) {
  div(class = "alert alert-info", role = "status",
    tags$strong("Unfinished draft opened. "),
    "Your editable answers were restored, including blanks. No calculated or validated result was restored. Complete or change the answers, then check them before calculating.",
    if (is.character(saved_at) && length(saved_at) == 1) p(class = "mb-0", paste("Draft saved:", saved_at)))
}
