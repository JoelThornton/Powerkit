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
  # An odds ratio of 0.5 (group 2 lower) is passed as 2 with the shares as
  # given, so powertools shifts group 2 towards the lowest category.
  expect_equal(result$curve$power, powertools::propodds(pC = c(0.1, 0.3, 0.4, 0.2), OR = 2, n1 = 100))
  # An odds ratio of 2 (group 2 higher) passes the shares highest first.
  expect_equal(run_spec(ordinal_spec(odds_ratio = 2))$curve$power, powertools::propodds(pC = c(0.2, 0.4, 0.3, 0.1), OR = 2, n1 = 100))
  expect_true(all(result$check_run$ok))
})

test_that("group 2 is shifted the way the odds ratio says, which matters when the shares are uneven", {
  # Whitehead's variance uses the two groups' average shares, so the same
  # odds ratio has more power when it spreads the answers out. Group 1
  # mostly in the lowest category: group 2 higher (2.5) spreads them out,
  # group 2 lower (0.4) bunches them further.
  shares <- list(0.7, 0.2, 0.1)
  spec_up <- ordinal_spec(probabilities = shares, odds_ratio = 2.5, goal = list(type = "power", n = 100))
  spec_up$variables$Y$levels <- list("Low", "Middle", "High")
  spec_down <- spec_up
  spec_down$population$odds_ratio <- 0.4
  up <- run_spec(spec_up)$curve$power
  down <- run_spec(spec_down)$curve$power
  expect_equal(up, powertools::propodds(pC = c(0.1, 0.2, 0.7), OR = 2.5, n1 = 50))
  expect_equal(down, powertools::propodds(pC = c(0.7, 0.2, 0.1), OR = 2.5, n1 = 50))
  expect_gt(up, down + 0.1)
  # Against a simulation of the same population: group 2's shares by
  # proportional odds (Hmisc's pomodm(), as in the simulated-data export),
  # tested with the Wilcoxon-Mann-Whitney test, the proportional-odds score
  # test's two-group form. 4,000 studies: Monte Carlo SE about 0.008.
  skip_on_cran()
  simulated <- function(odds_ratio) {
    p1 <- c(0.7, 0.2, 0.1)
    p2 <- Hmisc::pomodm(p = p1, odds.ratio = odds_ratio)
    withr::with_seed(2026, mean(replicate(4000, {
      a <- sample.int(3, 50, TRUE, p1)
      b <- sample.int(3, 50, TRUE, p2)
      suppressWarnings(stats::wilcox.test(a, b, exact = FALSE, correct = FALSE)$p.value) < 0.05
    })))
  }
  # Within 0.035 (Whitehead's approximation and the simulation's error);
  # passing the shares the wrong way round was off by about 0.15 here.
  expect_lt(abs(up - simulated(2.5)), 0.035)
  expect_lt(abs(down - simulated(0.4)), 0.035)
})

test_that("unequal groups use powertools' n.ratio", {
  spec <- ordinal_spec(goal = list(type = "power", n = 300))
  spec$options$allocation_ratio <- 2
  expect_equal(
    run_spec(spec)$curve$power,
    powertools::propodds(pC = c(0.1, 0.3, 0.4, 0.2), OR = 2, n1 = 100, n.ratio = 2)
  )
})

test_that("the required n is the first valid whole-group total whose power reaches the target", {
  result <- run_spec(ordinal_spec(list(type = "sample_size", power = 0.8)))
  n <- result$n_required$n
  power_at <- function(n) {
    n1 <- round(n / 2)
    powertools::propodds(pC = c(0.1, 0.3, 0.4, 0.2), OR = 2, n1 = n1, n.ratio = (n - n1) / n1)
  }
  expect_gte(power_at(n), 0.8)
  expect_equal(n %% 2, 0)
  expect_lt(power_at(n - 2), 0.8)
  # n - 1 changes the requested equal allocation; it is not a valid
  # competing sample size, even if its unbalanced formula has enough power.
  expect_error(run_spec(ordinal_spec(list(type = "power", n = n - 1))), "nearest")
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

test_that("the check run reads group 2's shares at full precision (audit, 19 November 2026)", {
  # Shares 0.005, 0.20, 0.795 with an odds ratio of 2: powertools prints
  # group 2's shares to 3 decimals, which can't show the odds ratio at the
  # first cut-point, and the check failed on a valid design.
  spec <- example_spec("ordinal_two_groups")
  spec$variables$Y$levels <- list("None", "Mild", "Moderate")
  spec$population$probabilities <- list(0.005, 0.2, 0.795)
  spec$population$odds_ratio <- 2
  spec$goal <- list(type = "power", n = 200L)
  check <- run_spec(validate_spec(spec))$check_run
  expect_true(all(check$ok))
  expect_equal(check$recovered[grepl("cut-point", check$parameter)], c(2, 2), tolerance = 1e-6)
})
