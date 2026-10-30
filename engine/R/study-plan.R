#' Save several power analyses as one study plan file
#'
#' A study often has more than one analysis, each powered on its own card
#' (for example a multilevel model and a mediation in the same study). A
#' study plan keeps them together in one JSON file: each analysis is a
#' project as [write_project()] writes it, so each can be reopened and
#' reproduced on its own.
#'
#' @param analyses A list of analyses, each a list with `spec`, and
#'   optionally `result` and `route`, as for [write_project()].
#' @param file Path to write to. If `NULL`, the JSON text is returned.
#'
#' @return The JSON text, invisibly when written to `file`.
#' @seealso [read_study_plan()], [write_project()]
#' @export
#' @examples
#' \dontrun{
#' spec <- read_spec(system.file("specs", "independent_t.json", package = "powerkit"))
#' path <- tempfile(fileext = ".powerkit.json")
#' write_study_plan(list(list(spec = spec, result = run_spec(spec))), file = path)
#' plan <- read_study_plan(path)
#' }
write_study_plan <- function(analyses, file = NULL) {
  if (!is.list(analyses) || length(analyses) == 0) {
    abort_project("A study plan needs at least one analysis.")
  }
  entries <- lapply(analyses, function(a) {
    if (!is.list(a) || is.null(a$spec)) {
      abort_project("Each analysis in a study plan should be a list with a 'spec'.")
    }
    jsonlite::parse_json(write_project(a$spec, a$result, a$route %||% list()), simplifyVector = FALSE)
  })
  plan <- list(
    format = study_plan_format(),
    format_version = project_format_version(),
    saved = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    powerkit_version = as.character(utils::packageVersion("powerkit")),
    analyses = entries
  )
  text <- as.character(jsonlite::toJSON(
    plan,
    auto_unbox = TRUE, digits = NA, null = "null", na = "null", pretty = TRUE
  ))
  if (is.null(file)) {
    return(text)
  }
  write_utf8(paste0(text, "\n"), file)
  invisible(text)
}

#' Open a saved study plan file
#'
#' Reads a file written by [write_study_plan()] (or the app's "Save study
#' plan" button). Each analysis is checked as [read_project()] checks a
#' project.
#'
#' @param x Path to a study plan file, or its JSON text.
#'
#' @return A `powerkit_study_plan`: a list with `analyses` (a list of
#'   `powerkit_project`s), `saved` and `powerkit_version`.
#' @seealso [write_study_plan()], [read_project()]
#' @export
read_study_plan <- function(x) {
  text <- if (length(x) == 1 && file.exists(x)) {
    paste(readLines(x, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  } else {
    paste(x, collapse = "\n")
  }
  raw <- tryCatch(
    jsonlite::parse_json(text, simplifyVector = FALSE),
    error = function(e) abort_project("This file isn't a powerkit study plan: it isn't valid JSON.")
  )
  if (!is.list(raw) || !identical(raw$format, study_plan_format())) {
    abort_project("This file isn't a powerkit study plan (it has no \"format\": \"powerkit-study-plan\").")
  }
  if (!is.numeric(raw$format_version) || raw$format_version > project_format_version()) {
    abort_project(sprintf(
      "This study plan was saved by a newer version of powerkit (format %s). Update powerkit to open it.",
      format(raw$format_version)
    ))
  }
  analyses <- lapply(raw$analyses, function(a) {
    read_project(jsonlite::toJSON(a, auto_unbox = TRUE, digits = NA, null = "null", na = "null"))
  })
  structure(
    list(analyses = analyses, saved = raw$saved, powerkit_version = raw$powerkit_version),
    class = "powerkit_study_plan"
  )
}

study_plan_format <- function() "powerkit-study-plan"
