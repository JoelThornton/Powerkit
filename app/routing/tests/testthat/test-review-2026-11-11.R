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
