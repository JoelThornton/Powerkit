# The ANCOVA's covariates (E23, 17 November 2026): measured on each person
# (Shieh's method) or set by the design (fixed, as G*Power). The researcher
# says which; neither is preselected.

test_that("the covariate question is asked with no answer chosen in advance", {
  fields <- form_fields(form_groups(forms, "E23"))
  field <- Filter(function(f) identical(f$id, "covariate_model"), fields)[[1]]
  expect_setequal(names(field$choices), c("random", "fixed"))
  expect_null(field$default)
  expect_true(isTRUE(field$required))
  expect_setequal(names(field$choice_notes), c("random", "fixed"))
  expect_true(field_applies(field, list(test_version = "ancova_f", metric = "raw")))
  expect_false(field_applies(field, list(test_version = "bayes_factor", metric = "raw")))
  expect_false(field_applies(field, list(test_version = "ancova_f", metric = "eta_squared")))
})

test_that("fixed covariates reach the spec, name the test and drop the Shieh difference", {
  fields <- form_fields(form_groups(forms, "E23"))
  values <- modifyList(form_examples$E23, list(goal = "power", n = "90", covariate_model = "fixed"))
  spec <- build_spec(forms, "E23", fields, values)
  expect_identical(spec$target_test$covariate_model, "fixed")
  expect_true(is_fixed_ancova(spec))
  expect_false("15" %in% known_difference_keys(forms, "E23", spec))
  measured <- build_spec(forms, "E23", fields, modifyList(values, list(covariate_model = "random")))
  expect_false(is_fixed_ancova(measured))
  expect_true("15" %in% known_difference_keys(forms, "E23", measured))
  # An effect given as partial eta-squared is planned with fixed covariates.
  eta <- measured
  eta$target_test$covariate_model <- NULL
  eta$population <- list(metric = "eta_squared", eta_squared = 0.06, covariates = 1L)
  expect_true(is_fixed_ancova(eta))
})
