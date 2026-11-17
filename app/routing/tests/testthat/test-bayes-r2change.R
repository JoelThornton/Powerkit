# E24's Bayes factor for an R-squared increase and for one coefficient:
# the input screen asks for what the engine needs and nothing it refuses.

e24_bayes_values <- function(question) {
  v <- modifyList(form_examples$E24, list(question = question, goal = "power", n = "150", alpha = NULL,
    evidence_threshold = "10", prior_scale = "0.354"))
  if (question == "r2_increase") {
    modifyList(v, list(r2c_test = "bayes_factor", r2_full = "0.15", r2_reduced = "0.08", predictors_total = "5", predictors_tested = "2"))
  } else {
    modifyList(v, list(coef_test = "bayes_factor", X_label = "Stress", partial_r2 = "0.05", r2_reduced = "0.1", predictors_total = "4"))
  }
}

test_that("the Bayes factor hides alpha and the robust-test inputs, and asks for R-squared without the predictor", {
  fields <- form_fields(form_groups(forms, "E24"))
  field <- function(id) Filter(function(f) identical(f$id, id), fields)[[1]]
  for (question in c("r2_increase", "single_coefficient")) {
    v <- e24_bayes_values(question)
    expect_false(field_applies(field("alpha"), v), info = question)
    expect_true(field_applies(field("evidence_threshold"), v), info = question)
    expect_true(field_applies(field("prior_scale"), v), info = question)
    expect_true(field_applies(field("r2_reduced"), v), info = question)
    expect_length(form_problems(fields, v), 0)
    spec <- build_spec(forms, "E24", fields, v)
    expect_identical(spec$target_test$method, "bayes_factor")
    expect_null(spec$target_test$alpha)
    expect_s3_class(powerkit::validate_spec(spec), "powerkit_spec")
  }
  v <- e24_bayes_values("single_coefficient")
  expect_false(field_applies(field("variance_ratio"), v))
  expect_false(field_applies(field("error_shape"), v))
  # The usual tests keep alpha, and R-squared without the predictor stays
  # off the coefficient's screen.
  v$coef_test <- "f_test"
  expect_true(field_applies(field("alpha"), v))
  expect_false(field_applies(field("r2_reduced"), v))
  v <- e24_bayes_values("r2_increase")
  v$r2c_test <- "f_test"
  expect_true(field_applies(field("alpha"), v))
  expect_false(field_applies(field("evidence_threshold"), v))
})

test_that("the smallest detectable effect isn't offered with these Bayes factors", {
  goal <- Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, "E24")))[[1]]
  sens <- list(shown_if = goal$choices_shown_if$sensitivity)
  expect_false(field_applies(sens, e24_bayes_values("r2_increase")))
  expect_false(field_applies(sens, e24_bayes_values("single_coefficient")))
  expect_true(field_applies(sens, modifyList(e24_bayes_values("r2_increase"), list(r2c_test = "f_test"))))
})

test_that("the result names the comparison and the planning line speaks of evidence", {
  fields <- form_fields(form_groups(forms, "E24"))
  v <- e24_bayes_values("r2_increase")
  spec <- build_spec(forms, "E24", fields, v)
  spec$options$nrep <- 200L
  result <- powerkit::run_spec(spec)
  html <- as.character(result_panel_ui(tree, forms, "E24", fields, v, list(status = "ok", spec = spec, result = result)))
  expect_match(html, "a Bayes factor test of an R-squared increase", fixed = TRUE)
  text <- writeup_text(forms$forms$E24, spec, result, fields, v)
  expect_match(text[["full"]], "model without the tested predictors", fixed = TRUE)
  planning <- as.character(planning_decision_ui(forms$forms$E24))
  expect_match(planning, "r2c_test", fixed = TRUE)
  expect_match(planning, "coef_test", fixed = TRUE)
})
