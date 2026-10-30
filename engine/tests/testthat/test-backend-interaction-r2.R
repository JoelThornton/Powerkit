r2_spec <- function(r2_change, r2_main = NULL, goal = list(type = "power", n = 200L)) {
  spec <- example_spec("regression_interaction")
  spec$population <- c(list(metric = "r2_change", r2_change = r2_change), if (!is.null(r2_main)) list(r2_main = r2_main))
  for (v in c("X", "W", "Y")) spec$variables[[v]]$reliability <- NULL
  spec$goal <- goal
  spec
}

# r(X,Y) = r(W,Y) = r(X,W) = .2, r(XW,Y) = .15: the product is uncorrelated
# with X and W, so its R-squared change is .15^2 = .0225, over the main
# effects' (.04 + .04 - 2 * .2 * .2 * .2) / (1 - .2^2) = .0667.
r2_main_example <- (0.04 + 0.04 - 2 * 0.2 * 0.2 * 0.2) / (1 - 0.2^2)

test_that("an interaction given by its R-squared change runs on pwrss's power.f.regression(), as a direct call does", {
  result <- run_spec(r2_spec(0.0225, r2_main_example))
  expect_identical(result$provenance$backend_function, "pwrss::power.f.regression")
  expect_true(all(result$check_run$ok))
  direct <- pwrss::power.f.regression(r.squared.change = 0.0225 / (1 - r2_main_example), k.total = 3, k.tested = 1,
    n = 200, alpha = 0.05, verbose = 0)
  expect_equal(result$curve$power, direct$power)
  # Without the main effects' R-squared: a smaller f^2, so less power.
  expect_lt(run_spec(r2_spec(0.0225))$curve$power, result$curve$power)
})

test_that("the R-squared change gives G*Power's fixed-model power, a little above InteractionPoweR's formula", {
  # Known difference 7 (docs/conventions.md): its size at three sample sizes.
  for (n in c(100L, 200L, 400L)) {
    ours <- run_spec(r2_spec(0.0225, r2_main_example, goal = list(type = "power", n = n)))$curve$power
    theirs <- InteractionPoweR::power_interaction_r2(N = n, r.x1.y = 0.2, r.x2.y = 0.2, r.x1x2.y = 0.15, r.x1.x2 = 0.2)$pwr
    expect_gt(ours, theirs, label = n)
    expect_lt(ours - theirs, 0.02, label = n)
  }
  expect_equal(run_spec(r2_spec(0.0225, r2_main_example))$curve$power, 0.5994, tolerance = 1e-3)
  expect_equal(InteractionPoweR::power_interaction_r2(N = 200, r.x1.y = 0.2, r.x2.y = 0.2, r.x1x2.y = 0.15, r.x1.x2 = 0.2)$pwr,
    0.5827, tolerance = 1e-3)
})

test_that("the R-squared change route refuses what needs the correlations", {
  with_rel <- r2_spec(0.02)
  with_rel$variables$X$reliability <- 0.8
  expect_spec_problem(with_rel, "Reliability is used with the correlations")
  binary <- r2_spec(0.02)
  binary$variables$X <- list(type = "binary", label = "Condition", levels = list("A", "B"))
  expect_error(validate_spec(binary), class = "powerkit_spec_error")
  expect_spec_problem(r2_spec(0.5, 0.6), "must be below 1")
  expect_false(simulated_data_available(r2_spec(0.02)))
})

test_that("the exported script reproduces the result", {
  skip_unless_scripts_can_run()
  spec <- validate_spec(r2_spec(0.0225, r2_main_example))
  expect_script_reproduces_power(spec, run_for_export(spec))
})
