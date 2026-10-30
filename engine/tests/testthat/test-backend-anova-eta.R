eta_spec <- function(template, eta_squared, effect = NULL, goal = list(type = "sample_size", power = 0.8)) {
  spec <- example_spec(paste0("anova_", sub("^2x2_between$", "2x2_between", template)))
  spec$population <- list(metric = "eta_squared", eta_squared = eta_squared)
  spec$target_test$method <- "anova_f"
  if (!is.null(effect)) spec$target_test$effect <- effect
  spec$goal <- goal
  spec$options$cell_ratio <- NULL
  spec
}

f_to_eta <- function(f) f^2 / (1 + f^2)

test_that("an ANOVA given by partial eta-squared runs on pwrss's power.f.ancova(), as a direct call does", {
  for (case in list(list("oneway_between", NULL), list("2x2_between", "interaction"), list("factorial_between", "main_effect_B"))) {
    spec <- eta_spec(case[[1]], f_to_eta(0.25), effect = case[[2]], goal = list(type = "power", n = 120L))
    result <- run_spec(spec)
    expect_identical(result$provenance$backend, "pwrss")
    expect_identical(result$provenance$backend_function, "pwrss::power.f.ancova")
    expect_true(all(result$check_run$ok), label = case[[1]])
    design <- eta_anova_design(validate_spec(spec))
    direct <- do.call(pwrss::power.f.ancova, c(
      list(eta.squared = f_to_eta(0.25), factor.levels = design$levels),
      if (!is.null(design$target)) list(target.effect = design$target),
      list(k.covariates = 0, n.total = 120, alpha = 0.05, ceil.n = FALSE, verbose = 0)
    ))
    expect_equal(result$curve$power, direct$power, label = case[[1]])
  }
})

test_that("the same population effect gives the same power as Superpower's exact calculation from means", {
  # A 2 x 3 interaction from cell means: Superpower's noncentrality at N
  # gives the population f^2 = lambda / N, and the partial eta-squared
  # route reproduces its power.
  means <- list(list(0, 0, 0), list(0, 0.3, 0.6))
  from_means <- example_spec("anova_factorial_between")
  from_means$variables$B$levels <- list("Low", "Medium", "High")
  from_means$population <- list(metric = "standardised", means = means, sd = 1)
  from_means$target_test$effect <- "interaction"
  from_means$goal <- list(type = "power", n = 180L)
  exact <- run_spec(from_means)
  design <- suppressWarnings(Superpower::ANOVA_design("2b*3b", n = 30, mu = c(0, 0, 0, 0, 0.3, 0.6), sd = 1, plot = FALSE))
  lambda <- suppressWarnings(Superpower::ANOVA_exact(design, verbose = FALSE))$main_results["a:b", "non_centrality"]
  f2 <- lambda / 180
  by_eta <- eta_spec("factorial_between", f2 / (1 + f2), effect = "interaction", goal = list(type = "power", n = 180L))
  by_eta$variables$B$levels <- list("Low", "Medium", "High")
  expect_equal(run_spec(by_eta)$curve$power, exact$curve$power, tolerance = 1e-6)
})

test_that("the sample size keeps every group or cell the same size", {
  result <- run_spec(eta_spec("factorial_between", f_to_eta(0.25), effect = "interaction"))
  levels <- eta_anova_design(validate_spec(eta_spec("factorial_between", 0.05)))$levels
  expect_equal(result$n_required$n %% prod(levels), 0)
})

test_that("a published F with both dfs, or Cohen's f, converts into the partial eta-squared", {
  spec <- eta_spec("factorial_between", 0.05, effect = "interaction")
  spec$population$eta_squared <- NULL
  spec$effect_justification <- list(type = "meta_analysis", conversion = list(from = "F", value = 4.2, df = 2L, df_error = 114L))
  v <- validate_spec(spec)
  expect_equal(v$population$eta_squared, effectsize::F_to_eta2(4.2, 2, 114)[[1]])
  spec$effect_justification$conversion <- list(from = "f", value = 0.25)
  expect_equal(validate_spec(spec)$population$eta_squared, effectsize::f_to_eta2(0.25))
  spec$effect_justification$conversion <- list(from = "F", value = 4.2, df_error = 114L)
  expect_spec_problem(spec, "needs its numerator degrees of freedom ('df') as well as 'df_error'")
})

test_that("partial eta-squared is refused where the group means are needed", {
  welch <- eta_spec("oneway_between", 0.05)
  welch$target_test$method <- "welch_f"
  expect_spec_problem(welch, "'welch_f' needs the group means and SDs")
  unequal <- eta_spec("2x2_between", 0.05, effect = "interaction")
  unequal$options$cell_ratio <- list(list(2, 1), list(1, 1))
  expect_spec_problem(unequal, "the groups are equal in size")
  both <- eta_spec("oneway_between", 0.05)
  both$population$means <- list(0, 0.2, 0.4)
  expect_error(validate_spec(both), class = "powerkit_spec_error")
  expect_false(simulated_data_available(eta_spec("oneway_between", 0.05)))
})

test_that("the exported script reproduces the result", {
  skip_unless_scripts_can_run()
  spec <- validate_spec(eta_spec("factorial_between", 0.06, effect = "interaction", goal = list(type = "power", n = 120L)))
  expect_script_reproduces_power(spec, run_for_export(spec))
})

test_that("repeated-measures and mixed ANOVA take either kind of partial eta-squared, on pwrss's power.f.mixed.anova()", {
  rm_spec <- function(template, population, effect = NULL) {
    spec <- example_spec(paste0("anova_", template))
    spec$population <- population
    if (!is.null(effect)) spec$target_test$effect <- effect
    spec$goal <- list(type = "power", n = 90L)
    spec
  }
  # pwrss's own example (its help for power.f.mixed.anova()): a pretest and
  # post-test with d = 0.30 is eta-squared .022 without the correlation and
  # .08255 with it (r = .5); both describe the same study.
  planned <- run_spec(rm_spec("2x2_mixed", list(metric = "eta_squared", eta_squared = 0.022, eta_source = "planned", r = 0.5), "main_effect_B"))
  published <- run_spec(rm_spec("2x2_mixed", list(metric = "eta_squared", eta_squared = 0.08255, eta_source = "published"), "main_effect_B"))
  expect_identical(planned$provenance$backend_function, "pwrss::power.f.mixed.anova")
  expect_true(all(planned$check_run$ok))
  expect_true(all(published$check_run$ok))
  expect_equal(planned$curve$power, published$curve$power, tolerance = 1e-4)
  direct <- pwrss::power.f.mixed.anova(eta.squared = 0.022, factor.levels = c(2, 2), rho.within = 0.5, effect = "within",
    n.total = 90, alpha = 0.05, ceil.n = FALSE, verbose = 0)
  expect_equal(planned$curve$power, direct$power)
  # One within factor: one group, its levels within.
  within <- run_spec(rm_spec("oneway_within", list(metric = "eta_squared", eta_squared = 0.06, eta_source = "published")))
  expect_equal(within$curve$power, pwrss::power.f.mixed.anova(eta.squared = 0.06, factor.levels = c(1, 3), rho.within = NA,
    effect = "within", n.total = 90, alpha = 0.05, ceil.n = FALSE, verbose = 0)$power)
  # The planned kind needs the correlation; the published kind refuses one.
  expect_error(validate_spec(rm_spec("mixed", list(metric = "eta_squared", eta_squared = 0.06, eta_source = "planned"))), class = "powerkit_spec_error")
  expect_error(validate_spec(rm_spec("mixed", list(metric = "eta_squared", eta_squared = 0.06, eta_source = "published", r = 0.5))), class = "powerkit_spec_error")
  # A published F converts only into the published kind.
  conv <- rm_spec("mixed", list(metric = "eta_squared", eta_source = "planned", r = 0.5))
  conv$effect_justification <- list(type = "meta_analysis", conversion = list(from = "F", value = 6, df = 2L, df_error = 88L))
  expect_spec_problem(conv, "set 'population > eta_source' to \"published\"")
  conv$population <- list(metric = "eta_squared", eta_source = "published")
  expect_equal(validate_spec(conv)$population$eta_squared, effectsize::F_to_eta2(6, 2, 88)[[1]])
})
