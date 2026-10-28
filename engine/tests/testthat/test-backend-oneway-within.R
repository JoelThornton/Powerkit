# One-way repeated-measures ANOVA (template oneway_within): one
# within-participants factor with three or more levels, Superpower's "kw"
# design, the omnibus F test with sphericity assumed. Checked against
# Superpower called directly, from inputs written out by hand here.

within_example <- function(goal, ...) {
  small_run_spec("anova_oneway_within", goal = goal, ...)
}

test_that("one-way within runs on Superpower, exactly, and passes its check run", {
  result <- run_spec(within_example(list(type = "power", n = 30)))
  expect_equal(result$provenance$backend, "Superpower")
  expect_equal(result$provenance$method, "exact")
  expect_equal(result$curve$mcse, 0)
  expect_true(all(result$check_run$ok))
  # Three means, three SDs and the three pairwise correlations.
  expect_equal(nrow(result$check_run), 9)
  expect_true(all(grepl("condition", result$check_run$parameter)))
})

test_that("one-way within equals Superpower's ANOVA_exact() called directly", {
  # Example: means 600, 620, 650 ms; SD 100; r = 0.6; 30 participants.
  power <- run_spec(within_example(list(type = "power", n = 30)))$curve$power
  design <- Superpower::ANOVA_design(
    design = "3w", n = 30, mu = c(600, 620, 650), sd = 100, r = 0.6, plot = FALSE
  )
  set.seed(7)
  direct <- Superpower::ANOVA_exact(design, alpha_level = 0.05, verbose = FALSE)
  expect_equal(power, direct$main_results["a", "power"] / 100)
})

test_that("one-way within agrees with Superpower's analytic power_oneway_within()", {
  # A second route inside Superpower: the noncentral F with the
  # within-participant error term, from the same design object.
  power <- run_spec(within_example(list(type = "power", n = 30)))$curve$power
  design <- Superpower::ANOVA_design(
    design = "3w", n = 30, mu = c(600, 620, 650), sd = 100, r = 0.6, plot = FALSE
  )
  analytic <- Superpower::power_oneway_within(design, alpha_level = 0.05)$power / 100
  expect_equal(power, analytic, tolerance = 1e-6)
})

test_that("a higher correlation between conditions gives more power", {
  at_r <- function(r) {
    spec <- within_example(list(type = "power", n = 30))
    spec$population$r <- r
    run_spec(spec)$curve$power
  }
  expect_lt(at_r(0.3), at_r(0.6))
  expect_lt(at_r(0.6), at_r(0.8))
})

test_that("one-way within finds a sample size, in single participants", {
  result <- run_spec(within_example(list(type = "sample_size", power = 0.8)))
  n <- result$n_required$n
  expect_true(is.numeric(n) && n >= 5)
  below <- run_spec(within_example(list(type = "power", n = n - 1)))$curve$power
  at <- run_spec(within_example(list(type = "power", n = n)))$curve$power
  expect_lt(below, 0.8)
  expect_gte(at, 0.8)
})

test_that("one-way within simulates with ANOVA_power() on request", {
  result <- run_spec(within_example(list(type = "power", n = 30), method = "simulation", nrep = 100))
  expect_equal(result$provenance$method, "simulation")
  expect_gt(result$curve$mcse, 0)
})

test_that("one-way within refuses plainly what it can't do", {
  spec <- example_spec("anova_oneway_within")
  spec$population$means <- list(600, 620)
  expect_spec_problem(spec, "'population > means' needs at least 3 entries")
  spec <- example_spec("anova_oneway_within")
  spec$population$r <- NULL
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  spec <- example_spec("anova_oneway_within")
  spec$goal <- list(type = "power", n = 4)
  expect_spec_problem(spec, "needs at least 5 participants")
})

test_that("one-way within: the exported Superpower script reproduces powerkit (exact)", {
  skip_unless_scripts_can_run()
  spec <- within_example(list(type = "power", n = 30))
  expect_script_reproduces_power(spec, run_spec(spec))
})
