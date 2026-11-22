# The exported script for the same people measured more than once with a
# count, yes/no or ordered outcome (mixed_model / repeated_glmm, E75). The
# translation, check runs and refusals are in test-backend-glmm.R.

test_that("the R script reproduces the run", {
  spec <- glmm_spec(n = 20L)
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
  spec <- glmm_spec("negative_binomial", method = "likelihood_ratio", n = 16L)
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
  spec <- glmm_spec("ordinal", x = "between_factor", levels = c("A", "B", "C"), values = c(1, 1.5, 2), method = "wald", n = 18L)
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
})
