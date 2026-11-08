# Small telescopes (Simonsohn, 2015): the replication's one-sided test of
# whether the effect is smaller than the original's d33 (r33), for a true
# effect of 0. d33 from pwr; the test's power from pwrss.

telescope_spec <- function(template = "independent_t", sizes = list(n1 = 20L, n2 = 20L), effect = 0.6,
                           goal = list(type = "sample_size", power = 0.8)) {
  spec <- example_spec(template)
  field <- switch(template, paired_t = "dz", correlation = "r", "d")
  spec$population[[field]] <- effect
  spec$effect_justification <- list(type = "prior_study", source = "The original study", small_telescopes = sizes)
  spec$goal <- goal
  spec
}

test_that("d33 is the effect the original study had a third of a chance to find, from pwr", {
  expect_equal(telescope_effect("independent_t", n1 = 20, n2 = 20)$effect,
    pwr::pwr.t2n.test(n1 = 20, n2 = 20, power = 1 / 3)$d)
  expect_equal(pwr::pwr.t2n.test(n1 = 20, n2 = 20, d = telescope_effect("independent_t", n1 = 20, n2 = 20)$effect)$power, 1 / 3,
    tolerance = 1e-4)
  expect_identical(telescope_effect("correlation", n = 40)$effect_name, "r33")
  expect_identical(telescope_effect("paired_t", n = 30)$effect_name, "d_z33")
})

test_that("the replication needs about 2.5 times the original sample, as Simonsohn's rule says", {
  result <- run_spec(telescope_spec())
  expect_equal(result$provenance$backend, "pwrss")
  # 20 per group in the original: d33 = 0.496, and 51 per group.
  expect_equal(result$n_required$n, 102)
  expect_equal(result$small_telescopes$effect, 0.4959, tolerance = 1e-3)
  expect_equal(result$small_telescopes$original_n, 40)
  expect_null(result$critical_effect)
  for (n in c(10L, 50L)) {
    n_rep <- run_spec(telescope_spec(sizes = list(n1 = n, n2 = n)))$n_required$n
    expect_gte(n_rep / (2 * n), 2.3)
    expect_lte(n_rep / (2 * n), 2.7)
  }
  # And at 2.5 times, power is close to 80%.
  power <- run_spec(telescope_spec(goal = list(type = "power", n = 100L)))$curve$power
  expect_equal(power, 0.8, tolerance = 0.02)
})

test_that("the paired and one-sample t-tests and the correlation are covered", {
  expect_equal(run_spec(telescope_spec("paired_t", list(n = 30L), effect = 0.5))$n_required$n, 75)
  expect_equal(run_spec(telescope_spec("correlation", list(n = 40L), effect = 0.4))$n_required$n, 103)
  one <- run_spec(telescope_spec("one_sample_t", list(n = 30L), effect = 0.5))$n_required$n
  expect_equal(one, 75)
})

test_that("the original effect's sign sets the direction, not the size", {
  up <- run_spec(telescope_spec(effect = 0.6))
  down <- run_spec(telescope_spec(effect = -0.3))
  expect_equal(down$n_required$n, up$n_required$n)
  expect_lt(down$small_telescopes$effect, 0)
})

test_that("small telescopes says plainly what it can't combine with", {
  spec <- telescope_spec()
  spec$effect_justification$safeguard <- list(n1 = 20L, n2 = 20L)
  expect_spec_problem(spec, "small telescopes or safeguard power, not both")
  spec <- telescope_spec()
  spec$target_test$method <- "mann_whitney"
  expect_spec_problem(spec, "doesn't combine with a rank")
  spec <- telescope_spec(goal = list(type = "sensitivity", n = 100L, power = 0.8))
  expect_spec_problem(spec, "the replication's sample size, or its power")
  expect_spec_problem(telescope_spec(sizes = list(n1 = 20L)), "original study's group sizes")
  spec <- example_spec("anova_oneway_between")
  spec$effect_justification <- list(type = "prior_study", source = "x", small_telescopes = list(n = 30L))
  expect_spec_problem(spec, "not for this design")
  # No adjustment is asked for: d33 doesn't depend on the original estimate.
  expect_s3_class(validate_spec(telescope_spec()), "powerkit_spec")
})

test_that("the exported script reproduces small telescopes from pwr and pwrss alone", {
  skip_unless_scripts_can_run()
  for (spec in list(telescope_spec(), telescope_spec("correlation", list(n = 40L), effect = 0.4),
                    telescope_spec("paired_t", list(n = 30L), effect = 0.5, goal = list(type = "power", n = 75L)))) {
    result <- run_spec(spec)
    run <- run_exported_script(spec, result)
    expect_equal(run$reproduced, run$powerkit, tolerance = 1e-10)
    expect_false(any(grepl("powerkit::|library\\(powerkit\\)", run$script)))
  }
})
