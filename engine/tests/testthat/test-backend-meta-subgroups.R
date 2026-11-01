# A planned meta-analysis of subgroups (meta_analysis / subgroups, E66):
# does the average effect differ between kinds of studies?

subgroup_spec <- function(..., test = NULL, model = "random", goal = list(type = "power", n = 20L)) {
  spec <- example_spec("meta_subgroups")
  # Assigned one by one: utils::modifyList() leaves an unnamed list (the
  # effects) as it was.
  values <- list(...)
  for (key in names(values)) spec$population[[key]] <- values[[key]]
  spec$target_test$model <- model
  spec$target_test$test <- test
  spec$goal <- goal
  spec$options <- if (hartung_knapp_test(spec)) list(nrep = 200L, seed = 5L) else NULL
  spec
}

test_that("the z test and the fixed-effect model are metapower's mod_power(), as a direct call gives", {
  direct <- metapower::mod_power(n_groups = 2, effect_sizes = c(0.2, 0.5), study_size = 40, k = 20, i2 = 0.5, es_type = "d")$mod_power
  random <- run_spec(subgroup_spec(test = "z"))
  expect_equal(random$curve$power, direct$random_power_b)
  expect_true(all(random$check_run$ok))
  fixed <- run_spec(subgroup_spec(model = "fixed"))
  expect_equal(fixed$curve$power, direct$fixed_power_b)
  expect_identical(fixed$provenance$backend_function, "metapower::mod_power")
})

test_that("the random-effects model defaults to the Hartung-Knapp test of the moderator, simulated with metafor", {
  result <- suppressWarnings(run_spec(subgroup_spec()))
  expect_identical(result$provenance$backend, "Spower")
  expect_match(result$provenance$backend_function, "test = \"knha\"", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  # The experiment is metafor's Hartung-Knapp test of the kinds.
  set.seed(3)
  p <- p_meta_hk_mod(20, c(0.2, 0.5), 0.1, 0.1)
  set.seed(3)
  kind <- rep(1:2, each = 10)
  yi <- stats::rnorm(20, stats::rnorm(20, c(0.2, 0.5)[kind], sqrt(0.1)), sqrt(0.1))
  expect_equal(p, metafor::rma(yi = yi, vi = rep(0.1, 20), mods = ~ factor(kind), method = "DL", test = "knha")$QMp)
})

test_that("subgroup specs need whole kinds of study, a two-sided test and different effects", {
  expect_spec_problem(subgroup_spec(test = "z", goal = list(type = "power", n = 21L)), "split equally")
  one <- subgroup_spec(test = "z")
  one$target_test$alternative <- "greater"
  expect_spec_problem(one, "no direction")
  same <- subgroup_spec(effects = list(0.3, 0.3), test = "z", goal = list(type = "sample_size", power = 0.8))
  expect_error(validate_spec(same), class = "powerkit_spec_error")
  expect_spec_problem(subgroup_spec(metric = "r", effects = list(0.2, 1.1), test = "z"), "between -1 and 1")
})

test_that("the exported scripts reproduce the results with metapower, or Spower and metafor, alone", {
  spec <- subgroup_spec(test = "z")
  expect_script_reproduces_power(spec, run_spec(spec))
  hk <- subgroup_spec(goal = list(type = "power", n = 12L))
  expect_script_reproduces_power(hk, suppressWarnings(run_spec(hk)))
})
