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

test_that("the dependent correlations, variances, Hotelling and MANOVA cards find their effect (16 November 2026)", {
  cases <- list(
    E51 = list(extra = list(r_X_Z = ""), label = "second correlation"),
    E52 = list(extra = list(var = ""), label = "variance ratio"),
    E53 = list(extra = list(var1 = ""), label = "variance ratio"),
    E60 = list(extra = list(), label = "Mahalanobis distance"),
    E59 = list(extra = list(A_levels = "Control, Treatment", means = "20, 18, 22\n18, 16.5, 20"), label = "Mahalanobis distance")
  )
  for (ep in names(cases)) {
    goal <- Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, ep)))[[1]]
    expect_true("sensitivity" %in% names(goal$choices), info = ep)
    run <- smallest_effect_run(ep, cases[[ep]]$extra)
    expect_equal(run$result$sensitivity$power, 0.8, tolerance = 1e-6, label = ep)
    expect_match(result_figure(run$spec, run$result)$label, cases[[ep]]$label, fixed = TRUE, label = ep)
    expect_match(goal_sentences(run$spec, run$result)[["headline"]], cases[[ep]]$label, fixed = TRUE, label = ep)
  }
  # A one-sided test for a smaller variance: the ratio below 1 isn't "the smallest".
  run <- smallest_effect_run("E52", list(var = ""))
  expect_lt(run$result$sensitivity$effect, 1)
  expect_identical(result_figure(run$spec, run$result)$label, "the variance ratio you could detect")
  # MANOVA's smallest effect is offered with the MANOVA test, not PERMANOVA.
  goal <- Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, "E59")))[[1]]
  expect_false(field_applies(list(shown_if = goal$choices_shown_if$sensitivity), list(manova_test = "permanova")))
})

test_that("an equivalence test gives the narrowest bounds it could show, and the bound is not asked for", {
  fields <- form_fields(form_groups(forms, "E36"))
  bound <- Filter(function(f) identical(f$id, "bound"), fields)[[1]]
  expect_false(field_applies(bound, list(goal = "sensitivity", effect_units = "standardised", comparison = "tost_independent")))
  expect_true(field_applies(bound, list(goal = "power", effect_units = "standardised", comparison = "tost_independent")))
  run <- smallest_effect_run("E36", list(bound = ""))
  s <- run$result$sensitivity
  expect_identical(s$effect_name, "bound")
  expect_equal(s$power, 0.8, tolerance = 1e-6)
  figure <- result_figure(run$spec, run$result)
  expect_identical(figure$label, "the narrowest equivalence bounds you could show")
  expect_match(figure$value, "^±")
  lines <- goal_sentences(run$spec, run$result)
  expect_match(lines[["headline"]], "narrowest equivalence bounds you could show", fixed = TRUE)
  expect_no_match(lines[["headline"]], "smallest effect", fixed = TRUE)
  # In the measure's own units, the bounds are given in those units.
  run <- smallest_effect_run("E36", list(effect_units = "raw", raw_bound = "", raw_mean_1 = "50", raw_mean_2 = "51", raw_sd = "10"))
  expect_match(units_sentence(run$result) %||% "", "bounds of ±", fixed = TRUE)
})
