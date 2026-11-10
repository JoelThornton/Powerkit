test_that("count forms expose the corrected analysis and preserve uncorrected defaults", {
  for (ep in c("E5", "E6")) {
    fields <- form_fields(form_groups(forms, ep))
    method <- Filter(function(f) identical(f$id, "method"), fields)[[1]]
    corrected <- if (ep == "E5") "z_test_corrected" else "pearson_chi_square_corrected"
    expect_true(corrected %in% names(method$choices))
    expect_false(identical(method$default, corrected))
    expect_match(method$choices[[method$default]], "without continuity correction", fixed = TRUE)
    inputs <- modifyList(form_examples[[ep]], list(method = corrected, goal = "power", n = 340))
    if (ep == "E6") inputs <- modifyList(inputs, list(X_levels = "A, B", Y_levels = "No, Yes", probabilities = "0.25, 0.25\n0.175, 0.325"))
    spec <- build_spec(forms, ep, fields, inputs)
    expect_equal(spec$target_test$method, corrected)
    expect_null(spec$options$proportions_formula)
    expect_null(spec$options$method)
    expect_s3_class(powerkit::validate_spec(spec), "powerkit_spec")
    expect_match(count_test_sentence(spec), "continuity correction", fixed = TRUE)
    expect_false(any(grepl("no continuity correction", departures_for(forms, ep, spec), fixed = TRUE)))
    accuracy <- Filter(function(f) identical(f$id, "simulation_accuracy"), fields)[[1]]
    expect_true(field_applies(accuracy, inputs))
  }
})

test_that("count-test identity is explicit and larger tables have no spurious correction departure", {
  spec <- list(design = "basic_test", template = "two_proportions", target_test = list(method = "z_test"))
  expect_match(count_test_sentence(spec), "without continuity correction", fixed = TRUE)
  spec$template <- "chi_square_independence"
  spec$target_test$method <- "pearson_chi_square"
  spec$variables <- list(X = list(levels = letters[1:3]), Y = list(levels = letters[1:2]))
  expect_false(any(grepl("continuity", departures_for(forms, "E6", spec), fixed = TRUE)))
  expect_null(count_test_sentence(list(design = "mediation")))
})
