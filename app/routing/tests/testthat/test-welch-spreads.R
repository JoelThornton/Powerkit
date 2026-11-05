test_that("Welch raw inputs select one common SD or two separate SDs", {
  fields <- form_fields(form_groups(forms, "E2", 2))
  by_id <- stats::setNames(fields, vapply(fields, `[[`, "", "id"))
  values <- list(method = "welch_t", effect_units = "raw", welch_sd_input = "separate")
  expect_false(field_applies(by_id$raw_sd, values))
  expect_true(field_applies(by_id$raw_sd1, values))
  expect_true(field_applies(by_id$raw_sd2, values))
  # Changing test cannot leave the common-SD box hidden by an old choice.
  values$method <- "student_t"
  expect_true(field_applies(by_id$raw_sd, values))
  expect_false(field_applies(by_id$raw_sd1, values))
  expect_match(shown_if_js(by_id$raw_sd), " || ", fixed = TRUE)
  values$method <- "welch_t"
  values$welch_sd_input <- NULL
  expect_true(field_applies(by_id$raw_sd, values))
})

test_that("Welch population assumptions remain in notes and copied text", {
  spec <- list(template = "independent_t", target_test = list(method = "welch_t"), population = list(sd_ratio = 3))
  words <- welch_population_note(spec)
  expect_match(words, "3 times", fixed = TRUE)
  expect_match(words, "normal scores", fixed = TRUE)
  expect_match(words, "independent of allocation", fixed = TRUE)
})

test_that("the raw Welch form ignores a hidden common SD and preserves both spreads", {
  fields <- form_fields(form_groups(forms, "E2", 2))
  values <- modifyList(form_examples$E2, list(effect_units = "raw", goal = "power", n = "120",
    welch_sd_input = "separate", raw_mean_1 = "20", raw_mean_2 = "24",
    raw_sd = "99", raw_sd1 = "5", raw_sd2 = "15", welch_method = "exact"))
  expect_length(form_problems(fields, values), 0)
  spec <- engine_function("validate_spec")(build_spec(forms, "E2", fields, values))
  expect_null(spec$population$raw$sd)
  expect_equal(spec$population$raw$sd1, 5)
  expect_equal(spec$population$raw$sd2, 15)
  expect_equal(spec$population$d, 4 / sqrt(125))
  result <- engine_function("run_spec")(spec)
  words <- writeup_text(forms$forms$E2, spec, result, fields, values)
  expect_true(all(grepl("3 times", words[c("short", "full")], fixed = TRUE)))
})
