# Input screens for the end points powerkit runs (forms.yaml).
#
# A screen collects the values on a card's "What you would enter" list,
# builds a design spec and checks it with the engine's validate_spec().
# Nothing is calculated: the prototype only shows the checked spec.
#
# Functions here are pure (no Shiny state), so the tests can call them
# directly. The engine is loaded read-only, on first use.

load_forms <- function(path = "forms.yaml") yaml::read_yaml(path)

has_form <- function(forms, ep_id) !is.null(forms$forms[[ep_id]])

# Number of mediators offered for parallel and serial mediation. Two is the
# validated case; more is open question 10 (setting parallel_mediators_max).
mediator_choices <- 2:4

# Mediator roles for k mediators.
mediator_roles <- function(k) paste0("M", seq_len(k))

# Indirect paths a hypothesis can be about.
indirect_path_choices <- function(kind, k) {
  ms <- mediator_roles(k)
  if (identical(kind, "parallel")) return(paste0("X->", ms, "->Y"))
  # Serial: every ordered, non-empty subset of the mediators.
  subsets <- unlist(lapply(seq_len(k), function(size) {
    combos <- utils::combn(ms, size, simplify = FALSE)
    vapply(combos, paste, character(1), collapse = "->")
  }))
  paste0("X->", subsets, "->Y")
}

path_field <- function(from, to, label = NULL, optional = FALSE) {
  list(
    id = paste0("p_", gsub("[^A-Za-z0-9]", "", from), "_", gsub("[^A-Za-z0-9]", "", to)),
    label = label %||% sprintf("Path %s -> %s", from, to),
    type = "number", path = sprintf("population.paths.%s->%s", from, to),
    effect = TRUE
  )
}

# Fields for a generated group (mediation with k mediators).
generated_fields <- function(kind, generator, k) {
  ms <- mediator_roles(k)
  switch(
    generator,
    parallel_paths = c(
      unlist(lapply(ms, function(m) list(path_field("X", m), path_field(m, "Y"))), recursive = FALSE),
      list(path_field("X", "Y", "Path X -> Y (direct)"))
    ),
    serial_paths = {
      nodes <- c("X", ms)
      fields <- list()
      for (i in seq_along(ms)) {
        for (from in nodes[seq_len(i)]) fields <- c(fields, list(path_field(from, ms[i])))
      }
      c(fields, lapply(ms, function(m) path_field(m, "Y")), list(path_field("X", "Y", "Path X -> Y (direct)")))
    },
    residual_correlations = {
      pairs <- utils::combn(ms, 2, simplify = FALSE)
      lapply(pairs, function(p) list(
        id = paste0("rc_", p[1], "_", p[2]),
        label = sprintf("Residual correlation of %s with %s (optional; empty = 0)", p[1], p[2]),
        type = "number", path = sprintf("population.residual_correlations.%s<->%s", p[1], p[2]),
        optional = TRUE, min = -1, max = 1
      ))
    },
    target_path = {
      choices <- indirect_path_choices(kind, k)
      list(list(
        id = "target_path", label = "Indirect path", type = "select", path = "target_test.path",
        required = TRUE, choices = stats::setNames(as.list(choices), choices)
      ))
    }
  )
}

# The names group, for forms whose card doesn't list variable names.
names_group <- function(form, k) {
  roles <- unlist(form$names)
  if (!is.null(form$mediators)) roles <- c("X", mediator_roles(k), "Y")
  describe <- c(X = "X (the cause or predictor)", W = "W (the moderator)", M = "M (the mediator)", Y = "Y (the outcome)")
  list(
    input = NULL, title = "What you call each variable",
    fields = lapply(roles, function(role) list(
      id = paste0(role, "_label"),
      label = if (role %in% names(describe)) describe[[role]] else sprintf("%s (mediator %s)", role, sub("M", "", role)),
      type = "text", path = sprintf("variables.%s.label", role), required = TRUE
    ))
  )
}

# The groups of fields a form shows, with generated groups expanded.
# `k` is the number of mediators (parallel and serial mediation only).
form_groups <- function(forms, ep_id, k = 2) {
  form <- forms$forms[[ep_id]]
  groups <- lapply(form$groups, function(g) {
    if (!is.null(g$generated)) g$fields <- generated_fields(form$mediators, g$generated, k)
    g
  })
  if (!is.null(form$mediators)) {
    groups <- c(list(list(input = NULL, title = "How many mediators", fields = list(list(
      id = "n_mediators", label = "Number of mediators", type = "select", required = TRUE,
      choices = stats::setNames(as.list(as.character(mediator_choices)), mediator_choices),
      default = "2", default_source = "the number powerkit has validated (two); more is open question 10"
    )))), groups)
  }
  if (!is.null(form$names) || !is.null(form$mediators)) groups <- c(list(names_group(form, k)), groups)
  if (!is.null(form$extra)) groups <- c(groups, list(list(input = NULL, title = "How power is worked out", fields = form$extra)))
  c(groups, closing_groups(forms, ep_id))
}

# The closing questions every form asks (decision-tree.md, table 2.2).
closing_groups <- function(forms, ep_id) {
  form <- forms$forms[[ep_id]]
  tool <- forms$tool_defaults[[form$tool]]
  goals <- list(sample_size = "The sample size I need", power = "The power I'd have at a given sample size")
  if (isTRUE(form$sensitivity)) goals$sensitivity <- "The smallest effect I could detect at a given sample size"
  test <- list(
    list(id = "goal", label = "What do you want to find out?", type = "select", path = "goal.type", required = TRUE, choices = goals),
    list(id = "power", label = "Target power, as a proportion (for example 0.9); needed for the sample size and the smallest effect",
         type = "number", path = "goal.power", needed_for = c("sample_size", "sensitivity"), min_exclusive = 0, max_exclusive = 1,
         default = tool[["power"]], default_source = tool[["power_source"]]),
    list(id = "n", label = "Number of participants analysed; needed for power and the smallest effect",
         type = "number", path = "goal.n", needed_for = c("power", "sensitivity"), min = 2, integer = TRUE),
    list(id = "alpha", label = "Significance level (alpha)", type = "number", path = "target_test.alpha", required = TRUE,
         min_exclusive = 0, max = 0.5, default = tool[["alpha"]], default_source = tool[["alpha_source"]])
  )
  if (isTRUE(form$directional)) {
    test <- c(test, list(list(
      id = "alternative", label = "Direction of the test", type = "select", path = "target_test.alternative", required = TRUE,
      choices = list(two_sided = "Two-sided (either direction)", greater = "One-sided: the effect is positive", less = "One-sided: the effect is negative"),
      default = "two_sided", default_source = tool[["alternative_source"]]
    )))
  }
  list(
    list(input = NULL, title = "What you want to find out", fields = test),
    list(input = NULL, title = "Where your effect size comes from", fields = list(
      list(id = "just_type", label = "Source of the effect size", type = "select", path = "effect_justification.type", required = TRUE,
           choices = list(
             smallest_effect_of_interest = "The smallest effect that would matter",
             meta_analysis = "A meta-analysis", prior_study = "A previous study", pilot_study = "A pilot study")),
      list(id = "just_source", label = "Where the number comes from, in your words (for example a reference or a decision rule)",
           type = "text", path = "effect_justification.source", required = TRUE),
      list(id = "just_adjustment", label = "How you adjusted it (needed for a previous study; for example halved for publication bias)",
           type = "text", path = "effect_justification.adjustment", needed_if_just = "prior_study")
    )),
    list(input = NULL, title = "Participants you expect to lose", fields = list(
      list(id = "attrition", label = "Proportion you expect to lose (optional; for example 0.1 for 10%)", type = "number",
           path = "options.attrition", optional = TRUE, min = 0, max_exclusive = 1)
    ))
  )
}

form_fields <- function(groups) unlist(lapply(groups, `[[`, "fields"), recursive = FALSE)

# --- Reading values ------------------------------------------------------------

blank <- function(x) is.null(x) || length(x) == 0 || all(is.na(x)) || identical(trimws(as.character(x[[1]])), "")

parse_number <- function(x) {
  if (blank(x)) return(NA_real_)
  x <- trimws(as.character(x))
  if (!grepl("^[-+]?([0-9]+\\.?[0-9]*|\\.[0-9]+)([eE][-+]?[0-9]+)?$", x)) return(NaN)
  as.numeric(x)
}

parse_levels <- function(x) {
  if (blank(x)) return(character())
  out <- trimws(strsplit(as.character(x), ",", fixed = TRUE)[[1]])
  out[nzchar(out)]
}

parse_table <- function(x) {
  if (blank(x)) return(NULL)
  lines <- trimws(strsplit(as.character(x), "\n", fixed = TRUE)[[1]])
  lines <- lines[nzchar(lines)]
  lapply(lines, function(l) vapply(trimws(strsplit(l, ",", fixed = TRUE)[[1]]), parse_number, numeric(1), USE.NAMES = FALSE))
}

# Whether a field applies, given the goal, the justification and any other
# choice it depends on (`shown_if`: shown only when another field `is`, or
# `is_not`, a given value; an empty choice counts as no value).
field_applies <- function(field, values) {
  if (!is.null(field$shown_if)) {
    current <- values[[field$shown_if$field]]
    current <- if (blank(current)) "" else as.character(current)
    if (!is.null(field$shown_if[["is"]]) && !identical(current, field$shown_if[["is"]])) return(FALSE)
    if (!is.null(field$shown_if[["is_not"]]) && identical(current, field$shown_if[["is_not"]])) return(FALSE)
  }
  if (!is.null(field$needed_for)) return(isTRUE(values$goal %in% field$needed_for))
  if (!is.null(field$needed_if_just)) return(identical(values$just_type, field$needed_if_just))
  TRUE
}

quote_label <- function(field) sprintf("“%s”", field$label)

# Problems the screen can find before the engine sees the spec, in plain
# English, naming each field by its label.
form_problems <- function(fields, values) {
  problems <- character()
  for (f in fields) {
    if (!field_applies(f, values)) next
    v <- values[[f$id]]
    # Required: marked so, an effect size, or needed for the goal chosen.
    needed <- isTRUE(f$required) || isTRUE(f$effect) || !is.null(f$needed_for) || !is.null(f$needed_if_just)
    if (blank(v)) {
      if (isTRUE(f$effect)) {
        problems <- c(problems, sprintf("%s is empty. Enter the value you expect; powerkit doesn't fill in effect sizes.", quote_label(f)))
      } else if (needed) {
        problems <- c(problems, sprintf("%s is empty.", quote_label(f)))
      }
      next
    }
    if (identical(f$type, "number")) {
      x <- parse_number(v)
      if (is.nan(x)) {
        problems <- c(problems, sprintf("%s should be a number written with a decimal point, such as 0.3.", quote_label(f)))
        next
      }
      if (!is.null(f[["min"]]) && x < f[["min"]]) problems <- c(problems, sprintf("%s must be at least %s.", quote_label(f), f[["min"]]))
      if (!is.null(f[["max"]]) && x > f[["max"]]) problems <- c(problems, sprintf("%s must be at most %s.", quote_label(f), f[["max"]]))
      if (!is.null(f$min_exclusive) && x <= f$min_exclusive) problems <- c(problems, sprintf("%s must be more than %s.", quote_label(f), f$min_exclusive))
      if (!is.null(f$max_exclusive) && x >= f$max_exclusive) problems <- c(problems, sprintf("%s must be less than %s.", quote_label(f), f$max_exclusive))
      if (isTRUE(f$integer) && x != round(x)) problems <- c(problems, sprintf("%s must be a whole number.", quote_label(f)))
    }
    if (identical(f$type, "levels")) {
      lv <- parse_levels(v)
      if (length(lv) < 2) problems <- c(problems, sprintf("%s needs at least two names, separated by commas.", quote_label(f)))
      if (anyDuplicated(lv)) problems <- c(problems, sprintf("%s has the same name twice.", quote_label(f)))
    }
    if (identical(f$type, "table")) {
      tb <- parse_table(v)
      if (any(vapply(tb, function(r) any(is.nan(r) | is.na(r)), logical(1)))) {
        problems <- c(problems, sprintf("%s: every entry should be a number written with a decimal point, such as 0.25.", quote_label(f)))
      } else {
        rows <- length(parse_levels(values$X_levels)); cols <- length(parse_levels(values$Y_levels))
        if (length(tb) != rows || any(lengths(tb) != cols)) {
          problems <- c(problems, sprintf("%s should have %d lines (one per category of the first variable) of %d numbers each (one per category of the second).", quote_label(f), rows, cols))
        }
      }
    }
  }
  problems
}

# --- Building the spec ---------------------------------------------------------

set_path <- function(x, keys, value) {
  key <- keys[[1]]
  index <- suppressWarnings(as.integer(key))
  if (!is.na(index) && grepl("^[0-9]+$", key)) key <- index
  if (length(keys) == 1) {
    x[[key]] <- value
  } else {
    child <- if (is.numeric(key)) { if (length(x) >= key) x[[key]] else list() } else (x[[key]] %||% list())
    x[[key]] <- set_path(child, keys[-1], value)
  }
  x
}

split_path <- function(path) {
  # Path segments are separated by dots, except inside "A->B" or "A<->B" keys.
  strsplit(path, ".", fixed = TRUE)[[1]]
}

field_value <- function(f, v) {
  switch(
    f$type,
    number = { x <- parse_number(v); if (isTRUE(f$integer)) as.integer(x) else x },
    levels = as.list(parse_levels(v)),
    table = lapply(parse_table(v), as.list),
    trimws(as.character(v))
  )
}

# The design spec for the values entered (assumes form_problems() found none).
build_spec <- function(forms, ep_id, fields, values) {
  form <- forms$forms[[ep_id]]
  spec <- form$base
  # Mediators are added for the number chosen; each is a score.
  if (!is.null(form$mediators)) {
    for (m in mediator_roles(as.integer(values$n_mediators %||% 2))) spec$variables[[m]] <- list(type = "continuous")
  }
  for (f in fields) {
    if (is.null(f$path) || !field_applies(f, values)) next
    v <- values[[f$id]]
    if (blank(v)) next
    spec <- set_path(spec, split_path(f$path), field_value(f, v))
  }
  spec
}

# --- The engine's check ----------------------------------------------------------

engine_cache <- new.env(parent = emptyenv())

# A function from powerkit's engine: the installed powerkit package, or
# engine/ loaded read-only with pkgload. NULL when neither is available.
engine_function <- function(name, engine_dir = file.path(routing_root(), "..", "..", "engine")) {
  key <- paste0("fn_", name)
  if (!is.null(engine_cache[[key]])) return(engine_cache[[key]])
  fn <- tryCatch({
    if (requireNamespace("powerkit", quietly = TRUE)) {
      getExportedValue("powerkit", name)
    } else if (requireNamespace("pkgload", quietly = TRUE) && dir.exists(engine_dir)) {
      if (!"powerkit" %in% loadedNamespaces()) {
        suppressMessages(pkgload::load_all(engine_dir, export_all = FALSE, helpers = FALSE, quiet = TRUE, attach = FALSE))
      }
      get(name, envir = asNamespace("powerkit"))
    }
  }, error = function(e) NULL)
  engine_cache[[key]] <- fn
  fn
}

# validate_spec(), or NULL where the engine isn't available.
engine_validator <- function(engine_dir = file.path(routing_root(), "..", "..", "engine")) {
  engine_function("validate_spec", engine_dir)
}

routing_root <- function() getOption("powerkit.routing_dir", getwd())

# Put the user's field labels in place of spec paths in the engine's
# messages (e.g. 'target_test > alpha' becomes "Significance level (alpha)").
plain_engine_message <- function(message, fields) {
  for (f in fields) {
    if (is.null(f$path)) next
    engine_path <- gsub(".", " > ", f$path, fixed = TRUE)
    message <- gsub(sprintf("'%s'", engine_path), quote_label(f), message, fixed = TRUE)
  }
  message
}

# Check a spec with validate_spec(). Returns status "ok", "problems" or
# "unavailable", with the engine's problems and advice in plain English.
check_spec <- function(spec, fields, validate = engine_validator()) {
  if (is.null(validate)) return(list(status = "unavailable", problems = character(), advice = character()))
  advice <- character()
  result <- tryCatch(
    withCallingHandlers(
      { validate(spec); "ok" },
      warning = function(w) { advice <<- c(advice, conditionMessage(w)); invokeRestart("muffleWarning") }
    ),
    error = function(e) e
  )
  if (identical(result, "ok")) {
    return(list(status = "ok", problems = character(), advice = vapply(advice, plain_engine_message, "", fields = fields, USE.NAMES = FALSE)))
  }
  problems <- result$problems %||% conditionMessage(result)
  list(status = "problems", problems = vapply(problems, plain_engine_message, "", fields = fields, USE.NAMES = FALSE),
       advice = vapply(advice, plain_engine_message, "", fields = fields, USE.NAMES = FALSE))
}

spec_json <- function(spec) as.character(jsonlite::toJSON(spec, auto_unbox = TRUE, pretty = TRUE, digits = NA))

# --- Copying answers -------------------------------------------------------------

# The route taken and the values entered, as plain text to paste anywhere.
answers_text <- function(tree, route_label, history, ep_id, fields, values) {
  ep <- tree$endpoints[[ep_id]]
  lines <- c("powerkit routing prototype: my answers", "", paste0("Route: ", route_label))
  lines <- c(lines, path_lines(tree, history))
  lines <- c(lines, "", sprintf("End point: %s, %s (%s)", ep_id, ep$plain_name, ep$doc_name), "", "Values entered:")
  for (f in fields) {
    v <- values[[f$id]]
    if (blank(v) || !field_applies(f, values)) next
    shown <- if (!is.null(f$choices) && !is.null(f$choices[[as.character(v)]])) f$choices[[as.character(v)]] else gsub("\n", " / ", as.character(v))
    lines <- c(lines, sprintf("- %s: %s", f$label, shown))
  }
  paste(lines, collapse = "\n")
}
