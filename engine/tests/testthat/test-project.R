# Project files (write_project(), read_project(), reproduce_project()):
# a saved project reloads to identical inputs and reproduces the same
# result.

project_spec <- function(name, goal, ...) {
  spec <- example_spec(name)
  spec$options <- c(list(seed = 11), list(...))
  spec$goal <- goal
  validate_spec(spec)
}

route_example <- list(
  route = "choose",
  endpoint = "E2",
  history = list(
    list(node = "S1", answer = "A score"),
    list(node = "Q1", answer = "A difference between groups")
  ),
  form_values = list(d = 0.4, alpha = 0.05, n = 128L)
)

save_and_read <- function(spec, result = NULL, route = list()) {
  path <- tempfile(fileext = ".powerkit.json")
  on.exit(unlink(path))
  write_project(spec, result, route = route, file = path)
  read_project(path)
}

test_that("a saved project reloads to identical inputs", {
  spec <- project_spec("independent_t", list(type = "power", n = 128))
  result <- run_spec(spec)
  project <- save_and_read(spec, result, route_example)
  expect_s3_class(project, "powerkit_project")
  expect_identical(unclass(project$spec), unclass(spec))
  expect_identical(spec_hash(project$spec), spec_hash(spec))
  expect_identical(project$spec$options$seed, 11L)
  expect_equal(project$route, route_example)
  expect_length(project$notes, 0)
})

test_that("a reloaded project reproduces the same result, exactly and by simulation", {
  specs <- list(
    project_spec("independent_t", list(type = "sample_size", power = 0.8), attrition = 0.1),
    project_spec("anova_2x2_between", list(type = "sensitivity", n = 120, power = 0.8)),
    # Simulation (Spower): the seed in the spec gives the same data sets.
    project_spec("correlation", list(type = "power", n = 80), method = "simulation", nrep = 200)
  )
  for (spec in specs) {
    result <- run_spec(spec)
    project <- save_and_read(spec, result)
    again <- reproduce_project(project)
    expect_true(again$same, info = spec$template)
    expect_length(again$differences, 0)
    expect_equal(again$result$curve, result$curve, info = spec$template)
    expect_equal(again$result$n_required, result$n_required, info = spec$template)
    expect_equal(again$result$provenance$spec_hash, result$provenance$spec_hash)
  }
})

test_that("a simulated project reproduces on the cores it ran on, whatever this session uses", {
  # Spower runs its replications in one random stream per core, so the
  # same seed gives another answer on another number of cores: reproducing
  # pins the number the file records.
  spec <- project_spec("correlation", list(type = "power", n = 80), method = "simulation", nrep = 200)
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  result <- run_spec(spec)
  project <- save_and_read(spec, result)
  expect_identical(project$result$provenance$cores, 1L)
  options(powerkit.cores = 2)
  again <- reproduce_project(project)
  expect_true(again$same)
  expect_equal(again$result$curve, result$curve)
  expect_identical(getOption("powerkit.cores"), 2)

  # A file saved before the cores were recorded says why it may differ.
  record <- jsonlite::parse_json(write_project(spec, result), simplifyVector = FALSE)
  record$result$provenance$cores <- NULL
  record$result$curve[[1]]$power <- 0.123
  older <- read_project(jsonlite::toJSON(record, auto_unbox = TRUE, digits = NA, null = "null"))
  expect_match(reproduce_project(older)$differences, "doesn't record how many cores", all = FALSE)

  # An exact result records no cores and reproduces as before.
  exact <- project_spec("independent_t", list(type = "power", n = 128), method = "exact")
  project <- save_and_read(exact, run_spec(exact))
  expect_null(project$result$provenance$cores)
  expect_true(reproduce_project(project)$same)
})

test_that("a project saves the result's provenance and versions", {
  spec <- project_spec("paired_t", list(type = "power", n = 40))
  result <- run_spec(spec)
  project <- save_and_read(spec, result)
  p <- project$result$provenance
  expect_equal(p$backend, result$provenance$backend)
  expect_equal(p$seed, 11L)
  expect_equal(unlist(p$packages), result$provenance$packages)
  expect_equal(project$powerkit_version, as.character(utils::packageVersion("powerkit")))
  expect_equal(project$r_version, R.version.string)
  expect_true(project$result$check_run_passed)
})

test_that("a project without a result reloads, and reproducing it just runs it", {
  spec <- project_spec("one_sample_t", list(type = "power", n = 60))
  project <- save_and_read(spec)
  expect_null(project$result)
  again <- reproduce_project(project)
  expect_true(is.na(again$same))
  expect_s3_class(again$result, "powerkit_result")
})

test_that("changes and differences are reported in plain English", {
  spec <- project_spec("independent_t", list(type = "power", n = 128))
  result <- run_spec(spec)
  text <- write_project(spec, result)
  raw <- jsonlite::parse_json(text, simplifyVector = FALSE)

  edited <- raw
  edited$spec$population$d <- 0.5
  project <- read_project(jsonlite::toJSON(edited, auto_unbox = TRUE, digits = NA, null = "null"))
  expect_match(project$notes, "changed after it was saved", all = FALSE)
  expect_false(reproduce_project(project)$same)

  older <- raw
  older$powerkit_version <- "0.0.0.1"
  older$result$provenance$packages$pwr <- "0.1"
  project <- read_project(jsonlite::toJSON(older, auto_unbox = TRUE, digits = NA, null = "null"))
  expect_match(project$notes, "Saved with powerkit 0.0.0.1", all = FALSE)
  expect_match(project$notes, "Saved with pwr 0.1", all = FALSE)
})

test_that("files that aren't projects, or are from a newer powerkit, are refused", {
  expect_error(read_project("{not json"), class = "powerkit_project_error")
  expect_error(read_project("{\"spec_version\": \"0.1\"}"), "isn't a powerkit project", class = "powerkit_project_error")
  spec <- project_spec("one_sample_t", list(type = "power", n = 60))
  raw <- jsonlite::parse_json(write_project(spec), simplifyVector = FALSE)
  raw$format_version <- 99
  expect_error(
    read_project(jsonlite::toJSON(raw, auto_unbox = TRUE, digits = NA, null = "null")),
    "newer version of powerkit", class = "powerkit_project_error"
  )
  raw$format_version <- 1
  raw$spec$goal$n <- -5
  expect_error(read_project(jsonlite::toJSON(raw, auto_unbox = TRUE, digits = NA, null = "null")), class = "powerkit_spec_error")
})

test_that("a result from another spec, or a spec with no seed, can't be saved together", {
  spec <- project_spec("independent_t", list(type = "power", n = 128))
  other <- project_spec("independent_t", list(type = "power", n = 100))
  expect_error(write_project(other, run_spec(spec)), "spec hashes differ", class = "powerkit_project_error")
  unseeded <- unclass(spec)
  unseeded$options$seed <- NULL
  unseeded <- validate_spec(unseeded)
  expect_error(write_project(unseeded, run_spec(unseeded)), "has no seed", class = "powerkit_project_error")
})

test_that("a project holds the whole result, which reads back identical without running it", {
  spec <- read_spec(system.file("specs", "anova_2x2_mixed.json", package = "powerkit"))
  result <- run_spec(spec)
  path <- tempfile(fileext = ".powerkit.json")
  on.exit(unlink(path))
  write_project(spec, result, file = path)
  project <- read_project(path)
  expect_identical(unclass(saved_result(project)), unclass(result))
  expect_s3_class(saved_result(project), "powerkit_result")
  # Missing values, infinities, names, empty vectors and data frames keep
  # their types.
  value <- list(a = NA, b = c(x = 1.5, y = NA, z = Inf, w = NaN, v = 1 / 3), c = data.frame(n = 1:2, s = c("a", NA)), k = data.frame(x = 1, row.names = "first"),
    d = NULL, e = list(), f = character(0), g = 1L, h = structure(list(q = TRUE), class = "foo"))
  json <- jsonlite::toJSON(encode_value(value), auto_unbox = TRUE, digits = NA, null = "null", na = "null")
  expect_identical(decode_value(jsonlite::parse_json(json, simplifyVector = FALSE)), value)
  # A file without it (saved by an earlier powerkit), or whose spec was
  # changed after saving, gives NULL: the result has to be run again.
  older <- project
  older$screen <- NULL
  expect_null(saved_result(older))
  changed <- project
  changed$spec$target_test$alpha <- 0.01
  expect_null(saved_result(changed))
})
