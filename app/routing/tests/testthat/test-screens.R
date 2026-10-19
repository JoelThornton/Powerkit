# Every screen renders from the data file, shows the prototype banner, and
# the app never calculates power itself: it builds specs and calls the
# engine (validate_spec(), run_spec() and the exports).

test_that("the banner says which designs calculate (judgement call B14)", {
  expect_identical(tree$banner, "Prototype: calculations are available for E1–E9, E18, E23–E26, E48 and E49; E10–E14 give a rough preview of power, then the full analysis here or as an R script (a required N goes straight to the R script); other designs show guidance only for now.")
  expect_match(as.character(prototype_banner(tree)), tree$banner, fixed = TRUE)
})

test_that("only cards that don't calculate say 'No numbers are calculated'", {
  for (id in c(unlist(forms$calculates), paste0("E", 10:14))) {
    expect_no_match(as.character(card_ui(tree, id)), "No numbers are calculated", fixed = TRUE, label = id)
  }
  for (id in c("E19", "E45")) {
    expect_match(as.character(card_ui(tree, id)), "No numbers are calculated", fixed = TRUE, label = id)
  }
})

test_that("every end-point card renders, with its status and inputs", {
  for (id in names(tree$endpoints)) {
    html <- as.character(card_ui(tree, id))
    expect_match(html, htmltools::htmlEscape(tree$endpoints[[id]]$plain_name), fixed = TRUE, label = id)
    if (!is.null(tree$endpoints[[id]]$inputs)) expect_match(html, "What you would enter", fixed = TRUE, label = id)
    expected <- if (isTRUE(tree$endpoints[[id]]$generic)) tree$endpoints[[id]]$card_heading %||% "Not in powerkit yet." else switch(tree$endpoints[[id]]$status,
      runs_validated = "Runs in powerkit.", runs_validation_in_progress = "Runs, validation in progress.",
      coming_soon = "Coming soon.",
      not_in_powerkit = if (isTRUE(tree$endpoints[[id]]$no_ready_made_tool)) "Not in powerkit yet." else "Not in powerkit yet: use")
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

test_that("undecided settings show a labelled placeholder; decided ones show the decision", {
  s <- setting_by_key(tree, "observed_power")
  expect_null(s$value)
  expect_match(as.character(placeholder_ui(s)), "Undecided: for the maintainer", fixed = TRUE)
  s$value <- "warn"
  html <- as.character(placeholder_ui(s))
  expect_match(html, "Maintainer decision", fixed = TRUE)
  expect_match(html, "Warn and allow", fixed = TRUE)
})

test_that("cards show undecided settings as compact labelled placeholders", {
  html <- as.character(card_ui(tree, "E7"))
  expect_match(html, "Undecided, for the maintainer", fixed = TRUE)
  expect_match(html, "Judgement call 3.1", fixed = TRUE)
  html_not <- as.character(card_ui(tree, "E36"))
  expect_match(html_not, "Open question 6", fixed = TRUE)
})

test_that("deciding against the guided route hides it, with no code change", {
  expect_match(as.character(start_ui(tree)), "Plan my whole study", fixed = TRUE)
  t2 <- tree
  for (i in seq_along(t2$settings)) if (t2$settings[[i]]$key == "guided_route") t2$settings[[i]]$value <- "no"
  expect_false(grepl("Plan my whole study", as.character(start_ui(t2)), fixed = TRUE))
})

test_that("the plan screen shows placeholders for the combined N and the consistency check, and no numbers", {
  answers <- list(x = "cond2", outcome = "score", mediators = "one", moderator = "score", covariate = "baseline")
  html <- as.character(guided_plan_ui(tree, answers, c("compare", "moderation", "mediation"), c("compare", "moderation", "mediation"),
    list(compare = "ANCOVA: the outcome adjusting for the baseline"), "any"))
  expect_match(html, "calculated here once the engine is connected", fixed = TRUE)
  expect_match(html, "The effect of x on the outcome appears in", ignore.case = TRUE)
  expect_match(html, "needs an alpha correction", fixed = TRUE)
  expect_match(html, "E23", fixed = TRUE)
  expect_match(html, "E15", fixed = TRUE)
  expect_match(html, "E16", fixed = TRUE)
})

test_that("the app never computes power itself: it only calls the engine's run_spec(), validate_spec() and exports", {
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
  expect_setequal(used, c("validate_spec", "run_spec", "export_script", "export_citations", "export_run_script", "power_interval",
    "write_project", "read_project"))
  # Calculations run only for the end points listed in forms.yaml.
  expect_setequal(unlist(forms$calculates), c(paste0("E", 1:9), "E18", "E23", "E24", "E25", "E26", "E48", "E49"))
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
  expect_no_match(as.character(card_ui(t2, "E28")), "Other defensible analyses exist", fixed = TRUE)
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
    list(node = "s4", answer = "Detect an effect", ctx = list(outcome = "score", times = "once")),
    list(node = "q1", answer = tree$safety_net$label, ctx = list(outcome = "score", times = "once"))
  )
  html <- as.character(card_ui(tree, "E-unsure", history = history))
  for (a in c("A score or scale", "Independent people", "Once", "Detect an effect")) expect_match(html, a, fixed = TRUE)
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
