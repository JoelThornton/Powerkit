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
  lines <- result_sentences(run$spec, run$result)
  expect_match(lines[["headline"]], "narrowest equivalence bounds you could show", fixed = TRUE)
  expect_no_match(lines[["headline"]], "smallest effect", fixed = TRUE)
  # In the measure's own units, the bounds are given in those units.
  run <- smallest_effect_run("E36", list(effect_units = "raw", raw_bound = "", raw_mean_1 = "50", raw_mean_2 = "51", raw_sd = "10"))
  expect_match(units_sentence(run$result) %||% "", "bounds of ±", fixed = TRUE)
})

test_that("a meta-analysis gives the smallest average effect its number of studies could detect", {
  goal <- Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, "E61")))[[1]]
  expect_match(goal$choices$sensitivity, "number of studies", fixed = TRUE)
  expect_false(field_applies(list(shown_if = goal$choices_shown_if$sensitivity), list(meta_question = "subgroups")))
  for (test in c("z", "hartung_knapp")) {
    fields <- form_fields(form_groups(forms, "E61"))
    values <- modifyList(form_examples$E61, list(goal = "sensitivity", n = "20", power = "0.8", alpha = "0.05", meta_effect = "", meta_test = test))
    expect_length(form_problems(fields, values), 0)
    spec <- build_spec(forms, "E61", fields, values)
    calc <- run_calculation(spec, seed = forms$default_seed)
    expect_identical(calc$status, "ok")
    figure <- result_figure(calc$spec, calc$result)
    expect_match(figure$label, "average effect", fixed = TRUE)
    expect_match(figure$sub, "20 studies", fixed = TRUE)
    lines <- result_sentences(calc$spec, calc$result)
    expect_match(lines[["headline"]], "With 20 studies, the smallest average effect", fixed = TRUE)
    expect_no_match(lines[["headline"]], "participants in total", fixed = TRUE)
  }
})

test_that("a structural equation model gives the smallest misfit, factor correlation or latent slope its sample could detect", {
  goal <- Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, "E37")))[[1]]
  expect_false(field_applies(list(shown_if = goal$choices_shown_if$sensitivity), list(question = "invariance")))
  expect_true(field_applies(list(shown_if = goal$choices_shown_if$sensitivity), list(question = "model_fit")))
  # The RMSEA may stay empty: the search sets it.
  fits <- list(
    chi_square_exact_fit = list(n = "200", label = "the smallest RMSEA you could detect", headline = "the smallest misfit that the chi-square test of exact model fit"),
    chi_square_close_fit = list(n = "200", label = "the smallest RMSEA you could detect", headline = "the smallest RMSEA that the test of close fit"),
    chi_square_not_close_fit = list(n = "600", label = "the largest RMSEA you could show to fit closely", headline = "would show close fit with 80% power if the model's RMSEA in the population is")
  )
  for (fit in names(fits)) {
    extra <- list(n = fits[[fit]]$n, question = "model_fit", fit_test = fit, rmsea = "",
      rmsea_null = if (fit == "chi_square_exact_fit") "" else "0.05")
    run <- smallest_effect_run("E37", extra)
    expect_null(run$spec$population[["rmsea"]], label = fit)
    expect_identical(result_figure(run$spec, run$result)$label, fits[[fit]]$label)
    lines <- result_sentences(run$spec, run$result)
    expect_match(lines[["headline"]], fits[[fit]]$headline, fixed = TRUE)
    expect_no_match(paste(lines, collapse = " "), "NULL", fixed = TRUE)
    methods <- writeup_text(forms$forms$E37, run$spec, run$result, run$fields, run$values)[["short"]]
    # The test chosen is named, and the RMSEA found is stated once.
    expect_match(methods, if (fit == "chi_square_exact_fit") "exact model fit" else if (fit == "chi_square_close_fit") "test of close fit" else "test of not-close fit", fixed = TRUE)
    expect_no_match(methods, "misfit to detect was|assumed a population RMSEA")
  }
  # A factor correlation and a latent slope: the value tested is searched,
  # so the model described leaves it out.
  for (question in c("factor_correlation", "latent_regression")) {
    example <- sem_examples[[question]]
    run <- smallest_effect_run("E37", c(example[setdiff(names(example), names(closing_ok))], list(n = "200")))
    figure <- result_figure(run$spec, run$result)
    expect_match(figure$label, if (question == "factor_correlation") "smallest factor correlation" else "smallest standardised slope", fixed = TRUE)
    lines <- result_sentences(run$spec, run$result)
    expect_no_match(lines[["detail"]], if (question == "factor_correlation") "correlating 0.2" else "slopes 0.2, 0.3", fixed = TRUE)
  }
})

test_that("ordinal two groups, survival, growth curves and reliability give the smallest effect with the effect left empty", {
  cases <- list(
    list(ep = "E29", extra = list(odds_ratio = ""), label = "the smallest odds ratio you could detect"),
    list(ep = "E43", extra = list(p_event2 = ""), label = "group 2's proportion with the event you could detect"),
    list(ep = "E43", extra = list(question = "cox_predictor", hazard_ratio = "", event_proportion = "0.3", r2_other = "0.1", X_level1 = "", X_level2 = ""),
      label = "the smallest hazard ratio you could detect"),
    list(ep = "E35", extra = list(slope_difference = ""), label = "the smallest difference in rates of change you could detect"),
    list(ep = "E69", extra = list(icc = ""), label = "the smallest ICC you could show is above 0.6"),
    list(ep = "E69", extra = list(question = "cronbach_alpha", reliability = "", reliability_null = "0.7", items = "5"),
      label = "the smallest Cronbach's alpha you could show is above 0.7"),
    list(ep = "E69", extra = list(question = "kappa", kappa = "", kappa_null = "0.4", Y_levels = "Yes, No", proportions = "0.7, 0.3", kappa_raters = "2"),
      label = "the smallest kappa you could show is above 0.4")
  )
  for (case in cases) {
    run <- smallest_effect_run(case$ep, c(case$extra, list(n = "150")))
    expect_identical(result_figure(run$spec, run$result)$label, case$label)
    methods <- writeup_text(forms$forms[[case$ep]], run$spec, run$result, run$fields, run$values)[["short"]]
    # The effect is what was found, so the write-up doesn't call what was
    # entered the effect size.
    expect_no_match(methods, "The effect size, ", fixed = TRUE)
  }
  lines <- result_sentences(run$spec, run$result)
  expect_match(lines[["headline"]], "would show the kappa is above 0.4 with 80% power if it is", fixed = TRUE)
  # Bland-Altman limits of agreement are simulated: no goal yet.
  goal <- Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, "E69")))[[1]]
  expect_false(field_applies(list(shown_if = goal$choices_shown_if$sensitivity), list(question = "bland_altman")))
})

test_that("paired variances, the trend tests, d', factorial logistic regression and moderation by groups find the smallest effect by a simulated search", {
  cases <- list(
    list(ep = "E57", extra = list(var1 = ""), label = "the smallest variance ratio you could detect", name = "variance ratio = "),
    list(ep = "E66", extra = list(), label = "the smallest difference between the highest and lowest proportions you could detect",
      name = "difference between the highest and lowest proportions = "),
    list(ep = "E72", extra = list(d2 = ""), label = "the smallest difference in d' you could detect", name = "difference in d' = "),
    list(ep = "E64", extra = list(), label = "the smallest difference between the largest and smallest mean you could detect",
      name = "difference between the largest and smallest mean = "),
    list(ep = "E30", extra = list(), label = "the smallest difference between the largest and smallest group's correlation you could detect",
      name = "difference between the largest and smallest group's correlation = "),
    list(ep = "E45", extra = list(level_change = ""), label = "the smallest change in level you could detect", name = "change in level = "),
    list(ep = "E32", extra = list(odds_ratio_xw = ""), label = "the smallest interaction odds ratio you could detect", name = "interaction odds ratio = "),
    list(ep = "E15", extra = list(r_XW_Y = ""), label = "the smallest correlation of the interaction with Y you could detect",
      name = "is correlation of the interaction with Y = "),
    list(ep = "E70", extra = list(), label = "the smallest odds ratio you could detect", name = "odds ratio = "),
    list(ep = "E47", extra = list(), label = "the smallest odds ratio you could detect", name = "odds ratio = "),
    list(ep = "E47", extra = list(effect = "interaction"), label = "the smallest ratio of odds ratios you could detect",
      name = "ratio of odds ratios = ")
  )
  # Mediation on the moderation card has no smallest-effect goal.
  goal <- Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, "E32")))[[1]]
  expect_false(field_applies(list(shown_if = goal$choices_shown_if$sensitivity), list(analysis = "mediation")))
  for (case in cases) {
    n <- switch(case$ep, E47 = "420", E30 = "300", E45 = "24", E32 = "400", E70 = "400", E15 = "300", "100")
    run <- smallest_effect_run(case$ep, c(case$extra, list(n = n, simulation_accuracy = "quick")))
    expect_true(isTRUE(run$result$sensitivity$simulated), label = case$ep)
    expect_identical(result_figure(run$spec, run$result)$label, case$label)
    expect_match(result_sentences(run$spec, run$result)[["headline"]], case$name, fixed = TRUE)
    expect_false(is.na(usual_seconds(forms, case$ep, "sensitivity")), label = case$ep)
  }
})

test_that("the three-way interaction finds its smallest coefficient by InteractionPoweR's formula", {
  run <- smallest_effect_run("E31", list(b_XWZ = "", n = "300"))
  expect_identical(run$result$sensitivity$effect_name, "b_XWZ")
  expect_identical(result_figure(run$spec, run$result)$label, "the smallest three-way coefficient you could detect")
})

test_that("latent profiles and factor analysis find their smallest separation and loading", {
  cases <- list(
    list(ep = "E58", extra = list(separation = ""), label = "the smallest separation between neighbouring profiles you could detect"),
    list(ep = "E73", extra = list(loading = ""), label = "the smallest loading you could detect")
  )
  for (case in cases) {
    run <- smallest_effect_run(case$ep, c(case$extra, list(n = "150", simulation_accuracy = "quick")))
    expect_true(isTRUE(run$result$sensitivity$simulated), label = case$ep)
    expect_identical(result_figure(run$spec, run$result)$label, case$label)
    expect_false(is.na(usual_seconds(forms, case$ep, "sensitivity")), label = case$ep)
  }
})

test_that("the mediation cards offer the smallest indirect effect or index, through the R script", {
  export <- engine_function("export_run_script")
  for (ep in c("E10", "E11", "E12", "E13", "E14", "E16", "E17", "E40")) {
    goal <- Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, ep)))[[1]]
    expect_true("sensitivity" %in% names(goal$choices), info = ep)
    fields <- form_fields(form_groups(forms, ep))
    values <- smallest_effect_values(ep, list(n = "200"))
    expect_length(form_problems(fields, values), 0)
    spec <- build_spec(forms, ep, fields, values)
    spec$options$seed <- 3L
    # No preview: straight to the script, with its run time.
    expect_true(runs_long(forms, ep, spec), info = ep)
    expect_false(has_preview(forms, ep, "sensitivity", spec), info = ep)
    expect_match(script_run_time(forms, ep, "sensitivity", spec), "sizes of the effect are simulated", fixed = TRUE, info = ep)
    file <- withr::local_tempfile(fileext = ".R")
    export(spec, file)
    expect_true(any(grepl("sensitivity", readLines(file), fixed = TRUE)), info = ep)
  }
  # E38 (the difference between two conditional indirect effects) does not
  # offer it: its residual variances change with every path.
  goal <- Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, "E38")))[[1]]
  expect_false("sensitivity" %in% names(goal$choices))
})

test_that("the mixed-model cards offer the smallest effect through the R script, for one coefficient tested", {
  export <- engine_function("export_run_script")
  cases <- list(E33 = list(difference = "", n = "60"), E63 = list(n = "60"), E67 = list(slope = "", n = "60"), E68 = list(d = "", n = "640"),
    E41 = list(n = "420"), E62 = list(n = "420"))
  for (ep in names(cases)) {
    goal <- Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, ep)))[[1]]
    expect_true("sensitivity" %in% names(goal$choices), info = ep)
    fields <- form_fields(form_groups(forms, ep))
    values <- smallest_effect_values(ep, cases[[ep]])
    expect_length(form_problems(fields, values), 0)
    spec <- build_spec(forms, ep, fields, values)
    spec$options$seed <- 3L
    expect_true(runs_long(forms, ep, spec), info = ep)
    expect_false(has_preview(forms, ep, "sensitivity", spec), info = ep)
    expect_match(script_run_time(forms, ep, "sensitivity", spec), "sizes of the effect are simulated", fixed = TRUE, info = ep)
    file <- withr::local_tempfile(fileext = ".R")
    export(spec, file)
    expect_true(any(grepl("sensitivity", readLines(file), fixed = TRUE)), info = ep)
  }
  # Several coefficients tested together: the goal isn't offered.
  fields <- form_fields(form_groups(forms, "E41"))
  values <- smallest_effect_values("E41", list(two_level_effect = "within_and_interaction"))
  expect_match(form_problems(fields, values), "isn't available with the other answers", fixed = TRUE, all = FALSE)
})
