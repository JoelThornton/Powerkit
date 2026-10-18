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
# `start`: the answers to screen A (situation, aim, claim), which set the
# goal's starting choice and add the claim's questions.
form_groups <- function(forms, ep_id, k = 2, start = list()) {
  form <- forms$forms[[ep_id]]
  groups <- lapply(form$groups, function(g) {
    if (!is.null(g$generated)) g$fields <- generated_fields(form$mediators, g$generated, k)
    # The t-tests and the correlation need no effect size for the smallest
    # detectable effect: the engine solves for it (an empty value counts
    # as zero, and the result is positive).
    if (isTRUE(form$sensitivity_without_effect)) {
      has_effect <- any(vapply(g$fields, function(f) isTRUE(f$effect), logical(1)))
      g$fields <- lapply(g$fields, function(f) {
        if (isTRUE(f$effect)) f$optional_for <- c("sensitivity", "sensitivity_curve")
        f
      })
      if (has_effect) g$note <- "For the smallest effect you could detect, this can stay empty if you have no estimate; a negative value sets the direction."
    }
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
  # method_extra: further choices about the formula, shown with the method
  # (E5's z test or Cohen's h).
  if (isTRUE(form$basic_method)) groups <- c(groups, list(list(input = NULL, title = "How power is worked out", fields = c(list(basic_method_field(forms, ep_id)), form$method_extra))))
  c(groups, closing_groups(forms, ep_id, start))
}

# E1-E6: pwr's formula or Spower's simulation (forms.yaml,
# basic_method_field). Welch's t-test has no pwr formula, so for E2 the
# choice is shown only with Student's test; with Welch's the engine
# simulates.
basic_method_field <- function(forms, ep_id) {
  field <- forms$basic_method_field
  if (any(vapply(form_fields(forms$forms[[ep_id]]$groups), function(f) identical(f$id, "method"), logical(1)))) {
    field$shown_if <- list(field = "method", is = "student_t")
  }
  field
}

# The closing questions every form asks (decision-tree.md, table 2.2).
closing_groups <- function(forms, ep_id, start = list()) {
  form <- forms$forms[[ep_id]]
  tool <- forms$tool_defaults[[form$tool]]
  goals <- list(sample_size = "The sample size I need", power = "The power I'd have at a given sample size")
  if (isTRUE(form$sensitivity)) goals$sensitivity <- "The smallest effect I could detect at a given sample size"
  if (isTRUE(form$sensitivity_without_effect)) goals$sensitivity_curve <- "The smallest effect I could detect across a range of sample sizes"
  goal <- list(id = "goal", label = "What do you want to find out?", type = "select", path = "goal.type", required = TRUE, choices = goals)
  if (identical(start$situation, "fixed")) {
    goal$default <- if (isTRUE(form$sensitivity)) "sensitivity" else "power"
    goal$default_source <- "you said your sample size is fixed"
  }
  test <- list(
    goal,
    list(id = "power", label = "Target power, as a proportion (for example 0.9); needed for the sample size and the smallest effect",
         type = "number", path = "goal.power", needed_for = c("sample_size", "sensitivity"), min_exclusive = 0, max_exclusive = 1,
         default = tool[["power"]], default_source = tool[["power_source"]]),
    list(id = "power_reason", label = "Why this target power (optional; goes in the write-up, for example \"95% because a miss would waste a year of recruitment\")",
         type = "text", optional = TRUE),
    list(id = "n", label = "Number of participants analysed; needed for power and the smallest effect",
         type = "number", path = "goal.n", needed_for = c("power", "sensitivity"), min = 2, integer = TRUE),
    list(id = "n_max", label = "The largest number of participants you could analyse; needed for the range of sample sizes",
         type = "number", needed_for = "sensitivity_curve", min = 16, integer = TRUE),
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
  c(list(
    list(input = NULL, title = "What you want to find out", fields = test)),
    claim_groups(start$claim),
    list(
    list(input = NULL, title = "Where your effect size comes from", fields = list(
      list(id = "just_type", label = "Source of the effect size", type = "select", path = "effect_justification.type", required = TRUE,
           choices = c(list(
             smallest_effect_of_interest = "The smallest effect that would matter",
             meta_analysis = "A meta-analysis", prior_study = "A previous study", pilot_study = "A pilot study"),
             if (isTRUE(form$sensitivity_without_effect)) list(none = "I can't justify an effect size"))),
      list(id = "just_source", label = "Your reasoning, in your own words: where the number comes from, or why there isn't one (any length, any language; needed to save or export the plan, not to calculate)",
           type = "text", path = "effect_justification.source", optional = TRUE),
      list(id = "just_adjustment", label = "How you adjusted it (needed for a previous study; for example halved for publication bias)",
           type = "text", path = "effect_justification.adjustment", needed_if_just = "prior_study")
    )),
    list(input = NULL, title = "Participants you expect to lose", fields = list(
      list(id = "attrition", label = "Proportion you expect to lose (optional; for example 0.1 for 10%)", type = "number",
           path = "options.attrition", optional = TRUE, min = 0, max_exclusive = 1)
    )),
    # A fixed default seed, so the same answers give the same result
    # (judgement-calls.md B15); the user can change it.
    list(input = NULL, title = "Random seed", fields = list(
      list(id = "seed", label = sprintf("Random seed (a whole number; used when power is simulated, so the same seed gives the same result; empty = %s)", forms$default_seed),
           type = "number", path = "options.seed", optional = TRUE, integer = TRUE, min = 1, max = 2147483647,
           default = forms$default_seed, default_source = "powerkit's fixed default seed (judgement-calls.md B15)")
    ))
  ))
}

# The claim from screen A, on the input screen: a note for every claim but
# "one test", and for "any of several" the number of tests, which divides
# alpha between them (Bonferroni; docs/decisions.md, 18 October 2026).
claim_groups <- function(claim) {
  claim <- claim %||% "one"
  if (identical(claim, "one")) return(list())
  note <- switch(
    claim,
    each = "You said each test supports its own claim. Power this test on its own; run the input screen again for each of the others. No correction for several tests is needed, because no single conclusion rests on more than one test.",
    any = "You said your claim is about the set: it is supported if any one of the tests is significant. So the chance of a false positive is spread over the set: powerkit divides your significance level by the number of tests (Bonferroni) and uses that for this test.",
    all = "You said your claim needs every test to be significant. The chance that all succeed is lower than any one test's power: for two independent tests powered at 0.9, about 0.9 x 0.9 = 0.81. Tests on the same people are usually positively correlated, so that product is roughly a floor, not exact. Consider a higher target power for each test."
  )
  fields <- if (identical(claim, "any")) {
    list(list(id = "n_tests", label = "Number of tests in the set", type = "number", required = TRUE, min = 2, integer = TRUE))
  } else {
    list()
  }
  list(list(input = NULL, title = "Your claim", note = note, fields = fields))
}

# One line for the result screen on how the claim was handled, or NULL.
claim_result_note <- function(values, alpha_used) {
  switch(
    values$claim %||% "one",
    one = NULL,
    each = "Your claim: several claims, each standing on its own. This result is for one test, with no correction; work out each of the others the same way.",
    any = sprintf(
      "Your claim: any of %s tests. The significance level for this test is %s divided by %s (Bonferroni): %s.",
      values$n_tests, format(signif(alpha_used * as.numeric(values$n_tests), 3)), values$n_tests, format(signif(alpha_used, 3))
    ),
    all = "Your claim: all of several tests. The chance that every test succeeds is lower than this power: for two independent tests at 0.9, about 0.81, and roughly that or a little higher for correlated tests on the same people."
  )
}

# Alpha for this test: the significance level entered, divided by the
# number of tests when the claim is "any of several".
claim_alpha <- function(alpha, values) {
  k <- parse_number(values$n_tests)
  if (is.na(k) || is.nan(k) || k < 2) return(alpha)
  alpha / k
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
      if (effect_optional(f, values)) next
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
  c(problems, combination_problems(values))
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
    if (blank(v) && effect_optional(f, values)) v <- "0"
    if (blank(v)) next
    spec <- set_path(spec, split_path(f$path), field_value(f, v))
  }
  if (!is.null(spec$target_test$alpha)) spec$target_test$alpha <- claim_alpha(spec$target_test$alpha, values)
  # The range of sample sizes is several engine runs (sensitivity_curve());
  # the spec kept for the exports is the largest N at 80% power.
  if (identical(values$goal, "sensitivity_curve")) {
    spec$goal <- list(type = "sensitivity", n = as.integer(parse_number(values$n_max)), power = 0.8)
  }
  spec
}

# An effect size may stay empty for the smallest detectable effect, or
# when the user can't justify one (t-tests and the correlation only).
effect_optional <- function(f, values) {
  isTRUE(f$effect) && length(f$optional_for) > 0 &&
    (isTRUE(values$goal %in% f$optional_for) || identical(values$just_type, "none"))
}

# Problems with the combination of answers, beyond single fields.
combination_problems <- function(values) {
  if (identical(values$just_type, "none") && !isTRUE(values$goal %in% c("sensitivity", "sensitivity_curve"))) {
    return("With no effect size to plan for, there is no sample size or power to work out. Under \u201cWhat do you want to find out?\u201d, choose the smallest effect you could detect, at a given sample size or across a range of sample sizes.")
  }
  character()
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
