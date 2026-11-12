# Minimum-effect tests (target_test > method "minimum_effect") on the
# one-sample, paired and two-group t-tests, by pwrss's power.t.student()
# for the effect minus the margin (the shifted t-test, t.test(mu = margin));
# and the two-group t-test given by
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

test_that("power is the shifted t-test's: pwrss's one-sided t-test of the effect minus the margin", {
  result <- run_spec(met_spec())
  expect_equal(result$provenance$backend_function, "pwrss::power.t.student")
  direct <- pwrss::power.t.student(d = 0.3, margin = 0, n2 = 57, n.ratio = 1, alpha = 0.05,
                                   alternative = "one.sided", verbose = 0)$power
  expect_equal(result$curve$power, direct)
  expect_true(all(result$check_run$ok))
  # Lower scores: the margin's sign follows the side.
  less <- run_spec(met_spec(d = -0.5, alternative = "less"))$curve$power
  expect_equal(less, direct)
  # Two-sided: outside both margins, alpha / 2 in each tail; the tail on
  # the wrong side comes from pwr.
  two <- run_spec(met_spec(alternative = NULL))
  main <- pwrss::power.t.student(d = 0.3, margin = 0, n2 = 57, n.ratio = 1, alpha = 0.025,
                                 alternative = "one.sided", verbose = 0)$power
  far <- pwr::pwr.t2n.test(n1 = 57, n2 = 57, d = 0.7, sig.level = 0.025, alternative = "less")$power
  expect_equal(two$curve$power, main + far)
  expect_lt(two$curve$power, direct)
  expect_true(all(c("pwrss", "pwr") %in% names(two$provenance$packages)))
  # Paired and one sample.
  paired <- run_spec(met_spec("paired_t", goal = list(type = "power", n = 60)))$curve$power
  expect_equal(paired, pwrss::power.t.student(d = 0.3, margin = 0, n2 = 60, design = "paired", alpha = 0.05,
                                              alternative = "one.sided", verbose = 0)$power)
  one <- run_spec(met_spec("one_sample_t", goal = list(type = "power", n = 60)))$curve$power
  expect_equal(one, paired)
})

test_that("the power is the exact power of t.test(mu = margin), a central t shifted by the margin", {
  # The test rejects when the t statistic of the mean difference minus the
  # margin exceeds the 95th centile of the central t. Written here with
  # base R's t distributions, independently of pwrss.
  n <- 57
  se <- sqrt(2 / n)
  df <- 2 * n - 2
  by_hand <- function(d) stats::pt(stats::qt(0.95, df), df, ncp = (d - 0.2) / se, lower.tail = FALSE)
  expect_equal(run_spec(met_spec())$curve$power, by_hand(0.5), tolerance = 1e-8)
  # Two-sided, both tails written out.
  two_by_hand <- stats::pt(stats::qt(0.975, df), df, ncp = (0.5 - 0.2) / se, lower.tail = FALSE) +
    stats::pt(stats::qt(0.025, df), df, ncp = (0.5 + 0.2) / se)
  expect_equal(run_spec(met_spec(alternative = NULL))$curve$power, two_by_hand, tolerance = 1e-8)
  # At the margin itself the rejection rate is alpha.
  expect_equal(by_hand(0.2), 0.05, tolerance = 1e-8)
  expect_equal(run_spec(met_spec(d = 0.2 + 1e-9))$curve$power, 0.05, tolerance = 1e-6)
})

test_that("a simulation of t.test(mu = margin) agrees with the formula", {
  set.seed(712)
  n <- 40
  reject <- replicate(4000, {
    y1 <- stats::rnorm(n)
    y2 <- stats::rnorm(n, mean = 0.6)
    stats::t.test(y2 - 0.2, y1, var.equal = TRUE, alternative = "greater")$p.value < 0.05
  })
  power <- run_spec(met_spec(d = 0.6, goal = list(type = "power", n = 2 * n)))$curve$power
  expect_lt(abs(mean(reject) - power), 4 * sqrt(power * (1 - power) / 4000))
})

test_that("the smallest detectable effect is the shifted test's, 0.6686 for 57 per group and a margin of 0.2", {
  sens <- run_spec(met_spec(d = 0, goal = list(type = "sensitivity", n = 114, power = 0.8)))$sensitivity
  shifted <- pwrss::power.t.student(d = NULL, margin = 0, n2 = 57, power = 0.8, alpha = 0.05,
                                    alternative = "one.sided", verbose = 0)$d
  expect_equal(sens$effect, shifted + 0.2, tolerance = 1e-6)
  expect_equal(round(sens$effect, 4), 0.6686)
  expect_equal(sens$power, 0.8, tolerance = 1e-6)
  # Below: negative, on the "less" side.
  less <- run_spec(met_spec(d = 0, alternative = "less", goal = list(type = "sensitivity", n = 114, power = 0.8)))$sensitivity
  expect_equal(less$effect, -sens$effect, tolerance = 1e-6)
  # Two-sided: the effect whose power, both tails together, is the target.
  two <- run_spec(met_spec(d = 0, alternative = NULL, goal = list(type = "sensitivity", n = 114, power = 0.8)))$sensitivity
  expect_gt(two$effect, sens$effect)
  expect_equal(two$power, 0.8, tolerance = 1e-6)
})

test_that("pwrss's own margin argument, a margin in SD units, gives slightly less power (Known difference 10, retired)", {
  # Until 12 November 2026 powerkit passed the margin through pwrss's
  # `margin` argument: a noncentral t under the null, the test of a margin
  # in SD units. The size of the difference, for the record.
  pwrss_margin <- pwrss::power.t.student(d = 0.5, margin = 0.2, n2 = 57, n.ratio = 1, alpha = 0.05,
                                         alternative = "one.sided", verbose = 0)$power
  shifted <- run_spec(met_spec())$curve$power
  expect_equal(round(c(shifted, pwrss_margin), 3), c(0.479, 0.472))
  n_shifted <- run_spec(met_spec(goal = list(type = "sample_size", power = 0.8)))$n_required$n
  n_margin <- sum(pwrss::power.t.student(d = 0.5, margin = 0.2, power = 0.8, alpha = 0.05,
                                         alternative = "one.sided", verbose = 0)$n)
  expect_equal(c(n_shifted, n_margin), c(278, 282))
})

test_that("the required n is the shifted test's, and grows as the margin nears the effect", {
  n <- run_spec(met_spec(goal = list(type = "sample_size", power = 0.8)))$n_required$n
  per_group <- pwrss::power.t.student(d = 0.3, margin = 0, power = 0.8, alpha = 0.05, alternative = "one.sided", verbose = 0)$n
  expect_equal(n, 2 * ceiling(unname(per_group[1])))
  wider <- run_spec(met_spec(margin = 0.3, goal = list(type = "sample_size", power = 0.8)))$n_required$n
  expect_gt(wider, n)
})

test_that("unequal groups pass both group sizes to pwrss", {
  result <- run_spec(met_spec(goal = list(type = "power", n = 150), options = list(allocation_ratio = 2)))
  direct <- pwrss::power.t.student(d = 0.3, margin = 0, n2 = 100, n.ratio = 0.5, alpha = 0.05,
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
  expect_script_reproduces(met_spec(alternative = NULL, d = 0, goal = list(type = "sensitivity", n = 114, power = 0.8)))
  expect_script_reproduces(met_spec("paired_t", alternative = NULL, goal = list(type = "power", n = 60)))
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
