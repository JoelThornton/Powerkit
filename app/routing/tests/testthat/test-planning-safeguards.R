test_that("new all-test plans do not assume independent significance decisions", {
  fields <- form_fields(claim_groups("all", 2))
  dependence <- Filter(function(f) identical(f$id, "all_dependence"), fields)[[1]]
  expect_identical(dependence$default, "unknown")
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
