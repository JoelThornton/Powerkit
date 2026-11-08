# Whole-study simulation (experimental; docs/conventions.md, Departure 13).
#
# From the guided plan: one population model for the whole study, entered
# once as standardised paths, and every planned analysis simulated on the
# same data sets by the engine's run_whole_study() (power4mome). The app
# never computes power: it checks which plans the engine covers, asks for
# the values the engine says the population needs
# (whole_study_parameters()), builds the spec and shows the engine's result.
#
# Covered: different people measured once, a measured predictor (X) or
# two groups or conditions (next.md item 1, 31 October 2026), a score
# outcome, no covariates, a measured moderator or none, and one or two
# mediators that are scores. Each ticked analysis must lead to one of the
# end points below. With two groups, the comparison of the groups (E2) is
# the regression of Y on the groups, Student's t test; the moderation (E15)
# and mediation (E16) with a yes/no X are simulated the same way.
#
# Measured twice (before and after): the outcome's first measurement is
# the baseline B, and every analysis adjusts the second for it, as the
# ANCOVA card (E23) does (decided 31 October 2026). Covered: the
# comparison when the ANCOVA is chosen (the mixed ANOVA's group x time
# test is not simulated as a whole study), the moderation, a mediation
# through one or two mediators (side by side or in a chain) and a
# moderated mediation with one moderated link (X to the mediator, or the
# mediator to the outcome); these have no card of their own yet (E41).

whole_study_tests <- c(E4 = "x_y", E9 = "interaction", E10 = "indirect", E11 = "indirect",
  E12 = "indirect", E13 = "index_of_mome", E14 = "index_of_mome",
  E2 = "x_y", E15 = "interaction", E16 = "indirect")

# Plain names for the variables and product terms in path labels.
whole_study_names <- c(X = "the predictor (X)", Y = "the outcome (Y)", W = "the moderator (W)",
  B = "the first measurement of the outcome (B)", M = "the mediator (M)", M1 = "the first mediator (M1)", M2 = "the second mediator (M2)",
  XW = "the predictor x moderator interaction (XW)", MW = "the mediator x moderator interaction (MW)")

# Measured twice: the analysis that each planned analysis becomes once Y
# is adjusted for its first measurement (whole_study_plan()).
whole_study_twice_tests <- c(compare = "x_y", moderation = "interaction", mediation = "indirect", modmed = "index_of_mome", check = "x_m")
whole_study_twice_endpoints <- c(compare = "E23", moderation = "E24", mediation = "E41", modmed = "E41")

# The effect of X on the mediator (a manipulation check, tree.yaml's
# `check`): M on X alone, whatever card it leads to (the two-group
# comparison or the correlation), with one mediator that is a score.
whole_study_check_endpoints <- c("E2", "E4")

# Measured twice, the routes ask how two mediators connect and which link
# W moderates (tree.yaml: ME3 and MM4, every answer going to E41); the
# answer picks the model, as the card's end point does when measured once.
whole_study_twice_serial <- "In a chain: X affects the first, which affects the next"
whole_study_twice_links <- c("The link from X to the mediator" = "x_m", "The link from the mediator to the outcome" = "m_y")

whole_study_path_label <- function(key) {
  if (identical(key, "X<->W")) return("Correlation of the predictor with the moderator (X with W; for groups or conditions, 0 if people are randomised to them)")
  if (identical(key, "X<->B")) return("Correlation of the predictor with the first measurement of the outcome (X with B; for groups or conditions, 0 if people are randomised to them)")
  if (identical(key, "W<->B")) return("Correlation of the moderator with the first measurement of the outcome (W with B)")
  if (identical(key, "M1<->M2")) return("Correlation of the two mediators' residuals (what M1 and M2 share beyond X)")
  ends <- strsplit(key, "->", fixed = TRUE)[[1]]
  sprintf("Path %s → %s: from %s to %s", ends[1], ends[2], whole_study_names[[ends[1]]], whole_study_names[[ends[2]]])
}

whole_study_input_id <- function(key) paste0("ws_", gsub("[^A-Za-z0-9]", "_", key))

# Whether the plan can be simulated as a whole study, and if so the
# engine's analyses and variables. Returns list(ok, reasons, analyses,
# variables, mediators, path_choices).
whole_study_plan <- function(tree, answers, ticked, primary, asks) {
  experiment <- whole_study_experiment_plan(tree, answers, ticked, primary)
  if (!is.null(experiment)) return(experiment)
  reasons <- character()
  if (!answers$x %in% c("score", "cond2")) reasons <- c(reasons, "the main predictor (X) is a measured score or two groups or conditions")
  if (!identical(answers$outcome, "score")) reasons <- c(reasons, "the outcome is a score")
  twice <- identical(answers$times, "twice")
  # Measured twice, the first measurement is the baseline already (B, which
  # every analysis adjusts for), so "a baseline measure" is the same study
  # as "none" (8 November 2026).
  covariate <- answers$covariate %||% "none"
  if (twice && identical(covariate, "baseline")) covariate <- "none"
  if (!identical(covariate, "none")) reasons <- c(reasons, "there are no covariates other than the first measurement of the outcome")
  if (!(answers$times %||% "once") %in% c("once", "twice")) reasons <- c(reasons, "each person is measured once or twice")
  if (!answers$moderator %in% c("none", "score")) reasons <- c(reasons, "the moderator, if any, is a measured score")
  if (!answers$mediators %in% c("none", "one", "several")) reasons <- c(reasons, "the mediators, if any, are scores")
  if (length(intersect(ticked, primary)) == 0) reasons <- c(reasons, "at least one analysis is a main analysis")
  endpoints <- vapply(ticked, function(id) {
    resolve_analysis(tree, analysis_by_id(tree, id), answers, asks[[id]])$endpoint %||% ""
  }, character(1))
  covered <- if (twice) {
    vapply(seq_along(ticked), function(i) {
      id <- ticked[i]
      if (identical(id, "check")) return(endpoints[[i]] %in% whole_study_check_endpoints && identical(answers$mediators, "one"))
      identical(unname(whole_study_twice_endpoints[id]), endpoints[[i]]) &&
        (!identical(id, "modmed") || (identical(answers$x, "score") && identical(answers$mediators, "one") &&
          (asks[[id]] %||% "") %in% names(whole_study_twice_links)))
    }, logical(1))
  } else {
    ifelse(ticked == "check", endpoints %in% whole_study_check_endpoints & identical(answers$mediators, "one"),
      endpoints %in% names(whole_study_tests))
  }
  outside <- ticked[!covered]
  if (length(outside)) {
    reasons <- c(reasons, sprintf("every analysis is one the simulation covers (not yet: %s)",
      paste(vapply(outside, function(id) analysis_by_id(tree, id)$label, ""), collapse = "; ")))
  }
  if (length(ticked) == 0) reasons <- c(reasons, "at least one analysis is planned")
  if (length(reasons)) return(list(ok = FALSE, reasons = reasons))

  mediators <- switch(answers$mediators, one = "M", several = c("M1", "M2"), character())
  link <- c(E13 = "x_m", E14 = "m_y")
  serial <- if (twice) identical(asks[["mediation"]], whole_study_twice_serial) else "E12" %in% endpoints
  analyses <- lapply(seq_along(ticked), function(i) {
    id <- ticked[i]
    ep <- endpoints[[i]]
    a <- list(id = id, label = analysis_by_id(tree, id)$label,
      test = if (twice || identical(id, "check")) whole_study_twice_tests[[id]] else whole_study_tests[[ep]],
      role = if (id %in% primary) "main" else "extra")
    if (identical(a$test, "indirect")) a$path <- if (length(mediators) == 1) "X->M->Y" else if (serial) "X->M1->M2->Y" else "X->M1->Y"
    if (identical(a$test, "index_of_mome")) a$moderated_link <- if (twice) whole_study_twice_links[[asks[[id]]]] else link[[ep]]
    a
  })
  tests <- vapply(analyses, function(a) a$test, "")
  roles <- c("X", if (any(tests %in% c("interaction", "index_of_mome"))) "W",
    if (any(tests %in% c("indirect", "index_of_mome", "x_m"))) mediators, if (twice) "B", "Y")
  path_choices <- if (length(mediators) == 2 && "indirect" %in% tests) {
    if (serial) c("X->M1->M2->Y", "X->M1->Y", "X->M2->Y") else c("X->M1->Y", "X->M2->Y")
  }
  list(ok = TRUE, analyses = analyses, roles = roles, binary_x = identical(answers$x, "cond2"),
    mediators = if (length(mediators) == 2 && any(tests %in% c("indirect", "index_of_mome", "x_m"))) (if (serial) "serial" else "parallel"),
    path_choices = path_choices)
}

# Experiments (next.md item 1, 6 November 2026): conditions or groups,
# between or within participants, crossed with a moderator of two or more
# groups, a score outcome and no covariates or mediators, analysed with a
# factorial ANOVA (Superpower, through the engine's experiment route). The
# effect of X is the ANOVA's main effect of X, the moderation its X x W
# interaction, both read from the same simulated data sets. Measured once:
# X a condition with two or more groups (the two-group comparison with no
# moderator stays on power4mome's route, as before); measured twice: the
# same people in X's two conditions, crossed with groups of W. NULL when
# the plan isn't an experiment of this kind.
whole_study_experiment_plan <- function(tree, answers, ticked, primary) {
  x <- answers$x %||% ""
  w <- answers$moderator %||% "none"
  times <- answers$times %||% "once"
  between_x <- x %in% c("cond2", "cond3") && identical(times, "once")
  within_x <- identical(x, "within2") && identical(times, "twice")
  if (!(between_x || within_x)) return(NULL)
  if (!w %in% c("none", "two", "three")) return(NULL)
  if (identical(x, "cond2") && identical(w, "none")) return(NULL)
  # Other outcomes, covariates and mediators: the general route says why
  # it can't simulate the plan.
  if (!identical(answers$outcome, "score") || !identical(answers$covariate %||% "none", "none") ||
    !identical(answers$mediators %||% "none", "none")) return(NULL)
  reasons <- character()
  outside <- setdiff(ticked, c("compare", "moderation"))
  if (length(outside)) reasons <- c(reasons, sprintf("every analysis is one the simulation covers (not yet: %s)",
    paste(vapply(outside, function(id) analysis_by_id(tree, id)$label, ""), collapse = "; ")))
  if (length(ticked) == 0) reasons <- c(reasons, "at least one analysis is planned")
  if (length(intersect(ticked, primary)) == 0) reasons <- c(reasons, "at least one analysis is a main analysis")
  if (length(reasons)) return(list(ok = FALSE, reasons = reasons))
  has_w <- !identical(w, "none")
  template <- if (within_x) {
    if (!has_w) "oneway_within" else if (identical(w, "two")) "2x2_mixed" else "mixed"
  } else {
    if (!has_w) "oneway_between" else if (identical(x, "cond2") && identical(w, "two")) "2x2_between" else "factorial_between"
  }
  # Factor A is the between factor: X measured once, W in a mixed design.
  # With W measured once, X is A and W is B.
  x_factor <- if (within_x && has_w) "B" else "A"
  effect_of <- c(compare = if (x_factor == "A") "main_effect_A" else "main_effect_B", moderation = "interaction")
  analyses <- lapply(ticked, function(id) {
    list(id = id, label = whole_study_experiment_labels[[id]], test = "anova_effect", effect = effect_of[[id]],
      role = if (id %in% primary) "main" else "extra")
  })
  list(ok = TRUE, experiment = TRUE, analyses = analyses, template = template, x_factor = x_factor,
    x_within = within_x, has_w = has_w, x_levels = if (identical(x, "cond3")) 3L else 2L,
    w_levels = if (identical(w, "three")) 3L else 2L, roles = c("X", if (has_w) "W", "Y"))
}

whole_study_experiment_labels <- c(compare = "The main effect of X (in the factorial ANOVA)",
  moderation = "Whether the effect of X depends on the moderator (the X x W interaction)")

# The variables' names: from what the user typed on the plan's input
# screens, else the role names.
# `named`: names typed on the simulation screen itself
# (whole_study_name_inputs()), which come first.
whole_study_labels <- function(roles, plan_values, named = list()) {
  defaults <- c(X = "Predictor", Y = "Outcome", B = "Outcome, first measurement", W = "Moderator", M = "Mediator", M1 = "First mediator", M2 = "Second mediator")
  out <- defaults[roles]
  if (length(named)) plan_values <- c(list(stats::setNames(named, paste0(names(named), "_label"))), plan_values)
  for (r in roles) {
    for (values in plan_values) {
      typed <- values[[paste0(r, "_label")]]
      if (!is.null(typed) && length(typed) == 1 && nzchar(trimws(typed))) {
        out[[r]] <- trimws(typed)
        break
      }
    }
  }
  # The first measurement of the outcome is named after the outcome.
  if ("B" %in% roles && identical(out[["B"]], defaults[["B"]])) out[["B"]] <- paste0(out[["Y"]], ", first measurement")
  out
}

# The variables' names, on the simulation screen: filled in from the plan's
# input screens where they were typed there, so the result and its write-up
# never fall back on "Predictor" or "Moderator" unasked (8 November 2026).
# The outcome's first measurement is named after the outcome.
whole_study_name_roles <- function(roles) setdiff(roles, "B")
whole_study_name_words <- c(X = "The predictor or condition (X)", W = "The moderator (W)", M = "The mediator (M)",
  M1 = "The first mediator (M1)", M2 = "The second mediator (M2)", Y = "The outcome (Y)")
whole_study_name_inputs <- function(roles, labels) {
  tagList(
    h3(class = "h5", "What your variables are called"),
    p(class = "text-muted small", "Used in the result and the methods paragraph."),
    div(class = "ws-names", lapply(whole_study_name_roles(roles), function(r) {
      textInput(paste0("ws_name_", r), whole_study_name_words[[r]], value = if (r %in% names(labels)) labels[[r]] else "", width = "100%")
    }))
  )
}
whole_study_names_from_input <- function(input, roles) {
  out <- lapply(whole_study_name_roles(roles), function(r) trimws(input[[paste0("ws_name_", r)]] %||% ""))
  names(out) <- whole_study_name_roles(roles)
  Filter(nzchar, out)
}

# The spec without its population, for whole_study_parameters().
whole_study_skeleton <- function(plan, labels, path = NULL) {
  analyses <- lapply(plan$analyses, function(a) {
    if (!is.null(path) && identical(a$test, "indirect")) a$path <- path
    a
  })
  spec <- list(
    spec_version = "0.1", kind = "whole_study",
    variables = stats::setNames(lapply(plan$roles, function(r) {
      list(type = if (identical(r, "X") && isTRUE(plan$binary_x)) "binary" else "continuous", label = labels[[r]])
    }), plan$roles),
    analyses = analyses,
    claim = "each", alpha = 0.05,
    effect_justification = list(type = "none"),
    goal = list(type = "power", n = 100L)
  )
  if (!is.null(plan$mediators)) spec$mediators <- plan$mediators
  spec
}

# Values for the path inputs from what was entered on the plan's input
# screens (shared values), where the meaning is the same.
whole_study_prefill <- function(shared) {
  from <- c("X->M" = "p_x_m", "M->Y" = "p_m_y", "X->Y" = "p_x_y", "X<->W" = "r_x_w")
  out <- list()
  for (key in names(from)) {
    v <- shared[[from[[key]]]]$value
    if (!is.null(v) && nzchar(v)) out[[key]] <- v
  }
  out
}

# The largest N calculated so far for a main analysis on the plan.
whole_study_start_n <- function(results, primary) {
  ns <- unlist(lapply(results[intersect(names(results), primary)], function(r) if (identical(r$goal, "sample_size")) r$n))
  if (length(ns)) max(ns) else NULL
}

# Monte Carlo precision of a power from `nrep` replications, as the
# half-width of a 95% interval at 50% power, in percentage points.
whole_study_precision <- function(nrep) round(100 * 1.96 * sqrt(0.25 / nrep))

# A long wait in words: hours (to the half hour) from an hour and a half.
whole_study_duration <- function(seconds) {
  if (seconds < 90 * 60) return(duration_text(seconds))
  hours <- seconds / 3600
  sprintf("about %s hours", format(if (hours < 10) round(2 * hours) / 2 else round(hours)))
}

whole_study_seconds <- function(forms, plan, nrep) {
  per <- forms$whole_study$seconds_per_replication
  tests <- vapply(plan$analyses, function(a) a$test, "")
  sum(unlist(per[tests])) * nrep + (forms$whole_study$overhead_seconds %||% 15)
}

# On the plan screen. When the simulation covers the plan, it is the plan's
# first step: a short description, the analyses it will run, and the
# button. Otherwise one folded note says what it would need.
whole_study_entry_ui <- function(plan, ticked = NULL, labels = NULL, badge = NULL) {
  if (!isTRUE(plan$ok)) {
    return(tags$details(class = "plan-more whole-study-entry",
      tags$summary("Simulating the whole study at once (experimental) isn't available for this plan"),
      p("It covers studies where:"), tags$ul(lapply(plan$reasons, tags$li))))
  }
  div(class = "whole-study-entry whole-study-lead",
    h3(class = "h4", "Your whole study in one go ", tags$span(class = "badge bg-warning text-dark", "Experimental")),
    p(class = "lead", "Describe your study once. powerkit simulates it many times and runs every analysis below on each simulated study, so you see the power of each one, and the chance that your claim succeeds, from one model."),
    if (length(ticked)) tags$ul(class = "whole-study-analyses", lapply(ticked, function(id) tags$li(labels[[id]], if (!is.null(badge)) badge(id)))),
    p(class = "text-muted small", "New in powerkit and not yet checked by a statistician: use it to explore, not to report."),
    pick_button("Describe your study", "guided:simulate", class = "btn btn-primary")
  )
}

# The simulation screen: the population, the sample size and the run.
whole_study_ui <- function(forms, plan, params, labels, prefill, n, rule, values = list(), path = NULL, problem = NULL) {
  value_of <- function(key) values[[key]] %||% prefill[[key]] %||% ""
  rule_words <- c(each = "each main result is a separate claim", all = "the claim needs every main result to be significant",
    any = "any one significant main result supports the claim")
  nrep_choices <- forms$whole_study$nrep_choices
  tagList(
    screen_nav_ui("guided:plan", "Back to your plan"),
    h2("Simulate the whole study ", tags$span(class = "badge bg-warning text-dark", "Experimental")),
    p(class = "lead", "Describe your study once. Every planned analysis is then run on the same simulated studies."),
    div(class = "alert alert-warning", role = "note",
      "The method is new in powerkit and is waiting for a statistician's check. The results may change. Use them to explore your plan, not to report."),
    if (!is.null(problem)) div(class = "form-problems", role = "alert", tabindex = "-1", h3(class = "h5", "Please check"), tags$ul(lapply(problem, tags$li))),
    h3(class = "h5", "Your analyses"),
    tags$ul(lapply(plan$analyses, function(a) tags$li(a$label, " ",
      tags$span(class = if (a$role == "main") "badge bg-primary" else "badge bg-secondary", if (a$role == "main") "Main analysis" else "Extra analysis")))),
    p(tags$strong("Your claim:"), paste0(" ", rule_words[[rule]], ".")),
    whole_study_name_inputs(plan$roles, labels),
    if (!is.null(plan$path_choices)) selectInput("ws_path", "Which indirect effect does the mediation analysis test?",
      choices = plan$path_choices, selected = path %||% plan$path_choices[1], width = "100%"),
    h3(class = "h5", "Your study: standardised paths"),
    p(class = "text-muted", "Each path is the change in the outcome of that arrow, in standard deviations, for a one standard deviation change in its cause, holding the arrow's other causes constant. Use 0 for no effect. Values entered on your plan's input screens are filled in where they mean the same thing; check them, since in the whole model each path holds every other cause constant."),
    div(class = "ws-paths", lapply(c(params$paths, params$correlations), function(key) {
      textInput(whole_study_input_id(key), whole_study_path_label(key), value = value_of(key), width = "100%")
    })),
    h3(class = "h5", "Sample size and precision"),
    textInput("ws_n", "Total participants analysed (N)", value = values$n %||% (if (!is.null(n)) as.character(n) else ""), width = "100%"),
    if (!is.null(n)) p(class = "text-muted small", "Filled in with the largest sample size calculated on your plan for a main analysis."),
    textInput("ws_alpha", "Significance level (alpha)", value = values$alpha %||% "0.05", width = "100%"),
    p(class = "text-muted", sprintf(
      "This screen runs a quick look: %s simulated studies, so each power is within about \u00b1%s percentage points (%s). For numbers to report, and to find the sample size you need, run the full simulation on your computer: the R script is offered with the result.",
      whole(forms$whole_study$quick_nrep), whole_study_precision(forms$whole_study$quick_nrep),
      duration_text(whole_study_seconds(forms, plan, forms$whole_study$quick_nrep)))),
    textInput("ws_seed", "Random seed (the same seed gives the same result)", value = values$seed %||% as.character(forms$default_seed), width = "100%"),
    p(class = "text-muted small", "It runs in a separate process: you can cancel it, and leaving this screen stops it."),
    action_bar(actionButton("ws_run", "Run the simulation", class = "btn btn-primary")),
    uiOutput("ws_result")
  )
}

# The values typed on the simulation screen, by key.
whole_study_values <- function(input, params) {
  keys <- c(params$paths, params$correlations)
  out <- lapply(keys, function(k) input[[whole_study_input_id(k)]] %||% "")
  names(out) <- keys
  c(out, list(n = input$ws_n %||% "", alpha = input$ws_alpha %||% "",
    seed = input$ws_seed %||% "", path = input$ws_path))
}

# The spec from the screen's values, or the problems in plain words.
# `nrep` is the quick look's number of simulated studies.
whole_study_spec <- function(skeleton, params, values, rule, nrep = values$nrep) {
  problems <- character()
  number <- function(key, label, lower = -1, upper = 1, open = FALSE) {
    x <- suppressWarnings(as.numeric(trimws(values[[key]] %||% "")))
    if (length(x) != 1 || is.na(x)) {
      problems <<- c(problems, sprintf("%s: enter a number (0 for no effect).", label))
      return(NULL)
    }
    if (x < lower || x > upper || (open && (x == lower || x == upper))) {
      problems <<- c(problems, sprintf("%s: enter a value %s %s and %s.", label, if (open) "strictly between" else "between", lower, upper))
      return(NULL)
    }
    x
  }
  paths <- lapply(params$paths, function(k) number(k, whole_study_path_label(k)))
  names(paths) <- params$paths
  correlations <- lapply(params$correlations, function(k) number(k, whole_study_path_label(k), open = TRUE))
  names(correlations) <- params$correlations
  n <- suppressWarnings(as.numeric(values$n))
  if (is.na(n) || n != round(n) || n < 20) problems <- c(problems, "Total participants: enter a whole number of 20 or more.")
  alpha <- suppressWarnings(as.numeric(values$alpha))
  if (is.na(alpha) || alpha <= 0 || alpha >= 1) problems <- c(problems, "Significance level: enter a number between 0 and 1, such as 0.05.")
  seed <- suppressWarnings(as.numeric(values$seed))
  if (is.na(seed) || seed != round(seed) || seed < 1 || seed > 2147483647) problems <- c(problems, "Random seed: enter a whole number of 1 or more.")
  if (length(problems)) return(list(problems = problems))
  spec <- skeleton
  if (!is.null(values$path)) {
    spec$analyses <- lapply(spec$analyses, function(a) {
      if (identical(a$test, "indirect")) a$path <- values$path
      a
    })
  }
  spec$population <- list(paths = paths)
  if (length(correlations)) spec$population$correlations <- correlations
  spec$claim <- rule
  spec$alpha <- alpha
  spec$goal <- list(type = "power", n = as.integer(n))
  spec$options <- list(nrep = as.integer(nrep), seed = as.integer(seed))
  list(spec = spec)
}

# The engine's check, in plain words (validate_whole_study()).
whole_study_check <- function(spec, validate = engine_function("validate_whole_study")) {
  if (is.null(validate)) return("The simulation needs powerkit's engine, which isn't installed where this prototype is running.")
  tryCatch({
    validate(spec)
    character()
  }, error = function(e) {
    if (!inherits(e, "powerkit_error")) {
      return("powerkit couldn't check this plan: something went wrong in its engine. Please report this, with the answers you copied.")
    }
    msg <- conditionMessage(e)
    lines <- trimws(sub("^\\*\\s*", "", strsplit(msg, "\n", fixed = TRUE)[[1]]))
    lines[nzchar(lines) & !grepl("has a problem|has problems", lines)]
  })
}

# Names of the values an analysis's own input screen asks for, for the
# implied values (the engine names them as the forms do).
whole_study_value_label <- function(key) {
  fixed <- c(r = "Correlation r", r_X_Y = "Correlation of X with Y", r_W_Y = "Correlation of W with Y",
    r_XW_Y = "Correlation of the interaction XW with Y", r_X_W = "Correlation of X with W",
    c_X_W = "Correlation of X with W", indirect = "Indirect effect (product of its paths)",
    index = "Index of moderated mediation", rc_M1_M2 = "Residual correlation of M1 with M2",
    d = "Cohen's d of the groups (not adjusted for a first measurement)",
    r_B_Y = "Correlation of the first measurement B with the outcome Y",
    cohen_f = "Cohen's f of the effect (Superpower)", power_alone = "Power of this test on its own (exact)")
  if (key %in% names(fixed)) return(fixed[[key]])
  if (grepl("^p_", key)) {
    parts <- strsplit(sub("^p_", "", key), "_", fixed = TRUE)[[1]]
    return(sprintf("Path %s -> %s", parts[1], parts[2]))
  }
  key
}

# The script for the full run on the user's computer
# (export_whole_study_script()): the power at the quick look's N with the
# full number of simulated studies, or the smallest N for a target power.
whole_study_script_ui <- function(forms, plan, n, rule, mains) {
  ws <- forms$whole_study
  r_needs <- backend_r_requirement(if (isTRUE(plan$experiment)) "Superpower" else "power4mome")
  one_run <- whole_study_seconds(forms, plan, ws$full_nrep)
  search <- ws$search_runs * one_run
  target_of <- if (mains == 1) "your main analysis" else switch(rule,
    all = "the chance that all of your main analyses are significant in the same study",
    any = "the chance that at least one of your main analyses is significant",
    each = "each of your main analyses")
  div(class = "script-offer ws-script",
    h4(class = "h5", "Run the full simulation on your computer"),
    p("The quick look above is for exploring. The R script runs the full simulation on your computer with the same population and seed, so anyone can rerun it and get the same numbers."),
    radioButtons("ws_script_goal", "What should the script work out?",
      choiceNames = list(
        sprintf("The sample size you need: the smallest N at which %s reaches the target power (%s on one core)",
          target_of, whole_study_duration_range(search)),
        sprintf("The power at N = %s, from %s simulated studies (within about \u00b1%s percentage points; %s on one core)",
          whole(n), whole(ws$full_nrep), whole_study_precision(ws$full_nrep), whole_study_duration(one_run))),
      choiceValues = list("sample_size", "power"), selected = "sample_size", width = "100%"),
    selectInput("ws_target", "Target power (for the sample size)",
      choices = stats::setNames(as.character(ws$target_powers), paste0(100 * unlist(ws$target_powers), "%")),
      selected = "0.8", width = "100%"),
    p("What you need:"),
    tags$ul(
      tags$li(sprintf("R%s, from cran.r-project.org.", if (is.null(r_needs)) "" else sprintf(" %s or later", r_needs))),
      tags$li("powerkit and the packages it uses. In R, run once: ",
        tags$code("install.packages(\"remotes\")"), " then ",
        tags$code("remotes::install_github(\"JoelThornton/Powerkit\", subdir = \"engine\")"), "."),
      tags$li("Then run the script. More cores finish sooner (its first lines say how) without changing the result. It saves the result and the citations.")),
    download_button("ws_download_script", "Download R script for the full simulation", class = "btn btn-primary"))
}

# The spec the script runs: the quick look's spec with the full number of
# simulated studies and the goal chosen.
whole_study_script_spec <- function(spec, forms, goal, target) {
  spec$options$nrep <- as.integer(forms$whole_study$full_nrep)
  spec$goal <- if (identical(goal, "power")) list(type = "power", n = spec$goal$n)
    else list(type = "sample_size", power = as.numeric(target))
  spec
}

whole_study_script_time <- function(forms, plan, goal) {
  one_run <- whole_study_seconds(forms, plan, forms$whole_study$full_nrep)
  if (identical(goal, "power")) return(paste(whole_study_duration(one_run), "on one core"))
  paste(whole_study_duration_range(forms$whole_study$search_runs * one_run), "on one core")
}

# "about 1.5 to 3 hours", or "about 40 minutes to 1.5 hours".
whole_study_duration_range <- function(seconds) {
  words <- sub("^about ", "", vapply(seconds, whole_study_duration, ""))
  unit <- sub("^[0-9.,]+ ", "", words)
  if (unit[1] == unit[2]) return(sprintf("about %s to %s", sub(" .*$", "", words[1]), words[2]))
  sprintf("about %s to %s", words[1], words[2])
}

# A power as a bar, with its 95% interval as a lighter band behind it.
whole_study_power_bar <- function(power, lower, upper) {
  pc <- function(x) sprintf("%.1f%%", 100 * max(0, min(1, x)))
  div(class = "ws-bar", `aria-hidden` = "true",
    span(class = "ws-bar-ci", style = sprintf("left: %s; width: %s;", pc(lower), pc(upper - lower))),
    span(class = "ws-bar-fill", style = sprintf("width: %s;", pc(power))))
}

whole_study_outcomes <- function(r) {
  a <- r$analyses
  if (!all(c("failed", "attempted", "valid", "successful", "conditional_power", "successful_study_probability") %in% names(a))) return(character())
  labels <- a$label
  if (!is.null(r$joint) && !is.null(r$joint$failed)) {
    a <- rbind(a[, c("attempted", "valid", "failed", "successful", "conditional_power", "successful_study_probability")],
      as.data.frame(r$joint[c("attempted", "valid", "failed", "successful", "conditional_power", "successful_study_probability")]))
    labels <- c(labels, if (identical(r$joint$rule, "all")) "The chance that every main analysis was significant" else "The chance that at least one main analysis was significant")
  }
  a$n <- r$n
  a$denominator <- ifelse(a$failed > 0, "valid", "all_valid")
  paste0(labels, ": ", simulation_outcome_text(list(provenance = list(simulations = a))))
}

whole_study_result_ui <- function(calc, plan_values = list(), departure = NULL, script = NULL) {
  if (!identical(calc$status, "ok")) {
    return(div(class = "form-problems", role = "alert", tabindex = "-1",
      h3(class = "h5", "The simulation didn't finish"), p(calc$message)))
  }
  r <- calc$result
  a <- r$analyses
  joint <- r$joint
  rule_text <- c(all = "all of your main analyses are significant", any = "at least one of your main analyses is significant")
  pv <- r$provenance
  experiment <- identical(pv$backend, "Superpower")
  show_joint <- !is.null(joint) && !identical(r$claim, "each")
  methods <- whole_study_methods(r)
  methods_full <- paste(whole_study_methods(r, full = TRUE), sprintf("Spec hash: %s. Check run (n = 100,000): %s.", pv$spec_hash,
    if (all(r$check_run$ok)) "passed" else "failed"))
  # As on every result: the answer, each analysis, then saving and how it
  # was calculated.
  div(
    class = "result-panel whole-study-result", role = "status", tabindex = "-1",
    result_sections_ui(list(`ws-answer` = "The answer", `ws-inputs` = "Check your inputs",
      `ws-take` = "Write it up and save it", `ws-how` = "How it was calculated")),
    div(class = paste("result-card result-main", if (show_joint) "has-hero"), id = "ws-answer",
      h3(class = "h4", "Your result"),
      if (("failed" %in% names(a) && any(a$failed > 0)) || isTRUE(joint$failed > 0))
        div(class = "alert alert-warning", role = "status",
          p("Some simulated studies could not be analysed. The powers and intervals below describe valid decisions only. Success per attempted study is lower when fits fail; Monte Carlo uncertainty does not resolve these failures."),
          tags$ul(lapply(whole_study_outcomes(r), tags$li))),
      if (show_joint) div(class = "result-hero",
        div(class = "result-figure",
          tags$span(class = "result-figure-value", percent(joint$power)),
          tags$span(class = "result-figure-label", if (joint$rule == "all") "chance that every main analysis is significant" else "chance that at least one main analysis is significant"),
          tags$span(class = "result-figure-sub", sprintf("95%% interval %s to %s", percent(joint$lower), percent(joint$upper)))),
        div(class = "result-assumes",
          tags$span(class = "result-assumes-title", "Assuming"),
          tags$ul(tags$li(sprintf("N = %s", whole(r$n))), tags$li(sprintf("Alpha = %s", format(r$alpha))),
            tags$li(sprintf("%s simulated studies", whole(pv$nrep)))))),
      if (show_joint) p(class = "lead result-headline", HTML(sprintf(
        "With <strong>N = %s</strong>, the chance that %s in the same study is <strong>%s</strong> (95%% interval %s to %s).",
        whole(r$n), rule_text[[joint$rule]], percent(joint$power), percent(joint$lower), percent(joint$upper)))),
      if (!is.null(script)) p(class = "ws-quick-note", role = "note", sprintf(
        "A quick look, from %s simulated studies: each power is within about \u00b1%s percentage points. For numbers to report, and for the sample size you need, run the full simulation on your computer (under \u201cWrite it up and save it\u201d).",
        whole(r$provenance$nrep), whole_study_precision(r$provenance$nrep))),
      h4(class = "h6 mt-3", "Each analysis"),
      div(class = "table-responsive", tags$table(class = "table table-sm ws-table",
        tags$thead(tags$tr(tags$th("Analysis"), tags$th("Role"), tags$th("Tested at alpha"), tags$th("Power"), tags$th(class = "ws-bar-col", "95% interval"))),
        tags$tbody(lapply(seq_len(nrow(a)), function(i) tags$tr(
          tags$td(a$label[i]), tags$td(if (a$role[i] == "main") "Main" else "Extra"),
          tags$td(format(signif(a$alpha[i], 3))), tags$td(tags$strong(percent(a$power[i]))),
          tags$td(class = "ws-bar-col", whole_study_power_bar(a$power[i], a$lower[i], a$upper[i]),
            tags$span(class = "ws-bar-text", sprintf("%s to %s", percent(a$lower[i]), percent(a$upper[i]))))))))),
      if (identical(r$claim, "each")) p(class = "text-muted", "Each main result is a separate claim, so each analysis's own power is what matters."),
      if (identical(r$claim, "any")) p(class = "text-muted",
        "Your claim counts any one significant main result, so each main analysis is tested at alpha divided by the number of main analyses (Bonferroni), as on the plan's input screens."),
      p(class = "small", sprintf(if (experiment)
        "From %s simulated studies of %s participants. Every F test comes from the same ANOVA on the same simulated studies, so the chance that several succeed together is counted directly, not assumed."
        else "From %s simulated studies of %s participants. Each analysis is fitted with its own model, as it would be analysed on its own: the power of each comes from the same simulated studies, so the chance that several succeed together is counted directly, not assumed.",
        whole(pv$nrep), whole(r$n)))),
    div(class = "result-card", id = "ws-inputs",
      h4(class = "h5", "What your study model means for each analysis's own input screen"),
      p(class = "small", if (experiment)
        "Each test's effect size (Cohen's f) and its power when it is the only test, calculated exactly from your means (Superpower's ANOVA_exact()), as its own card would give them."
        else "Estimated from one very large simulated sample. If you calculated an analysis separately, compare these with what you entered: where they differ, the separate calculations describe different studies."),
      {
        # "You entered" only when something was entered on a card's screen.
        entered <- any(vapply(r$implied, function(imp) {
          own <- plan_values[[imp$id]] %||% list()
          any(vapply(names(imp$values), function(k) length(own[[k]]) == 1 && nzchar(as.character(own[[k]])), logical(1)))
        }, logical(1)))
        lapply(r$implied, function(imp) {
          own <- plan_values[[imp$id]] %||% list()
          label <- a$label[a$id == imp$id]
          div(class = "ws-implied-block",
            tags$p(class = "ws-implied-title", tags$strong(label)),
            div(class = "table-responsive", tags$table(class = "table table-sm ws-implied",
              tags$thead(tags$tr(tags$th("Value"), tags$th("Implied by your study model"), if (entered) tags$th("You entered on its screen"))),
              tags$tbody(lapply(names(imp$values), function(k) tags$tr(
                tags$td(whole_study_value_label(k)), tags$td(sprintf("%.3f", imp$values[[k]])),
                if (entered) tags$td(own[[k]] %||% "\u2014")))))))
        })
      }),
    div(class = "result-card result-save", id = "ws-take",
      h4(class = "h5", "Write it up and save it"),
      h5(class = "h6", "Methods paragraph (draft)"),
      writeup_ui(c(short = methods, full = methods_full)),
      script,
      div(class = "nav-buttons mt-2",
        download_button("ws_download_spec", "Download the specification (JSON)", class = "btn btn-outline-primary"),
        download_button("download_guided_plan", "Save this plan", class = "btn btn-outline-primary")),
      p(class = "small text-muted", "\u201cSave this plan\u201d keeps your plan and these inputs in a file you can open again from the start screen; the specification is for running the simulation in R.")),
    div(class = "result-card result-how", id = "ws-how",
      h4(class = "h5", "How it was calculated"),
      if (experiment) p(class = "result-credit", "Simulated with the R package ", tags$strong("Superpower"), sprintf(" (version %s), with afex %s fitting each ANOVA. Experimental: a statistician's check is still to come.",
        pv$packages[["Superpower"]], pv$packages[["afex"]]))
      else p(class = "result-credit", "Simulated with the R package ", tags$strong("power4mome"), sprintf(" (version %s), with lavaan %s and manymome %s. Experimental: a statistician's check is still to come.",
        pv$packages[["power4mome"]], pv$packages[["lavaan"]], pv$packages[["manymome"]])),
      h5(class = "h6", "How this differs from calculating each analysis separately"),
      p(departure %||% "Separate calculations each describe their own study; this simulation uses one model of your study for all of them."),
      p(class = "small text-muted", "This is recorded as a departure from the established tools in powerkit's conventions."),
      tags$details(class = "result-more", tags$summary("Details for a statistician"),
        tags$pre(class = "small", paste0(if (experiment) "Design (Superpower):\n" else "Population model (lavaan syntax):\n", r$models$population,
          "\n\nPopulation values:\n", r$models$population_values,
          "\n\nAnalysis models:\n", paste(sprintf("%s: %s", a$id, gsub("\n", "; ", r$models$analyses)), collapse = "\n"),
          sprintf("\n\nCheck run (n = 100,000): %s", if (all(r$check_run$ok)) "passed" else "FAILED"))),
        p(class = "small", sprintf("Seed %s; %s simulated studies%s; spec hash %s; %s; %s; powerkit %s. Run time %s seconds.",
          pv$seed, whole(pv$nrep), if (!is.na(pv$ci_draws)) sprintf("; %s Monte Carlo draws per confidence interval", whole(pv$ci_draws)) else "",
          pv$spec_hash, pv$r_version, paste(names(pv$packages)[names(pv$packages) != "powerkit"], pv$packages[names(pv$packages) != "powerkit"], collapse = ", "),
          pv$packages[["powerkit"]], round(pv$run_time_seconds)))))
  )
}

# The population the simulation assumed, in words, so that a reader can
# judge or reproduce it: cell means and SD for an experiment, the
# standardised paths and correlations for a path model.
whole_study_population_text <- function(r) {
  values <- r$models$population_values %||% ""
  if (identical(r$provenance$backend, "Superpower")) {
    m <- regmatches(values, regexec("^Cell means \\(Superpower's order, ([^)]*)\\): ([^;]*); SD: ([^;]*)(; correlation: (.*))?$", values))[[1]]
    if (length(m) == 0) return(sprintf("The assumed population was: %s. ", values))
    return(sprintf("The assumed population had cell means of %s (in Superpower's order, %s) and an SD of %s%s. ",
      m[3], m[2], m[4], if (nzchar(m[6])) sprintf(", with a correlation of %s between a person's repeated measurements", m[6]) else ""))
  }
  lines <- trimws(strsplit(values, "\n", fixed = TRUE)[[1]])
  lines <- lines[nzchar(lines)]
  if (length(lines) == 0) return("")
  words <- vapply(lines, function(l) {
    if (grepl("^M1 ~~ M2: ", l)) return(sprintf("residual covariance of M1 and M2 %s", sub("^M1 ~~ M2: ", "", l)))
    if (grepl(" ~~ ", l, fixed = TRUE)) {
      m <- regmatches(l, regexec("^(\\S+) ~~ (\\S+): (.*)$", l))[[1]]
      return(sprintf("correlation of %s and %s %s", m[2], m[3], m[4]))
    }
    m <- regmatches(l, regexec("^(\\S+) ~ (\\S+): (.*)$", l))[[1]]
    if (length(m) == 0) return(l)
    sprintf("%s to %s %s", gsub(":", " x ", m[3], fixed = TRUE), m[2], m[4])
  }, character(1), USE.NAMES = FALSE)
  sprintf("The assumed population values (standardised) were: %s. ", paste(words, collapse = "; "))
}

whole_study_methods <- function(r, full = FALSE) {
  a <- r$analyses
  pv <- r$provenance
  lower_first <- function(x) paste0(tolower(substr(x, 1, 1)), substr(x, 2, nchar(x)))
  powers <- paste(sprintf("%s for %s", percent(a$power), lower_first(a$label)), collapse = "; ")
  # Measured twice: the engine reports the baseline's correlation with the
  # outcome for every analysis, which each adjusted for.
  twice <- any(vapply(r$implied, function(i) "r_B_Y" %in% names(i$values), logical(1)))
  baseline <- if (twice) "Each person was measured twice, and every analysis adjusted the second measurement of the outcome for the first, as an analysis of covariance does. " else ""
  joint <- if (!is.null(r$joint) && !identical(r$claim, "each")) sprintf(
    " The study's claim needs %s to be significant: the chance that %s was significant in the same simulated study was %s.",
    if (r$joint$rule == "all") "every main analysis" else "at least one main analysis",
    if (r$joint$rule == "all") "every main analysis" else "at least one main analysis",
    percent(r$joint$power)) else ""
  # Counts of simulated studies that could not be analysed go in the full
  # version only, and only when some failed.
  failed <- ("failed" %in% names(a) && any(a$failed > 0)) || isTRUE(r$joint$failed > 0)
  failures <- if (full && failed) paste(whole_study_outcomes(r), collapse = " ") else ""
  population <- whole_study_population_text(r)
  if (identical(pv$backend, "Superpower")) {
    return(trimws(paste(sprintf(paste0(
      "Power was estimated by simulating the whole experiment (%s; the whole-study simulation is experimental) with the R package Superpower %s (ANOVA_power(), ANOVAs fitted by afex %s). ",
      "%sThis population generated %s data sets of N = %s; every planned F test was read from the same ANOVA of each data set at alpha = %s%s. ",
      "Estimated power was %s.%s Random seed %s."),
      powerkit_cited(pv$packages[["powerkit"]]), pv$packages[["Superpower"]], pv$packages[["afex"]],
      population, whole(pv$nrep), whole(r$n), format(r$alpha),
      if (identical(r$claim, "any")) " divided by the number of main analyses (Bonferroni)" else "",
      powers, joint, pv$seed), failures)))
  }
  trimws(paste(sprintf(paste0(
    "Power was estimated by simulating the whole study (%s; the whole-study simulation is experimental) with the R package power4mome %s. ",
    "One population model, specified as standardised paths, generated %s data sets of N = %s; each planned analysis was fitted to every data set with its own model ",
    "(regressions by ordinary least squares; mediation models in lavaan, with indirect effects tested by Monte Carlo confidence intervals) at alpha = %s%s. ",
    "%s%sEstimated power was %s.%s Random seed %s."),
    powerkit_cited(pv$packages[["powerkit"]]), pv$packages[["power4mome"]], whole(pv$nrep), whole(r$n), format(r$alpha),
    if (identical(r$claim, "any")) " divided by the number of main analyses (Bonferroni)" else "",
    population, baseline, powers, joint, pv$seed), failures))
}

# Experiments: the screen asks for the levels of each factor, the cell
# means in a grid (rows: the between factor, or X when both are between;
# columns: the other factor), one SD and, with a within factor, one
# correlation, then builds the whole study around a factorial ANOVA design
# spec (the engine's `experiment`).
whole_study_experiment_levels <- function(text) {
  levels <- trimws(strsplit(text %||% "", ",", fixed = TRUE)[[1]])
  levels[nzchar(levels)]
}

whole_study_experiment_default_levels <- function(prefix, k) paste(sprintf("%s %d", prefix, seq_len(k)), collapse = ", ")

# The grid's factors: list(rows, columns), each list(role, levels).
whole_study_experiment_axes <- function(plan, values) {
  x <- whole_study_experiment_levels(values$x_levels)
  w <- if (plan$has_w) whole_study_experiment_levels(values$w_levels)
  if (!plan$has_w) return(list(rows = list(role = "X", levels = x), columns = NULL))
  if (identical(plan$x_factor, "A")) list(rows = list(role = "X", levels = x), columns = list(role = "W", levels = w))
  else list(rows = list(role = "W", levels = w), columns = list(role = "X", levels = x))
}

whole_study_mean_id <- function(i, j) sprintf("ws_mean_%d_%d", i, j)

whole_study_means_grid_ui <- function(plan, labels, values) {
  axes <- whole_study_experiment_axes(plan, values)
  rows <- axes$rows$levels
  cols <- if (is.null(axes$columns)) "Mean" else axes$columns$levels
  if (length(rows) < 2 || (!is.null(axes$columns) && length(cols) < 2)) {
    return(p(class = "text-muted", "Name at least two levels of each factor above to enter the means."))
  }
  cell <- function(i, j) {
    id <- whole_study_mean_id(i, j)
    name <- if (is.null(axes$columns)) rows[i] else sprintf("%s, %s", rows[i], cols[j])
    tags$td(tags$input(id = id, type = "text", inputmode = "decimal", class = "form-control",
      value = values$means[[id]] %||% "", `aria-label` = sprintf("Mean of %s: %s", labels[["Y"]], name)))
  }
  div(class = "table-responsive", tags$table(class = "table table-sm ws-means",
    tags$caption(sprintf("Expected mean of %s in each %s", labels[["Y"]], if (is.null(axes$columns)) "condition" else "cell")),
    tags$thead(tags$tr(tags$th(scope = "col", labels[[axes$rows$role]]),
      lapply(cols, function(c) tags$th(scope = "col", if (is.null(axes$columns)) c else sprintf("%s: %s", labels[[axes$columns$role]], c))))),
    tags$tbody(lapply(seq_along(rows), function(i) tags$tr(tags$th(scope = "row", rows[i]),
      lapply(seq_along(cols), function(j) cell(i, j)))))))
}

whole_study_experiment_ui <- function(forms, plan, labels, n, rule, values = list(), problem = NULL) {
  rule_words <- c(each = "each main result is a separate claim", all = "the claim needs every main result to be significant",
    any = "any one significant main result supports the claim")
  value_of <- function(key, default = "") values[[key]] %||% default
  design_words <- if (!plan$has_w) {
    if (plan$x_within) "the same people in each condition: a repeated-measures ANOVA" else "different people in each condition: a one-way ANOVA"
  } else if (plan$x_within) {
    sprintf("%s within participants crossed with groups of %s: a mixed ANOVA", labels[["X"]], labels[["W"]])
  } else {
    sprintf("%s crossed with %s, different people in each cell: a two-way ANOVA", labels[["X"]], labels[["W"]])
  }
  tagList(
    screen_nav_ui("guided:plan", "Back to your plan"),
    h2("Simulate the whole study ", tags$span(class = "badge bg-warning text-dark", "Experimental")),
    p(class = "lead", "Describe your experiment once. Every planned test is then run on the same simulated studies."),
    div(class = "alert alert-warning", role = "note",
      "The method is new in powerkit and is waiting for a statistician's check. The results may change. Use them to explore your plan, not to report."),
    if (!is.null(problem)) div(class = "form-problems", role = "alert", tabindex = "-1", h3(class = "h5", "Please check"), tags$ul(lapply(problem, tags$li))),
    h3(class = "h5", "Your analyses"),
    p(sprintf("Your study is an experiment with %s. Each analysis is one of its F tests, all from the same ANOVA on the same data.", design_words)),
    tags$ul(lapply(plan$analyses, function(a) tags$li(whole_study_experiment_label(a$id, labels), " ",
      tags$span(class = if (a$role == "main") "badge bg-primary" else "badge bg-secondary", if (a$role == "main") "Main analysis" else "Extra analysis")))),
    p(tags$strong("Your claim:"), paste0(" ", rule_words[[rule]], ".")),
    whole_study_name_inputs(plan$roles, labels),
    h3(class = "h5", "Your experiment"),
    textInput("ws_x_levels", sprintf("Levels of %s (separate them with commas)", labels[["X"]]),
      value = value_of("x_levels", whole_study_experiment_default_levels("Condition", plan$x_levels)), width = "100%"),
    if (plan$has_w) textInput("ws_w_levels", sprintf("Levels of %s (separate them with commas)", labels[["W"]]),
      value = value_of("w_levels", whole_study_experiment_default_levels("Group", plan$w_levels)), width = "100%"),
    p(class = "text-muted", "The means you expect, in the outcome's own units. Their pattern sets every effect: equal means in a row and a column mean no effect there, and parallel rows mean no interaction."),
    uiOutput("ws_means_grid"),
    textInput("ws_sd", sprintf("SD of %s within each cell (the same in every cell)", labels[["Y"]]), value = value_of("sd"), width = "100%"),
    if (plan$x_within) textInput("ws_r", sprintf("Correlation between a person's scores in the conditions of %s", labels[["X"]]),
      value = value_of("r"), width = "100%"),
    h3(class = "h5", "Sample size and precision"),
    textInput("ws_n", "Total participants analysed (N)", value = values$n %||% (if (!is.null(n)) as.character(n) else ""), width = "100%"),
    p(class = "text-muted small", if (plan$x_within && !plan$has_w) "Everyone takes part in every condition." else "Split equally between the groups."),
    textInput("ws_alpha", "Significance level (alpha)", value = value_of("alpha", "0.05"), width = "100%"),
    p(class = "text-muted", sprintf(
      "This screen runs a quick look: %s simulated studies, so each power is within about ±%s percentage points (%s). For numbers to report, and to find the sample size you need, run the full simulation on your computer: the R script is offered with the result.",
      whole(forms$whole_study$quick_nrep), whole_study_precision(forms$whole_study$quick_nrep),
      duration_text(whole_study_seconds(forms, plan, forms$whole_study$quick_nrep)))),
    textInput("ws_seed", "Random seed (the same seed gives the same result)", value = value_of("seed", as.character(forms$default_seed)), width = "100%"),
    p(class = "text-muted small", "It runs in a separate process: you can cancel it, and leaving this screen stops it."),
    action_bar(actionButton("ws_run", "Run the simulation", class = "btn btn-primary")),
    uiOutput("ws_result")
  )
}

whole_study_experiment_label <- function(id, labels) {
  switch(id,
    compare = sprintf("The main effect of %s", labels[["X"]]),
    moderation = sprintf("Whether the effect of %s depends on %s (the interaction)", labels[["X"]], labels[["W"]]),
    id)
}

whole_study_experiment_values <- function(input, plan) {
  values <- list(x_levels = input$ws_x_levels %||% "", w_levels = input$ws_w_levels %||% "",
    sd = input$ws_sd %||% "", r = input$ws_r %||% "", n = input$ws_n %||% "", alpha = input$ws_alpha %||% "",
    seed = input$ws_seed %||% "")
  axes <- whole_study_experiment_axes(plan, values)
  cols <- max(1, length(axes$columns$levels))
  ids <- unlist(lapply(seq_along(axes$rows$levels), function(i) vapply(seq_len(cols), function(j) whole_study_mean_id(i, j), "")))
  values$means <- stats::setNames(lapply(ids, function(id) input[[id]] %||% ""), ids)
  values
}

# The whole-study spec for an experiment, or the problems in plain words.
whole_study_experiment_spec <- function(plan, labels, values, rule, nrep) {
  problems <- character()
  num <- function(x) suppressWarnings(as.numeric(trimws(x %||% "")))
  axes <- whole_study_experiment_axes(plan, values)
  rows <- axes$rows$levels
  cols <- axes$columns$levels
  if (length(rows) < 2) problems <- c(problems, sprintf("Levels of %s: name at least two, separated by commas.", labels[[axes$rows$role]]))
  if (!is.null(axes$columns) && length(cols) < 2) problems <- c(problems, sprintf("Levels of %s: name at least two, separated by commas.", labels[[axes$columns$role]]))
  if (anyDuplicated(c(rows)) || anyDuplicated(cols)) problems <- c(problems, "Give each level of a factor its own name.")
  if (length(problems)) return(list(problems = problems))
  ncols <- max(1, length(cols))
  means <- lapply(seq_along(rows), function(i) vapply(seq_len(ncols), function(j) num(values$means[[whole_study_mean_id(i, j)]]), numeric(1)))
  if (any(is.na(unlist(means)))) problems <- c(problems, "Means: enter a number in every cell.")
  sd <- num(values$sd)
  if (is.na(sd) || sd <= 0) problems <- c(problems, "SD: enter a number above 0.")
  r <- NULL
  if (plan$x_within) {
    r <- num(values$r)
    if (is.na(r) || r <= -1 || r >= 1) problems <- c(problems, "Correlation: enter a number strictly between -1 and 1, such as 0.5.")
  }
  n <- num(values$n)
  if (is.na(n) || n != round(n) || n < 4) problems <- c(problems, "Total participants: enter a whole number.")
  alpha <- num(values$alpha)
  if (is.na(alpha) || alpha <= 0 || alpha >= 1) problems <- c(problems, "Significance level: enter a number between 0 and 1, such as 0.05.")
  seed <- num(values$seed)
  if (is.na(seed) || seed != round(seed) || seed < 1 || seed > 2147483647) problems <- c(problems, "Random seed: enter a whole number of 1 or more.")
  if (length(problems)) return(list(problems = problems))
  factor_type <- function(role) if (identical(role, "X") && plan$x_within) "within_factor" else "between_factor"
  variables <- list(A = list(type = factor_type(axes$rows$role), label = labels[[axes$rows$role]], levels = as.list(rows)))
  if (!is.null(axes$columns)) variables$B <- list(type = factor_type(axes$columns$role), label = labels[[axes$columns$role]], levels = as.list(cols))
  variables$Y <- list(type = "continuous", label = labels[["Y"]])
  template <- if (is.null(axes$columns)) {
    if (plan$x_within) "oneway_within" else "oneway_between"
  } else if (plan$x_within) {
    if (length(rows) == 2 && length(cols) == 2) "2x2_mixed" else "mixed"
  } else {
    if (length(rows) == 2 && length(cols) == 2) "2x2_between" else "factorial_between"
  }
  population <- list(metric = "raw", means = if (is.null(axes$columns)) as.list(unlist(means)) else lapply(means, as.list), sd = sd)
  if (!is.null(r)) population$r <- r
  experiment <- list(spec_version = "0.1", design = "factorial_anova", template = template, variables = variables,
    population = population, target_test = list(method = "anova_f"))
  analyses <- lapply(plan$analyses, function(a) { a$label <- whole_study_experiment_label(a$id, labels); a })
  list(spec = list(spec_version = "0.1", kind = "whole_study", experiment = experiment, analyses = analyses,
    claim = rule, alpha = alpha, effect_justification = list(type = "none"),
    goal = list(type = "power", n = as.integer(n)),
    options = list(nrep = as.integer(nrep), seed = as.integer(seed))))
}
