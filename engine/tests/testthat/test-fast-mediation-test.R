# The direct Monte Carlo interval (fast-mediation-test.R) against the
# manymome-based test it replaces: the same simulated studies, fitted the
# same way, with the same Monte Carlo draws, must give the same estimate,
# interval and decision in every replication, for each kind of test.

compare_mediation_tests <- function(example, n = 200, nrep = 6, seed = 11) {
  spec <- example_spec(example)
  inputs <- power4mome_inputs(spec)
  original <- if (identical(inputs$test_name, "test_cond_indirect_diff")) test_cond_indirect_diff else
    getExportedValue("power4mome", inputs$test_name)
  run <- function(test_fun) {
    old <- options(power4mome.bz = FALSE)
    on.exit(options(old))
    out <- power4mome_call(inputs, n, nrep, seed, R = inputs$ci_draws, ci_type = inputs$ci_type,
      test_fun = test_fun, test_args = inputs$test_args)
    t(vapply(out$test_all[[1]], function(r) unname(r$test_results[1:4]), numeric(4)))
  }
  list(original = run(original), fast = run(power4mome_test_fun(inputs$test_name)))
}

test_that("each kind of test gives the same interval and decision as manymome's, replication by replication", {
  skip_on_cran()
  skip_if_not_installed("power4mome")
  skip_if_not_installed("boot")
  for (example in c("mediation_simple", "mediation_serial", "mediation_parallel", "process_7", "process_14",
                    "process_7_parallel", "process_8", "process_58", "process_59")) {
    both <- compare_mediation_tests(example)
    expect_equal(both$fast[, 1:3], both$original[, 1:3], tolerance = 1e-10, info = example)
    expect_identical(both$fast[, 4], both$original[, 4], info = example)
  }
})

test_that("cases outside the direct route go to the original test", {
  original <- function(...) "original"
  fast <- fast_mediation_test("index", original)
  expect_identical(fast(fit = NULL, get_test_name = TRUE), "original")
  expect_identical(fast(fit = NULL, boot_ci = TRUE, mc_ci = FALSE), "original")
  expect_identical(fast(fit = NULL, mc_out = NULL), "original")
})

test_that("the path effect is the product of each path's coefficient at the moderator's value", {
  est <- data.frame(lhs = c("M", "M", "Y", "Y"), op = "~", rhs = c("X", "X:W", "M", "M:W"),
    est = c(0.2, 0.15, 0.3, 0.1))
  expect_equal(mc_path_effect(est, c("X", "M", "Y")), 0.2 * 0.3)
  expect_equal(mc_path_effect(est, c("X", "M", "Y"), "W", 1), (0.2 + 0.15) * (0.3 + 0.1))
  expect_equal(mc_statistic("index", est, c("X", "M", "Y"), "W", -1, 1), (0.35 * 0.4) - (0.2 * 0.3))
  expect_equal(mc_statistic("difference", est, c("X", "M", "Y"), "W", -1, 1), 0.35 * 0.4 - 0.05 * 0.2)
})
