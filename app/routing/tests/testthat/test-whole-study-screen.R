# Whole-study simulation (experimental): which plans it covers, the screen,
# the spec it builds and the result. The engine runs the simulation.

ws_answers <- list(x = "score", outcome = "score", mediators = "one", moderator = "score", covariate = "none", times = "once")

test_that("the whole-study simulation covers measured predictors and score outcomes, and says why not otherwise", {
  plan <- whole_study_plan(tree, ws_answers, c("compare", "mediation", "moderation"), c("compare", "mediation"), list())
  expect_true(plan$ok)
  expect_equal(vapply(plan$analyses, function(a) a$test, ""), c("x_y", "indirect", "interaction"))
  expect_equal(vapply(plan$analyses, function(a) a$role, ""), c("main", "main", "extra"))
  expect_equal(plan$roles, c("X", "W", "M", "Y"))

  # A two-group condition is not covered yet; the reason is given.
  other <- modifyList(ws_answers, list(x = "cond2"))
  plan <- whole_study_plan(tree, other, c("compare", "mediation"), "compare", list())
  expect_false(plan$ok)
  expect_true(any(grepl("measured score", plan$reasons, fixed = TRUE)))

  # No main analysis.
  plan <- whole_study_plan(tree, ws_answers, "compare", character(), list())
  expect_false(plan$ok)

  # Moderated mediation follows the link the user chose.
  plan <- whole_study_plan(tree, ws_answers, c("modmed"), "modmed", list(modmed = "The link from the mediator to the outcome"))
  expect_true(plan$ok)
  expect_equal(plan$analyses[[1]]$moderated_link, "m_y")
  # "Both links" (E38) isn't covered.
  plan <- whole_study_plan(tree, ws_answers, c("modmed"), "modmed", list(modmed = "Both links, or X to the mediator and the direct link"))
  expect_false(plan$ok)
})

test_that("two mediators in a chain test the whole chain unless another path is chosen", {
  answers <- modifyList(ws_answers, list(mediators = "several", moderator = "none"))
  plan <- whole_study_plan(tree, answers, "mediation", "mediation",
    list(mediation = "In a chain: X affects the first, which affects the next"))
  expect_true(plan$ok)
  expect_equal(plan$mediators, "serial")
  expect_equal(plan$analyses[[1]]$path, "X->M1->M2->Y")
  expect_equal(plan$path_choices, c("X->M1->M2->Y", "X->M1->Y", "X->M2->Y"))
  expect_equal(plan$roles, c("X", "M1", "M2", "Y"))
})

test_that("variable names come from the plan's input screens", {
  labels <- whole_study_labels(c("X", "M", "Y"), list(mediation = list(X_label = "Workload", M_label = " Exhaustion ")))
  expect_equal(unname(labels), c("Workload", "Exhaustion", "Outcome"))
})

test_that("the screen asks for every value the engine says the population needs, with values from the plan filled in", {
  params_of <- engine_function("whole_study_parameters")
  skip_if(is.null(params_of), "engine not available")
  plan <- whole_study_plan(tree, ws_answers, c("compare", "mediation", "moderation"), c("compare", "mediation"), list())
  skeleton <- whole_study_skeleton(plan, whole_study_labels(plan$roles, list()))
  params <- params_of(skeleton)
  expect_setequal(params$paths, c("X->M", "X->Y", "M->Y", "W->Y", "XW->Y"))
  expect_equal(params$correlations, "X<->W")
  prefill <- whole_study_prefill(list(p_x_m = list(value = "0.3", from = "mediation"), r_x_w = list(value = "-0.2", from = "moderation")))
  html <- as.character(whole_study_ui(forms, plan, params, c(X = "X"), prefill, 180L, "all"))
  for (key in c(params$paths, params$correlations)) expect_match(html, whole_study_input_id(key), fixed = TRUE)
  expect_match(html, "value=\"0.3\"", fixed = TRUE)
  expect_match(html, "value=\"-0.2\"", fixed = TRUE)
  expect_match(html, "value=\"180\"", fixed = TRUE)
  expect_match(html, "Experimental", fixed = TRUE)
  expect_match(html, "the claim needs every main result to be significant", fixed = TRUE)
})

test_that("the spec is built from the screen's values, and problems are named in plain words", {
  params_of <- engine_function("whole_study_parameters")
  skip_if(is.null(params_of), "engine not available")
  plan <- whole_study_plan(tree, ws_answers, c("compare", "moderation"), c("compare", "moderation"), list())
  skeleton <- whole_study_skeleton(plan, whole_study_labels(plan$roles, list()))
  params <- params_of(skeleton)
  values <- list("X->Y" = "0.2", "W->Y" = "-0.1", "XW->Y" = "abc", "X<->W" = "1", n = "10", alpha = "0.05", nrep = "200", seed = "1")
  built <- whole_study_spec(skeleton, params, values, "all")
  expect_true(any(grepl("Path XW .* Y.*enter a number", built$problems)))
  expect_true(any(grepl("strictly between", built$problems, fixed = TRUE)))
  expect_true(any(grepl("20 or more", built$problems, fixed = TRUE)))

  values[["XW->Y"]] <- "-0.15"; values[["X<->W"]] <- "-0.2"; values$n <- "150"
  built <- whole_study_spec(skeleton, params, values, "any")
  expect_null(built$problems)
  expect_equal(built$spec$claim, "any")
  expect_equal(built$spec$goal$n, 150L)
  expect_equal(built$spec$population$paths[["XW->Y"]], -0.15)
  expect_length(whole_study_check(built$spec), 0)

  # Impossible paths: the engine's message is passed on.
  values[["X->Y"]] <- "0.99"; values[["W->Y"]] <- "0.9"
  built <- whole_study_spec(skeleton, params, values, "all")
  expect_match(paste(whole_study_check(built$spec), collapse = " "), "impossible together", fixed = TRUE)
})

test_that("the result shows each analysis, the joint power for the claim, the implied values and the methods", {
  run <- engine_function("run_whole_study")
  skip_if(is.null(run), "engine not available")
  skip_on_cran()
  plan <- whole_study_plan(tree, ws_answers, c("compare", "moderation"), c("compare", "moderation"), list())
  skeleton <- whole_study_skeleton(plan, whole_study_labels(plan$roles, list()))
  params <- engine_function("whole_study_parameters")(skeleton)
  values <- list("X->Y" = "0.2", "W->Y" = "-0.1", "XW->Y" = "-0.15", "X<->W" = "-0.2", n = "150", alpha = "0.05", nrep = "100", seed = "3")
  spec <- whole_study_spec(skeleton, params, values, "all")$spec
  calc <- run_calculation(spec, run = run)
  expect_equal(calc$status, "ok")
  html <- as.character(whole_study_result_ui(calc, list(compare = list(r = "0.25")), departure = forms$departures[["13"]]))
  # The departure from the established tools is stated on the result.
  expect_match(html, "the joint chance is counted directly", fixed = TRUE)
  expect_match(html, "the chance that all of your main analyses are significant in the same study", fixed = TRUE)
  expect_match(html, plan$analyses[[1]]$label, fixed = TRUE)
  expect_match(html, "Implied by your population", fixed = TRUE)
  expect_match(html, ">0.25<", fixed = TRUE)
  expect_match(html, "Methods paragraph", fixed = TRUE)
  expect_match(html, "power4mome", fixed = TRUE)
  expect_match(html, "Experimental", fixed = TRUE)

  failed <- whole_study_result_ui(list(status = "error", message = "Something plain."))
  expect_match(as.character(failed), "Something plain.", fixed = TRUE)
})
