# Every screen renders from the data file, shows the prototype banner, and
# the app never calculates power itself: it builds specs and calls the
# engine (validate_spec(), run_spec() and the exports).

test_that("the banner says in plain words which designs calculate (judgement call B14)", {
  expect_match(tree$banner, "^Prototype, still being checked\\.")
  expect_match(tree$banner, "R script for the full run on your computer", fixed = TRUE)
  # No internal codes such as E1 or E10-E14.
  expect_false(grepl("E[0-9]", tree$banner))
  expect_match(as.character(prototype_banner(tree)), tree$banner, fixed = TRUE)
})

test_that("only cards that don't calculate say 'No numbers are calculated'", {
  for (id in c(unlist(forms$calculates), paste0("E", 10:14))) {
    expect_no_match(as.character(card_ui(tree, id)), "No numbers are calculated", fixed = TRUE, label = id)
  }
  for (id in c("E43", "E45")) {
    expect_match(as.character(card_ui(tree, id)), "No numbers are calculated", fixed = TRUE, label = id)
  }
})

test_that("every end-point card renders, with its status and inputs", {
  for (id in names(tree$endpoints)) {
    html <- as.character(card_ui(tree, id))
    expect_match(html, htmltools::htmlEscape(tree$endpoints[[id]]$plain_name), fixed = TRUE, label = id)
    if (!is.null(tree$endpoints[[id]]$inputs)) expect_match(html, "What you would enter", fixed = TRUE, label = id)
    expected <- if (isTRUE(tree$endpoints[[id]]$generic)) tree$endpoints[[id]]$card_heading %||% "Not in powerkit yet." else switch(tree$endpoints[[id]]$status,
      runs_validated = "Validated: ", runs_validation_in_progress = "Runs, validation in progress.",
      coming_soon = "Coming soon.",
      not_in_powerkit = if (isTRUE(tree$endpoints[[id]]$no_ready_made_tool)) "Not in powerkit yet." else tree$endpoints[[id]]$not_in_powerkit_heading %||% "Not in powerkit yet: use")
    expect_match(html, expected, fixed = TRUE, label = id)
  }
})

test_that("validated cards link to the validation log", {
  html <- as.character(card_ui(tree, "E7"))
  expect_match(html, tree$links$validation_log, fixed = TRUE)
})

test_that("in-progress cards are labelled differently from validated ones", {
  # No end point is in progress at the moment, so mark one on a copy.
  staged <- tree
  staged$endpoints$E9$status <- "runs_validation_in_progress"
  in_progress <- as.character(card_ui(staged, "E9"))
  expect_match(in_progress, "status-in-progress", fixed = TRUE)
  expect_match(in_progress, "Validation in progress", fixed = TRUE)
  expect_no_match(in_progress, "status-runs\"", fixed = TRUE)
  expect_no_match(as.character(card_ui(tree, "E7")), "status-in-progress", fixed = TRUE)
})

test_that("end points with no ready-made tool say so plainly, with the two options", {
  text <- htmltools::htmlEscape(tree$no_ready_made_tool_text)
  expect_match(text, "custom simulation in R", fixed = TRUE)
  expect_match(text, "statistician", fixed = TRUE)
  for (id in c("E30", "E32", "E39", "E42")) {
    html <- as.character(card_ui(tree, id))
    expect_match(html, "No ready-made tool.", fixed = TRUE, label = id)
    expect_match(html, text, fixed = TRUE, label = id)
  }
  e26 <- as.character(card_ui(tree, "E26"))
  expect_match(e26, htmltools::htmlEscape("Cochran's Q:"), fixed = TRUE)
  expect_match(e26, text, fixed = TRUE)
})

test_that("end points outside the five tools say so", {
  for (id in names(tree$endpoints)) {
    if (!identical(tree$endpoints[[id]]$five_tools, "not covered")) next
    expect_match(as.character(card_ui(tree, id)), "Not covered by the five tools", fixed = TRUE, label = id)
  }
  expect_match(as.character(card_ui(tree, "E42")), "Not covered by the five tools", fixed = TRUE)
})

test_that("every question screen renders with a back button", {
  for (id in names(Filter(Negate(is_automatic), tree$nodes))) {
    html <- as.character(node_ui(tree, id, list()))
    expect_match(html, htmltools::htmlEscape(tree$nodes[[id]]$text), fixed = TRUE, label = id)
    expect_match(html, "&#39;back&#39;", fixed = TRUE, label = id)
  }
})

test_that("'I know my analysis' can skip the screening; the other routes can't", {
  skip <- tree$routes$skip_screening
  screening <- names(Filter(function(n) n$doc_id %in% c("S1", "S2", "S3", "S4", "O5a", "T1"), tree$nodes))
  expect_gte(length(screening), 4)
  for (id in screening) {
    known <- as.character(node_ui(tree, id, list(), list(), "known"))
    expect_match(known, "&#39;skip_screening&#39;", fixed = TRUE, label = id)
    expect_match(known, htmltools::htmlEscape(skip$label), fixed = TRUE, label = id)
    # The design finder and the guided plan need the answers to route at
    # all, so neither offers the skip.
    for (route in c("choose", "guided")) {
      expect_no_match(as.character(node_ui(tree, id, list(), list(), route)),
        "skip_screening", fixed = TRUE, label = paste(id, route))
    }
  }
  # A question that isn't screening doesn't offer it either.
  expect_no_match(as.character(node_ui(tree, "q1", list(), list(), "known")),
    "skip_screening", fixed = TRUE)
})

test_that("the skipped list holds every analysis and offers the questions as a filter", {
  all_of_them <- as.character(known_ui(tree, list(), NULL))
  for (id in names(tree$endpoints)) {
    expect_match(all_of_them, sprintf("&#39;ep:%s&#39;", id), fixed = TRUE, label = id)
  }
  # It says how many, and that nothing was screened out.
  expect_match(all_of_them, sprintf(tree$routes$skip_screening$note, length(tree$endpoints)), fixed = TRUE)
  expect_no_match(all_of_them, "that fit your screening answers", fixed = TRUE)
  # And it offers the screening questions instead.
  expect_match(all_of_them, "&#39;screen_me&#39;", fixed = TRUE)
  expect_match(all_of_them, htmltools::htmlEscape(tree$routes$skip_screening$filter_label), fixed = TRUE)

  # With screening answers the list is filtered, and says so.
  ctx <- list(outcome = "score", times = "once")
  filtered <- as.character(known_ui(tree, list(), ctx))
  fits <- length(endpoints_for_context(tree, ctx))
  expect_lt(fits, length(tree$endpoints))
  expect_match(filtered, sprintf("Showing the %d of %d analyses", fits, length(tree$endpoints)), fixed = TRUE)
  expect_no_match(filtered, "screen_me", fixed = TRUE)
})

test_that("the skip is part of 'where you are', so Back and Forward restore it", {
  expect_true("skip_screening" %in% nav_fields)
})

test_that("undecided settings show a labelled placeholder; decided ones show the decision", {
  s <- setting_by_key(tree, "simple_effects_target")
  expect_null(s$value)
  expect_match(as.character(placeholder_ui(s)), "Undecided: for the maintainer", fixed = TRUE)
  html <- as.character(placeholder_ui(setting_by_key(tree, "observed_power")))
  expect_match(html, "Maintainer decision", fixed = TRUE)
  expect_match(html, "Warn and allow", fixed = TRUE)
})

test_that("cards show undecided settings as compact labelled placeholders, in the maintainer's view", {
  withr::local_options(powerkit.maintainer_view = TRUE)
  html <- as.character(card_ui(tree, "E7"))
  expect_match(html, "Undecided, for the maintainer", fixed = TRUE)
  expect_match(html, "Judgement call 3.1", fixed = TRUE)
  html_not <- as.character(card_ui(tree, "E35"))
  expect_match(html_not, "Open question 6", fixed = TRUE)
})

test_that("the public view shows no settings for the maintainer, decided or not", {
  withr::local_options(powerkit.maintainer_view = FALSE)
  for (id in names(tree$endpoints)) {
    html <- as.character(card_ui(tree, id))
    expect_false(grepl("for the maintainer|Maintainer decision|Judgement call|Open question [0-9]", html), label = id)
  }
  expect_false(grepl("for the maintainer|Maintainer decision", as.character(start_ui(tree))))
  expect_null(placeholders_at(tree, "card"))
})

test_that("the maintainer's view is asked for by the environment or the address", {
  withr::local_envvar(POWERKIT_MAINTAINER_VIEW = "")
  expect_false(maintainer_view_requested(""))
  expect_false(maintainer_view_requested("?view=public"))
  expect_true(maintainer_view_requested("?view=maintainer"))
  withr::local_envvar(POWERKIT_MAINTAINER_VIEW = "true")
  expect_true(maintainer_view_requested(""))
  # The tab is only built into the page in that view.
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, 'if (maintainer_view_requested(req$QUERY_STRING)) tabPanel("For the maintainer', fixed = TRUE)
})

test_that("deciding against the guided route hides it, with no code change", {
  expect_match(as.character(start_ui(tree)), "Plan my whole study", fixed = TRUE)
  t2 <- tree
  for (i in seq_along(t2$settings)) if (t2$settings[[i]]$key == "guided_route") t2$settings[[i]]$value <- "no"
  expect_false(grepl("Plan my whole study", as.character(start_ui(t2)), fixed = TRUE))
})

test_that("the plan screen offers the experimental whole-study simulation only where it applies, and shows no numbers before any calculation", {
  answers <- list(x = "cond2", outcome = "score", mediators = "one", moderator = "score", covariate = "baseline")
  html <- as.character(guided_plan_ui(tree, answers, c("compare", "moderation", "mediation"), c("compare", "moderation", "mediation"),
    list(compare = "ANCOVA: the outcome adjusting for the baseline"), "any"))
  expect_match(html, "Simulating the whole study at once \\(experimental\\) isn.{1,5}t available for this plan")
  expect_false(grepl("guided:simulate", html, fixed = TRUE))
  # The plan the simulation covers leads with it, and folds the separate
  # calculations below.
  covered <- list(x = "score", outcome = "score", mediators = "one", moderator = "none", covariate = "none", times = "once")
  html2 <- as.character(guided_plan_ui(tree, covered, c("compare", "mediation"), c("compare", "mediation"), list(), "all", forms = forms))
  expect_match(html2, "Your whole study in one go", fixed = TRUE)
  expect_match(html2, "guided:simulate", fixed = TRUE)
  expect_lt(regexpr("Your whole study in one go", html2, fixed = TRUE), regexpr("Or calculate each analysis on its own", html2, fixed = TRUE))
  expect_match(html, "The plan then shows the largest", fixed = TRUE)
  expect_false(grepl("N = ", html, fixed = TRUE))
  expect_false(grepl("once the engine is connected", html, fixed = TRUE))
  expect_match(html, "The effect of x on the outcome appears in", ignore.case = TRUE)
  expect_match(html, "needs an alpha correction", fixed = TRUE)
  expect_match(html, "E23", fixed = TRUE)
  expect_match(html, "E15", fixed = TRUE)
  expect_match(html, "E16", fixed = TRUE)
})

test_that("the plan opens each analysis's input screen, where powerkit has one", {
  answers <- list(x = "cond2", outcome = "score", mediators = "one", moderator = "score", covariate = "baseline", times = "once")
  ticked <- c("compare", "moderation", "mediation")
  asks <- list(compare = "ANCOVA: the outcome adjusting for the baseline")
  html <- as.character(guided_plan_ui(tree, answers, ticked, c("compare", "mediation"), asks, "any", forms = forms))
  # ANCOVA (E23) and the condition x score interaction (E15) have input
  # screens; mediation with a two-group X (E16) doesn't yet.
  for (id in ticked) {
    ep <- resolve_analysis(tree, analysis_by_id(tree, id), answers, asks[[id]])$endpoint
    expect_identical(grepl(sprintf("gform:%s&#39;", id), html, fixed = TRUE), has_form(forms, ep), label = id)
  }
  expect_match(html, "gform:compare&#39;", fixed = TRUE)
  # Two main analyses and "any one": the claim and the number of tests go to
  # the input screen. An extra analysis, or a lone main one, stands alone.
  expect_identical(plan_form_start(list(aim = "predict"), "compare", c("compare", "mediation"), "any")[c("claim", "n_tests")],
    list(claim = "any", n_tests = 2L))
  expect_identical(plan_form_start(list(), "compare", c("compare", "mediation"), "each")$claim, "each")
  expect_null(plan_form_start(list(), "compare", c("compare", "mediation"), "each")$n_tests)
  expect_identical(plan_form_start(list(claim = "all"), "moderation", c("compare", "mediation"), "all")$claim, "one")
  expect_identical(plan_form_start(list(claim = "all"), "compare", "compare", "all")$claim, "one")
  # The input screen's back button returns to the plan.
  expect_match(as.character(form_ui(tree, forms, "E23", form_groups(forms, "E23"), from_plan = TRUE)), "Back to my plan", fixed = TRUE)
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, 'kind == "gform"', fixed = TRUE)
  expect_match(code, 'if (identical(state$came_from, "plan")) "g_plan" else "card"', fixed = TRUE)
})

test_that("the plan's combined sample size is the largest N among the main analyses, named", {
  # A score X with one mediator and a score moderator: the comparison is a
  # correlation (E4) and the moderation is E9, both with input screens.
  answers <- list(x = "score", outcome = "score", mediators = "none", moderator = "score", covariate = "none", times = "once")
  ticked <- c("compare", "moderation")
  ep <- function(id) resolve_analysis(tree, analysis_by_id(tree, id), answers)$endpoint
  expect_true(has_form(forms, ep("compare")) && has_form(forms, ep("moderation")))
  plan <- function(results, primary = ticked) as.character(guided_plan_ui(tree, answers, ticked, primary, list(), "all", forms = forms, results = results))
  one <- list(compare = list(endpoint = ep("compare"), goal = "sample_size", n = 84))
  html <- plan(one)
  expect_match(html, "Largest so far: <strong>N = 84</strong>", fixed = TRUE)
  expect_match(html, "Still to calculate: Whether the effect of X depends on the moderator", fixed = TRUE)
  expect_match(html, "Change your values", fixed = TRUE)
  both <- c(one, list(moderation = list(endpoint = ep("moderation"), goal = "sample_size", n = 1200)))
  html <- plan(both)
  expect_match(html, "Your study needs <strong>N = 1,200</strong>", fixed = TRUE)
  expect_match(html, "(Whether the effect of X depends on the moderator (X x W))", fixed = TRUE)
  expect_false(grepl("Still to calculate", html, fixed = TRUE))
  # An extra analysis doesn't count, however large its N.
  html <- plan(both, primary = "compare")
  expect_match(html, "Your study needs <strong>N = 84</strong>", fixed = TRUE)
  # Power instead of N: not counted, and the plan says why.
  html <- plan(list(compare = list(endpoint = ep("compare"), goal = "power", n = NULL)))
  expect_match(html, "calculate the sample size", fixed = TRUE)
  expect_false(grepl("<strong>N = ", html, fixed = TRUE))
  # A result for an end point the analysis no longer leads to is ignored.
  html <- plan(list(compare = list(endpoint = "E2", goal = "sample_size", n = 50)))
  expect_false(grepl("N = 50", html, fixed = TRUE))
  # A main analysis powerkit can't calculate is named as one to work out elsewhere.
  med <- list(x = "cond2", outcome = "score", mediators = "one", moderator = "none", covariate = "none", times = "once")
  html <- as.character(guided_plan_ui(tree, med, c("compare", "mediation"), c("compare", "mediation"), list(), "each", forms = forms,
    results = list(compare = list(endpoint = "E2", goal = "sample_size", n = 128))))
  expect_match(html, "work out their sample size elsewhere", fixed = TRUE)
  expect_match(html, "Largest so far", fixed = TRUE)
  # The calculations are kept from the input screen and restored with Back.
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "state$plan_results[[state$plan_id]] <-", fixed = TRUE)
  expect_true("plan_results" %in% nav_fields)
})

test_that("a value two analyses on the plan share is entered once and fills the other's input screen", {
  # Every shared value names a real field on each input screen it lists.
  for (v in tree$guided$shared_values) for (ep in names(v$fields)) {
    ids <- vapply(form_fields(form_groups(forms, ep)), `[[`, "", "id")
    expect_true(v$fields[[ep]] %in% ids, label = paste(v$id, ep))
  }
  # Mediation (E10) and moderated mediation (E13) share the X -> M path.
  shared <- harvest_shared(tree, "E10", list(p_X_M = "0.3", p_M_Y = "0.25", p_X_Y = "", n = "200"), "mediation")
  expect_identical(shared$p_x_m, list(value = "0.3", from = "mediation"))
  expect_null(shared$p_x_y)  # empty values aren't shared
  start <- plan_form_values(tree, "E13", own = list(p_X_M = "0.1", p_W_M = "0.2"), shared = shared)
  expect_identical(start$values$p_X_M, "0.3")   # the latest shared value wins
  expect_identical(start$values$p_W_M, "0.2")   # the analysis's own values stay
  expect_identical(start$values$p_M_Y, "0.25")
  expect_setequal(names(start$filled), c("p_x_m", "p_m_y"))
  note <- as.character(carried_note_ui(tree, start$filled))
  expect_match(note, "Filled in from your plan", fixed = TRUE)
  expect_match(note, "Path X -&gt; M", fixed = TRUE)
  expect_match(note, "from Whether X affects the outcome through the mediator(s)", fixed = TRUE)
  expect_null(carried_note_ui(tree, character()))
  # An end point that asks for none of them gets nothing.
  expect_identical(plan_form_values(tree, "E2", list(d = "0.5"), shared)$values, list(d = "0.5"))
  # On the plan: a score X and moderator, with the comparison (E4) and the
  # moderation (E9) ticked, share the correlation of X with the outcome.
  answers <- list(x = "score", outcome = "score", mediators = "none", moderator = "score", covariate = "none", times = "once")
  html <- as.character(guided_plan_ui(tree, answers, c("compare", "moderation"), "compare", list(), "each", forms = forms,
    shared = list(r_x_y = list(value = "0.3", from = "compare"))))
  expect_match(html, "Enter these once", fixed = TRUE)
  expect_match(html, "<strong>Correlation of X with the outcome</strong>", fixed = TRUE)
  expect_match(html, "0.3 (entered for The effect of X on the outcome)", fixed = TRUE)
  # The correlation of X with the moderator is asked by E9 only here.
  expect_false(grepl("Correlation of X with the moderator", html, fixed = TRUE))
  # The input screen shows the note when values were carried.
  expect_match(as.character(form_ui(tree, forms, "E13", form_groups(forms, "E13"), from_plan = TRUE, carried = carried_note_ui(tree, start$filled))),
    "Filled in from your plan", fixed = TRUE)
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "plan_form_values(tree, res$endpoint, state$plan_values[[value]], state$plan_shared)", fixed = TRUE)
  expect_true(all(c("plan_values", "plan_shared", "plan_filled") %in% nav_fields))
})

test_that("the app never computes power itself: it only calls the engine's run_spec(), validate_spec(), exports and whole-study checks", {
  files <- c(file.path(routing_dir, "app.R"), list.files(file.path(routing_dir, "R"), full.names = TRUE))
  code <- paste(unlist(lapply(files, readLines)), collapse = "\n")
  # No backend package, power formula or engine internals are called directly.
  for (pattern in c("powerkit::", "powerkit:::", "Spower::", "Superpower::", "power4mome::", "InteractionPoweR::", "power.t.test", "pwr::", "search_n(")) {
    expect_false(grepl(pattern, code, fixed = TRUE), label = pattern)
  }
  # Engine functions are taken by name through engine_function(), and only
  # these (CLAUDE.md: the app builds specs and calls the engine).
  used <- regmatches(code, gregexpr('engine_function\\("[^"]+"', code))[[1]]
  used <- unique(sub('engine_function\\("', "", sub('"$', "", used)))
  expect_setequal(used, c("validate_spec", "run_spec", "export_script", "export_citations", "export_run_script", "simulated_data", "simulated_data_available", "power_interval",
    "write_project", "read_project", "validate_whole_study", "whole_study_parameters", "export_whole_study_script"))
  # Calculations run only for the end points listed in forms.yaml.
  expect_setequal(unlist(forms$calculates), c(paste0("E", 1:9), "E18", "E19", "E20", "E21", "E23", "E24", "E25", "E26", "E27", "E28", "E34", "E36", "E37", "E48", "E49", "E50", "E51", "E52", "E53", "E54", "E55", "E56", "E57", "E31", "E29", "E47", "E22"))
})

test_that("each card lists only the closing questions that apply to it", {
  e5 <- as.character(card_ui(tree, "E5"))
  expect_no_match(e5, "how reliable your measures are", fixed = TRUE)
  expect_match(e5, "Which version of the test?", fixed = TRUE) # the z test or Fisher's exact test
  expect_match(e5, "Does your hypothesis predict a direction?", fixed = TRUE)
  e6 <- as.character(card_ui(tree, "E6"))
  expect_no_match(e6, "Which version of the test?", fixed = TRUE)
  e9 <- as.character(card_ui(tree, "E9"))
  expect_match(e9, "how reliable your measures are", fixed = TRUE)
  expect_no_match(e9, "Does your hypothesis predict a direction?", fixed = TRUE)
  e2 <- as.character(card_ui(tree, "E2"))
  expect_match(e2, "Student&#39;s or Welch&#39;s t-test.|Student's or Welch's t-test.")
  e7 <- as.character(card_ui(tree, "E7"))
  expect_match(e7, "All three are available for this design.", fixed = TRUE)
  expect_match(e5, "isn&#39;t available for this design yet|isn't available for this design yet")
})

test_that("every technical term in 'What you would enter' has a plain-English hint beside it", {
  jargon <- c("Cohen", "d_z", "\\bSD", "correlation", "cell", "reliab", "standardised", "Monte Carlo", "residual",
    "indirect", "contrast", "adjusted", "covariate", "R-squared", "discordant", "odds", "coefficient", "rate ratio",
    "product", "fixed effects", "variance", "ICC", "cluster", "equivalence", "RMSEA", "breakpoint", "autocorrelation",
    "prior", "mediator", "predictor", "interaction", "factor", "\\bCI\\b", "parameters", "Welch")
  for (id in names(tree$endpoints)) {
    for (input in tree$endpoints[[id]]$inputs) {
      hits <- jargon[vapply(jargon, function(j) grepl(j, input, ignore.case = TRUE, perl = TRUE), logical(1))]
      if (length(hits) == 0) next
      expect_gt(length(glossary_for(tree, input)), 0, label = paste(id, input))
    }
  }
  html <- as.character(card_ui(tree, "E26"))
  expect_match(html, "<dfn>discordant proportions</dfn>", fixed = TRUE)
})

test_that("hints explain terms and never suggest a value to choose", {
  for (g in tree$glossary) {
    expect_no_match(g$hint, "\\b(small|medium|large|typical)\\b|usually choose|we recommend|should be|default", label = g$term)
  }
})

test_that("the note on other defensible analyses is off until the maintainer turns it on", {
  covered <- names(Filter(function(e) e$status %in% c("runs_validated", "runs_validation_in_progress", "coming_soon"), tree$endpoints))
  expect_setequal(names(Filter(function(e) !is.null(e$alternatives), tree$endpoints)), covered)
  expect_null(setting_by_key(tree, "other_analyses_note")$value)
  for (id in covered) expect_no_match(as.character(card_ui(tree, id)), "Other defensible analyses exist", fixed = TRUE, label = id)
  t2 <- tree
  for (i in seq_along(t2$settings)) if (t2$settings[[i]]$key == "other_analyses_note") t2$settings[[i]]$value <- "show"
  for (id in covered) {
    html <- as.character(card_ui(t2, id))
    expect_match(html, "Other defensible analyses exist for this design (e.g.", fixed = TRUE, label = id)
    expect_match(html, "Power the analysis you plan to run.", fixed = TRUE, label = id)
  }
  expect_no_match(as.character(card_ui(t2, "E43")), "Other defensible analyses exist", fixed = TRUE)
})

test_that("the safety-net card says what to write down for a statistician, using the screening answers", {
  html <- as.character(card_ui(tree, "E-unsure"))
  expect_match(html, "What to write down for a statistician", fixed = TRUE)
  for (it in tree$safety_net$prepare$items) expect_match(html, htmltools::htmlEscape(it$label), fixed = TRUE)
  expect_match(html, "not answered yet", fixed = TRUE)
  history <- list(
    list(node = "s1", answer = "A score or scale", ctx = list()),
    list(node = "s2", answer = "Independent people", ctx = list(outcome = "score")),
    list(node = "s3", answer = "Once", ctx = list(outcome = "score")),
    list(node = "q1", answer = tree$safety_net$label, ctx = list(outcome = "score", times = "once"))
  )
  html <- as.character(card_ui(tree, "E-unsure", history = history))
  for (a in c("A score or scale", "Independent people", "Once")) expect_match(html, a, fixed = TRUE)
  expect_no_match(html, "not answered yet", fixed = TRUE)
  expect_match(html, "Where nothing fitted", fixed = TRUE)
  expect_match(html, htmltools::htmlEscape(tree$nodes$q1$text), fixed = TRUE)
})

test_that("question IDs stay in the page source but are hidden from users", {
  html <- as.character(node_ui(tree, "q1", list()))
  expect_match(html, '<div class="question-id" hidden aria-hidden="true" data-question-id="Q1">Question Q1</div>', fixed = TRUE)
  html <- as.character(node_ui(tree, "s1", list()))
  expect_match(html, 'data-question-id="S1"', fixed = TRUE)
})

test_that("answer chips are at least 44 px tall and wide (touch targets)", {
  css <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  chip <- regmatches(css, regexpr("\\.chip \\{[^}]*\\}", css))
  expect_match(chip, "min-height: 44px", fixed = TRUE)
  expect_match(chip, "min-width: 44px", fixed = TRUE)
})

test_that("hints also explain terms in standard names and backend lines, once per card", {
  e18 <- as.character(card_ui(tree, "E18"))
  expect_match(e18, "<dfn>omnibus test</dfn>", fixed = TRUE)
  e36 <- as.character(card_ui(tree, "E36"))
  expect_match(e36, "<dfn>equivalence test (TOST)</dfn>", fixed = TRUE)
  e5 <- as.character(card_ui(tree, "E5"))
  expect_match(e5, "<dfn>continuity correction</dfn>", fixed = TRUE)
  # A term in both the standard name and the backend line is explained once.
  e7 <- as.character(card_ui(tree, "E7"))
  expect_equal(lengths(regmatches(e7, gregexpr("<dfn>ANOVA</dfn>", e7, fixed = TRUE))), 1)
  # "Bayes factor" isn't explained as a factor in a design.
  eb <- as.character(card_ui(tree, "E-bayes"))
  expect_no_match(eb, "<dfn>factor and levels</dfn>", fixed = TRUE)
  expect_match(eb, "<dfn>Bayes factor</dfn>", fixed = TRUE)
})

# Progress and shorter cards (22 October 2026) -------------------------------

test_that("the progress steps follow the four screens, with the current one marked", {
  expect_identical(screen_step("start"), "study")
  expect_identical(screen_step("node"), "design")
  expect_identical(screen_step("card"), "design")
  expect_identical(screen_step("g_plan"), "design")
  expect_identical(screen_step("form"), "numbers")
  expect_identical(screen_step("form", has_result = TRUE), "result")
  html <- as.character(progress_ui("numbers"))
  expect_match(html, 'aria-label="Progress"', fixed = TRUE)
  expect_identical(lengths(regmatches(html, gregexpr('aria-current="step"', html, fixed = TRUE))), 1L)
  expect_match(html, '<li class="current" aria-current="step">', fixed = TRUE)
  expect_identical(lengths(regmatches(html, gregexpr("(done)", html, fixed = TRUE))), 2L)
  # Steps, never a percentage.
  expect_false(grepl("%", html, fixed = TRUE))
  # Drawn apart from the screen, so a result never redraws the form.
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, 'uiOutput("progress"), uiOutput("screen")', fixed = TRUE)
})

test_that("cards fold what you'd enter, the package and the next questions into one section", {
  html <- as.character(card_ui(tree, "E2"))
  expect_match(html, '<details class="card-more">', fixed = TRUE)
  more <- sub('.*<details class="card-more">', "", html)
  for (text in c("What you would enter", "Backend:", "be asked next")) expect_match(more, text, fixed = TRUE)
  # The rank-test note stays in view. The effect size's source is asked on
  # the input screen only, not listed on the card first (28 October 2026).
  before <- sub('<details class="card-more">.*', "", html)
  expect_no_match(before, "Where your effect size comes from", fixed = TRUE)
  expect_match(before, "rank-test-note", fixed = TRUE)
})

test_that("app.R parses (the other tests read it as text)", {
  expect_no_error(parse(file.path(routing_dir, "app.R"), encoding = "UTF-8"))
})

test_that("each tab has its own address, so a page can be shared by link", {
  expect_identical(page_from_query("?page=labs"), labs_tab_title)
  expect_identical(page_from_query("?page=About"), "About")
  expect_identical(page_from_query("?page=whats-new"), "What's new")
  expect_null(page_from_query(""))
  expect_null(page_from_query("?page=nowhere"))
  # The maintainer's tab only opens in the maintainer's view.
  withr::with_envvar(c(POWERKIT_MAINTAINER_VIEW = ""), {
    expect_null(page_from_query("?page=maintainer"))
    expect_identical(page_from_query("?view=maintainer&page=maintainer"), "For the maintainer: undecided settings")
  })
  # Every tab in app.R has an address, and back again.
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  for (tab in setdiff(page_slugs(), labs_tab_title)) expect_match(code, sprintf('tabPanel("%s"', tab), fixed = TRUE)
  for (slug in names(page_slugs())) expect_identical(page_slug(page_slugs()[[slug]]), slug)
  expect_identical(page_slug(NULL), "plan")
  expect_match(code, "selected = page_from_query(req$QUERY_STRING)", fixed = TRUE)
  expect_match(code, "page = page_slug(input$tabs)", fixed = TRUE)
  expect_match(nav_js, "searchParams.set('page'", fixed = TRUE)
})

test_that("the top bar's share button copies a working link to the page", {
  # Inside Connect Cloud's frame the address bar can't show the page, so
  # the button builds the link from the public address.
  expect_match(as.character(share_page_ui()), public_address, fixed = TRUE)
  expect_match(nav_js, "window.pkSharePage", fixed = TRUE)
  expect_match(nav_js, "window.pkLabsTool", fixed = TRUE)
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "share_page_ui())", fixed = TRUE)
  # Each shared page name is one the app opens.
  for (p in c("about", "whats-new", "labs")) expect_false(is.null(page_from_query(paste0("?page=", p))))
  expect_true("prereplication" %in% vapply(labs_tools, `[[`, "", "id"))
  expect_match(labs_js, "get('tool')", fixed = TRUE)
})

test_that("the browser's Back and Forward move between powerkit's screens", {
  # Each screen or tab change is a history entry; the key tells them apart.
  expect_false(identical(nav_key("card", NULL, "E2", 7, "Plan"), nav_key("form", NULL, "E2", 7, "Plan")))
  expect_false(identical(nav_key("node", "q1", NULL, 1, "Plan"), nav_key("node", "q2", NULL, 2, "Plan")))
  expect_false(identical(nav_key("form", NULL, "E2", 7, "Plan"), nav_key("form", NULL, "E2", 7, "About")))
  expect_identical(nav_key("card", NULL, "E2", 7, "Plan"), nav_key("card", NULL, "E2", 7, "Plan"))
  # What an entry restores includes where you are and what you typed, not a calculation.
  expect_true(all(c("screen", "node", "history", "endpoint", "form_values", "ctx") %in% nav_fields))
  expect_false(any(c("calc", "long_spec") %in% nav_fields))
  expect_match(nav_js, "history.pushState", fixed = TRUE)
  expect_match(nav_js, "popstate", fixed = TRUE)
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "observeEvent(input$pk_nav_to,", fixed = TRUE)
  expect_match(code, "tags$script(HTML(nav_js))", fixed = TRUE)
})

test_that("the analysis list names each analysis without internal codes or PROCESS numbers", {
  withr::local_options(powerkit.maintainer_view = FALSE)
  html <- as.character(known_ui(tree))
  expect_no_match(html, "\\(E[0-9]+\\)")
  expect_no_match(html, "PROCESS model", fixed = TRUE)
  expect_match(html, "Simple mediation", fixed = TRUE)
  # Equivalence is named as what powerkit does, not as tests it doesn't.
  expect_no_match(html, "minimum-effect test", fixed = TRUE)
  withr::local_options(powerkit.maintainer_view = TRUE)
  expect_match(as.character(known_ui(tree)), "Simple mediation (E10)", fixed = TRUE)
})

test_that("the methods paragraph names mediation models without PROCESS numbers", {
  for (ep in c("E10", "E11", "E12", "E13", "E14", "E40")) {
    expect_no_match(forms$forms[[ep]]$methods_name, "PROCESS", fixed = TRUE, info = ep)
  }
})
