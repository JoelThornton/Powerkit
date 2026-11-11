test_that("interaction input routes explain their different calculations before results", {
  fields <- form_fields(form_groups(forms, "E9"))
  method <- Filter(function(f) identical(f$id, "interaction_metric"), fields)[[1]]
  expect_match(method$choice_notes$r2_change, "fixed-model regression formula", fixed = TRUE)
  expect_match(method$choice_notes$correlation, "formula approximation", fixed = TRUE)
  expect_match(forms$known_differences[["1"]], "not a universal error bound or a direct G*Power comparison", fixed = TRUE)
  expect_false(grepl("3%", forms$known_differences[["1"]], fixed = TRUE))
  student <- Filter(function(f) identical(f$id, "method"), form_fields(form_groups(forms, "E2")))[[1]]
  expect_match(student$choice_notes$student_t, "even when group sizes are equal", fixed = TRUE)
  expect_false(grepl("need the same number", student$choice_notes$student_t, fixed = TRUE))
})

test_that("family planning reports this test's power and the conditions for joint claims", {
  values <- list(claim = "any", n_tests = "3", goal = "sample_size", power = "0.8")
  spec <- list(target_test = list(alpha = .05 / 3), goal = list(power = .8))
  expect_match(writeup_claim(values, spec), "not the probability that any test in the set succeeds", fixed = TRUE)
  expect_match(claim_result_note(values, .05 / 3), "not the chance that any test in the set succeeds", fixed = TRUE)
  values$claim <- "all"
  spec$goal$power <- claim_power(.8, values)
  expect_equal(spec$goal$power, .8^(1/3))
  text <- writeup_claim(values, spec)
  expect_match(text, "this test was planned", fixed = TRUE)
  expect_match(text, "every required test reaches at least that power under the same population", fixed = TRUE)
  expect_match(text, "does not verify those conditions for the other tests", fixed = TRUE)
  expect_match(claim_result_note(values, .05, "sample_size"), "their significance decisions are independent", fixed = TRUE)
  expect_match(claim_notes()$each, "does not control the chance of any false positive", fixed = TRUE)
})
