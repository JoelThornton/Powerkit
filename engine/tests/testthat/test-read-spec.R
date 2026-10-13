test_that("read_spec() reads a spec file and returns a powerkit_spec", {
  spec <- read_spec(example_path("process_7"))
  expect_s3_class(spec, "powerkit_spec")
  expect_equal(spec$design, "moderated_mediation")
  expect_equal(spec$population$paths[["XW->M"]], 0.15)
})

test_that("read_spec() reads a JSON string", {
  json <- paste(readLines(example_path("independent_t")), collapse = "\n")
  spec <- read_spec(json)
  expect_equal(spec$template, "independent_t")
})

test_that("read_spec(validate = FALSE) reads a spec without checking it", {
  json <- '{"spec_version": "0.1", "design": "not_a_design"}'
  expect_no_error(spec <- read_spec(json, validate = FALSE))
  expect_equal(spec$design, "not_a_design")
  expect_error(read_spec(json), class = "powerkit_spec_error")
})

test_that("a missing file gives a plain-English error", {
  err <- expect_error(read_spec("no-such-spec.json"), class = "powerkit_spec_error")
  expect_match(conditionMessage(err), "Couldn't find the spec file 'no-such-spec.json'", fixed = TRUE)
})

test_that("an empty file gives a plain-English error", {
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path))
  writeLines("  ", path)
  err <- expect_error(read_spec(path), class = "powerkit_spec_error")
  expect_match(conditionMessage(err), "is empty", fixed = TRUE)
})

test_that("invalid JSON gives a plain-English error with common causes", {
  err <- expect_error(
    read_spec('{"spec_version": "0.1", "design": "basic_test",}'),
    class = "powerkit_spec_error"
  )
  expect_match(conditionMessage(err), "isn't valid JSON", fixed = TRUE)
  expect_match(conditionMessage(err), "missing or extra comma", fixed = TRUE)
})

test_that("JSON that isn't an object is rejected", {
  expect_spec_problem('[1, 2, 3]', "must be a set of named fields")
  expect_spec_problem(list(1, 2), "must be a set of named fields")
  expect_error(read_spec(42), "needs the path to a .json file", class = "powerkit_spec_error")
})

test_that("printing a spec gives a short summary in the user's labels", {
  spec <- read_spec(example_path("mediation_serial"))
  expect_output(print(spec), "Design:    mediation / process_6", fixed = TRUE)
  expect_output(print(spec), "M1 = Mindset beliefs", fixed = TRUE)
  expect_output(print(spec), "indirect_effect (X->M1->M2->Y)", fixed = TRUE)
})

test_that("a paired spec states the direction of d_z", {
  spec <- read_spec(example_path("paired_t"))
  expect_output(print(spec), "d_z = mean of (After minus Before) / SD of those differences", fixed = TRUE)
  expect_false(grepl("Effect:", paste(capture.output(print(read_spec(example_path("correlation")))), collapse = "\n")))
})
