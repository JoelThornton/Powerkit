# Validation: cluster-randomised trial, a score compared between two
# conditions to which whole groups were assigned. Backend: powertools'
# crt.parallel.cont() by formula (the design effect, with degrees of
# freedom from the number of groups). Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-powertools.R)
#      check powerkit against powertools called directly, and against the
#      design-effect calculation done with pwrss's generic t test
#   2. published examples: below, to be transcribed by the maintainer
#   3. agreement with trials simulated separately: below, by the group
#      means' t test (groups of one size) and a mixed model (groups of
#      different sizes), and for a group treatment trial by Welch's test
#      of the individuals against the groups' means
#   4. Type I error: d = 0 gives alpha by construction (unit tests)
# Values transcribed from a published source or G*Power (tests marked
# "(published)" or "(G*Power value)", or a value whose comment cites its
# source) are owned by the maintainer: do not edit them. Other expected
# values were written with the code (CLAUDE.md, Non-negotiables).
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

# Independent simulation ------------------------------------------------------
# The unit tests compare powerkit with powertools called directly. These
# draw trials in base R as the input screen describes them (d over the
# total SD, the ICC as the share of variance between groups) and analyse
# them the usual way: the t test of the group means for groups of one
# size, a mixed model with a random intercept (Satterthwaite's df) for
# groups of different sizes.

test_that("cluster-randomised trial: agrees with trials simulated separately and analysed by group means (simulation)", {
  skip_unless_full_validation()
  spec <- cluster_validation_spec(0.4, 0.05, 20, 0.05, 2, seed = 304, n = 400)
  reference <- independent_cluster_trial_power(0.4, 0.05, 20, groups_per_condition = 10,
    nrep = validation_nrep(), seed = 1304)
  expect_power_near(engine_power(spec), reference, reference_nrep = validation_nrep())
})

test_that("cluster-randomised trial, groups of different sizes: agrees with a mixed model on simulated trials (simulation)", {
  skip_unless_full_validation()
  skip_if_not_installed("lmerTest")
  # powertools adjusts for the sizes' spread by a relative efficiency (an
  # approximation), so a small allowance is given beyond simulation error.
  spec <- cluster_validation_spec(0.4, 0.05, 20, 0.05, 2, seed = 305, cluster_size_sd = 8, n = 400)
  reference <- independent_cluster_trial_power(0.4, 0.05, 20, groups_per_condition = 10, m_sd = 8,
    nrep = 4000, seed = 1305)
  expect_power_within_approximation(engine_power(spec), reference, reference_nrep = 4000, allowance = 0.02)
})

group_treatment_validation_spec <- function(d, icc, cluster_size, seed, n) {
  v <- validation_variable
  validation_spec(
    design = "cluster_trial",
    template = "group_treatment",
    variables = list(
      X = v("binary", "Condition", levels = list("Individual", "Group")),
      Y = v("continuous", "Outcome")
    ),
    population = list(metric = "standardised", d = d, icc = icc, cluster_size = cluster_size),
    target_test = list(effect = "mean_difference", method = "cluster_t", alpha = 0.05, alternative = "two_sided"),
    seed = seed,
    n = n
  )
}

test_that("group treatment trial: agrees with trials simulated separately and analysed by Welch's test (simulation)", {
  skip_unless_full_validation()
  # 10 groups of 8 and 80 people taking part individually, where
  # irgtt.cont()'s own df (11.2) would give .512 (Departure 38).
  spec <- group_treatment_validation_spec(0.4, 0.1, 8, seed = 306, n = 160)
  reference <- independent_group_treatment_power(0.4, 0.1, m = 8, groups = 10, individuals = 80,
    nrep = validation_nrep(), seed = 1306)
  expect_power_near(engine_power(spec), reference, reference_nrep = validation_nrep())
  # Few groups, where the two df differ most: 4 groups of 5.
  few <- group_treatment_validation_spec(0.8, 0.1, 5, seed = 307, n = 40)
  reference_few <- independent_group_treatment_power(0.8, 0.1, m = 5, groups = 4, individuals = 20,
    nrep = validation_nrep(), seed = 1307)
  expect_power_near(engine_power(few), reference_few, reference_nrep = validation_nrep())
})

test_that("group treatment trial, yes/no outcome: agrees with trials simulated separately (simulation)", {
  skip_unless_full_validation()
  v <- validation_variable
  spec <- validation_spec(
    design = "cluster_trial",
    template = "group_treatment",
    variables = list(
      X = v("binary", "Condition", levels = list("Individual", "Group")),
      Y = v("binary", "Outcome")
    ),
    population = list(metric = "proportion", p1 = 0.3, p2 = 0.45, icc = 0.05, cluster_size = 10),
    target_test = list(effect = "proportion_difference", method = "z_test", alpha = 0.05, alternative = "two_sided"),
    seed = 308,
    n = 400
  )
  reference <- independent_group_treatment_binary_power(0.3, 0.45, 0.05, m = 10, groups = 20,
    individuals = 200, nrep = validation_nrep(), seed = 1308)
  expect_power_near(engine_power(spec), reference, reference_nrep = validation_nrep())
})
