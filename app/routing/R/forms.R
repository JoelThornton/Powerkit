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

# Number of mediators offered. Two is the validated case. Parallel
# mediation stays at two until three or more are validated (open question
# 10, decided 22 October 2026: setting parallel_mediators_max, `two`);
# serial mediation offers up to four.
mediator_choices <- 2:4
mediator_choices_for <- function(kind) if (identical(kind, "parallel")) 2L else mediator_choices

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
    # Moderated mediation with parallel mediators (E40): the paths both
    # PROCESS models share, and those of the model chosen in `stage`.
    modmed_paths = {
      first <- list(field = "stage", is = "process_7")
      second <- list(field = "stage", is = "process_14")
      only <- function(field, when) c(field, list(shown_if = when))
      c(
        unlist(lapply(ms, function(m) list(
          path_field("X", m),
          only(path_field("W", m), first),
          only(path_field("XW", m, sprintf("Path XW -> %s (the interaction)", m)), first),
          path_field(m, "Y"),
          only(path_field(paste0(m, "W"), "Y", sprintf("Path %sW -> Y (the interaction)", m)), second)
        )), recursive = FALSE),
        list(only(path_field("W", "Y"), second), path_field("X", "Y", "Path X -> Y (direct)"))
      )
    },
    modmed_target = list(list(
      id = "target_path", label = "Whose index of moderated mediation the hypothesis is about", type = "select",
      path = "target_test.path", required = TRUE,
      choices = stats::setNames(as.list(paste0("Through ", ms, " (X -> ", ms, " -> Y)")), paste0("X->", ms, "->Y"))
    )),
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
  if (!is.null(form$mediators)) roles <- c("X", intersect("W", roles), mediator_roles(k), "Y")
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
# The Bayes factor threshold starts empty (8 November 2026), as target
# power does: after it, an optional reason for the write-up, shown with it.
with_threshold_reason <- function(g) {
  at <- which(vapply(g$fields, function(f) identical(f$id, "evidence_threshold"), logical(1)))
  if (!length(at)) return(g)
  reason <- list(id = "evidence_reason", label = "Why this threshold", type = "text", optional = TRUE,
    help = "Goes in the write-up; for example \"30, because the claim contradicts an established finding\".",
    shown_if = g$fields[[at]]$shown_if)
  g$fields <- append(g$fields, list(reason), after = at)
  g
}

# The analysis prior keeps its software's default, with a short question
# beside it (8 November 2026): a default prior is a convention, so the
# user is asked whether it fits their field.
prior_ids <- c("prior_scale", "prior_width", "prior_concentration", "prior_a")
prior_prompt <- paste("Does this default fit your field? It is the software's convention, not evidence about your effect.",
  "If what is known in your area points to another prior, enter the one you will analyse with, and say why in your analysis plan.")
with_prior_prompt <- function(g) {
  g$fields <- lapply(g$fields, function(f) {
    if (isTRUE(f$id %in% prior_ids)) f$prompt <- prior_prompt
    f
  })
  g
}

form_groups <- function(forms, ep_id, k = 2, start = list()) {
  form <- forms$forms[[ep_id]]
  # A number of mediators not offered (e.g. from an older project file) is
  # brought within range.
  if (!is.null(form$mediators)) k <- min(max(k, 2L), max(mediator_choices_for(form$mediators)))
  groups <- lapply(form$groups, function(g) {
    # A generated group can end with fixed fields (`fields_after`).
    if (!is.null(g$generated)) g$fields <- c(generated_fields(form$mediators, g$generated, k), g$fields_after)
    # The basic tests need no effect size for the smallest detectable
    # effect: the engine solves for it (an empty value counts as zero, or
    # as the field's `when_empty`, and the result is positive). A
    # `baseline` field (group 1's proportion) is still needed.
    if (isTRUE(form$sensitivity_without_effect)) {
      has_effect <- any(vapply(g$fields, function(f) isTRUE(f$effect), logical(1)))
      g$fields <- lapply(g$fields, function(f) {
        if (isTRUE(f$effect) && !isTRUE(f$baseline)) f$optional_for <- c("sensitivity", "sensitivity_curve")
        f
      })
      if (has_effect) g$note <- form$sensitivity_note %||% "For the smallest effect you could detect, this can stay empty if you have no estimate; a negative value sets the direction."
    }
    with_prior_prompt(with_threshold_reason(with_conversion(with_eta_squared(g, form$base$template), form$base$template)))
  })
  if (isTRUE(form$base$design %in% c("mediation", "moderated_mediation"))) {
    groups <- lapply(groups, function(g) {
      g$fields <- lapply(g$fields, function(f) {
        if (identical(f$id, "ci_draws")) {
          f$label <- "Draws or bootstrap resamples per confidence interval"
          f$empty_text <- "1,000 for Monte Carlo/ML bootstrap; 5,000 for OLS bootstrap"
          f$help <- "A numerical accuracy setting, not an effect-size assumption. Leave empty for the defaults, or match the resample count in your planned analysis. More draws reduce simulation noise and take longer."
          # The quick estimate draws no interval.
          if (simple_mediation_card(form)) f$shown_if <- list(field = "method", is_not = "joint_significance")
        }
        f
      })
      if (identical(g$title, "Monte Carlo draws")) g$title <- "Confidence interval accuracy"
      g
    })
    has_draws <- any(vapply(form_fields(groups), function(f) identical(f$id, "ci_draws"), logical(1)))
    if (!has_draws) groups <- c(groups, list(list(input = NULL, title = "Confidence interval accuracy",
      fields = list(list(id = "ci_draws", label = "Draws or bootstrap resamples per confidence interval",
        type = "number", path = "options.ci_draws", optional = TRUE, min = 100, max = 100000, integer = TRUE,
        empty_text = "1,000 for Monte Carlo/ML bootstrap; 5,000 for OLS bootstrap",
        help = "Leave empty for the numerical default, or match your planned analysis. More draws reduce simulation noise and take longer.")))))
    groups <- c(list(mediation_analysis_group(simple_mediation_card(form))), groups)
  }
  if (!is.null(form$mediators)) {
    groups <- c(list(list(input = NULL, title = "How many mediators", fields = list(list(
      id = "n_mediators", label = "Number of mediators", type = "select", required = TRUE,
      choices = stats::setNames(as.list(as.character(mediator_choices_for(form$mediators))), mediator_choices_for(form$mediators)),
      default = "2", default_source = if (identical(form$mediators, "parallel"))
        "two, the number powerkit has validated for parallel mediation; more will be offered once checked"
      else "the number powerkit has validated (two)"
    )))), groups)
  }
  if (!is.null(form$names) || !is.null(form$mediators)) groups <- c(list(names_group(form, k)), groups)
  # A generic test asks for the direction after the test type, since only
  # t and z tests have one.
  if (isTRUE(form$directional)) {
    direction <- direction_group(forms$tool_defaults[[form$tool]], form$direction_shown_if)
    groups <- if (isTRUE(form$generic)) c(groups, list(direction)) else c(list(direction), groups)
  }
  if (!is.null(form$extra)) groups <- c(groups, list(list(input = NULL, title = "How power is worked out", fields = form$extra)))
  groups <- lapply(groups, function(g) { g$fields <- lapply(g$fields, function(f) with_level_count(with_name_default(f))); g })
  groups <- with_sd_units(groups)
  # method_extra: further choices about the formula, shown with the method
  # (E5's z test or Cohen's h).
  if (isTRUE(form$basic_method)) groups <- c(groups, list(list(input = NULL, title = "How power is worked out", fields = c(list(basic_method_field(forms, ep_id)), form$method_extra))))
  out <- c(groups, simulation_accuracy_group(forms, ep_id), closing_groups(forms, ep_id, start))
  candidates <- form_fields(out)
  c(out, list(list(input = NULL, title = "Assumptions and named alternatives", fields = list(
    list(id = "scenario_library", label = "Assumptions and named alternatives", type = "scenario_library", optional = TRUE,
      scenario_fields = candidates)))))
}


# The estimator and interval are chosen together so PROCESS-style planning
# cannot accidentally keep lavaan ML or a Monte Carlo interval.
# Simple mediation (one mediator: E10, E16) also offers a quick estimate
# (12 November 2026): the joint-significance test by pwrss's formula,
# instant and with a sample size, which the simulated interval can't give
# in the app. It is where the screen starts, and the result says plainly
# that it is an estimate and how to get the number to report.
simple_mediation_card <- function(form) {
  identical(form$base$design, "mediation") && identical(form$base$template, "process_4") && is.null(form$mediators)
}

mediation_analysis_group <- function(simple = FALSE) {
  group <- mediation_analysis_group_full()
  if (!simple) return(group)
  f <- group$fields[[1]]
  f$choices <- c(list(joint_significance = "Quick estimate: both paths significant, by formula (instant, for planning)"), f$choices)
  f$default <- "joint_significance"
  f$default_source <- "the quick estimate, so the screen gives an answer straight away (pwrss's power.z.mediation(method = 'joint') formula, a little optimistic); choose a simulated method for the number you report"
  f$choice_notes <- list(
    joint_significance = "An estimate for planning, not for your write-up. The joint-significance test counts the indirect effect when both paths are significant; its power comes from a formula, so the answer is instant, but it is optimistic: with paths of .3 and 100 people it gives 75% power where the full simulation gives 71%, so the sample size it gives can be about 10% short. For the number you report, choose one of the simulated methods: power at a fixed sample size runs here in about 12 minutes, and the sample size comes as an R script for your own computer.")
  f$help <- paste("Start with the quick estimate to see roughly how many people you need.", f$help)
  group$fields[[1]] <- f
  group
}

mediation_analysis_group_full <- function() {
  list(input = NULL, title = "Which mediation analysis will you run?",
    note = "Choose the method you will use to analyse your study. PROCESS is one way of running mediation; its model number alone does not identify the test.",
    note_more = "The PROCESS-style option fits each equation by ordinary least squares (OLS) and resamples whole participants. It covers the displayed model with complete independent observations and continuous mediators/outcomes, using the existing normal-error population generator. It does not run PROCESS itself or cover its logistic, clustered/stratified bootstrap, measurement-error or bias-corrected options.",
    fields = list(list(id = "method", label = "Estimation and confidence interval", type = "select",
      path = "target_test.method", required = TRUE, default = "monte_carlo_ci",
      default_source = "the existing power4mome method: maximum likelihood and a Monte Carlo interval; choose OLS bootstrap for PROCESS-style analysis",
      choices = list(monte_carlo_ci = "Maximum likelihood + Monte Carlo interval (current Powerkit method)",
        ols_percentile_bootstrap = "Ordinary regression + percentile bootstrap (PROCESS-style)",
        percentile_bootstrap = "Maximum likelihood + percentile bootstrap"),
      help = "Ordinary regression fits one regression for each equation; maximum likelihood fits a joint path model. Choose the method and interval you will report. Bootstrap planning runs through a downloaded R script and can take hours. The Monte Carlo option keeps its existing browser workflow.")))
}

simulation_accuracy_group <- function(forms, ep_id) {
  form <- forms$forms[[ep_id]]
  choices <- unlist(lapply(form_fields(form$groups), function(f) names(f$choices)))
  offered <- ep_id %in% c(names(forms$background), names(forms$simulations$endpoints)) ||
    isTRUE(form$basic_method) || identical(form$base$design, "factorial_anova") ||
    any(choices %in% c("simulation", "hartung_knapp", "brunner_munzel", "permanova")) ||
    identical(form$base$template, "paired_variances")
  if (!offered) return(NULL)
  when <- NULL
  if (isTRUE(form$basic_method)) when <- list(any = list(
    list(field = "method", is_one_of = c("wilcoxon_signed_rank", "mann_whitney", "brunner_munzel", "spearman", "kendall", "z_test_corrected", "pearson_chi_square_corrected")),
    list(list(field = "method", is = "welch_t"), list(field = "welch_method", is_not = "exact")),
    list(list(field = "calc_method", is = "simulation"), list(field = "method", is_not = "welch_t"),
      list(field = "method", is_not = "bayes_factor"), list(field = "method", is_not = "minimum_effect"), list(field = "method", is_not = "fisher_exact"))))
  if (identical(form$base$design, "meta_analysis")) {
    test <- Filter(function(f) identical(f$path, "target_test.test"), form_fields(form$groups))
    if (length(test)) when <- list(field = test[[1]]$id, is = "hartung_knapp")
  }
  group <- list(input = NULL, title = "Simulation accuracy", note = paste(
    "Used only when this analysis is simulated. More simulated studies shrink the random error in the answer;",
    "they do not resolve uncertainty about your effect size, SDs, correlations or other assumptions."),
    note_more = paste(
    "The margins below are approximate pointwise 95% margins for the random error in a probability, assuming every simulated study gives a valid decision.",
    "Failures can reduce the effective number of decisions; read the actual interval and failure counts in the result.",
    "More simulations do not guarantee a sample-size search's accuracy. Formulas have no simulation error.",
    if (any(choices %in% c("z_test_corrected", "pearson_chi_square_corrected")))
      "For continuity-corrected count tests, finding N also uses fresh checks of at least 10,000 studies per candidate. This takes longer and may recommend more participants than the minimum."), fields = list(
    list(id = "simulation_accuracy", label = "How precise should the simulation be?", type = "select", optional = TRUE,
      default = "standard", default_source = "1,000 repeated studies, powerkit's usual simulation setting",
      choices = list(quick = "Quick exploration: about +/-5 percentage points (400 studies)",
        standard = "Standard: about +/-3 percentage points (1,000 studies)",
        precise = "More precise: about +/-1 percentage point (10,000 studies; takes longer)", custom = "Custom number of repeated studies"),
      sets = list(quick = list(list(path = "options.nrep", value = 400L)),
        standard = list(list(path = "options.nrep", value = 1000L)),
        precise = list(list(path = "options.nrep", value = 10000L)))),
    list(id = "nrep", label = "Repeated studies per sample size", type = "number", path = "options.nrep",
      optional = TRUE, integer = TRUE, min = 100, max = 1000000,
      help = "Advanced: empty uses the engine's usual number. A custom number changes simulation error and run time, not the assumed population.",
      shown_if = list(field = "simulation_accuracy", is = "custom"))))
  if (!is.null(when)) {
    group$shown_if <- list(when)
    group$fields <- lapply(group$fields, function(f) {
      f$shown_if <- c(list(when), if (!is.null(f$shown_if)) list(f$shown_if))
      f
    })
  }
  list(group)
}

# Names of variables and their levels only label the result and the
# write-up, so they may stay empty: an empty name stands for a neutral one
# taken from the field's label ("Group 1", "Outcome"), shown in the box.
# Fields of type "levels" are not names alone: they set how many levels
# there are, so they stay required.
name_field <- function(f) {
  identical(f$type, "text") && !is.null(f$path) &&
    grepl("^variables\\.[^.]+\\.(label|levels\\.[0-9]+)$", f$path)
}

name_default_text <- function(f) {
  text <- trimws(sub("\\s*\\(.*$", "", f$label))
  text <- sub(",\\s*the .*$", "", text)
  if (grepl("^The [a-z]+ factor$", text)) text <- sub("^The (.)", "\\U\\1", text, perl = TRUE)
  if (grepl("^(What|The groups)", text)) {
    role <- sub("^variables\\.([^.]+)\\..*$", "\\1", f$path)
    text <- if (grepl("conditions are", text)) "Condition"
      else if (grepl("groups", text)) "Group"
      else if (role %in% c("A", "B", "C")) paste("Factor", role)
      else role
  }
  text
}

with_name_default <- function(f) {
  if (!name_field(f) || !isTRUE(f$required)) return(f)
  f$required <- FALSE
  f$name_default <- name_default_text(f)
  f
}

# A variable's groups, conditions or categories may be given by how many
# there are instead of by name (5 November 2026): "3" stands for
# "Group 1, Group 2, Group 3", so naming them is optional, as in G*Power,
# which asks only for the number.
level_count_field <- function(f) {
  identical(f$type, "levels") && !is.null(f$path) && grepl("^variables\\.[^.]+\\.levels$", f$path)
}

level_prefix <- function(f) {
  label <- tolower(f$label)
  if (grepl("group", label)) "Group"
  else if (grepl("condition", label)) "Condition"
  else if (grepl("categor", label)) "Category"
  else if (grepl("timepoint", label)) "Time"
  else "Level"
}

with_level_count <- function(f) {
  if (!level_count_field(f)) return(f)
  prefix <- level_prefix(f)
  note <- sprintf("Or just how many there are, such as 3: they are then called %s 1, %s 2 and so on.", prefix, prefix)
  f$help <- if (is.null(f$help)) note else paste(f$help, note)
  f$level_prefix <- prefix
  f
}

# The values with any count in a levels field written out as names.
expand_level_counts <- function(fields, values) {
  for (f in fields) {
    if (is.null(f$level_prefix) || is.null(f$id)) next
    v <- values[[f$id]]
    if (is.null(v) || length(v) != 1 || !grepl("^\\s*[0-9]+\\s*$", as.character(v))) next
    n <- as.integer(v)
    if (n >= 2 && n <= 50) values[[f$id]] <- paste(sprintf("%s %d", f$level_prefix, seq_len(n)), collapse = ", ")
  }
  values
}

# Means in SD units have an SD of 1 by definition, so the SD isn't asked:
# choosing SD units fills it in (5 November 2026). Applies where the form
# has the "Units of the means" choice and one common SD (population.sd).
with_sd_units <- function(groups) {
  ids <- unlist(lapply(groups, function(g) vapply(g$fields, function(f) f$id %||% "", character(1))))
  if (!all(c("metric", "sd") %in% ids)) return(groups)
  lapply(groups, function(g) {
    g$fields <- lapply(g$fields, function(f) {
      if (identical(f$id, "metric") && "standardised" %in% names(f$choices)) {
        f$sets <- utils::modifyList(f$sets %||% list(), list(standardised = c(f$sets$standardised, list(list(path = "population.sd", value = 1)))))
      }
      if (identical(f$id, "sd") && identical(f$path, "population.sd")) {
        f$shown_if <- c(shown_if_conditions(f), list(list(field = "metric", is_not = "standardised")))
        f$label <- sub(";? *1 if the means are in SD units", "", f$label)
      }
      f
    })
    g
  })
}

# The decision rule is chosen before looking at data, without a prefilled
# direction. A directional prediction can still accompany a two-sided test;
# it does not by itself select one-sided testing.
direction_group <- function(tool, shown_if = NULL) {
  list(input = NULL, title = "Your hypothesis", note = direction_note, fields = list(
    list(
      id = "alternative", label = "Which directions will your statistical decision test?", type = "select", path = "target_test.alternative", required = TRUE,
      choices = list(
        greater = "Positive effects only (one-sided test)",
        less = "Negative effects only (one-sided test)",
        two_sided = "Effects in either direction (two-sided test; a directional prediction is still possible)"),
      default_source = paste0("Not filled in for you (for reference: ", tool[["alternative_source"]], ")"),
      shown_if = shown_if
    ),
    list(
      id = "alternative_reason", label = "Why only this direction counts for the decision", help = "Decide before seeing the results. Explain why an effect in the opposite direction would not count as a rejection under this rule; a directional prediction alone does not require a one-sided test.",
      type = "text", optional = TRUE, shown_if = if (is.null(shown_if)) list(field = "alternative", is_one_of = c("greater", "less")) else c(list(list(field = "alternative", is_one_of = c("greater", "less"))), shown_if)
    )
  ))
}

direction_note <- "Test two-sided unless a result in the opposite direction would change nothing you conclude or do. You can predict a direction and still test two-sided."

# E1-E6: pwr's formula or Spower's simulation (forms.yaml,
# basic_method_field). Where the form has a test version (`method`), the
# choice is shown only with the version pwr covers: its default, or the
# form's `basic_method_with` (E2's Student's t-test; Welch's, the default,
# has its own choice of formula or simulation). Fisher's exact test (E5) is
# pwrss's formula only.
basic_method_field <- function(forms, ep_id) {
  field <- forms$basic_method_field
  population <- switch(ep_id,
    E1 = "The ordinary one-sample t-test simulation draws normal scores.",
    E2 = "The ordinary Student two-group t-test simulation draws normal scores with equal population SDs. Welch planning uses its own stated group spreads.",
    E3 = "The ordinary paired t-test simulation draws normal paired scores with the specified standardised mean difference.",
    E4 = "The Pearson correlation simulation draws bivariate normal scores with the specified correlation. Rank-test shape choices, when shown, are separate inputs.",
    E5 = "The simulation draws binary outcomes at each group's specified proportion.",
    E6 = "The simulation draws table counts from the cell probabilities implied by the specified population.",
    NULL)
  field$help <- paste(c(population, field$help), collapse = " ")
  version <- Filter(function(f) identical(f$id, "method"), form_fields(forms$forms[[ep_id]]$groups))
  if (length(version)) field$shown_if <- list(field = "method", is = forms$forms[[ep_id]]$basic_method_with %||% version[[1]][["default"]])
  field
}

# The id of the field that offers a Bayes factor test version (the field
# writing target_test.method), or NULL when the form offers none.
offers_bayes_factor <- function(form) {
  hit <- Filter(function(f) identical(f$path, "target_test.method") && "bayes_factor" %in% names(f$choices), form_fields(form$groups))
  if (length(hit)) hit[[1]]$id
}

# Precision planning (E46): the interval's width instead of power. Both
# goals are the engine's goal type "precision" (build_spec()): with a
# width it finds the sample size, with a sample size the width.
precision_goal_fields <- function(tool) {
  mbess <- list(field = "estimate", is_one_of = c("two_groups", "paired", "one_group", "regression_coefficient"))
  list(
    list(id = "goal", label = "What do you want to find out?", type = "select", required = TRUE,
         choices = list(precision_n = "The sample size for an interval this narrow",
           precision_width = "How narrow the interval would be at a given sample size")),
    list(id = "width", writeup_label = "interval width", label = "Target interval width (upper limit minus lower, in the estimate's own units)",
         help = "For example 0.4 for d (about \u00b10.2), 0.2 for a correlation, or 0.1 for a proportion (about \u00b15 percentage points).",
         type = "number", path = "goal.width", needed_for = "precision_n", min_exclusive = 0),
    # Assurance by default on MBESS's routes (8 November 2026; Departure
    # 25): an interval as narrow as planned only on average is wider than
    # planned in about half of studies. Its value starts empty, as target
    # power does.
    list(id = "width_target", label = "What should the target width promise?", type = "select", required = TRUE,
         choices = list(assurance = "A chance that my interval is no wider than this (assurance)",
           expected = "Only that the interval is this wide on average (MBESS's default)"),
         default = "assurance", default_source = "a stated chance of an interval narrow enough; on average, about half of intervals are wider than planned",
         shown_if = list(list(field = "goal", is = "precision_n"), mbess)),
    list(id = "assurance", label = "Chance that the interval is no wider than that (assurance)",
         help = "As a proportion, for example 0.9: planning then targets a 90% chance of an interval no wider than your target, under the population you specify (MBESS's assurance). Like target power, it is your choice to justify; the result compares 80%, 90% and 95%.",
         type = "number", path = "goal.assurance", required = TRUE, min_exclusive = 0.5, max_exclusive = 1,
         shown_if = list(list(field = "goal", is = "precision_n"), mbess, list(field = "width_target", is = "assurance"))),
    list(id = "assurance_reason", label = "Why this chance", help = "Goes in the write-up; for example \"90% because a second study to narrow the interval is not affordable\".",
         type = "text", optional = TRUE,
         shown_if = list(list(field = "goal", is = "precision_n"), mbess, list(field = "width_target", is = "assurance"))),
    list(id = "n", label = "Number of participants analysed (in total; pairs for paired data)",
         type = "number", path = "goal.n", needed_for = "precision_width", min = 3, integer = TRUE),
    list(id = "conf_level", label = "Confidence level", help = "As a proportion, for example 0.95 for a 95% interval.", type = "number",
         required = TRUE, min_exclusive = 0.5, max_exclusive = 1, default = tool[["conf_level"]], default_source = tool[["conf_level_source"]])
  )
}

# The closing questions every form asks (decision-tree.md, table 2.2).
closing_groups <- function(forms, ep_id, start = list()) {
  form <- forms$forms[[ep_id]]
  tool <- forms$tool_defaults[[form$tool]]
  goals <- list(sample_size = "The sample size I need", power = "The power I'd have at a given sample size")
  # Generic tests have no sample size: the noncentrality reflects it.
  if (isTRUE(form$generic)) goals <- list(power = "The power for this noncentrality", sensitivity = "The noncentrality I'd need for a target power")
  # A meta-analysis (E61): n is the number of studies.
  meta <- isTRUE(form$meta)
  if (meta) goals <- list(sample_size = "The number of studies I need", power = "The power I'd have with a given number of studies")
  # Dyadic data (E44): n is the number of pairs.
  pairs <- identical(form$units, "pairs")
  if (pairs) goals <- list(sample_size = "The number of pairs I need", power = "The power I'd have with a given number of pairs")
  if (isTRUE(form$sensitivity)) goals$sensitivity <- "The smallest effect I'd have a good chance of finding, at a given sample size"
  # "The same" only follows the goal it repeats (E24 has the range alone).
  if (isTRUE(form$sensitivity_without_effect)) goals$sensitivity_curve <- if (isTRUE(form$sensitivity)) "The same, across a range of sample sizes" else "The smallest effect I'd have a good chance of finding, across a range of sample sizes"
  # A justified alpha (JustifyAlpha's optimal_alpha()): the one-sample,
  # paired and two-group t-tests and the correlation (E1-E4).
  if (isTRUE(form$justified_alpha)) goals$justified_alpha <- "A significance level that balances the two errors, at a given sample size"
  goal <- list(id = "goal", label = "What do you want to find out?", type = "select", path = "goal.type", required = TRUE, choices = goals)
  # A form offering a Bayes factor t-test (E1-E3) has no significance
  # level for that version: "power" is the chance of strong evidence.
  bayes_field <- offers_bayes_factor(form)
  no_bayes <- if (!is.null(bayes_field)) list(field = bayes_field, is_not = "bayes_factor")
  # So a justified significance level is offered only with a test that
  # has one (`choices_shown_if`: the choice is hidden otherwise).
  if (!is.null(no_bayes) && !is.null(goals$justified_alpha)) goal$choices_shown_if <- list(justified_alpha = list(no_bayes))
  if (identical(start$situation, "fixed")) {
    goal$default <- if (isTRUE(form$sensitivity)) "sensitivity" else "power"
    goal$default_source <- "you said your sample size is fixed"
  }
  # Whether the sample size is fixed (asked on the start screen until 26
  # October 2026): with the goals that take a sample size, for the
  # write-up ("fixed by resource constraints").
  situation <- list(id = "situation", label = "Is this number of participants fixed?", type = "select",
    choices = list(choose = "No: I'm seeing what power a sample this size gives",
      fixed = "Yes: a participant pool, a budget or a rare group sets it"),
    default = if (identical(start$situation, "fixed")) "fixed" else "choose",
    shown_for_goals = c("power", "sensitivity", "justified_alpha"), optional = TRUE)
  # A card without the smallest-effect goal says so when the sample is
  # fixed, the case that goal is for (coverage audit, 12 November 2026).
  if (!isTRUE(form$sensitivity) && !isTRUE(form$generic) && !isTRUE(form$sensitivity_without_effect)) {
    situation$choice_notes <- list(fixed = paste(
      "This card doesn't yet give the smallest effect a fixed sample could detect. It gives the power at your sample size for the",
      "effect you enter: try the smallest effect that would matter, and a few others, to see which your sample can find."))
  }
  test <- list(
    goal,
    list(id = "power", label = "Target power", help = "The chance your test comes out significant if the effect is the size you enter (0.8 means 80%). Higher power needs more people. Weigh what a missed effect would cost against what recruiting costs; 80% is a habit, not a rule. It is not the chance your hypothesis is true.",
         type = "number", path = "goal.power", needed_for = c("sample_size", "sensitivity"), min_exclusive = 0, max_exclusive = 1,
         # Empty on every card (8 November 2026): the target is the user's
         # choice to justify, and the result compares 80%, 90% and 95%.
         default = NULL, usual = 0.8, shortcuts = c(.8, .9, .95), default_source = target_power_source),
    list(id = "power_reason", label = "Why this target power", help = "Goes in the write-up; for example \"95% because a miss would waste a year of recruitment\".",
         type = "text", optional = TRUE, shown_for_goals = c("sample_size", "sensitivity")),
    list(id = "n", label = "Number of participants analysed",
         type = "number", path = "goal.n", needed_for = c("power", "sensitivity", "justified_alpha"), min = 2, integer = TRUE),
    list(id = "n_max", label = "The largest number of participants you could analyse",
         type = "number", needed_for = "sensitivity_curve", min = 16, integer = TRUE),
    situation,
    list(id = "cost_ratio", label = "How many times worse is a false positive than a missed effect?",
         help = "1 if the two mistakes are equally bad; 4 if a false positive is four times worse (the ratio behind the usual 5% and 80%).",
         type = "number", path = "goal.cost_ratio", needed_for = "justified_alpha", min_exclusive = 0, default = 1,
         default_source = "both mistakes weighted equally"),
    list(id = "prior_odds", label = "How much more likely is the effect to be real than not, before the study?",
         help = "1 if you think it as likely as not. Leave at 1 if you have no view.",
         type = "number", path = "goal.prior_odds", optional = TRUE, shown_for_goals = "justified_alpha", min_exclusive = 0, default = 1),
    list(id = "error_rule", label = "How should the two errors be traded off?", type = "select", path = "goal.error_rule",
         choices = list(minimize = "Make their weighted total as small as possible", balance = "Make the weighted errors equal"),
         default = "minimize", shown_for_goals = "justified_alpha", optional = TRUE),
    list(id = "alpha", label = "Significance level (alpha)", help = "The chance of a significant result when there is no effect. A lower level means fewer false positives and needs more people for the same power. It is not the chance that a significant finding is false.", type = "number", path = "target_test.alpha", required = TRUE,
         # Empty on every card (8 November 2026), as target power is: one
         # click gives the usual level, so choosing it is the user's act.
         min_exclusive = 0, max = 0.5, default = NULL, usual = tool[["alpha"]] %||% 0.05,
         usual_label = sprintf("Use %s, the usual level", format(tool[["alpha"]] %||% 0.05)),
         # .05 is the usual level in psychology and what readers expect; the
         # two stricter levels sit beside it, with when they fit, and the
         # result shows what each costs (12 November 2026).
         shortcuts = c(tool[["alpha"]] %||% 0.05, 0.01, 0.005),
         shortcut_labels = c(sprintf("Use %s, the usual level", format(tool[["alpha"]] %||% 0.05)), "0.01", "0.005"),
         prompt = "0.01 or 0.005 fit a study that runs many tests, or a surprising claim that needs stronger evidence. Results worked out by formula show what each would cost.",
         default_source = sprintf("Empty on every card: choose the level your claim needs; %s is the usual one, %s", format(tool[["alpha"]] %||% 0.05),
           tool[["alpha_source"]]),
         # Not asked when the goal is to find the level (the balance of the
         # two errors): build_spec() gives the engine the usual 0.05 for
         # its comparison row.
         shown_if = Filter(Negate(is.null), list(no_bayes, list(field = "goal", is_not = "justified_alpha")))),
    # Goes in the write-up when given (8 November 2026: asked whatever the
    # level, and optional).
    list(id = "alpha_reason", label = "Why this significance level", help = "Goes in the write-up; for example \"the claim is new, so stronger evidence is wanted\".",
         type = "text", optional = TRUE, shown_if = Filter(Negate(is.null), list(no_bayes, list(field = "goal", is_not = "justified_alpha"))))
  )
  if (isTRUE(form$generic)) test <- Filter(function(f) !f$id %in% c("n", "n_max"), test)
  # No significance test (latent profiles: the BIC chooses the number of
  # profiles), so no alpha to ask for.
  if (isTRUE(form$no_alpha)) {
    test <- Filter(function(f) !f$id %in% c("alpha", "alpha_reason"), test)
    at <- which(vapply(test, function(f) identical(f$id, "power"), logical(1)))
    if (length(at)) {
      test[[at]]$label <- form$power_label %||% "Target chance of success"
      test[[at]]$help <- form$power_help %||% test[[at]]$help
    }
  }
  if (isTRUE(form$precision)) test <- precision_goal_fields(tool)
  if (meta) {
    test <- Filter(function(f) !f$id %in% c("n_max", "situation"), test)
    at <- which(vapply(test, function(f) identical(f$id, "n"), logical(1)))
    test[[at]]$label <- "Number of studies"
  }
  if (pairs) {
    at <- which(vapply(test, function(f) identical(f$id, "n"), logical(1)))
    test[[at]]$label <- "Number of pairs"
  }
  Filter(Negate(is.null), c(list(
    list(input = NULL, title = "What you want to find out", fields = test)),
    list(list(input = NULL, title = "Scientific question (optional)", fields = list(
      list(id = "research_question", label = "What scientific question will this study address?", type = "text", optional = TRUE,
        help = "For example, whether training improves recall enough to change practice. This labels the planning document; it does not choose a statistical test for you.")))),
    if (!isTRUE(form$precision)) claim_groups(start$claim, start$n_tests, isTRUE(start$claim_from_plan)),
    list(
    list(input = NULL, title = "Where your effect size comes from", fields = c(list(
      list(id = "just_type", label = "Source of the effect size", type = "select", path = "effect_justification.type", required = TRUE,
           choices = c(list(
             smallest_effect_of_interest = "The smallest effect that would matter",
             meta_analysis = "A meta-analysis", prior_study = "A previous study", pilot_study = "A pilot study",
             convention = "A convention or rule of thumb (such as Cohen's small, medium or large)",
             own_study_result = "The result of my finished study (observed power)"),
             if (isTRUE(form$sensitivity_without_effect)) list(none = "I can't justify an effect size"))),
      list(id = "just_source", label = "Why this effect size?",
           help = "In your own words: where the number comes from, or why there isn't one. Any length, any language. If you leave it empty, the write-up says no justification was recorded.",
           type = "text", path = "effect_justification.source", optional = TRUE),
      # A pilot is as much one study's estimate as a published one, and
      # less precise, so it gets the same question.
      list(id = "just_adjustment", label = "How you adjusted it", help = "An estimate from one study is uncertain, and published estimates are more likely to be ones that came out large. Plan for a value you can defend: the reported estimate with your reason for trusting it, the lower end of its interval (safeguard power), or a smaller value supported by other evidence. If you kept the estimate unchanged, say why.",
           type = "text", path = "effect_justification.adjustment", needed_if_just = c("prior_study", "pilot_study"),
           # Said where the problem is listed, since the box appears only
           # once a pilot or previous study is chosen (C-15).
           empty_message = "\u201cHow you adjusted it\u201d is empty. An effect from one study (a pilot or a previous study) is uncertain, so powerkit asks how you allowed for that: say in a sentence, in the box under \u201cSource of the effect size\u201d, whether you planned for a smaller value or why you kept the estimate unchanged. Any wording is fine.",
           shown_if = list(list(field = "just_type", is_one_of = c("prior_study", "pilot_study")), list(field = "sg_use", is_not = "yes"),
             list(field = "sg_use", is_not = "telescopes")))
    ), safeguard_fields(form$base$template), heterogeneity_fields(form$base$template))),
    # A single time series has no participants to lose (`no_attrition`).
    if (!isTRUE(form$generic) && !meta && !isTRUE(form$no_attrition)) list(input = NULL, title = "Participants you expect to lose", fields = list(
      list(id = "attrition", label = "Proportion you expect to lose", help = "For example 0.1 for 10%. This only adds a recruitment buffer for the analysed sample; it does not model missing data or your method for handling them. If unsure, compare plausible loss rates rather than treating zero as known.", type = "number",
           path = "options.attrition", optional = TRUE, min = 0, max_exclusive = 1)
    )),
    # A fixed default seed, so the same answers give the same result
    # (judgement-calls.md B15); the user can change it.
    list(input = NULL, title = "Random seed", fields = list(
      list(id = "seed", label = "Random seed", help = sprintf("A whole number, used when power is simulated, so the same seed gives the same result; empty = %s.", forms$default_seed),
           type = "number", path = "options.seed", optional = TRUE, integer = TRUE, min = 1, max = 2147483647,
           default = forms$default_seed, default_source = "powerkit's fixed default seed (judgement-calls.md B15)")
    )),
    # Guess first (optional teaching mode): the guess is shown next to the
    # answer and goes nowhere else (no spec path, not in the exports).
    list(input = NULL, title = "Guess the answer first (optional, to learn how power behaves)", note = guess_note, fields = list(
      list(id = "guess", label = "Your guess", type = "number", optional = TRUE, min = 0,
           shown_if = list(field = "goal", is_not = "sensitivity_curve"))
    ))
  )))
}

# Safeguard power (Perugini, Gallucci & Costantini, 2014): for an effect
# size from one earlier study, plan with the lower end of a confidence
# interval around it. The engine works the interval out (psych); the form
# asks for the earlier study's sample size and the protection wanted.
safeguard_sizes <- list(one_sample_t = "n", paired_t = "n", correlation = "n", independent_t = c("n1", "n2"))

safeguard_fields <- function(template) {
  sizes <- safeguard_sizes[[template %||% ""]]
  if (is.null(sizes)) return(list())
  from_one_study <- list(field = "just_type", is_one_of = c("prior_study", "pilot_study"))
  using <- list(from_one_study, list(field = "sg_use", is = "yes"))
  size_field <- function(id, label, min) list(id = paste0("sg_", id), label = label, type = "number", integer = TRUE, min = min,
    required = TRUE, path = paste0("effect_justification.safeguard.", id), shown_if = using)
  # Small telescopes (Simonsohn, 2015), for a replication of a published
  # study: the original's sample size sets d33, the effect it could detect
  # a third of the time.
  telescoping <- list(list(field = "just_type", is = "prior_study"), list(field = "sg_use", is = "telescopes"))
  original_field <- function(id, label, min) list(id = paste0("st_", id), label = label, type = "number", integer = TRUE, min = min,
    required = TRUE, path = paste0("effect_justification.small_telescopes.", id), shown_if = telescoping)
  c(list(
    list(id = "sg_use", label = "How to plan from this one study", type = "select", default = "no",
         help = paste("One study's estimate is uncertain, and may be too large. Safeguard power plans with the lower end of a",
                      "confidence interval around it instead, so the study is protected if the true effect is smaller (Perugini, Gallucci & Costantini, 2014).",
                      "For a replication, small telescopes plans the study to test whether the effect is smaller than the original study could have",
                      "detected (Simonsohn, 2015). Enter the earlier study's effect size above as it was reported."),
         choices = list(no = "Plan with the effect size as it is", yes = "Use the safeguard effect size",
                        telescopes = "This is a replication: plan it by small telescopes"),
         choices_shown_if = list(telescopes = list(list(field = "just_type", is = "prior_study"))),
         choice_notes = list(telescopes = paste("For a close replication of one original study. The replication is planned to test whether the effect",
           "is smaller than d33, the effect the original study had a one-in-three chance to detect, if the true effect is zero.",
           "A result below d33 means the original study was too small to have reliably seen an effect that size; it doesn't show the",
           "original was a false positive, and it says something about the original only if the replication recreated its conditions",
           "(the same manipulation, of similar strength, measured the same way, in a comparable sample).",
           "The test is Student's t-test (or the correlation's test), whichever version you chose above, so it matches the original;",
           "report Welch's test beside it if the groups' spreads may differ.")),
         shown_if = from_one_study)),
    if (identical(sizes, "n")) list(size_field("n", "How many people the earlier study had", 4))
    else list(size_field("n1", "People in group 1 of the earlier study", 2), size_field("n2", "People in group 2 of the earlier study", 2)),
    if (identical(sizes, "n")) list(original_field("n", "How many people the original study had", 4))
    else list(original_field("n1", "People in group 1 of the original study", 2), original_field("n2", "People in group 2 of the original study", 2)),
    # d33 uses the original's own significance level, not the replication's.
    list(list(id = "st_alpha", label = "Significance level the original study used", type = "number",
         help = "Two-sided, as the original study tested it; usually 0.05. It sets d33 only: the replication's own significance level is set above.",
         path = "effect_justification.small_telescopes.alpha", optional = TRUE, default = 0.05, min_exclusive = 0, max_exclusive = 0.5,
         default_source = "The usual two-sided level; change it if the original study used another", shown_if = telescoping)),
    list(list(id = "sg_protection", label = "Protection against the estimate being too large", type = "number",
         help = "0.8 uses the lower end of a 60% confidence interval; 0.95 uses the lower end of a 90% one.",
         path = "effect_justification.safeguard.protection", required = TRUE, default = 0.8, min_exclusive = 0.5, max_exclusive = 1,
         default_source = "Perugini, Gallucci & Costantini (2014)", shown_if = using)))
}

# Effects that vary between studies, for the t-tests (Kenny & Judd, 2019)
# and a Pearson correlation (McShane & Bockenholt, 2014, on Fisher's z):
# the SD of the true effect around the one planned for, which then is the
# average effect. Variation is an explicit optional scenario; a new plan
# starts empty (the usual fixed-effect calculation). Stored values keep
# their original meaning (Departures 23 and 24, revised 10 November 2026).
heterogeneity_field_templates <- c("independent_t", "one_sample_t", "paired_t", "correlation")

heterogeneity_fields <- function(template) {
  if (!isTRUE(template %in% heterogeneity_field_templates)) return(list())
  # The formulas are for the test by formula, for power, the sample size
  # or the smallest detectable effect.
  common <- list(list(field = "sg_use", is_not = "telescopes"),
    list(field = "calc_method", is_not = "simulation"), list(field = "welch_method", is_not = "simulation"),
    list(field = "goal", is_not = "sensitivity_curve"), list(field = "goal", is_not = "justified_alpha"))
  if (identical(template, "correlation")) {
    return(list(list(id = "het_tau", label = "How much might the true correlation vary between studies? (as an SD on Fisher's z)",
      fold = "The correlation may differ from study to study (optional)",
      type = "number", optional = TRUE, min = 0, max = 2, path = "population.tau",
      default_source = "Starts empty: power for the correlation entered; choose variation only to average across differing study correlations",
      help = paste("Optional. Leave empty to plan for the correlation you entered. If you enter a value, the answer is averaged over",
        "studies whose true correlations differ by this much (an SD on Fisher's z, which is close to r for small values;",
        "McShane & Bockenholt, 2014). That changes the question, and it can raise or lower power. The best source is a",
        "meta-analysis of this correlation that reports tau on Fisher's z. powerkit knows of no published reference values on",
        "this scale; 0.025, 0.075 and 0.125 are a quarter of r = .1, .3 and .5, the rule Kenny and Judd (2019) use for d,",
        "and are only illustrations. The results show the answer at each of them and at your value."),
      shown_if = c(list(list(field = "method", is = "pearson")), common))))
  }
  list(list(id = "het_tau", label = "How much might the true effect vary between studies? (as an SD in d)",
    type = "number", optional = TRUE, min = 0, max = 2, path = "population.tau",
    default_source = "Starts empty: power for the effect entered; choose variation only to average across differing study effects",
    fold = "The effect may differ from study to study (optional)",
    help = paste("Optional. Leave empty to plan for the effect you entered. If you enter a value, the answer is averaged over",
      "studies whose true effects differ by this much (as an SD in d), which changes the question; it can raise or lower",
      "power. The best source is a meta-analysis of this effect that reports tau. Kenny and Judd (2019) use 0.05, 0.125",
      "and 0.20 as examples; they are a quarter of Cohen's 0.2, 0.5 and 0.8, so treat them as illustrations, not estimates",
      "for your field. The results show the answer at each of them and at your value. It needs equal SDs in the two groups."),
    shown_if = c(list(list(field = "method", is_one_of = c("t_test", "student_t", "welch_t"))), common)))
}

# ANOVA and ANCOVA by its effect size: the "Units of the means"
# choice gains "an effect size" (partial eta-squared, as G*Power takes it;
# the engine then uses pwrss's F test), which hides the means and the SDs
# and shows the partial eta-squared instead. The test version stays: the
# engine explains that Welch's F and the Kruskal-Wallis test need means.
eta_squared_templates <- c("oneway_between", "2x2_between", "factorial_between", "factorial_three", "oneway_ancova",
                           "factorial_ancova", "oneway_within", "2x2_mixed", "mixed")
# Repeated-measures and mixed ANOVA: partial eta-squared means different
# things there, so the screen asks which kind it is (required, no default)
# and, for an effect size planned the G*Power way, the correlation between
# measurements.
eta_squared_mixed_templates <- c("oneway_within", "2x2_mixed", "mixed")

with_eta_squared <- function(group, template) {
  if (!isTRUE(template %in% eta_squared_templates)) return(group)
  by_means <- list(field = "metric", is_not = "eta_squared")
  hide <- function(f) {
    if (isTRUE(f$effect) || isTRUE(f$in_effect_text) || identical(f$id, "sd_mode")) {
      f$shown_if <- c(shown_if_conditions(f), list(by_means))
    }
    # The table of means offers the effect size in its place, so the
    # option isn't only a choice under "Units of the means" (12 November 2026).
    if (identical(f$type, "table") && identical(f$path, "population.means")) {
      f$alternative <- list(field = "metric", value = "eta_squared",
        label = if ("f" %in% conversion_choices[[template]]) "Give partial eta-squared or Cohen's f instead" else "Give partial eta-squared instead")
    }
    f
  }
  mixed <- template %in% eta_squared_mixed_templates
  by_effect <- list(field = "metric", is = "eta_squared")
  fields <- list()
  for (f in group$fields) {
    if (identical(f$id, "metric")) {
      f$choices <- c(f$choices, list(eta_squared = if ("f" %in% conversion_choices[[template]]) "An effect size: partial eta-squared or Cohen's f, as in G*Power" else "An effect size: partial eta-squared, as in G*Power"))
      source <- if (mixed) list(list(
        id = "eta_source", label = "Where does your partial eta-squared come from?", type = "select", required = TRUE,
        path = "population.eta_source", shown_if = by_effect,
        choices = list(published = "A published repeated-measures or mixed ANOVA (as SPSS, R or JASP report it)",
                       planned = "An effect size planned the G*Power way, without the correlation"),
        help = paste("The two are different numbers for the same study. A published value already includes the correlation",
                     "between measurements. G*Power's default effect size doesn't, so you then give the correlation as well.")))
      fields <- c(fields, list(f), source, list(list(
        id = "eta_squared", label = "Partial eta-squared of the effect you test", writeup_label = "partial eta-squared",
        type = "number", path = "population.eta_squared", effect = TRUE, min_exclusive = 0, max_exclusive = 1,
        shown_if = list(field = "metric", is = "eta_squared"),
        help = paste("For one factor, its eta-squared. powerkit treats it as the true effect, as G*Power does. A published value",
                     "is that study's estimate and tends to be too large; omega-squared, if reported, is less biased. Groups are",
                     "taken as equal in size, and the test is the ANOVA F test (Welch's F and rank tests need the means).")
      )))
    } else {
      fields <- c(fields, list(hide(f)))
    }
  }
  at <- which(vapply(fields, function(f) identical(f$id, "eta_squared"), logical(1)))
  if (length(at) == 1 && template %in% c("oneway_ancova", "factorial_ancova")) {
    fields[[at]]$help <- paste("The partial eta-squared of the effect you test, from an ANCOVA with the same covariates. It already",
      "allows for them, so their R-squared isn't needed; their number still counts, as in G*Power. powerkit treats it as the",
      "true effect; a published value tends to be too large. Groups are taken as equal in size.")
  }
  if (length(at) == 1 && identical(template, "factorial_three")) {
    fields[[at]]$help <- paste("The partial eta-squared of the effect you test, as in G*Power. This is for three factors that are all",
      "between participants (different people in every cell); with a within-participants factor, give the means instead.",
      "powerkit treats it as the true effect; a published value tends to be too large. Groups are taken as equal in size.")
  }
  if (mixed) {
    if (length(at) == 1) {
      fields[[at]]$help <- paste("The partial eta-squared of the effect you test. powerkit treats it as the true effect, as G*Power does;",
        "a published value tends to be too large. Groups are equal in size, and sphericity is assumed.")
      fields <- append(fields, list(list(
        id = "eta_r", label = "Correlation between measurements (the same for every pair)", writeup_label = "correlation between measurements",
        type = "number", path = "population.r", required = TRUE, min = -1, max = 1, in_effect_text = TRUE,
        shown_if = list(by_effect, list(field = "eta_source", is = "planned"))
      )), after = at)
    }
  }
  group$fields <- fields
  group
}

# Effect-size conversion: a published effect in another form (a t or F
# statistic, r, d or an odds ratio), converted by the engine into the
# card's own effect size (psych's t2d() for t and F into d or d_z, the
# effectsize package for the rest). The forms each card
# accepts follow the engine's list of conversions (a test in test-results.R
# checks they agree). The fields go straight after the effect field, which
# is hidden while a conversion is chosen.
conversion_choices <- list(
  independent_t = c("t", "F", "r", "odds_ratio"),
  one_sample_t = "t",
  paired_t = c("t", "F"),
  correlation = c("t", "F", "d", "odds_ratio"),
  oneway_between = c("F", "f"),
  "2x2_between" = c("F", "f"),
  factorial_between = c("F", "f"),
  factorial_three = c("F", "f"),
  oneway_ancova = c("F", "f"),
  factorial_ancova = c("F", "f"),
  oneway_within = "F",
  "2x2_mixed" = "F",
  mixed = "F",
  two_proportions = c("odds_ratio", "risk_ratio")
)

conversion_labels <- list(
  t = "A t statistic", F = "An F statistic with one numerator df (two groups or two conditions)",
  r = "A correlation r", d = "Cohen's d (two groups)", odds_ratio = "An odds ratio",
  f = "Cohen's f", risk_ratio = "A risk ratio"
)

# `when`: the effect field's own conditions (for example, not while the
# effect is given in the measure's own units).
conversion_fields <- function(template, when = list()) {
  from <- conversion_choices[[template]]
  labels <- conversion_labels[from]
  if (isTRUE(template %in% eta_squared_templates)) labels$F <- "An F statistic, with its two degrees of freedom"
  proportions <- identical(template, "two_proportions")
  if (proportions) {
    labels$odds_ratio <- "An odds ratio (group 2's odds of 'yes' over group 1's), with group 1's proportion above"
    labels$risk_ratio <- "A risk ratio (group 2's proportion over group 1's), with group 1's proportion above"
  }
  # Cohen's f is G*Power's own input for an ANOVA, not a published form:
  # say so where it is offered, so it is found.
  has_f <- "f" %in% from
  if (has_f) labels$f <- "Cohen's f (the effect size G*Power asks for)"
  choices <- c(list(none = if (has_f) "No: I'll enter partial eta-squared" else "No: I'll enter the effect size myself"), labels)
  sets <- stats::setNames(lapply(from, function(x) list(list(path = "effect_justification.conversion.from", value = x))), from)
  planning <- c(when, list(list(field = "goal", is_one_of = c("power", "sample_size"))),
    # A published F from a repeated-measures ANOVA gives its own kind of
    # partial eta-squared, so it is offered only for that kind.
    if (isTRUE(template %in% eta_squared_mixed_templates)) list(list(field = "eta_source", is = "published")))
  converting <- c(planning, list(list(field = "conv_from", is_one_of = from)))
  sizes <- if (identical(template, "independent_t")) {
    # Two groups of different sizes: the sizes change d (engine,
    # convert_effect()); left empty, the groups are taken as equal.
    sized <- c(converting, list(list(field = "conv_from", is_one_of = c("t", "F", "r"))))
    help <- "Leave both empty if the published groups were the same size."
    list(
      list(id = "conv_n1", label = "Group 1's size in the published study (optional)", type = "number", integer = TRUE, min = 2,
           conversion = TRUE, path = "effect_justification.conversion.n1", shown_if = sized, help = help),
      list(id = "conv_n2", label = "Group 2's size in the published study (optional)", type = "number", integer = TRUE, min = 2,
           conversion = TRUE, path = "effect_justification.conversion.n2", shown_if = sized, help = help))
  }
  c(Filter(Negate(is.null), list(
    list(id = "conv_from", label = if (has_f) "Do you have Cohen's f or an F statistic instead?" else "Is your effect size published in another form?", type = "select", default = "none",
         choices = choices, sets = sets, shown_if = planning,
         help = if (proportions) paste(
           "powerkit works out group 2's proportion from the ratio and group 1's proportion (an odds ratio with the effectsize",
           "package, Ben-Shachar, L\u00fcdecke & Makowski, 2020) and shows the result. An odds ratio from a logistic regression",
           "with covariates is a conditional one, usually further from 1 than the two groups' raw odds ratio. Published effects",
           "tend to be larger than the true effect: say how you adjusted it.") else paste("powerkit converts it with the psych package (a t or F statistic, by the formula in Lakens, 2013) or the",
                      "effectsize package (Ben-Shachar, L\u00fcdecke & Makowski, 2020) and shows the result and the function used. Published effects",
                      "tend to be larger than the true effect: say how you adjusted it, or use safeguard power below if it comes",
                      "from one study.")),
    list(id = "conv_value", label = "The published value", type = "number", required = TRUE, conversion = TRUE,
         path = "effect_justification.conversion.value", shown_if = converting),
    if (isTRUE(template %in% eta_squared_templates)) {
      list(id = "conv_df1", label = "Its first degrees of freedom (the effect's df, the first number in F(df1, df2))", type = "number",
           integer = TRUE, min = 1, conversion = TRUE, required = TRUE, path = "effect_justification.conversion.df",
           shown_if = c(converting, list(list(field = "conv_from", is = "F"))))
    },
    list(id = "conv_df", label = "Its error degrees of freedom (the second df of F, or the df of t)", type = "number", integer = TRUE, min = 1, conversion = TRUE,
         required = TRUE, path = "effect_justification.conversion.df_error",
         shown_if = c(converting, list(list(field = "conv_from", is_one_of = c("t", "F")))))
  )), sizes)
}

with_conversion <- function(group, template) {
  if (is.null(conversion_choices[[template %||% ""]])) return(group)
  # A field marked no_conversion (the two-group card's point-biserial r)
  # is another way to give the effect, not the one a conversion fills.
  at <- which(vapply(group$fields, function(f) isTRUE(f$effect) && !isTRUE(f$no_conversion) &&
    grepl("^population\\.(d|dz|r|eta_squared|p2)$", f$path %||% ""), logical(1)))
  if (length(at) != 1) return(group)
  effect <- group$fields[[at]]
  when <- shown_if_conditions(effect)
  effect$shown_if <- c(when, list(list(field = "conv_from", is_one_of = c("none", ""))))
  group$fields[[at]] <- effect
  group$fields <- append(group$fields, conversion_fields(template, when), after = at)
  group
}

guess_note <- paste(
  "Before you press \u201cCalculate\u201d, write down what you expect:",
  "the number of participants (for the sample size), the power as a percentage (for power),",
  "or the size of the smallest effect you could detect. Your guess is shown next to the answer;",
  "it isn't part of the plan, the R script or the write-up."
)

# The claim, on the input screen (on the start screen until 26 October
# 2026): one test unless the user says otherwise, with a note for each of
# the other claims, and the number of tests for "any of several" (which
# divides alpha between them: Bonferroni; docs/decisions.md, 18 October
# 2026) and for "all of several" (which raises each test's target power so
# that all succeed together with the target power; docs/decisions.md, 19
# October 2026). From a plan or an older project, it starts at the claim
# given then. It is in view on the input screen (12 November 2026): the
# multiple-testing question is one the usual tools never ask. "related"
# (12 November 2026) is for a researcher who holds the error-statistical
# view that separate claims from a related group of tests need a
# correction (Mayo, 2018): the same Bonferroni division as "any".
claim_choices <- list(
  one = "One test: my conclusion rests on this test alone",
  each = "Several claims, each standing on its own (no correction)",
  related = "Several claims from a related group of tests, corrected as a group (Bonferroni)",
  any = "Any of several tests: the claim holds if at least one is significant",
  all = "All of several tests: the claim needs every one to be significant"
)

claim_notes <- function() list(
  each = paste(
    "You said each test supports its own claim. Power this test on its own; run the input screen again for each of the others.",
    "This setting applies no correction across the claims (Rubin, 2021); it does not control the chance of any false positive across the collection. If any positive test would count towards one conclusion, choose the any-test option instead; if you want a correction because the tests form a related group, choose the corrected option.",
    philosophy_note
  ),
  related = paste(
    "You said each test supports its own claim, and that the tests form a related group you want to correct for, such as several outcomes of the same treatment.",
    "powerkit divides your significance level by the number of tests (Bonferroni) and uses that for this test; plan each of the others the same way.",
    "This follows the error-statistical view that a related group of tests needs a correction (Mayo, 2018, pp. 275\u2013276); under Rubin's (2021) view, separate claims need none."
  ),
  any = "You said your claim is about the set: it is supported if any one of the tests is significant. So the chance of a false positive is spread over the set: powerkit divides your significance level by the number of tests (Bonferroni) and uses that for this test.",
  all = paste(
    "You said your claim needs every test to be significant. No correction to the significance level is needed, but the joint chance cannot exceed the least powerful individual test:",
    "two independent tests at 0.8 each succeed together only about 0.8 x 0.8 = 0.64 of the time.",
    "Powerkit raises each test's target power using the rule you choose below. Independent tests use the product rule; unknown dependence uses a sufficient bound that may be conservative. Both need defensible common population assumptions. Where supported, a joint-power simulation models the tests together."
  )
)

claim_groups <- function(claim = "one", n_tests = NULL, from_plan = FALSE) {
  claim <- claim %||% "one"
  if (!claim %in% names(claim_choices)) claim <- "one"
  fields <- list(
    list(id = "claim", label = "How many tests does your conclusion rest on?", type = "select",
         choices = claim_choices, default = claim, choice_notes = claim_notes(),
         help = if (isTRUE(from_plan)) "Set by your study plan, so that every analysis in it agrees. To change it, change the plan's claim." else
           "Most studies rest on one test. If yours runs several, say how they count: it can change the significance level or the power each test needs."),
    list(id = "n_tests", label = "Number of tests", type = "number", required = TRUE, min = 2, integer = TRUE,
         default = n_tests, applies_if_claim = c("related", "any", "all"),
         shown_if = list(list(field = "claim", is_not = "one"), list(field = "claim", is_not = "each"))),
    list(id = "all_dependence", label = "Planning for all tests: what can you assume?", type = "select", required = TRUE, default = "unknown",
         shown_for_goals = c("sample_size", "sensitivity"),
         default_source = "the sufficient union-bound target avoids assuming independence; the product rule remains an explicit option",
         choices = list(independent = "Independent tests: use the product of their powers",
           unknown = "Dependence unknown: use a sufficient target that may be conservative"),
         shown_if = list(field = "claim", is = "all"),
         help = "If you can't say how the tests' results are related, choose \"unknown\": measuring the same participants does not make the tests independent. powerkit then sets each test's power high enough that all of them succeed together at least as often as your target, whatever the relationship. This is a safe bound: the true chance is usually higher.")
  )
  list(list(input = NULL, title = "Your claim", fields = fields))
}

# Whether separate claims need a correction depends on one's philosophy of
# significance testing (Rubin, 2024, Journal of Trial and Error; Mayo, 2018).
philosophy_note <- paste(
  "Not everyone agrees: whether to correct depends on your view of significance testing.",
  "Under the more common error-statistical view, a correction may be expected when the tests form a related group, such as several outcomes of the same treatment,",
  "especially if some of them could go unreported (Mayo, 2018, pp. 275\u2013276). Rubin (2024, Journal of Trial and Error) sets out the difference."
)

claim_tests <- function(values) {
  # One test, or claims standing on their own: no set of tests, whatever
  # number was typed before the claim was changed back.
  if (isTRUE(values$claim %in% c("one", "each"))) return(NA)
  k <- parse_number(values$n_tests)
  if (length(k) != 1 || is.na(k) || k < 2) NA else k
}

# One line for the result screen on how the claim was handled, or NULL.
# `goal`: the goal type; the target power was raised only for the sample
# size and the smallest detectable effect.
claim_result_note <- function(values, alpha_used, goal = NULL) {
  k <- claim_tests(values)
  switch(
    values$claim %||% "one",
    one = NULL,
    each = "Your claim: several claims, each standing on its own. This result is for one test, with no correction; work out each of the others the same way.",
    related = if (is.null(alpha_used)) {
      sprintf("Your claim: %s related tests, corrected as a group. A Bayes factor test has no significance level, so powerkit applies no correction.", values$n_tests)
    } else sprintf(
      "Your claim: %s related tests, each its own claim, corrected as a group. The significance level for this test is %s divided by %s (Bonferroni): %s. Work out each of the others the same way.",
      values$n_tests, format(signif(alpha_used * as.numeric(values$n_tests), 3)), values$n_tests, format(signif(alpha_used, 3))
    ),
    any = if (is.null(alpha_used)) {
      # Bayes factor tests have no significance level to divide.
      sprintf("Your claim: any of %s tests. A Bayes factor test has no significance level, so powerkit applies no correction; the more tests you run, the more chances one of them has to give misleading evidence.", values$n_tests)
    } else sprintf(
      "Your claim: any of %s tests. The significance level for this test is %s divided by %s (Bonferroni): %s. The power shown is for this test at its adjusted alpha, not the chance that any test in the set succeeds.",
      values$n_tests, format(signif(alpha_used * as.numeric(values$n_tests), 3)), values$n_tests, format(signif(alpha_used, 3))
    ),
    all = if (!is.na(k) && isTRUE(goal %in% c("sample_size", "sensitivity"))) {
      target <- parse_number(values$power)
      if (identical(values$all_dependence, "unknown")) return(sprintf(
        "Your claim needs all %s tests. With dependence unknown, this test is planned at 1 - (1 - %s)/%s = %s power. If every test reaches at least this power under the same population assumptions, the chance that all succeed is at least %s by the union bound (Blitzstein & Hwang, 2019). This may be conservative; significance levels are unchanged. It is a sufficient bound, not an estimate of joint power. Conditional power among valid fits alone does not establish it when fits fail.",
        whole(k), format(target), whole(k), format(signif(claim_power(target, values), 4)), format(target)))
      sprintf(paste(
        "Your claim: all of %s tests. So that all of them succeed together with a chance of %s, this test is planned at %s^(1/%s) = %s power; plan each of the others at the same power.",
        "This assumes every test reaches at least the stated power under the same population assumptions and their significance decisions are independent. This calculation does not verify the other tests. Related tests can have a lower or higher joint chance; this calculation does not guarantee the target for them. Where supported, use the study plan's joint-power simulation.",
        "Another approach raises each test's significance level instead (a \"reverse Bonferroni\": Francis & Thunell, 2021); powerkit doesn't do that."),
        whole(k), format(target), format(target), whole(k), format(signif(claim_power(target, values), 3)))
    } else {
      "Your claim: all of several tests. The power shown is for this test alone. If the tests are independent, the chance that every test succeeds is the product of their powers (for two tests at 0.8, 0.64). For related tests it can be lower or higher; a joint-power simulation is needed to model their dependence."
    }
  )
}

# Alpha for this test: the significance level entered, divided by the
# number of tests when the claim is "any of several".
claim_alpha <- function(alpha, values) {
  k <- claim_tests(values)
  if (identical(values$claim, "all") || is.na(k)) return(alpha)
  alpha / k
}

# Target power for this test: when the claim is "all of several", the
# k-th root of the target, so that k independent tests planned this way
# all succeed with the target power (power^k = target).
claim_power <- function(power, values) {
  k <- claim_tests(values)
  if (!identical(values$claim, "all") || is.na(k) || is.null(power)) return(power)
  engine_function("all_tests_target")(power, k, if (identical(values$all_dependence, "unknown")) "unknown" else "independent")
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

# Comma-separated numbers on one line (a one-way ANOVA's group means).
parse_numbers <- function(x) {
  if (blank(x)) return(numeric())
  vapply(trimws(strsplit(as.character(x), ",", fixed = TRUE)[[1]]), parse_number, numeric(1), USE.NAMES = FALSE)
}

parse_table <- function(x) {
  if (blank(x)) return(NULL)
  lines <- trimws(strsplit(as.character(x), "\n", fixed = TRUE)[[1]])
  lines <- lines[nzchar(lines)]
  lapply(lines, function(l) vapply(trimws(strsplit(l, ",", fixed = TRUE)[[1]]), parse_number, numeric(1), USE.NAMES = FALSE))
}

# Whether a field applies, given the goal, the justification and any other
# choice it depends on (`shown_if`: shown only when another field `is`, or
# `is_not`, a given value; an empty choice counts as no value; a list of
# such conditions must all hold).
field_applies <- function(field, values) {
  # The number of tests: only for a claim about a set (an empty claim is
  # one test).
  if (!is.null(field$applies_if_claim)) return(isTRUE(values$claim %in% field$applies_if_claim))
  for (cond in shown_if_conditions(field)) {
    if (!is.null(cond$any)) {
      if (!any(vapply(cond$any, function(x) field_applies(list(shown_if = x), values), logical(1)))) return(FALSE)
      next
    }
    current <- values[[cond$field]]
    current <- if (blank(current)) "" else as.character(current)
    if (!is.null(cond[["is"]]) && !identical(current, cond[["is"]])) return(FALSE)
    if (!is.null(cond[["is_not"]]) && identical(current, cond[["is_not"]])) return(FALSE)
    if (!is.null(cond[["is_one_of"]]) && !current %in% cond[["is_one_of"]]) return(FALSE)
  }
  if (!is.null(field$needed_for)) return(isTRUE(values$goal %in% field$needed_for))
  if (!is.null(field$shown_for_goals)) return(isTRUE(values$goal %in% field$shown_for_goals))
  if (!is.null(field$needed_if_just)) return(isTRUE((values$just_type %||% "") %in% field$needed_if_just))
  TRUE
}

# A field's `shown_if` as a list of conditions (one, or several that must
# all hold).
shown_if_conditions <- function(field) {
  if (is.null(field$shown_if)) return(list())
  if (!is.null(field$shown_if$field)) list(field$shown_if) else field$shown_if
}

quote_label <- function(field) sprintf("“%s”", field$label)

# Problems the screen can find before the engine sees the spec, in plain
# English, naming each field by its label.
form_problems <- function(fields, values) {
  values <- expand_level_counts(fields, values)
  problems <- character()
  # Each problem is named by its field's id, so the screen can show it next
  # to the field as well as in the list.
  add <- function(message) problems <<- c(problems, stats::setNames(message, f$id))
  for (f in fields) {
    if (!field_applies(f, values)) next
    v <- values[[f$id]]
    # A choice offered only with some other answers (`choices_shown_if`).
    hidden_choice <- if (!blank(v)) f$choices_shown_if[[as.character(v)]]
    if (!is.null(hidden_choice) && !field_applies(list(shown_if = hidden_choice), values)) {
      add(sprintf("%s: \"%s\" isn't available with the other answers you chose. Choose another.", quote_label(f), f$choices[[as.character(v)]]))
      next
    }
    # Required: marked so, an effect size, or needed for the goal chosen.
    needed <- isTRUE(f$required) || isTRUE(f$effect) || !is.null(f$needed_for) || !is.null(f$needed_if_just)
    if (blank(v)) {
      if (effect_optional(f, values) || source_not_asked(f, values)) next
      if (isTRUE(f$effect)) {
        add(sprintf("%s is empty. Enter the value you expect; powerkit doesn't fill in effect sizes.", quote_label(f)))
      } else if (needed) {
        add(f$empty_message %||% sprintf("%s is empty.", quote_label(f)))
      }
      next
    }
    if (identical(f$type, "number")) {
      x <- parse_number(v)
      if (is.nan(x)) {
        add(sprintf("%s should be a number written with a decimal point, such as 0.3.", quote_label(f)))
        next
      }
      # A percentage typed where a proportion is asked for (80 for 80%
      # power, 5 for a 5% significance level): say what to type instead.
      top <- f$max_exclusive %||% f[["max"]]
      bottom <- f$min_exclusive %||% f[["min"]]
      if (!is.null(top) && top <= 1 && !is.null(bottom) && bottom >= 0 && x >= 2 && x <= 100) {
        add(sprintf("%s is entered as a proportion between 0 and 1: for %s%%, type %s.", quote_label(f), format(x), format(x / 100)))
        next
      }
      if (!is.null(f[["min"]]) && x < f[["min"]]) add(sprintf("%s must be at least %s.", quote_label(f), f[["min"]]))
      if (!is.null(f[["max"]]) && x > f[["max"]]) add(sprintf("%s must be at most %s.", quote_label(f), f[["max"]]))
      if (!is.null(f$min_exclusive) && x <= f$min_exclusive) add(sprintf("%s must be more than %s.", quote_label(f), f$min_exclusive))
      if (!is.null(f$max_exclusive) && x >= f$max_exclusive) add(sprintf("%s must be less than %s.", quote_label(f), f$max_exclusive))
      if (isTRUE(f$integer) && x != round(x)) add(sprintf("%s must be a whole number.", quote_label(f)))
    }
    if (identical(f$type, "levels")) {
      lv <- parse_levels(v)
      if (length(lv) < 2) add(sprintf("%s needs at least two names, separated by commas.", quote_label(f)))
      if (anyDuplicated(lv)) add(sprintf("%s has the same name twice.", quote_label(f)))
    }
    if (identical(f$type, "numbers")) {
      xs <- parse_numbers(v)
      if (any(is.nan(xs) | is.na(xs))) {
        add(sprintf("%s: every entry should be a number written with a decimal point, such as 10.5, separated by commas.", quote_label(f)))
      } else if (!is.null(f$per_levels) && length(xs) != length(parse_levels(values[[f$per_levels]]))) {
        add(sprintf("%s should have %d numbers, one for each name you gave, in the same order.", quote_label(f), length(parse_levels(values[[f$per_levels]]))))
      }
    }
    if (identical(f$type, "table")) {
      tb <- parse_table(v)
      if (any(vapply(tb, function(r) any(is.nan(r) | is.na(r)), logical(1)))) {
        add(sprintf("%s: every entry should be a number written with a decimal point, such as 0.25.", quote_label(f)))
      } else {
        # Rows and columns follow two level fields: X_levels and Y_levels
        # unless the field names others (`rows_from`, `cols_from`).
        # `rows_from` may name two level fields: one line per combination,
        # the first's levels slowest (E56: A by B, with C's levels across).
        rows <- prod(vapply(unlist(f$rows_from %||% "X_levels"), function(id) length(parse_levels(values[[id]])), integer(1)))
        cols <- length(parse_levels(values[[f$cols_from %||% "Y_levels"]]))
        if (length(tb) != rows || any(lengths(tb) != cols)) {
          add(sprintf("%s should have %d lines (one per %s) of %d numbers each (one per %s).", quote_label(f), rows,
                      f$rows_name %||% "category of the first variable", cols, f$cols_name %||% "category of the second"))
        }
      }
    }
  }
  scenario_problem <- if (!blank(values$scenario_library)) tryCatch({
    read_scenario_library(values$scenario_library, fields)
    character()
  }, error = function(e) conditionMessage(e)) else character()
  # Partial eta-squared (or Cohen's f turned into it) plans the classical
  # F test only; said here, before the engine is called, in the screen's
  # own words (11 November 2026: the default, Welch's ANOVA, otherwise
  # failed on the engine's message after a long wait).
  version <- values$test_version %||% values$method
  if (identical(values$metric, "eta_squared") && !blank(version) && !version %in% c("anova_f", "ancova_f") &&
      any(vapply(fields, function(f) identical(f$id, "test_version") && field_applies(f, values), logical(1)))) {
    problems <- c(problems, c(test_version = paste0(
      "An effect size (partial eta-squared or Cohen's f) plans the classical ANOVA only. ",
      "Under \u201cTest version\u201d choose the classical ANOVA, or give the group means and SD to keep the version you chose.")))
  }
  c(problems, combination_problems(values), scenario_problem)
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

field_value <- function(f, v, values = list()) {
  switch(
    f$type,
    number = { x <- parse_number(v); if (isTRUE(f$integer)) as.integer(x) else x },
    levels = as.list(parse_levels(v)),
    numbers = as.list(parse_numbers(v)),
    table = {
      rows <- lapply(parse_table(v), as.list)
      # `nest_by`: lines grouped into one array per level of the first
      # factor, each holding one line per level of the field named (E56:
      # three factors' means, A by B by C).
      if (is.null(f$nest_by)) rows else {
        per <- length(parse_levels(values[[f$nest_by]]))
        unname(split(rows, ceiling(seq_along(rows) / per)))
      }
    },
    trimws(as.character(v))
  )
}

# The design spec for the values entered (assumes form_problems() found none).
build_spec <- function(forms, ep_id, fields, values) {
  values <- expand_level_counts(fields, values)
  form <- forms$forms[[ep_id]]
  spec <- form$base
  # Mediators are added for the number chosen; each is a score.
  if (!is.null(form$mediators)) {
    for (m in mediator_roles(as.integer(values$n_mediators %||% 2))) spec$variables[[m]] <- list(type = "continuous")
  }
  # Several outcomes named in one field (E59): one score variable each, Y1
  # to Yp.
  if (!is.null(form$outcomes) && !blank(values[[form$outcomes]])) {
    labels <- parse_levels(values[[form$outcomes]])
    for (j in seq_along(labels)) spec$variables[[paste0("Y", j)]] <- list(type = "continuous", label = labels[[j]])
  }
  for (f in fields) {
    # A field with no path may still set spec values through `sets` (E56:
    # which factors are measured in everyone).
    if ((is.null(f$path) && is.null(f$sets)) || !field_applies(f, values)) next
    v <- values[[f$id]]
    if (blank(v) && effect_optional(f, values)) v <- empty_effect(f, values)
    if (blank(v) && source_not_asked(f, values)) v <- "none"
    # A field left empty may stand for another field's value (E34: the
    # baseline score's R-squared between groups starts as the one within).
    if (blank(v) && !is.null(f$copy_if_empty)) v <- values[[f$copy_if_empty]]
    if (blank(v) && !is.null(f$name_default)) v <- f$name_default
    if (blank(v)) next
    if (!is.null(f$path)) spec <- set_path(spec, split_path(f$path), field_value(f, v, values))
    # `sets`: further spec values that follow from a choice (E24's
    # question sets the template and the effect tested); an entry with a
    # `shown_if` applies only when its conditions hold (E34: the test of a
    # yes/no outcome depends on how the conditions are assigned).
    for (extra in f$sets[[as.character(v)]]) {
      if (field_applies(extra, values)) spec <- set_path(spec, split_path(extra$path), extra$value)
    }
  }
  # The pair compared (pairwise comparisons) is matched to the levels'
  # spelling, so "none, praise" finds "None" and "Praise".
  factor_levels <- spec$variables$A$levels %||% spec$variables$X$levels
  if (!is.null(spec$target_test$comparison) && !is.null(factor_levels)) {
    levels <- unlist(factor_levels)
    pair <- unlist(spec$target_test$comparison)
    at <- match(tolower(trimws(pair)), tolower(trimws(levels)))
    spec$target_test$comparison <- as.list(ifelse(is.na(at), pair, levels[at]))
  }
  # The category tested against the first (E70) is matched to the
  # outcome's spelling in the same way.
  if (!is.null(spec$target_test$category) && !is.null(spec$variables$Y$levels)) {
    levels <- unlist(spec$variables$Y$levels)
    at <- match(tolower(trimws(spec$target_test$category)), tolower(trimws(levels)))
    if (!is.na(at)) spec$target_test$category <- levels[at]
  }
  # Precision (E46): one engine goal, and the interval's level as alpha.
  if (isTRUE(form$precision)) {
    spec$goal$type <- "precision"
    spec$target_test$alpha <- 1 - parse_number(values$conf_level)
    # MBESS's d, d_z and standardised mean use the noncentral t; the other
    # estimates set their own interval (forms.yaml, E46's `sets`).
    if (spec$template %in% c("two_groups", "paired", "one_group")) spec$target_test$method <- "noncentral_t"
    return(spec)
  }
  # The level is what a justified alpha finds, so it isn't asked for; the
  # engine's comparison row uses the usual 0.05.
  if (identical(values$goal, "justified_alpha") && is.null(spec$target_test$alpha)) spec$target_test$alpha <- 0.05
  if (!is.null(spec$target_test$alpha)) spec$target_test$alpha <- claim_alpha(spec$target_test$alpha, values)
  if (identical(spec$goal$type, "sample_size") || identical(spec$goal$type, "sensitivity")) spec$goal$power <- claim_power(spec$goal$power, values)
  # The range of sample sizes is several engine runs (sensitivity_curve());
  # the spec kept for the exports is the largest N at 80% power.
  if (identical(values$goal, "sensitivity_curve")) {
    spec$goal <- list(type = "sensitivity", n = as.integer(parse_number(values$n_max)), power = 0.8)
  }
  spec
}

# The value an empty effect size stands for: zero; group 1's proportion
# (two proportions: no difference); the reduced model's R-squared (no
# increase); or, for a table of proportions, equal
# proportions in every combination (no association).
empty_effect <- function(f, values) {
  switch(
    f$when_empty %||% "zero",
    zero = "0",
    same_as_p1 = values$p1,
    # Multiple regression's R-squared increase: no increase over the model
    # without the tested predictors.
    same_as_r2_reduced = values$r2_reduced %||% "0",
    no_association = {
      rows <- length(parse_levels(values$X_levels))
      cols <- length(parse_levels(values$Y_levels))
      line <- paste(rep(sprintf("%.15g", 1 / (rows * cols)), cols), collapse = ", ")
      paste(rep(line, rows), collapse = "\n")
    }
  )
}

# An effect size may stay empty for the smallest detectable effect, or
# when the user can't justify one (the basic tests only).
effect_optional <- function(f, values) {
  isTRUE(f$effect) && length(f$optional_for) > 0 &&
    (isTRUE(values$goal %in% f$optional_for) || identical(values$just_type, "none"))
}

# Finding the smallest detectable effect enters no effect size, so it needs
# no source for one: the question may stay empty, and the spec records
# "none" (11 November 2026). Only where the card offers that answer.
source_not_asked <- function(f, values) {
  identical(f$id, "just_type") && "none" %in% names(f$choices) &&
    isTRUE(values$goal %in% c("sensitivity", "sensitivity_curve"))
}

# Problems with the combination of answers, beyond single fields.
combination_problems <- function(values) {
  if (identical(values$just_type, "none") && !isTRUE(values$goal %in% c("sensitivity", "sensitivity_curve"))) {
    return(c(just_type = "\u201cI can't justify an effect size\u201d leaves no effect to plan for, so there is no sample size or power to work out. If you are using a conventional value, choose \u201cA convention or rule of thumb\u201d as the source. Otherwise, under \u201cWhat do you want to find out?\u201d, choose the smallest effect you could detect."))
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
  ids <- vapply(fields, function(f) f$id %||% "", "")
  # The number of simulated studies is chosen by "How precise should the
  # simulation be?"; its custom field is hidden until asked for.
  if ("simulation_accuracy" %in% ids) {
    message <- gsub("'options > nrep'", quote_label(fields[[match("simulation_accuracy", ids)]]), message, fixed = TRUE)
  }
  for (f in fields) {
    if (is.null(f$path)) next
    engine_path <- gsub(".", " > ", f$path, fixed = TRUE)
    message <- gsub(sprintf("'%s'", engine_path), quote_label(f), message, fixed = TRUE)
  }
  # A sentence that still names a setting this screen doesn't show can't be
  # acted on here, so it is left out.
  sentences <- strsplit(message, "(?<=[.!?])\\s+", perl = TRUE)[[1]]
  hidden <- grepl("'options > ", sentences, fixed = TRUE)
  if (any(hidden) && !all(hidden)) message <- paste(sentences[!hidden], collapse = " ")
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
  # Only the engine's own errors are worded for users; anything else is a
  # fault, reported without its internals.
  problems <- if (inherits(result, "powerkit_error")) result$problems %||% conditionMessage(result) else
    "powerkit couldn't check these answers: something went wrong in its engine. Please report this, with the answers you copied."
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
    if (identical(f$id, "scenario_library")) {
      lines <- c(lines, assumption_record_lines(values, fields), named_alternative_lines(values, fields))
      next
    }
    shown <- if (!is.null(f$choices) && !is.null(f$choices[[as.character(v)]])) f$choices[[as.character(v)]] else gsub("\n", " / ", as.character(v))
    lines <- c(lines, sprintf("- %s: %s", f$label, shown))
  }
  paste(lines, collapse = "\n")
}

# Target power starts empty on every card (8 November 2026), whatever the
# package's own default, so the user chooses it and says why.
target_power_source <- "Empty on every card: choose the power your study needs and say why; the result compares 80%, 90% and 95%"
