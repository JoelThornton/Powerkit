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

whole_study_tests <- c(E4 = "x_y", E9 = "interaction", E10 = "indirect", E11 = "indirect",
  E12 = "indirect", E13 = "index_of_mome", E14 = "index_of_mome",
  E2 = "x_y", E15 = "interaction", E16 = "indirect")

# Plain names for the variables and product terms in path labels.
whole_study_names <- c(X = "the predictor (X)", Y = "the outcome (Y)", W = "the moderator (W)",
  M = "the mediator (M)", M1 = "the first mediator (M1)", M2 = "the second mediator (M2)",
  XW = "the predictor x moderator interaction (XW)", MW = "the mediator x moderator interaction (MW)")

whole_study_path_label <- function(key) {
  if (identical(key, "X<->W")) return("Correlation of the predictor with the moderator (X with W)")
  if (identical(key, "M1<->M2")) return("Correlation of the two mediators' residuals (what M1 and M2 share beyond X)")
  ends <- strsplit(key, "->", fixed = TRUE)[[1]]
  sprintf("Path %s → %s: from %s to %s", ends[1], ends[2], whole_study_names[[ends[1]]], whole_study_names[[ends[2]]])
}

whole_study_input_id <- function(key) paste0("ws_", gsub("[^A-Za-z0-9]", "_", key))

# Whether the plan can be simulated as a whole study, and if so the
# engine's analyses and variables. Returns list(ok, reasons, analyses,
# variables, mediators, path_choices).
whole_study_plan <- function(tree, answers, ticked, primary, asks) {
  reasons <- character()
  if (!answers$x %in% c("score", "cond2")) reasons <- c(reasons, "the main predictor (X) is a measured score or two groups or conditions")
  if (!identical(answers$outcome, "score")) reasons <- c(reasons, "the outcome is a score")
  if (!identical(answers$covariate %||% "none", "none")) reasons <- c(reasons, "there are no covariates")
  if (!identical(answers$times %||% "once", "once")) reasons <- c(reasons, "each person is measured once")
  if (!answers$moderator %in% c("none", "score")) reasons <- c(reasons, "the moderator, if any, is a measured score")
  if (!answers$mediators %in% c("none", "one", "several")) reasons <- c(reasons, "the mediators, if any, are scores")
  if (length(intersect(ticked, primary)) == 0) reasons <- c(reasons, "at least one analysis is a main analysis")
  endpoints <- vapply(ticked, function(id) {
    resolve_analysis(tree, analysis_by_id(tree, id), answers, asks[[id]])$endpoint %||% ""
  }, character(1))
  outside <- ticked[!endpoints %in% names(whole_study_tests)]
  if (length(outside)) {
    reasons <- c(reasons, sprintf("every analysis is one the simulation covers (not yet: %s)",
      paste(vapply(outside, function(id) analysis_by_id(tree, id)$label, ""), collapse = "; ")))
  }
  if (length(ticked) == 0) reasons <- c(reasons, "at least one analysis is planned")
  if (length(reasons)) return(list(ok = FALSE, reasons = reasons))

  mediators <- switch(answers$mediators, one = "M", several = c("M1", "M2"), character())
  link <- c(E13 = "x_m", E14 = "m_y")
  serial <- "E12" %in% endpoints
  analyses <- lapply(seq_along(ticked), function(i) {
    id <- ticked[i]
    ep <- endpoints[[i]]
    a <- list(id = id, label = analysis_by_id(tree, id)$label, test = whole_study_tests[[ep]],
      role = if (id %in% primary) "main" else "extra")
    if (identical(a$test, "indirect")) a$path <- if (length(mediators) == 1) "X->M->Y" else if (serial) "X->M1->M2->Y" else "X->M1->Y"
    if (identical(a$test, "index_of_mome")) a$moderated_link <- link[[ep]]
    a
  })
  tests <- vapply(analyses, function(a) a$test, "")
  roles <- c("X", if (any(tests %in% c("interaction", "index_of_mome"))) "W",
    if (any(tests %in% c("indirect", "index_of_mome"))) mediators, "Y")
  path_choices <- if (length(mediators) == 2 && "indirect" %in% tests) {
    if (serial) c("X->M1->M2->Y", "X->M1->Y", "X->M2->Y") else c("X->M1->Y", "X->M2->Y")
  }
  list(ok = TRUE, analyses = analyses, roles = roles, binary_x = identical(answers$x, "cond2"),
    mediators = if (length(mediators) == 2 && any(tests %in% c("indirect", "index_of_mome"))) (if (serial) "serial" else "parallel"),
    path_choices = path_choices)
}

# The variables' names: from what the user typed on the plan's input
# screens, else the role names.
whole_study_labels <- function(roles, plan_values) {
  defaults <- c(X = "Predictor", Y = "Outcome", W = "Moderator", M = "Mediator", M1 = "First mediator", M2 = "Second mediator")
  out <- defaults[roles]
  for (r in roles) {
    for (values in plan_values) {
      typed <- values[[paste0(r, "_label")]]
      if (!is.null(typed) && length(typed) == 1 && nzchar(trimws(typed))) {
        out[[r]] <- trimws(typed)
        break
      }
    }
  }
  out
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
    index = "Index of moderated mediation", rc_M1_M2 = "Residual correlation of M1 with M2")
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
  r_needs <- backend_r_requirement("power4mome")
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
    downloadButton("ws_download_script", "Download R script for the full simulation", class = "btn btn-primary"))
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
  div(
    class = "result-panel whole-study-result", role = "status", tabindex = "-1",
    h3(class = "h4", "Result"),
    if (!is.null(script)) p(class = "alert alert-info", role = "note", sprintf(
      "A quick look, from %s simulated studies: each power is within about \u00b1%s percentage points. For numbers to report, and for the sample size you need, run the full simulation on your computer (below).",
      whole(r$provenance$nrep), whole_study_precision(r$provenance$nrep))),
    if (!is.null(joint) && !identical(r$claim, "each")) p(class = "lead", HTML(sprintf(
      "With <strong>N = %s</strong>, the chance that %s in the same study is <strong>%s</strong> (95%% interval %s to %s).",
      whole(r$n), rule_text[[joint$rule]], percent(joint$power), percent(joint$lower), percent(joint$upper)))),
    tags$table(class = "table table-sm ws-table",
      tags$thead(tags$tr(tags$th("Analysis"), tags$th("Role"), tags$th("Tested at alpha"), tags$th("Power"), tags$th("95% interval"))),
      tags$tbody(lapply(seq_len(nrow(a)), function(i) tags$tr(
        tags$td(a$label[i]), tags$td(if (a$role[i] == "main") "Main" else "Extra"),
        tags$td(format(signif(a$alpha[i], 3))), tags$td(tags$strong(percent(a$power[i]))),
        tags$td(sprintf("%s to %s", percent(a$lower[i]), percent(a$upper[i]))))))),
    if (identical(r$claim, "each")) p(class = "text-muted", "Each main result is a separate claim, so each analysis's own power is what matters."),
    if (identical(r$claim, "any")) p(class = "text-muted", sprintf(
      "Your claim counts any one significant main result, so each main analysis is tested at alpha divided by the number of main analyses (Bonferroni), as on the plan's input screens.")),
    p(sprintf("From %s simulated studies of %s participants. Each analysis is fitted with its own model, as it would be analysed on its own: the power of each comes from the same simulated studies, so the chance that several succeed together is counted directly, not assumed.",
      whole(pv$nrep), whole(r$n))),
    h4(class = "h5", "What your study model means for each analysis's own input screen"),
    p(class = "text-muted", "Estimated from one very large simulated sample. If you calculated an analysis separately, compare these with what you entered: where they differ, the separate calculations describe different studies."),
    lapply(r$implied, function(imp) {
      own <- plan_values[[imp$id]] %||% list()
      label <- a$label[a$id == imp$id]
      tagList(tags$p(tags$strong(label)),
        tags$table(class = "table table-sm ws-implied",
          tags$thead(tags$tr(tags$th("Value"), tags$th("Implied by your study model"), tags$th("You entered on its screen"))),
          tags$tbody(lapply(names(imp$values), function(k) tags$tr(
            tags$td(whole_study_value_label(k)), tags$td(sprintf("%.3f", imp$values[[k]])),
            tags$td(own[[k]] %||% "—"))))))
    }),
    h4(class = "h5", "How this differs from calculating each analysis separately"),
    p(departure %||% "Separate calculations each describe their own study; this simulation uses one model of your study for all of them."),
    p(class = "text-muted", "This is recorded as a departure from the established tools in powerkit's conventions."),
    h4(class = "h5", "Methods paragraph (draft)"),
    p(class = "methods", whole_study_methods(r)),
    tags$details(tags$summary("Details for a statistician"),
      tags$pre(class = "small", paste0("Population model (lavaan syntax):\n", r$models$population,
        "\n\nPopulation values:\n", r$models$population_values,
        "\n\nAnalysis models:\n", paste(sprintf("%s: %s", a$id, gsub("\n", "; ", r$models$analyses)), collapse = "\n"),
        sprintf("\n\nCheck run (n = 100,000): %s", if (all(r$check_run$ok)) "passed" else "FAILED"))),
      p(class = "small", sprintf("Seed %s; %s simulated studies%s; spec hash %s; %s; power4mome %s, lavaan %s, manymome %s; powerkit %s. Run time %s seconds.",
        pv$seed, whole(pv$nrep), if (!is.na(pv$ci_draws)) sprintf("; %s Monte Carlo draws per confidence interval", whole(pv$ci_draws)) else "",
        pv$spec_hash, pv$r_version, pv$packages[["power4mome"]], pv$packages[["lavaan"]], pv$packages[["manymome"]], pv$packages[["powerkit"]],
        round(pv$run_time_seconds)))),
    script,
    downloadButton("ws_download_spec", "Download the specification (JSON)", class = "btn btn-outline-primary")
  )
}

whole_study_methods <- function(r) {
  a <- r$analyses
  pv <- r$provenance
  lower_first <- function(x) paste0(tolower(substr(x, 1, 1)), substr(x, 2, nchar(x)))
  powers <- paste(sprintf("%s for %s", percent(a$power), lower_first(a$label)), collapse = "; ")
  joint <- if (!is.null(r$joint) && !identical(r$claim, "each")) sprintf(
    " The proportion of simulated studies in which %s was %s.",
    if (r$joint$rule == "all") "every main analysis was significant" else "at least one main analysis was significant",
    percent(r$joint$power)) else ""
  sprintf(paste0(
    "Power was estimated by simulating the whole study (powerkit %s, experimental) with the R package power4mome %s. ",
    "One population model, specified as standardised paths, generated %s data sets of N = %s; each planned analysis was fitted to every data set with its own model ",
    "(regressions by ordinary least squares; mediation models in lavaan, with indirect effects tested by Monte Carlo confidence intervals) at alpha = %s%s. ",
    "Estimated power was %s.%s Random seed %s."),
    pv$packages[["powerkit"]], pv$packages[["power4mome"]], whole(pv$nrep), whole(r$n), format(r$alpha),
    if (identical(r$claim, "any")) " divided by the number of main analyses (Bonferroni)" else "",
    powers, joint, pv$seed)
}
