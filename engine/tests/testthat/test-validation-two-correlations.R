# Validation: two independent Pearson correlations (Fisher's z test).
# Backend: pwrss's power.z.twocors() by formula. Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-formula-tests.R)
#      check powerkit against pwrss called directly
#   2. published examples: the G*Power 3.1 manual (below)
#   3. direct-call agreement with a simulation: not yet (no simulation
#      option)
#   4. Type I error: equal correlations give alpha by construction (unit
#      tests)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

two_correlations_spec <- function(r1, r2, alpha, tails, seed, n = NULL,
                                  target_power = NULL, allocation_ratio = 1) {
  v <- validation_variable
  validation_spec(
    design = "basic_test",
    template = "two_correlations",
    variables = list(
      X = v("continuous", "Predictor"),
      Y = v("continuous", "Outcome"),
      G = v("binary", "Group", levels = list("First", "Second"))
    ),
    population = list(metric = "correlation", r1 = r1, r2 = r2),
    target_test = list(
      effect = "correlation_difference", method = "fisher_z", alpha = alpha,
      alternative = if (tails == 1) (if (r2 > r1) "greater" else "less") else "two_sided"
    ),
    seed = seed,
    n = n,
    target_power = target_power,
    options = list(allocation_ratio = allocation_ratio)
  )
}

# 2. Published examples: G*Power 3.1 -------------------------------------------
#
# G*Power's inputs, confirmed against the manual (section 27, pp. 65-66):
#   * The effect size is q = z1 - z2, the difference between the two
#     Fisher-transformed correlations (27.1). powerkit takes the two
#     correlations themselves, as pwrss does, and the effect-size drawer in
#     G*Power converts between them, so transcribe r1 and r2 and let the
#     engine derive q. The drawer's own value for q is worth noting while
#     transcribing, as a check that the right pair was entered.
#   * The two sample sizes are entered separately. powerkit takes the total
#     and an allocation ratio n2/n1, so give the total and the ratio.
#   * "This test has no options" (27.2), so nothing else has to be set.
#   * Its H1 distribution is N(q/s, 1) with
#     s = sqrt(1/(N1 - 3) + 1/(N2 - 3)) (27.5), which is the test pwrss
#     computes.
# Caution when reading the printed Output block of 27.3 (p. 65): the
#   manual's two-column layout interleaves this section with section 26, so
#   that block's printed lines are mixed up with the chi-square test's
#   ("Critical z: 60.391478" is section 26's critical chi-square, and the
#   line labelled "Upper critical chi-square" holds this test's critical z,
#   -1.959964). The power value on the last line is this test's.

test_that("two independent correlations: matches the G*Power 3.1 manual example (published)", {
  skip_unless_full_validation()
  # Source: G*Power 3.1 manual (version of June 1, 2023), section 27.3
  #   ("z test: Correlation - inequality of two independent Pearson r's",
  #   Examples), p. 65: test A correlating with a criterion against test B,
  #   post hoc analysis with unequal groups. The manual notes this is
  #   Example 4.3 in Cohen (1988, p. 131), which gives 0.72 with rounding.
  #   Transcribe the two correlations, both sample sizes, alpha and the
  #   reported power (see the caution above about the printed block).
  r1 <- TODO_PUBLISHED_VALUE # correlation coefficient r1
  r2 <- TODO_PUBLISHED_VALUE # correlation coefficient r2
  n1 <- TODO_PUBLISHED_VALUE # the smaller "Sample size" in the Input block
  n2 <- TODO_PUBLISHED_VALUE # the larger "Sample size" in the Input block
  alpha <- TODO_PUBLISHED_VALUE # alpha err prob
  tails <- TODO_PUBLISHED_VALUE # Tail(s): 1 or 2
  published_power <- TODO_PUBLISHED_VALUE # Output: Power (1-beta err prob)
  skip_if_todo(r1, r2, n1, n2, alpha, tails, published_power)

  spec <- two_correlations_spec(
    r1, r2, alpha, tails, seed = 501, n = n1 + n2, allocation_ratio = n2 / n1
  )
  expect_power_exact(engine_power(spec), published_power)
})

test_that("two independent correlations: required N matches the G*Power 3.1 manual (published)", {
  skip_unless_full_validation()
  # Source: as above, the second part of 27.3 (p. 65): the same
  #   correlations and alpha, with the power found above as the target and
  #   an allocation ratio of 1, so the groups are equal. The manual reports
  #   the size of each group; powerkit's required N is the total, so
  #   transcribe the per-group size and double it here.
  r1 <- TODO_PUBLISHED_VALUE
  r2 <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  tails <- TODO_PUBLISHED_VALUE
  target_power <- TODO_PUBLISHED_VALUE # the power carried over from the post hoc analysis
  n_per_group <- TODO_PUBLISHED_VALUE # the cases needed in each group
  skip_if_todo(r1, r2, alpha, tails, target_power, n_per_group)

  spec <- two_correlations_spec(
    r1, r2, alpha, tails, seed = 502, target_power = target_power, allocation_ratio = 1
  )
  expect_n_near(engine_n_required(spec), 2 * n_per_group)
})
