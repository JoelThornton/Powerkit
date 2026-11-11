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
