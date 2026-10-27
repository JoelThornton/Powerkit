# Validation: equivalence tests (two one-sided tests, TOST) for two
# independent groups, paired data and one sample. Backend: TOSTER's
# power_t_TOST(), by formula. Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-toster.R) check
#      powerkit against TOSTER called directly and against a large-sample
#      approximation in base R
#   2. published examples: below, for the maintainer to choose and
#      transcribe
#   3. direct-call agreement: below, with the arguments written out by hand
#   4. Type I error: below; with the true difference at the bound, the
#      rejection rate of TOST is at most alpha and close to it with many
#      people
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

# Equivalence specs are built here rather than with validation_spec(),
# which adds a replication count: these are computed by formula, so they
# have none.
equivalence_spec <- function(template, population, alpha, seed, n = NULL, target_power = NULL, options = list()) {
  variables <- switch(
    template,
    tost_independent = list(
      X = validation_variable("binary", "group", levels = c("A", "B")),
      Y = validation_variable("continuous", "outcome")
    ),
    tost_paired = list(
      X = validation_variable("within_factor", "condition", levels = c("first", "second")),
      Y = validation_variable("continuous", "outcome")
    ),
    tost_one_sample = list(Y = validation_variable("continuous", "outcome"))
  )
  spec <- list(
    spec_version = "0.1",
    design = "equivalence_test",
    template = template,
    variables = variables,
    population = c(list(metric = "standardised"), population),
    effect_justification = list(
      type = "smallest_effect_of_interest",
      source = "powerkit validation benchmark (not a real study)"
    ),
    target_test = list(
      effect = if (template == "tost_one_sample") "mean" else "mean_difference",
      method = "tost",
      alpha = alpha
    ),
    goal = if (is.null(target_power)) list(type = "power", n = n) else list(type = "sample_size", power = target_power),
    options = c(list(seed = seed), options)
  )
  validate_spec(spec)
}

# 2. Published examples ------------------------------------------------------------

test_that("equivalence, two independent groups: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE. A published power or sample-size
  # calculation for TOST with two independent groups, for the maintainer
  # to choose (candidate: Lakens, 2017, the equivalence-testing primer
  # cited by citation("TOSTER")). Note the section and page here, and
  # whether alpha is per one-sided test (as in TOST) or for a 1 - 2 alpha
  # confidence interval (the same thing).
  d <- TODO_PUBLISHED_VALUE # expected true difference, as Cohen's d
  bound <- TODO_PUBLISHED_VALUE # equivalence bound, as Cohen's d (symmetric: -bound to +bound)
  alpha <- TODO_PUBLISHED_VALUE # alpha for each one-sided test
  target_power <- TODO_PUBLISHED_VALUE # the power the example plans for
  n_per_group <- TODO_PUBLISHED_VALUE # Output: sample size per group
  skip_if_todo(d, bound, alpha, target_power, n_per_group)

  spec <- equivalence_spec("tost_independent", list(d = d, bound = bound), alpha, seed = 301, target_power = target_power)
  expect_n_near(engine_n_required(spec), 2 * n_per_group)
})

test_that("equivalence, paired data: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE. A published power or sample-size
  # calculation for TOST with paired data, for the maintainer to choose.
  dz <- TODO_PUBLISHED_VALUE # expected true mean difference, as d_z
  bound <- TODO_PUBLISHED_VALUE # equivalence bound, as d_z
  alpha <- TODO_PUBLISHED_VALUE # alpha for each one-sided test
  target_power <- TODO_PUBLISHED_VALUE # the power the example plans for
  n <- TODO_PUBLISHED_VALUE # Output: number of pairs
  skip_if_todo(dz, bound, alpha, target_power, n)

  spec <- equivalence_spec("tost_paired", list(dz = dz, bound = bound), alpha, seed = 302, target_power = target_power)
  expect_n_near(engine_n_required(spec), n)
})

# 3. Direct-call agreement --------------------------------------------------------

test_that("equivalence: powerkit matches TOSTER called directly", {
  skip_unless_full_validation()
  spec <- equivalence_spec("tost_independent", list(d = 0.1, bound = 0.4), alpha = 0.05, seed = 303, n = 260)
  direct <- TOSTER::power_t_TOST(n = 130, delta = 0.1, sd = 1, eqb = c(-0.4, 0.4), alpha = 0.05, type = "two.sample")$power
  expect_power_exact(engine_power(spec), direct)

  spec <- equivalence_spec("tost_paired", list(dz = -0.05, bound = 0.3), alpha = 0.05, seed = 304, n = 150)
  direct <- TOSTER::power_t_TOST(n = 150, delta = -0.05, sd = 1, eqb = c(-0.3, 0.3), alpha = 0.05, type = "paired")$power
  expect_power_exact(engine_power(spec), direct)

  spec <- equivalence_spec("tost_one_sample", list(d = 0, bound = 0.25), alpha = 0.025, seed = 305, n = 300)
  direct <- TOSTER::power_t_TOST(n = 300, delta = 0, sd = 1, eqb = c(-0.25, 0.25), alpha = 0.025, type = "one.sample")$power
  expect_power_exact(engine_power(spec), direct)
})

# 4. Type I error ------------------------------------------------------------------

test_that("equivalence: Type I error is at most alpha, and near it with many people", {
  skip_unless_full_validation()
  # With the true difference at the bound, the null hypothesis of TOST is
  # true, so equivalence should be declared at most alpha of the time.
  for (template in c("tost_independent", "tost_paired", "tost_one_sample")) {
    population <- if (template == "tost_paired") list(dz = 0.3, bound = 0.3) else list(d = 0.3, bound = 0.3)
    spec <- equivalence_spec(template, population, alpha = 0.05, seed = 306, n = 2000)
    power <- engine_power(spec)$power
    expect_lte(power, 0.05 + 1e-8, label = template)
    expect_gte(power, 0.04, label = template)
  }
})
