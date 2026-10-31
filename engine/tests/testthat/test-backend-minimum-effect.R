# Minimum-effect tests (target_test > method "minimum_effect") on the
# one-sample, paired and two-group t-tests, by pwrss's power.t.student()
# with the margin on the effect's side; and the two-group t-test given by
# a point-biserial correlation (population > metric "point_biserial").

expect_script_reproduces <- function(spec) {
  result <- run_spec(spec)
  out <- run_exported_script(spec, result)
  expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10)
}

met_spec <- function(template = "independent_t", goal = list(type = "power", n = 114), d = 0.5, margin = 0.2,
                     alternative = "greater", options = NULL) {
  spec <- example_spec(template)
  spec$target_test$method <- "minimum_effect"
  spec$target_test$alternative <- alternative
  spec$population <- list(metric = "standardised", margin = margin)
  spec$population[[if (template == "paired_t") "dz" else "d"]] <- d
  spec$goal <- goal
  spec$options <- options
  spec
}

test_that("power is pwrss's for the margin on the effect's side", {
  result <- run_spec(met_spec())
  expect_equal(result$provenance$backend_function, "pwrss::power.t.student")
  direct <- pwrss::power.t.student(d = 0.5, margin = 0.2, n2 = 57, n.ratio = 1, alpha = 0.05,
                                   alternative = "one.sided", verbose = 0)$power
  expect_equal(result$curve$power, direct)
  expect_true(all(result$check_run$ok))
  # Lower scores: the margin's sign follows the side.
  less <- run_spec(met_spec(d = -0.5, alternative = "less"))$curve$power
  expect_equal(less, direct)
  # Two-sided: outside both margins, alpha / 2 in each tail.
  two <- run_spec(met_spec(alternative = NULL))$curve$power
  direct_two <- pwrss::power.t.student(d = 0.5, margin = c(-0.2, 0.2), n2 = 57, n.ratio = 1, alpha = 0.05,
                                       alternative = "two.one.sided", verbose = 0)$power
  expect_equal(two, direct_two)
  expect_lt(two, direct)
  # Paired and one sample.
  paired <- run_spec(met_spec("paired_t", goal = list(type = "power", n = 60)))$curve$power
  expect_equal(paired, pwrss::power.t.student(d = 0.5, margin = 0.2, n2 = 60, design = "paired", alpha = 0.05,
                                              alternative = "one.sided", verbose = 0)$power)
  one <- run_spec(met_spec("one_sample_t", goal = list(type = "power", n = 60)))$curve$power
  expect_equal(one, paired)
})

test_that("pwrss's power is the exact power of the t-test against a margin in SD units", {
  # The test rejects when the t statistic of the mean difference exceeds
  # the 95th centile of the noncentral t with noncentrality margin / SE.
  # Written here with base R's t distributions, independently of pwrss.
  n <- 57
  se <- sqrt(2 / n)
  df <- 2 * n - 2
  by_hand <- function(d) stats::pt(stats::qt(0.95, df, ncp = 0.2 / se), df, ncp = d / se, lower.tail = FALSE)
  expect_equal(run_spec(met_spec())$curve$power, by_hand(0.5), tolerance = 1e-8)
  # At the margin itself the rejection rate is alpha.
  expect_equal(by_hand(0.2), 0.05, tolerance = 1e-8)
})

test_that("the smallest detectable effect is pwrss's, 0.6735 for 57 per group and a margin of 0.2", {
  sens <- run_spec(met_spec(d = 0, goal = list(type = "sensitivity", n = 114, power = 0.8)))$sensitivity
  direct <- pwrss::power.t.student(d = NULL, margin = 0.2, n2 = 57, power = 0.8, alpha = 0.05,
                                   alternative = "one.sided", verbose = 0)$d
  expect_equal(sens$effect, direct)
  expect_equal(round(sens$effect, 4), 0.6735)
  expect_equal(sens$power, 0.8, tolerance = 1e-6)
  # The same calculation with one group's degrees of freedom (n - 1 = 56)
  # in place of the test's (2n - 2 = 112) gives 0.681: the difference is
  # in the degrees of freedom, not in pwrss.
  se <- sqrt(2 / 57)
  wrong_df <- stats::uniroot(function(d) {
    stats::pt(stats::qt(0.95, 56, ncp = 0.2 / se), 56, ncp = d / se, lower.tail = FALSE) - 0.8
  }, c(0.2, 2), tol = 1e-10)$root
  expect_equal(round(wrong_df, 3), 0.681)
  # Below: negative, on the "less" side.
  less <- run_spec(met_spec(d = 0, alternative = "less", goal = list(type = "sensitivity", n = 114, power = 0.8)))$sensitivity
  expect_equal(less$effect, -direct, tolerance = 1e-6)
})

test_that("a margin in SD units differs very slightly from one in the outcome's own units (Known difference 10)", {
  # TOSTER's t_TOST(hypothesis = "MET") with a bound in raw units tests a
  # central t shifted by the bound: slightly higher power at the same n.
  n <- 57
  se <- sqrt(2 / n)
  df <- 2 * n - 2
  shifted <- stats::pt(stats::qt(0.95, df), df, ncp = (0.5 - 0.2) / se, lower.tail = FALSE)
  pwrss_power <- run_spec(met_spec())$curve$power
  expect_gt(shifted, pwrss_power)
  expect_lt(shifted - pwrss_power, 0.02)
})

test_that("the required n is pwrss's, and grows as the margin nears the effect", {
  n <- run_spec(met_spec(goal = list(type = "sample_size", power = 0.8)))$n_required$n
  per_group <- pwrss::power.t.student(d = 0.5, margin = 0.2, power = 0.8, alpha = 0.05, alternative = "one.sided", verbose = 0)$n
  expect_equal(n, sum(per_group))
  wider <- run_spec(met_spec(margin = 0.3, goal = list(type = "sample_size", power = 0.8)))$n_required$n
  expect_gt(wider, n)
})

test_that("unequal groups pass both group sizes to pwrss", {
  result <- run_spec(met_spec(goal = list(type = "power", n = 150), options = list(allocation_ratio = 2)))
  direct <- pwrss::power.t.student(d = 0.5, margin = 0.2, n2 = 100, n.ratio = 0.5, alpha = 0.05,
                                   alternative = "one.sided", verbose = 0)$power
  expect_equal(result$curve$power, direct)
})

test_that("a margin in the outcome's own units is divided by the SD", {
  spec <- met_spec("paired_t", goal = list(type = "power", n = 60))
  spec$population <- list(metric = "raw", raw = list(mean_1 = 10, mean_2 = 15, sd_difference = 10, margin = 2))
  expect_equal(run_spec(spec)$curve$power, run_spec(met_spec("paired_t", goal = list(type = "power", n = 60), margin = 0.2))$curve$power)
})

test_that("an effect at or inside the margin, or a missing margin, is refused in plain English", {
  goal <- list(type = "sample_size", power = 0.8)
  expect_spec_problem(met_spec(d = 0.2, goal = goal), "not above the smallest effect of interest")
  expect_spec_problem(met_spec(d = 0.5, alternative = "less", goal = goal), "not below minus")
  expect_spec_problem(met_spec(d = 0.1, alternative = NULL, goal = goal), "further from 0")
  no_margin <- met_spec()
  no_margin$population$margin <- NULL
  expect_spec_problem(no_margin, "needs the smallest effect of interest")
  stray <- example_spec("independent_t")
  stray$population$margin <- 0.2
  expect_spec_problem(stray, "only used by a minimum-effect test")
  sim <- met_spec(options = list(method = "simulation"))
  expect_spec_problem(sim, "simulation")
})

test_that("the exported script reproduces each goal", {
  for (goal in list(list(type = "sample_size", power = 0.8), list(type = "power", n = 100),
                    list(type = "sensitivity", n = 114, power = 0.8))) {
    spec <- met_spec(d = if (goal$type == "sensitivity") 0 else 0.5, goal = goal)
    expect_script_reproduces(spec)
  }
  expect_script_reproduces(met_spec(alternative = NULL, goal = list(type = "power", n = 100)))
})

# Point-biserial r ------------------------------------------------------------

pb_spec <- function(r = 0.25, goal = list(type = "sample_size", power = 0.95), alternative = "greater", options = NULL) {
  spec <- example_spec("independent_t")
  spec$target_test$method <- "student_t"
  spec$target_test$alternative <- alternative
  spec$population <- list(metric = "point_biserial", r = r)
  spec$goal <- goal
  spec$options <- options
  spec
}

test_that("a point-biserial r gives the point-biserial model's power, whatever the allocation", {
  # The point-biserial model: noncentrality r sqrt(N) / sqrt(1 - r^2),
  # N - 2 degrees of freedom, written with base R's t distribution.
  model <- function(r, n) {
    df <- n - 2
    stats::pt(stats::qt(0.95, df), df, ncp = r * sqrt(n) / sqrt(1 - r^2), lower.tail = FALSE)
  }
  expect_equal(run_spec(pb_spec(goal = list(type = "power", n = 120)))$curve$power, model(0.25, 120), tolerance = 1e-8)
  unequal <- run_spec(pb_spec(goal = list(type = "power", n = 120), options = list(allocation_ratio = 2)))$curve$power
  expect_equal(unequal, model(0.25, 120), tolerance = 1e-8)
})

test_that("d is worked out from r and the share in group 2, and reported with r", {
  result <- run_spec(pb_spec())
  expect_equal(result$effect_from_units$value, psych::r2d(0.25))
  expect_equal(result$effect_from_units$r, 0.25)
  expect_equal(result$effect_from_units$share, 0.5)
  unequal <- run_spec(pb_spec(options = list(allocation_ratio = 3)))$effect_from_units
  expect_equal(unequal$value, 0.25 / sqrt(0.75 * 0.25 * (1 - 0.25^2)))
  # The smallest detectable r is also given.
  sens <- run_spec(pb_spec(r = 0, goal = list(type = "sensitivity", n = 164, power = 0.95)))
  expect_equal(sens$effect_from_units$smallest_r, powerkit:::point_biserial_from_d(sens$sensitivity$effect, 0.5))
  expect_equal(round(sens$effect_from_units$smallest_r, 2), 0.25)
})

test_that("a point-biserial r outside -1 to 1, or r without the metric, is refused", {
  expect_error(validate_spec(pb_spec(r = 1.2)), class = "powerkit_spec_error")
  stray <- example_spec("independent_t")
  stray$population$r <- 0.3
  expect_error(validate_spec(stray), class = "powerkit_spec_error")
})

test_that("the exported script reproduces a point-biserial plan", {
  expect_script_reproduces(pb_spec())
})
