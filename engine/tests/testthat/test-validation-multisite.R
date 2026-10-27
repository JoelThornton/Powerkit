# Validation: multisite trial, a score compared between two conditions to
# which people were randomised within each group (half to each). Backend:
# powertools' multisite.cont() by formula (degrees of freedom from the
# number of groups). Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-powertools.R)
#      check powerkit against powertools called directly, and against the
#      textbook variance done with pwrss's generic t test
#   2. published examples: below, to be transcribed by the maintainer
#   3. direct-call agreement with a simulation: not yet (no simulation
#      option)
#   4. Type I error: d = 0 gives alpha by construction (unit tests)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

multisite_validation_spec <- function(d, icc, icc_effect, cluster_size, alpha, tails, seed,
                                      n = NULL, target_power = NULL) {
  v <- validation_variable
  validation_spec(
    design = "cluster_trial",
    template = "multisite",
    variables = list(
      X = v("binary", "Condition", levels = list("Control", "Intervention")),
      Y = v("continuous", "Outcome")
    ),
    population = list(
      metric = "standardised", d = d, icc = icc, icc_effect = icc_effect,
      cluster_size = cluster_size
    ),
    target_test = list(
      effect = "mean_difference", method = "multisite_t", alpha = alpha,
      alternative = if (tails == 1) (if (d > 0) "greater" else "less") else "two_sided"
    ),
    seed = seed,
    n = n,
    target_power = target_power
  )
}

# 2. Published examples -------------------------------------------------------
#
# Source: to be chosen by the maintainer. powertools accompanies Crespi,
#   C. M. (2025), Power and Sample Size in R (CRC Press; named in the
#   package's DESCRIPTION), whose chapter on multisite trials is the
#   natural first check. Record the source, section and page here when
#   transcribing.
# Conventions to check against the source before transcribing:
#   * d is the difference in means divided by the outcome's TOTAL SD, as
#     powertools' delta / sd.
#   * icc is the share of the total variance between the groups' means
#     (powertools' icc0); icc_effect is the share from the effect varying
#     between groups (icc1). A source that gives the effect's variation as
#     a variance or an effect-size variability needs converting.
#   * The test is a t test with (number of groups - 1) degrees of freedom,
#     with half of each group in each condition.
#   * powerkit's n is the total number of participants (groups x group size).

test_that("multisite trial: power matches a published worked example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: source, section, page).
  d <- TODO_PUBLISHED_VALUE # standardised difference between conditions (total SD)
  icc <- TODO_PUBLISHED_VALUE # ICC of the group means (icc0)
  icc_effect <- TODO_PUBLISHED_VALUE # ICC of the effect across groups (icc1)
  cluster_size <- TODO_PUBLISHED_VALUE # participants per group, both conditions
  groups <- TODO_PUBLISHED_VALUE # number of groups
  alpha <- TODO_PUBLISHED_VALUE # significance level
  tails <- TODO_PUBLISHED_VALUE # 1 or 2
  published_power <- TODO_PUBLISHED_VALUE # power as printed
  skip_if_todo(d, icc, icc_effect, cluster_size, groups, alpha, tails, published_power)

  spec <- multisite_validation_spec(
    d, icc, icc_effect, cluster_size, alpha, tails, seed = 311, n = cluster_size * groups
  )
  expect_power_exact(engine_power(spec), published_power)
})

test_that("multisite trial: required groups match a published worked example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: source, section, page).
  d <- TODO_PUBLISHED_VALUE # standardised difference between conditions (total SD)
  icc <- TODO_PUBLISHED_VALUE # ICC of the group means (icc0)
  icc_effect <- TODO_PUBLISHED_VALUE # ICC of the effect across groups (icc1)
  cluster_size <- TODO_PUBLISHED_VALUE # participants per group, both conditions
  alpha <- TODO_PUBLISHED_VALUE # significance level
  tails <- TODO_PUBLISHED_VALUE # 1 or 2
  target_power <- TODO_PUBLISHED_VALUE # target power
  published_groups <- TODO_PUBLISHED_VALUE # number of groups needed
  skip_if_todo(d, icc, icc_effect, cluster_size, alpha, tails, target_power, published_groups)

  spec <- multisite_validation_spec(
    d, icc, icc_effect, cluster_size, alpha, tails, seed = 312, target_power = target_power
  )
  expect_equal(engine_n_required(spec)$n / cluster_size, published_groups)
})
