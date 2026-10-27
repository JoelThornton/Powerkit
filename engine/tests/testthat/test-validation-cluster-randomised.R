# Validation: cluster-randomised trial, a score compared between two
# conditions to which whole groups were assigned. Backend: powertools'
# crt.parallel.cont() by formula (the design effect, with degrees of
# freedom from the number of groups). Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-powertools.R)
#      check powerkit against powertools called directly, and against the
#      design-effect calculation done with pwrss's generic t test
#   2. published examples: below, to be transcribed by the maintainer
#   3. direct-call agreement with a simulation: not yet (no simulation
#      option)
#   4. Type I error: d = 0 gives alpha by construction (unit tests)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

cluster_validation_spec <- function(d, icc, cluster_size, alpha, tails, seed,
                                    cluster_size_sd = 0, n = NULL, target_power = NULL) {
  v <- validation_variable
  population <- list(metric = "standardised", d = d, icc = icc, cluster_size = cluster_size)
  if (cluster_size_sd > 0) population$cluster_size_sd <- cluster_size_sd
  validation_spec(
    design = "cluster_trial",
    template = "cluster_randomised",
    variables = list(
      X = v("binary", "Condition", levels = list("Control", "Intervention")),
      Y = v("continuous", "Outcome")
    ),
    population = population,
    target_test = list(
      effect = "mean_difference", method = "cluster_t", alpha = alpha,
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
#   package's DESCRIPTION), so a worked example from its chapter on
#   cluster randomised trials is the natural first check; a worked example
#   from another published text on cluster trials would add an independent
#   one. Record the source, section and page here when transcribing.
# Conventions to check against the source before transcribing:
#   * d is the difference in means divided by the outcome's TOTAL SD
#     (between and within groups together), as powertools' delta / sd;
#     a source that standardises by the within-group SD needs converting.
#   * The test is a t test with (number of groups - 2) degrees of freedom.
#     A source using the normal (z) approximation will give slightly
#     higher power, or slightly fewer groups, than powerkit.
#   * powerkit's n is the total number of participants (groups x group
#     size), with the same number of groups in each condition.

test_that("cluster-randomised trial: power matches a published worked example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: source, section, page).
  d <- TODO_PUBLISHED_VALUE # standardised difference between conditions (total SD)
  icc <- TODO_PUBLISHED_VALUE # intraclass correlation
  cluster_size <- TODO_PUBLISHED_VALUE # participants per group
  groups_per_condition <- TODO_PUBLISHED_VALUE # groups in each condition
  alpha <- TODO_PUBLISHED_VALUE # significance level
  tails <- TODO_PUBLISHED_VALUE # 1 or 2
  published_power <- TODO_PUBLISHED_VALUE # power as printed
  skip_if_todo(d, icc, cluster_size, groups_per_condition, alpha, tails, published_power)

  spec <- cluster_validation_spec(
    d, icc, cluster_size, alpha, tails, seed = 301,
    n = cluster_size * groups_per_condition * 2
  )
  expect_power_exact(engine_power(spec), published_power)
})

test_that("cluster-randomised trial: required groups match a published worked example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: source, section, page).
  d <- TODO_PUBLISHED_VALUE # standardised difference between conditions (total SD)
  icc <- TODO_PUBLISHED_VALUE # intraclass correlation
  cluster_size <- TODO_PUBLISHED_VALUE # participants per group
  alpha <- TODO_PUBLISHED_VALUE # significance level
  tails <- TODO_PUBLISHED_VALUE # 1 or 2
  target_power <- TODO_PUBLISHED_VALUE # target power
  published_groups_per_condition <- TODO_PUBLISHED_VALUE # groups needed in each condition
  skip_if_todo(d, icc, cluster_size, alpha, tails, target_power, published_groups_per_condition)

  spec <- cluster_validation_spec(
    d, icc, cluster_size, alpha, tails, seed = 302, target_power = target_power
  )
  n <- engine_n_required(spec)$n
  expect_equal(n / cluster_size / 2, published_groups_per_condition)
})

test_that("cluster-randomised trial, groups of different sizes: power matches a published worked example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: source, section, page). powertools adjusts
  #   for varying group sizes with a relative efficiency
  #   (re.clustsize.cont()); a source using another adjustment will differ.
  d <- TODO_PUBLISHED_VALUE # standardised difference between conditions (total SD)
  icc <- TODO_PUBLISHED_VALUE # intraclass correlation
  cluster_size <- TODO_PUBLISHED_VALUE # average participants per group
  cluster_size_sd <- TODO_PUBLISHED_VALUE # SD of the group sizes
  groups_per_condition <- TODO_PUBLISHED_VALUE # groups in each condition
  alpha <- TODO_PUBLISHED_VALUE # significance level
  tails <- TODO_PUBLISHED_VALUE # 1 or 2
  published_power <- TODO_PUBLISHED_VALUE # power as printed
  skip_if_todo(d, icc, cluster_size, cluster_size_sd, groups_per_condition, alpha, tails, published_power)

  spec <- cluster_validation_spec(
    d, icc, cluster_size, alpha, tails, seed = 303, cluster_size_sd = cluster_size_sd,
    n = cluster_size * groups_per_condition * 2
  )
  expect_power_exact(engine_power(spec), published_power)
})
