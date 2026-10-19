# Project files from the app: "Save project" hands the engine the spec, the
# result and the route (write_project()); "Open a saved project" reads it
# (read_project()) and puts the input screen back. A reopened project must
# give identical inputs and reproduce the same result.

run <- engine_function("run_spec", file.path(repo_dir, "engine"))
write_project <- engine_function("write_project", file.path(repo_dir, "engine"))
read_project <- engine_function("read_project", file.path(repo_dir, "engine"))
reproduce_project <- engine_function("reproduce_project", file.path(repo_dir, "engine"))
spec_hash <- engine_function("spec_hash", file.path(repo_dir, "engine"))

skip_without_projects <- function() {
  if (is.null(write_project) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine (with project files) couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(write_project) || is.null(read_project), "this engine has no project files")
}

example_state <- function(ep) {
  list(
    route = "choose", endpoint = ep, came_from = "node",
    ctx = list(outcome = "score"),
    history = list(list(node = "S1", answer = "A score", ctx = list())),
    form_k = 2L
  )
}

save_and_reopen <- function(ep, values) {
  fields <- form_fields(form_groups(forms, ep))
  spec <- build_spec(forms, ep, fields, values)
  calc <- run_calculation(spec, run, seed = 11L)
  path <- tempfile(fileext = ".powerkit.json")
  on.exit(unlink(path))
  write_project(calc$spec, calc$result, route = project_route(example_state(ep), values), file = path)
  project <- read_project(path)
  list(calc = calc, fields = fields, project = project,
    restored = restore_from_project(project$route, tree, forms))
}

test_that("a saved project reopens the same screen with identical values", {
  skip_without_projects()
  for (ep in c("E2", "E7")) {
    values <- form_examples[[ep]]
    out <- save_and_reopen(ep, values)
    r <- out$restored
    expect_type(r, "list")
    expect_identical(r$screen, "form", label = ep)
    expect_identical(r$endpoint, ep, label = ep)
    expect_identical(r$route, "choose")
    expect_identical(r$came_from, "node")
    expect_identical(r$form_k, 2L)
    expect_equal(r$history, example_state(ep)$history)
    expect_equal(r$ctx, example_state(ep)$ctx)
    expect_identical(r$form_values, as.list(values), label = ep)
  }
})

test_that("a reopened project reproduces the same result", {
  skip_without_projects()
  for (ep in c("E2", "E7")) {
    out <- save_and_reopen(ep, form_examples[[ep]])
    # Checking the reopened values again builds the same spec and result.
    again <- run_calculation(build_spec(forms, ep, out$fields, out$restored$form_values), run, seed = 11L)
    expect_identical(spec_hash(again$spec), spec_hash(out$calc$spec), label = ep)
    expect_equal(again$result$curve, out$calc$result$curve, label = ep)
    expect_equal(again$result$n_required, out$calc$result$n_required, label = ep)
    # And the engine's own check against the saved numbers agrees.
    expect_true(reproduce_project(out$project)$same, label = ep)
  }
})

test_that("projects the app can't reopen get a plain-English reason", {
  expect_match(restore_from_project(list(), tree, forms), "wasn't saved from the app")
  route <- project_route(example_state("E2"), list())
  route$endpoint <- "E43"
  expect_match(restore_from_project(route, tree, forms), "doesn't offer")
})

test_that("the start screen offers to open a project, and results offer to save one", {
  html <- as.character(open_project_ui())
  expect_match(html, "open_project", fixed = TRUE)
  expect_match(html, "Or open a saved project", fixed = TRUE)
  app <- readLines(file.path(routing_dir, "app.R"))
  expect_true(any(grepl("output$download_project <- downloadHandler", app, fixed = TRUE)))
  expect_true(any(grepl("open_project_ui()", app, fixed = TRUE)))
  results <- readLines(file.path(routing_dir, "R", "results.R"))
  expect_true(any(grepl("downloadButton(\"download_project\", \"Save project\"", results, fixed = TRUE)))
})

test_that("the notice after opening names the version and any differences", {
  project <- list(saved = "2026-10-18 10:00:00 UTC", powerkit_version = "0.0.0.9000",
    result = list(goal_type = "power"), notes = "Saved with pwr 1.2; here it is 1.3.0. Results may differ slightly.")
  html <- as.character(project_opened_ui(project))
  expect_match(html, "Project opened.", fixed = TRUE)
  expect_match(html, "powerkit 0.0.0.9000", fixed = TRUE)
  expect_match(html, "Saved with pwr 1.2", fixed = TRUE)
})

# The plan checker (19 October 2026) ------------------------------------------

test_that("the plan checker says what a shared plan found and what it leaves unstated", {
  skip_without_projects()
  values <- modifyList(form_examples[["E2"]], list(just_type = "pilot_study", just_source = "Our pilot (n = 20) found d = 0.4.", alpha = "0.01"))
  out <- save_and_reopen("E2", values)
  html <- as.character(plan_check_ui(tree, forms, out$project))
  expect_match(html, "Checking a shared plan", fixed = TRUE)
  expect_match(html, tree$endpoints$E2$plain_name, fixed = TRUE)
  expect_match(html, sprintf("You need %s participants in total", whole(out$calc$result$n_required$n)), fixed = TRUE)
  expect_match(html, "would miss it about 20 times in 100", fixed = TRUE)
  expect_match(html, "comes from a pilot study", fixed = TRUE)
  expect_match(html, "The significance level is 0.01 rather than 0.05, with no reason given", fixed = TRUE)
  expect_match(html, "no allowance for people who drop out", fixed = TRUE)
  expect_match(html, "No reason is given for the target power", fixed = TRUE)
  expect_match(html, "Our pilot (n = 20) found d = 0.4.", fixed = TRUE)
  expect_match(html, "not a pass or fail", fixed = TRUE)
  expect_match(html, "check_open", fixed = TRUE)
  expect_no_match(html, "No reasoning is given for the effect size", fixed = TRUE)
})

test_that("the plan checker's questions follow what the plan states", {
  base <- list(goal = "sample_size", just_type = "smallest_effect_of_interest", just_source = "A clinic would act on it.",
    power_reason = "A miss would waste a year.", alpha = "0.05", alternative = "two_sided", attrition = "0.1")
  result <- list(goal_type = "sample_size")
  expect_length(plan_questions(base, result), 0)
  q <- function(...) plan_questions(modifyList(base, list(...)), result)
  expect_match(q(just_source = ""), "No reasoning is given for the effect size", fixed = TRUE)
  expect_match(q(alternative = "greater"), "one-sided, with no reason given", fixed = TRUE)
  expect_length(q(alternative = "greater", alternative_reason = "The theory predicts an increase."), 0)
  expect_length(q(alpha = "0.01", alpha_reason = "A new claim."), 0)
  expect_match(q(attrition = ""), "no allowance", fixed = TRUE)
  expect_length(plan_questions(modifyList(base, list(attrition = "")), list(goal_type = "power")), 0)
  expect_match(q(claim = "all"), "every one of several tests", fixed = TRUE)
  expect_match(q(just_type = "prior_study", just_adjustment = "halved"), "adjusted as follows: “halved”", fixed = TRUE)
})
