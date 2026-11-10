test_that("OLS bootstrap is explicit, legacy methods retain their defaults", {
  spec <- process_bootstrap_spec("mediation_simple")
  inputs <- power4mome_inputs(spec)
  expect_identical(inputs$fit_function, "lm")
  expect_identical(inputs$ci_type, "boot")
  expect_false(inputs$test_args$mc_ci)
  expect_true(inputs$test_args$boot_ci)
  expect_identical(inputs$test_args$test_method, "ci")
  expect_identical(default_ci_draws("ols_percentile_bootstrap"), 5000L)
  expect_identical(default_ci_draws(), 1000L)
  expect_identical(default_ci_draws("percentile_bootstrap"), 1000L)
  spec$options$ci_draws <- NULL
  expect_equal(power4mome_inputs(spec)$ci_draws, 5000)
  expect_equal(mediation_analysis_record(spec)$draws, 5000)
  expect_true("lmhelprs" %in% route_spec(spec)$packages)
  old <- spec; old$target_test$method <- "percentile_bootstrap"
  expect_identical(power4mome_inputs(old)$fit_function, "lavaan")
  expect_equal(power4mome_inputs(old)$ci_draws, 1000)
})

test_that("OLS bootstrap coefficients, intervals and decisions match independent equation fits", {
  skip_if_not_installed("lmhelprs", "0.4.2")
  skip_if_not_installed("boot")
  cases <- c("mediation_simple", "mediation_parallel", "mediation_serial", "process_7",
    "process_14", "process_7_parallel", "process_8", "process_58", "process_59")
  for (name in cases) {
    spec <- process_bootstrap_spec(name)
    inputs <- power4mome_inputs(spec)
    object <- power4mome_call(inputs, 100, 2, 72411, R = inputs$ci_draws, ci_type = "boot",
      test_fun = power4mome_test_fun(inputs$test_name), test_args = inputs$test_args)
    for (study in object[[1]]) {
      expect_s3_class(study$extra$fit, "lm_list_lmhelprs")
      ref <- process_reference_interval(study$mm_lm_dat_out, inputs, study$extra$boot_out)
      actual <- do.call(power4mome_test_fun(inputs$test_name), c(list(fit = study$extra$fit,
        boot_out = study$extra$boot_out), inputs$test_args))
      expect_equal(unname(actual["est"]), ref$estimate, tolerance = 1e-10, label = name)
      expect_equal(unname(actual[c("cilo", "cihi")]), unname(ref$ci), tolerance = 1e-10, label = name)
      expect_equal(unname(actual["sig"]), ref$significant, label = name)
    }
  }
})

test_that("OLS bootstrap exports reproduce the selected analysis without powerkit", {
  skip_on_cran()
  skip_if_not_installed("lmhelprs", "0.4.2")
  spec <- process_bootstrap_spec("mediation_simple")
  spec$goal <- list(type = "power", n = 80L)
  result <- run_quietly(spec)
  expect_true(result$mediation_analysis$process_style)
  expect_match(result$provenance$backend_function, "OLS; casewise percentile bootstrap", fixed = TRUE)
  reproduced <- run_exported_script(spec, result)
  expect_true(any(grepl('fit_function = "lm"', reproduced$script, fixed = TRUE)))
  expect_equal(reproduced$reproduced$power, result$curve$power[1])
  expect_false(any(grepl("library(powerkit)", reproduced$script, fixed = TRUE)))
})

test_that("a local OLS bootstrap script saves a reopenable app project", {
  skip_on_cran()
  skip_if_not_installed("lmhelprs", "0.4.2")
  spec <- process_bootstrap_spec("mediation_simple")
  spec$goal <- list(type = "power", n = 80L)
  route <- list(app = "routing-prototype", endpoint = "E16", route = "choose",
    form_values = list(method = "ols_percentile_bootstrap", ci_draws = 100,
      p_X_M = -.25, p_M_Y = -.3, p_X_Y = .1, goal = "power", n = 80, alpha = .05))
  out <- run_exported_run_script(spec, route = route)
  expect_equal(out$project$route, route)
  expect_identical(out$project$spec$target_test$method, "ols_percentile_bootstrap")
  expect_equal(out$project$result$mediation_analysis$draws, 100)
  expect_true(isTRUE(out$project$result$mediation_analysis$process_style))
  expect_equal(saved_result(out$project)$mediation_analysis, out$result$mediation_analysis)
  expect_true(out$files[["powerkit-reproduce.R"]])
})
