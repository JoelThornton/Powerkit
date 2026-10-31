# A planned meta-analysis (design meta_analysis, template mean_effect):
# metapower's mpower(), with n the number of studies.

meta_spec <- function(..., goal = list(type = "power", n = 20L)) {
  spec <- example_spec("meta_mean_effect")
  spec$population <- utils::modifyList(spec$population, list(...))
  spec$goal <- goal
  spec
}

test_that("a meta-analysis runs on metapower's mpower(), as a direct call does", {
  for (model in c("random", "fixed")) {
    spec <- meta_spec()
    spec$target_test$model <- model
    result <- run_spec(spec)
    expect_identical(result$provenance$backend_function, "metapower::mpower")
    expect_true(all(result$check_run$ok), label = model)
    direct <- metapower::mpower(effect_size = 0.15, study_size = 40, k = 20, i2 = 0.5, es_type = "d")$power
    expect_equal(result$curve$power, if (model == "fixed") direct$fixed_power else direct$random_power, label = model)
  }
})

test_that("the number of studies needed is the smallest k reaching the target power", {
  spec <- meta_spec(goal = list(type = "sample_size", power = 0.8))
  k <- run_spec(spec)$n_required$n
  power <- function(k) metapower::mpower(effect_size = 0.15, study_size = 40, k = k, i2 = 0.5, es_type = "d")$power$random_power
  expect_gte(power(k), 0.8)
  expect_lt(power(k - 1), 0.8)
})

test_that("a negative effect gives the power of its size, and a one-sided test runs its way", {
  spec <- meta_spec(effect = -0.15)
  spec$target_test$alternative <- "less"
  pos <- meta_spec()
  pos$target_test$alternative <- "greater"
  expect_equal(run_spec(spec)$curve$power, run_spec(pos)$curve$power)
  spec$target_test$alternative <- "greater"
  expect_spec_problem(spec, "direction of the expected effect")
})

test_that("a meta-analysis refuses an impossible r, odd study sizes for d, and sensitivity", {
  expect_spec_problem(meta_spec(metric = "r", effect = 1.2), "between -1 and 1")
  expect_spec_problem(meta_spec(study_size = 41L), "must be even")
  expect_spec_problem(meta_spec(goal = list(type = "sensitivity", n = 20L, power = 0.8)), "smallest detectable")
})

test_that("metapower rounds Fisher's z to two decimals: the size of the difference (Known difference 9)", {
  # r = 0.25 in 5 studies of 30, I-squared 0: metapower works with
  # z = 0.26 instead of 0.2554, the largest difference over r .05 to .3,
  # 30 to 100 per study, 5 to 20 studies and I-squared 0 to .75
  # (docs/conventions.md): fixed-effect power 85.6% against 84.3% with the
  # exact z.
  spec <- meta_spec(metric = "r", effect = 0.25, study_size = 30L, i2 = 0, goal = list(type = "power", n = 5L))
  spec$target_test$model <- "fixed"
  rounded <- run_spec(spec)$curve$power
  ncp <- atanh(0.25) / sqrt(1 / (27 * 5))
  exact <- stats::pnorm(ncp - stats::qnorm(0.975)) + stats::pnorm(-stats::qnorm(0.975) - ncp)
  expect_equal(round(c(rounded, exact), 3), c(0.856, 0.843))
})

test_that("the exported script reproduces the result with metapower alone", {
  spec <- meta_spec()
  expect_script_reproduces_power(spec, run_spec(spec))
  spec <- meta_spec(goal = list(type = "sample_size", power = 0.8))
  result <- run_spec(spec)
  run <- run_exported_script(spec, result)
  expect_equal(run$reproduced$n, result$n_required$n)
})
