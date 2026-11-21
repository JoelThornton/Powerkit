# Validation: an ordinal outcome compared between two groups, under
# proportional odds. Backend: powertools::propodds() by formula (Whitehead's
# method, as its help cites). Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-ordinal.R) check
#      powerkit against propodds() called directly; below, against Hmisc's
#      popower(), an independent implementation of the same method
#   2. published examples: placeholders below, for the maintainer
#   3. agreement with studies simulated separately: the proportional-odds
#      model written out, each study fitted by MASS::polr(), with most people
#      at one end of the scale, both directions of the shift and unequal
#      groups. This is the check that would have caught the direction
#      error fixed on 17 November 2026: propodds() and popower() share the
#      convention, so comparing them could not
#   4. Type I error: not applicable to the formula (an odds ratio of 1 is
#      refused as no effect)
# Values transcribed from a published source or G*Power (tests marked
# "(published)" or "(G*Power value)", or a value whose comment cites its
# source) are owned by the maintainer: do not edit them. Other expected
# values were written with the code (CLAUDE.md, Non-negotiables).
# Skipped unless POWERKIT_FULL_VALIDATION=true.

ordinal_validation_spec <- function(probabilities, odds_ratio, n = NULL, target_power = NULL,
                                    alpha = 0.05, allocation_ratio = 1) {
  v <- validation_variable
  validation_spec(
    design = "ordinal_regression",
    template = "ordinal_two_groups",
    variables = list(
      X = v("binary", "Group", levels = list("First", "Second")),
      Y = v("categorical", "Outcome", levels = as.list(paste("Category", seq_along(probabilities))))
    ),
    population = list(metric = "proportion", probabilities = as.list(probabilities), odds_ratio = odds_ratio),
    target_test = list(effect = "odds_ratio", method = "proportional_odds", alpha = alpha),
    seed = 1,
    n = n,
    target_power = target_power,
    options = list(allocation_ratio = allocation_ratio)
  )
}

# 1. Published example -----------------------------------------------------------

test_that("ordinal outcome, two groups: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE (for example the method paper powertools'
  #   help for propodds() cites, Whitehead (1993); the maintainer adds it to
  #   refs.bib and records the section, table and page here).
  probabilities <- TODO_PUBLISHED_VALUE # group 1's share in each category, in order
  odds_ratio <- TODO_PUBLISHED_VALUE
  alpha <- TODO_PUBLISHED_VALUE
  target_power <- TODO_PUBLISHED_VALUE
  published_n <- TODO_PUBLISHED_VALUE # the published total sample size
  skip_if_todo(probabilities, odds_ratio, alpha, target_power, published_n)
  spec <- ordinal_validation_spec(probabilities, odds_ratio, target_power = target_power, alpha = alpha)
  expect_equal(run_spec(spec)$n_required$n, published_n)
})

# 2. Independent implementation ------------------------------------------------------

test_that("ordinal outcome, two groups: equals Hmisc's popower(), with equal and unequal groups", {
  skip_unless_full_validation()
  p_control <- c(0.2, 0.5, 0.2, 0.1)
  for (ratio in c(1, 2)) {
    n1 <- 60
    spec <- ordinal_validation_spec(p_control, 2.5, n = n1 * (1 + ratio), allocation_ratio = ratio)
    # popower() takes the average of the two groups' shares; Hmisc's
    # pomodm() gives group 2's shares under proportional odds; an odds ratio
    # above 1 moves them towards the higher categories, as the card's help says
    # (the comparison used 1 / 2.5, the engine's old direction, until 17
    # November 2026; changed with the maintainer's agreement).
    p_average <- (p_control + Hmisc::pomodm(p = p_control, odds.ratio = 2.5)) / 2
    direct <- Hmisc::popower(p = p_average, odds.ratio = 2.5, n1 = n1, n2 = n1 * ratio)$power
    expect_equal(run_spec(spec)$curve$power, direct, tolerance = 1e-8, label = paste("ratio", ratio))
  }
})


# 3. Independent simulation ---------------------------------------------------------
# Whitehead's formula is a large-sample approximation to the test of the
# group's coefficient, so the simulated Wald test may differ from it by a
# little more than Monte Carlo error at these sizes (1 to 2 points in the
# first runs): an allowance of 0.03 power, well below the error the
# direction mistake made (a factor of about two in the sample size).

test_that("ordinal outcome, two groups: agrees with proportional-odds studies simulated separately and fitted by polr() (simulation)", {
  skip_unless_full_validation()
  skewed <- c(0.6, 0.25, 0.1, 0.05)
  cases <- list(
    list(shares = skewed, odds_ratio = 2, n = 160, ratio = 1, seed = 601),
    list(shares = skewed, odds_ratio = 0.5, n = 160, ratio = 1, seed = 602),
    list(shares = skewed, odds_ratio = 0.5, n = 180, ratio = 2, seed = 603),
    list(shares = c(0.1, 0.3, 0.4, 0.2), odds_ratio = 1.8, n = 200, ratio = 1, seed = 604)
  )
  powers <- numeric(0)
  for (case in cases) {
    spec <- ordinal_validation_spec(case$shares, case$odds_ratio, n = case$n, allocation_ratio = case$ratio)
    estimate <- engine_power(spec)
    reference <- independent_ordinal_power(case$shares, case$odds_ratio, case$n, case$ratio,
      nrep = validation_nrep(), seed = case$seed)
    expect_power_within_approximation(estimate, reference, validation_nrep(), allowance = 0.03)
    powers <- c(powers, estimate$power)
  }
  # With most people in the lowest category, a shift up (odds ratio 2) and
  # the same shift down (0.5) have different power; the order must be the
  # simulation's.
  up <- independent_ordinal_power(skewed, 2, 160, nrep = validation_nrep(), seed = 605)
  down <- independent_ordinal_power(skewed, 0.5, 160, nrep = validation_nrep(), seed = 606)
  expect_identical(sign(powers[1] - powers[2]), sign(up - down))
})
