test_that("precision's estimate selector stays visible before conditional study inputs", {
  groups <- form_groups(forms, "E46")
  selector <- Filter(function(g) "estimate" %in% vapply(g$fields, `[[`, "", "id"), groups)
  expect_length(selector, 1)
  expect_identical(form_section(selector[[1]]), "study")
  sections <- vapply(groups, form_section, "")
  hidden_ids <- vapply(form_fields(groups[sections == "settings"]), `[[`, "", "id")
  expect_false("estimate" %in% hidden_ids)
  aim <- Filter(function(q) identical(q$id, "aim"), tree$start_questions)[[1]]
  expect_identical(aim$options$estimate$next, "E46")
})

test_that("simulation choices disclose supported populations and Welch's current limit", {
  for (ep in paste0("E", 1:6)) {
    f <- basic_method_field(forms, ep)
    expect_match(f$help, "Selecting simulation does not add", fixed = TRUE)
    expect_identical(f$default, "exact")
    expect_false(isTRUE(f$required))
  }
  method <- Filter(function(f) identical(f$id, "method"), form_fields(forms$forms$E2$groups))[[1]]
  expect_match(method$choice_notes$welch_t, "equal population SDs", fixed = TRUE)
  expect_match(basic_method_field(forms, "E2")$help, "normal scores", fixed = TRUE)
})

test_that("all-tests guidance states dependence without promising conservative joint power", {
  values <- list(claim = "all", n_tests = "2", power = "0.8")
  note <- claim_result_note(values, 0.05, "sample_size")
  expect_match(note, "independent", fixed = TRUE)
  expect_match(note, "does not guarantee", fixed = TRUE)
  expect_match(claim_result_note(values, 0.05, "power"), "lower or higher", fixed = TRUE)
  expect_equal(claim_power(0.8, values)^2, 0.8)
})
