# The exported script for the Bayes factor of an effect in a three-factor
# ANOVA (E56). The inputs, the decomposition and the runs are in
# test-backend-bayes-three.R.

test_that("the R script reproduces the run", {
  skip_unless_scripts_can_run()
  spec <- bfthree_spec(within = character(), effect = "main_effect_C", n = 40)
  run <- expect_script_reproduces_power(spec, run_quietly(spec))
  expect_true(any(grepl("anovaBF(", run$script, fixed = TRUE)))
})
