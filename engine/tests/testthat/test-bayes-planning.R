# The Labs Bayesian planning tool: bayes_planning() returns bfpwr's chances
# of each outcome at a fixed sample size, under the design prior and with
# no effect, and the two priors' densities.

test_that("the outcomes are bfpwr's, and each row adds up to one", {
  plan <- bayes_planning(120, "two.sample", effect = 0.5, effect_sd = 0.15)
  belief <- plan$outcomes[plan$outcomes$truth == "belief", ]
  null <- plan$outcomes[plan$outcomes$truth == "null", ]
  expect_equal(belief$for_effect, bfpwr::ptbf01(k = 1 / 10, n = 120, dpm = 0.5, dpsd = 0.15, type = "two.sample"))
  expect_equal(null$for_null, bfpwr::ptbf01(k = 10, n = 120, dpm = 0, dpsd = 0, type = "two.sample", lower.tail = FALSE))
  expect_equal(null$for_effect, bfpwr::ptbf01(k = 1 / 10, n = 120, dpm = 0, dpsd = 0, type = "two.sample"))
  expect_equal(rowSums(plan$outcomes[c("for_effect", "for_null", "neither")]), c(1, 1))
  expect_identical(plan$package$name, "bfpwr")
  expect_match(plan$function_used, "bfpwr::ptbf01(", fixed = TRUE)
})

test_that("with no uncertainty, the chance of strong evidence for an effect is the Bayes factor card's power", {
  spec <- example_spec("independent_t")
  spec$target_test$method <- "bayes_factor"
  spec$target_test$alpha <- NULL
  spec$population$score_shape <- NULL
  spec$options <- list(seed = 7)
  spec$goal <- list(type = "power", n = 240)
  result <- run_quietly(spec)
  plan <- bayes_planning(120, "two.sample", effect = spec$population$d)
  expect_equal(plan$outcomes$for_effect[plan$outcomes$truth == "belief"], result$curve$power, tolerance = 1e-8)
  expect_equal(plan$outcomes$for_null[plan$outcomes$truth == "null"], result$bayes$evidence_for_null, tolerance = 1e-8)
  expect_equal(plan$outcomes$for_effect[plan$outcomes$truth == "null"], result$bayes$misleading_evidence, tolerance = 1e-8)
})

test_that("uncertainty about the effect lowers the chance and raises the sample size", {
  exact <- bayes_planning(120, effect = 0.5)
  uncertain <- bayes_planning(120, effect = 0.5, effect_sd = 0.15)
  expect_lt(uncertain$outcomes$for_effect[1], exact$outcomes$for_effect[1])
  expect_gt(uncertain$n_needed, exact$n_needed)
  # The sample size search: the target is met at n_needed, not one fewer.
  chance <- function(n) bfpwr::ptbf01(k = 1 / 10, n = n, dpm = 0.5, dpsd = 0.15, type = "two.sample")
  expect_gte(chance(uncertain$n_needed), 0.8)
  expect_lt(chance(uncertain$n_needed - 1), 0.8)
})

test_that("the largest evidence for no effect is the Bayes factor at t = 0, and only two-sided", {
  plan <- bayes_planning(120)
  expect_equal(plan$largest_bf01, bfpwr::tbf01(t = 0, n = 120, type = "two.sample"))
  expect_lt(plan$largest_bf01, 10)
  expect_equal(plan$outcomes$for_null[plan$outcomes$truth == "null"], 0)
  expect_true(is.na(bayes_planning(120, alternative = "greater")$largest_bf01))
})

test_that("the curves rise with the sample size and pass through the size set", {
  plan <- bayes_planning(80, "one.sample", effect = 0.3, effect_sd = 0.1)
  expect_true(all(diff(plan$curves$for_effect) >= -1e-8))
  expect_gte(max(plan$curves$n), 160)
  expect_equal(nrow(plan$curves), length(unique(plan$curves$n)))
})

test_that("the priors are a Cauchy analysis prior and a normal design prior", {
  plan <- bayes_planning(50, prior_scale = 1, effect = 0.4, effect_sd = 0.2)
  pr <- plan$priors
  expect_equal(pr$analysis, stats::dcauchy(pr$x, 0, 1))
  expect_equal(pr$design, stats::dnorm(pr$x, 0.4, 0.2))
  one_sided <- bayes_planning(50, alternative = "greater")$priors
  expect_true(all(one_sided$analysis[one_sided$x < 0] == 0))
  expect_equal(one_sided$analysis[one_sided$x > 0], 2 * stats::dcauchy(one_sided$x[one_sided$x > 0], 0, 1 / sqrt(2)))
  expect_true(all(is.na(bayes_planning(50)$priors$design)))
})

test_that("a sample size beyond 10,000 is NA, and bad inputs are refused in plain words", {
  expect_true(is.na(bayes_planning(30, effect = 0.01)$n_needed))
  expect_error(bayes_planning(2), "whole number of participants", class = "powerkit_error")
  expect_error(bayes_planning(50.5), "whole number", class = "powerkit_error")
  expect_error(bayes_planning(50, type = "anova"), "type", class = "powerkit_error")
  expect_error(bayes_planning(50, effect_sd = -1), "0 or more", class = "powerkit_error")
  expect_error(bayes_planning(50, prior_scale = 0), "more than 0", class = "powerkit_error")
  expect_error(bayes_planning(50, threshold = 1), "above 1", class = "powerkit_error")
  expect_error(bayes_planning(50, target = 1), "between 0 and 1", class = "powerkit_error")
  expect_error(bayes_planning(NA_real_), "whole number", class = "powerkit_error")
})
