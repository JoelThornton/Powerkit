# Wave 2 engine groundwork (docs/coverage-roadmap.md): one-way ANOVA,
# R-squared in multiple regression, one proportion, McNemar's test and
# Welch's t-test by formula. Each is checked against its backend called
# directly, from inputs written out by hand here. The checks against
# G*Power use the maintainer's screenshots (McNemar's a priori N is still a placeholder).

wave2_spec <- function(name, goal, ...) {
  spec <- example_spec(name)
  spec$options <- list(seed = 7)
  spec$goal <- goal
  changes <- list(...)
  spec[names(changes)] <- changes
  spec
}

power_at <- function(spec) run_spec(spec)$curve$power

welch_exact_spec <- function(goal, ratio = 1, alternative = NULL) {
  spec <- example_spec("independent_t")
  spec$target_test$method <- "welch_t"
  spec$target_test$alternative <- alternative
  spec$options <- list(seed = 7, method = "exact", allocation_ratio = ratio)
  spec$goal <- goal
  spec
}

test_that("each wave 2 test runs on its backend, exactly, and passes its check run", {
  cases <- list(
    anova_oneway_between = "Superpower",
    regression_r2_zero = "pwrss",
    regression_r2_increase = "pwrss",
    one_proportion = "pwrss",
    mcnemar = "pwrss"
  )
  for (name in names(cases)) {
    result <- run_spec(wave2_spec(name, list(type = "power", n = 120)))
    expect_equal(result$provenance$backend, cases[[name]], info = name)
    expect_equal(result$provenance$method, "exact", info = name)
    expect_equal(result$curve$mcse, 0, info = name)
    expect_true(all(result$check_run$ok), info = name)
  }
  result <- run_spec(welch_exact_spec(list(type = "power", n = 120)))
  expect_equal(result$provenance$backend, "pwrss")
  expect_equal(result$provenance$method, "exact")
})

test_that("one-way ANOVA equals Superpower's ANOVA_exact() called directly, and pwr's balanced formula", {
  # Example: means 10, 11, 13; SD 6; three groups of 40.
  power <- power_at(wave2_spec("anova_oneway_between", list(type = "power", n = 120)))
  design <- Superpower::ANOVA_design(design = "3b", n = 40, mu = c(10, 11, 13), sd = 6, plot = FALSE)
  set.seed(7)
  direct <- Superpower::ANOVA_exact(design, alpha_level = 0.05, verbose = FALSE)
  expect_equal(power, direct$main_results["a", "power"] / 100)
  # The same test by pwr's balanced one-way formula: Cohen's f is the SD
  # of the group means (dividing by k) over the within-group SD.
  means <- c(10, 11, 13)
  f <- sqrt(mean((means - mean(means))^2)) / 6
  expect_equal(power, pwr::pwr.anova.test(k = 3, n = 40, f = f, sig.level = 0.05)$power, tolerance = 1e-6)
})

test_that("one-way ANOVA needs equal groups, one mean per level, and has no sensitivity yet", {
  spec <- wave2_spec("anova_oneway_between", list(type = "power", n = 100))
  expect_spec_problem(spec, "split into 3 equal groups")
  spec$goal$n <- 120
  spec$population$means <- list(10, 11, 13, 14)
  expect_spec_problem(spec, "'population > means' has 4 values")
  spec <- wave2_spec("anova_oneway_between", list(type = "power", n = 120))
  spec$variables$A$levels <- list("None", "Praise")
  spec$population$means <- list(10, 13)
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  sens <- wave2_spec("anova_oneway_between", list(type = "sensitivity", n = 120, power = 0.8))
  expect_error(run_spec(sens), class = "powerkit_not_available")
})

test_that("R-squared against 0 equals pwrss::power.f.regression() called directly", {
  # Example: R-squared 0.10 with 5 predictors.
  power <- power_at(wave2_spec("regression_r2_zero", list(type = "power", n = 100)))
  direct <- pwrss::power.f.regression(
    r.squared.change = 0.1, k.total = 5, k.tested = 5, n = 100, alpha = 0.05, verbose = 0
  )
  expect_equal(power, direct$power)
  # pwrss's convention, from its source: noncentrality f^2 * n, with
  # f^2 = R2 / (1 - R2), on 5 and n - 5 - 1 degrees of freedom.
  f2 <- 0.1 / 0.9
  analytic <- 1 - stats::pf(stats::qf(0.95, 5, 94), 5, 94, ncp = f2 * 100)
  expect_equal(power, analytic, tolerance = 1e-10)
})

test_that("an R-squared increase passes pwrss the partial R-squared, giving Cohen's f^2", {
  # Example: R-squared 0.10 with 3 controls, 0.15 with 2 more predictors.
  power <- power_at(wave2_spec("regression_r2_increase", list(type = "power", n = 150)))
  partial <- (0.15 - 0.10) / (1 - 0.10)
  direct <- pwrss::power.f.regression(
    r.squared.change = partial, k.total = 5, k.tested = 2, n = 150, alpha = 0.05, verbose = 0
  )
  expect_equal(power, direct$power)
  # Cohen's f^2 for an increase: (R2_full - R2_reduced) / (1 - R2_full).
  f2 <- (0.15 - 0.10) / (1 - 0.15)
  analytic <- 1 - stats::pf(stats::qf(0.95, 2, 144), 2, 144, ncp = f2 * 150)
  expect_equal(power, analytic, tolerance = 1e-10)
})

test_that("R-squared specs that can't be right are refused", {
  spec <- wave2_spec("regression_r2_increase", list(type = "power", n = 150))
  spec$population$r2_reduced <- 0.2
  expect_spec_problem(spec, "can't be more than 'r2_full'")
  spec <- wave2_spec("regression_r2_increase", list(type = "power", n = 150))
  spec$population$predictors_tested <- 6
  expect_spec_problem(spec, "can't be more than 'predictors_total'")
  spec <- wave2_spec("regression_r2_zero", list(type = "power", n = 6))
  expect_spec_problem(spec, "needs at least 7 participants")
  spec <- wave2_spec("regression_r2_zero", list(type = "power", n = 100))
  spec$target_test$alternative <- "greater"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})

test_that("one proportion equals pwrss::power.exact.oneprop() called directly", {
  # Example: 65% against 50%.
  power <- power_at(wave2_spec("one_proportion", list(type = "power", n = 80)))
  direct <- pwrss::power.exact.oneprop(
    prob = 0.65, null.prob = 0.5, n = 80, alpha = 0.05, alternative = "two.sided", verbose = 0
  )
  expect_equal(power, direct$power)
  spec <- wave2_spec("one_proportion", list(type = "power", n = 80))
  spec$target_test$alternative <- "greater"
  direct <- pwrss::power.exact.oneprop(
    prob = 0.65, null.prob = 0.5, n = 80, alpha = 0.05, alternative = "one.sided", verbose = 0
  )
  expect_equal(power_at(spec), direct$power)
})

test_that("McNemar's test equals pwrss::power.exact.mcnemar() called directly", {
  # Example: 10% yes before only, 25% yes after only.
  power <- power_at(wave2_spec("mcnemar", list(type = "power", n = 100)))
  direct <- pwrss::power.exact.mcnemar(
    prob10 = 0.25, prob01 = 0.10, n.paired = 100, alpha = 0.05,
    alternative = "two.sided", method = "exact", verbose = 0
  )
  expect_equal(power, direct$power)
})

test_that("exact tests of counts report the smallest n that reaches the target", {
  # Power goes up and down with n for exact tests of counts, so every
  # smaller n must fall short.
  for (name in c("one_proportion", "mcnemar")) {
    result <- run_spec(wave2_spec(name, list(type = "sample_size", power = 0.8)))
    spec <- validate_spec(wave2_spec(name, list(type = "sample_size", power = 0.8)))
    backend <- route_spec(spec)
    smaller <- seq(backend$exact_min_n, result$n_required$n - 1)
    expect_true(all(vapply(smaller, backend$exact_power, numeric(1)) < 0.8), info = name)
    expect_gte(backend$exact_power(result$n_required$n), 0.8)
  }
  # The example's one-proportion power dips below 0.80 again after n = 90
  # (pwrss's own sample-size answer is 92; see docs/coverage-roadmap.md).
  one <- run_spec(wave2_spec("one_proportion", list(type = "sample_size", power = 0.8)))
  expect_equal(one$n_required$n, 90)
})

test_that("departure: pwrss's own sample-size answer for exact tests of counts (Departure 12)", {
  own_oneprop <- pwrss::power.exact.oneprop(
    prob = 0.65, null.prob = 0.5, power = 0.8, alpha = 0.05, alternative = "two.sided", verbose = 0
  )$n
  own_mcnemar <- pwrss::power.exact.mcnemar(
    prob10 = 0.25, prob01 = 0.10, power = 0.8, alpha = 0.05,
    alternative = "two.sided", method = "exact", verbose = 0
  )$n.paired
  ours <- function(name) run_spec(wave2_spec(name, list(type = "sample_size", power = 0.8)))$n_required$n
  expect_equal(c(own_oneprop, own_mcnemar), c(92, 130))
  expect_equal(c(ours("one_proportion"), ours("mcnemar")), c(90, 129))
})

test_that("McNemar and one-proportion specs that can't be right are refused", {
  spec <- wave2_spec("mcnemar", list(type = "power", n = 100))
  spec$population$p_first_only <- 0.8
  expect_spec_problem(spec, "add up to 1.05")
  spec <- wave2_spec("one_proportion", list(type = "power", n = 80))
  spec$target_test$alternative <- "less"
  expect_spec_problem(spec, "goes the other way")
  spec <- wave2_spec("one_proportion", list(type = "power", n = 80))
  spec$options$method <- "simulation"
  expect_spec_problem(spec, "'simulation' isn't available for this test yet")
})

test_that("Welch's t-test by formula equals pwrss::power.t.welch(), and stays on Spower by default", {
  power <- power_at(welch_exact_spec(list(type = "power", n = 120), ratio = 2))
  # 40 in group 1, 80 in group 2; pwrss's n.ratio is n1 / n2.
  direct <- pwrss::power.t.welch(
    d = 0.4, var.ratio = 1, n.ratio = 40 / 80, n2 = 80, alpha = 0.05,
    alternative = "two.sided", claim.basis = "md.pval", verbose = 0
  )
  expect_equal(power, direct$power)
  default <- welch_exact_spec(list(type = "power", n = 120))
  default$options$method <- NULL
  expect_equal(route_spec(validate_spec(default))$name, "Spower")
  expect_spec_problem(
    welch_exact_spec(list(type = "power", n = 120), alternative = "less"),
    "goes the other way"
  )
})

test_that("one-way recruitment rounds up each group", {
  spec <- wave2_spec("anova_oneway_between", list(type = "power", n = 120))
  spec$options$attrition <- 0.15
  result <- run_spec(spec)
  expect_equal(result$recruitment$groups_recruit, rep(48, 3))
  expect_equal(result$recruitment$unit, "group")
})

test_that("exported scripts for the wave 2 tests reproduce powerkit's results", {
  skip_on_cran()
  specs <- list(
    wave2_spec("anova_oneway_between", list(type = "sample_size", power = 0.8)),
    wave2_spec("regression_r2_zero", list(type = "power", n = 100)),
    wave2_spec("regression_r2_increase", list(type = "sample_size", power = 0.8)),
    wave2_spec("one_proportion", list(type = "sample_size", power = 0.8)),
    wave2_spec("mcnemar", list(type = "power", n = 100), options = list(seed = 7, attrition = 0.1)),
    welch_exact_spec(list(type = "sample_size", power = 0.8), ratio = 2)
  )
  for (spec in specs) {
    result <- run_spec(spec)
    out <- run_exported_script(spec, result)
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10, info = spec$template)
  }
})

# Reference for the G*Power tests below: G*Power values, not published
#   ones. G*Power 3.1, maintainer's screenshots, 18 October 2026
#   (docs/figures/gpower/A10_*, A11_*, A23_*, A35_*, A37_*; recorded in
#   docs/gpower-parity.md, "Wave 2"). alpha = .05 throughout. Effect sizes
#   are entered here exactly as typed into G*Power (f, f2), so the spec's
#   inputs are set to give those values.

test_that("one-way ANOVA matches G*Power (G*Power values)", {
  skip_if_not_installed("Superpower")
  # F tests, "ANOVA: Fixed effects, omnibus, one-way", 3 groups, f = 0.279
  # (the screenshots used 0.279, not the example's 0.2079). Means -a, 0, a
  # with SD 1 give f = a * sqrt(2 / 3).
  a <- 0.279 / sqrt(2 / 3)
  population <- list(metric = "raw", means = c(-a, 0, a), sd = 1)
  spec <- wave2_spec("anova_oneway_between", list(type = "sample_size", power = 0.8), population = population)
  # A priori: total N 129, actual power 0.8072995.
  expect_identical(as.integer(sum(run_spec(spec)$n_required$n)), 129L)
  spec$goal <- list(type = "power", n = 129)
  expect_equal(round(power_at(spec), 7), 0.8072995)
  # Post hoc: N = 120, power 0.7757040.
  spec$goal <- list(type = "power", n = 120)
  expect_equal(round(power_at(spec), 7), 0.7757040)
})

test_that("R-squared against zero matches G*Power (G*Power values)", {
  # F tests, "Linear multiple regression: Fixed model, R2 deviation from
  # zero", 5 predictors, f2 = 0.1111 (R2 = f2 / (1 + f2)).
  population <- list(metric = "r_squared", r2 = 0.1111 / 1.1111, predictors = 5)
  spec <- wave2_spec("regression_r2_zero", list(type = "sample_size", power = 0.8), population = population)
  # A priori: total N 122, actual power 0.8034946.
  expect_identical(as.integer(run_spec(spec)$n_required$n), 122L)
  spec$goal <- list(type = "power", n = 122)
  expect_equal(round(power_at(spec), 7), 0.8034946)
  # Post hoc: N = 100, power 0.7013300 (noncentrality 11.11 = f2 * N).
  spec$goal <- list(type = "power", n = 100)
  expect_equal(round(power_at(spec), 7), 0.7013300)
})

test_that("R-squared increase matches G*Power, whose noncentrality is f2 * N (G*Power value)", {
  # F tests, "Linear multiple regression: Fixed model, R2 increase", 2
  # tested of 5 predictors, f2 = 0.0588. With R2 reduced = .10,
  # f2 = (full - .10) / (1 - full) gives full = (.0588 + .10) / 1.0588.
  population <- list(
    metric = "r_squared", r2_full = (0.0588 + 0.10) / 1.0588, r2_reduced = 0.10,
    predictors_total = 5, predictors_tested = 2
  )
  spec <- wave2_spec("regression_r2_increase", list(type = "sample_size", power = 0.8), population = population)
  # A priori: total N 167, actual power 0.8001440, noncentrality 9.8196
  # (= 0.0588 * 167, pwrss's convention, not pwr's f2 * (u + v + 1)).
  expect_identical(as.integer(run_spec(spec)$n_required$n), 167L)
  spec$goal <- list(type = "power", n = 167)
  expect_equal(round(power_at(spec), 7), 0.8001440)
})

test_that("one proportion matches G*Power, including the smallest N (G*Power values)", {
  # Exact, "Proportion: Difference from constant (binomial test, one
  # sample case)", constant proportion .50, effect size g = .15 (.65).
  spec <- wave2_spec("one_proportion", list(type = "sample_size", power = 0.8))
  # A priori, two tails: total N 90, actual power 0.8122881. G*Power
  # reports the smallest N that reaches the target, as powerkit does
  # (pwrss's own answer is 92; Departure 12).
  expect_identical(as.integer(run_spec(spec)$n_required$n), 90L)
  spec$goal <- list(type = "power", n = 90)
  expect_equal(round(power_at(spec), 7), 0.8122881)
  # Post hoc, N = 80: two tails 0.7235283; one tail 0.8540286.
  spec$goal <- list(type = "power", n = 80)
  expect_equal(round(power_at(spec), 7), 0.7235283)
  spec$target_test$alternative <- "greater"
  expect_equal(round(power_at(spec), 7), 0.8540286)
})

test_that("McNemar matches G*Power's exact option (G*Power value)", {
  # Exact, "Proportions: Inequality, two dependent groups (McNemar)", two
  # tails, odds ratio 2.5, proportion of discordant pairs .35, Options:
  # "exact (unconditional) power". Post hoc, N = 100: power 0.7186706
  # with the faster approximation, 0.6742876 with the exact option
  # (docs/figures/gpower/A37_mcnemar_post_hoc_n100_exact.png).
  spec <- wave2_spec("mcnemar", list(type = "power", n = 100))
  expect_equal(round(power_at(spec), 7), 0.6742876)
})

test_that("McNemar a priori N against G*Power's exact option (placeholder)", {
  # TODO_PUBLISHED_VALUE: the a priori screenshot sent with the exact
  # option set it to apply only "if N < 100", so its answer (121) came
  # from the approximation. powerkit's exact answer is 129. Waits for an a
  # priori screenshot with the exact option for every N.
  skip("G*Power's exact a priori McNemar N not yet sent (TODO_PUBLISHED_VALUE)")
})
