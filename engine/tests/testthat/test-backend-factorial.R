# Two-factor ANOVA with both factors between participants beyond 2 x 2
# (template factorial_between, Superpower's "kb*mb" design) or both within
# participants, 2 x 2 or larger (template factorial_within, "kw*mw", one
# correlation between every pair of cells, so sphericity holds). Checked
# against Superpower called directly, from inputs written out by hand here.

factorial_example <- function(name, goal, effect = "interaction", ...) {
  spec <- small_run_spec(name, goal = goal, ...)
  spec$target_test$effect <- effect
  spec
}
within_example <- function(goal, ...) factorial_example("anova_factorial_within", goal, ...)
between_example <- function(goal, ...) factorial_example("anova_factorial_between", goal, ...)

# The examples' cell means, in Superpower's order a1_b1, a1_b2, a1_b3, a2_b1, ...
within_mu <- c(400, 410, 420, 430, 450, 470)
between_mu <- c(0, 0, 0, 0.1, 0.3, 0.5)
rows <- c(main_effect_A = "a", main_effect_B = "b", interaction = "a:b")

test_that("both designs run on Superpower, exactly, and pass their check runs", {
  within <- run_spec(within_example(list(type = "power", n = 40)))
  expect_equal(within$provenance$backend, "Superpower")
  expect_equal(within$provenance$method, "exact")
  expect_true(all(within$check_run$ok))
  # Six cells (a mean and an SD each) and a correlation for each of the 15
  # pairs of cells.
  expect_equal(nrow(within$check_run), 6 * 2 + 15)
  between <- run_spec(between_example(list(type = "power", n = 120)))
  expect_true(all(between$check_run$ok))
  expect_equal(nrow(between$check_run), 6 * 2)
})

test_that("each effect of the within design equals Superpower's ANOVA_exact() called directly", {
  design <- Superpower::ANOVA_design(
    design = "2w*3w", n = 40, mu = within_mu, sd = 80, r = 0.6, plot = FALSE
  )
  set.seed(7)
  direct <- Superpower::ANOVA_exact(design, alpha_level = 0.05, verbose = FALSE)$main_results
  for (effect in names(rows)) {
    power <- run_spec(within_example(list(type = "power", n = 40), effect = effect))$curve$power
    expect_equal(power, direct[rows[[effect]], "power"] / 100, label = effect)
  }
})

test_that("each effect of the between design equals Superpower's ANOVA_exact() called directly", {
  design <- Superpower::ANOVA_design(
    design = "2b*3b", n = 20, mu = between_mu, sd = 1, plot = FALSE
  )
  set.seed(7)
  direct <- Superpower::ANOVA_exact(design, alpha_level = 0.05, verbose = FALSE)$main_results
  for (effect in names(rows)) {
    # n is the total: 20 in each of the six cells.
    power <- run_spec(between_example(list(type = "power", n = 120), effect = effect))$curve$power
    expect_equal(power, direct[rows[[effect]], "power"] / 100, label = effect)
  }
})

test_that("a 2 x 2 within design runs (it has no other template)", {
  spec <- within_example(list(type = "power", n = 30))
  spec$variables$B$levels <- list("Short", "Long")
  spec$population$means <- list(list(400, 420), list(430, 470))
  result <- run_spec(spec)
  expect_true(all(result$check_run$ok))
  design <- Superpower::ANOVA_design(
    design = "2w*2w", n = 30, mu = c(400, 420, 430, 470), sd = 80, r = 0.6, plot = FALSE
  )
  set.seed(7)
  direct <- Superpower::ANOVA_exact(design, alpha_level = 0.05, verbose = FALSE)
  expect_equal(result$curve$power, direct$main_results["a:b", "power"] / 100)
})

test_that("the sample size search: whole cells for the between design, any n for the within", {
  result <- run_spec(between_example(list(type = "sample_size", power = 0.8), effect = "main_effect_A"))
  n <- result$n_required$n
  expect_equal(n %% 6, 0)
  expect_lt(run_spec(between_example(list(type = "power", n = n - 6), effect = "main_effect_A"))$curve$power, 0.8)
  expect_gte(run_spec(between_example(list(type = "power", n = n), effect = "main_effect_A"))$curve$power, 0.8)
  result <- run_spec(within_example(list(type = "sample_size", power = 0.8)))
  n <- result$n_required$n
  expect_lt(run_spec(within_example(list(type = "power", n = n - 1)))$curve$power, 0.8)
  expect_gte(run_spec(within_example(list(type = "power", n = n)))$curve$power, 0.8)
})

test_that("the within design simulates with ANOVA_power() on request", {
  result <- run_spec(within_example(list(type = "power", n = 40), method = "simulation", nrep = 100))
  expect_equal(result$provenance$method, "simulation")
  expect_gt(result$curve$mcse, 0)
})

test_that("the two-factor designs refuse plainly what they can't do", {
  spec <- example_spec("anova_factorial_within")
  spec$population$means <- list(list(400, 410), list(430, 450))
  expect_spec_problem(spec, "should have 2 rows (one per level of Cue (A)), each with 3 means")
  spec <- example_spec("anova_factorial_within")
  spec$population$r <- -0.3
  expect_spec_problem(spec, "must be above -0.2")
  spec <- example_spec("anova_factorial_between")
  spec$variables$B$levels <- list("Easy", "Hard")
  spec$population$means <- list(list(0, 0), list(0.1, 0.5))
  expect_spec_problem(spec, "use the template '2x2_between'")
  spec <- example_spec("anova_factorial_between")
  spec$goal <- list(type = "power", n = 100)
  expect_spec_problem(spec, "split into 6 equal groups, one per cell")
})

test_that("the two-factor designs: the exported Superpower scripts reproduce powerkit (exact)", {
  skip_unless_scripts_can_run()
  spec <- within_example(list(type = "power", n = 40))
  expect_script_reproduces_power(spec, run_spec(spec))
  spec <- between_example(list(type = "power", n = 120))
  expect_script_reproduces_power(spec, run_spec(spec))
})
