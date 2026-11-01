# Validation: a moderator that is a score (E61, meta_regression) and the
# test of heterogeneity (E61, heterogeneity). Backend: Spower with
# metafor's rma().
#   1. analytic agreement: an independent simulation written without
#      Spower: the same studies drawn directly and fitted with metafor
#   2. published examples: placeholders, for the maintainer
#   3. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

meta_more_reps <- 2000L

meta_more_spec_for <- function(template, population, test, seed, n) {
  validation_spec(
    design = "meta_analysis",
    template = template,
    variables = list(Y = validation_variable("continuous", "Outcome")),
    population = c(list(metric = "d"), population),
    target_test = c(if (template == "meta_regression") list(effect = "moderator_slope", method = "z_test", test = test) else
      list(effect = "heterogeneity", method = "q_test"), list(alpha = 0.05)),
    seed = seed,
    n = n,
    options = list(nrep = meta_more_reps)
  )
}

meta_more_by_hand <- function(template, p, test, k, nrep, seed) {
  v <- 4 / p$study_size + p$effect^2 / (2 * p$study_size)
  tau2 <- p$i2 * v / (1 - p$i2)
  x <- stats::qnorm((seq_len(k) - 0.5) / k)
  x <- (x - mean(x)) / sqrt(mean((x - mean(x))^2))
  with_seed(seed, mean(vapply(seq_len(nrep), function(i) {
    if (template == "meta_regression") {
      yi <- p$effect + p$slope * x + stats::rnorm(k, 0, sqrt(tau2)) + stats::rnorm(k, 0, sqrt(v))
      fit <- metafor::rma(yi = yi, vi = rep(v, k), mods = ~ x, method = "DL", test = test)
      fit$pval[2] < 0.05
    } else {
      yi <- p$effect + stats::rnorm(k, 0, sqrt(tau2)) + stats::rnorm(k, 0, sqrt(v))
      metafor::rma(yi = yi, vi = rep(v, k), method = "FE")$QEp < 0.05
    }
  }, logical(1))))
}

regression_population <- list(effect = 0.3, slope = 0.15, study_size = 40, i2 = 0.3)
heterogeneity_population <- list(effect = 0.3, study_size = 40, i2 = 0.5)

for (test in c("knha", "z")) {
  test_that(sprintf("a score moderator, %s test: agrees with an independent simulation (analytic)", test), {
    skip_unless_full_validation()
    skip_if_not_installed("metafor")
    reference <- meta_more_by_hand("meta_regression", regression_population, test, 30, meta_more_reps, seed = 6901)
    spec <- meta_more_spec_for("meta_regression", regression_population, if (test == "z") "z" else "hartung_knapp", seed = 6902, n = 30)
    expect_power_near(engine_power(spec), reference, reference_nrep = meta_more_reps)
  })
}

test_that("the test of heterogeneity: agrees with an independent simulation (analytic)", {
  skip_unless_full_validation()
  skip_if_not_installed("metafor")
  reference <- meta_more_by_hand("heterogeneity", heterogeneity_population, NULL, 20, meta_more_reps, seed = 6903)
  spec <- meta_more_spec_for("heterogeneity", heterogeneity_population, NULL, seed = 6904, n = 20)
  expect_power_near(engine_power(spec), reference, reference_nrep = meta_more_reps)
})

test_that("both tests: Type I error near alpha with no effect", {
  skip_unless_full_validation()
  null_reg <- modifyList(regression_population, list(slope = 0))
  expect_type1_near(engine_power(meta_more_spec_for("meta_regression", null_reg, "hartung_knapp", seed = 6905, n = 30)), alpha = 0.05)
  null_q <- modifyList(heterogeneity_population, list(i2 = 0))
  expect_type1_near(engine_power(meta_more_spec_for("heterogeneity", null_q, NULL, seed = 6906, n = 20)), alpha = 0.05)
})

test_that("a score moderator and heterogeneity: match a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (for example Hedges and Pigott's
  # worked examples of power for meta-regression and for the Q test).
  population <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(population, n, published_power, reference_nrep)
  expect_power_near(engine_power(meta_more_spec_for("meta_regression", population, "hartung_knapp", seed = 6907, n = n)),
    published_power, reference_nrep = reference_nrep)
})
