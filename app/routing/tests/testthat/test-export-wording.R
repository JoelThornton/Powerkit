# Wording of exported text: powerkit named as a prototype until 1.0, and
# effect-size labels written for a paper rather than for the input screen.

test_that("exports name powerkit as a prototype until version 1.0", {
  expect_match(powerkit_cited("0.36.0"), "powerkit (version 0.36.0, a prototype in development whose results are not yet fully validated)", fixed = TRUE)
  expect_identical(powerkit_cited("1.0.0"), "powerkit (version 1.0.0)")
  expect_match(powerkit_cited(NULL), "a prototype", fixed = TRUE)
})

test_that("write-up labels drop the screen's ranges and capitals", {
  expect_identical(writeup_field_label(list(label = "Correlation r (0 to 1)")), "correlation r")
  expect_identical(writeup_field_label(list(label = "Cohen's d")), "Cohen's d")
  expect_identical(writeup_field_label(list(label = "Odds ratio", writeup_label = "the odds ratio")), "the odds ratio")
})

test_that("the planning document's decision rule reads as a sentence", {
  rule <- decision_rule_text(list(design = "t_test", target_test = list(alpha = 0.05, alternative = "two_sided")))
  expect_match(rule, "^A significance test at alpha = 0.05, two-sided\\. ")
  expect_no_match(rule, " ;|two sided ;")
  expect_match(decision_rule_text(list(design = "t_test", target_test = list(alpha = 0.025, alternative = "greater"))), "one-sided (greater)", fixed = TRUE)
})

test_that("the planning document's evidence section is worded for a reader", {
  record <- list(format_version = 1, scope = "Two equal groups, d from 0.2 to 0.8.", record_id = "E2-student", registry_version = "2026-11-05.2",
    categories = list(package_agreement = list(status = "recorded", note = "pwr called directly."), independent = list(status = "not_linked")))
  lines <- evidence_reader_lines(record)
  expect_match(lines[1], "prototype until version 1.0", fixed = TRUE)
  expect_true(any(grepl("Agreement with other software: checked on the example cases recorded in the validation log. pwr called directly.", lines, fixed = TRUE)))
  expect_true(any(grepl("no record yet", lines, fixed = TRUE)))
  expect_no_match(paste(lines, collapse = " "), "SHA-256")
  expect_match(evidence_reader_lines(NULL), "No record", fixed = TRUE)
})

test_that("the methods paragraph names every value a reader needs to redo the plan", {
  # The planned contrast's weights, the reliability test's value to beat
  # and number of ratings, and the growth curve's occasions and
  # starting-level spread (project review of 7 November 2026).
  needs <- list(
    E19 = c("contrast weights = -3, -1, 1, 3"),
    E69 = c("ICC to beat = 0.6", "ratings of each person = 3"),
    E35 = c("occasions = 0, 1, 2, 3", "SD of people's starting levels = 6", "correlation of starting levels and rates of change = -0.2")
  )
  for (ep in names(needs)) {
    text <- writeup_effect(form_fields(form_groups(forms, ep)), form_examples[[ep]])
    for (value in needs[[ep]]) expect_match(text, value, fixed = TRUE, label = paste(ep, value))
  }
})
