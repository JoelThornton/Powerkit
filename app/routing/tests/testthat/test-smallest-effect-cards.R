# The smallest detectable effect on the formula cards that gained it on
# 16 November 2026 (engine: sensitivity-pwrss.R). Each card offers the goal,
# runs it from its screen with the effect left empty where it may be, and
# words the answer with the effect's own name.

smallest_effect_values <- function(ep, extra = list()) {
  values <- modifyList(form_examples[[ep]], list(goal = "sensitivity", n = "120", power = "0.8", alpha = "0.05"))
  modifyList(values, extra)
}

smallest_effect_run <- function(ep, extra = list()) {
  fields <- form_fields(form_groups(forms, ep))
  values <- smallest_effect_values(ep, extra)
  problems <- form_problems(fields, values)
  expect_length(problems, 0)
  spec <- build_spec(forms, ep, fields, values)
  calc <- run_calculation(spec, seed = forms$default_seed)
  expect_identical(calc$status, "ok", label = ep)
  list(spec = spec, result = calc$result, values = values, fields = fields)
}

test_that("the formula cards offer the smallest detectable effect, at one sample size and across a range", {
  for (ep in c("E19", "E23", "E24", "E25", "E26", "E27", "E28", "E48", "E49")) {
    goal <- Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, ep)))[[1]]
    expect_true("sensitivity" %in% names(goal$choices), info = ep)
  }
  goal <- Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, "E27")))[[1]]
  expect_true("sensitivity_curve" %in% names(goal$choices))
})

test_that("each card runs the goal with the effect left empty where it may be, and names the effect", {
  cases <- list(
    E24 = list(extra = list(r2_full = ""), label = "partial R-squared"),
    E25 = list(extra = list(p = ""), label = "proportion"),
    E26 = list(extra = list(p_second_only = ""), label = "proportion changing only in the second condition"),
    E27 = list(extra = list(odds_ratio = ""), label = "odds ratio"),
    E28 = list(extra = list(), label = "rate ratio"),
    E48 = list(extra = list(), label = "w"),
    E49 = list(extra = list(r2 = ""), label = "group 2's correlation"),
    E19 = list(extra = list(), label = "contrast"),
    E23 = list(extra = list(), label = "difference between the largest and smallest mean")
  )
  for (ep in names(cases)) {
    run <- smallest_effect_run(ep, cases[[ep]]$extra)
    s <- run$result$sensitivity
    expect_equal(s$power, 0.8, tolerance = 1e-6, label = ep)
    figure <- result_figure(run$spec, run$result)
    expect_match(figure$label, cases[[ep]]$label, fixed = TRUE, label = ep)
    lines <- goal_sentences(run$spec, run$result)
    expect_match(lines[["headline"]], cases[[ep]]$label, fixed = TRUE, label = ep)
    expect_no_match(lines[["headline"]], "_", fixed = TRUE)
  }
})

test_that("a ratio below 1, or a proportion to reach, is not called the smallest", {
  run <- smallest_effect_run("E28")
  expect_lt(run$result$sensitivity$effect, 1)
  expect_identical(result_figure(run$spec, run$result)$label, "the rate ratio you could detect")
  run <- smallest_effect_run("E25", list(p = ""))
  expect_identical(result_figure(run$spec, run$result)$label, "the proportion you could detect")
})

test_that("test versions without the goal don't offer it", {
  goal_of <- function(ep) Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, ep)))[[1]]
  e24 <- goal_of("E24")
  expect_false(field_applies(list(shown_if = e24$choices_shown_if$sensitivity),
    list(question = "r2_zero", r2_test = "bayes_factor")))
  expect_true(field_applies(list(shown_if = e24$choices_shown_if$sensitivity),
    list(question = "r2_zero", r2_test = "f_test")))
  expect_false(field_applies(list(shown_if = e24$choices_shown_if$sensitivity),
    list(question = "single_coefficient", coef_test = "ols_hc3")))
  expect_true(field_applies(list(shown_if = e24$choices_shown_if$sensitivity_curve),
    list(question = "r2_increase")))
  expect_false(field_applies(list(shown_if = goal_of("E28")$choices_shown_if$sensitivity), list(count_model = "negative_binomial")))
  expect_false(field_applies(list(shown_if = goal_of("E25")$choices_shown_if$sensitivity), list(method = "bayes_factor")))
  expect_false(field_applies(list(shown_if = goal_of("E23")$choices_shown_if$sensitivity), list(test_version = "bayes_factor")))
})

test_that("an ANOVA given by partial eta-squared finds the smallest partial eta-squared", {
  run <- smallest_effect_run("E18", list(metric = "eta_squared", eta_squared = "0.06", means = "", sd = ""))
  expect_identical(run$result$sensitivity$effect_name, "eta_squared")
  expect_match(result_figure(run$spec, run$result)$label, "partial eta-squared", fixed = TRUE)
})
