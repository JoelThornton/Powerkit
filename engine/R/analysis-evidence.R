# The registry records observed case checks, not a universal validation flag.
# A missing entry stays unknown; a passing unit suite does not turn a skipped
# method-validation test or an untranscribed benchmark into a pass.
evidence_registry <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) {
      path <- system.file("evidence", "records.json", package = "powerkit", mustWork = TRUE)
      cache <<- jsonlite::read_json(path, simplifyVector = FALSE)
      cache$sha256 <<- digest::digest(file = path, algo = "sha256")
    }
    cache
  }
})

evidence_value <- function(x, path) {
  for (key in strsplit(path, ".", fixed = TRUE)[[1]]) {
    if (!is.list(x) || is.null(x[[key]])) return(NULL)
    x <- x[[key]]
  }
  x
}

evidence_match <- function(spec, rules) {
  all(vapply(names(rules), function(path) {
    value <- evidence_value(spec, path)
    rule <- rules[[path]]
    if (is.list(rule)) {
      if (!is.null(rule$absent)) return(identical(is.null(value), rule$absent))
      if (!is.null(rule$one_of)) return(length(value) == 1 && value %in% unlist(rule$one_of))
      if (!is.null(rule$not)) return(!isTRUE(all.equal(value, rule$not, check.attributes = FALSE)))
    }
    isTRUE(all.equal(value, rule, check.attributes = FALSE))
  }, logical(1)))
}

evidence_metadata <- function(spec) {
  defaults <- c(one_sample_t = "t_test", independent_t = "student_t", paired_t = "t_test", correlation = "pearson")
  if (is.null(spec$target_test)) spec$target_test <- list()
  if (is.null(spec$target_test$method) && spec$template %in% names(defaults))
    spec$target_test$method <- unname(defaults[[spec$template]])
  spec$target_test$alternative <- spec$target_test$alternative %||% "two_sided"
  numeric_named <- function(x, pattern) {
    if (!is.list(x)) return(numeric())
    unlist(lapply(names(x), function(key) {
      if (grepl(pattern, key, ignore.case = TRUE) && is.numeric(x[[key]])) x[[key]] else numeric_named(x[[key]], pattern)
    }), use.names = FALSE)
  }
  reliabilities <- numeric_named(spec, "reliab")
  correlations <- unlist(spec$population$correlations, use.names = FALSE)
  spec$features <- list(
    mediators = sum(grepl("^M[0-9]*$", names(spec$variables))),
    score_shape = spec$population$score_shape %||% "normal",
    sd_ratio = spec$population$sd_ratio %||% 1,
    allocation_ratio = spec$options$allocation_ratio %||% 1,
    measurement_error = any(reliabilities < 1),
    specified_correlations = if (length(correlations) && any(correlations != 0)) "nonzero" else "none")
  spec
}

#' Recorded evidence for an analysis variant
#'
#' Returns a versioned snapshot separating software agreement, independent
#' reference checks, published examples and method-validation runs. Records
#' describe the cases and revisions actually checked. They are not a claim
#' that every population, parameter or option has been validated. Unmatched
#' choices explicitly have no linked record; this does not mean that a test
#' failed or that no other evidence exists.
#'
#' @param spec A specification, or partial design/test metadata for discovery.
#'   This lookup does not run or validate a power calculation.
#' @param computation_method Optional resolved calculation mode, such as
#'   `"exact"` or `"simulation"`, when known. It is recorded, not executed.
#' @return A list with registry version/hash, a variant identifier, a matched
#'   record (if present), four category records, sources and coverage limits.
#' @export
analysis_evidence <- function(spec, computation_method = NULL) {
  if (!is.list(spec) || length(spec$design) != 1 || length(spec$template) != 1)
    abort_spec("Evidence lookup needs a design and template.")
  registry <- evidence_registry()
  query <- evidence_metadata(spec)
  query$features$computation_method <- computation_method %||% spec$options$method %||% "unspecified"
  hits <- Filter(function(x) evidence_match(query, x$match), registry$records)
  if (length(hits)) hits <- hits[order(vapply(hits, function(x) length(x$match), integer(1)), decreasing = TRUE)]
  record <- if (length(hits)) hits[[1]] else NULL
  kinds <- c("package_agreement", "independent", "published", "full_validation")
  categories <- stats::setNames(lapply(kinds, function(kind) {
    item <- record$categories[[kind]]
    if (!is.null(item$when) && !evidence_match(query, item$when)) {
      item$status <- "outside_scope"
      item$note <- paste("The linked case used different settings.", item$note)
    }
    item %||% list(status = "not_linked", note = "No variant-specific case record is linked in this registry.", sources = list())
  }), kinds)
  source_ids <- unique(unlist(lapply(categories, `[[`, "sources"), use.names = FALSE))
  list(format_version = 1L, registry_version = registry$version,
    registry_sha256 = registry$sha256,
    variant = paste(spec$design, spec$template, query$target_test$method %||% "unspecified",
      spec$target_test$effect %||% "unspecified", query$target_test$alternative,
      query$features$computation_method, sep = "/"),
    record_id = record$id %||% "unlinked", categories = categories,
    scope = record$scope %||% "Complete inputs may narrow the variant. No linked record is not a failed check.",
    limits = registry$limits, sources = if (length(source_ids)) registry$sources[source_ids] else list())
}

evidence_record_text <- function(record) {
  if (!is.list(record) || !isTRUE(record$format_version == 1)) return("No supported variant-level evidence snapshot was captured with this result.")
  labels <- c(package_agreement = "Software agreement", independent = "Independent reference",
    published = "Published example", full_validation = "Method-validation run")
  states <- c(recorded = "recorded cases", scoped_only = "scoped checks only",
    pending = "benchmark pending transcription", not_linked = "no linked record",
    outside_scope = "outside the recorded case settings")
  lines <- vapply(names(labels), function(kind) {
    item <- record$categories[[kind]]
    state <- unname(states[item$status %||% "not_linked"])
    if (length(state) != 1 || is.na(state)) state <- "status not recognised by this version"
    sprintf("%s: %s. %s", labels[[kind]], state, item$note %||% "")
  }, character(1))
  c(sprintf("Variant evidence record: %s; registry %s (%s).", record$record_id, record$registry_version, record$registry_sha256),
    lines, paste("Coverage:", record$scope), record$limits)
}
