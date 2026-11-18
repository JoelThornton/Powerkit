# McNemar's chi-square test, with and without the continuity correction
# (E26), simulated with Spower by powerkit's experiment p_mcnemar_chisq(),
# which calls Spower's p_mcnemar.test(). Routing, the direct Spower call,
# the table, refusals, sensitivity, the check run and the exported script;
# accuracy is checked by test-validation-mcnemar.R.

mcnemar_chisq_spec <- function(method = "mcnemar_chisq", n = 120L, nrep = 100L, alternative = "two_sided", goal = NULL) {
  spec <- example_spec("mcnemar")
  spec$population$p_first_only <- 0.1
  spec$population$p_second_only <- 0.25
  spec$target_test$method <- method
  spec$target_test$alternative <- alternative
  spec$goal <- goal %||% list(type = "power", n = n)
  spec$options <- list(seed = 7L, nrep = nrep)
  spec
}

test_that("the chi-square versions run on Spower and pass their check run; the exact test stays on pwrss", {
  for (method in c("mcnemar_chisq", "mcnemar_chisq_corrected")) {
    result <- run_quietly(mcnemar_chisq_spec(method))
    expect_equal(result$provenance$backend, "Spower")
    expect_equal(result$provenance$method, "simulation")
    expect_match(result$provenance$backend_function,
      if (method == "mcnemar_chisq") "correct = FALSE" else "correct = TRUE", fixed = TRUE)
    expect_true(all(result$check_run$ok))
  }
  exact <- mcnemar_chisq_spec("mcnemar_exact")
  exact$options$nrep <- NULL
  expect_equal(run_quietly(exact)$provenance$backend, "pwrss")
})

test_that("on one core, it equals a direct Spower call of the experiment", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  set.seed(7)
  direct <- Spower::Spower(p_mcnemar_chisq(n = 80, p_first_only = 0.1, p_second_only = 0.25, correct = TRUE),
    replications = 200, verbose = FALSE)
  expect_equal(run_quietly(mcnemar_chisq_spec("mcnemar_chisq_corrected", n = 80L, nrep = 200L))$curve$power, direct$power)
})

test_that("the table puts the discordant pairs where mcnemar.test() reads them", {
  prop <- mcnemar_table(0.1, 0.25)
  expect_equal(sum(prop), 1)
  expect_equal(c(prop[2, 1], prop[1, 2]), c(0.1, 0.25))
  # A study with no discordant pairs counts as not significant.
  expect_identical(with_seed(1, p_mcnemar_chisq(5, 1e-9, 1e-9, FALSE)), 1)
  # The correction makes the test more conservative.
  plain <- run_quietly(mcnemar_chisq_spec("mcnemar_chisq", nrep = 400L))$curve$power
  corrected <- run_quietly(mcnemar_chisq_spec("mcnemar_chisq_corrected", nrep = 400L))$curve$power
  expect_gt(plain, corrected)
})

test_that("one-sided chi-square tests and the exact method are refused in plain words", {
  expect_spec_problem(mcnemar_chisq_spec(alternative = "greater"), "For a one-sided test, choose McNemar's exact test")
  exact <- mcnemar_chisq_spec()
  exact$options$method <- "exact"
  expect_spec_problem(exact, "'options > method' 'exact' isn't available for this test")
})

test_that("the smallest detectable change is found by simulation", {
  spec <- mcnemar_chisq_spec(nrep = 200L, goal = list(type = "sensitivity", n = 200L, power = 0.8))
  result <- run_quietly(spec)
  expect_true(is.finite(result$sensitivity$effect))
  expect_gt(result$sensitivity$effect, 0.1)
})

test_that("the R script reproduces the run", {
  spec <- mcnemar_chisq_spec("mcnemar_chisq_corrected", n = 90L, nrep = 100L)
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
})
