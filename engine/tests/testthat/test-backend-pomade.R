# A meta-analysis whose studies each give several correlated effects
# (meta_analysis / dependent_effects, E61): POMADE's power_MADE(), the CHE
# model with the RVE test.

pomade_spec <- function(..., goal = list(type = "power", n = 20L)) {
  spec <- example_spec("meta_dependent_effects")
  spec$population <- utils::modifyList(spec$population, list(...))
  spec$goal <- goal
  spec
}

test_that("power is POMADE's own, with metapower's sampling variance for a typical study", {
  spec <- validate_spec(pomade_spec())
  inputs <- pomade_inputs(spec)
  expect_equal(inputs$sigma2, 4 / 40 + 0.15^2 / 80)
  direct <- suppressWarnings(POMADE::power_MADE(J = 20, mu = 0.15, tau = 0.1, omega = 0.05, rho = 0.6, alpha = 0.05,
    model = "CHE", var_df = "RVE", sigma2_dist = inputs$sigma2, n_ES_dist = 4, warning = FALSE))$power
  result <- run_spec(spec)
  expect_equal(result$curve$power[result$curve$n == 20], direct, tolerance = 1e-10)
  expect_identical(result$provenance$backend, "POMADE")
  expect_true(all(result$check_run$ok))
})

test_that("more effects per study and less correlated ones give more power; r is analysed on Fisher's z", {
  power_of <- function(spec) {
    result <- run_spec(spec)
    result$curve$power[result$curve$n == spec$goal$n]
  }
  base <- power_of(pomade_spec())
  expect_gt(power_of(pomade_spec(effects_per_study = 8L)), base)
  expect_gt(power_of(pomade_spec(rho = 0.2)), base)
  r_spec <- pomade_spec(metric = "r", effect = 0.15, tau = 0.05, omega = 0.05)
  inputs <- pomade_inputs(validate_spec(r_spec))
  expect_equal(inputs$mu, atanh(0.15))
  expect_equal(inputs$sigma2, 1 / 37)
})

test_that("POMADE's test is two-sided, and an impossible correlation is refused", {
  one_sided <- pomade_spec()
  one_sided$target_test$alternative <- "greater"
  expect_spec_problem(one_sided, "two-sided")
  expect_error(validate_spec(pomade_spec(rho = 1)), class = "powerkit_spec_error")
})

test_that("the number of studies needed, and the exported script reproduces it with POMADE alone", {
  spec <- pomade_spec(goal = list(type = "sample_size", power = 0.8))
  result <- run_spec(spec)
  expect_identical(result$n_required$n, 31)
  expect_script_reproduces_power(pomade_spec(), run_spec(pomade_spec()))
})
