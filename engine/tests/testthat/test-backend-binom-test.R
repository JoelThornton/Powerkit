# The exact binomial test with R's binom.test() p-value (backend-binom-test.R).

binom_spec <- function(goal, p = 0.2, p0 = 0.1, alternative = NULL) {
  spec <- example_spec("one_proportion")
  spec$population$p <- p
  spec$population$p0 <- p0
  spec$target_test$method <- "binom_test"
  spec$target_test$alternative <- alternative
  spec$options <- list(seed = 7)
  spec$goal <- goal
  spec
}

test_that("binom_test_p() is binom.test()'s p-value on every count", {
  for (n in c(1, 2, 7, 20, 41, 100, 257)) {
    for (p0 in c(0.03, 0.1, 0.25, 0.5, 0.62, 0.9)) {
      x <- 0:n
      for (alternative in c("two.sided", "less", "greater")) {
        expected <- vapply(x, function(k) stats::binom.test(k, n, p0, alternative = alternative)$p.value, numeric(1))
        expect_equal(binom_test_p(x, n, p0, alternative), expected, tolerance = 1e-12,
          info = sprintf("n = %d, p0 = %s, %s", n, p0, alternative))
        # The decision at alpha .05 is the same on every count.
        expect_identical(binom_test_p(x, n, p0, alternative) <= 0.05, expected <= 0.05)
      }
    }
  }
})

test_that("binom.test()'s rule needs fewer people than equal tails for 20% against 10%", {
  # Power summed over every count from binom.test() itself, independently of
  # binom_test_power().
  by_hand <- function(n) {
    x <- 0:n
    reject <- vapply(x, function(k) stats::binom.test(k, n, 0.1)$p.value <= 0.05, TRUE)
    sum(stats::dbinom(x[reject], n, 0.2))
  }
  result <- run_spec(binom_spec(list(type = "sample_size", power = 0.8)))
  expect_identical(result$provenance$backend, "stats")
  expect_identical(result$n_required$n, 83)
  expect_gte(by_hand(83), 0.8)
  expect_true(all(vapply(2:82, by_hand, numeric(1)) < 0.8))
  # The default route, alpha / 2 in each tail, needs 94.
  equal <- binom_spec(list(type = "sample_size", power = 0.8))
  equal$target_test$method <- "exact_binomial"
  expect_identical(run_spec(equal)$n_required$n, 94)

  power <- run_spec(binom_spec(list(type = "power", n = 60)))$curve$power
  expect_equal(power, by_hand(60))
})

test_that("one-sided, binom.test()'s rule is the usual one-tailed exact test", {
  one <- run_spec(binom_spec(list(type = "power", n = 40), p = 0.2, p0 = 0.2, alternative = "less"))$curve$power
  x <- 0:40
  reject <- vapply(x, function(k) stats::binom.test(k, 40, 0.2, alternative = "less")$p.value <= 0.05, TRUE)
  expect_equal(one, sum(stats::dbinom(x[reject], 40, 0.2)))
  greater <- binom_spec(list(type = "power", n = 60), alternative = "greater")
  equal <- greater
  equal$target_test$method <- "exact_binomial"
  expect_equal(run_spec(greater)$curve$power, run_spec(equal)$curve$power)
})

test_that("the smallest detectable proportion is found with binom.test()'s power", {
  result <- run_spec(binom_spec(list(type = "sensitivity", n = 80, power = 0.8), p = 0.1))
  s <- result$sensitivity
  expect_gt(s$effect, 0.1)
  expect_equal(binom_test_power(80, s$effect, 0.1, 0.05), 0.8, tolerance = 1e-6)
})

test_that("the R script reproduces each goal with base R alone", {
  for (goal in list(list(type = "power", n = 60), list(type = "sample_size", power = 0.8),
                    list(type = "sensitivity", n = 80, power = 0.8))) {
    spec <- binom_spec(goal, p = if (identical(goal$type, "sensitivity")) 0.1 else 0.2)
    result <- run_spec(spec)
    script <- export_script(spec, result)
    expect_no_match(script, "library(pwrss)", fixed = TRUE)
    out <- utils::capture.output(source(textConnection(script), local = new.env()))
    expect_true(any(grepl("Reproduced powerkit's result", out, fixed = TRUE)), info = goal$type)
  }
})

# The z test of one proportion, R's prop.test() (method "z_test" or
# "z_test_corrected"), summed over its counts the same way.

test_that("prop_test_p() is prop.test()'s p-value on every count, without and with the correction", {
  for (n in c(1, 2, 7, 20, 41, 100, 257)) {
    for (p0 in c(0.03, 0.1, 0.25, 0.5, 0.62, 0.9)) {
      x <- 0:n
      for (alternative in c("two.sided", "less", "greater")) {
        for (correct in c(FALSE, TRUE)) {
          expected <- vapply(x, function(k) suppressWarnings(stats::prop.test(k, n, p0, alternative = alternative, correct = correct))$p.value, numeric(1))
          info <- sprintf("n = %d, p0 = %s, %s, correct = %s", n, p0, alternative, correct)
          expect_equal(prop_test_p(x, n, p0, alternative, correct), expected, tolerance = 1e-12, info = info)
          expect_identical(prop_test_p(x, n, p0, alternative, correct) <= 0.05, expected <= 0.05, info = info)
        }
      }
    }
  }
})

test_that("Departure 36: the z test of one proportion is summed over its counts, by this much", {
  # Power summed over prop.test()'s own decisions, independently of
  # binom_test_power().
  by_hand <- function(n, correct) {
    x <- 0:n
    reject <- vapply(x, function(k) suppressWarnings(stats::prop.test(k, n, 0.1, correct = correct))$p.value <= 0.05, TRUE)
    sum(stats::dbinom(x[reject], n, 0.2))
  }
  z <- binom_spec(list(type = "power", n = 94))
  z$target_test$method <- "z_test"
  corrected <- z
  corrected$target_test$method <- "z_test_corrected"
  expect_identical(run_spec(z)$provenance$backend, "stats")
  expect_equal(run_spec(z)$curve$power, by_hand(94, FALSE))
  expect_equal(run_spec(corrected)$curve$power, by_hand(94, TRUE))
  # The size of the difference from pwrss's normal approximation
  # (conventions.md, Departure 36): 80.1% against 83.0% without the
  # correction, 80.1% against 79.5% with it.
  approx <- function(correct) pwrss::power.z.oneprop(prob = 0.2, null.prob = 0.1, n = 94, alpha = 0.05,
    alternative = "two.sided", std.error = "null", correct = correct, verbose = FALSE)$power
  expect_equal(by_hand(94, FALSE), 0.8006, tolerance = 1e-4)
  expect_equal(approx(FALSE), 0.8300, tolerance = 1e-4)
  expect_equal(approx(TRUE), 0.7954, tolerance = 1e-4)

  # Sample size: the smallest that reaches 80%, 78 (pwrss: 86) without the
  # correction and 89 (pwrss: 96) with it.
  z$goal <- corrected$goal <- list(type = "sample_size", power = 0.8)
  expect_identical(run_spec(z)$n_required$n, 78)
  expect_identical(run_spec(corrected)$n_required$n, 89)
  expect_gte(by_hand(78, FALSE), 0.8)
  expect_true(all(vapply(2:77, by_hand, numeric(1), correct = FALSE) < 0.8))
  expect_gte(by_hand(89, TRUE), 0.8)
  expect_true(all(vapply(2:88, by_hand, numeric(1), correct = TRUE) < 0.8))
})

test_that("the z test's R script reproduces each goal with base R alone", {
  for (method in c("z_test", "z_test_corrected")) {
    for (goal in list(list(type = "power", n = 60), list(type = "sample_size", power = 0.8),
                      list(type = "sensitivity", n = 80, power = 0.8))) {
      spec <- binom_spec(goal, p = if (identical(goal$type, "sensitivity")) 0.1 else 0.2, alternative = "greater")
      spec$target_test$method <- method
      result <- run_spec(spec)
      script <- export_script(spec, result)
      expect_match(script, "prop.test", fixed = TRUE)
      out <- utils::capture.output(source(textConnection(script), local = new.env()))
      expect_true(any(grepl("Reproduced powerkit's result", out, fixed = TRUE)), info = paste(method, goal$type))
    }
  }
})
