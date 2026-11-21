# Whole-study simulation (experimental): which plans it covers, the screen,
# the spec it builds and the result. The engine runs the simulation.

ws_answers <- list(x = "score", outcome = "score", mediators = "one", moderator = "score", covariate = "none", times = "once")

test_that("the whole-study simulation covers measured predictors and score outcomes, and says why not otherwise", {
  plan <- whole_study_plan(tree, ws_answers, c("compare", "mediation", "moderation"), c("compare", "mediation"), list())
  expect_true(plan$ok)
  expect_equal(vapply(plan$analyses, function(a) a$test, ""), c("x_y", "indirect", "interaction"))
  expect_equal(vapply(plan$analyses, function(a) a$role, ""), c("main", "main", "extra"))
  expect_equal(plan$roles, c("X", "W", "M", "Y"))

  # Three or more groups are not covered yet; the reason is given.
  other <- modifyList(ws_answers, list(x = "cond3"))
  plan <- whole_study_plan(tree, other, c("compare", "mediation"), "compare", list())
  expect_false(plan$ok)
  expect_true(any(grepl("two groups or conditions", plan$reasons, fixed = TRUE)))

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

test_that("measured twice, every analysis adjusts for the first measurement; the ANCOVA comparison is covered, the mixed ANOVA's is not", {
  twice <- modifyList(ws_answers, list(x = "cond2", times = "twice"))
  ancova <- list(compare = "ANCOVA: the second measurement adjusting for the first")
  plan <- whole_study_plan(tree, twice, c("compare", "moderation", "mediation"), c("compare", "moderation"), ancova)
  expect_true(plan$ok)
  expect_equal(vapply(plan$analyses, function(a) a$test, ""), c("x_y", "interaction", "indirect"))
  expect_equal(plan$roles, c("X", "W", "M", "B", "Y"))
  skeleton <- whole_study_skeleton(plan, whole_study_labels(plan$roles, list(compare = list(Y_label = "Exhaustion"))))
  expect_identical(skeleton$variables$B, list(type = "continuous", label = "Exhaustion, first measurement"))
  # The mixed ANOVA's group x time test is not simulated as a whole study
  # measured twice.
  mixed <- list(compare = "The 2 x 2 mixed ANOVA interaction (group x time)")
  plan <- whole_study_plan(tree, twice, "compare", "compare", mixed)
  expect_false(plan$ok)
  expect_true(any(grepl("not yet", plan$reasons, fixed = TRUE)))
  # Moderated mediation needs a measured X and the moderated link chosen.
  expect_false(whole_study_plan(tree, twice, "modmed", "modmed", list())$ok)
  # Two mediators need how they connect.
  expect_false(whole_study_plan(tree, modifyList(twice, list(mediators = "several")), "mediation", "mediation", list())$ok)
  # Measured three times or more stays outside.
  expect_false(whole_study_plan(tree, modifyList(twice, list(times = "many_conditions")), "compare", "compare", ancova)$ok)
  params_of <- engine_function("whole_study_parameters")
  skip_if(is.null(params_of), "engine not available")
  params <- params_of(skeleton)
  expect_true("B->Y" %in% params$paths)
  # Two groups: their correlations with W and B are asked too (0 if people
  # are randomised to the groups).
  expect_setequal(params$correlations, c("X<->W", "X<->B", "W<->B"))
})

test_that("measured twice: two mediators side by side or in a chain, and moderated mediation of one link", {
  twice <- modifyList(ws_answers, list(times = "twice"))
  several <- modifyList(twice, list(mediators = "several", moderator = "none"))
  route <- resolve_analysis(tree, analysis_by_id(tree, "mediation"), several)
  expect_identical(route$ask$doc_id, "ME3")
  chain <- whole_study_plan(tree, several, "mediation", "mediation",
    list(mediation = "In a chain: X affects the first, which affects the next"))
  expect_true(chain$ok)
  expect_identical(chain$mediators, "serial")
  expect_identical(chain$analyses[[1]]$path, "X->M1->M2->Y")
  expect_equal(chain$roles, c("X", "M1", "M2", "B", "Y"))
  side <- whole_study_plan(tree, several, "mediation", "mediation",
    list(mediation = "Side by side: X affects each one separately"))
  expect_true(side$ok)
  expect_identical(side$mediators, "parallel")
  expect_identical(side$analyses[[1]]$path, "X->M1->Y")
  # Moderated mediation: the chosen link is the one the index tests.
  expect_identical(resolve_analysis(tree, analysis_by_id(tree, "modmed"), twice)$ask$doc_id, "MM4")
  for (choice in list(c("The link from X to the mediator", "x_m"), c("The link from the mediator to the outcome", "m_y"))) {
    plan <- whole_study_plan(tree, twice, c("modmed", "mediation"), "modmed", list(modmed = choice[1]))
    expect_true(plan$ok)
    expect_identical(plan$analyses[[1]]$test, "index_of_mome")
    expect_identical(plan$analyses[[1]]$moderated_link, choice[2])
    expect_equal(plan$roles, c("X", "W", "M", "B", "Y"))
  }
  # Both links moderated is not simulated (nor is it measured once).
  both <- whole_study_plan(tree, twice, "modmed", "modmed", list(modmed = "Both links, or X to the mediator and the direct link"))
  expect_false(both$ok)
  # A yes/no X with moderated mediation stays outside, as measured once.
  expect_false(whole_study_plan(tree, modifyList(twice, list(x = "cond2")), "modmed", "modmed",
    list(modmed = "The link from X to the mediator"))$ok)
  skeleton <- whole_study_skeleton(chain, whole_study_labels(chain$roles, list()))
  params_of <- engine_function("whole_study_parameters")
  skip_if(is.null(params_of), "engine not available")
  params <- params_of(skeleton)
  expect_true(all(c("B->Y", "M1->M2") %in% params$paths))
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
  expect_match(html, "Validation in progress", fixed = TRUE)
  expect_no_match(html, "statistician", fixed = TRUE)
  expect_match(html, "the claim needs every main result to be significant", fixed = TRUE)
  # A quick look here; the full run is the script's.
  expect_match(html, sprintf("a quick look: %s simulated studies", forms$whole_study$quick_nrep), fixed = TRUE)
  expect_false(grepl("ws_nrep", html, fixed = TRUE))
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
  script <- whole_study_script_ui(forms, plan, 150L, "all", 2)
  html <- as.character(whole_study_result_ui(calc, list(compare = list(r = "0.25")), departure = forms$departures[["13"]], script = script))
  expect_match(html, "A quick look, from 100 simulated studies", fixed = TRUE)
  expect_match(html, "ws_download_script", fixed = TRUE)
  # The departure from the established tools is stated on the result.
  expect_match(html, "their joint success is counted directly", fixed = TRUE)
  expect_match(html, "the chance that all of your main analyses are significant in the same study", fixed = TRUE)
  expect_match(html, plan$analyses[[1]]$label, fixed = TRUE)
  expect_match(html, "Implied by your study model", fixed = TRUE)
  expect_match(html, ">0.25<", fixed = TRUE)
  expect_match(html, "Methods paragraph", fixed = TRUE)
  expect_match(html, "power4mome", fixed = TRUE)
  expect_match(html, "experimental)", fixed = TRUE)
  # The paragraph states the population, words the joint power as the
  # claim, names powerkit as a prototype and leaves out failure counts
  # when none failed.
  methods <- whole_study_methods(calc$result)
  expect_match(methods, "The assumed population values (standardised) were: X to Y 0.2", fixed = TRUE)
  expect_match(methods, "correlation of X and W -0.2", fixed = TRUE)
  expect_match(methods, "The study's claim needs every main analysis to be significant", fixed = TRUE)
  expect_match(methods, "a prototype in development", fixed = TRUE)
  expect_no_match(methods, "Joint all criterion|studies attempted")
  # Laid out like every result: section links, the joint chance as the big
  # figure, each analysis's power as a bar, and a methods paragraph to copy.
  expect_match(html, "result-sections", fixed = TRUE)
  expect_match(html, "result-figure-value", fixed = TRUE)
  expect_match(html, "ws-bar-fill", fixed = TRUE)
  expect_match(html, "writeup_short", fixed = TRUE)

  failed <- whole_study_result_ui(list(status = "error", message = "Something plain."))
  expect_match(as.character(failed), "Something plain.", fixed = TRUE)
})

test_that("the planning document gathers the analyses, the claim, the population, the powers and the script", {
  run <- engine_function("run_whole_study")
  export <- engine_function("export_whole_study_script")
  skip_if(is.null(run) || is.null(export), "engine not available")
  skip_on_cran()
  plan <- whole_study_plan(tree, ws_answers, c("compare", "moderation"), c("compare", "moderation"), list())
  skeleton <- whole_study_skeleton(plan, whole_study_labels(plan$roles, list()))
  params <- engine_function("whole_study_parameters")(skeleton)
  values <- list("X->Y" = "0.2", "W->Y" = "-0.1", "XW->Y" = "-0.15", "X<->W" = "-0.2", n = "150", alpha = "0.05", nrep = "100", seed = "3")
  spec <- whole_study_spec(skeleton, params, values, "all")$spec
  calc <- run_calculation(spec, run = run)
  expect_equal(calc$status, "ok")
  md <- whole_study_planning_document(calc, export(spec), departure = forms$departures[["13"]])
  text <- paste(md, collapse = "\n")
  expect_identical(md[1], "# Whole-study simulation report")
  expect_match(text, "**Validation in progress.**", fixed = TRUE)
  expect_match(text, "quick look of 100 simulated studies", fixed = TRUE)
  expect_match(text, "needs every main analysis (2) to be significant in the same study", fixed = TRUE)
  for (label in calc$result$analyses$label) expect_match(text, label, fixed = TRUE)
  expect_match(text, "(main analysis): power", fixed = TRUE)
  expect_match(text, "## Joint power for the claim", fixed = TRUE)
  expect_match(text, sprintf("**%s**", percent(calc$result$joint$power)), fixed = TRUE)
  expect_match(text, "The assumed population values (standardised) were: X to Y 0.2", fixed = TRUE)
  expect_match(text, whole_study_methods(calc$result, full = TRUE), fixed = TRUE)
  expect_match(text, calc$result$provenance$spec_hash, fixed = TRUE)
  expect_match(text, "their joint success is counted directly", fixed = TRUE)
  # The script that reproduces the numbers is in the document, whole.
  expect_match(text, "```r\n# Runs a powerkit whole-study simulation", fixed = TRUE)
  expect_match(text, "library(powerkit)", fixed = TRUE)
  # As PDF, the script's "<-" reads as written (still escaped); as Word,
  # its lines stay apart.
  html <- printable_document(md, "0.0.0")
  expect_match(html, "spec_json &lt;- paste(", fixed = TRUE)
  expect_no_match(html, "&amp;lt;", fixed = TRUE)
  docx <- docx_body(md)$body
  expect_match(docx, "<w:br/>", fixed = TRUE)
  # The result offers it.
  page <- as.character(whole_study_result_ui(calc, departure = forms$departures[["13"]]))
  expect_match(page, "ws_planning_document_button", fixed = TRUE)
  expect_match(page, "ws_download_planning_docx", fixed = TRUE)
})

test_that("the script for the full run finds the sample size, or the power at N with the full number of studies", {
  export <- engine_function("export_whole_study_script")
  skip_if(is.null(export), "engine not available")
  plan <- whole_study_plan(tree, ws_answers, c("compare", "moderation"), c("compare", "moderation"), list())
  skeleton <- whole_study_skeleton(plan, whole_study_labels(plan$roles, list()))
  params <- engine_function("whole_study_parameters")(skeleton)
  values <- list("X->Y" = "0.2", "W->Y" = "-0.1", "XW->Y" = "-0.15", "X<->W" = "-0.2", n = "150", alpha = "0.05", seed = "3")
  spec <- whole_study_spec(skeleton, params, values, "all", nrep = forms$whole_study$quick_nrep)$spec
  expect_equal(spec$options$nrep, as.integer(forms$whole_study$quick_nrep))

  search <- whole_study_script_spec(spec, forms, "sample_size", "0.9")
  expect_equal(search$goal, list(type = "sample_size", power = 0.9))
  expect_equal(search$options$nrep, as.integer(forms$whole_study$full_nrep))
  expect_equal(search$options$seed, 3L)
  text <- export(search, run_time = whole_study_script_time(forms, plan, "sample_size"))
  expect_match(text, "the smallest n for 90% power, by the chance that every main analysis is significant", fixed = TRUE)
  expect_match(text, "on one core.", fixed = TRUE)

  full <- whole_study_script_spec(spec, forms, "power", "0.9")
  expect_equal(full$goal, list(type = "power", n = 150L))
  expect_match(export(full), "the power of every analysis at n = 150", fixed = TRUE)

  # The choice names what the target applies to, for the claim.
  html <- as.character(whole_study_script_ui(forms, plan, 150L, "any", 2))
  expect_match(html, "the chance that at least one of your main analyses is significant", fixed = TRUE)
  html <- as.character(whole_study_script_ui(forms, plan, 150L, "any", 1))
  expect_match(html, "your main analysis reaches the target power", fixed = TRUE)
  expect_match(html, "remotes::install_github", fixed = TRUE)
})

test_that("long waits are given in hours", {
  expect_equal(whole_study_duration(3 * 3600), "about 3 hours")
  expect_equal(whole_study_duration(25 * 3600), "about 25 hours")
  expect_equal(whole_study_duration(2.8 * 3600), "about 3 hours")
  expect_equal(whole_study_duration(100 * 60), "about 1.5 hours")
  expect_equal(whole_study_duration(600), "about 10 minutes")
  expect_equal(whole_study_duration_range(c(100 * 60, 2.8 * 3600)), "about 1.5 to 3 hours")
  expect_equal(whole_study_duration_range(c(40 * 60, 2 * 3600)), "about 40 minutes to 2 hours")
})

test_that("two groups or conditions: the group comparison, moderation and mediation are simulated together (next.md item 1)", {
  answers <- modifyList(ws_answers, list(x = "cond2"))
  plan <- whole_study_plan(tree, answers, c("compare", "mediation", "moderation"), c("compare", "moderation"), list())
  expect_true(plan$ok)
  expect_true(plan$binary_x)
  expect_equal(vapply(plan$analyses, function(a) a$test, ""), c("x_y", "indirect", "interaction"))
  skeleton <- whole_study_skeleton(plan, whole_study_labels(plan$roles, list()))
  expect_identical(skeleton$variables$X$type, "binary")
  expect_identical(skeleton$variables$W$type, "continuous")
  params_of <- engine_function("whole_study_parameters")
  skip_if(is.null(params_of), "engine not available")
  # The engine asks for the correlation of the groups with W: 0 when people
  # are randomised to the groups, as the label says, and otherwise the
  # correlation of non-randomised groups (such as gender) with the moderator.
  params <- params_of(skeleton)
  expect_true("X<->W" %in% params$correlations)
  expect_match(whole_study_path_label("X<->W"), "0 if people are randomised", fixed = TRUE)
})

test_that("experiments: conditions crossed with groups are simulated as one factorial ANOVA", {
  exp_answers <- list(x = "cond2", outcome = "score", mediators = "none", moderator = "two", covariate = "none", times = "once")
  plan <- whole_study_plan(tree, exp_answers, c("compare", "moderation"), c("compare", "moderation"), list())
  expect_true(plan$ok)
  expect_true(plan$experiment)
  expect_equal(vapply(plan$analyses, function(a) a$effect, ""), c("main_effect_A", "interaction"))
  labels <- whole_study_labels(plan$roles, list())
  values <- list(x_levels = "Control, Training", w_levels = "Young, Old", sd = "10", n = "200", alpha = "0.05", seed = "1",
    means = list(ws_mean_1_1 = "50", ws_mean_1_2 = "50", ws_mean_2_1 = "55", ws_mean_2_2 = "52"))
  built <- whole_study_experiment_spec(plan, labels, values, "all", 200)
  expect_null(built$problems)
  expect_equal(built$spec$experiment$template, "2x2_between")
  expect_equal(built$spec$experiment$population$means, list(list(50, 50), list(55, 52)))
  expect_equal(built$spec$analyses[[2]]$label, sprintf("Whether the effect of %s depends on %s (the interaction)", labels[["X"]], labels[["W"]]))
  # A missing mean and an SD of 0 are said plainly.
  values$means$ws_mean_2_2 <- ""
  values$sd <- "0"
  problems <- whole_study_experiment_spec(plan, labels, values, "all", 200)$problems
  expect_true(any(grepl("every cell", problems)) && any(grepl("SD", problems)))

  # The same people in two conditions, crossed with three groups: a mixed
  # ANOVA, X the within factor (B) and the groups between (A).
  mixed <- modifyList(exp_answers, list(x = "within2", moderator = "three", times = "twice"))
  plan <- whole_study_plan(tree, mixed, c("compare", "moderation"), "moderation", list())
  expect_true(plan$experiment)
  expect_equal(plan$x_factor, "B")
  expect_equal(vapply(plan$analyses, function(a) a$role, ""), c("extra", "main"))
  values <- list(x_levels = "Before, After", w_levels = "A, B, C", sd = "1", r = "0.5", n = "90", alpha = "0.05", seed = "1",
    means = list(ws_mean_1_1 = "0", ws_mean_1_2 = "0", ws_mean_2_1 = "0", ws_mean_2_2 = "0.3", ws_mean_3_1 = "0", ws_mean_3_2 = "0.5"))
  built <- whole_study_experiment_spec(plan, whole_study_labels(plan$roles, list()), values, "each", 200)
  expect_equal(built$spec$experiment$template, "mixed")
  expect_equal(built$spec$experiment$variables$B$type, "within_factor")
  expect_equal(built$spec$experiment$population$r, 0.5)
  expect_length(whole_study_check(built$spec), 0)

  # Three conditions and no moderator: a one-way ANOVA. Two conditions
  # with no moderator stay on the general route, as before.
  plan <- whole_study_plan(tree, modifyList(exp_answers, list(x = "cond3", moderator = "none")), "compare", "compare", list())
  expect_true(plan$experiment)
  expect_null(whole_study_plan(tree, modifyList(exp_answers, list(moderator = "none")), "compare", "compare", list())$experiment)
  # A mediator or a yes/no outcome: the general route's reasons.
  expect_false(whole_study_plan(tree, modifyList(exp_answers, list(outcome = "yesno")), "compare", "compare", list())$ok)
})

test_that("measured twice, a baseline covariate is the first measurement, so the plan is simulated as without one", {
  none <- modifyList(ws_answers, list(x = "cond2", times = "twice"))
  base <- modifyList(none, list(covariate = "baseline"))
  plan_none <- whole_study_plan(tree, none, c("compare", "moderation"), c("compare", "moderation"),
    list(compare = "ANCOVA: the second measurement adjusting for the first"))
  plan_base <- whole_study_plan(tree, base, c("compare", "moderation"), c("compare", "moderation"),
    list(compare = "ANCOVA: the outcome adjusting for the baseline"))
  expect_true(plan_base$ok)
  expect_identical(plan_base$analyses, plan_none$analyses)
  expect_identical(plan_base$roles, plan_none$roles)
  # Other covariates are added beside the baseline (C1, then C2 and C3).
  other <- whole_study_plan(tree, modifyList(none, list(covariate = "other")), "moderation", "moderation", list())
  expect_true(other$ok)
  expect_identical(other$roles, c("X", "W", "B", "C1", "Y"))
  # A covariate that isn't a score measured on each person isn't simulated.
  unsure <- whole_study_plan(tree, modifyList(none, list(covariate = "notsure")), "moderation", "moderation", list())
  expect_false(unsure$ok)
  expect_true(any(grepl("covariates are scores", unsure$reasons, fixed = TRUE)))
})

test_that("covariates: every analysis adjusts for them, the screen asks how many and for their paths, and the write-up says so", {
  params_of <- engine_function("whole_study_parameters")
  skip_if(is.null(params_of), "engine not available")
  answers <- modifyList(ws_answers, list(covariate = "other"))
  # The effect of X with covariates is the multiple regression (E24), or
  # the ANCOVA (E23) for two groups; both are the regression adjusting for them.
  plan <- whole_study_plan(tree, answers, c("compare", "mediation", "moderation"), c("compare", "mediation"), list(), n_covariates = "2")
  expect_true(plan$ok)
  expect_equal(vapply(plan$analyses, function(a) a$test, ""), c("x_y", "indirect", "interaction"))
  expect_equal(plan$roles, c("X", "W", "M", "C1", "C2", "Y"))
  expect_identical(plan$n_covariates, 2L)
  groups <- whole_study_plan(tree, modifyList(answers, list(x = "cond2", moderator = "none")), "compare", "compare", list())
  expect_true(groups$ok)
  expect_equal(groups$roles, c("X", "C1", "Y"))
  labels <- whole_study_labels(plan$roles, list())
  expect_identical(labels[["C2"]], "Second covariate")
  skeleton <- whole_study_skeleton(plan, labels)
  params <- params_of(skeleton)
  expect_true(all(c("C1->M", "C2->M", "C1->Y", "C2->Y") %in% params$paths))
  expect_true(all(c("X<->C1", "W<->C2", "C1<->C2") %in% params$correlations))
  html <- as.character(whole_study_ui(forms, plan, params, labels, list(), 200L, "all"))
  expect_match(html, "How many covariates every analysis adjusts for", fixed = TRUE)
  expect_match(html, "ws_name_C2", fixed = TRUE)
  expect_match(html, whole_study_input_id("C1<->C2"), fixed = TRUE)
  expect_match(whole_study_path_label("X<->C1"), "Correlation of the predictor with the first covariate (X with C1; for groups", fixed = TRUE)
  expect_match(whole_study_path_label("C1->M"), "from the first covariate (C1) to the mediator (M)", fixed = TRUE)
  # The screen's choice of how many reaches the plan.
  expect_identical(whole_study_values(list(ws_n_covariates = "3"), params)$n_covariates, "3")
  # The methods paragraph says what every analysis adjusted for.
  r <- list(analyses = data.frame(id = "compare", label = "The effect", power = 0.8, role = "main"),
    implied = list(compare = list(values = c(r = 0.2, r_C1_Y = 0.3, r_C2_Y = 0.1))),
    provenance = list(backend = "power4mome", packages = list(powerkit = "0.80.0", power4mome = "0.2.1"), nrep = 200, seed = 1),
    n = 200, alpha = 0.05, claim = "each", models = list(population_values = ""))
  expect_match(whole_study_methods(r), "adjusted each of its regressions (for the mediators and the outcome) for the two covariates (C1, C2)", fixed = TRUE)
})

test_that("a manipulation check beside a mediation is planned and simulated as M on X alone", {
  answers <- modifyList(ws_answers, list(x = "cond2", moderator = "none"))
  check <- analysis_by_id(tree, "check")
  expect_identical(resolve_analysis(tree, check, answers)$endpoint, "E2")
  expect_identical(resolve_analysis(tree, check, modifyList(answers, list(x = "score")))$endpoint, "E4")
  # Offered only with mediators.
  expect_false("check" %in% vapply(applicable_analyses(tree, modifyList(answers, list(mediators = "none"))), `[[`, "", "id"))
  expect_true("check" %in% vapply(applicable_analyses(tree, answers), `[[`, "", "id"))
  plan <- whole_study_plan(tree, answers, c("check", "mediation"), "mediation", list())
  expect_true(plan$ok)
  expect_equal(vapply(plan$analyses, function(a) a$test, ""), c("x_m", "indirect"))
  expect_equal(plan$roles, c("X", "M", "Y"))
  # Measured twice too, with the outcome's first measurement in the model.
  twice <- whole_study_plan(tree, modifyList(answers, list(times = "twice")), c("check", "mediation"), "mediation", list())
  expect_true(twice$ok)
  expect_equal(twice$roles, c("X", "M", "B", "Y"))
  # Two mediators: the check is planned card by card, not simulated.
  two <- whole_study_plan(tree, modifyList(answers, list(mediators = "several")), c("check"), "check", list())
  expect_false(two$ok)
  params_of <- engine_function("whole_study_parameters")
  skip_if(is.null(params_of), "engine not available")
  skeleton <- whole_study_skeleton(plan, whole_study_labels(plan$roles, list()))
  expect_setequal(params_of(skeleton)$paths, c("X->M", "M->Y", "X->Y"))
})

test_that("names typed on the simulation screen come first, and the screen asks for them", {
  labels <- whole_study_labels(c("X", "W", "B", "Y"), list(compare = list(Y_label = "Exhaustion")),
    named = list(X = "Workload", Y = "Burnout"))
  expect_identical(unname(labels[c("X", "W", "B", "Y")]), c("Workload", "Moderator", "Burnout, first measurement", "Burnout"))
  html <- as.character(whole_study_name_inputs(c("X", "W", "B", "Y"), labels))
  expect_match(html, "ws_name_X", fixed = TRUE)
  expect_false(grepl("ws_name_B", html, fixed = TRUE))
  input <- list(ws_name_X = " Workload ", ws_name_W = "", ws_name_Y = "Burnout")
  expect_identical(whole_study_names_from_input(input, c("X", "W", "B", "Y")), list(X = "Workload", Y = "Burnout"))
})

test_that("a rough power curve is offered for experiments and regressions, and read in plain words", {
  regression <- list(goal = list(type = "power", n = 200), analyses = list(list(test = "x_y"), list(test = "interaction")))
  expect_true(whole_study_curve_offered(regression))
  mediation <- regression
  mediation$analyses[[2]]$test <- "indirect"
  expect_false(whole_study_curve_offered(mediation))
  plan <- list(analyses = list(list(test = "x_y"), list(test = "interaction")))
  html <- as.character(whole_study_curve_offer_ui(forms, plan))
  expect_match(html, "Show a rough power curve", fixed = TRUE)
  expect_match(html, "5 sample sizes", fixed = TRUE)
  calc <- list(status = "ok", result = list(rule = "all",
    curve = data.frame(n = c(100, 150, 200, 300), power = c(0.4, 0.6, 0.78, 0.93), lower = c(0.33, 0.53, 0.72, 0.89),
      upper = c(0.47, 0.67, 0.84, 0.96), nrep = 200),
    provenance = list(nrep = 200, seed = 1, backend = "power4mome", packages = list(power4mome = "0.1"))))
  html <- as.character(whole_study_curve_ui(calc))
  expect_match(html, "between N = 200 and N = 300", fixed = TRUE)
  expect_match(html, "every main analysis", fixed = TRUE)
  calc$result$curve$power <- c(0.1, 0.2, 0.3, 0.4)
  expect_match(as.character(whole_study_curve_ui(calc)), "stays below 80% up to N = 300", fixed = TRUE)
  expect_match(as.character(whole_study_curve_ui(list(status = "error", message = "Plain."))), "Plain.", fixed = TRUE)
})

test_that("a two-group predictor can be given as Cohen's d, which the engine turns into the path", {
  plan <- list(binary_x = TRUE, analyses = list(list(id = "total", test = "x_y", label = "Total", role = "main")), roles = c("X", "Y"))
  params <- list(paths = c("X->Y"), correlations = character())
  expect_identical(whole_study_d_keys(plan, params), "X->Y")
  expect_identical(whole_study_d_keys(modifyList(plan, list(binary_x = FALSE)), params), character())
  html <- as.character(whole_study_ui(forms, plan, params, list(X = "X", Y = "Y"), list(d_Y = "0.4"), NULL, "each"))
  expect_match(html, "Cohen.{1,6}s d of the groups on the outcome \\(Y\\)")
  expect_match(html, "value=\"0.4\"", fixed = TRUE)
  expect_identical(whole_study_prefill(list(), plan, list(total = list(d = "0.5")))$d_Y, "0.5")
  skeleton <- list(spec_version = "0.1", kind = "whole_study", variables = list(X = list(type = "binary", label = "X"), Y = list(type = "continuous", label = "Y")),
    analyses = plan$analyses, effect_justification = list(type = "none"))
  values <- list(`X->Y` = "", x_effect = "d", d_Y = "0.4", n = "100", alpha = "0.05", seed = "1")
  built <- whole_study_spec(skeleton, params, values, "each", nrep = 200)
  expect_null(built$problems)
  expect_identical(built$spec$population$group_d, list(Y = 0.4))
  expect_null(built$spec$population$paths$`X->Y`)
  expect_length(whole_study_check(built$spec), 0)
  values$x_effect <- "path"
  expect_match(paste(whole_study_spec(skeleton, params, values, "each", nrep = 200)$problems, collapse = " "), "Path X")
  r <- list(group_d = list(Y = 0.4), found_paths = list(`X->Y` = 0.1987))
  expect_match(whole_study_group_d_text(r), "path from X to Y (0.199) gives a Cohen's d of 0.4", fixed = TRUE)
})

test_that("the same people in three or more conditions: the plan offers it and simulates it as a repeated-measures or two-way within ANOVA", {
  g <- tree$guided
  x_var <- Filter(function(v) identical(v$id, "x"), g$variables)[[1]]
  w_var <- Filter(function(v) identical(v$id, "moderator"), g$variables)[[1]]
  many <- list(times = "many_conditions")
  expect_true(all(c("within3", "within2") %in% names(guided_options(x_var, many))))
  expect_false("within3" %in% names(guided_options(x_var, list(times = "twice"))))
  expect_true("within" %in% names(guided_options(w_var, many)))
  expect_false("within" %in% names(guided_options(w_var, list(times = "once"))))
  base <- list(x = "within3", outcome = "score", mediators = "none", moderator = "none", covariate = "none", times = "many_conditions")
  compare <- analysis_by_id(tree, "compare")
  moderation <- analysis_by_id(tree, "moderation")
  expect_identical(resolve_analysis(tree, compare, base)$endpoint, "E54")
  expect_identical(resolve_analysis(tree, compare, modifyList(base, list(moderator = "two")))$endpoint, "E55")
  expect_identical(resolve_analysis(tree, moderation, modifyList(base, list(moderator = "two")))$endpoint, "E55")
  both <- modifyList(base, list(x = "within2", moderator = "within"))
  expect_identical(resolve_analysis(tree, compare, both)$endpoint, "E20")
  expect_identical(resolve_analysis(tree, moderation, both)$endpoint, "E20")

  # One factor in three or more conditions: a repeated-measures ANOVA.
  plan <- whole_study_plan(tree, base, "compare", "compare", list())
  expect_true(plan$experiment)
  expect_identical(plan$template, "oneway_within")
  expect_identical(plan$x_levels, 3L)
  labels <- whole_study_labels(plan$roles, list())
  values <- list(x_levels = "Easy, Medium, Hard", sd = "100", r = "0.6", n = "40", alpha = "0.05", seed = "1",
    means = list(ws_mean_1_1 = "600", ws_mean_2_1 = "620", ws_mean_3_1 = "650"))
  built <- whole_study_experiment_spec(plan, labels, values, "each", nrep = 200)
  expect_null(built$problems)
  expect_identical(built$spec$experiment$template, "oneway_within")
  expect_identical(built$spec$experiment$variables$A$type, "within_factor")
  expect_length(whole_study_check(built$spec), 0)

  # Both factors within people: a two-way repeated-measures ANOVA, X as A.
  plan <- whole_study_plan(tree, both, c("compare", "moderation"), c("compare", "moderation"), list())
  expect_true(plan$ok)
  expect_identical(plan$template, "factorial_within")
  expect_identical(plan$x_factor, "A")
  expect_true(plan$w_within)
  html <- as.character(whole_study_experiment_ui(forms, plan, whole_study_labels(plan$roles, list()), 30L, "all"))
  expect_match(html, "two-way repeated-measures ANOVA", fixed = TRUE)
  expect_match(html, "Correlation between a person's scores in any two conditions", fixed = TRUE)
  expect_match(html, "Everyone takes part in every condition.", fixed = TRUE)
  values <- list(x_levels = "Valid, Invalid", w_levels = "Short, Medium, Long", sd = "80", r = "0.6", n = "30", alpha = "0.05", seed = "1",
    means = list(ws_mean_1_1 = "400", ws_mean_1_2 = "410", ws_mean_1_3 = "420", ws_mean_2_1 = "430", ws_mean_2_2 = "450", ws_mean_2_3 = "470"))
  built <- whole_study_experiment_spec(plan, whole_study_labels(plan$roles, list()), values, "all", nrep = 200)
  expect_null(built$problems)
  expect_identical(built$spec$experiment$template, "factorial_within")
  expect_identical(built$spec$experiment$variables$B$type, "within_factor")
  expect_length(whole_study_check(built$spec), 0)

  # X in three or more conditions crossed with groups: a mixed ANOVA.
  plan <- whole_study_plan(tree, modifyList(base, list(moderator = "three")), c("compare", "moderation"), "moderation", list())
  expect_identical(plan$template, "mixed")
  expect_identical(plan$x_factor, "B")
})

test_that("the moderator's own effect is a planned analysis: Y on W in a regression study, W's main effect in an experiment", {
  w_main <- analysis_by_id(tree, "w_main")
  expect_false(is.null(w_main))
  expect_true("w_main" %in% vapply(applicable_analyses(tree, ws_answers), `[[`, "", "id"))
  expect_false("w_main" %in% vapply(applicable_analyses(tree, modifyList(ws_answers, list(moderator = "none"))), `[[`, "", "id"))
  expect_identical(resolve_analysis(tree, w_main, ws_answers)$endpoint, "E4")
  expect_identical(resolve_analysis(tree, w_main, modifyList(ws_answers, list(x = "cond2", moderator = "two")))$endpoint, "E7")
  expect_identical(resolve_analysis(tree, w_main, modifyList(ws_answers, list(x = "within3", moderator = "two", times = "many_conditions")))$endpoint, "E55")
  # A regression study: Y on W alone, beside the interaction.
  plan <- whole_study_plan(tree, ws_answers, c("moderation", "w_main"), c("moderation", "w_main"), list())
  expect_true(plan$ok)
  expect_equal(vapply(plan$analyses, function(a) a$test, ""), c("interaction", "w_y"))
  expect_equal(plan$roles, c("X", "W", "Y"))
  alone <- whole_study_plan(tree, ws_answers, "w_main", "w_main", list())
  expect_true(alone$ok)
  expect_equal(alone$roles, c("X", "W", "Y"))
  twice <- whole_study_plan(tree, modifyList(ws_answers, list(x = "cond2", times = "twice")), "w_main", "w_main", list())
  expect_true(twice$ok)
  expect_identical(twice$analyses[[1]]$test, "w_y")
  # An experiment: the main effect of the moderator's factor.
  exp <- whole_study_plan(tree, modifyList(ws_answers, list(x = "cond2", moderator = "three", mediators = "none")),
    c("compare", "w_main"), "w_main", list())
  expect_true(exp$experiment)
  expect_identical(vapply(exp$analyses, function(a) a$effect, ""), c("main_effect_A", "main_effect_B"))
  mixed <- whole_study_plan(tree, list(x = "within3", outcome = "score", mediators = "none", moderator = "two", covariate = "none",
    times = "many_conditions"), c("compare", "w_main"), "compare", list())
  expect_identical(vapply(mixed$analyses, function(a) a$effect, ""), c("main_effect_B", "main_effect_A"))
  expect_match(whole_study_experiment_label("w_main", c(X = "Task", W = "Group", Y = "Score")), "The main effect of Group", fixed = TRUE)
})
