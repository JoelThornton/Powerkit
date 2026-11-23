# Validation: tests by formula with no simulation of their own: one
# proportion (E25), McNemar's exact test (E26), chi-square goodness of fit
# (E48) and the F tests of linear regression (E24: R-squared against 0, an
# R-squared increase and one coefficient). Backend: pwrss
# (power.exact.oneprop(), power.exact.mcnemar(), power.chisq.gof(),
# power.f.regression()). The unit tests (test-backend-formula-tests.R,
# test-backend-binom-test.R) check powerkit against pwrss called directly;
# these check what the inputs mean, against tests written out here
# (helper-independent-simulation.R) with no call to pwrss:
#   1. the exact tests of counts: stats::binom.test()'s power summed over
#      every outcome the study could see, so the comparison is exact
#   2. goodness of fit: studies drawn as multinomial counts and tested by
#      stats::chisq.test()
#   3. regression: with predictors measured on each person (the default,
#      Departure 39), studies with new normal predictors each time; with
#      predictors set by the design (the fixed model, which G*Power's and
#      pwrss's F tests assume), the same predictor values in every study.
#      Both tested by lm()'s F test
#   4. Type I error: no effect gives at most alpha (exact tests) or alpha
# Values transcribed from a published source or G*Power (tests marked
# "(published)" or "(G*Power value)", or a value whose comment cites its
# source) are owned by the maintainer: do not edit them. Other expected
# values were written with the code (CLAUDE.md, Non-negotiables).
# Skipped unless POWERKIT_FULL_VALIDATION=true.

formula_validation_spec <- function(name, n, seed, population = list(), target_test = list()) {
  # (population and target_test are merged by name; set list-valued
  # fields such as probabilities directly.)
  spec <- example_spec(name)
  spec$population <- utils::modifyList(spec$population, population)
  spec$target_test <- utils::modifyList(spec$target_test, target_test)
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = validation_nrep(), seed = seed)
  spec
}

# 1. Exact tests of counts -----------------------------------------------------

test_that("one proportion: powerkit matches binom.test()'s exact power, both directions (simulation)", {
  skip_unless_full_validation()
  cases <- list(
    list(n = 60, p = 0.65, p0 = 0.5, alternative = "two_sided"),
    list(n = 83, p = 0.3, p0 = 0.2, alternative = "greater"),
    list(n = 50, p = 0.1, p0 = 0.25, alternative = "less")
  )
  for (case in cases) {
    spec <- formula_validation_spec("one_proportion", case$n, 601,
      population = list(p = case$p, p0 = case$p0), target_test = list(alternative = case$alternative))
    reference <- independent_one_proportion_power(case$n, case$p, case$p0, alternative = sub("_", ".", case$alternative))
    expect_power_exact(engine_power(spec), reference)
  }
})

test_that("one proportion: Type I error is at most alpha (simulation)", {
  skip_unless_full_validation()
  spec <- formula_validation_spec("one_proportion", 60, 602, population = list(p = 0.5, p0 = 0.5))
  power <- engine_power(spec)$power
  expect_equal(power, independent_one_proportion_power(60, 0.5, 0.5), tolerance = 1e-6)
  expect_lte(power, 0.05)
})

test_that("McNemar's exact test: powerkit matches binom.test() on the discordant pairs, both directions (simulation)", {
  skip_unless_full_validation()
  cases <- list(
    list(n = 100, first = 0.1, second = 0.25, alternative = "two_sided"),
    list(n = 75, first = 0.08, second = 0.2, alternative = "greater"),
    list(n = 120, first = 0.2, second = 0.1, alternative = "less")
  )
  for (case in cases) {
    spec <- formula_validation_spec("mcnemar", case$n, 611,
      population = list(p_first_only = case$first, p_second_only = case$second),
      target_test = list(alternative = case$alternative))
    reference <- independent_mcnemar_exact_power(case$n, case$first, case$second, alternative = sub("_", ".", case$alternative))
    expect_power_exact(engine_power(spec), reference)
  }
})

test_that("McNemar's exact test: Type I error is at most alpha (simulation)", {
  skip_unless_full_validation()
  spec <- formula_validation_spec("mcnemar", 100, 612, population = list(p_first_only = 0.15, p_second_only = 0.15))
  power <- engine_power(spec)$power
  expect_equal(power, independent_mcnemar_exact_power(100, 0.15, 0.15), tolerance = 1e-6)
  expect_lte(power, 0.05)
})

# 2. Goodness of fit -----------------------------------------------------------

test_that("goodness of fit: powerkit matches chisq.test() on simulated counts (simulation)", {
  skip_unless_full_validation()
  cases <- list(
    list(n = 120, p = c(0.25, 0.3, 0.45), null = rep(1 / 3, 3)),
    list(n = 200, p = c(0.15, 0.25, 0.3, 0.3), null = c(0.2, 0.2, 0.3, 0.3))
  )
  for (case in cases) {
    spec <- formula_validation_spec("chi_square_gof", case$n, 621)
    spec$population$probabilities <- as.list(case$p)
    spec$population$null_probabilities <- as.list(case$null)
    spec$variables$Y$levels <- as.list(paste("Category", seq_along(case$p)))
    reference <- independent_gof_power(case$n, case$p, case$null, nrep = validation_nrep(), seed = 622)
    expect_power_near(engine_power(spec), reference, reference_nrep = validation_nrep())
  }
})

test_that("goodness of fit: Type I error is near alpha (simulation)", {
  skip_unless_full_validation()
  null <- c(0.2, 0.3, 0.5)
  type1 <- independent_gof_power(150, null, null, nrep = validation_nrep(), seed = 623)
  expect_type1_near(list(power = type1), 0.05)
})

# 3. Linear regression ---------------------------------------------------------

test_that("measured predictors: powerkit matches lm()'s F tests on studies with new normal predictors (simulation)", {
  skip_unless_full_validation()
  cases <- list(
    list(name = "regression_r2_zero", n = 40, population = list(r2 = 0.1, predictors = 5), r2_full = 0.1, r2_reduced = 0, controls = 0, tested = 5),
    list(name = "regression_r2_increase", n = 150, population = list(r2_full = 0.15, r2_reduced = 0.1, predictors_total = 5, predictors_tested = 2),
         r2_full = 0.15, r2_reduced = 0.1, controls = 3, tested = 2),
    list(name = "regression_r2_increase", n = 40, population = list(r2_full = 0.3, r2_reduced = 0.2, predictors_total = 8, predictors_tested = 3),
         r2_full = 0.3, r2_reduced = 0.2, controls = 5, tested = 3),
    list(name = "regression_coefficient", n = 60, population = list(partial_r2 = 0.1, predictors_total = 4),
         r2_full = 0.2 + 0.1 * 0.8, r2_reduced = 0.2, controls = 3, tested = 1)
  )
  for (case in cases) {
    spec <- formula_validation_spec(case$name, case$n, 641, population = case$population, target_test = list(method = "f_test"))
    spec$population$variance_ratio <- NULL
    reference <- independent_regression_power(case$n, r2_full = case$r2_full, r2_reduced = case$r2_reduced, controls = case$controls,
                                              tested = case$tested, measured = TRUE, nrep = validation_nrep(), seed = 642)
    expect_power_near(engine_power(spec), reference, reference_nrep = validation_nrep())
  }
})

# Predictors set by the design (target_test > predictor_model "fixed").

test_that("R-squared against 0, set predictors: powerkit matches lm()'s overall F with the same predictor values in every study (simulation)", {
  skip_unless_full_validation()
  spec <- formula_validation_spec("regression_r2_zero", 100, 631, population = list(r2 = 0.1, predictors = 5),
    target_test = list(predictor_model = "fixed"))
  reference <- independent_regression_power(100, r2_full = 0.1, controls = 0, tested = 5, nrep = validation_nrep(), seed = 632)
  expect_power_near(engine_power(spec), reference, reference_nrep = validation_nrep())
})

test_that("R-squared increase, set predictors: powerkit matches lm()'s F for the added predictors (simulation)", {
  skip_unless_full_validation()
  spec <- formula_validation_spec("regression_r2_increase", 150, 633,
    population = list(r2_full = 0.15, r2_reduced = 0.1, predictors_total = 5, predictors_tested = 2),
    target_test = list(predictor_model = "fixed"))
  reference <- independent_regression_power(150, r2_full = 0.15, r2_reduced = 0.1, controls = 3, tested = 2,
                                            nrep = validation_nrep(), seed = 634)
  expect_power_near(engine_power(spec), reference, reference_nrep = validation_nrep())
})

test_that("one coefficient, set predictors: powerkit matches lm()'s t test of the predictor (simulation)", {
  skip_unless_full_validation()
  # A partial R-squared of .04 beyond three controls that explain 20%.
  spec <- formula_validation_spec("regression_coefficient", 150, 635,
    population = list(partial_r2 = 0.04, predictors_total = 4), target_test = list(method = "f_test", predictor_model = "fixed"))
  spec$population$variance_ratio <- NULL
  reference <- independent_regression_power(150, r2_full = 0.2 + 0.04 * 0.8, r2_reduced = 0.2, controls = 3, tested = 1,
                                            nrep = validation_nrep(), seed = 636)
  expect_power_near(engine_power(spec), reference, reference_nrep = validation_nrep())
})

test_that("R-squared increase: Type I error is near alpha (simulation)", {
  skip_unless_full_validation()
  type1 <- independent_regression_power(150, r2_full = 0.1, r2_reduced = 0.1, controls = 3, tested = 2,
                                        nrep = validation_nrep(), seed = 637)
  expect_type1_near(list(power = type1), 0.05)
})
