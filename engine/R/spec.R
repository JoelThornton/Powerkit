#' Read a design specification
#'
#' Reads a powerkit design specification from a JSON file or a JSON string
#' and (by default) checks it with [validate_spec()].
#'
#' @param x Path to a `.json` file, or a string containing JSON.
#' @param validate If `TRUE` (the default), check the specification and stop
#'   with a plain-English message if it has problems.
#'
#' @return A `powerkit_spec` object: a named list mirroring the JSON.
#' @seealso [validate_spec()], [spec_hash()]
#' @export
#' @examples
#' path <- system.file("specs", "process_7.json", package = "powerkit")
#' spec <- read_spec(path)
#' spec
read_spec <- function(x, validate = TRUE) {
  json <- spec_json_text(x)
  spec <- parse_spec_json(json)
  if (isTRUE(validate)) {
    return(validate_spec(spec))
  }
  new_spec(spec)
}

#' Check a design specification
#'
#' Checks a specification in two stages. First its structure is checked
#' against the JSON schema in `inst/schema/design.schema.json`. Then the
#' implied population is checked for possibility: for example, that path
#' values do not explain more than 100% of a variable's variance, that a
#' correlation matrix is positive definite, and that cell probabilities add
#' up to 1. All problems found are reported together in plain English.
#'
#' Advice that does not make the spec invalid (for example, a warning about
#' effect sizes taken from pilot studies) is given as a warning of class
#' `powerkit_spec_warning`.
#'
#' @param spec A specification as a named list (e.g. from [read_spec()] with
#'   `validate = FALSE`), or a JSON string or file path.
#'
#' @return The specification, normalised to the form [read_spec()] returns,
#'   with class `powerkit_spec`. Called for its error if the spec is invalid:
#'   the error has class `powerkit_spec_error` and a `problems` field holding
#'   one message per problem.
#' @export
#' @examples
#' spec <- read_spec(
#'   system.file("specs", "independent_t.json", package = "powerkit"),
#'   validate = FALSE
#' )
#' spec$goal$power <- 1.5
#' try(validate_spec(spec))
validate_spec <- function(spec) {
  if (is.character(spec)) {
    spec <- parse_spec_json(spec_json_text(spec))
  }
  spec <- unclass(spec)
  if (!is_json_object(spec)) {
    abort_spec("The spec must be a set of named fields ({ ... }), not a list or a single value.")
  }

  problems <- check_duplicate_names(spec)
  if (length(problems) == 0) {
    problems <- check_spec_version(spec)
  }
  if (length(problems) == 0) {
    spec <- normalise_spec(spec)
    problems <- schema_problems(spec)
  }
  if (length(problems) == 0) {
    spec <- standardise_raw_effect(spec)
  }
  if (length(problems) == 0) {
    # After the effect in the outcome's own units is standardised, so the
    # safeguard starts from that standardised estimate.
    safeguard <- apply_safeguard(spec)
    spec <- safeguard$spec
    problems <- safeguard$problems
  }
  if (length(problems) == 0) {
    problems <- population_problems(spec)
  }
  if (length(problems) > 0) {
    abort_spec(problems)
  }

  for (advice in spec_advice(spec)) {
    warn_spec(advice)
  }
  new_spec(spec)
}

#' Hash a design specification
#'
#' Returns a SHA-256 hash of the specification's content. Field order and
#' whitespace do not affect the hash, so the same design always gets the
#' same hash. Every result records this hash.
#'
#' @param spec A specification (named list or `powerkit_spec`).
#' @return A 64-character hexadecimal string.
#' @export
#' @examples
#' spec <- read_spec(system.file("specs", "process_7.json", package = "powerkit"))
#' spec_hash(spec)
spec_hash <- function(spec) {
  json <- spec_to_json(sort_names(unclass(spec)))
  digest::digest(json, algo = "sha256", serialize = FALSE)
}

#' @export
print.powerkit_spec <- function(x, ...) {
  vars <- vapply(
    names(x$variables),
    function(role) paste0(role, " = ", x$variables[[role]]$label),
    character(1)
  )
  target <- x$target_test$effect
  if (!is.null(x$target_test$path)) {
    target <- paste0(target, " (", x$target_test$path, ")")
  }
  goal <- switch(
    x$goal$type,
    sample_size = sprintf("smallest n for power %s", x$goal$power),
    power = sprintf("power at n = %s", x$goal$n),
    sensitivity = sprintf("smallest detectable effect at n = %s with power %s", x$goal$n, x$goal$power)
  )
  cat(
    sprintf("<powerkit spec %s>\n", x$spec_version),
    sprintf("Design:    %s / %s\n", x$design, x$template),
    sprintf("Variables: %s\n", paste(vars, collapse = "; ")),
    sprintf("Target:    %s, %s, alpha = %s\n", target, x$target_test$method, x$target_test$alpha),
    effect_definition(x),
    sprintf("Goal:      %s\n", goal),
    sep = ""
  )
  invisible(x)
}

# A line stating how the effect size is defined, where its direction is a
# convention the user needs to see (paired designs: d_z is the second
# condition minus the first).
effect_definition <- function(spec) {
  if (!identical(spec$template, "paired_t")) {
    return("")
  }
  levels <- unlist(spec$variables$X$levels) %||% c("first condition", "second condition")
  sprintf(
    "Effect:    d_z = mean of (%s minus %s) / SD of those differences\n",
    levels[2], levels[1]
  )
}

# The t-tests accept the effect in the outcome's own units (population >
# metric "raw"). The standardised effect the backends take is worked out
# here, by its definition in the schema, and replaces any value already
# there, so a spec read back from a result gives the same effect:
#   one sample:   d   = (mean - test value) / SD
#   two groups:   d   = (mean 2 - mean 1) / SD (one SD within each group)
#   paired:       d_z = (mean 2 - mean 1) / SD of the differences, where
#                 the SD of the differences, from one SD and the
#                 correlation r between the two measurements, is
#                 SD * sqrt(2 * (1 - r)).
standardise_raw_effect <- function(spec) {
  pop <- spec$population
  if (!spec$design %in% c("basic_test", "equivalence_test") || !identical(pop$metric, "raw")) {
    return(spec)
  }
  raw <- pop$raw
  paired_sd <- function() raw$sd_difference %||% (raw$sd * sqrt(2 * (1 - raw$r)))
  switch(
    spec$template,
    one_sample_t = ,
    tost_one_sample = spec$population$d <- (raw$mean - raw$test_value) / raw$sd,
    independent_t = ,
    tost_independent = spec$population$d <- (raw$mean_2 - raw$mean_1) / raw$sd,
    paired_t = ,
    tost_paired = spec$population$dz <- (raw$mean_2 - raw$mean_1) / paired_sd()
  )
  # Equivalence tests: the bound, in the same SD units as the effect.
  if (identical(spec$design, "equivalence_test")) {
    sd <- if (identical(spec$template, "tost_paired")) paired_sd() else raw$sd
    spec$population$bound <- raw$bound / sd
  }
  spec
}

# The standardised effect worked out from the outcome's own units, for the
# result: list(name, value, difference, sd), or NULL when the spec gave
# the standardised effect itself.
effect_from_units <- function(spec) {
  pop <- spec$population
  if (!spec$design %in% c("basic_test", "equivalence_test") || !identical(pop$metric, "raw")) {
    return(NULL)
  }
  raw <- pop$raw
  paired <- spec$template %in% c("paired_t", "tost_paired")
  list(
    name = if (paired) "d_z" else "Cohen's d",
    value = if (paired) pop$dz else pop$d,
    difference = if (spec$template %in% c("one_sample_t", "tost_one_sample")) raw$mean - raw$test_value else raw$mean_2 - raw$mean_1,
    sd = if (paired) raw$sd_difference %||% (raw$sd * sqrt(2 * (1 - raw$r))) else raw$sd,
    sd_name = if (paired) "the SD of the differences" else "the SD",
    # Equivalence tests: the bound in the outcome's units and in SD units.
    bound = raw$bound,
    bound_value = pop$bound
  )
}

# Supported spec versions. Add to this (and keep old schemas) when the format
# changes, so that old saved specs keep running.
supported_spec_versions <- function() "0.1"

spec_schema_path <- function() {
  system.file("schema", "design.schema.json", package = "powerkit", mustWork = TRUE)
}

# The compiled validator is cached for the session.
spec_cache <- new.env(parent = emptyenv())

spec_validator <- function() {
  if (is.null(spec_cache$validator)) {
    spec_cache$validator <- jsonvalidate::json_validator(spec_schema_path(), engine = "ajv")
  }
  spec_cache$validator
}

new_spec <- function(spec) {
  structure(spec, class = "powerkit_spec")
}

spec_json_text <- function(x) {
  if (!is.character(x) || length(x) != 1 || is.na(x)) {
    abort_spec("read_spec() needs the path to a .json file, or a JSON string.")
  }
  if (grepl("^\\s*[{[]", x)) {
    return(x)
  }
  if (!file.exists(x)) {
    abort_spec(sprintf("Couldn't find the spec file '%s'. Check the file name and folder.", x))
  }
  text <- paste(readLines(x, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  if (!nzchar(trimws(text))) {
    abort_spec(sprintf("The spec file '%s' is empty.", x))
  }
  text
}

parse_spec_json <- function(json) {
  spec <- tryCatch(
    jsonlite::parse_json(json, simplifyVector = FALSE),
    error = function(e) {
      detail <- trimws(gsub("\\s+", " ", conditionMessage(e)))
      abort_spec(paste0(
        "The spec isn't valid JSON, so it can't be read. Common causes are a ",
        "missing or extra comma, a missing closing bracket, or single quotes ",
        "where JSON needs double quotes. The JSON reader said: ", detail
      ))
    }
  )
  if (!is_json_object(spec)) {
    abort_spec("The spec must be a set of named fields ({ ... }), not a list or a single value.")
  }
  spec
}

# Round-trip through JSON so that specs built in R (vectors, matrices) and
# specs read from files have the same representation.
normalise_spec <- function(spec) {
  jsonlite::parse_json(spec_to_json(spec), simplifyVector = FALSE)
}

spec_to_json <- function(spec) {
  as.character(jsonlite::toJSON(
    spec,
    auto_unbox = TRUE,
    digits = NA,
    null = "null",
    na = "null"
  ))
}

sort_names <- function(x) {
  if (!is.list(x)) {
    return(x)
  }
  if (!is.null(names(x))) {
    x <- x[order(names(x))]
  }
  lapply(x, sort_names)
}

is_json_object <- function(x) {
  is.list(x) && length(x) > 0 && !is.null(names(x)) && all(nzchar(names(x)))
}

check_spec_version <- function(spec) {
  version <- spec$spec_version
  if (is.null(version)) {
    return(paste0(
      "The spec is missing 'spec_version'. Add \"spec_version\": \"",
      supported_spec_versions()[1], "\" at the top."
    ))
  }
  if (!is.character(version) || length(version) != 1 ||
    !version %in% supported_spec_versions()) {
    return(sprintf(
      "This spec says it uses format version %s, but this version of powerkit reads version %s. If the spec came from a newer powerkit, update powerkit.",
      format_value(version), paste(supported_spec_versions(), collapse = ", ")
    ))
  }
  character()
}

check_duplicate_names <- function(x, path = character()) {
  if (!is.list(x)) {
    return(character())
  }
  problems <- character()
  nms <- names(x)
  if (!is.null(nms)) {
    for (dup in unique(nms[duplicated(nms) & nzchar(nms)])) {
      problems <- c(problems, sprintf(
        "%s has '%s' more than once. Keep only one.",
        where_label(path), dup
      ))
    }
  }
  for (i in seq_along(x)) {
    child <- if (is.null(nms) || !nzchar(nms[i])) as.character(i - 1) else nms[i]
    problems <- c(problems, check_duplicate_names(x[[i]], c(path, child)))
  }
  problems
}

abort_spec <- function(problems) {
  heading <- if (length(problems) == 1) {
    "This design spec has a problem:"
  } else {
    sprintf("This design spec has %d problems:", length(problems))
  }
  message <- paste(c(heading, paste0("* ", problems)), collapse = "\n")
  stop(structure(
    class = c("powerkit_spec_error", "powerkit_error", "error", "condition"),
    list(message = message, call = NULL, problems = problems)
  ))
}

warn_spec <- function(advice) {
  warning(structure(
    class = c("powerkit_spec_warning", "warning", "condition"),
    list(message = advice, call = NULL)
  ))
}
