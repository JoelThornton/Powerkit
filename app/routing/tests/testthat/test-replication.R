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
  expect_match(html, "(planned for no effect)", fixed = TRUE)
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
  expect_match(st, "102 (51 per group)", fixed = TRUE)
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
  expect_match(full, "| Goal | As reported | With its uncertainty | Shrunk towards zero |", fixed = TRUE)
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
    session$setInputs(rep_n1 = "20", rep_n2 = "20", rep_smallest = "0.2", rep_run = 2)
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
  expect_lt(regexpr("rep_run_quick", ui)[1], regexpr(">Goals and sample size</legend>", ui, fixed = TRUE)[1])
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
  expect_match(html, "Small telescopes is left out", fixed = TRUE)
  expect_no_match(html, "two-sided p =", fixed = TRUE)
  expect_match(html, "rep_to_sequential", fixed = TRUE)
  g <- plan$goals[plan$goals$goal == "bf_repeat", ]
  expect_match(as.character(replication_headline_ui(plan)), replication_n_words(plan, g$n[g$prior %in% "shrunk"]), fixed = TRUE)
  expect_match(as.character(replication_choice_ui(plan)), "<option value=\"bf_repeat\" selected>", fixed = TRUE)
  methods <- replication_methods_paragraph(plan, "bf_repeat", "uncertain")
  expect_match(methods, "bfpwr (Pawel & Held, 2025)", fixed = TRUE)
  expect_match(methods, "Ly et al., 2018", fixed = TRUE)
  expect_match(methods, replication_n_words(plan, g$n[g$prior %in% "uncertain"]), fixed = TRUE)
  expect_match(replication_methods_paragraph(plan, "bf_null", "uncertain"), "planned for a true effect of zero", fixed = TRUE)
  expect_match(replication_methods_paragraph(plan, "significance", "uncertain"), "read from its Bayes factor", fixed = TRUE)
  report <- paste(replication_report(bf_filled, plan), collapse = "\n")
  expect_match(report, "How it was analysed: a bayes factor", fixed = TRUE)
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
