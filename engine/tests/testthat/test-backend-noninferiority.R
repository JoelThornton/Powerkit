# Non-inferiority by pwrss's one-sided tests against a margin: agreement
# with pwrss called directly, the direction of "better", refusals, and the
# exported script.

ni_spec <- function(name, goal = list(type = "power", n = 200), ...) {
  spec <- example_spec(name)
  spec$goal <- goal
  spec$options <- list(seed = 7)
  spec$population <- utils::modifyList(spec$population, list(...))
  spec
}

test_that("each template gives pwrss's power for the margin and the expected effect", {
  result <- run_spec(ni_spec("noninf_independent", d = 0.1))
  expect_equal(result$provenance$backend_function, "pwrss::power.t.student")
  direct <- pwrss::power.t.student(d = 0.1, margin = -0.3, n2 = 100, n.ratio = 1, alpha = 0.025,
                                   alternative = "one.sided", verbose = 0)$power
  expect_equal(result$curve$power, direct)
  expect_true(all(result$check_run$ok))

  direct <- pwrss::power.t.student(d = 0, margin = -0.25, n2 = 200, design = "paired", alpha = 0.025,
                                   alternative = "one.sided", verbose = 0)$power
  expect_equal(run_spec(ni_spec("noninf_paired"))$curve$power, direct)

  result <- run_spec(ni_spec("noninf_two_proportions", p2 = 0.72))
  expect_equal(result$provenance$backend_function, "pwrss::power.z.twoprops")
  direct <- pwrss::power.z.twoprops(prob1 = 0.72, prob2 = 0.7, margin = -0.1, n2 = 100, n.ratio = 1,
                                    alpha = 0.025, alternative = "one.sided", verbose = 0)$power
  expect_equal(result$curve$power, direct)
})

test_that("the required n agrees with pwrss's own", {
  n <- run_spec(ni_spec("noninf_independent", goal = list(type = "sample_size", power = 0.8)))$n_required$n
  per_group <- pwrss::power.t.student(d = 0, margin = -0.3, power = 0.8, alpha = 0.025, alternative = "one.sided", verbose = 0)$n
  expect_equal(n, sum(per_group))
  n <- run_spec(ni_spec("noninf_two_proportions", goal = list(type = "sample_size", power = 0.8)))$n_required$n
  per_group <- pwrss::power.z.twoprops(prob1 = 0.7, prob2 = 0.7, margin = -0.1, power = 0.8, alpha = 0.025,
                                       alternative = "one.sided", verbose = 0)$n
  expect_equal(n, sum(per_group))
})

test_that("when lower is better, a lower expected value raises power and a higher one lowers it", {
  base <- run_spec(ni_spec("noninf_one_sample", d = 0))$curve$power
  expect_gt(run_spec(ni_spec("noninf_one_sample", d = -0.1))$curve$power, base)
  expect_lt(run_spec(ni_spec("noninf_one_sample", d = 0.1))$curve$power, base)
  # Two proportions of an outcome to avoid (relapse): group 2 lower is better.
  relapse <- function(p2) run_spec(ni_spec("noninf_two_proportions", p1 = 0.3, p2 = p2, better = "lower"))$curve$power
  expect_gt(relapse(0.27), relapse(0.3))
  expect_lt(relapse(0.33), relapse(0.3))
})

test_that("an expected effect at or beyond the margin is refused, in plain English", {
  goal <- list(type = "sample_size", power = 0.8)
  expect_spec_problem(ni_spec("noninf_independent", goal = goal, d = -0.4), "worse than the non-inferiority margin")
  expect_spec_problem(ni_spec("noninf_independent", goal = goal, d = -0.3), "exactly at")
  expect_spec_problem(ni_spec("noninf_one_sample", goal = goal, d = 0.35), "worse than")
  expect_spec_problem(ni_spec("noninf_two_proportions", goal = goal, p2 = 0.55), "worse than")
})

test_that("unequal groups pass both group sizes to pwrss", {
  spec <- ni_spec("noninf_independent", goal = list(type = "power", n = 300))
  spec$options$allocation_ratio <- 2
  direct <- pwrss::power.t.student(d = 0, margin = -0.3, n2 = 200, n.ratio = 0.5, alpha = 0.025,
                                   alternative = "one.sided", verbose = 0)$power
  expect_equal(run_spec(spec)$curve$power, direct)
})

test_that("the exported script reproduces each non-inferiority result", {
  for (name in c("noninf_independent", "noninf_paired", "noninf_one_sample", "noninf_two_proportions")) {
    spec <- ni_spec(name, goal = list(type = "sample_size", power = 0.9))
    result <- run_spec(spec)
    out <- run_exported_script(spec, result)
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10, info = name)
  }
  spec <- ni_spec("noninf_two_proportions", p1 = 0.3, p2 = 0.3, better = "lower")
  spec$options$allocation_ratio <- 1.5
  result <- run_spec(spec)
  out <- run_exported_script(spec, result)
  expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10)
})
