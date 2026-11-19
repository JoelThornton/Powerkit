# The Labs replication planner (R/replication.R): the app lays out the
# engine's replication_planning(); it never computes a number itself.

skip_if_not_installed("BayesRepDesign")

filled <- list(rep_design = "two_groups", rep_effect = "0.7", rep_n1 = "20", rep_n2 = "20", rep_original_alpha = "0.05",
  rep_smallest = "0.2", rep_tau = "0.05", rep_alpha = "0.05", rep_power = "0.8", rep_threshold = "10", rep_n_at = "200",
  rep_study = "Smith (2020)", rep_goal = "significance", rep_prior = "uncertain")
plan_of <- function(values = filled) do.call(engine_function("replication_planning"), replication_args(values))

test_that("the fields become the engine's arguments, blanks left out", {
  args <- replication_args(filled)
  expect_equal(args[c("original_effect", "original_n1", "original_n2", "tau", "smallest_effect", "n")],
    list(original_effect = 0.7, original_n1 = 20, original_n2 = 20, tau = 0.05, smallest_effect = 0.2, n = 200))
  paired <- replication_args(list(rep_design = "paired", rep_effect = "0.5", rep_n = "30"))
  expect_equal(paired$original_n, 30)
  expect_null(paired$original_n1)
  expect_null(paired$smallest_effect)
  expect_null(paired$n)
  expect_equal(paired$alpha, 0.05)
  expect_length(replication_missing(filled), 0)
  expect_match(replication_missing(list(rep_design = "two_groups", rep_effect = "0.5", rep_n1 = "20")), "two group sizes")
  expect_match(replication_missing(list(rep_design = "correlation", rep_n = "80"))[1], "effect")
})

test_that("the table has every goal under the three beliefs, and the no-effect goals across the row", {
  plan <- plan_of()
  html <- as.character(replication_result_ui(plan))
  for (label in replication_prior_labels) expect_match(html, label, fixed = TRUE)
  for (goal in unique(plan$goals$goal)) expect_match(html, replication_goal_labels[[goal]], fixed = TRUE)
  expect_match(html, ", planned for no effect", fixed = TRUE)
  # An original of 20 per group can't show agreement within 0.2.
  expect_match(html, "Not reachable with this original study", fixed = TRUE)
  # The numbers are the engine's.
  sig <- plan$goals[plan$goals$goal == "significance" & plan$goals$prior %in% "uncertain", "n"]
  expect_match(html, replication_n_words(plan, sig), fixed = TRUE)
  expect_match(html, "rep-chances", fixed = TRUE)
  expect_match(html, "d33 = 0.496", fixed = TRUE)
})

test_that("the methods paragraph states the goal, the belief and its calculation", {
  plan <- plan_of()
  sig <- replication_methods_paragraph(plan, "significance", "uncertain")
  expect_match(sig, "a significant result in the original's direction", fixed = TRUE)
  expect_match(sig, "design prior that carries the original estimate's uncertainty", fixed = TRUE)
  expect_match(sig, "standard deviation of 0.05", fixed = TRUE)
  expect_match(sig, "BayesRepDesign", fixed = TRUE)
  st <- replication_methods_paragraph(plan, "small_telescopes", "uncertain")
  expect_match(st, "102 participants (51 per group)", fixed = TRUE)
  expect_match(st, "Simonsohn, 2015", fixed = TRUE)
  expect_match(replication_methods_paragraph(plan, "negligible", "as_reported"), "equivalence test", fixed = TRUE)
  expect_match(replication_methods_paragraph(plan, "agreement", "as_reported"), "cannot reach", fixed = TRUE)
})

test_that("the write-up can be downloaded at any stage, with what's missing marked", {
  empty <- paste(replication_report(list()), collapse = "\n")
  expect_match(empty, "# Replication plan", fixed = TRUE)
  expect_match(empty, "_(not filled in yet)_", fixed = TRUE)
  expect_match(empty, "Not calculated yet", fixed = TRUE)
  full <- paste(replication_report(filled, plan_of(), version = "0.0.0"), collapse = "\n")
  expect_match(full, "Smith (2020)", fixed = TRUE)
  expect_match(full, "| Criterion | Its role | Sample size it needs | Chance with the planned sample size |", fixed = TRUE)
  expect_match(full, "Main criterion: sets the sample size", fixed = TRUE)
  expect_no_match(full, "Not calculated yet", fixed = TRUE)
  expect_match(full, "Bayesian Approaches to Designing Replication Studies", fixed = TRUE)
  # The pre-replication notes go in when they are filled in, a level down.
  notes <- list(labs_study = "Smith (2020)", labs_finding = "Training raises recall.", labs_goals = "To test the theory.")
  with_notes <- paste(replication_report(filled, plan_of(), notes, "go"), collapse = "\n")
  expect_match(with_notes, "\n## Pre-replication", fixed = TRUE)
  expect_match(with_notes, "To test the theory.", fixed = TRUE)
  expect_no_match(paste(replication_report(filled, NULL, list(labs_study = "")), collapse = "\n"), "Pre-replication", fixed = TRUE)
})

test_that("the planner's file keeps its own fields and nothing else", {
  path <- tempfile(fileext = ".json")
  jsonlite::write_json(replication_file(c(filled, list(other = "x")), "0.0.0"), path, auto_unbox = TRUE)
  back <- plan_from_replication_text(paste(readLines(path), collapse = "\n"))$replication$fields
  expect_true(all(names(back) %in% names(filled)))
  expect_false("other" %in% names(back))
  expect_identical(back$rep_effect, "0.7")
  expect_null(plan_from_replication_text(jsonlite::toJSON(list(app = "something-else", fields = filled), auto_unbox = TRUE)))
  expect_null(plan_from_replication_text("not json"))
})

test_that("replicating from the finder asks the original's design, and its card says how to plan it", {
  aim <- aim_question(tree)
  # No shortcut past the design questions: every design reaches its card.
  expect_null(aim$options$replicate$labs)
  expect_null(aim$options$replicate$`next`)
  expect_true(replicating(list(aim = "replicate")))
  expect_false(replicating(list(aim = "predict")))
  # The planner's four designs are offered it, on the same design.
  for (ep in c("E1", "E2", "E3")) expect_false(is.null(replication_card_design(forms, ep)))
  expect_identical(replication_card_design(forms, "E2"), "two_groups")
  two_groups <- as.character(replication_card_note(forms, "E2"))
  expect_match(two_groups, "the plan's Goals give the sample size for each goal", fixed = TRUE)
  expect_match(two_groups, "choose the test it used: the replication uses the same", fixed = TRUE)
  # Opened from a replication plan, the note names it and links back.
  kept <- as.character(replication_card_note(forms, "E2", new_replication_plan("Smith replication")))
  expect_match(kept, "Smith replication", fixed = TRUE)
  expect_match(kept, "rep_view_plan", fixed = TRUE)
  expect_no_match(two_groups, "rep_view_plan", fixed = TRUE)
  expect_true("two_groups" %in% replication_designs_ui)
  # Any other design plans the replication on its own card.
  other <- setdiff(names(forms$forms), names(Filter(function(f) isTRUE(f$base$template %in% names(replication_card_templates)), forms$forms)))[1]
  expect_null(replication_card_design(forms, other))
  note <- as.character(replication_card_note(forms, other))
  expect_no_match(note, "the plan's Goals give", fixed = TRUE)
  expect_match(note, "a significant result again", fixed = TRUE)
  # The effect's source starts as an earlier study, unless already chosen.
  expect_identical(replication_form_values(list())$just_type, "prior_study")
  expect_identical(replication_form_values(list(just_type = "pilot_study"))$just_type, "pilot_study")
  # With the plan (queue item 28): the sample-size question, the plan's
  # level and chance of success, and the original's effect where the card
  # takes it as the plan holds it.
  pv <- replication_values(list(fields = list(rep_design = "two_groups", rep_effect = "0.45",
    rep_alpha = "0.01", rep_power = "0.9")))
  fv <- replication_form_values(list(), "E2", pv)
  expect_identical(fv[c("goal", "alpha", "power", "effect_units", "d")],
    list(goal = "sample_size", alpha = "0.01", power = "0.9", effect_units = "standardised", d = "0.45"))
  # What the user already chose is kept.
  expect_identical(replication_form_values(list(goal = "power", d = "0.3"), "E2", pv)[c("goal", "d")], list(goal = "power", d = "0.3"))
  # Empty plan settings stay empty: the card asks for them.
  empty <- replication_form_values(list(), "E2", replication_values(list(fields = list())))
  expect_null(empty$alpha); expect_null(empty$power); expect_null(empty$d)
  # A t statistic, d_rm, another design or a card that takes another effect: no effect copied.
  t_given <- replication_values(list(fields = list(rep_design = "paired", rep_effect_type = "t", rep_effect = "3.1")))
  expect_null(replication_form_values(list(), "E3", t_given)$dz)
  dz <- replication_values(list(fields = list(rep_design = "paired", rep_effect = "0.4")))
  expect_identical(replication_form_values(list(), "E3", dz)$dz, "0.4")
  expect_null(replication_card_effect_field("E2", dz))
  expect_null(replication_card_effect_field("E7", pv))
  r <- replication_values(list(fields = list(rep_design = "correlation", rep_effect = "0.3")))
  expect_identical(replication_form_values(list(), "E4", r)$r, "0.3")
  expect_null(replication_form_values(list(), "E4", r)$effect_units)
  # They reach the input screen.
  screen <- as.character(form_ui(tree, forms, "E2", form_groups(forms, "E2"), fv))
  expect_match(screen, 'id="f_d"[^>]*value="0.45"|value="0.45"[^>]*id="f_d"')
  expect_match(screen, 'id="f_alpha"[^>]*value="0.01"|value="0.01"[^>]*id="f_alpha"')
  # Every field the presets name is one of the card's own.
  for (ep in c("E1", "E2", "E3", "E4")) {
    ids <- c(vapply(unlist(lapply(forms$forms[[ep]]$groups, `[[`, "fields"), recursive = FALSE), `[[`, character(1), "id"))
    expect_true(all(c("d", "dz", "r")[c(ep %in% c("E1", "E2"), ep == "E3", ep == "E4")] %in% ids), info = ep)
    expect_true("effect_units" %in% ids || ep == "E4", info = ep)
  }
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "if (replicating(state$start)) replication_card_note(forms, state$endpoint, plan_get(state$rep_plan))", fixed = TRUE)
  expect_match(code, "observeEvent(input$rep_view_plan", fixed = TRUE)
})

test_that("the notes lead on to the original study, and the main route's signpost starts a replication plan", {
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "replication_server(input, output, session", fixed = TRUE)
  expect_match(as.character(labs_next_ui("go", FALSE)), "Next: the original study", fixed = TRUE)
  expect_match(as.character(labs_next_ui("change", FALSE)), "Next: the original study", fixed = TRUE)
  expect_no_match(as.character(labs_next_ui("not_worth", FALSE)), "Next: the original study", fixed = TRUE)
  expect_match(as.character(labs_signpost_ui()), "rep_plan_new_signpost", fixed = TRUE)
  expect_match(code, "observeEvent(input$rep_plan_new_signpost", fixed = TRUE)
  # The notes are kept in the plan, not in the browser tab as in Labs.
  expect_no_match(labs_js, "pkLabsClear", fixed = TRUE)
})

test_that("the server plans from the fields, and says what is missing first", {
  testServer(function(input, output, session) replication_server(input, output, session), {
    session$setInputs(rep_design = "two_groups", rep_effect = "0.7", rep_n1 = "", rep_n2 = "", rep_run = 1)
    expect_match(as.character(output$rep_result$html), "two group sizes", fixed = TRUE)
    # The replication's own significance level and chance start empty
    # (P-04): choosing them is asked for before anything is calculated.
    session$setInputs(rep_n1 = "20", rep_n2 = "20", rep_smallest = "0.2", rep_run = 2)
    expect_match(as.character(output$rep_result$html), "Choose the significance level and the chance of success to aim for under Goals first", fixed = TRUE)
    session$setInputs(rep_alpha = "0.05", rep_power = "0.8", rep_run = 4)
    expect_match(as.character(output$rep_result$html), "rep-table", fixed = TRUE)
    session$setInputs(rep_effect = "0", rep_run = 3)
    expect_match(as.character(output$rep_result$html), "not 0", fixed = TRUE)
  })
})

test_that("the simple answer comes first, from the table's own first row (C-14)", {
  plan <- plan_of()
  html <- as.character(replication_headline_ui(plan))
  g <- plan$goals[plan$goals$goal == "significance", ]
  expect_match(html, replication_n_words(plan, g$n[g$prior %in% "as_reported"]), fixed = TRUE)
  expect_match(html, replication_n_words(plan, g$n[g$prior %in% "shrunk"]), fixed = TRUE)
  expect_match(html, "with 80% power", fixed = TRUE)
  expect_lt(regexpr("result-headline", as.character(replication_result_ui(plan)))[1],
    regexpr("rep-table", as.character(replication_result_ui(plan)))[1])
  # Section 1 has its own button, so no goals or beliefs come before a number.
  ui <- as.character(replication_planner_sections())
  expect_lt(regexpr("rep_run_quick", ui)[1], regexpr(">3. Goals and sample size</h3>", ui, fixed = TRUE)[1])
})

# Another design whose focal effect is one number (queue item 21).
generic_filled <- list(rep_design = "generic", rep_effect_name = "odds ratio", rep_scale = "log", rep_effect = "2.1",
  rep_se_from = "ci", rep_ci_lower = "1.2", rep_ci_upper = "3.7", rep_ci_level = "95", rep_n = "150",
  rep_smallest = "1.2", rep_alpha = "0.05", rep_power = "0.8", rep_threshold = "10", rep_tau = "0",
  rep_goal = "significance", rep_prior = "shrunk")

test_that("another design's fields become the engine's generic arguments", {
  args <- replication_args(generic_filled)
  expect_identical(args$design, "generic")
  expect_identical(args$scale, "log")
  expect_identical(args$effect_name, "odds ratio")
  expect_equal(args$original_ci, c(1.2, 3.7))
  expect_equal(args$original_ci_level, 0.95)
  expect_null(args$original_se)
  expect_equal(replication_args(modifyList(generic_filled, list(rep_se_from = "se", rep_se = "0.3")))$original_se, 0.3)
  expect_equal(replication_args(modifyList(generic_filled, list(rep_se_from = "statistic", rep_statistic = "2.6")))$original_statistic, 2.6)
  expect_length(replication_missing(generic_filled), 0)
  expect_match(replication_missing(modifyList(generic_filled, list(rep_ci_upper = ""))), "confidence interval")
  expect_match(replication_missing(modifyList(generic_filled, list(rep_se_from = "se"))), "standard error")
  expect_match(replication_missing(modifyList(generic_filled, list(rep_n = ""))), "number of people")
})

test_that("another design's table, methods and write-up come from the engine's generic plan", {
  plan <- plan_of(generic_filled)
  html <- as.character(replication_result_ui(plan))
  expect_match(html, "rep-table", fixed = TRUE)
  expect_match(html, "on the log scale", fixed = TRUE)
  expect_match(html, "square root of the ratio of sample sizes", fixed = TRUE)
  expect_no_match(html, "small_telescopes|yardstick")
  expect_no_match(html, replication_goal_labels[["small_telescopes"]], fixed = TRUE)
  methods <- replication_methods_paragraph(plan, "significance", "shrunk")
  g <- plan$goals[plan$goals$goal == "significance" & plan$goals$prior %in% "shrunk", ]
  expect_match(methods, replication_n_words(plan, g$n), fixed = TRUE)
  expect_match(methods, "odds ratio = 2.1", fixed = TRUE)
  expect_match(methods, "copies the original's design", fixed = TRUE)
  report <- paste(replication_report(generic_filled, plan), collapse = "\n")
  expect_match(report, "The effect: odds ratio (A ratio", fixed = TRUE)
  expect_match(report, "a 95% confidence interval from 1.2 to 3.7", fixed = TRUE)
  expect_true("generic" %in% replication_designs_ui)
  ui <- as.character(replication_planner_sections())
  for (id in c("rep_effect_name", "rep_scale", "rep_se_from", "rep_se", "rep_ci_lower", "rep_ci_upper", "rep_ci_level", "rep_statistic")) {
    expect_match(ui, sprintf("id=\"%s\"", id), fixed = TRUE)
    expect_true(id %in% replication_field_ids)
  }
})

test_that("every card says how a replication plan takes its effect", {
  for (ep in names(forms$forms)) {
    e <- replication_card_effect(forms, ep)
    expect_false(is.null(e), label = ep)
    kinds <- intersect(names(e), c("exact", "effect", "multi_df", "none"))
    expect_length(kinds, 1)
    if (!is.null(e$exact)) {
      expect_true(e$exact %in% replication_designs_ui[replication_designs_ui != "generic"], label = ep)
      expect_identical(replication_card_design(forms, ep), e$exact, label = ep)
    }
    if (!is.null(e$effect)) expect_true(e$scale %in% replication_scales_ui, label = ep)
  }
  # Each of the four exact designs' cards says so; the others name their effect or say why not.
  expect_setequal(names(Filter(function(e) !is.null(e$exact), forms$replication_effects)), c("E1", "E2", "E3", "E4"))
  expect_match(replication_card_effect_note(forms, "E27"), "odds ratio of the predictor", fixed = TRUE)
  expect_match(replication_card_effect_note(forms, "E18"), "several degrees of freedom", fixed = TRUE)
  expect_match(replication_card_effect_note(forms, "E18"), "card E19", fixed = TRUE)
  expect_match(replication_card_effect_note(forms, "E61"), "meta-analysis", fixed = TRUE)
  expect_null(replication_card_effect_note(forms, "E2"))
  expect_match(as.character(replication_card_note(forms, "E27")), "Another design", fixed = TRUE)
})

test_that("the server plans another design from its fields", {
  testServer(function(input, output, session) replication_server(input, output, session), {
    do.call(session$setInputs, c(modifyList(generic_filled, list(rep_ci_upper = "")), list(rep_run = 1)))
    expect_match(as.character(output$rep_result$html), "confidence interval", fixed = TRUE)
    session$setInputs(rep_ci_upper = "3.7", rep_run = 2)
    expect_match(as.character(output$rep_result$html), "rep-table", fixed = TRUE)
    session$setInputs(rep_ci_lower = "2.5", rep_run = 3)
    expect_match(as.character(output$rep_result$html), "inside its confidence interval", fixed = TRUE)
  })
})

# An original analysed with Bayes factors (queue item 21).
bf_filled <- list(rep_design = "two_groups", rep_analysis = "bayes_factor", rep_bf = "3.38", rep_prior_scale = "0.707",
  rep_n1 = "30", rep_n2 = "30", rep_effect = "", rep_original_alpha = "0.05", rep_tau = "0", rep_alpha = "0.05",
  rep_power = "0.8", rep_threshold = "10", rep_n_at = "120", rep_goal = "bf_repeat", rep_prior = "uncertain")
post_filled <- list(rep_design = "one_sample", rep_analysis = "posterior", rep_original_prior = "default",
  rep_effect = "0.4", rep_post_from = "ci", rep_cri_lower = "0.12", rep_cri_upper = "0.67", rep_cri_level = "95",
  rep_prior_scale = "0.707", rep_n = "50", rep_tau = "0", rep_alpha = "0.05", rep_power = "0.8", rep_threshold = "10")

test_that("an original's Bayes factor or posterior becomes the engine's arguments", {
  skip_if_not_installed("BayesFactor")
  args <- replication_args(bf_filled)
  expect_identical(args$original_analysis, "bayes_factor")
  expect_equal(args$original_bf, 3.38)
  expect_equal(args$original_prior_scale, 0.707)
  expect_null(args$original_effect)
  post <- replication_args(post_filled)
  expect_identical(post$original_prior, "default")
  expect_equal(post$original_ci, c(0.12, 0.67))
  expect_equal(post$original_ci_level, 0.95)
  expect_null(post$original_se)
  expect_equal(replication_args(modifyList(post_filled, list(rep_post_from = "sd", rep_post_sd = "0.14")))$original_se, 0.14)
  # A generic posterior takes the posterior's SD, not the standard error fields.
  generic_post <- replication_args(modifyList(generic_filled, list(rep_analysis = "posterior", rep_original_prior = "vague",
    rep_post_from = "sd", rep_post_sd = "0.25")))
  expect_equal(generic_post$original_se, 0.25)
  expect_null(generic_post$original_ci)
  expect_null(replication_args(filled)$original_analysis)
  expect_length(replication_missing(bf_filled), 0)
  expect_length(replication_missing(post_filled), 0)
  expect_match(replication_missing(modifyList(bf_filled, list(rep_bf = ""))), "Bayes factor")
  expect_match(replication_missing(modifyList(post_filled, list(rep_cri_upper = ""))), "credible interval")
  expect_match(replication_missing(modifyList(post_filled, list(rep_effect = "")))[1], "posterior's mean")
})

test_that("a Bayes factor original's table, headline, methods and write-up", {
  skip_if_not_installed("BayesFactor")
  skip_if_not_installed("bfpwr")
  plan <- plan_of(bf_filled)
  html <- as.character(replication_result_ui(plan))
  expect_match(html, "comes from a t statistic of 2.5", fixed = TRUE)
  expect_match(html, replication_goal_labels[["bf_repeat"]], fixed = TRUE)
  expect_match(html, replication_goal_labels[["bf_null"]], fixed = TRUE)
  expect_match(html, "Small telescopes needs the original's significance test", fixed = TRUE)
  expect_no_match(html, "two-sided p =", fixed = TRUE)
  expect_match(html, "rep_to_sequential", fixed = TRUE)
  g <- plan$goals[plan$goals$goal == "bf_repeat", ]
  expect_match(as.character(replication_headline_ui(plan)), replication_n_words(plan, g$n[g$prior %in% "shrunk"]), fixed = TRUE)
  # Its usual main criterion is the original's own test, repeated.
  expect_identical(replication_resolve_goals(c(bf_filled[setdiff(names(bf_filled), "rep_goal")], rep_goal = "auto"),
    unique(plan$goals$goal))$goal, "bf_repeat")
  methods <- replication_methods_paragraph(plan, "bf_repeat", "uncertain")
  expect_match(methods, "bfpwr (Pawel & Held, 2025)", fixed = TRUE)
  expect_match(methods, "Ly et al., 2018", fixed = TRUE)
  expect_match(methods, replication_n_words(plan, g$n[g$prior %in% "uncertain"]), fixed = TRUE)
  expect_match(replication_methods_paragraph(plan, "bf_null", "uncertain"), "planned for a true effect of zero", fixed = TRUE)
  expect_match(replication_methods_paragraph(plan, "significance", "uncertain"), "read from its Bayes factor", fixed = TRUE)
  report <- paste(replication_report(bf_filled, plan), collapse = "\n")
  expect_match(report, "How it was analysed: a Bayes factor", fixed = TRUE)
  expect_match(report, "Its Bayes factor (BF10): 3.38", fixed = TRUE)
  expect_no_match(report, "Significance level:", fixed = TRUE)
  expect_match(report, "Verhagen", fixed = TRUE)
  # The sequential design starts from the chosen belief, in each group.
  s <- replication_sequential_settings(plan, "shrunk")
  dp <- plan$priors[plan$priors$prior == "shrunk", ]
  expect_equal(c(s$effect, s$effect_sd), round(c(dp$mean, dp$sd), 3))
  expect_identical(s$type, "two.sample")
  expect_equal(s$n_max, g$n[g$prior %in% "shrunk"] / 2)
  expect_identical(s$threshold, "10")
})

test_that("a posterior original is planned, refused for an informative prior", {
  plan <- plan_of(post_filled)
  html <- as.character(replication_result_ui(plan))
  expect_match(html, "from a default prior", fixed = TRUE)
  expect_match(replication_methods_paragraph(plan, "significance", "uncertain"), "posterior mean", fixed = TRUE)
  report <- paste(replication_report(post_filled, plan), collapse = "\n")
  expect_match(report, "Its 95% credible interval: 0.12 to 0.67", fixed = TRUE)
  testServer(function(input, output, session) replication_server(input, output, session), {
    do.call(session$setInputs, c(modifyList(post_filled, list(rep_original_prior = "informative")), list(rep_run = 1)))
    expect_match(as.character(output$rep_result$html), "vague or a default one", fixed = TRUE)
    session$setInputs(rep_original_prior = "vague", rep_run = 2)
    expect_match(as.character(output$rep_result$html), "rep-table", fixed = TRUE)
    session$setInputs(rep_design = "correlation", rep_analysis = "bayes_factor", rep_bf = "5", rep_n = "80", rep_run = 3)
    expect_match(as.character(output$rep_result$html), "only for a t-test", fixed = TRUE)
  })
  ui <- as.character(replication_planner_sections())
  for (id in c("rep_analysis", "rep_bf", "rep_original_prior", "rep_prior_scale", "rep_post_from", "rep_post_sd",
               "rep_cri_lower", "rep_cri_upper", "rep_cri_level")) {
    expect_match(ui, sprintf("id=\"%s\"", id), fixed = TRUE)
    expect_true(id %in% replication_field_ids)
  }
})

test_that("the planner's wording matches the cards' (P-04, P-07, P-08, P-09)", {
  html <- as.character(replication_workspace_ui(tree))
  # The evidence threshold as the cards word it, 10 labelled.
  expect_match(html, "Evidence threshold for the Bayes factors", fixed = TRUE)
  expect_match(html, "10 (a common threshold)", fixed = TRUE)
  expect_no_match(html, "Strong evidence", fixed = TRUE)
  expect_false(any(grepl("Strong evidence", replication_goal_labels, fixed = TRUE)))
  # Variation starts at Small, with the cards' help.
  expect_match(html, '<option value="0.05" selected>Small (0.05)</option>', fixed = TRUE)
  expect_match(html, "How to interpret the between-study SD", fixed = TRUE)
  expect_match(html, "a quarter of Cohen's 0.2, 0.5 and 0.8", fixed = TRUE)
  expect_match(html, "illustrations, not estimates for your field", fixed = TRUE)
  # Alpha and power empty, with one-click buttons.
  alpha <- regmatches(html, regexpr('<input[^>]*id="rep_alpha"[^>]*>', html))
  expect_match(alpha, 'value=""', fixed = TRUE)
  expect_match(alpha, "rep-num", fixed = TRUE)
  expect_match(html, 'id="rep_alpha_usual"', fixed = TRUE)
  expect_match(html, "Use 0.05, the usual level", fixed = TRUE)
  expect_match(html, 'id="rep_power_usual_3"[^>]*>95%', perl = TRUE)
  # One sentence over the two routes; the references once, folded, linked.
  expect_match(html, "Two ways to the sample size", fixed = TRUE)
  expect_identical(lengths(regmatches(html, gregexpr("rep-references", html, fixed = TRUE))), 1L)
  expect_no_match(html, "References: ", fixed = TRUE)
  expect_match(html, "<summary>References \\([0-9]+\\)</summary>")
  expect_match(html, '<a href="https://doi.org/', fixed = TRUE)
  expect_no_match(html, "&lt;https://", fixed = TRUE)
  expect_identical(replication_a_pct(0.8), "an 80%")
  expect_identical(replication_a_pct(0.9), "a 90%")
})

test_that("the result names the belief the write-up starts on, without stray spaces", {
  plan <- engine_function("replication_planning")("two_groups", 0.7, original_n1 = 20, original_n2 = 20, tau = 0.05)
  html <- as.character(replication_result_ui(plan))
  expect_match(html, "allowing for the uncertainty in the original's estimate (the belief the plan you write up starts on, below)", fixed = TRUE)
  expect_match(html, "for an 80% chance of each goal", fixed = TRUE)
  expect_no_match(html, "[[:alnum:])] [.](\\s|<|$)", perl = TRUE)
  expect_match(html, "vary between studies with an SD of 0.05", fixed = TRUE)
})

# The 17 November 2026 review of replication plans.
test_that("variation between studies is on each design's own scale", {
  base <- list(rep_effect = "0.5", rep_n = "50", rep_alpha = "0.05", rep_power = "0.8")
  # Designs planned in d start at Kenny and Judd's 0.05.
  expect_equal(replication_args(c(base, rep_design = "paired"))$tau, 0.05)
  # A correlation starts at the correlation card's 0.025 on Fisher's z, and
  # ignores a value chosen for d.
  expect_equal(replication_args(c(base, rep_design = "correlation", rep_tau = "0.2"))$tau, 0.025)
  expect_equal(replication_args(c(base, rep_design = "correlation", rep_tau_r = "0.125"))$tau, 0.125)
  # Another design takes a number on its own scale, none when empty: values
  # in d have no meaning there.
  generic <- c(base, rep_design = "generic", rep_se = "0.2", rep_tau = "0.05")
  expect_equal(replication_args(generic)$tau, 0)
  expect_equal(replication_args(c(generic, rep_tau_value = "0.03"))$tau, 0.03)
  html <- as.character(replication_workspace_ui(tree))
  expect_match(html, '<option value="0.025" selected>Small (0.025)</option>', fixed = TRUE)
  expect_match(html, "an SD on the effect's own scale", fixed = TRUE)
  expect_match(as.character(replication_tau_note(0, "generic", "log")), "no meaning on this effect's scale", fixed = TRUE)
  expect_match(as.character(replication_tau_note(0.03, "generic", "log")), "0.03 on the log scale", fixed = TRUE)
  expect_match(as.character(replication_tau_note(0.025, "correlation")), "the correlation card's smallest value", fixed = TRUE)
})

test_that("a goal any replication meets says so, and doesn't set the sample size", {
  plan <- engine_function("replication_planning")("generic", 0.74, original_n = 120, original_f = 15.38,
    power = 0.9, effect_name = "interaction contrast")
  row <- plan$goals[plan$goals$goal == "pooled", ][1, ]
  expect_identical(row$reason, "any_size")
  expect_match(replication_cell(plan, row), "^Any size: even the smallest replication has a chance above 99%")
  expect_match(replication_methods_paragraph(plan, "pooled", "uncertain"), "does not set the replication's sample size", fixed = TRUE)
  html <- as.character(replication_result_ui(plan))
  expect_no_match(html, "Not reachable: at most 100%", fixed = TRUE)
})

test_that("the paper's t, its repeated-measures d or an F become the engine's arguments", {
  paired <- list(rep_design = "paired", rep_effect = "1.99", rep_n = "60", rep_alpha = "0.05", rep_power = "0.8")
  expect_null(replication_args(paired)$original_effect_type)
  expect_identical(replication_args(c(paired, rep_effect_type = "t"))$original_effect_type, "t")
  rm <- replication_args(c(paired, rep_effect_type = "d_rm", rep_effect_r = "0.6"))
  expect_identical(rm$original_effect_type, "d_rm")
  expect_equal(rm$original_r, 0.6)
  expect_match(replication_missing(c(paired, rep_effect_type = "d_rm")), "correlation between the original's two measurements", all = FALSE)
  # A repeated-measures d is only for pairs; a correlation never converts.
  expect_null(replication_args(list(rep_design = "two_groups", rep_effect = "0.5", rep_n1 = "20", rep_n2 = "20",
    rep_effect_type = "d_rm"))$original_effect_type)
  expect_null(replication_args(list(rep_design = "correlation", rep_effect = "0.3", rep_n = "50", rep_effect_type = "t"))$original_effect_type)
  f <- replication_args(list(rep_design = "generic", rep_effect = "0.74", rep_n = "120", rep_se_from = "f", rep_f = "15.38"))
  expect_equal(f$original_f, 15.38)
  expect_match(replication_missing(list(rep_design = "generic", rep_effect = "0.74", rep_n = "120", rep_se_from = "f")), "its F statistic", all = FALSE)
  # The methods paragraph and the write-up say what the paper reported.
  plan <- do.call(engine_function("replication_planning"), replication_args(c(paired, rep_effect_type = "t")))
  expect_match(replication_methods_paragraph(plan, "significance", "uncertain"), "from its t statistic of 1.99 (Lakens, 2013)", fixed = TRUE)
  report <- paste(replication_report(c(paired, rep_effect_type = "t"), plan), collapse = "\n")
  expect_match(report, "Reported effect: a t statistic of 1.99", fixed = TRUE)
  expect_match(report, "Lakens D (2013)", fixed = TRUE)
  expect_match(report, "for t-tests and ANOVAs", fixed = TRUE)
})

test_that("the write-up cites only what its goals, settings and original used", {
  planner <- engine_function("replication_planning")
  # Not calculated: no references at all.
  expect_no_match(paste(replication_report(list()), collapse = "\n"), "## References", fixed = TRUE)
  # An original t-test with no variation: no Kenny and Judd, no Bayes factor
  # reading, no bfpwr, no Lakens.
  # Only the criteria chosen count: a significance plan with an equivalence
  # bound given cites neither small telescopes nor the Bayes factors the
  # plan also computed.
  plain_values <- list(rep_design = "two_groups", rep_effect = "0.7", rep_n1 = "20", rep_n2 = "20", rep_tau = "0",
    rep_alpha = "0.05", rep_power = "0.8", rep_smallest = "0.3", rep_also = "absence")
  plain <- replication_run(plain_values, planner)
  keys <- replication_ref_keys_used(plain)
  expect_true(all(c("Pawel2026_replication", "Anderson2016_replication") %in% keys))
  expect_false(any(c("Simonsohn2015_telescopes", "Kenny2019_heterogeneity", "Ly2018_summary_reanalysis", "bfpwr_method",
    "McLatchie2020_bayes_factors", "VerhagenWagenmakers2014_replication", "Lakens2013_effectsizes") %in% keys))
  # Left blank, the equivalence bound is d33, which brings Simonsohn.
  d33 <- replication_run(plain_values[setdiff(names(plain_values), "rep_smallest")], planner)
  expect_identical(d33$choice$bound, "d33")
  expect_true("Simonsohn2015_telescopes" %in% replication_ref_keys_used(d33))
  # Ticking a Bayes factor brings its references.
  bf_too <- replication_run(c(plain_values[setdiff(names(plain_values), "rep_also")], rep_also = "absence\nbf_replication"), planner)
  expect_true(all(c("VerhagenWagenmakers2014_replication", "Ly2019_replication_bf") %in% replication_ref_keys_used(bf_too)))
  # Another design has no small telescopes, so no Simonsohn.
  generic <- planner("generic", 0.74, original_n = 120, original_f = 15.38)
  expect_false("Simonsohn2015_telescopes" %in% replication_ref_keys_used(generic))
  # Variation and a Bayes factor original bring their own.
  bf <- planner("paired", original_n = 25, original_analysis = "bayes_factor", original_bf = 8, tau = 0.05)
  expect_true(all(c("Kenny2019_heterogeneity", "Ly2018_summary_reanalysis", "bfpwr_method", "McLatchie2020_bayes_factors") %in%
    replication_ref_keys_used(bf)))
  report <- paste(replication_report(plain_values, plain), collapse = "\n")
  expect_no_match(report, "Kenny", fixed = TRUE)
  expect_no_match(report, "Simonsohn", fixed = TRUE)
})

test_that("a card that can't plan isn't kept as the original's design", {
  note <- as.character(replication_card_note(forms, "E-unsure"))
  expect_match(note, "isn't kept as the original's design", fixed = TRUE)
  expect_no_match(note, "This card plans the replication", fixed = TRUE)
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "req(!is.null(tree$endpoints[[ep %||% \"\"]]), !is.null(forms$forms[[ep]]))", fixed = TRUE)
  # Already in a replication plan, the input screen hides the signpost offering one.
  expect_match(code, "if (replicating(state$start)) tags$style(\".labs-signpost { display: none; }\")", fixed = TRUE)
})

test_that("a replication plan says its validation is in progress, on screen and in the write-up", {
  skip_if(is.null(engine_function("replication_planning", file.path(repo_dir, "engine"))), "no engine")
  plan <- engine_function("replication_planning", file.path(repo_dir, "engine"))("two_groups", 0.5,
    original_n1 = 40, original_n2 = 40)
  html <- as.character(replication_result_ui(plan))
  expect_match(html, "badge-progress", fixed = TRUE)
  expect_match(html, "Validation in progress", fixed = TRUE)
  report <- paste(replication_report(list(rep_design = "two_groups"), plan), collapse = "\n")
  expect_match(report, "Validation in progress: Each goal's chance agrees", fixed = TRUE)
  # No plan, no claim about it.
  expect_no_match(paste(replication_report(list()), collapse = "\n"), "Validation in progress", fixed = TRUE)
})

test_that("the purpose picks the main criterion, and the others are reported at its sample size", {
  planner <- engine_function("replication_planning")
  base <- list(rep_design = "two_groups", rep_effect = "0.5", rep_n1 = "40", rep_n2 = "40", rep_tau = "0.05",
    rep_alpha = "0.05", rep_power = "0.8", rep_smallest = "0.3")
  goals <- c("significance", "pooled", "bf_replication", "bf_sceptical", "bf_repeat", "bf_null", "small_telescopes", "negligible", "agreement")
  # Each purpose's usual criterion, and the absence criterion it ticks.
  confirm <- replication_resolve_goals(c(base, rep_purpose = "confirm", rep_also = "absence"), goals)
  expect_identical(confirm[c("goal", "also")], list(goal = "significance", also = "negligible"))
  either <- replication_resolve_goals(c(base, rep_purpose = "either", rep_also = "absence"), goals)
  expect_identical(either[c("goal", "also")], list(goal = "bf_repeat", also = "bf_null"))
  absent <- replication_resolve_goals(c(base, rep_purpose = "absent", rep_also = "absence\nsmall_telescopes"), goals)
  expect_identical(absent[c("goal", "also")], list(goal = "negligible", also = "small_telescopes"))
  # A chosen criterion beats the purpose; "none" reports nothing else.
  chosen <- replication_resolve_goals(c(base, rep_purpose = "either", rep_goal = "pooled", rep_also = "none"), goals)
  expect_identical(chosen[c("goal", "also")], list(goal = "pooled", also = character(0)))
  # Another design has no default Bayes factor test: settling it either way uses the replication Bayes factor.
  no_t <- setdiff(goals, c("bf_repeat", "bf_null"))
  expect_identical(replication_resolve_goals(list(rep_purpose = "either"), no_t)$goal, "bf_replication")
  # There, a Bayes factor main criterion shows absence by the equivalence
  # test, whose chance is planned for no effect (the replication Bayes
  # factor's is not); without a bound for it, the plan says so.
  sceptical <- replication_resolve_goals(list(rep_goal = "bf_sceptical", rep_also = "absence"), no_t)
  expect_identical(sceptical[c("also", "absence_missing")], list(also = "negligible", absence_missing = FALSE))
  unbounded <- replication_resolve_goals(list(rep_purpose = "either", rep_also = "absence"), setdiff(no_t, "negligible"))
  expect_true(unbounded$absence_missing)
  # A Bayesian original: to show absence, the Bayes factor t-test for no
  # effect where the design has one, else the equivalence test.
  bayes <- list(rep_analysis = "posterior", rep_purpose = "absent")
  expect_identical(replication_resolve_goals(bayes, goals)$goal, "bf_null")
  expect_identical(replication_resolve_goals(bayes, no_t)$goal, "negligible")
  expect_identical(replication_resolve_goals(c(bayes, rep_design = "anova"), goals)$goal, "negligible")
  # Its equivalence test needs the researcher's bound, asked for before the run.
  needs <- list(rep_design = "correlation", rep_analysis = "posterior", rep_purpose = "absent", rep_power = "0.8", rep_alpha = "0.05")
  expect_identical(replication_settings_missing(needs), "the smallest effect that would matter")
  expect_length(replication_settings_missing(c(needs, rep_smallest = "0.1")), 0)
  expect_length(replication_settings_missing(modifyList(needs, list(rep_analysis = "test"))), 0)
  # The run: the sample size from the main criterion under the chosen belief,
  # and the chances at that sample size from the engine.
  plan <- replication_run(c(base, rep_purpose = "confirm", rep_prior = "shrunk", rep_also = "absence\nbf_replication"), planner)
  n <- plan$goals$n[plan$goals$goal == "significance" & plan$goals$prior %in% "shrunk"]
  expect_identical(plan$at_main$n, n)
  # Departure 30's size: the absence criterion adds a line, not people.
  alone <- replication_run(c(base, rep_purpose = "confirm", rep_prior = "shrunk", rep_also = "none"), planner)
  expect_identical(alone$at_main$n, n)
  expect_true("negligible" %in% plan$choice$also)
  expect_length(alone$choice$also, 0)
  again <- planner("two_groups", 0.5, original_n1 = 40, original_n2 = 40, tau = 0.05, smallest_effect = 0.3, n = n)$at_n
  expect_equal(plan$at_main$chances$chance[plan$at_main$chances$goal == "bf_replication" & plan$at_main$chances$prior %in% "shrunk"],
    again$chance[again$goal == "bf_replication" & again$prior %in% "shrunk"])
  html <- as.character(replication_result_ui(plan))
  expect_match(html, sprintf("the replication needs %s.", replication_n_words(plan, n)), fixed = TRUE)
  expect_match(html, "rep-main-chances", fixed = TRUE)
  expect_match(html, "(your belief)", fixed = TRUE)
  expect_lt(regexpr("rep-main-chances", html)[1], regexpr("rep-every-goal", html)[1])
  # The methods paragraph gives the others' chances under the same belief.
  report <- paste(replication_report(c(base, rep_prior = "shrunk"), plan), collapse = "\n")
  expect_match(report, "the chance of each criterion also reported is:", fixed = TRUE)
  expect_match(report, "if there is no effect", fixed = TRUE)
  # A criterion the original can't have says so in plain words.
  generic <- list(rep_design = "generic", rep_effect = "0.74", rep_n = "120", rep_se_from = "f", rep_f = "15.38",
    rep_alpha = "0.05", rep_power = "0.8")
  expect_error(replication_run(c(generic, rep_goal = "small_telescopes"), planner), "planned on the design's card")
  expect_error(replication_run(c(generic, rep_purpose = "absent"), planner), "needs the smallest effect that would matter")
  # Without a bound, another design's absence criterion is left out, with a note.
  quiet <- replication_run(c(generic, rep_also = "absence"), planner)
  expect_true(quiet$choice$absence_missing)
  expect_match(as.character(replication_result_ui(quiet)), "enter it under Goals to add it", fixed = TRUE)
})

test_that("Also report is kept in the plan as text, with no tick kept as none", {
  expect_identical(replication_also_value(c("absence", "pooled")), "absence\npooled")
  expect_identical(replication_also_value(NULL), "none")
  expect_identical(replication_also_selected("absence\npooled"), c("absence", "pooled"))
  expect_identical(replication_also_selected("none"), character(0))
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "updateCheckboxGroupInput(session, id, selected = replication_also_selected(v))", fixed = TRUE)
  expect_match(code, "if (identical(id, \"rep_also\")) return(replication_also_value(v))", fixed = TRUE)
})

test_that("the quick answer uses the usual settings when none are chosen", {
  code <- paste(readLines(file.path(routing_dir, "R", "replication.R")), collapse = "\n")
  expect_match(code, "usual <- list(rep_alpha = \"0.05\", rep_power = \"0.8\")", fixed = TRUE)
  expect_match(code, "run(usual)", fixed = TRUE)
})

test_that("a one-sided replication is planned, written up and restored as one", {
  planner <- engine_function("replication_planning")
  base <- list(rep_design = "two_groups", rep_effect = "0.5", rep_n1 = "40", rep_n2 = "40", rep_tau = "0.05",
    rep_alpha = "0.05", rep_power = "0.8", rep_purpose = "confirm", rep_also = "none")
  expect_null(replication_args(base)$alternative)
  one <- c(base, rep_sided = "one.sided")
  expect_identical(replication_args(one)$alternative, "one.sided")
  two_plan <- replication_run(base, planner)
  one_plan <- replication_run(one, planner)
  expect_lt(one_plan$at_main$n, two_plan$at_main$n)
  report <- paste(replication_report(one, one_plan), collapse = "\n")
  expect_match(report, "(a one-sided test at 0.05)", fixed = TRUE)
  expect_match(report, "replication significance level 0.05 (one-sided, in the original's direction)", fixed = TRUE)
  expect_match(paste(replication_report(base, two_plan), collapse = "\n"),
    "(a two-sided test at 0.05, counted as a success only in the original's direction)", fixed = TRUE)
  expect_identical(replication_field_defaults$rep_sided, "two.sided")
  expect_true("rep_sided" %in% replication_field_ids)
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "\"rep_purpose\", \"rep_prior\", \"rep_sided\", \"rep_anova_kind\", \"rep_f_from\", \"rep_assurance\")) updateRadioButtons", fixed = TRUE)
})

test_that("the write-up has a study design table, and the script runs the chosen criteria only", {
  planner <- engine_function("replication_planning")
  values <- list(rep_design = "two_groups", rep_effect = "0.5", rep_n1 = "40", rep_n2 = "40", rep_tau = "0.05",
    rep_alpha = "0.05", rep_power = "0.8", rep_purpose = "confirm", rep_also = "absence\nbf_replication")
  plan <- replication_run(values, planner)
  report <- replication_report(values, plan)
  start <- which(report == "### Study design table")
  expect_length(start, 1)
  expect_match(report[start + 4], "^| Question | Hypothesis | Sampling plan | Analysis plan |")
  rows <- report[(start + 6):(start + 8)]
  expect_true(all(startsWith(rows, "| Does the original effect replicate? |")))
  expect_match(rows[1], "set by this criterion for an 80% chance of success", fixed = TRUE)
  expect_match(rows[2], "The data support the original's effect over no effect.", fixed = TRUE)
  expect_match(rows[3], "Two one-sided tests at 0.05 against the bounds", fixed = TRUE)
  expect_match(rows[3], "d33, the effect the original had a one-in-three chance of detecting", fixed = TRUE)
  expect_identical(report[start + 9], "")
  # Labels keep their capitals inside a sentence.
  expect_match(paste(report, collapse = "\n"), "(replication Bayes factor of at least 10), ", fixed = TRUE)
  expect_no_match(paste(report, collapse = "\n"), "at your threshold", fixed = TRUE)
  # The script: the main criterion's sample size, then the others' chances at it.
  script <- replication_script_text(plan, engine_function("replication_planning_script"))
  expect_no_match(script, "sapply(priors", fixed = TRUE)
  expect_match(script, "dp <- priors$uncertain", fixed = TRUE)
  env <- new.env()
  chances <- suppressWarnings(eval(parse(text = script), envir = env))
  expect_identical(env$n, plan$at_main$n)
  expect_setequal(names(chances), c("negligible", "bf_replication"))
  # Before a choice is made, every goal under every belief.
  plan$choice <- NULL
  expect_match(replication_script_text(plan, engine_function("replication_planning_script")), "sapply(priors", fixed = TRUE)
})

test_that("the replication Bayes factors' direction is shown and written up when they are used", {
  planner <- engine_function("replication_planning")
  base <- list(rep_design = "two_groups", rep_effect = "0.5", rep_n1 = "40", rep_n2 = "40", rep_tau = "0.05",
    rep_alpha = "0.05", rep_power = "0.8", rep_purpose = "confirm")
  plan <- replication_run(c(base, rep_also = "bf_replication"), planner)
  expect_match(as.character(replication_result_ui(plan)), "rep-direction-note", fixed = TRUE)
  expect_match(paste(replication_report(c(base, rep_also = "bf_replication"), plan), collapse = "\n"),
    "only with the replication's estimate in the original's direction (BayesRepDesign's paradox = FALSE)", fixed = TRUE)
  plain <- replication_run(c(base, rep_also = "none"), planner)
  expect_no_match(as.character(replication_result_ui(plain)), "rep-direction-note", fixed = TRUE)
  expect_no_match(paste(replication_report(c(base, rep_also = "none"), plain), collapse = "\n"), "paradox", fixed = TRUE)
})

test_that("replication criteria control their own settings", {
  legacy <- list(rep_design = "two_groups", rep_power = "0.8")
  expect_true(replication_criteria_settings(legacy)$alpha)
  expect_identical(replication_settings_missing(legacy), "the significance level")

  original <- list(rep_design = "two_groups", rep_analysis = "bayes_factor", rep_goal = "auto",
    rep_also = "absence", rep_power = "0.8")
  expect_true(replication_criteria_settings(original)$bf)
  expect_false(replication_criteria_settings(original)$alpha)
  expect_length(replication_settings_missing(original), 0)

  frequentist <- modifyList(original, list(rep_goal = "significance"))
  expect_false(replication_criteria_settings(frequentist)$bf)
  expect_true(replication_criteria_settings(frequentist)$alpha)
  expect_identical(replication_settings_missing(frequentist), "the significance level")

  bayesian <- modifyList(original, list(rep_analysis = "test", rep_goal = "bf_repeat"))
  expect_true(replication_criteria_settings(bayesian)$bf)
  expect_false(replication_criteria_settings(bayesian)$sided)
  mixed <- modifyList(bayesian, list(rep_also = "significance"))
  expect_true(replication_criteria_settings(mixed)$alpha)
  expect_true(replication_criteria_settings(mixed)$bf)
})

test_that("'there or not' says when a null result could not show anything at the planned size", {
  skip_if_not_installed("bfpwr")
  run <- function(v) replication_run(v, engine_function("replication_planning"))
  either <- modifyList(filled, list(rep_goal = "auto", rep_purpose = "either", rep_also = "absence", rep_prior = "shrunk", rep_n_at = ""))
  plan <- run(either)
  expect_identical(plan$choice[c("goal", "also")], list(goal = "bf_repeat", also = "bf_null"))
  gap <- replication_either_gap(plan)
  expect_match(gap, "To settle it either way", fixed = TRUE)
  g <- plan$goals[plan$goals$goal == "bf_null", ]
  expect_match(gap, replication_n_words(plan, g$n[1]), fixed = TRUE)
  expect_match(as.character(replication_main_chances_ui(plan)), "rep-either-gap", fixed = TRUE)
  # Not for the other purposes, which plan for what they aim to show.
  expect_null(replication_either_gap(run(modifyList(either, list(rep_purpose = "confirm")))))
  expect_null(replication_either_gap(run(modifyList(either, list(rep_purpose = "absent")))))
})

test_that("an expected dropout gives the number to recruit, in the result, the write-up and the script", {
  skip_if(is.null(engine_function("replication_recruitment")), "this engine has no replication_recruitment()")
  run <- function(v) replication_run(v, engine_function("replication_planning"))
  v <- modifyList(filled, list(rep_attrition = "0.1", rep_n_at = ""))
  plan <- run(v)
  n <- plan$at_main$n
  expect_equal(plan$recruit$n_recruit, 2 * ceiling(n / 2 / 0.9 - 1e-9))
  html <- as.character(replication_result_ui(plan))
  expect_match(html, "rep-recruit", fixed = TRUE)
  expect_match(html, sprintf("%s participants (%s per group), allowing for 10%% dropout", format(plan$recruit$n_recruit, big.mark = ","),
    format(plan$recruit$groups_recruit[1], big.mark = ",")), fixed = TRUE)
  expect_match(replication_methods_paragraph(plan, plan$choice$goal, plan$choice$prior), "so we will recruit", fixed = TRUE)
  report <- paste(replication_report(v, plan), collapse = "\n")
  expect_match(report, "expected dropout 10%", fixed = TRUE)
  expect_match(replication_script_text(plan, engine_function("replication_planning_script")), "n_recruit <- 2 * ceiling", fixed = TRUE)
  # None without a dropout, and a dropout that isn't a proportion is asked for again.
  expect_null(run(filled)$recruit)
  expect_match(paste(replication_settings_missing(modifyList(v, list(rep_attrition = "10"))), collapse = " "), "dropout as a proportion", fixed = TRUE)
  expect_length(replication_settings_missing(modifyList(v, list(rep_attrition = "0"))), 0)
})

test_that("unequal groups are planned, named in the result and the write-up, and allowed for in recruitment", {
  skip_if(!"allocation_ratio" %in% names(formals(engine_function("replication_planning"))), "this engine plans equal groups only")
  run <- function(v) replication_run(v, engine_function("replication_planning"))
  v <- modifyList(filled, list(rep_ratio = "2", rep_attrition = "0.1", rep_n_at = ""))
  expect_identical(replication_args(v)$allocation_ratio, 2)
  # Blank, 1 or another design: equal groups.
  expect_null(replication_args(modifyList(v, list(rep_ratio = "")))$allocation_ratio)
  expect_null(replication_args(modifyList(v, list(rep_ratio = "1")))$allocation_ratio)
  expect_null(replication_args(modifyList(v, list(rep_design = "paired", rep_n = "30")))$allocation_ratio)
  plan <- run(v)
  equal <- run(modifyList(v, list(rep_ratio = "")))
  expect_gt(plan$at_main$n, equal$at_main$n)
  g <- engine_function("replication_recruitment")(plan$at_main$n, groups = 2, allocation_ratio = 2)$groups_analysed
  html <- as.character(replication_result_ui(plan))
  expect_match(html, sprintf("(%s in group 1, %s in group 2)", g[1], g[2]), fixed = TRUE)
  expect_match(html, "in group 1, ", fixed = TRUE)
  expect_equal(plan$recruit$groups_recruit, ceiling(g / 0.9 - 1e-9))
  expect_match(html, "correction for publication bias plans two equal groups", fixed = TRUE)
  report <- paste(replication_report(v, plan), collapse = "\n")
  expect_match(report, "group 2 2 times the size of group 1", fixed = TRUE)
  expect_match(replication_methods_paragraph(plan, plan$choice$goal, plan$choice$prior), "in group 2", fixed = TRUE)
  expect_match(replication_script_text(plan, engine_function("replication_planning_script")), "ratio <- 2", fixed = TRUE)
  # A ratio that isn't a number above 0 is asked for again.
  expect_match(paste(replication_settings_missing(modifyList(v, list(rep_ratio = "two"))), collapse = " "), "groups' ratio", fixed = TRUE)
  expect_true(is.na(replication_ratio(list(rep_ratio = "0"))))
  expect_true("rep_ratio" %in% replication_field_ids)
})

test_that("a change in the outcome measure's reliability is planned, explained and cited", {
  skip_if(!"reliability_original" %in% names(formals(engine_function("replication_planning"))), "this engine has no reliabilities")
  run <- function(v) replication_run(v, engine_function("replication_planning"))
  v <- modifyList(filled, list(rep_rel_original = "0.9", rep_rel_replication = "0.7", rep_n_at = ""))
  args <- replication_args(v)
  expect_identical(c(args$reliability_original, args$reliability_replication), c(0.9, 0.7))
  # Not for pairs, and not unless both are numbers above 0 and at most 1.
  expect_null(replication_args(modifyList(v, list(rep_design = "paired", rep_n = "30")))$reliability_original)
  expect_null(replication_reliabilities(modifyList(v, list(rep_rel_replication = ""))))
  expect_match(paste(replication_settings_missing(modifyList(v, list(rep_rel_replication = ""))), collapse = " "),
    "reliability in both studies", fixed = TRUE)
  plan <- run(v)
  same <- run(modifyList(v, list(rep_rel_original = "", rep_rel_replication = "")))
  expect_gt(plan$at_main$n, same$at_main$n)
  html <- as.character(replication_result_ui(plan))
  expect_match(html, "Planned for the replication&#39;s measure|Planned for the replication's measure")
  expect_match(replication_methods_paragraph(plan, plan$choice$goal, plan$choice$prior), "Schmidt & Hunter, 1996", fixed = TRUE)
  expect_true("Schmidt1996_measurement" %in% replication_ref_keys_used(plan))
  # Small telescopes isn't offered, and the equivalence test needs a smallest effect.
  expect_false("small_telescopes" %in% plan$goals$goal)
  settings <- replication_criteria_settings(modifyList(v, list(rep_goal = "negligible", rep_smallest = "")))
  expect_true(settings$bound_needed)
  expect_true(all(c("rep_rel_original", "rep_rel_replication") %in% replication_field_ids))
})
