# Justified alpha (goal > type "justified_alpha"): JustifyAlpha's
# optimal_alpha() on pwr's power, for the one-sample, paired and two-group
# t-tests and the correlation.

ja_spec <- function(name, goal = list()) {
  spec <- example_spec(name)
  spec$options <- NULL
  # The example uses Welch's test, which pwr's formula doesn't cover.
  if (name == "independent_t") spec$target_test$method <- "student_t"
  spec$goal <- modifyList(list(type = "justified_alpha", n = 64L), goal)
  spec
}

test_that("powerkit's justified alpha is optimal_alpha() called directly on pwr's power", {
  direct <- list(
    independent_t = "pwr::pwr.t.test(n = 32, d = %s, sig.level = x, type = 'two.sample', alternative = 'two.sided')$power",
    one_sample_t = "pwr::pwr.t.test(n = 64, d = %s, sig.level = x, type = 'one.sample', alternative = 'two.sided')$power",
    paired_t = "pwr::pwr.t.test(n = 64, d = %s, sig.level = x, type = 'paired', alternative = 'two.sided')$power",
    correlation = "pwr::pwr.r.test(n = 64, r = %s, sig.level = x, alternative = 'two.sided')$power"
  )
  for (name in names(direct)) {
    spec <- ja_spec(name)
    spec$target_test$alternative <- "two_sided"
    effect <- switch(name, correlation = spec$population$r, paired_t = spec$population$d_z %||% spec$population$d, spec$population$d)
    result <- run_spec(spec)
    j <- result$justified_alpha
    expected <- JustifyAlpha::optimal_alpha(sprintf(direct[[name]], format(effect, digits = 15)))
    expect_equal(j$alpha, expected$alpha, tolerance = 1e-8, label = name)
    expect_equal(j$beta, expected$beta, tolerance = 1e-8, label = name)
    expect_equal(result$curve$power, 1 - expected$beta, tolerance = 1e-8)
    expect_equal(result$provenance$backend, "pwr")
    expect_true("JustifyAlpha" %in% names(result$provenance$packages))
  }
})

test_that("the balance rule makes the weighted errors equal (G*Power's compromise power analysis)", {
  for (cost in c(1, 4)) {
    j <- run_spec(ja_spec("independent_t", list(error_rule = "balance", cost_ratio = cost)))$justified_alpha
    # optimal_alpha() searches with optimize(tol = 0.001).
    expect_equal(cost * j$alpha, j$beta, tolerance = 0.01)
  }
})

test_that("a costlier false positive or a less likely effect gives a stricter alpha", {
  base <- run_spec(ja_spec("independent_t"))$justified_alpha
  costly <- run_spec(ja_spec("independent_t", list(cost_ratio = 4)))$justified_alpha
  unlikely <- run_spec(ja_spec("independent_t", list(prior_odds = 0.25)))$justified_alpha
  expect_lt(costly$alpha, base$alpha)
  expect_lt(unlikely$alpha, base$alpha)
  # The conventional alpha is kept for comparison, with pwr's power at it.
  expect_equal(base$conventional_alpha, 0.05)
  expect_equal(base$conventional_power, run_spec(within(ja_spec("independent_t"), goal <- list(type = "power", n = 64L)))$curve$power,
    tolerance = 1e-10)
})

test_that("a justified alpha is refused, in plain words, where pwr doesn't cover the test", {
  spec <- ja_spec("independent_t")
  spec$target_test$method <- "welch_t"
  expect_error(run_spec(spec), "A justified alpha is available for the one-sample, paired and two-group t-tests")
  spec <- ja_spec("two_proportions")
  expect_error(run_spec(spec), "A justified alpha is available")
  spec <- example_spec("independent_t")
  spec$goal$cost_ratio <- 2
  expect_error(run_spec(spec), "'goal > cost_ratio' is only used for a justified alpha")
  spec <- ja_spec("independent_t")
  spec$goal$power <- 0.8
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})

test_that("the exported script reproduces the justified alpha", {
  skip_unless_scripts_can_run()
  for (goal in list(list(), list(error_rule = "balance", cost_ratio = 2, prior_odds = 0.5))) {
    spec <- ja_spec("correlation", goal)
    result <- run_spec(spec)
    out <- run_exported_script(spec, result)
    expect_false(any(grepl("powerkit::|library\\(powerkit\\)", out$script)))
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10)
  }
})

test_that("minimising the weighted errors gives a lower alpha than balancing them, as G*Power's compromise does (Known difference 11)", {
  spec <- ja_spec("independent_t")
  spec$population$d <- 0.5
  spec$target_test$alternative <- "two_sided"
  minimum <- run_spec(spec)$justified_alpha
  spec$goal$error_rule <- "balance"
  balance <- run_spec(spec)$justified_alpha
  expect_equal(round(minimum$alpha, 3), 0.184)
  expect_equal(round(balance$alpha, 3), 0.221)
  # Balancing with equal weights makes alpha equal beta (q = 1).
  expect_equal(balance$alpha, balance$beta, tolerance = 0.005)
})
