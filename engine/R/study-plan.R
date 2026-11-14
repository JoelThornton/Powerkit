#' Save several power analyses as one study plan file
#'
#' A study often has more than one analysis, each powered on its own card
#' (for example a multilevel model and a mediation in the same study). A
#' study plan keeps them together in one JSON file: each analysis is a
#' project as [write_project()] writes it, so each can be reopened and
#' reproduced on its own.
#'
#' @param analyses A list of analyses, each a list with `spec`, and
#'   optionally `result` and `route`, as for [write_project()]. An analysis
#'   may also carry `plan_role` (`"primary"`, `"secondary"` or `"check"`)
#'   and `plan_note` (free text), kept with it in the file.
#' @param file Path to write to. If `NULL`, the JSON text is returned.
#' @param id,name,description Optional single strings: the plan's
#'   identifier, its name and a description of the study. Fields left
#'   `NULL` are not written, and older versions of powerkit ignore them.
#' @param guided Optional list: the app's record of a guided whole-study
#'   plan ("Plan my whole study") that the study plan holds. It is kept as
#'   given; `NULL` is not written.
#' @param replication Optional list: the app's record of a replication plan
#'   (the pre-replication notes, the original study, the goals and how the
#'   replication differs) that the study plan holds. Kept as given; `NULL`
#'   is not written.
#'
#' @return The JSON text, invisibly when written to `file`.
#' @seealso [read_study_plan()], [write_project()]
#' @export
#' @examples
#' spec <- read_spec(system.file("specs", "independent_t.json", package = "powerkit"))
#' spec$target_test$method <- "student_t"
#' path <- tempfile(fileext = ".powerkit.json")
#' write_study_plan(list(list(spec = spec, result = run_spec(spec))), file = path)
#' plan <- read_study_plan(path)
#' unlink(path)
write_study_plan <- function(analyses, file = NULL, id = NULL, name = NULL, description = NULL, guided = NULL, replication = NULL) {
  if (!is.null(guided) && !is.list(guided)) {
    abort_project("A study plan's guided plan should be a list (the app's guided-plan record).")
  }
  if (!is.null(replication) && !is.list(replication)) {
    abort_project("A study plan's replication plan should be a list (the app's replication-plan record).")
  }
  if (!is.list(analyses) || length(analyses) == 0) {
    abort_project("A study plan needs at least one analysis.")
  }
  entries <- lapply(analyses, function(a) {
    if (!is.list(a) || is.null(a$spec)) {
      abort_project("Each analysis in a study plan should be a list with a 'spec'.")
    }
    # Preserve an opened project's original result and provenance, including
    # older projects which have a numerical record but no typed screen.
    if (inherits(a, "powerkit_project")) {
      spec <- validate_spec(a$spec)
      hash <- spec_hash(spec)
      if (!is.null(a$result) && !identical(a$result$provenance$spec_hash, hash)) {
        abort_project("A saved analysis's inputs no longer match its result. Calculate it again before saving the plan.")
      }
      entry <- list(format = project_format(), format_version = project_format_version(),
        saved = a$saved, powerkit_version = a$powerkit_version, r_version = a$r_version,
        spec = unclass(spec), spec_hash = hash, route = a$route,
        result = a$result, screen = a$screen)
    } else {
      entry <- jsonlite::parse_json(write_project(a$spec, a$result, a$route %||% list()), simplifyVector = FALSE)
    }
    # Assigning NULL leaves an absent field out of the file.
    entry$plan_role <- plan_text_field(a$plan_role)
    entry$plan_note <- plan_text_field(a$plan_note)
    entry
  })
  plan <- list(
    format = study_plan_format(),
    format_version = project_format_version(),
    saved = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    powerkit_version = as.character(utils::packageVersion("powerkit")),
    id = plan_text_field(id),
    name = plan_text_field(name),
    description = plan_text_field(description),
    analyses = entries,
    guided = guided,
    replication = replication
  )
  # Optional fields: written only when given.
  for (field in c("id", "name", "description", "guided", "replication")) if (is.null(plan[[field]])) plan[[field]] <- NULL
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
#'   `powerkit_project`s), `saved`, `powerkit_version`, `id`, `name` and
#'   `description` (each `NULL` when the file has none), `guided` (the
#'   guided-plan record, or `NULL`), `replication` (the replication-plan
#'   record, or `NULL`), and `roles` and `notes`, character
#'   vectors with one element per analysis (`NA` where the file has none).
#' @seealso [write_study_plan()], [read_project()]
#' @export
#' @examples
#' spec <- read_spec(system.file("specs", "independent_t.json", package = "powerkit"))
#' spec$target_test$method <- "student_t"
#' plan <- read_study_plan(write_study_plan(list(list(spec = spec, result = run_spec(spec)))))
#' length(plan$analyses)
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
  per_analysis <- function(field) {
    vapply(raw$analyses, function(a) plan_text_field(a[[field]]) %||% NA_character_, character(1))
  }
  structure(
    list(analyses = analyses, saved = raw$saved, powerkit_version = raw$powerkit_version,
      id = plan_text_field(raw$id), name = plan_text_field(raw$name),
      description = plan_text_field(raw$description),
      guided = if (is.list(raw$guided)) raw$guided,
      replication = if (is.list(raw$replication)) raw$replication,
      roles = per_analysis("plan_role"), notes = per_analysis("plan_note")),
    class = "powerkit_study_plan"
  )
}

study_plan_format <- function() "powerkit-study-plan"

# A plan's optional text field: one string, or NULL (not written).
plan_text_field <- function(x) {
  if (is.list(x) && length(x) == 1L) x <- x[[1]]
  if (is.character(x) && length(x) == 1L && !is.na(x)) x else NULL
}
