# One-way repeated measures with an SD per condition, a correlation per
# pair and a sphericity correction (Superpower's ANOVA_design() and
# ANOVA_exact(correction =)).

covariance_spec <- function(correction = NULL, n = 30, sd = c(100, 120, 150), r = c(0.8, 0.5, 0.6)) {
  spec <- example_spec("anova_oneway_within")
  spec$population$means <- list(600, 630, 650)
  spec$population$sd <- sd
  spec$population$r <- r
  spec$target_test$correction <- correction
  spec$goal <- list(type = "power", n = n)
  spec
}

direct_exact <- function(correction) {
  design <- with_seed(NULL, Superpower::ANOVA_design("3w", n = 30, mu = c(600, 630, 650), sd = c(100, 120, 150),
    r = c(0.8, 0.5, 0.6), plot = FALSE))
  suppressWarnings(Superpower::ANOVA_exact(design, correction = correction, verbose = FALSE))
}

test_that("an SD per condition and a correlation per pair reach Superpower, with each correction", {
  for (correction in c("none", "GG", "HF")) {
    result <- run_quietly(covariance_spec(correction))
    direct <- direct_exact(correction)
    expect_equal(result$curve$power, direct$main_results["a", "power"] / 100, tolerance = 1e-8, label = correction)
    expect_true(all(result$check_run$ok), label = correction)
  }
  # The MANOVA approach doesn't assume sphericity and is shown beside it.
  expect_equal(run_quietly(covariance_spec())$manova$power, direct_exact("none")$manova_results["a", "power"] / 100, tolerance = 1e-8)
})

test_that("without sphericity, the corrections cost power; with it, they change nothing", {
  none <- run_quietly(covariance_spec("none"))$curve$power
  gg <- run_quietly(covariance_spec("GG"))$curve$power
  expect_gt(none - gg, 0.03)
  equal <- covariance_spec("GG", sd = 100, r = 0.6)
  expect_equal(run_quietly(equal)$curve$power, run_quietly(covariance_spec("none", sd = 100, r = 0.6))$curve$power, tolerance = 1e-6)
})

test_that("departure: the size of the Greenhouse-Geisser correction, the app's default (Departure 26)", {
  # docs/conventions.md, Departure 26: means 600, 620 and 650, SD 100,
  # correlations .8, .5 and .2, 40 people. Superpower's default (no
  # correction) gives 80.5%; the corrected test, which the app plans for
  # once the SDs or correlations differ, 68.4%, and needs 52 people for 80%.
  spec <- function(correction, goal = list(type = "power", n = 40)) {
    s <- covariance_spec(correction, sd = c(100, 100, 100), r = c(0.8, 0.5, 0.2))
    s$population$means <- list(600, 620, 650)
    s$goal <- goal
    s
  }
  expect_equal(run_quietly(spec("none"))$curve$power, 0.805, tolerance = 0.001)
  expect_equal(run_quietly(spec("GG"))$curve$power, 0.684, tolerance = 0.001)
  target <- list(type = "sample_size", power = 0.8)
  expect_equal(run_quietly(spec("none", target))$n_required$n, 40)
  expect_equal(run_quietly(spec("GG", target))$n_required$n, 52)
})

test_that("impossible or mismatched SDs and correlations are refused in plain words", {
  expect_spec_problem(covariance_spec(r = c(0.9, 0.1, 0.9)), "can't all hold at once")
  expect_spec_problem(covariance_spec(r = c(0.5, 0.5, 0.5, 0.5)), "one correlation per pair of conditions (3")
  eta <- example_spec("anova_oneway_within")
  eta$population <- list(metric = "eta_squared", eta_squared = 0.06, eta_source = "published")
  eta$target_test$correction <- "GG"
  expect_spec_problem(eta, "needs the condition means, SDs and correlations")
  between <- example_spec("anova_oneway_between")
  between$target_test$correction <- "GG"
  expect_spec_problem(between, "only applies to repeated-measures ANOVAs")
})

test_that("the exported script reproduces a corrected test with unequal SDs and correlations", {
  skip_unless_scripts_can_run()
  spec <- covariance_spec("GG")
  expect_script_reproduces_power(spec, run_for_export(spec))
})
