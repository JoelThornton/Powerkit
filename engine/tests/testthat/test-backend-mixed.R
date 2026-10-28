# Mixed ANOVA beyond 2 x 2 (template mixed): one between-participants factor
# by one within-participants factor, at least one with three or more
# levels (for example group by time with three timepoints), Superpower's
# "kb*mw" design with sphericity assumed. Checked against Superpower called
# directly, from inputs written out by hand here.

mixed_example <- function(goal, effect = "interaction", ...) {
  spec <- small_run_spec("anova_mixed", goal = goal, ...)
  spec$target_test$effect <- effect
  spec
}

# The example's cell means, in Superpower's order a1_b1, a1_b2, a1_b3, a2_b1, ...
example_mu <- c(20, 16, 15, 20, 19, 18.5)

test_that("the mixed design runs on Superpower, exactly, and passes its check run", {
  result <- run_spec(mixed_example(list(type = "power", n = 60)))
  expect_equal(result$provenance$backend, "Superpower")
  expect_equal(result$provenance$method, "exact")
  expect_true(all(result$check_run$ok))
  # Six cells (a mean and an SD each) and three correlations in each group.
  expect_equal(nrow(result$check_run), 6 * 2 + 3 * 2)
})

test_that("each effect equals Superpower's ANOVA_exact() called directly", {
  design <- Superpower::ANOVA_design(
    design = "2b*3w", n = 30, mu = example_mu, sd = 6, r = 0.5, plot = FALSE
  )
  set.seed(7)
  direct <- Superpower::ANOVA_exact(design, alpha_level = 0.05, verbose = FALSE)$main_results
  rows <- c(main_effect_A = "a", main_effect_B = "b", interaction = "a:b")
  for (effect in names(rows)) {
    power <- run_spec(mixed_example(list(type = "power", n = 60), effect = effect))$curve$power
    expect_equal(power, direct[rows[[effect]], "power"] / 100, label = effect)
  }
})

test_that("three groups by two timepoints is read row by row", {
  spec <- mixed_example(list(type = "power", n = 90))
  spec$variables$A$levels <- list("Therapy", "Exercise", "Waiting list")
  spec$variables$B$levels <- list("Before", "After")
  spec$population$means <- list(list(20, 15), list(20, 17), list(20, 19.5))
  result <- run_spec(spec)
  expect_true(all(result$check_run$ok))
  design <- Superpower::ANOVA_design(
    design = "3b*2w", n = 30, mu = c(20, 15, 20, 17, 20, 19.5), sd = 6, r = 0.5, plot = FALSE
  )
  set.seed(7)
  direct <- Superpower::ANOVA_exact(design, alpha_level = 0.05, verbose = FALSE)
  expect_equal(result$curve$power, direct$main_results["a:b", "power"] / 100)
})

test_that("the mixed design finds a sample size in whole groups", {
  result <- run_spec(mixed_example(list(type = "sample_size", power = 0.8)))
  n <- result$n_required$n
  expect_equal(n %% 2, 0)
  below <- run_spec(mixed_example(list(type = "power", n = n - 2)))$curve$power
  at <- run_spec(mixed_example(list(type = "power", n = n)))$curve$power
  expect_lt(below, 0.8)
  expect_gte(at, 0.8)
})

test_that("the mixed design simulates with ANOVA_power() on request", {
  result <- run_spec(mixed_example(list(type = "power", n = 60), method = "simulation", nrep = 100))
  expect_equal(result$provenance$method, "simulation")
  expect_gt(result$curve$mcse, 0)
})

test_that("the mixed design refuses plainly what it can't do", {
  spec <- example_spec("anova_mixed")
  spec$population$means <- list(list(20, 16), list(20, 19))
  expect_spec_problem(spec, "should have 2 rows (one per level of Group (A)), each with 3 means")
  spec <- example_spec("anova_mixed")
  spec$variables$B$levels <- list("Before", "After")
  spec$population$means <- list(list(20, 16), list(20, 19))
  expect_spec_problem(spec, "use the template '2x2_mixed'")
  spec <- example_spec("anova_mixed")
  spec$goal <- list(type = "power", n = 61)
  expect_spec_problem(spec, "split into 2 equal groups")
})

test_that("the mixed design: the exported Superpower script reproduces powerkit (exact)", {
  skip_unless_scripts_can_run()
  spec <- mixed_example(list(type = "power", n = 60))
  expect_script_reproduces_power(spec, run_spec(spec))
})
