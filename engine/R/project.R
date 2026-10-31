#' Save a power analysis as a project file
#'
#' Writes one JSON file holding everything needed to reopen a power
#' analysis and reproduce it: the design spec (with its seed), how the user
#' got there in the app (`route`), the result if one was calculated, and
#' the versions of powerkit, R and the backend package that produced it.
#' The file stays with the user; nothing is stored anywhere else.
#'
#' @param spec The design spec ([read_spec()] or a named list).
#' @param result Optional: the result of [run_spec()] for `spec`.
#' @param route Optional: a named list of how the analysis was reached in
#'   the app (for example the route, the answers given and the end point),
#'   stored as given. Values must be strings, numbers, logicals or lists of
#'   them.
#' @param file Path to write to. If `NULL`, the JSON text is returned.
#'
#' @return The JSON text, invisibly when written to `file`.
#' @seealso [read_project()], [reproduce_project()]
#' @export
#' @examples
#' \dontrun{
#' spec <- read_spec(system.file("specs", "independent_t.json", package = "powerkit"))
#' result <- run_spec(spec)
#' path <- tempfile(fileext = ".powerkit.json")
#' write_project(spec, result, file = path)
#' project <- read_project(path)
#' reproduce_project(project)$same
#' }
write_project <- function(spec, result = NULL, route = list(), file = NULL) {
  spec <- withCallingHandlers(
    validate_spec(spec),
    powerkit_spec_warning = function(w) invokeRestart("muffleWarning")
  )
  if (!is.null(result)) {
    if (!inherits(result, "powerkit_result")) {
      abort_project("'result' should be the result of run_spec() (a powerkit result).")
    }
    if (!identical(spec_hash(spec), result$provenance$spec_hash)) {
      abort_project(
        "This result wasn't produced from this spec (their spec hashes differ). Save the spec and the result from the same run."
      )
    }
    # The seed the run used belongs to the spec, so reopening it gives the
    # same simulated data sets.
    if (is.null(spec$options$seed) && !is.null(result$provenance$seed)) {
      abort_project(
        "The spec has no seed, so the saved project couldn't reproduce this result. Run the spec with 'options > seed' set, then save it."
      )
    }
  }
  if (!is.list(route)) {
    abort_project("'route' should be a named list.")
  }
  project <- list(
    format = project_format(),
    format_version = project_format_version(),
    saved = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    powerkit_version = as.character(utils::packageVersion("powerkit")),
    r_version = R.version.string,
    route = route,
    spec = unclass(spec),
    spec_hash = spec_hash(spec),
    result = if (!is.null(result)) result_record(result)
  )
  text <- as.character(jsonlite::toJSON(
    project,
    auto_unbox = TRUE, digits = NA, null = "null", na = "null",
    dataframe = "columns", pretty = TRUE
  ))
  if (is.null(file)) {
    return(text)
  }
  write_utf8(paste0(text, "\n"), file)
  invisible(text)
}

#' Open a saved project file
#'
#' Reads a file written by [write_project()] (or the app's "Save project"
#' button), checks its spec, and reports in plain English anything that
#' differs from now, such as another powerkit version.
#'
#' @param x Path to a project file, or its JSON text.
#'
#' @return A `powerkit_project`: a list with `spec` (a checked
#'   `powerkit_spec`), `route`, `result` (the saved result's numbers and
#'   provenance, or `NULL`), `saved`, `powerkit_version`, `r_version` and
#'   `notes` (differences from the current setup; empty if none).
#' @seealso [write_project()], [reproduce_project()]
#' @export
read_project <- function(x) {
  text <- if (length(x) == 1 && file.exists(x)) {
    paste(readLines(x, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  } else {
    paste(x, collapse = "\n")
  }
  raw <- tryCatch(
    jsonlite::parse_json(text, simplifyVector = FALSE),
    error = function(e) abort_project("This file isn't a powerkit project: it isn't valid JSON.")
  )
  if (!is.list(raw) || !identical(raw$format, project_format())) {
    abort_project("This file isn't a powerkit project (it has no \"format\": \"powerkit-project\").")
  }
  if (!is.numeric(raw$format_version) || raw$format_version > project_format_version()) {
    abort_project(sprintf(
      "This project was saved by a newer version of powerkit (project format %s). Update powerkit to open it.",
      format(raw$format_version)
    ))
  }
  spec <- withCallingHandlers(
    validate_spec(raw$spec),
    powerkit_spec_warning = function(w) invokeRestart("muffleWarning")
  )
  notes <- character()
  if (!identical(spec_hash(spec), raw$spec_hash)) {
    notes <- c(notes, "The spec in this file was changed after it was saved (its hash differs from the one recorded).")
  }
  current <- as.character(utils::packageVersion("powerkit"))
  if (!identical(raw$powerkit_version, current)) {
    notes <- c(notes, sprintf(
      "Saved with powerkit %s; this is powerkit %s. Results may differ slightly.",
      raw$powerkit_version, current
    ))
  }
  result <- raw$result
  if (!is.null(result)) {
    saved <- unlist(result$provenance$packages)
    for (pkg in setdiff(names(saved), "powerkit")) {
      now <- tryCatch(as.character(utils::packageVersion(pkg)), error = function(e) "not installed")
      if (!identical(now, saved[[pkg]])) {
        notes <- c(notes, sprintf(
          "Saved with %s %s; here it is %s. Results may differ slightly.", pkg, saved[[pkg]], now
        ))
      }
    }
  }
  structure(
    list(
      spec = spec,
      route = raw$route %||% list(),
      result = result,
      saved = raw$saved,
      powerkit_version = raw$powerkit_version,
      r_version = raw$r_version,
      notes = notes
    ),
    class = "powerkit_project"
  )
}

#' Run a saved project again and compare with its saved result
#'
#' Runs the project's spec with [run_spec()] (same seed) and compares the
#' numbers with those saved in the file. A simulation that isn't run in
#' batches draws its replications in one stream per core, so it is run on
#' the number of cores the file records, whatever `powerkit.cores` says.
#'
#' @param project A project from [read_project()].
#' @param tolerance Largest relative difference counted as the same.
#'
#' @return A list: `result` (the new [run_spec()] result), `same` (`TRUE`
#'   if every saved number is reproduced, `NA` if the file has no result)
#'   and `differences` (plain-English lines, empty when the same).
#' @export
reproduce_project <- function(project, tolerance = 1e-10) {
  if (!inherits(project, "powerkit_project")) {
    abort_project("'project' should come from read_project().")
  }
  cores <- saved_cores(project$result)
  if (!is.na(cores)) {
    old <- options(powerkit.cores = cores)
    on.exit(options(old), add = TRUE)
  }
  result <- run_spec(project$spec)
  if (is.null(project$result)) {
    return(list(result = result, same = NA, differences = character()))
  }
  now <- jsonlite::parse_json(
    jsonlite::toJSON(result_numbers(result_record(result)), auto_unbox = TRUE, digits = NA, null = "null", na = "null", dataframe = "columns"),
    simplifyVector = FALSE
  )
  saved <- result_numbers(project$result)
  differences <- character()
  for (name in names(saved)) {
    a <- unlist(saved[[name]])
    b <- unlist(now[[name]])
    if (!isTRUE(all.equal(a, b, tolerance = tolerance, check.attributes = FALSE))) {
      differences <- c(differences, sprintf("%s differs from the saved result.", name))
    }
  }
  if (length(differences) > 0 && is.na(cores) && identical(project$result$provenance$method, "simulation")) {
    differences <- c(differences, paste(
      "This file doesn't record how many cores the simulation ran on (powerkit before 0.24.1 didn't save it);",
      "a simulated result is reproduced only on the same number. Try options(powerkit.cores = 1), the app's setting."
    ))
  }
  list(result = result, same = length(differences) == 0, differences = differences)
}

#' @export
print.powerkit_project <- function(x, ...) {
  cat("<powerkit project>\n")
  cat(sprintf("Saved: %s (powerkit %s)\n", x$saved, x$powerkit_version))
  cat(sprintf("Design: %s / %s\n", x$spec$design, x$spec$template))
  if (!is.null(x$result)) {
    cat(sprintf("Saved result: %s, by %s\n", x$result$goal_type, x$result$provenance$backend))
  }
  for (note in x$notes) cat("Note: ", note, "\n", sep = "")
  invisible(x)
}

project_format <- function() "powerkit-project"
project_format_version <- function() 1L

abort_project <- function(message) {
  abort_run(message, class = "powerkit_project_error")
}

# The parts of a result saved in a project: its numbers and provenance.
# The check run is kept as its pass or fail, not its table.
result_record <- function(result) {
  list(
    goal_type = result$goal_type,
    curve = result$curve,
    n_required = result$n_required,
    sensitivity = result$sensitivity,
    recruitment = result$recruitment,
    check_run_passed = all(result$check_run$ok),
    provenance = c(
      result$provenance[c(
        "spec_hash", "method", "seed", "nrep", "cores", "backend", "backend_function",
        "r_version", "started"
      )],
      # A named list, so the JSON keeps the package names.
      list(packages = as.list(result$provenance$packages))
    )
  )
}

# The number of cores a saved simulation ran on, or NA (an exact result,
# or a file saved before powerkit recorded it).
saved_cores <- function(record) {
  cores <- suppressWarnings(as.integer(record$provenance$cores %||% NA_integer_))
  if (length(cores) != 1 || is.na(cores) || cores < 1) NA_integer_ else cores
}

# The numbers a reproduction must match.
result_numbers <- function(record) {
  record[c("curve", "n_required", "sensitivity", "recruitment")]
}
