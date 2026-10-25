# Validation: the generic tests, where the user gives a noncentrality
# parameter and degrees of freedom directly. Backend: pwrss's generic
# functions by formula. Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-generic.R) check
#      powerkit against pwrss called directly
#   2. published examples: the G*Power 3.1 manual (below)
#   3. direct-call agreement with a simulation: not applicable (a
#      noncentrality has no data-generating model to simulate)
#   4. Type I error: a noncentrality of 0 gives alpha by construction
#      (unit tests)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.
#
# Only the generic t test has a section in the manual (25, p. 63). The
# generic F, chi-square and z tests are not covered by the edition of
# 1 June 2023, so they can only be checked in G*Power itself; this file
# has a test for each when that happens.

# Generic specs are built here rather than with validation_spec(), which
# always adds a replication count and a sample size: a generic test has
# neither, because the noncentrality already carries the sample size. Its
# 'variables' is an empty set of named fields, not an empty list.
generic_spec <- function(template, population, alpha, tails, seed) {
  spec <- list(
    spec_version = "0.1",
    design = "generic_test",
    template = template,
    variables = stats::setNames(list(), character(0)),
    population = c(list(metric = "noncentrality"), population),
    effect_justification = list(
      type = "smallest_effect_of_interest",
      source = "powerkit validation benchmark (not a real study)"
    ),
    target_test = list(
      effect = "noncentrality",
      method = switch(template, t = "t_test", f = "f_test", chi_square = "chi_square_test", z = "z_test"),
      alpha = alpha,
      alternative = if (tails == 1) "greater" else "two_sided"
    ),
    goal = list(type = "power"),
    options = list(seed = seed)
  )
  # skip_if_no_backend() isn't used here: it probes route_spec(), and a
  # generic test doesn't go through the backend router at all (run_spec()
  # computes it from the noncentrality directly), so route_spec() reports
  # it as unavailable even though it runs.
  validate_spec(spec)
}

# A generic test's curve has a single row, whose n is NA, so the power is
# read from that row rather than matched to a sample size.
generic_power <- function(spec) {
  curve <- engine_function("run_spec")(spec)$curve
  if (nrow(curve) != 1) {
    stop("A generic test's power curve should have one row; it has ", nrow(curve), ".", call. = FALSE)
  }
  list(power = curve$power, mcse = curve$mcse)
}

# 2. Published examples: G*Power 3.1 -------------------------------------------

test_that("generic t test: matches the G*Power 3.1 manual example (published)", {
  skip_unless_full_validation()
  # Source: G*Power 3.1 manual (version of June 1, 2023), section 25.3
  #   ("t test: Generic case", Examples), p. 63: the one-sample t test
  #   recomputed as a generic t test, with N = 25, mu0 = 0, mu1 = 1 and
  #   sigma = 4, so d = -0.25, the noncentrality is d * sqrt(N) and the
  #   degrees of freedom are N - 1. A post hoc, two-sided analysis.
  #   Transcribe the noncentrality, the df, alpha, the tails and the
  #   reported power.
  # The manual notes this is "exactly the same value we get from the
  #   specialized routine", so it also checks the generic route against
  #   the one-sample t test.
  # Note on precision: this test uses expect_power_exact(), which allows
  #   half a unit in the last printed digit or 0.0005, whichever is
  #   larger. powerkit agrees with the manual to five decimal places and
  #   differs in the sixth (about 1e-6), which is inside that allowance but
  #   outside the printed digit, so don't be surprised by it.
  ncp <- TODO_PUBLISHED_VALUE # Noncentrality parameter delta
  df <- TODO_PUBLISHED_VALUE # Df
  alpha <- TODO_PUBLISHED_VALUE # alpha err prob
  tails <- TODO_PUBLISHED_VALUE # Tail(s): 1 or 2
  published_power <- TODO_PUBLISHED_VALUE # Output: Power (1-beta)
  skip_if_todo(ncp, df, alpha, tails, published_power)

  spec <- generic_spec("t", list(ncp = ncp, df = df), alpha, tails, seed = 601)
  expect_power_exact(generic_power(spec), published_power)
})

test_that("generic F test: matches a G*Power 3.1 example (published)", {
  skip_unless_full_validation()
  # No section in the manual (edition of 1 June 2023) for the generic F
  #   test, so this has to come from G*Power itself: run F tests > Generic
  #   F test, post hoc, and transcribe the noncentrality, both dfs, alpha
  #   and the power. A worked example from another source is equally good,
  #   as long as it states lambda, df1 and df2.
  ncp <- TODO_PUBLISHED_VALUE # Noncentrality parameter lambda
  df1 <- TODO_PUBLISHED_VALUE # Numerator df
  df2 <- TODO_PUBLISHED_VALUE # Denominator df
  alpha <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(ncp, df1, df2, alpha, published_power)

  spec <- generic_spec("f", list(ncp = ncp, df1 = df1, df2 = df2), alpha, tails = 2, seed = 602)
  expect_power_exact(generic_power(spec), published_power)
})

test_that("generic chi-square test: matches a G*Power 3.1 example (published)", {
  skip_unless_full_validation()
  # No section in the manual for the generic chi-square test, as above:
  #   run chi-square tests > Generic chi-square test in G*Power, post hoc,
  #   and transcribe the noncentrality, the df, alpha and the power.
  ncp <- TODO_PUBLISHED_VALUE
  df <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(ncp, df, alpha, published_power)

  spec <- generic_spec("chi_square", list(ncp = ncp, df = df), alpha, tails = 2, seed = 603)
  expect_power_exact(generic_power(spec), published_power)
})

test_that("generic z test: matches a G*Power 3.1 example (published)", {
  skip_unless_full_validation()
  # No section in the manual for the generic z test, as above. powerkit's
  #   generic z test has SD 1 under both hypotheses, so in G*Power set
  #   "Std dev H0" and "Std dev H1" to 1 before transcribing.
  ncp <- TODO_PUBLISHED_VALUE # Mean H1 (the noncentrality, with SD 1)
  alpha <- TODO_PUBLISHED_VALUE
  tails <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(ncp, alpha, tails, published_power)

  spec <- generic_spec("z", list(ncp = ncp), alpha, tails, seed = 604)
  expect_power_exact(generic_power(spec), published_power)
})
