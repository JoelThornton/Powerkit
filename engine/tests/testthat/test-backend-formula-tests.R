# More tests by formula (the maintainer's direction, 18 October 2026):
# Fisher's exact test, chi-square goodness of fit, two independent
# correlations, one-way ANCOVA and planned comparisons, each one pwrss call. Each is checked
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
    anova_oneway_contrast = "pwrss::power.t.contrasts",
    two_correlations = "pwrss::power.z.twocors",
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
    formula_spec("anova_oneway_ancova", list(type = "sample_size", power = 0.8)),
    formula_spec("anova_oneway_contrast", list(type = "sample_size", power = 0.8)),
    formula_spec("anova_oneway_contrast", list(type = "power", n = 40), options = list(seed = 7, attrition = 0.1))
  )
  for (spec in specs) {
    result <- run_spec(spec)
    out <- run_exported_script(spec, result)
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10, info = spec$template)
  }
})

# Planned comparisons (contrasts) ------------------------------------------------

test_that("a contrast equals pwrss::power.t.contrasts(), and Superpower's emmeans contrast", {
  # Example: means 1.5, 2, 3, 4 in four groups of 5, SD 2, linear trend.
  spec <- formula_spec("anova_oneway_contrast", list(type = "power", n = 20))
  power <- run_spec(spec)$curve$power
  direct <- pwrss::power.t.contrasts(
    mu.vector = c(1.5, 2, 3, 4), sd.vector = rep(2, 4), n.vector = rep(5, 4),
    contrast.matrix = matrix(c(-3, -1, 1, 3), nrow = 1),
    r.squared = 0, k.covariates = 0, alpha = 0.05, adjust.alpha = "none",
    ceil.n = FALSE, verbose = 0
  )
  expect_equal(power, as.numeric(direct$power))

  # Superpower computes the same contrast through emmeans, from one exact
  # data set rather than a formula: a check that powerkit's weights mean
  # what the ANOVA backend would take them to mean.
  skip_if_not_installed("Superpower")
  skip_if_not_installed("emmeans")
  design <- Superpower::ANOVA_design(design = "4b", n = 5, mu = c(1.5, 2, 3, 4), sd = 2, plot = FALSE)
  other <- Superpower::ANOVA_exact(
    design, alpha_level = 0.05, verbose = FALSE, emm = TRUE, contrast_type = "poly"
  )$emm_results
  linear <- other$power[other$contrast == "linear"]
  expect_equal(power, linear / 100, tolerance = 1e-6)
})

test_that("a contrast's weights can be on any scale", {
  at <- function(weights) {
    spec <- formula_spec("anova_oneway_contrast", list(type = "power", n = 20))
    spec$target_test$weights <- as.list(weights)
    run_spec(spec)$curve$power
  }
  # The same comparison, scaled up and down, and reversed.
  expect_equal(at(c(-3, -1, 1, 3)), at(c(-1.5, -0.5, 0.5, 1.5)))
  expect_equal(at(c(-3, -1, 1, 3)), at(c(-30, -10, 10, 30)))
  expect_equal(at(c(-3, -1, 1, 3)), at(c(3, 1, -1, -3)))
})

test_that("a contrast: the required n is the smallest that reaches the target", {
  spec <- validate_spec(formula_spec("anova_oneway_contrast", list(type = "sample_size", power = 0.8)))
  n <- run_spec(spec)$n_required$n
  backend <- route_spec(spec)
  # Four equal groups, so the valid sizes are multiples of 4.
  expect_gte(backend$exact_power(n), 0.8)
  expect_lt(backend$exact_power(n - 4), 0.8)
})

test_that("a contrast of zero gives power alpha at a fixed n", {
  spec <- formula_spec("anova_oneway_contrast", list(type = "power", n = 20))
  # Weights that cancel out on these means: 1.5 + 4 against 2 + 3 is not
  # zero, so use means that are all equal instead.
  spec$population$means <- list(2, 2, 2, 2)
  expect_equal(run_spec(spec)$curve$power, 0.05, tolerance = 1e-6)
})

test_that("contrast specs that can't be right are refused", {
  base <- function() formula_spec("anova_oneway_contrast", list(type = "power", n = 20))
  spec <- base()
  spec$target_test$weights <- list(-1, 0, 1)
  expect_spec_problem(spec, "'target_test > weights' has 3 values")
  spec <- base()
  spec$target_test$weights <- list(1, 0, 0, 1)
  expect_spec_problem(spec, "must add up to 0")
  spec <- base()
  spec$target_test$weights <- list(0, 0, 0, 0)
  expect_spec_problem(spec, "don't compare anything")
  spec <- base()
  spec$goal$n <- 21
  expect_spec_problem(spec, "split into 4 equal groups")
  spec <- base()
  spec$options$method <- "simulation"
  expect_spec_problem(spec, "'simulation' isn't available for this test yet")
  # Two-sided only: pwrss's contrast function has no one-sided option.
  spec <- base()
  spec$target_test$alternative <- "greater"
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  # The weights belong to a contrast, not to the omnibus test.
  spec <- formula_spec("anova_oneway_between", list(type = "power", n = 30))
  spec$target_test$weights <- list(-1, 0, 1)
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})
