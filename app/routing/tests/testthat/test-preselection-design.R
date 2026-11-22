# Questions about the study, and levels that work like alpha, start
# unanswered (22 November 2026): clicking through can't plan a different
# study, and no conventional level is chosen for the researcher.

design_questions <- list(
  E59 = c("manova_effect", "manova_factors"), E41 = c("two_level_effect", "two_outcome"),
  E62 = c("two_level_effect", "three_level_effect", "two_outcome", "in_sites"),
  E44 = c("apim_effect", "apim_effect_d", "apim_effect_w", "apim_effect_dw", "distinguishable"),
  E33 = c("crossed_participants", "item_design", "outcome_type"), E63 = c("crossed_participants", "item_design", "outcome_type"),
  E67 = c("outcome_type", "x_level"), E68 = c("three_outcome", "three_assignment"),
  E75 = c("glmm_outcome", "glmm_groups", "glmm_people"), E11 = "x_type", E12 = "x_type",
  E40 = c("x_type", "w_type", "stage"), E17 = c("w_type", "modmed_stage"), E39 = c("binm_x", "binm_m", "binm_y"),
  E38 = "modmed_model", E23 = "factors", E61 = "meta_question", E32 = c("analysis", "Y_kind"),
  E34 = c("outcome_type", "adjust_baseline"), E46 = "estimate", E77 = c("purpose", "outcome"), E50 = "generic_test",
  E37 = c("over", "mi_groups", "mi_occasions", "mi_factors"))

test_that("questions that describe the study start unanswered and must be answered", {
  for (ep in names(design_questions)) {
    fields <- form_fields(form_groups(forms, ep))
    for (id in design_questions[[ep]]) {
      f <- Filter(function(f) identical(f$id, id), fields)
      expect_length(f, 1)
      expect_null(f[[1]][["default"]], label = paste(ep, id))
      expect_true(isTRUE(f[[1]]$required), label = paste(ep, id))
    }
  }
})

test_that("levels like alpha start empty, with the usual value one click away", {
  level <- Filter(function(f) identical(f$id, "conf_level"), form_fields(form_groups(forms, "E46")))[[1]]
  expect_null(level[["default"]])
  html <- as.character(field_ui(level, NULL))
  expect_match(html, 'data-value="0.95"', fixed = TRUE)
  expect_match(html, "Use 0.95, the usual level", fixed = TRUE)
  for (x in list(c("E73", "congruence"), c("E73", "factor_correlation"), c("E37", "predictor_correlation"))) {
    f <- Filter(function(f) identical(f$id, x[2]), form_fields(form_groups(forms, x[1])))[[1]]
    expect_null(f[["default"]], label = x[2])
    expect_true(isTRUE(f$required), label = x[2])
    expect_true(length(f$shortcuts %||% f$usual) > 0, label = x[2])
  }
})

test_that("the whole-study screen takes the plan's significance level, or none", {
  expect_identical(whole_study_plan_alpha(list(a = list(alpha = "0.01"), b = list(alpha = "0.01"))), "0.01")
  expect_null(whole_study_plan_alpha(list(a = list(alpha = "0.01"), b = list(alpha = "0.05"))))
  expect_null(whole_study_plan_alpha(list()))
  html <- as.character(whole_study_alpha_field(""))
  expect_match(html, 'id="ws_alpha" type="text" class="shiny-input-text form-control" value=""', fixed = TRUE)
  expect_match(html, "Use 0.05, the usual level", fixed = TRUE)
})

test_that("the whole-study variables start unanswered unless the screening left one", {
  html <- as.character(guided_variables_ui(tree, list(), list()))
  expect_false(grepl('checked="checked"', html, fixed = TRUE))
  expect_match(html, "Answer each question above", fixed = TRUE)
})

test_that("the replication planner lists the settings still to choose", {
  base <- list(rep_design = "two_groups", rep_analysis = "test", rep_purpose = "confirm", rep_alpha = "0.05", rep_power = "0.8")
  missing <- replication_settings_missing(base)
  expect_true(any(grepl("two-sided or one-sided", missing, fixed = TRUE)))
  expect_true(any(grepl("vary between studies", missing, fixed = TRUE)))
  done <- replication_settings_missing(c(base, list(rep_sided = "two.sided", rep_tau = "0")))
  expect_false(any(grepl("two-sided or one-sided|vary between studies", done)))
})

test_that("the Tools planners start without an effect or target filled in", {
  html <- as.character(bayes_ui())
  expect_false(grepl('id="bayes_effect" type="number" class="shiny-input-number form-control" value="0.5"', html, fixed = TRUE))
  expect_false(grepl('name="bayes_threshold" value="10" checked', html, fixed = TRUE))
})
