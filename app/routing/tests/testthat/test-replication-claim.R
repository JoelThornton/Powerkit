# A claim resting on several tests (18 November 2026 onwards): the planner
# plans this test at the chance that makes all of them succeed together at
# the chosen chance, by the cards' rule (engine all_tests_target()).

claim_values <- list(rep_design = "anova", rep_anova_kind = "mixed", rep_levels_a = "2", rep_levels_b = "2",
  rep_anova_effect = "interaction", rep_n = "120", rep_f_from = "f", rep_anova_f = "15.38", rep_original_alpha = "0.05",
  rep_alpha = "0.05", rep_power = "0.8", rep_tau = "0.05", rep_prior = "uncertain")
claim_run <- function(v) replication_run(v, engine_function("replication_planning"), engine_function("replication_bucss"),
  engine_function("replication_anova_smallest"))

test_that("the number of tests is read only when it is a whole number of at least 2", {
  expect_true(is.na(replication_claim_tests(list())))
  expect_true(is.na(replication_claim_tests(list(rep_claim_tests = ""))))
  expect_true(is.na(replication_claim_tests(list(rep_claim_tests = "1"))))
  expect_true(is.na(replication_claim_tests(list(rep_claim_tests = "2.5"))))
  expect_equal(replication_claim_tests(list(rep_claim_tests = " 3 ")), 3)
  expect_identical(replication_claim_dependence(list()), "unknown")
  expect_identical(replication_claim_dependence(list(rep_claim_dependence = "independent")), "independent")
})

test_that("each test is planned at the chance that makes all of them succeed together", {
  all_tests <- engine_function("all_tests_target")
  one <- list(rep_claim_tests = "3")
  expect_equal(replication_claim_power(one, 0.8), all_tests(0.8, 3, "unknown"))
  expect_equal(replication_claim_power(one, 0.8), 1 - 0.2 / 3)
  expect_equal(replication_claim_power(c(one, rep_claim_dependence = "independent"), 0.8), 0.8^(1 / 3))
  expect_equal(replication_claim_power(list(), 0.8), 0.8)
  expect_equal(replication_args(modifyList(claim_values, one))$power, 1 - 0.2 / 3)
  expect_equal(replication_args(claim_values)$power, 0.8)
  expect_match(paste(replication_settings_missing(modifyList(claim_values, list(rep_claim_tests = "1"))), collapse = " "),
    "number of tests", fixed = TRUE)
})

test_that("the result and the write-up say the claim rests on several tests", {
  plan <- claim_run(modifyList(claim_values, list(rep_claim_tests = "3")))
  expect_equal(plan$claim$tests, 3)
  expect_equal(plan$claim$per_test, 1 - 0.2 / 3)
  words <- replication_claim_text(plan)
  expect_match(words, "all 3 tests", fixed = TRUE)
  expect_match(words, "may be conservative", fixed = TRUE)
  expect_match(paste(as.character(replication_claim_ui(plan)), collapse = ""), "Several tests", fixed = TRUE)
  # The write-up says "we", not "your", and gives no advice to the reader.
  sentence <- replication_recruit_sentence(plan)
  expect_match(sentence, "Our claim needs all 3 tests", fixed = TRUE)
  expect_no_match(sentence, "Your claim|plan each one", perl = TRUE)
  one <- claim_run(claim_values)
  expect_null(one$claim)
  expect_null(replication_claim_ui(one))
  # Fewer people are needed at the lower chance than at the claim's.
  expect_gt(claim_run(modifyList(claim_values, list(rep_claim_tests = "3")))$claim$per_test, 0.8)
})
