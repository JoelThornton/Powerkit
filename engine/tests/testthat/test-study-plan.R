# Study plan files (write_study_plan(), read_study_plan()): several
# analyses in one file, each reopening and reproducing as its own project.

plan_spec <- function(name, goal) {
  spec <- example_spec(name)
  spec$options <- list(seed = 11)
  spec$goal <- goal
  validate_spec(spec)
}

test_that("a study plan keeps each analysis, and each reproduces its result", {
  t_spec <- plan_spec("independent_t", list(type = "power", n = 128))
  r_spec <- plan_spec("correlation", list(type = "sample_size", power = 0.8))
  t_result <- run_spec(t_spec)
  r_result <- run_spec(r_spec)
  path <- tempfile(fileext = ".powerkit.json")
  on.exit(unlink(path))
  write_study_plan(list(
    list(spec = t_spec, result = t_result, route = list(endpoint = "E2", form_values = list(n = 128L))),
    list(spec = r_spec, result = r_result)
  ), file = path)
  plan <- read_study_plan(path)
  expect_s3_class(plan, "powerkit_study_plan")
  expect_length(plan$analyses, 2)
  expect_identical(spec_hash(plan$analyses[[1]]$spec), spec_hash(t_spec))
  expect_identical(spec_hash(plan$analyses[[2]]$spec), spec_hash(r_spec))
  expect_identical(plan$analyses[[1]]$route$endpoint, "E2")
  expect_length(plan$analyses[[1]]$notes, 0)
  expect_true(reproduce_project(plan$analyses[[1]])$same)
  expect_true(reproduce_project(plan$analyses[[2]])$same)
})

test_that("study plans and projects refuse each other's files in plain English", {
  spec <- plan_spec("independent_t", list(type = "power", n = 128))
  expect_error(write_study_plan(list()), "at least one analysis", class = "powerkit_error")
  expect_error(read_study_plan(write_project(spec)), "isn't a powerkit study plan", class = "powerkit_error")
  expect_error(read_project(write_study_plan(list(list(spec = spec)))), "isn't a powerkit project", class = "powerkit_error")
  expect_error(read_study_plan("{not json"), "isn't valid JSON", class = "powerkit_error")
})
