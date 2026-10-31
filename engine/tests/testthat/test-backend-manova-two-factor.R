# Two-way MANOVA (template manova with a second factor B; next.md item 2):
# the groups are A's levels by B's, B fastest, and the test is Pillai's
# trace of A, B or A x B in stats::manova(y ~ A * B), simulated with Spower.

manova2_spec <- function(effect = "main_effect_A", goal = list(type = "power", n = 160L), nrep = 300L) {
  spec <- example_spec("manova")
  spec$variables$A$levels <- list("Control", "Training")
  spec$variables$B <- list(type = "between_factor", label = "Delivery", levels = list("Online", "In person"))
  spec$population$means <- list(list(20, 18, 22), list(20, 18, 22), list(18, 16.5, 20), list(16, 15.5, 18))
  spec$target_test$effect <- effect
  spec$goal <- goal
  spec$options <- list(nrep = nrep, seed = 4L)
  spec
}

test_that("a two-way MANOVA tests each effect with Pillai's trace of A * B, and its check run recovers the cells", {
  for (effect in c("main_effect_A", "main_effect_B", "interaction")) {
    result <- suppressWarnings(run_spec(manova2_spec(effect)))
    expect_match(result$provenance$backend_function, "A * B", fixed = TRUE, label = effect)
    expect_true(all(result$check_run$ok), label = effect)
    # Four groups of means on three outcomes.
    expect_equal(sum(grepl("^mean of Y", result$check_run$parameter)), 12, label = effect)
  }
})

test_that("the experiment tests the term asked for, as a direct stats::manova() fit does", {
  means <- manova_means(validate_spec(manova2_spec()))
  set.seed(9)
  p <- p_manova(40, means, sds = c(6, 5, 7), r = 0.5, b = 2, term = "A:B")
  set.seed(9)
  data <- manova_scores(40, means, c(6, 5, 7), 0.5)
  group <- as.integer(data$group)
  A <- factor((group - 1) %/% 2 + 1)
  B <- factor((group - 1) %% 2 + 1)
  direct <- summary(stats::manova(as.matrix(data[, -1]) ~ A * B), test = "Pillai")$stats["A:B", "Pr(>F)"]
  expect_equal(p, direct)
})

test_that("a two-way MANOVA refuses the wrong number of rows, B's effect without B, and splits n into the cells", {
  short <- manova2_spec()
  short$population$means <- short$population$means[1:3]
  expect_spec_problem(short, "one row per combination of A and B (4)")
  one <- example_spec("manova")
  one$target_test$effect <- "interaction"
  expect_spec_problem(one, "need a second factor B")
  odd <- manova2_spec(goal = list(type = "power", n = 162L))
  expect_spec_problem(odd, "4 equal groups, one per combination of A and B")
  # No interaction in the means: a sample size search is refused.
  flat <- manova2_spec("interaction", goal = list(type = "sample_size", power = 0.8))
  flat$population$means <- list(list(20, 18, 22), list(19, 17, 21), list(18, 16, 20), list(17, 15, 19))
  expect_error(validate_spec(flat), class = "powerkit_spec_error")
})

test_that("the exported script reproduces a two-way MANOVA with Spower alone, and the data set has both factors", {
  spec <- manova2_spec("interaction", nrep = 200L)
  expect_script_reproduces_power(spec, run_spec(spec))
  code <- simulated_data_code(validate_spec(spec), 80, 1)
  expect_true(any(grepl("Delivery = rep(rep(", code, fixed = TRUE)))
})
