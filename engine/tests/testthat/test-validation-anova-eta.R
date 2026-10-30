# Validation: between-participants ANOVA given by the partial eta-squared
# of the effect tested (as G*Power takes it). Backend: pwrss's
# power.f.ancova() by formula, with no covariates. Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-anova-eta.R) check
#      powerkit against pwrss called directly, and against Superpower's
#      exact calculation from cell means with the same population effect
#   2. published examples: the G*Power 3.1 manual (below)
#   3. direct-call agreement with a simulation: not applicable (formula only)
#   4. Type I error: an effect of 0 is refused by the schema (eta-squared
#      must be above 0)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

eta_validation_spec <- function(levels, effect, eta_squared, alpha, seed, n = NULL, target_power = NULL) {
  v <- validation_variable
  factor_levels <- function(k, name) lapply(seq_len(k), function(i) paste(name, i))
  one_way <- length(levels) == 1
  validation_spec(
    design = "factorial_anova",
    template = if (one_way) "oneway_between" else if (all(levels == 2)) "2x2_between" else "factorial_between",
    variables = c(
      list(A = v("between_factor", "Factor A", levels = factor_levels(levels[1], "A"))),
      if (!one_way) list(B = v("between_factor", "Factor B", levels = factor_levels(levels[2], "B"))),
      list(Y = v("continuous", "Outcome"))
    ),
    population = list(metric = "eta_squared", eta_squared = eta_squared),
    target_test = c(list(method = "anova_f", alpha = alpha), if (!one_way) list(effect = effect) else list(effect = "main_effect_A")),
    seed = seed,
    n = n,
    target_power = target_power
  )
}

# 2. Published examples: G*Power 3.1 -------------------------------------------
#
# Source to transcribe: the G*Power 3.1 manual's chapters on "F test: Fixed
# effects ANOVA - one way" and "F test: Fixed effects ANOVA - special, main
# effects and interactions", each worked example's effect size f, numerator
# df, number of groups, alpha, power and total sample size. powerkit takes
# partial eta-squared: transcribe f as printed and the test converts it with
# eta^2 = f^2 / (1 + f^2), as G*Power does.

test_that("one-way ANOVA from its effect size: matches the G*Power 3.1 manual example (published)", {
  skip_unless_full_validation()
  f <- TODO_PUBLISHED_VALUE # effect size f
  groups <- TODO_PUBLISHED_VALUE # number of groups
  alpha <- TODO_PUBLISHED_VALUE # alpha err prob
  target_power <- TODO_PUBLISHED_VALUE # power (1 - beta err prob)
  published_n <- TODO_PUBLISHED_VALUE # total sample size
  skip_if_todo(f, groups, alpha, target_power, published_n)

  spec <- eta_validation_spec(groups, NULL, f^2 / (1 + f^2), alpha, seed = 301, target_power = target_power)
  expect_equal(engine_n_required(spec)$n, published_n)
})

test_that("factorial ANOVA interaction from its effect size: matches the G*Power 3.1 manual example (published)", {
  skip_unless_full_validation()
  f <- TODO_PUBLISHED_VALUE # effect size f
  levels <- TODO_PUBLISHED_VALUE # the two factors' numbers of levels, c(k, m)
  alpha <- TODO_PUBLISHED_VALUE # alpha err prob
  target_power <- TODO_PUBLISHED_VALUE # power (1 - beta err prob)
  published_n <- TODO_PUBLISHED_VALUE # total sample size
  skip_if_todo(f, levels, alpha, target_power, published_n)

  spec <- eta_validation_spec(levels, "interaction", f^2 / (1 + f^2), alpha, seed = 302, target_power = target_power)
  # powerkit keeps every cell the same size, so its N is G*Power's rounded
  # up to a multiple of the number of cells.
  expect_equal(engine_n_required(spec)$n, prod(levels) * ceiling(published_n / prod(levels)))
})

test_that("repeated-measures ANOVA from its effect size: matches the G*Power 3.1 manual example (published)", {
  skip_unless_full_validation()
  # Source to transcribe: the G*Power 3.1 manual's "F test: Repeated measures,
  # within factors" example (its effect size f, number of groups, number of
  # measurements, correlation among repeated measures, nonsphericity
  # correction 1, alpha, power and total sample size). G*Power's f there
  # leaves out the correlation, so the spec uses eta_source "planned" with r.
  f <- TODO_PUBLISHED_VALUE # effect size f
  measurements <- TODO_PUBLISHED_VALUE # number of measurements
  r <- TODO_PUBLISHED_VALUE # corr among rep measures
  alpha <- TODO_PUBLISHED_VALUE # alpha err prob
  target_power <- TODO_PUBLISHED_VALUE # power (1 - beta err prob)
  published_n <- TODO_PUBLISHED_VALUE # total sample size
  skip_if_todo(f, measurements, r, alpha, target_power, published_n)

  v <- validation_variable
  spec <- validation_spec(
    design = "factorial_anova", template = "oneway_within",
    variables = list(A = v("within_factor", "Condition", levels = lapply(seq_len(measurements), function(i) paste("Time", i))),
                     Y = v("continuous", "Outcome")),
    population = list(metric = "eta_squared", eta_squared = f^2 / (1 + f^2), eta_source = "planned", r = r),
    target_test = list(effect = "main_effect_A", method = "anova_f", alpha = alpha),
    seed = 303, target_power = target_power
  )
  expect_equal(engine_n_required(spec)$n, published_n)
})
