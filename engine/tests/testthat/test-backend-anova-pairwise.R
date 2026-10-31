# Pairwise comparisons after a one-way ANOVA (target_test > effect
# "pairwise"): the chosen pair's t-test, its p-value adjusted across all the
# pairwise comparisons, simulated with Superpower's ANOVA_power(p_adjust =).
# Few replications.

pairwise_spec <- function(template = "anova_oneway_between", comparison = c("None", "Praise"), p_adjust = "holm",
                          n = 90, nrep = 200) {
  spec <- example_spec(template)
  spec$target_test$effect <- "pairwise"
  spec$target_test$method <- "t_test"
  spec$target_test$comparison <- comparison
  spec$target_test$p_adjust <- p_adjust
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 5, nrep = nrep)
  spec
}

test_that("the chosen pair's adjusted power is Superpower's ANOVA_power(), replication for replication", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  result <- run_quietly(pairwise_spec())
  expect_identical(result$provenance$method, "simulation")
  expect_match(result$provenance$backend_function, "p_adjust = \"holm\"", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  design <- Superpower::ANOVA_design("3b", n = 30, mu = c(10, 11, 13), sd = 6, plot = FALSE)
  direct <- suppressWarnings(Superpower::ANOVA_power(design, p_adjust = "holm", nsims = 200, seed = 5, verbose = FALSE))
  expect_equal(result$curve$power, direct$pc_results["p_a_a1_a_a3", "power"] / 100)
  # The pair's order doesn't matter; its row follows the levels' order.
  expect_equal(superpower_inputs(validate_spec(pairwise_spec(comparison = c("Praise", "None"))))$pairwise_row, "p_a_a1_a_a3")
  expect_equal(superpower_inputs(validate_spec(pairwise_spec(comparison = c("Neutral", "Praise"))))$pairwise_row, "p_a_a2_a_a3")
})

test_that("pairwise comparisons work within participants too, with no MANOVA sentence", {
  spec <- pairwise_spec("anova_oneway_within", comparison = NULL, n = 40)
  spec$target_test$comparison <- unlist(spec$variables$A$levels)[1:2]
  result <- run_quietly(spec)
  expect_identical(result$provenance$method, "simulation")
  expect_null(result$manova)
  expect_gt(result$curve$power, 0)
})

test_that("adjusting costs power: none, then Holm, then Bonferroni", {
  powers <- vapply(c("none", "holm", "bonferroni"), function(a) run_quietly(pairwise_spec(p_adjust = a, nrep = 1000))$curve$power, numeric(1))
  expect_gte(powers[["none"]], powers[["holm"]])
  expect_gte(powers[["holm"]], powers[["bonferroni"]])
  # Departure 17's size (conventions.md): about 31% with Holm's adjustment
  # against 48% with none, for this pair at 30 per group.
  expect_gt(powers[["none"]] - powers[["holm"]], 0.1)
})

test_that("pairwise specs are refused in plain English when they can't be run", {
  unknown <- pairwise_spec(comparison = c("None", "Blame"))
  expect_error(validate_spec(unknown), "names 'Blame', which is not among A's levels", class = "powerkit_spec_error")
  same <- pairwise_spec(comparison = c("None", "None"))
  expect_error(validate_spec(same), "two different levels of A", class = "powerkit_spec_error")
  exact <- pairwise_spec()
  exact$options$method <- "exact"
  expect_error(validate_spec(exact), "only in its simulation", class = "powerkit_spec_error")
  stray <- example_spec("anova_oneway_between")
  stray$target_test$p_adjust <- "holm"
  expect_error(validate_spec(stray), "only apply to pairwise comparisons", class = "powerkit_spec_error")
  wrong_method <- pairwise_spec()
  wrong_method$target_test$method <- "anova_f"
  expect_error(validate_spec(wrong_method), "Pairwise comparisons are t-tests", class = "powerkit_spec_error")
  t_without_pairwise <- example_spec("anova_oneway_between")
  t_without_pairwise$target_test$method <- "t_test"
  expect_error(validate_spec(t_without_pairwise), "is for pairwise comparisons", class = "powerkit_spec_error")
})

test_that("a pair with equal means has nothing to detect, so no sample size is searched for", {
  equal <- pairwise_spec()
  equal$population$means <- list(10, 13, 10)
  equal$goal <- list(type = "sample_size", power = 0.8)
  expect_error(validate_spec(equal), class = "powerkit_spec_error")
})

test_that("the exported script reproduces a pairwise comparison", {
  skip_unless_scripts_can_run()
  spec <- pairwise_spec(p_adjust = "bonferroni", nrep = 100)
  expect_script_reproduces_power(spec, run_for_export(spec))
})
