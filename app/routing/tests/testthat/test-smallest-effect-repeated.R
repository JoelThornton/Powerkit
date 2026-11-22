# Repeated counts, yes/no answers and ratings (E75, through the R script)
# and Cochran's Q (E78, in the app): the smallest detectable effect.

test_that("repeated counts, yes/no answers and ratings offer the smallest effect through the R script, and Cochran's Q runs it here", {
  export <- engine_function("export_run_script")
  fields <- form_fields(form_groups(forms, "E75"))
  goal <- Filter(function(f) identical(f$id, "goal"), fields)[[1]]
  expect_true("sensitivity" %in% names(goal$choices))
  values <- smallest_effect_values("E75", list(n = "40"))
  expect_length(form_problems(fields, values), 0)
  spec <- build_spec(forms, "E75", fields, values)
  spec$options$seed <- 3L
  expect_true(runs_long(forms, "E75", spec))
  expect_false(has_preview(forms, "E75", "sensitivity", spec))
  expect_match(script_run_time(forms, "E75", "sensitivity", spec), "sizes of the effect are simulated", fixed = TRUE)
  file <- withr::local_tempfile(fileext = ".R")
  export(spec, file)
  expect_true(any(grepl("sensitivity", readLines(file), fixed = TRUE)))
  # Cochran's Q runs in the app, on its own card.
  run <- smallest_effect_run("E78", list(n = "60", simulation_accuracy = "quick"))
  expect_true(isTRUE(run$result$sensitivity$simulated))
  expect_identical(result_figure(run$spec, run$result)$label, "the smallest odds ratio you could detect")
  expect_false(is.na(usual_seconds(forms, "E78", "sensitivity")))
})
