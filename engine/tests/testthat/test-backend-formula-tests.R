# More tests by formula (the maintainer's direction, 18 October 2026):
# Fisher's exact test, chi-square goodness of fit, two independent
# correlations, two dependent correlations and one-way ANCOVA, each one
# pwrss call. Each is checked
# against its backend called directly, from inputs written out by hand,
# and against a second package where one does the same test. No G*Power
# or published values yet: validation comes later.

formula_spec <- function(name, goal, ...) {
  spec <- example_spec(name)
  spec$options <- list(seed = 7)
  spec$goal <- goal
  changes <- list(...)
  spec[names(changes)] <- changes
  spec
}

test_that("each formula test runs on pwrss, exactly, and passes its check run", {
  cases <- c(
    fisher_exact = "pwrss::power.exact.fisher",
    chi_square_gof = "pwrss::power.chisq.gof",
    two_correlations = "pwrss::power.z.twocors",
    overlapping_correlations = "pwrss::power.z.twocors.steiger",
    nonoverlapping_correlations = "pwrss::power.z.twocors.steiger",
    anova_oneway_ancova = "pwrss::power.f.ancova.shieh"
  )
  for (name in names(cases)) {
    result <- run_spec(formula_spec(name, list(type = "power", n = 120)))
    expect_equal(result$provenance$backend, "pwrss", info = name)
    expect_equal(result$provenance$backend_function, cases[[name]], info = name)
    expect_equal(result$provenance$method, "exact", info = name)
    expect_true(all(result$check_run$ok), info = name)
  }
  # The z test of two proportions keeps its own backends.
  z <- example_spec("two_proportions")
  z$goal <- list(type = "power", n = 120)
  expect_false(identical(route_spec(validate_spec(z))$functions[["exact"]], "pwrss::power.exact.fisher"))
})

test_that("Fisher's exact test equals pwrss::power.exact.fisher() called directly", {
  # Example: 30% against 60% attending; 40 in group 1, 80 in group 2.
  spec <- formula_spec("fisher_exact", list(type = "power", n = 120), options = list(seed = 7, allocation_ratio = 2))
  direct <- pwrss::power.exact.fisher(
    prob1 = 0.3, prob2 = 0.6, n.ratio = 40 / 80, n2 = 80, alpha = 0.05,
    alternative = "two.sided", method = "exact", ceil.n = FALSE, verbose = 0
  )
  expect_equal(run_spec(spec)$curve$power, direct$power)
})

test_that("Fisher's exact test reports the smallest n that reaches the target, in whole equal groups", {
  spec <- validate_spec(formula_spec("fisher_exact", list(type = "sample_size", power = 0.8)))
  result <- run_spec(spec)
  expect_equal(result$n_required$n %% 2, 0)
  backend <- route_spec(spec)
  smaller <- seq(backend$exact_min_n, result$n_required$n - 2, by = 2)
  expect_true(all(vapply(smaller, backend$exact_power, numeric(1)) < 0.8))
  expect_gte(backend$exact_power(result$n_required$n), 0.8)
})

test_that("goodness of fit equals pwrss::power.chisq.gof(), and pwr's chi-square formula", {
  # Example: 25%, 30% and 45% against a third each; n = 120.
  power <- run_spec(formula_spec("chi_square_gof", list(type = "power", n = 120)))$curve$power
  p <- c(0.25, 0.3, 0.45)
  w <- pwrss::probs.to.w(p, verbose = 0)
  direct <- pwrss::power.chisq.gof(w = w$w, df = 2, n = 120, alpha = 0.05, ceil.n = FALSE, verbose = 0)
  expect_equal(power, direct$power)
  # The same test by pwr: Cohen's w from ES.w1(), df = categories - 1.
  pwr_w <- pwr::ES.w1(rep(1 / 3, 3), p)
  expect_equal(power, pwr::pwr.chisq.test(w = pwr_w, N = 120, df = 2, sig.level = 0.05)$power, tolerance = 1e-8)
  # Fixed proportions other than equal ones.
  spec <- formula_spec("chi_square_gof", list(type = "power", n = 120))
  spec$population$null_probabilities <- list(0.2, 0.3, 0.5)
  pwr_w <- pwr::ES.w1(c(0.2, 0.3, 0.5), p)
  expect_equal(run_spec(spec)$curve$power, pwr::pwr.chisq.test(w = pwr_w, N = 120, df = 2, sig.level = 0.05)$power, tolerance = 1e-8)
})

test_that("goodness-of-fit specs that can't be right are refused", {
  spec <- formula_spec("chi_square_gof", list(type = "power", n = 120))
  spec$population$probabilities <- list(0.25, 0.75)
  expect_spec_problem(spec, "'population > probabilities' has 2 values")
  spec$population$probabilities <- list(0.25, 0.3, 0.3)
  expect_spec_problem(spec, "must add up to 1")
  spec <- formula_spec("chi_square_gof", list(type = "power", n = 120))
  spec$target_test$alternative <- "greater"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})

test_that("two correlations equal pwrss::power.z.twocors() called directly", {
  # Example: r = .20 against .45; 60 in group 1, 120 in group 2.
  spec <- formula_spec("two_correlations", list(type = "power", n = 180), options = list(seed = 7, allocation_ratio = 2))
  direct <- pwrss::power.z.twocors(
    rho1 = 0.2, rho2 = 0.45, n.ratio = 60 / 120, n2 = 120, alpha = 0.05,
    alternative = "two.sided", ceil.n = FALSE, verbose = 0
  )
  expect_equal(run_spec(spec)$curve$power, direct$power)
  spec$target_test$alternative <- "less"
  expect_spec_problem(spec, "goes the other way")
  spec$target_test$alternative <- "greater"
  expect_gt(run_spec(spec)$curve$power, direct$power)
})

test_that("ANCOVA equals pwrss::power.f.ancova.shieh(), and Superpower's Shieh method", {
  # Example: adjusted means 20, 18, 16; SD 6; covariate R-squared .36;
  # one covariate; three groups of 30.
  power <- run_spec(formula_spec("anova_oneway_ancova", list(type = "power", n = 90)))$curve$power
  direct <- pwrss::power.f.ancova.shieh(
    mu.vector = c(20, 18, 16), sd.vector = rep(6, 3), n.vector = rep(30, 3),
    r.squared = 0.36, k.covariates = 1, alpha = 0.05, ceil.n = FALSE, verbose = 0
  )
  expect_equal(power, direct$power)
  skip_if_not_installed("Superpower")
  other <- Superpower::power_oneway_ancova(
    mu = c(20, 18, 16), n = rep(30, 3), n_cov = 1, r2 = 0.36, sd = 6, alpha_level = 0.05, type = "exact"
  )
  expect_equal(power, other$power / 100, tolerance = 1e-4)
})

test_that("ANCOVA needs equal groups and one mean per group, and has no simulation", {
  spec <- formula_spec("anova_oneway_ancova", list(type = "power", n = 100))
  expect_spec_problem(spec, "split into 3 equal groups")
  spec$goal$n <- 90
  spec$population$means <- list(20, 18)
  expect_spec_problem(spec, "'population > means' has 2 values")
  spec <- formula_spec("anova_oneway_ancova", list(type = "power", n = 90))
  spec$options$method <- "simulation"
  expect_spec_problem(spec, "'simulation' isn't available for this test yet")
})

test_that("exported scripts for the formula tests reproduce powerkit's results", {
  skip_on_cran()
  specs <- list(
    formula_spec("fisher_exact", list(type = "sample_size", power = 0.8)),
    formula_spec("fisher_exact", list(type = "power", n = 90), options = list(seed = 7, allocation_ratio = 2)),
    formula_spec("chi_square_gof", list(type = "sample_size", power = 0.8)),
    formula_spec("two_correlations", list(type = "power", n = 180), options = list(seed = 7, attrition = 0.1)),
    formula_spec("overlapping_correlations", list(type = "sample_size", power = 0.8)),
    formula_spec("nonoverlapping_correlations", list(type = "power", n = 150), options = list(seed = 7, attrition = 0.1)),
    formula_spec("anova_oneway_ancova", list(type = "sample_size", power = 0.8))
  )
  for (spec in specs) {
    result <- run_spec(spec)
    out <- run_exported_script(spec, result)
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10, info = spec$template)
  }
})

# Two dependent correlations (one group) -----------------------------------------

test_that("overlapping correlations equal pwrss::power.z.twocors.steiger() called directly", {
  # Example: X with Y .40 against X with Z .20; Y with Z .50; n = 150.
  spec <- formula_spec("overlapping_correlations", list(type = "power", n = 150))
  direct <- pwrss::power.z.twocors.steiger(
    rho12 = 0.4, rho13 = 0.2, rho23 = 0.5, n = 150, alpha = 0.05,
    alternative = "two.sided", pooled = FALSE, common.index = TRUE, ceil.n = FALSE, verbose = 0
  )
  expect_equal(run_spec(spec)$curve$power, direct$power)
  # The second correlation (r_X_Z) is the smaller, so a one-sided test is
  # "less"; "greater" points the other way.
  spec$target_test$alternative <- "greater"
  expect_spec_problem(spec, "goes the other way")
  spec$target_test$alternative <- "less"
  expect_gt(run_spec(spec)$curve$power, direct$power)
})

test_that("non-overlapping correlations equal pwrss::power.z.twocors.steiger() called directly", {
  # Example: X1 with Y1 .20 against X2 with Y2 .40; X1-X2 and Y1-Y2 .50,
  # cross-correlations .10; n = 150.
  spec <- formula_spec("nonoverlapping_correlations", list(type = "power", n = 150))
  direct <- pwrss::power.z.twocors.steiger(
    rho12 = 0.2, rho34 = 0.4, rho13 = 0.5, rho14 = 0.1, rho23 = 0.1, rho24 = 0.5,
    n = 150, alpha = 0.05, alternative = "two.sided", pooled = FALSE,
    common.index = FALSE, ceil.n = FALSE, verbose = 0
  )
  expect_equal(run_spec(spec)$curve$power, direct$power)
  spec$target_test$alternative <- "less"
  expect_spec_problem(spec, "goes the other way")
  spec$target_test$alternative <- "greater"
  expect_gt(run_spec(spec)$curve$power, direct$power)
})

test_that("dependent correlations: the required n is the smallest that reaches the target", {
  for (name in c("overlapping_correlations", "nonoverlapping_correlations")) {
    spec <- validate_spec(formula_spec(name, list(type = "sample_size", power = 0.8)))
    result <- run_spec(spec)
    backend <- route_spec(spec)
    n <- result$n_required$n
    expect_gte(backend$exact_power(n), 0.8)
    expect_lt(backend$exact_power(n - 1), 0.8)
  }
})

test_that("dependent correlations that can't be right are refused", {
  spec <- formula_spec("overlapping_correlations", list(type = "power", n = 150))
  # X with Y .40, X with Z .90 and Y with Z -.50 can't all hold at once.
  spec$population$r_X_Z <- 0.9
  spec$population$r_Y_Z <- -0.5
  expect_spec_problem(spec, "impossible together")
  spec <- formula_spec("nonoverlapping_correlations", list(type = "power", n = 150))
  spec$population$r_X1_X2 <- 0.95
  spec$population$r_Y1_Y2 <- -0.95
  expect_spec_problem(spec, "impossible together")
  # Equal compared correlations: nothing to detect (two-sided power), and
  # no sample size can reach the target.
  spec <- formula_spec("overlapping_correlations", list(type = "power", n = 150))
  spec$population$r_X_Z <- 0.4
  expect_spec_problem(spec, "(r_X_Y and r_X_Z) are equal")
  spec$goal <- list(type = "sample_size", power = 0.8)
  expect_spec_problem(spec, "The effect you want to detect is zero")
  # No simulation, and allocation ratios belong to two-group designs.
  spec <- formula_spec("nonoverlapping_correlations", list(type = "power", n = 150))
  spec$options$method <- "simulation"
  expect_spec_problem(spec, "'simulation' isn't available for this test yet")
  spec <- formula_spec("nonoverlapping_correlations", list(type = "power", n = 150), options = list(seed = 7, allocation_ratio = 2))
  expect_spec_problem(spec, "only applies to two-group designs")
})

test_that("departure: dependent correlations use G*Power's unpooled test, not pwrss's pooled default (Departure 12)", {
  # The examples of G*Power 3.1's manual, sections 28.3.2 (common index)
  # and 28.3.1 (no common index), one-sided, alpha .05, 80% power, as
  # Spower's gpower_examples vignette gives them. Spower's vignette reports
  # G*Power's required N as 144 and 886. With pooled = FALSE pwrss gives
  # the same; with its default, pooled = TRUE, it gives 139 and 875.
  required <- function(pooled, ...) {
    pwrss::power.z.twocors.steiger(
      ..., power = 0.8, alpha = 0.05, alternative = "one.sided", pooled = pooled, verbose = 0
    )$n
  }
  common <- list(rho12 = 0.4, rho13 = 0.2, rho23 = 0.5, common.index = TRUE)
  none <- list(
    rho12 = 0.1, rho34 = 0.2, rho13 = 0.5, rho14 = 0.4, rho23 = -0.4, rho24 = 0.8,
    common.index = FALSE
  )
  expect_equal(do.call(required, c(list(pooled = FALSE), common)), 144)
  expect_equal(do.call(required, c(list(pooled = TRUE), common)), 139)
  expect_equal(do.call(required, c(list(pooled = FALSE), none)), 886)
  expect_equal(do.call(required, c(list(pooled = TRUE), none)), 875)

  # powerkit's result is the unpooled one.
  spec <- formula_spec("overlapping_correlations", list(type = "sample_size", power = 0.8))
  spec$target_test$alternative <- "less"
  expect_equal(run_spec(spec)$n_required$n, 144)
  spec <- formula_spec("nonoverlapping_correlations", list(type = "sample_size", power = 0.8))
  spec$population <- list(
    metric = "correlation", r_X1_Y1 = 0.1, r_X2_Y2 = 0.2, r_X1_X2 = 0.5,
    r_X1_Y2 = 0.4, r_Y1_X2 = -0.4, r_Y1_Y2 = 0.8
  )
  spec$target_test$alternative <- "greater"
  expect_equal(run_spec(spec)$n_required$n, 886)
})
