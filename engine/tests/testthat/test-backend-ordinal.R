# An ordinal outcome in two groups, by powertools::propodds()
# (proportional odds, Whitehead's method).

ordinal_spec <- function(goal = list(type = "power", n = 200), ...) {
  spec <- example_spec("ordinal_two_groups")
  spec$goal <- goal
  values <- list(...)
  for (k in names(values)) spec$population[[k]] <- values[[k]]
  spec
}

test_that("power is powertools' propodds(), with group 1's size and the ratio", {
  result <- run_spec(ordinal_spec())
  expect_equal(result$provenance$backend_function, "powertools::propodds")
  # An odds ratio of 0.5 is passed as 2: power is the same either way.
  expect_equal(result$curve$power, powertools::propodds(pC = c(0.1, 0.3, 0.4, 0.2), OR = 2, n1 = 100))
  expect_equal(run_spec(ordinal_spec(odds_ratio = 2))$curve$power, result$curve$power)
  expect_true(all(result$check_run$ok))
})

test_that("unequal groups use powertools' n.ratio", {
  spec <- ordinal_spec(goal = list(type = "power", n = 300))
  spec$options$allocation_ratio <- 2
  expect_equal(
    run_spec(spec)$curve$power,
    powertools::propodds(pC = c(0.1, 0.3, 0.4, 0.2), OR = 2, n1 = 100, n.ratio = 2)
  )
})

test_that("the required n is the first total whose power reaches the target", {
  result <- run_spec(ordinal_spec(list(type = "sample_size", power = 0.8)))
  n <- result$n_required$n
  power_at <- function(n) {
    n1 <- round(n / 2)
    powertools::propodds(pC = c(0.1, 0.3, 0.4, 0.2), OR = 2, n1 = n1, n.ratio = (n - n1) / n1)
  }
  expect_gte(power_at(n), 0.8)
  expect_lt(power_at(n - 1), 0.8)
})

test_that("shares that don't fit the categories, or don't sum to 1, and no effect are refused", {
  expect_spec_problem(ordinal_spec(probabilities = list(0.2, 0.3, 0.5)), "has 3 values")
  expect_spec_problem(ordinal_spec(probabilities = list(0.2, 0.3, 0.4, 0.2)), "add up to 1")
  expect_spec_problem(ordinal_spec(list(type = "sample_size", power = 0.8), odds_ratio = 1), "zero", fixed = TRUE)
})

test_that("the exported script reproduces the result", {
  skip_on_cran()
  for (goal in list(list(type = "power", n = 200), list(type = "sample_size", power = 0.8))) {
    spec <- ordinal_spec(goal)
    result <- run_spec(spec)
    out <- run_exported_script(spec, result)
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10, label = goal$type)
  }
})
