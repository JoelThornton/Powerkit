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

test_that("a study plan keeps its id, name, description, roles and notes", {
  spec <- plan_spec("independent_t", list(type = "power", n = 128))
  res <- run_spec(spec)
  text <- write_study_plan(list(
    list(spec = spec, result = res, plan_role = "primary", plan_note = "Main test"),
    list(spec = spec, result = res)),
    id = "a1b2c3d4e5f60718", name = "Thesis study 2", description = "Does training help?")
  plan <- read_study_plan(text)
  expect_identical(plan$id, "a1b2c3d4e5f60718")
  expect_identical(plan$name, "Thesis study 2")
  expect_identical(plan$description, "Does training help?")
  expect_identical(plan$roles, c("primary", NA))
  expect_identical(plan$notes, c("Main test", NA))
  # An opened project keeps its role and note when saved again.
  opened <- plan$analyses[[1]]
  opened$plan_role <- "check"
  opened$plan_note <- "Kept"
  again <- read_study_plan(write_study_plan(list(opened)))
  expect_identical(again$roles, "check")
  expect_identical(again$notes, "Kept")
})

test_that("a plan without the new fields still reads, and its analyses read as projects", {
  spec <- plan_spec("independent_t", list(type = "power", n = 128))
  plan <- read_study_plan(write_study_plan(list(list(spec = spec, result = run_spec(spec)))))
  expect_null(plan$name)
  expect_null(plan$id)
  expect_null(plan$description)
  expect_identical(plan$roles, NA_character_)
  expect_identical(plan$notes, NA_character_)
  expect_s3_class(plan$analyses[[1]], "powerkit_project")
  top <- names(jsonlite::parse_json(write_study_plan(list(list(spec = spec)))))
  expect_false(any(c("id", "name", "description") %in% top))
})

test_that("a study plan keeps the guided plan's record as it was given", {
  spec <- plan_spec("independent_t", list(type = "power", n = 128))
  guided <- list(format = "powerkit-guided-plan", version = 1L, saved_at = "2026-11-13 10:00:00 UTC",
    plan = list(ticked = list("a1", "a2"), primary = list("a1"), rule = "all", ws_values = list(n = 120)))
  plan <- read_study_plan(write_study_plan(list(list(spec = spec)), guided = guided))
  expect_identical(plan$guided$plan$primary, list("a1"))
  expect_identical(plan$guided$plan$ws_values$n, 120L)
  expect_identical(plan$guided$format, "powerkit-guided-plan")
  # Absent: not written, and read as NULL.
  plain <- write_study_plan(list(list(spec = spec)))
  expect_false("guided" %in% names(jsonlite::parse_json(plain)))
  expect_null(read_study_plan(plain)$guided)
  expect_error(write_study_plan(list(list(spec = spec)), guided = "not a record"), "guided")
})

test_that("a study plan keeps a replication plan's record as it was given", {
  spec <- read_spec(system.file("specs", "independent_t.json", package = "powerkit"))
  replication <- list(format = "powerkit-replication-plan", version = 1L,
    fields = list(rep_study = "Smith (2020)", rep_effect = "0.45"), endpoint = "E2")
  plan <- read_study_plan(write_study_plan(list(list(spec = spec)), replication = replication))
  expect_identical(plan$replication$fields$rep_study, "Smith (2020)")
  expect_identical(plan$replication$endpoint, "E2")
  plain <- write_study_plan(list(list(spec = spec)))
  expect_false("replication" %in% names(jsonlite::parse_json(plain)))
  expect_null(read_study_plan(plain)$replication)
  expect_error(write_study_plan(list(list(spec = spec)), replication = "not a record"), "replication")
})
