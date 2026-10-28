# Three-factor ANOVA (template factorial_three): three crossed factors, each
# between or within participants, on Superpower's exact data set. Checked
# against Superpower called directly, from inputs written out by hand here.

three_example <- function(goal, effect = "interaction_ABC", types = NULL, ...) {
  spec <- small_run_spec("anova_factorial_three", goal = goal, ...)
  spec$target_test$effect <- effect
  if (!is.null(types)) {
    for (v in names(types)) spec$variables[[v]]$type <- types[[v]]
    if (all(unlist(types) == "between_factor") && length(types) == 3) spec$population$r <- NULL
  }
  spec
}

# The example's cell means, in Superpower's order a1_b1_c1, a1_b1_c2, a1_b2_c1, ...
three_mu <- c(80, 60, 81, 61, 80, 60, 84, 70)
three_rows <- c(
  main_effect_A = "a", main_effect_B = "b", main_effect_C = "c",
  interaction_AB = "a:b", interaction_AC = "a:c", interaction_BC = "b:c", interaction_ABC = "a:b:c"
)
all_between <- list(A = "between_factor", B = "between_factor", C = "between_factor")
all_within <- list(A = "within_factor", B = "within_factor", C = "within_factor")

test_that("every mix of factors runs on Superpower, exactly, and passes its check run", {
  mixed <- run_spec(three_example(list(type = "power", n = 60)))
  expect_equal(mixed$provenance$backend, "Superpower")
  expect_equal(mixed$provenance$method, "exact")
  expect_true(all(mixed$check_run$ok))
  # Eight cells (a mean and an SD each) and, in each of the two groups, a
  # correlation for each of the 6 pairs of its four cells.
  expect_equal(nrow(mixed$check_run), 8 * 2 + 2 * 6)
  between <- run_spec(three_example(list(type = "power", n = 160), types = all_between))
  expect_true(all(between$check_run$ok))
  expect_equal(nrow(between$check_run), 8 * 2)
  within <- run_spec(three_example(list(type = "power", n = 20), types = all_within))
  expect_true(all(within$check_run$ok))
  expect_equal(nrow(within$check_run), 8 * 2 + 28)
})

test_that("each effect equals Superpower's ANOVA_exact() called directly", {
  cases <- list(
    list(design = "2b*2w*2w", n_cell = 30, n = 60, types = NULL),
    list(design = "2b*2b*2b", n_cell = 20, n = 160, types = all_between),
    list(design = "2w*2w*2w", n_cell = 20, n = 20, types = all_within)
  )
  for (case in cases) {
    design <- Superpower::ANOVA_design(
      design = case$design, n = case$n_cell, mu = three_mu, sd = 12,
      r = if (identical(case$types, all_between)) 0 else 0.5, plot = FALSE
    )
    set.seed(7)
    direct <- Superpower::ANOVA_exact(design, alpha_level = 0.05, verbose = FALSE)$main_results
    for (effect in names(three_rows)) {
      power <- run_spec(three_example(list(type = "power", n = case$n), effect = effect, types = case$types))$curve$power
      expect_equal(power, direct[three_rows[[effect]], "power"] / 100, label = paste(case$design, effect))
    }
  }
})

test_that("a factor with three levels is read in Superpower's order", {
  spec <- three_example(list(type = "power", n = 60), effect = "interaction_BC")
  spec$variables$C$levels <- list("Easy", "Medium", "Hard")
  spec$population$means <- list(
    list(list(80, 70, 60), list(81, 71, 61)),
    list(list(80, 70, 60), list(84, 77, 70))
  )
  result <- run_spec(spec)
  expect_true(all(result$check_run$ok))
  design <- Superpower::ANOVA_design(
    design = "2b*2w*3w", n = 30, mu = c(80, 70, 60, 81, 71, 61, 80, 70, 60, 84, 77, 70),
    sd = 12, r = 0.5, plot = FALSE
  )
  set.seed(7)
  direct <- Superpower::ANOVA_exact(design, alpha_level = 0.05, verbose = FALSE)$main_results
  expect_equal(result$curve$power, direct["b:c", "power"] / 100)
})

test_that("the sample size search uses whole between-participants groups", {
  result <- run_spec(three_example(list(type = "sample_size", power = 0.8), effect = "interaction_AB"))
  n <- result$n_required$n
  expect_equal(n %% 2, 0)
  expect_lt(run_spec(three_example(list(type = "power", n = n - 2), effect = "interaction_AB"))$curve$power, 0.8)
  expect_gte(run_spec(three_example(list(type = "power", n = n), effect = "interaction_AB"))$curve$power, 0.8)
})

test_that("the three-factor design simulates with ANOVA_power() on request", {
  result <- run_spec(three_example(list(type = "power", n = 60), method = "simulation", nrep = 100))
  expect_equal(result$provenance$method, "simulation")
  expect_gt(result$curve$mcse, 0)
})

test_that("the three-factor design refuses plainly what it can't do", {
  spec <- example_spec("anova_factorial_three")
  spec$population$means[[2]] <- list(list(80, 60), list(81, 61), list(82, 62))
  expect_spec_problem(spec, "should have 2 arrays (one per level of Group (A)), each with 2 arrays")
  spec <- example_spec("anova_factorial_three")
  spec$population$r <- NULL
  expect_spec_problem(spec, "give 'population > r'")
  spec <- example_spec("anova_factorial_three")
  spec$population$r <- -0.5
  expect_spec_problem(spec, "must be above -0.333")
  spec <- example_spec("anova_factorial_three")
  for (v in c("A", "B", "C")) spec$variables[[v]]$type <- "between_factor"
  expect_spec_problem(spec, "remove 'population > r'")
  spec <- example_spec("anova_factorial_three")
  spec$goal <- list(type = "power", n = 61)
  expect_spec_problem(spec, "split into 2 equal groups, one per combination of the between-participants factors")
  spec <- example_spec("anova_factorial_three")
  spec$population$means[[2]][[2]] <- list(81, 61)
  expect_spec_problem(spec, "The effect you want to detect is zero")
  # No smallest detectable effect yet, as for the two-factor designs.
  spec <- example_spec("anova_factorial_three")
  spec$goal <- list(type = "sensitivity", n = 60, power = 0.8)
  expect_error(run_spec(spec), "isn't available yet")
})

test_that("the three-factor effect size check is zero only when the effect is absent", {
  spec <- example_spec("anova_factorial_three")
  # Additive cell means: every interaction is zero, every main effect isn't.
  a <- c(0, 2); b <- c(0, 3); c <- c(0, 5)
  spec$population$means <- lapply(a, function(i) lapply(b, function(j) lapply(c, function(l) i + j + l)))
  for (effect in names(three_rows)) {
    spec$target_test$effect <- effect
    size <- three_factor_effect_size(spec)
    if (startsWith(effect, "main")) expect_gt(size, 0, label = effect) else expect_equal(size, 0, label = effect)
  }
})

test_that("the three-factor design: the exported Superpower script reproduces powerkit (exact)", {
  skip_unless_scripts_can_run()
  spec <- three_example(list(type = "power", n = 60))
  expect_script_reproduces_power(spec, run_spec(spec))
})
