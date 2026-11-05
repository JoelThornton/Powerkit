test_that("all-tests targets distinguish independence and arbitrary dependence", {
  expect_equal(all_tests_target(0.8, 2), sqrt(0.8))
  expect_equal(all_tests_target(0.8, 2, "unknown"), 0.9)
  expect_equal(all_tests_target(0.8, 1, "unknown"), 0.8)
  expect_identical(all_tests_target(1e-20, 1, "unknown"), 1e-20)
  expect_error(all_tests_target(1, 2), "between")
  expect_error(all_tests_target(0.8, 2.5), "whole")
  expect_error(all_tests_target(1 - .Machine$double.eps, 1e8, "unknown"), "certainty")
})

test_that("independent event simulations and sharp dependent couplings check the targets", {
  n <- 200000
  for (k in c(2, 5)) {
    p <- all_tests_target(0.8, k, "unknown")
    u <- with_seed(804 + k, runif(n))
    # Disjoint failure intervals of length 1-p give the worst possible
    # joint chance. This constructs events, independently of the formula.
    failures <- vapply(seq_len(k), function(i) u >= (i - 1) * (1 - p) & u < i * (1 - p), logical(n))
    expect_equal(mean(rowSums(failures) == 0), 0.8, tolerance = 0.004)
    independent <- with_seed(40 + k, matrix(runif(n * k), ncol = k))
    expect_equal(mean(rowSums(independent < all_tests_target(0.8, k)) == k), 0.8, tolerance = 0.004)
  }
  p <- all_tests_target(0.8, 2)
  grid <- (seq_len(100000) - 0.5) / 100000
  expect_lt(mean(grid <= p & grid >= 1 - p), 0.8)
})
