test_that("incomplete drafts survive two file round trips without a result", {
  route <- list(app = "routing-prototype", route = "choose", endpoint = "E2", came_from = "node",
    start = list(), ctx = list(), history = list(), form_k = 2L,
    form_values = list(d = "", power = "", just_source = "", allocation_ratio = "2"))
  file <- tempfile(fileext = ".powerkit.json")
  on.exit(unlink(file))
  for (i in 1:2) {
    write_draft(route, file)
    record <- read_draft_record(file)
    expect_identical(record$format, "powerkit-draft")
    expect_null(record$result)
    expect_null(record$spec)
    restored <- restore_draft(record, tree, forms)
    expect_type(restored, "list")
    expect_identical(restored$form_values, route$form_values)
    expect_null(restored$calc)
    route$form_values <- restored$form_values
  }
  record$result <- list(power = 1)
  expect_null(restore_draft(record, tree, forms)$calc)
  record$version <- 99
  expect_type(restore_draft(record, tree, forms), "character")
})

test_that("drafts allow no answers and reject unsupported fields and malformed values", {
  record <- list(format = "powerkit-draft", version = 1L, route = list(app = "routing-prototype",
    endpoint = "E2", form_values = list()))
  expect_type(restore_draft(record, tree, forms), "list")
  record$route$form_values <- list(not_a_field = "anything")
  expect_type(restore_draft(record, tree, forms), "character")
  record$route$form_values <- list(d = list(deep = list(a = 1)))
  expect_type(restore_draft(record, tree, forms), "character")
  expect_match(as.character(draft_opened_ui("2026-11-04")), "No calculated or validated result", fixed = TRUE)
})

test_that("an unfinished draft is offered on the plan tab with continue, not now and discard, and its time in plain words", {
  html <- as.character(draft_offer_ui("Compare two separate groups on a score", "2026-11-07 13:05:16 UTC"))
  expect_match(html, "Continue my plan", fixed = TRUE)
  expect_match(html, "Not now", fixed = TRUE)
  expect_match(html, "Discard my draft", fixed = TRUE)
  expect_no_match(html, "Start fresh", fixed = TRUE)
  expect_match(html, 'datetime="2026-11-07T13:05:16Z"', fixed = TRUE)
  expect_match(html, "on 07 November 2026 at 13:05 UTC", fixed = TRUE)
  # The offer sits in the plan tab, and is no longer a dialog over every tab.
  app <- readLines(file.path(routing_dir, "app.R"))
  expect_true(any(grepl('value = "Plan a power analysis", div(class = "pt-3", uiOutput("draft_offer")', app, fixed = TRUE)))
  expect_false(any(grepl("Continue where you left off", app, fixed = TRUE)))
})

test_that("the guided plan and whole-study inputs survive a file round trip", {
  state <- list(route = "plan", start = list(aim = "plan"), ctx = list(times = "once"),
    history = list(list(node = names(tree$nodes)[1], answer = "plan", ctx = list())),
    answers = list(x = "cond2", outcome = "score", mediators = "one"),
    ticked = c("total", "indirect"), primary = "indirect", asks = list(total = "difference"), rule = "each",
    plan_values = list(total = list(d = "0.4", power = "0.9")), plan_shared = list(alpha = "0.05"),
    plan_results = list(total = list(endpoint = "E2", goal = "sample_size", n = 264)),
    ws_values = list(n = "200", seed = "1234", means = list(m_1_1 = "0", m_2_1 = "0.5")), ws_names = list(X = "Training", M = "Skill"),
    ws_spec = list(kind = "whole_study", nrep = 400))
  ids <- vapply(tree$guided$analyses, `[[`, "", "id")
  state$ticked <- ids[1:2]; state$primary <- ids[2]
  state$asks <- stats::setNames(list("difference"), ids[1])
  state$plan_values <- stats::setNames(list(list(d = "0.4", power = "0.9")), ids[1])
  file <- tempfile(fileext = ".powerkit.json")
  on.exit(unlink(file))
  write_guided_plan(state, file)
  record <- read_guided_plan_record(file)
  expect_identical(record$format, "powerkit-guided-plan")
  restored <- restore_guided_plan(record, tree)
  expect_type(restored, "list")
  expect_identical(restored$screen, "g_plan")
  for (k in c("answers", "ticked", "primary", "rule", "ws_names")) expect_identical(restored[[k]], state[[k]], info = k)
  expect_identical(restored$plan_values[[ids[1]]]$d, "0.4")
  expect_identical(restored$ws_values$n, "200")
  expect_identical(restored$ws_values$means, list(m_1_1 = "0", m_2_1 = "0.5"))
  expect_null(restored$ws_calc)
  expect_match(as.character(guided_plan_opened_ui(record)), "Plan opened", fixed = TRUE)
  # Not a draft or a project, and checked against the tree.
  expect_null(read_draft_record(file))
  record$plan$ticked <- list("not-an-analysis")
  expect_type(restore_guided_plan(record, tree), "character")
  record <- read_guided_plan_record(file)
  record$plan$answers$x <- "not-an-option"
  expect_type(restore_guided_plan(record, tree), "character")
  record$version <- 2
  expect_type(restore_guided_plan(record, tree), "character")
})

test_that("a whole-study specification is recognised and pointed to R", {
  file <- tempfile(fileext = ".json")
  on.exit(unlink(file))
  jsonlite::write_json(list(kind = "whole_study", nrep = 400), file, auto_unbox = TRUE)
  expect_true(whole_study_spec_file(file))
  jsonlite::write_json(list(format = "powerkit-draft"), file, auto_unbox = TRUE)
  expect_false(whole_study_spec_file(file))
  expect_match(whole_study_spec_message, "Save this plan", fixed = TRUE)
})
