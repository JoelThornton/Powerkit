test_that("new all-test plans do not assume independent significance decisions", {
  fields <- form_fields(claim_groups("all", 2))
  dependence <- Filter(function(f) identical(f$id, "all_dependence"), fields)[[1]]
  expect_identical(dependence$default, "unknown")
  expect_true(dependence$required)
  expect_true("all_dependence" %in% names(form_problems(list(dependence), list(claim="all",goal="sample_size",all_dependence=""))))
  expect_length(form_problems(list(dependence), list(claim="one",goal="sample_size")), 0)
  expect_equal(claim_power(.8, list(claim = "all", n_tests = 2, all_dependence = dependence$default)), .9)
  legacy <- legacy_claim_values(list(claim = "all", n_tests = 2))
  expect_identical(legacy$all_dependence, "independent")
  expect_equal(claim_power(.8, legacy), sqrt(.8))
  expect_identical(legacy_claim_values(list(claim = "all", all_dependence = "unknown"))$all_dependence, "unknown")
  expect_null(legacy_claim_values(list(claim = "one"))$all_dependence)
  calc <- list(status = "ok", route = list(form_values = list(claim = "all", n_tests = "2")))
  expect_true(calculation_matches_values(calc, list(claim = "all", n_tests = "2", all_dependence = "independent")))
  expect_false(calculation_matches_values(calc, list(claim = "all", n_tests = "2", all_dependence = "unknown")))
})

test_that("the known corrected-ANOVA discrepancy is explicit without a universal bound", {
  spec <- list(design = "factorial_anova", template = "mixed", target_test = list(method = "anova_f", correction = "GG"))
  expect_match(gg_planning_note(spec), ".231 versus .218", fixed = TRUE)
  expect_match(gg_planning_note(spec), "not a general error bound", fixed = TRUE)
  spec$target_test$correction <- "HF"
  expect_match(gg_planning_note(spec), "not been verified as a remedy", fixed = TRUE)
  spec$target_test$correction <- "none"
  expect_null(gg_planning_note(spec))
})

test_that("interaction verification retains assumptions and only offers the supported route", {
  calc <- list(status = "ok", spec = list(design = "regression_interaction", template = "two_way",
    population = list(metric = "correlation"), goal = list(n = 300)),
    result = list(sensitivity = list(approximation = TRUE, effect = .1873484)))
  original <- list(goal = "sensitivity", n = "300", r_XW_Y = ".1", r_X_Y = ".2",
    r_W_Y = ".15", r_X_W = ".1", rel_X = ".8", rel_W = ".85", alpha = ".05", just_source = "Prior study")
  values <- interaction_verification_values(calc, original)
  expect_identical(values$goal, "power")
  expect_equal(as.numeric(values$r_XW_Y), .1873484)
  keep <- setdiff(names(original), c("goal", "r_XW_Y"))
  expect_identical(values[keep], original[keep])
  calc$spec$template <- "three_way"
  expect_null(interaction_verification_values(calc, original))
  calc$spec$template <- "two_way"; calc$spec$population$metric <- "r2_change"
  expect_null(interaction_verification_values(calc, original))
})

test_that("corrected count search uncertainty and verification preserve the analysis", {
  calc <- list(status="ok", spec=list(design="basic_test",template="two_proportions",
    target_test=list(method="z_test_corrected")),result=list(goal_type="sample_size",n_required=list(n=362)))
  values <- list(goal="sample_size",p1=".5",p2=".65",method="z_test_corrected",allocation_ratio="1")
  next_values <- corrected_count_verification_values(calc,values)
  expect_identical(next_values$n,"362")
  expect_identical(next_values$goal,"power")
  expect_identical(next_values$method,values$method)
  expect_match(corrected_count_search_note(calc$spec,calc$result),"can fall below the target",fixed=TRUE)
  calc$result$goal_type <- "power"
  expect_null(corrected_count_search_note(calc$spec,calc$result))
  expect_null(corrected_count_verification_values(calc,values))
})

test_that("fresh count confirmations are distinguished from old fitted estimates in results and methods", {
  fields <- form_fields(form_groups(forms, "E5"))
  values <- form_examples$E5
  values$method <- "z_test_corrected"
  values$goal <- "sample_size"
  spec <- build_spec(forms, "E5", fields, values)
  result <- list(goal_type = "sample_size", provenance = list(method = "simulation", nrep = 1000),
    n_required = list(n = 382, lower = NA_real_, upper = NA_real_, power = .83,
      power_lower = .815, verification = list(nrep = 10000, lower = .815)))
  expect_match(goal_sentences(spec, result)[["headline"]], "checked sample size", fixed = TRUE)
  expect_false(grepl("95% interval", goal_sentences(spec, result)[["detail"]], fixed = TRUE))
  expect_match(actual_power_sentence(spec, result), "fresh simulated power", fixed = TRUE)
  note <- corrected_count_search_note(spec, result)
  expect_match(note, "up to ten candidate checks", fixed = TRUE)
  expect_match(note, "wrong assumptions", fixed = TRUE)
  expect_false(grepl("curve fitted", actual_power_sentence(spec, result), fixed = TRUE))
  expect_match(as.character(planning_warnings_ui(spec, result)), "fresh simulation check", fixed = TRUE)
})

test_that("a confirmed count result retains the check in the complete result and all writeups", {
  fields <- form_fields(form_groups(forms, "E5"))
  values <- modifyList(form_examples$E5, list(method = "z_test_corrected", goal = "sample_size",
    p1 = ".2", p2 = ".8", power = ".8", attrition = ".1"))
  spec <- build_spec(forms, "E5", fields, values)
  spec$options$nrep <- 1000L
  result <- suppressWarnings(powerkit::run_spec(spec))
  html <- as.character(result_panel_ui(tree, forms, "E5", fields, values,
    list(status = "ok", spec = spec, result = result)))
  expect_match(html, "checked sample size", fixed = TRUE)
  expect_false(grepl("95% interval for the required N", html, fixed = TRUE))
  text <- writeup_text(forms$forms$E5, spec, result, fields, values)
  for (version in c("short", "full", "ethics")) {
    expect_match(text[[version]], "fresh simulation check", fixed = TRUE, info = version)
    expect_match(text[[version]], "wrong assumptions", fixed = TRUE, info = version)
    expect_match(text[[version]], "recruitment buffer", fixed = TRUE, info = version)
    expect_false(grepl("95% interval for the required sample size", text[[version]], fixed = TRUE))
  }
})

test_that("attrition and pilot guidance do not imply missing-data modelling or automatic effect shrinkage", {
  expect_null(attrition_planning_note(list(options = list(attrition = 0))))
  expect_null(attrition_planning_note(list()))
  expect_match(attrition_planning_note(list(options = list(attrition = .2))),
    "does not model", fixed = TRUE)
  fields <- form_fields(form_groups(forms, "E2"))
  attrition <- Filter(function(f) identical(f$id, "attrition"), fields)[[1]]
  adjustment <- Filter(function(f) identical(f$id, "just_adjustment"), fields)[[1]]
  expect_null(attrition$default)
  expect_match(attrition$help, "compare plausible loss rates", fixed = TRUE)
  expect_match(adjustment$help, "do not automatically halve", fixed = TRUE)
  expect_false(grepl("pilots because they are small", adjustment$help, fixed = TRUE))
})
