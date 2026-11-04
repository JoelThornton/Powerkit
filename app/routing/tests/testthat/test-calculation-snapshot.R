test_that("saving uses the answers from the calculation, not later edits", {
  values <- list(d = "0.5", n = 128, just_source = "A previous study")
  calc <- list(status = "ok", route = list(form_values = values))
  expect_true(calculation_matches_values(calc, values))
  expect_true(calculation_matches_values(calc, modifyList(values, list(n = "128"))))
  edited <- modifyList(values, list(d = "0.8"))
  expect_false(calculation_matches_values(calc, edited))
  expect_identical(calc$route$form_values$d, "0.5")
  expect_false(calculation_matches_values(list(status = "ok"), values))
})

test_that("opening a saved calculation keeps its original route snapshot", {
  project <- list(spec = list(), route = list(form_values = list(d = "0.5")))
  calc <- saved_calc(project, saved = function(p) list())
  expect_identical(calc$route, project$route)
})

test_that("opened study-plan entries are passed back intact", {
  project <- structure(list(spec = list(), result = list(n_required = list(n = 128)),
    screen = list(t = "list"), route = list(endpoint = "E2")), class = "powerkit_project")
  expect_identical(plan_analyses(list(list(project = project)))[[1]], project)
})

test_that("restored answers must describe the saved calculation", {
  run <- engine_function("run_spec", file.path(repo_dir, "engine"))
  if (is.null(run) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("The installed engine is required for this check.")
  }
  skip_if(is.null(run), "powerkit's engine isn't available here")
  values <- form_examples$E2
  fields <- form_fields(form_groups(forms, "E2"))
  calc <- run_calculation(build_spec(forms, "E2", fields, values), run, seed = 11L)
  expect_identical(calc$status, "ok")
  project <- list(spec = calc$spec, route = list(endpoint = "E2", form_values = values))
  expect_true(project_form_matches_spec(project, forms))
  project$route$form_values$d <- "0.8"
  expect_false(project_form_matches_spec(project, forms))
})
