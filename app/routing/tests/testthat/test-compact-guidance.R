test_that("routine guidance has named native info controls without wrapping the input", {
  f <- list(id = "power", label = "Target power", type = "number", help = "Power guidance.",
    usual = .8, shortcuts = c(.8, .9, .95))
  html <- as.character(field_ui(f, ""))
  expect_match(html, 'id="f_power_info"', fixed = TRUE)
  expect_match(html, 'aria-controls="f_power_info_body"', fixed = TRUE)
  expect_match(html, 'aria-label="Info: Target power"', fixed = TRUE)
  # One line in view, the rest behind the info button beside the label (D-11).
  expect_match(html, 'data-guidance-describedby="f_power_help_lead f_power_help"', fixed = TRUE)
  expect_match(html, 'class="field-help field-lead">Power guidance.', fixed = TRUE)
  expect_lt(regexpr('id="f_power-label"', html)[1], regexpr('id="f_power_info"', html)[1])
  expect_lt(regexpr('id="f_power_info"', html)[1], regexpr('id="f_power"', html)[1])
  for (value in c("0.8", "0.9", "0.95")) expect_match(html, paste0('data-value="', value, '"'), fixed = TRUE)
})

test_that("compact labels keep specialised success criteria and sample units intact", {
  expect_equal(compact_field_label(list(id = "power", label = "Target power")), "Power (1 - beta)")
  expect_null(compact_field_label(list(id = "power", label = "Target chance of recovering the factors")))
  expect_null(compact_field_label(list(id = "n", label = "Number of pairs")))
  expect_equal(compact_field_label(list(id = "welch_sd_ratio")), "SD ratio (group 2 / group 1)")
})

test_that("the result's concise test name follows the captured method", {
  fields <- form_fields(form_groups(forms, "E2"))
  spec <- build_spec(forms, "E2", fields, form_examples$E2)
  expect_equal(selected_method_label(spec, fields), "Welch's t-test")
  spec$target_test$method <- "student_t"
  expect_equal(selected_method_label(spec, fields), "Student's t-test")
  spec$target_test$method <- "not_a_method"
  expect_null(selected_method_label(spec, fields))
})
