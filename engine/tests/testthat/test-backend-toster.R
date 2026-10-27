# Equivalence tests (design equivalence_test): the two one-sided tests
# (TOST) for two independent groups, paired data and one sample, by
# TOSTER::power_t_TOST(). Checked against TOSTER called directly, against
# a large-sample approximation written out in base R, and through the
# exported script.

tost_spec <- function(name, goal = NULL, population = NULL, options = list(seed = 7)) {
  spec <- example_spec(name)
  spec$options <- options
  if (!is.null(goal)) spec$goal <- goal
  if (!is.null(population)) spec$population <- population
  spec
}

test_that("each equivalence test gives TOSTER's power for the values in the spec", {
  ind <- run_spec(tost_spec("tost_independent", list(type = "power", n = 100)))
  expect_equal(ind$provenance$backend_function, "TOSTER::power_t_TOST")
  expect_equal(ind$provenance$method, "exact")
  expect_equal(ind$curve$power, TOSTER::power_t_TOST(n = 50, delta = 0, sd = 1, eqb = c(-0.5, 0.5), alpha = 0.05, type = "two.sample")$power)
  one <- run_spec(tost_spec("tost_one_sample"))
  expect_equal(one$curve$power, TOSTER::power_t_TOST(n = 120, delta = 0.1, sd = 1, eqb = c(-0.4, 0.4), alpha = 0.05, type = "one.sample")$power)
  # The paired example is in the outcome's own units: d_z = 5 / 60 and the
  # bound 25 / 60, both in SDs of the differences. TOSTER takes raw units
  # as well, so the same call in milliseconds must agree.
  pair <- run_spec(tost_spec("tost_paired", list(type = "power", n = 80)))
  expect_equal(pair$curve$power, TOSTER::power_t_TOST(n = 80, delta = 5, sd = 60, eqb = c(-25, 25), alpha = 0.05, type = "paired")$power)
  expect_equal(pair$effect_from_units$bound, 25)
  expect_equal(pair$effect_from_units$bound_value, 25 / 60)
})

test_that("the required n is the first size whose power reaches the target", {
  r <- run_spec(tost_spec("tost_independent"))
  n <- r$n_required$n
  expect_equal(n %% 2, 0)
  power_at <- function(total) TOSTER::power_t_TOST(n = total / 2, delta = 0, sd = 1, eqb = c(-0.5, 0.5), alpha = 0.05)$power
  expect_gte(power_at(n), 0.8)
  expect_lt(power_at(n - 2), 0.8)
  # TOSTER's own answer for the n per group, rounded up.
  expect_equal(n, 2 * ceiling(TOSTER::power_t_TOST(delta = 0, sd = 1, eqb = c(-0.5, 0.5), alpha = 0.05, power = 0.8)$n))
})

test_that("unequal groups pass both group sizes to TOSTER", {
  spec <- tost_spec("tost_independent", list(type = "power", n = 150), options = list(seed = 7, allocation_ratio = 2))
  r <- run_spec(spec)
  expect_equal(r$curve$power, TOSTER::power_t_TOST(n = c(50, 100), delta = 0, sd = 1, eqb = c(-0.5, 0.5), alpha = 0.05)$power)
})

test_that("TOSTER agrees with a large-sample approximation in base R", {
  # With many people, each one-sided t test is close to a z test, so
  # power is about pnorm((bound - delta) / se - z) + pnorm((bound + delta) / se - z) - 1.
  n <- 2000
  delta <- 0.05
  bound <- 0.1
  se <- sqrt(2 / (n / 2))
  z <- stats::qnorm(0.95)
  approx <- stats::pnorm((bound - delta) / se - z) + stats::pnorm((bound + delta) / se - z) - 1
  r <- run_spec(tost_spec("tost_independent", list(type = "power", n = n),
    population = list(metric = "standardised", d = delta, bound = bound)))
  expect_equal(r$curve$power, approx, tolerance = 0.005)
})

test_that("the check run confirms the effect and the bounds TOSTER receives", {
  r <- run_spec(tost_spec("tost_one_sample"))
  expect_true(all(r$check_run$ok))
  expect_equal(r$check_run$recovered, c(0.1, -0.4, 0.4))
})

test_that("attrition splits two groups as the analysis does", {
  r <- run_spec(tost_spec("tost_independent", options = list(seed = 7, attrition = 0.1)))
  expect_equal(r$recruitment$groups_analysed, rep(r$n_required$n / 2, 2))
})

test_that("plain-English refusals for equivalence specs", {
  outside <- tost_spec("tost_independent", population = list(metric = "standardised", d = 0.6, bound = 0.5))
  expect_spec_problem(outside, "larger than the equivalence bound")
  outside_power <- tost_spec("tost_one_sample", population = list(metric = "standardised", d = -0.5, bound = 0.4))
  expect_spec_problem(outside_power, "has to lie inside the bounds")
  no_bound <- tost_spec("tost_independent", population = list(metric = "standardised", d = 0))
  expect_error(validate_spec(no_bound), class = "powerkit_spec_error")
  sens <- tost_spec("tost_independent", list(type = "sensitivity", n = 100, power = 0.8))
  expect_error(validate_spec(sens), class = "powerkit_spec_error")
  one_sided <- tost_spec("tost_one_sample")
  one_sided$target_test$alternative <- "greater"
  expect_error(validate_spec(one_sided), class = "powerkit_spec_error")
  sim <- tost_spec("tost_one_sample", options = list(seed = 7, method = "simulation"))
  expect_error(validate_spec(sim), class = "powerkit_spec_error")
  allocation <- tost_spec("tost_paired", options = list(seed = 7, allocation_ratio = 2))
  expect_spec_problem(allocation, "only applies to two-group designs")
})

test_that("at the bound itself, power is about alpha, and no n is sought", {
  spec <- tost_spec("tost_independent", list(type = "power", n = 2000),
    population = list(metric = "standardised", d = 0.5, bound = 0.5))
  expect_equal(run_spec(spec)$curve$power, 0.05, tolerance = 0.01)
  at_bound <- tost_spec("tost_independent", population = list(metric = "standardised", d = -0.5, bound = 0.5))
  expect_spec_problem(at_bound, "as large as the equivalence bound")
})

test_that("the exported script reproduces each equivalence result", {
  skip_on_cran()
  for (name in c("tost_independent", "tost_paired", "tost_one_sample")) {
    spec <- tost_spec(name, options = example_spec(name)$options)
    result <- run_spec(spec)
    out <- run_exported_script(spec, result)
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10, label = name)
  }
})
