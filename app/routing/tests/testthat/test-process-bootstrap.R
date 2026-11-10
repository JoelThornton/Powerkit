test_that("each mediation card exposes the analysis and resample settings in one place", {
  for (ep in c("E10", "E16", "E11", "E12", "E13", "E14", "E17", "E38", "E40")) {
    groups <- form_groups(forms, ep)
    fields <- form_fields(groups)
    method <- Filter(function(f) identical(f$id, "method"), fields)
    expect_length(method, 1)
    expect_setequal(names(method[[1]]$choices), c("monte_carlo_ci", "percentile_bootstrap", "ols_percentile_bootstrap"))
    expect_equal(sum(vapply(fields, function(f) identical(f$id, "ci_draws"), logical(1))), 1)
    group <- Filter(function(g) identical(g$title, "Which mediation analysis will you run?"), groups)[[1]]
    expect_identical(form_section(group), "study")
    values <- modifyList(form_examples[[ep]], list(method = "ols_percentile_bootstrap", ci_draws = 5000))
    spec <- build_spec(forms, ep, fields, values)
    expect_identical(spec$target_test$method, "ols_percentile_bootstrap")
    expect_equal(spec$options$ci_draws, 5000)
    expect_false(any(c("6", "7") %in% names(departures_for(forms, ep, spec))))
    expect_false("14" %in% known_difference_keys(forms, ep, spec))
    route <- project_route(list(endpoint = ep), values)
    restored <- restore_from_project(route, tree, forms)
    expect_identical(build_spec(forms, ep, fields, restored$form_values)$target_test$method, "ols_percentile_bootstrap")
  }
})

test_that("the result identifies OLS/bootstrap without claiming every PROCESS option is matched", {
  result <- list(mediation_analysis = list(estimator = "ordinary least squares",
    interval = "percentile bootstrap", draws = 5000, process_style = TRUE))
  text <- mediation_analysis_sentence(result)
  expect_match(text, "ordinary least squares", fixed = TRUE)
  expect_match(text, "5,000 whole-observation bootstrap resamples", fixed = TRUE)
  expect_match(text, "not PROCESS itself or all of its options", fixed = TRUE)
  expect_null(mediation_analysis_sentence(list()))
  spec <- list(design = "moderated_mediation", variables = list(X = list(type = "binary")),
    target_test = list(method = "ols_percentile_bootstrap"))
  expect_match(binary_x_modmed_note(spec), "not a calibration estimate for the selected bootstrap", fixed = TRUE)
})

test_that("bootstrap planning goes directly to the local script without a misleading preview", {
  fields <- form_fields(form_groups(forms, "E10"))
  spec <- build_spec(forms, "E10", fields, modifyList(form_examples$E10, list(method = "ols_percentile_bootstrap", goal = "power", n = 100)))
  expect_false(has_preview(forms, "E10", "power", spec))
  expect_false(full_run_in_app(forms, "E10", "power", spec))
  expect_match(script_run_time(forms, "E10", "power", spec), "potentially hours", fixed = TRUE)
  html <- as.character(no_preview_ui(forms, "E10", spec))
  expect_match(html, "5,000 whole-observation bootstrap resamples", fixed = TRUE)
  expect_match(html, "powerkit-result.powerkit.json", fixed = TRUE)
  spec$target_test$method <- "monte_carlo_ci"
  expect_true(has_preview(forms, "E10", "power", spec))
  expect_true(full_run_in_app(forms, "E10", "power", spec))
})
