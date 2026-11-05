test_that("unknown-dependence planning changes the per-test target and its explanation", {
  v <- list(claim = "all", n_tests = "2", power = "0.8", all_dependence = "unknown", goal = "sample_size")
  expect_equal(claim_power(0.8, v), 0.9)
  expect_equal(claim_alpha(0.05, v), 0.05)
  expect_match(claim_result_note(v, 0.05, "sample_size"), "sufficient bound", fixed = TRUE)
  expect_match(writeup_claim(v, list(goal = list(power = 0.9))), "without assuming independence", fixed = TRUE)
  v$all_dependence <- NULL
  expect_equal(claim_power(0.8, v), sqrt(0.8))
})
