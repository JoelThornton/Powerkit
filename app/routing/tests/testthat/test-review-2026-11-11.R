# Fixes from the pre-testing review of 11 November 2026: the default
# two-group test keeps its "How sure can you be?" panels, a percentage
# typed for a proportion gets a useful message, and a simplified group
# ratio is stated.

test_that("Welch's t-test, the two-group default, has the explore and smaller-effect panels", {
  spec <- list(design = "basic_test", template = "independent_t", target_test = list(method = "welch_t"),
    population = list(d = 0.5), goal = list(type = "sample_size", power = 0.8), options = list())
  expect_identical(explore_effect(spec)$field, "d")
  expect_false(is.null(explore_ui(spec, list())))
  # A simulated or rank-based version still has none.
  spec$options$method <- "simulation"
  expect_null(explore_effect(spec))
})

test_that("curves follow the engine's step between whole-group totals", {
  spec <- list(template = "independent_t", options = list(allocation_ratio = 0.5), goal = list(n = 90))
  expect_identical(curve_step(spec, list(n_step = 3)), 3)
  sizes <- explore_sizes(spec, list(goal_type = "power", n_step = 3))
  expect_true(all(sizes %% 3 == 0))
  # Results saved before the engine reported its step.
  expect_identical(curve_step(list(template = "independent_t", options = list()), list()), 2)
  expect_identical(curve_step(list(template = "paired_t", options = list()), list()), 1)
})

test_that("a percentage typed for a proportion says what to type", {
  fields <- form_fields(form_groups(forms, "E2", 2))
  values <- modifyList(form_examples$E2, list(goal = "sample_size", power = "80"))
  problems <- form_problems(fields, values)
  expect_true(any(grepl("for 80%, type 0.8", problems, fixed = TRUE)))
  expect_false(any(grepl("must be less than 1", problems, fixed = TRUE)))
  values$power <- "0.8"; values$alpha <- "5"
  expect_true(any(grepl("for 5%, type 0.05", form_problems(fields, values), fixed = TRUE)))
})

test_that("a simplified group ratio is stated on the result and in the write-up", {
  expect_null(allocation_note(list()))
  note <- allocation_note(list(allocation = list(entered = 0.67, ratio = 2 / 3, group1 = 3, group2 = 2)))
  expect_match(note, "3 : 2 (group 1 : group 2)", fixed = TRUE)
  expect_match(note, "0.67", fixed = TRUE)
})

test_that("the main button says what it does, and feedback is one click from every screen", {
  code <- paste(readLines(file.path(routing_dir, "R", "forms_ui.R")), collapse = "\n")
  expect_match(code, 'actionButton("form_check", "Calculate"', fixed = TRUE)
  app <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(app, "Feedback on this screen", fixed = TRUE)
})

test_that("a rule of thumb can be named as the source, and is written up as one", {
  fields <- form_fields(form_groups(forms, "E2"))
  values <- modifyList(form_examples[["E2"]], list(just_type = "convention", just_source = "Cohen's medium"))
  expect_length(form_problems(fields, values), 0)
  spec <- build_spec(forms, "E2", fields, values)
  expect_identical(spec$effect_justification$type, "convention")
  expect_match(reasoning_line(values), "a convention or rule of thumb, not evidence about this effect", fixed = TRUE)
  expect_warning(powerkit::validate_spec(spec), "convention or rule of thumb", fixed = TRUE)
})

test_that("finding the smallest detectable effect asks for no effect-size source", {
  fields <- form_fields(form_groups(forms, "E2"))
  values <- modifyList(form_examples[["E2"]], list(goal = "sensitivity", n = "120", just_type = "", just_source = ""))
  values[c("d", "power")] <- list("", "0.8")
  expect_false("just_type" %in% names(form_problems(fields, values)))
  expect_identical(build_spec(forms, "E2", fields, values)$effect_justification$type, "none")
  expect_null(reasoning_line(values))
  # Asked for as before when an effect size is planned for.
  values$goal <- "sample_size"; values$d <- "0.5"
  expect_true("just_type" %in% names(form_problems(fields, values)))
})

test_that("a hidden test selector does not name the result's test", {
  id <- names(Filter(function(f) any(vapply(form_fields(f$groups), function(x) identical(x$id, "coef_test"), logical(1))), forms$forms))[1]
  fields <- form_fields(form_groups(forms, id))
  spec <- list(target_test = list(method = "f_test"))
  expect_null(selected_method_label(spec, fields, list(question = "r2_increase")))
  expect_match(selected_method_label(spec, fields, list(question = "single_coefficient")), "usual t test", fixed = TRUE)
})

test_that("a package's deprecation notice is not shown as a note about the plan", {
  run <- function(spec) {
    warning("`aes_string()` was deprecated in ggplot2 3.0.0. Please report the issue to the authors.")
    warning("Power is low for this design.")
    list()
  }
  calc <- run_calculation(list(options = list(seed = 1L)), run = run)
  expect_identical(calc$notes, "Power is low for this design.")
})

test_that("editing only the reasoning gives the same calculation key; editing a number does not", {
  fields <- form_fields(form_groups(forms, "E2"))
  values <- form_examples[["E2"]]
  key <- function(v) calculation_key(build_spec(forms, "E2", fields, v), fields)
  first <- key(values)
  expect_identical(key(modifyList(values, list(just_source = "A different reason entirely"))), first)
  expect_identical(key(modifyList(values, list(alpha_reason = "Field convention"))), first)
  expect_false(identical(key(modifyList(values, list(d = "0.31"))), first))
  expect_false(identical(key(modifyList(values, list(alpha = "0.01"))), first))
  expect_false(identical(key(modifyList(values, list(just_type = "pilot_study", just_adjustment = "Halved"))), first))
})

test_that("a reused result carries the new words and a spec hash that matches them", {
  fields <- form_fields(form_groups(forms, "E2"))
  values <- form_examples[["E2"]]
  spec <- build_spec(forms, "E2", fields, values)
  calc <- run_calculation(spec, seed = forms$default_seed)
  edited <- build_spec(forms, "E2", fields, modifyList(values, list(just_source = "A different reason entirely")))
  again <- reused_calculation(calc, edited)
  expect_identical(again$spec$effect_justification$source, "A different reason entirely")
  expect_identical(again$spec$options$seed, calc$spec$options$seed)
  expect_identical(again$result$provenance$spec_hash, powerkit::spec_hash(again$spec))
  expect_identical(again$result$n_required, calc$result$n_required)
  # The exported script accepts the pair.
  expect_no_error(powerkit::export_script(again$spec, again$result))
})

test_that("the study plan survives a round trip through the browser's copy", {
  fields <- form_fields(form_groups(forms, "E2"))
  values <- form_examples[["E2"]]
  calc <- run_calculation(build_spec(forms, "E2", fields, values), seed = forms$default_seed)
  entries <- list(plan_entry(tree, "E2", calc, list(endpoint = "E2", form_values = values)))
  text <- study_plan_for_browser(entries)
  expect_true(nzchar(text))
  back <- study_plan_from_browser(tree, text)
  expect_length(back, 1)
  expect_equal(back[[1]]$n, entries[[1]]$n)
  expect_identical(back[[1]]$endpoint, "E2")
  expect_identical(study_plan_for_browser(list()), "")
  expect_null(study_plan_from_browser(tree, "not a plan"))
  expect_null(study_plan_from_browser(tree, ""))
})

test_that("the study plan button shows only when the plan holds an analysis, and discarding asks first", {
  expect_null(study_plan_chip_ui(0))
  expect_match(as.character(study_plan_chip_ui(2)), "Your study plan (2)", fixed = TRUE)
  html <- as.character(study_plan_ui(list(list(endpoint = "E2", label = "A t-test", goal = "sample_size", n = 128L))))
  expect_match(html, "confirm(&#39;Start a new plan?", fixed = TRUE)
  expect_match(html, "confirm(&#39;Remove this analysis", fixed = TRUE)
})

test_that("run_calculation() stands alone, as the background process runs it", {
  # The background worker gets this function without the app's others, so
  # a helper called from its warning handler stopped every background run
  # that carried a warning.
  alone <- run_calculation
  environment(alone) <- new.env(parent = baseenv())
  run <- function(spec) { warning("A note about the plan."); list() }
  calc <- alone(list(options = list(seed = 1L)), run = run, seed = 1L)
  expect_identical(calc$status, "ok")
  expect_identical(calc$notes, "A note about the plan.")
})

test_that("the two-proportions z test warns when an expected count is small, and points to Fisher's test", {
  spec <- list(template = "two_proportions", target_test = list(method = "z_test"), population = list(p1 = 0.05, p2 = 0.30), goal = list(n = 20))
  note <- small_count_note(spec, list(goal_type = "power", curve = list(n = 20)))
  expect_match(note, "only about 0.5 people", fixed = TRUE)
  expect_match(note, "Fisher's exact test", fixed = TRUE)
  # Ordinary sizes: no note. Fisher's test: no note.
  spec$population <- list(p1 = 0.6, p2 = 0.7)
  expect_null(small_count_note(spec, list(goal_type = "sample_size", n_required = list(n = 712))))
  spec$population <- list(p1 = 0.05, p2 = 0.30); spec$target_test$method <- "fisher_exact"
  expect_null(small_count_note(spec, list(goal_type = "power", curve = list(n = 20))))
})

test_that("unequal SDs or correlations plan for the Greenhouse-Geisser test by default (Departure 26)", {
  for (ep in c("E54", "E55", "E20")) {
    fields <- form_fields(form_groups(forms, ep))
    correction <- Filter(function(f) identical(f$id, "correction"), fields)[[1]]
    expect_identical(correction$default, "GG", info = ep)
    expect_true("26" %in% unlist(forms$forms[[ep]]$departures), info = ep)
  }
  spec <- list(design = "factorial_anova", template = "oneway_within",
    variables = list(A = list(type = "within_factor", levels = list("a", "b", "c")), Y = list(type = "continuous")),
    population = list(means = list(600, 620, 650), sd = list(100, 100, 100), r = list(0.8, 0.5, 0.2)),
    target_test = list(effect = "main_effect_A", method = "anova_f", correction = "GG"))
  expect_match(departures_for(forms, "E54", spec), "Greenhouse-Geisser corrected F test unless you choose otherwise", all = FALSE)
  expect_null(uncorrected_f_note(spec))
  # The uncorrected test stays available, with a warning and no departure.
  spec$target_test$correction <- "none"
  expect_false(any(grepl("unless you choose otherwise; Superpower", departures_for(forms, "E54", spec), fixed = TRUE)))
  expect_match(uncorrected_f_note(spec), "false positives more often than your significance level", fixed = TRUE)
  expect_true(uncorrected_f_note(spec) %in% planning_warning_notes(spec))
  # One SD and one correlation keep sphericity: neither applies.
  same <- modifyList(spec, list(population = list(sd = 100, r = 0.5)))
  same$population$sd <- 100; same$population$r <- 0.5
  expect_null(uncorrected_f_note(same))
  # Two repeated measurements cannot break sphericity.
  two <- spec
  two$variables$A$levels <- list("a", "b")
  expect_null(uncorrected_f_note(two))
  two$target_test$correction <- "GG"
  expect_false(any(grepl("Superpower applies no correction", departures_for(forms, "E54", two), fixed = TRUE)))
})

test_that("the correlation card plans by the exact method, with Fisher's z as a choice", {
  fields <- form_fields(form_groups(forms, "E4"))
  formula <- Filter(function(f) identical(f$id, "correlation_formula"), fields)[[1]]
  expect_identical(formula$default, "exact")
  expect_identical(names(formula$choices), c("exact", "fisher_z"))
  spec <- list(design = "basic_test", template = "correlation", target_test = list(method = "pearson"),
    population = list(r = 0.3), options = list())
  # The exact method is G*Power's: no note. Fisher's z carries one.
  expect_false(any(grepl("Fisher's z, an approximation", departures_for(forms, "E4", spec), fixed = TRUE)))
  spec$options$correlation_formula <- "fisher_z"
  expect_match(departures_for(forms, "E4", spec), "85 rather than 84", all = FALSE)
  values <- modifyList(form_examples$E4, list(r = "0.3", goal = "sample_size", power = "0.8", alpha = "0.05"))
  calc <- run_calculation(build_spec(forms, "E4", fields, values), seed = forms$default_seed)
  expect_identical(calc$status, "ok")
  expect_equal(calc$result$n_required$n, 84)
})
