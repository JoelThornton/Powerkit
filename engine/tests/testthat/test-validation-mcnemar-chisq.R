# Validation: McNemar's chi-square test, with and without the continuity
# correction (E26, target_test > method "mcnemar_chisq" and
# "mcnemar_chisq_corrected"). McNemar's exact test is pwrss's exact power,
# checked in test-validation-formula-tests.R.
# Backend: Spower simulation of powerkit's experiment p_mcnemar_chisq(),
# which calls Spower's p_mcnemar.test() (stats::mcnemar.test()).
#   1. agreement with an independent simulation: the pairs drawn as
#      multinomial counts and tested by the statistic written out,
#      (|b - c| - correction)^2 / (b + c) on 1 df, without Spower
#   2. Type I error
#   3. published example: placeholder, for the maintainer
# Values transcribed from a published source or G*Power (tests marked
# "(published)" or "(G*Power value)", or a value whose comment cites its
# source) are owned by the maintainer: do not edit them. Other expected
# values were written with the code (CLAUDE.md, Non-negotiables).
# Skipped unless POWERKIT_FULL_VALIDATION=true.

mcnemar_chisq_validation_spec <- function(method, p_first_only, p_second_only, n, seed = 501) {
  spec <- example_spec("mcnemar")
  spec$population$p_first_only <- p_first_only
  spec$population$p_second_only <- p_second_only
  spec$target_test$method <- method
  spec$target_test$alternative <- "two_sided"
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = validation_nrep(), seed = seed)
  spec <- validate_spec(spec)
  skip_if_no_backend(spec)
  spec
}

# b pairs "yes" in the first condition only, c in the second only.
mcnemar_p_by_hand <- function(b, c, correct) {
  if (b + c == 0) return(1)
  statistic <- (abs(b - c) - if (correct) 1 else 0)^2 / (b + c)
  stats::pchisq(statistic, 1, lower.tail = FALSE)
}

mcnemar_by_hand <- function(p_first_only, p_second_only, correct, n, nrep, seed) {
  prob <- c(p_first_only, p_second_only, 1 - p_first_only - p_second_only)
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    counts <- stats::rmultinom(1, n, prob)
    mcnemar_p_by_hand(counts[1], counts[2], correct) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("McNemar chi-square: powerkit agrees with the test written out (simulation)", {
  skip_unless_full_validation()
  # The statistic written out gives mcnemar.test()'s p-values (with a
  # discordant difference larger than 1, where the correction applies).
  for (correct in c(FALSE, TRUE)) {
    table <- matrix(c(30, 7, 18, 45), 2, 2)
    expect_equal(mcnemar_p_by_hand(table[2, 1], table[1, 2], correct),
      stats::mcnemar.test(table, correct = correct)$p.value, tolerance = 1e-10)
  }
  cases <- list(
    list(method = "mcnemar_chisq", p1 = 0.1, p2 = 0.25, n = 120),
    list(method = "mcnemar_chisq_corrected", p1 = 0.1, p2 = 0.25, n = 120),
    list(method = "mcnemar_chisq_corrected", p1 = 0.3, p2 = 0.15, n = 150)
  )
  for (case in cases) {
    spec <- mcnemar_chisq_validation_spec(case$method, case$p1, case$p2, case$n)
    reference <- mcnemar_by_hand(case$p1, case$p2, case$method == "mcnemar_chisq_corrected", case$n, 4000L, 502)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  }
})

test_that("McNemar chi-square: Type I error (simulation)", {
  skip_unless_full_validation()
  # Without the correction, near alpha; the correction makes the test
  # conservative, so its rate is at most alpha.
  expect_type1_near(engine_power(mcnemar_chisq_validation_spec("mcnemar_chisq", 0.15, 0.15, 200, seed = 503)), alpha = 0.05)
  corrected <- engine_power(mcnemar_chisq_validation_spec("mcnemar_chisq_corrected", 0.15, 0.15, 200, seed = 504))
  expect_lte(corrected$power, 0.05 + 3.29 * corrected$mcse)
})

test_that("McNemar chi-square: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power or sample-size example for
  # McNemar's chi-square test, with or without the continuity correction;
  # source, section, page).
  p_first_only <- TODO_PUBLISHED_VALUE
  p_second_only <- TODO_PUBLISHED_VALUE
  corrected <- TODO_PUBLISHED_VALUE # 1 with the continuity correction, 0 without
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(p_first_only, p_second_only, corrected, n, published_power)
  method <- if (corrected == 1) "mcnemar_chisq_corrected" else "mcnemar_chisq"
  spec <- mcnemar_chisq_validation_spec(method, p_first_only, p_second_only, n)
  expect_power_near(engine_power(spec), published_power)
})
