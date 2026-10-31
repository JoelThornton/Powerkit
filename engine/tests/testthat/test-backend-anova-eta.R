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
  expect_spec_problem(welch, "Welch's F test needs the mean in each group or condition and the SD")
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
  # pwrss's two values are the same study for a large sample; powerkit takes
  # the published kind's noncentrality as f^2 x the error df (88 here), so
  # it is a little lower than pwrss's f^2 x N.
  expect_equal(planned$curve$power, published$curve$power, tolerance = 0.02)
  direct <- pwrss::power.f.mixed.anova(eta.squared = 0.022, factor.levels = c(2, 2), rho.within = 0.5, effect = "within",
    n.total = 90, alpha = 0.05, ceil.n = FALSE, verbose = 0)
  expect_equal(planned$curve$power, direct$power)
  # One within factor: one group, its levels within.
  within <- run_spec(rm_spec("oneway_within", list(metric = "eta_squared", eta_squared = 0.06, eta_source = "published")))
  # The published kind is rescaled so the noncentrality is f^2 x the error
  # df, (90 - 1) x (3 - 1).
  f2 <- 0.06 / 0.94 * (89 * 2) / 90
  expect_equal(within$curve$power, pwrss::power.f.mixed.anova(eta.squared = f2 / (1 + f2), factor.levels = c(1, 3), rho.within = NA,
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

test_that("a published partial eta-squared gives the power of the study it came from, with three or more measurements", {
  # Superpower's exact dataset for a study, and the partial eta-squared its
  # ANOVA reports: entered as published, it gives Superpower's power back.
  # (Before 0.25.1 pwrss's f^2 x N noncentrality gave 60% here, not 89%.)
  within <- Superpower::ANOVA_design("3w", n = 40, mu = c(600, 620, 650), sd = 100, r = 0.6, plot = FALSE)
  exact <- Superpower::ANOVA_exact(within, verbose = FALSE)$main_results
  spec <- example_spec("anova_oneway_within")
  spec$population <- list(metric = "eta_squared", eta_squared = exact$partial_eta_squared[1], eta_source = "published")
  spec$goal <- list(type = "power", n = 40L)
  result <- run_spec(spec)
  expect_equal(result$curve$power, exact$power[1] / 100, tolerance = 1e-6)
  expect_true(all(result$check_run$ok))
  # A 2 x 3 mixed design: every effect.
  mixed <- Superpower::ANOVA_design("2b*3w", n = 30, mu = c(20, 16, 15, 20, 19, 18.5), sd = 6, r = 0.5, plot = FALSE)
  exact <- Superpower::ANOVA_exact(mixed, verbose = FALSE)$main_results
  effects <- c(main_effect_A = "a", main_effect_B = "b", interaction = "a:b")
  for (effect in names(effects)) {
    spec <- example_spec("anova_mixed")
    spec$population <- list(metric = "eta_squared", eta_squared = exact[effects[[effect]], "partial_eta_squared"], eta_source = "published")
    spec$target_test$effect <- effect
    spec$goal <- list(type = "power", n = 60L)
    expect_equal(run_spec(spec)$curve$power, exact[effects[[effect]], "power"] / 100, tolerance = 1e-6, label = effect)
  }
})

test_that("the script reproduces a published partial eta-squared with three measurements", {
  skip_unless_scripts_can_run()
  spec <- example_spec("anova_oneway_within")
  spec$population <- list(metric = "eta_squared", eta_squared = 0.06, eta_source = "published")
  spec$goal <- list(type = "power", n = 60L)
  spec <- validate_spec(spec)
  expect_script_reproduces_power(spec, run_for_export(spec))
})

# The F test from its noncentrality, as G*Power computes it: lambda = f^2 N,
# df2 = N minus the cells minus the covariates.
f_test_power <- function(eta_squared, df1, cells, covariates, n, alpha = 0.05) {
  df2 <- n - cells - covariates
  stats::pf(stats::qf(1 - alpha, df1, df2), df1, df2, ncp = n * eta_squared / (1 - eta_squared), lower.tail = FALSE)
}

test_that("an ANCOVA given by partial eta-squared runs on pwrss's power.f.ancova() with its covariates", {
  spec <- example_spec("anova_oneway_ancova")
  spec$population <- list(metric = "eta_squared", eta_squared = 0.06, covariates = 2L)
  spec$goal <- list(type = "power", n = 150L)
  result <- run_spec(spec)
  expect_identical(result$provenance$backend_function, "pwrss::power.f.ancova")
  expect_true(all(result$check_run$ok))
  expect_equal(result$curve$power, f_test_power(0.06, 2, 3, 2, 150), tolerance = 1e-8)

  two_way <- example_spec("anova_factorial_ancova")
  two_way$population <- list(metric = "eta_squared", eta_squared = 0.04, covariates = 1L)
  two_way$target_test$effect <- "interaction"
  two_way$goal <- list(type = "power", n = 162L)
  levels <- vapply(c("A", "B"), function(v) length(two_way$variables[[v]]$levels), integer(1))
  result <- run_spec(two_way)
  expect_true(all(result$check_run$ok))
  expect_equal(result$curve$power, f_test_power(0.04, prod(levels - 1), prod(levels), 1, 162), tolerance = 1e-8)
})

test_that("a three-factor between-participants ANOVA given by partial eta-squared tests each effect", {
  spec <- example_spec("anova_factorial_three")
  for (v in c("A", "B", "C")) spec$variables[[v]]$type <- "between_factor"
  spec$variables$B$levels <- list("Before", "Middle", "After")
  spec$population <- list(metric = "eta_squared", eta_squared = 0.03)
  spec$goal <- list(type = "power", n = 240L)
  df <- c(main_effect_A = 1, main_effect_B = 2, main_effect_C = 1, interaction_AB = 2, interaction_AC = 1,
          interaction_BC = 2, interaction_ABC = 2)
  for (effect in names(df)) {
    spec$target_test$effect <- effect
    result <- run_spec(spec)
    expect_true(all(result$check_run$ok), label = effect)
    expect_equal(result$curve$power, f_test_power(0.03, df[[effect]], 12, 0, 240), tolerance = 1e-8, label = effect)
  }
})

test_that("partial eta-squared for three factors is refused with a within-participants factor", {
  spec <- example_spec("anova_factorial_three")
  spec$population <- list(metric = "eta_squared", eta_squared = 0.03)
  expect_spec_problem(spec, "every factor is between participants")
})

test_that("an ANCOVA's and a three-factor ANOVA's exported scripts reproduce the result from partial eta-squared", {
  spec <- example_spec("anova_oneway_ancova")
  spec$population <- list(metric = "eta_squared", eta_squared = 0.06, covariates = 2L)
  spec$goal <- list(type = "power", n = 150L)
  result <- run_spec(spec)
  expect_match(export_script(spec, result), "k.covariates = covariates", fixed = TRUE)
  expect_script_reproduces_power(spec, result)

  three <- example_spec("anova_factorial_three")
  for (v in c("A", "B", "C")) three$variables[[v]]$type <- "between_factor"
  three$population <- list(metric = "eta_squared", eta_squared = 0.03)
  three$goal <- list(type = "power", n = 160L)
  expect_script_reproduces_power(three, run_spec(three))
})

test_that("an ANCOVA from its means (Shieh's method) and from the same partial eta-squared (G*Power's) differ a little", {
  # The same population: adjusted means 20, 18, 16, SD 6, the covariate
  # explaining 36%, so f^2 = var(means) / (SD^2 (1 - R^2)). Shieh's method
  # treats the covariate as random, G*Power's as fixed (docs/conventions.md,
  # ANCOVA): 81.3% against 81.8% with 90 people.
  spec <- example_spec("anova_oneway_ancova")
  spec$goal <- list(type = "power", n = 90L)
  shieh <- run_spec(spec)$curve$power
  f2 <- mean((c(20, 18, 16) - 18)^2) / (36 * (1 - 0.36))
  spec$population <- list(metric = "eta_squared", eta_squared = f2 / (1 + f2), covariates = 1L)
  fixed <- run_spec(spec)$curve$power
  expect_equal(fixed, f_test_power(f2 / (1 + f2), 2, 3, 1, 90), tolerance = 1e-8)
  expect_equal(round(c(shieh, fixed), 3), c(0.813, 0.818))
})
