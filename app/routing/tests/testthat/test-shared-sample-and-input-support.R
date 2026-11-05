test_that("result, plan and recruitment counts preserve their actual units", {
  result <- list(goal_type = "sample_size", n_required = list(n = 40),
    recruitment = list(n_analysed = 40, n_recruit = 50, attrition = 0.2,
      groups_analysed = numeric(), groups_recruit = numeric(), unit = NA_character_))
  expect_equal(plan_n(result), n_analysed(result))
  spec <- list(design = "dyadic", template = "apim", variables = list(), population = list(), options = list())
  expect_match(recruitment_lines(result, spec)[["analysed"]], "40 pairs", fixed = TRUE)
  expect_match(recruitment_lines(result, spec)[["recruit"]], "50 pairs", fixed = TRUE)
  expect_match(recruitment_lines(result)[["analysed"]], "analysis units", fixed = TRUE)
  result$goal_type <- "power"
  result$n_required <- NA
  result$curve <- data.frame(n = 120, power = 0.8)
  expect_equal(n_analysed(result), 120)
  expect_null(plan_n(result))
})

test_that("input support exposes matching existing translations without invented numbers", {
  for (id in names(forms$forms)) {
    fields <- form_fields(form_groups(forms, id))
    html <- as.character(input_support_ui(forms$forms[[id]], fields))
    expect_match(html, "save an unfinished draft", fixed = TRUE, info = id)
    expect_match(html, "cannot always be converted uniquely", fixed = TRUE, info = id)
  }
  paired <- as.character(input_support_ui(forms$forms$E3, form_fields(form_groups(forms, "E3"))))
  expect_match(paired, "SD of changes", fixed = TRUE)
  expect_match(paired, "smallest effect you could detect", fixed = TRUE)
})
