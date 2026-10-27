# Turn JSON-schema errors into plain-English messages.
#
# The schema validator (ajv, via jsonvalidate) reports each problem with a
# JSON pointer to the offending value, a keyword (required, enum, ...) and
# parameters. These helpers rewrite each one as a sentence that names the
# field in the user's terms and, where possible, suggests a fix.

schema_problems <- function(spec, validator = spec_validator()) {
  result <- validator(spec_to_json(spec), verbose = TRUE, greedy = TRUE)
  if (isTRUE(result)) {
    return(character())
  }
  errors <- attr(result, "errors")
  messages <- vapply(
    seq_len(nrow(errors)),
    function(i) schema_error_message(errors[i, , drop = FALSE], spec),
    character(1)
  )
  messages <- unique(messages[!is.na(messages)])
  if (length(messages) == 0) {
    messages <- "The spec doesn't match the expected format, but the problem couldn't be pinned down. Compare it with one of the example specs."
  }
  messages
}

# Keywords that only wrap other errors; their children carry the detail.
wrapper_keywords <- c("if", "then", "else", "allOf", "anyOf", "oneOf", "$ref")

schema_error_message <- function(error, spec) {
  keyword <- error$keyword
  if (keyword %in% wrapper_keywords) {
    return(NA_character_)
  }
  path <- pointer_segments(error$instancePath)
  where <- where_label(path)
  value <- value_at(spec, path)
  params <- error$params
  field <- if (length(path) > 0) path[length(path)] else ""

  switch(
    keyword,
    required = {
      missing <- params$missingProperty
      paste0(where, " is missing '", missing, "'.", missing_hint(missing))
    },
    additionalProperties = {
      extra <- params$additionalProperty
      allowed <- allowed_fields(error$parentSchema)
      paste0(
        "'", extra, "' is not a recognised field in ", tolower_first(where), ".",
        suggestion(extra, allowed$names),
        if (is.null(suggestion_match(extra, allowed$names))) allowed_text(allowed) else ""
      )
    },
    enum = {
      choices <- unlist(params$allowedValues)
      paste0(
        where, " must be one of ", quote_list(choices),
        "; you wrote ", format_value(value), ".",
        if (is.character(value)) suggestion(value, choices) else ""
      )
    },
    const = {
      allowed <- unlist(params$allowedValue)
      paste0(
        where, " must be ", format_value(allowed),
        "; you wrote ", format_value(value), ".",
        if (is.character(value)) suggestion(value, allowed) else ""
      )
    },
    type = {
      paste0(
        where, " should be ", type_phrase(params$type),
        ", but it is ", describe_value(value), "."
      )
    },
    minimum = ,
    maximum = ,
    exclusiveMinimum = ,
    exclusiveMaximum = {
      paste0(
        where, " must be ", comparison_phrase(params$comparison), " ",
        format_number(params$limit), "; you wrote ", format_value(value), ".",
        percent_hint(value, params$limit, field)
      )
    },
    minLength = paste0(where, " can't be empty."),
    minProperties = paste0(where, " can't be empty."),
    minItems = paste0(
      where, " needs at least ", params$limit, " entries; it has ",
      length(value), "."
    ),
    maxItems = paste0(
      where, " can have at most ", params$limit, " entries; it has ",
      length(value), "."
    ),
    uniqueItems = paste0(where, " has repeated entries; each one must be different."),
    `false schema` = paste0(
      where, " doesn't apply here", not_applicable_reason(path, spec),
      "; remove it."
    ),
    paste0(where, ": ", error$message, ".")
  )
}

# JSON pointer "/population/paths/X->M" -> c("population", "paths", "X->M").
pointer_segments <- function(pointer) {
  if (is.null(pointer) || is.na(pointer) || !nzchar(pointer)) {
    return(character())
  }
  segments <- strsplit(sub("^/", "", pointer), "/", fixed = TRUE)[[1]]
  segments <- gsub("~1", "/", segments, fixed = TRUE)
  gsub("~0", "~", segments, fixed = TRUE)
}

where_label <- function(path) {
  if (length(path) == 0) {
    return("The spec")
  }
  paste0("'", paste(path, collapse = " > "), "'")
}

tolower_first <- function(x) {
  if (startsWith(x, "The ")) paste0("t", substring(x, 2)) else x
}

value_at <- function(spec, path) {
  value <- spec
  for (segment in path) {
    if (!is.list(value)) {
      return(NULL)
    }
    if (is.null(names(value)) && grepl("^[0-9]+$", segment)) {
      index <- as.integer(segment) + 1L
      value <- if (index <= length(value)) value[[index]] else NULL
    } else {
      value <- value[[segment]]
    }
  }
  value
}

# Field names the schema allows where an additionalProperties error was
# raised. ajv reports the parent schema with each error; after jsonlite
# flattens the errors into a data frame, the properties that belong to this
# error's parent schema are the columns with a value in its row.
allowed_fields <- function(parent_schema) {
  props <- parent_schema$properties
  patterns <- parent_schema$patternProperties
  extra <- unlist(lapply(Filter(has_value, as.list(patterns)), function(p) p$description))
  list(
    names = names(Filter(has_value, as.list(props))),
    extra = extra[!is.na(extra)]
  )
}

has_value <- function(x) {
  if (is.data.frame(x)) {
    return(any(vapply(x, has_value, logical(1))))
  }
  if (is.list(x)) {
    return(length(x) > 0 && length(x[[1]]) > 0)
  }
  length(x) > 0 && !is.na(x[1])
}

allowed_text <- function(allowed) {
  if (length(allowed$names) == 0 || length(allowed$names) > 12) {
    return("")
  }
  extra <- allowed$extra[nzchar(allowed$extra)]
  text <- paste0(" Allowed here: ", paste(allowed$names, collapse = ", "))
  if (length(extra) > 0) {
    text <- paste0(text, ", and ", paste(extra, collapse = "; "))
  }
  paste0(text, ".")
}

# Suggest a correction only for names long enough to misspell, and only
# when one choice is clearly closest.
suggestion_match <- function(x, choices) {
  if (length(choices) == 0 || !is.character(x) || length(x) != 1 || nchar(x) < 3) {
    return(NULL)
  }
  distance <- utils::adist(tolower(x), tolower(choices))[1, ]
  best <- which(distance == min(distance))
  if (length(best) == 1 && distance[best] <= max(1, nchar(x) %/% 4)) choices[best] else NULL
}

suggestion <- function(x, choices) {
  match <- suggestion_match(x, choices)
  if (is.null(match)) "" else paste0(" Did you mean '", match, "'?")
}

missing_hint <- function(field) {
  hints <- c(
    effect_justification = paste0(
      " Every power analysis needs a reason for its effect size: give its type ",
      "(smallest_effect_of_interest, meta_analysis, prior_study, pilot_study, ",
      "own_study_result, ",
      "or none if no effect size can be justified) and, where you can, its source."
    ),
    adjustment = paste0(
      " Effects from single prior studies are usually overestimates; say how ",
      "you adjusted for this (e.g. 'halved'), or write 'none' and why."
    ),
    goal = paste0(
      " Say what you want: 'sample_size' (n for a target power), 'power' ",
      "(power at a fixed n) or 'sensitivity' (smallest effect detectable at n)."
    ),
    path = " Give the indirect path to test, e.g. 'X->M->Y'.",
    paths = " Give a value for every path in the model (use 0 for no effect)."
  )
  if (field %in% names(hints)) hints[[field]] else ""
}

not_applicable_reason <- function(path, spec) {
  if (identical(path[1], "goal") && !is.null(spec$goal$type)) {
    return(paste0(" when the goal type is '", spec$goal$type, "'"))
  }
  if (identical(path, c("target_test", "path"))) {
    return(" (an indirect path is only given for mediation designs)")
  }
  ""
}

percent_hint <- function(value, limit, field) {
  if (is.numeric(value) && length(value) == 1 && identical(as.numeric(limit), 1) &&
    value > 1 && value <= 100) {
    return(sprintf(
      " Write %s as a proportion: %s%% is %s.",
      if (nzchar(field)) field else "it", format_number(value), format_number(value / 100)
    ))
  }
  ""
}

# ajv gives the allowed types as "number", "number,array" or, for fields
# that allow several types (such as a cell SD: a number or a 2x2 array), as
# a list holding a character vector.
type_phrase <- function(types) {
  types <- unlist(strsplit(as.character(unlist(types)), ",", fixed = TRUE))
  phrases <- c(
    number = "a number",
    integer = "a whole number",
    string = "text in quotes",
    object = "a set of named fields ({ ... })",
    array = "a list ([ ... ])",
    boolean = "true or false",
    null = "null"
  )
  paste(phrases[types], collapse = " or ")
}

describe_value <- function(value) {
  if (is.null(value)) {
    return("empty (null)")
  }
  if (is.list(value)) {
    return(if (is.null(names(value))) "a list ([ ... ])" else "a set of named fields ({ ... })")
  }
  if (is.character(value)) {
    return(paste0("text (", format_value(value), ")"))
  }
  if (is.logical(value)) {
    return(paste0("true/false (", tolower(as.character(value)), ")"))
  }
  if (is.numeric(value) && value != round(value)) {
    return(paste0("a number with decimals (", format_number(value), ")"))
  }
  format_value(value)
}

comparison_phrase <- function(comparison) {
  switch(
    comparison,
    ">=" = "at least",
    ">" = "greater than",
    "<=" = "at most",
    "<" = "less than",
    comparison
  )
}

format_number <- function(x) {
  format(x, digits = 15, scientific = FALSE, trim = TRUE)
}

format_value <- function(value) {
  if (is.null(value)) {
    return("nothing")
  }
  if (is.character(value)) {
    return(paste0("'", value, "'", collapse = ", "))
  }
  if (is.numeric(value)) {
    return(paste(format_number(value), collapse = ", "))
  }
  if (is.list(value)) {
    return(describe_value(value))
  }
  paste(as.character(value), collapse = ", ")
}

quote_list <- function(x, conjunction = "or") {
  x <- paste0("'", x, "'")
  if (length(x) == 1) {
    return(x)
  }
  paste0(paste(utils::head(x, -1), collapse = ", "), " ", conjunction, " ", x[length(x)])
}

`%||%` <- function(x, y) if (is.null(x)) y else x
