# McNemar's chi-square test on E26 and Levene's and the Brown-Forsythe test
# on E53 (17 November 2026, next.md item 27): the researcher chooses the
# test they will run, and the choice reaches the spec and the write-up.

run <- engine_function("run_spec", file.path(repo_dir, "engine"))
skip_without_run <- function() {
  if (is.null(run) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(run), "powerkit's engine isn't available here")
}

# The write-up of a quick run (200 simulated studies).
quick_writeup <- function(ep, fields, values) {
  spec <- build_spec(forms, ep, fields, values)
  spec$options$nrep <- 200L
  calc <- run_calculation(spec, run, seed = 1L)
  expect_identical(calc$status, "ok")
  paste(writeup_text(forms$forms[[ep]], calc$spec, calc$result, fields, values), collapse = " ")
}

field_named <- function(card, id) {
  Filter(function(f) identical(f$id, id), form_fields(form_groups(forms, card)))[[1]]
}

test_that("E26 asks which McNemar test, and the choice reaches the spec and the write-up", {
  field <- field_named("E26", "method")
  expect_setequal(names(field$choices), c("mcnemar_exact", "mcnemar_chisq", "mcnemar_chisq_corrected"))
  expect_setequal(names(field$choice_notes), names(field$choices))
  fields <- form_fields(form_groups(forms, "E26"))
  values <- modifyList(form_examples$E26, list(goal = "power", n = "120", just_source = "A pilot study.", method = "mcnemar_chisq_corrected"))
  spec <- build_spec(forms, "E26", fields, values)
  expect_identical(spec$target_test$method, "mcnemar_chisq_corrected")
  # Known Difference 2 describes the exact test only.
  expect_false("2" %in% known_difference_keys(forms, "E26", spec))
  exact <- build_spec(forms, "E26", fields, modifyList(values, list(method = "mcnemar_exact")))
  expect_true("2" %in% known_difference_keys(forms, "E26", exact))
  skip_without_run()
  expect_match(quick_writeup("E26", fields, values), "McNemar's chi-square test with the continuity correction", fixed = TRUE)
})

test_that("E53 asks which variance test, and the score shape only for Levene's and the Brown-Forsythe test", {
  method <- field_named("E53", "method")
  expect_setequal(names(method$choices), c("f_var", "levene", "brown_forsythe"))
  shape <- field_named("E53", "score_shape")
  expect_false(field_applies(shape, list(method = "f_var")))
  expect_true(field_applies(shape, list(method = "brown_forsythe")))
  fields <- form_fields(form_groups(forms, "E53"))
  values <- modifyList(form_examples$E53, list(goal = "power", n = "200", just_source = "A pilot study.", method = "brown_forsythe", score_shape = "heavy_tailed"))
  spec <- build_spec(forms, "E53", fields, values)
  expect_identical(spec$target_test$method, "brown_forsythe")
  expect_identical(spec$population$score_shape, "heavy_tailed")
  f_test <- build_spec(forms, "E53", fields, modifyList(values, list(method = "f_var")))
  expect_null(f_test$population$score_shape)
  skip_without_run()
  expect_match(quick_writeup("E53", fields, values), "the Brown-Forsythe test of two variances", fixed = TRUE)
})
