# The MANOVA approach to a repeated-measures effect: Superpower's
# ANOVA_exact() reports it beside the univariate F, and powerkit records it
# when the target effect involves a within factor with three or more levels.

manova_direct <- function(spec, n) {
  inputs <- superpower_inputs(spec)
  design <- Superpower::ANOVA_design(inputs$design, n = n / inputs$groups, mu = inputs$mu,
                                     sd = inputs$sd, r = inputs$r, plot = FALSE)
  out <- suppressWarnings(Superpower::ANOVA_exact(design, alpha_level = inputs$alpha, verbose = FALSE))
  out$manova_results[inputs$effect, "power"] / 100
}

test_that("the MANOVA approach's power equals Superpower's, at the n analysed", {
  spec <- example_spec("anova_oneway_within")
  result <- suppressWarnings(run_spec(spec))
  expect_equal(result$manova$n, result$n_required$n)
  expect_equal(result$manova$power, manova_direct(spec, result$n_required$n))
  spec$goal <- list(type = "power", n = 40)
  expect_equal(suppressWarnings(run_spec(spec))$manova$power, manova_direct(spec, 40))
  # The mixed design's interaction involves its three-level within factor.
  spec <- example_spec("anova_mixed")
  spec$goal <- list(type = "power", n = 60)
  expect_equal(suppressWarnings(run_spec(spec))$manova$power, manova_direct(spec, 60))
})

test_that("it is recorded only where it can differ from the univariate F, and only exactly", {
  expect_null(suppressWarnings(run_spec(example_spec("anova_2x2_mixed")))$manova)
  expect_null(suppressWarnings(run_spec(example_spec("anova_oneway_between")))$manova)
  spec <- example_spec("anova_mixed")
  spec$target_test$effect <- "main_effect_A"
  expect_false(manova_applies(spec))
  spec$target_test$effect <- "main_effect_B"
  expect_true(manova_applies(spec))
})
