# Validation: a planned comparison (contrast) between the levels of one
# between-participants factor. Backend: pwrss's power.t.contrasts() by
# formula. Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-formula-tests.R)
#      check powerkit against pwrss called directly, and against the same
#      contrast computed through Superpower's emmeans support
#   2. published examples: the G*Power 3.1 manual (below)
#   3. direct-call agreement with a simulation: not yet (no simulation
#      option)
#   4. Type I error: a contrast of 0 gives alpha by construction (unit
#      tests)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

contrast_spec <- function(means, sd, weights, alpha, seed, n = NULL, target_power = NULL) {
  v <- validation_variable
  levels <- lapply(seq_along(means), function(i) paste("Level", i))
  validation_spec(
    design = "factorial_anova",
    template = "oneway_contrast",
    variables = list(
      A = v("between_factor", "Factor", levels = levels),
      Y = v("continuous", "Outcome")
    ),
    population = list(metric = "raw", means = as.list(means), sd = sd),
    target_test = list(
      effect = "contrast", method = "contrast_t", alpha = alpha,
      weights = as.list(weights)
    ),
    seed = seed,
    n = n,
    target_power = target_power
  )
}

# 2. Published examples: G*Power 3.1 -------------------------------------------
#
# All three tests below come from one worked example: G*Power 3.1 manual
# (version of June 1, 2023), section 11.3.3 ("F test: Fixed effects ANOVA -
# special, main effects and interactions", Power for planned comparisons),
# p. 29. Its design is a single factor with four levels, mean vector
# (1.5, 2, 3, 4), n = 5 in each group and SD 2 within each group, and it
# tabulates three contrasts with their weights, sigma_m, f, eta-squared and
# power.
#
# How G*Power computes a contrast, and what to transcribe:
#   * G*Power has no contrast input screen. A contrast is entered into the
#     factorial ANOVA test as an effect size f with "Numerator df" 1 and
#     "Number of groups" the number of levels (4 here). The f for a
#     contrast C = sum(c_i * mu_i) is f = sigma_m / sigma with
#     sigma_m = |C| / sqrt(N * sum(c_i^2 / n_i)) (11.3.3, p. 29).
#   * powerkit takes the means, the SD and the weights instead, and derives
#     the contrast itself, so what is transcribed here is the **power**,
#     plus the inputs. The published f is worth checking against the
#     table's own f while transcribing: if it matches, the weights were
#     entered as the manual intends.
#   * The weights' scale doesn't matter (a unit test checks this), so the
#     table's weights can be transcribed as printed, including halves.
# Caution on the printed block (11.3.3, p. 29): it says "Type of power
#   analysis: A priori" but supplies a total sample size and reports power,
#   which is a post hoc analysis. Take the N from the design (4 groups of
#   5, so 20) and the power from the table.

test_that("contrast, two levels against two: matches the G*Power 3.1 manual example (published)", {
  skip_unless_full_validation()
  # Source: as above. The table's first row, "1,2 vs. 3,4".
  means <- c(1.5, 2, 3, 4) # the example's mean vector, in order
  sd <- 2 # SD within each group
  n <- 20 # total sample size (groups x n per group)
  weights <- c(-0.5, -0.5, 0.5, 0.5) # the row's weights c, in order
  alpha <- 0.05 # alpha err prob
  published_power <- 0.451898 # the power reported for this contrast
  skip_if_todo(means, sd, n, weights, alpha, published_power)

  spec <- contrast_spec(means, sd, weights, alpha, seed = 201, n = n)
  expect_power_exact(engine_power(spec), published_power)
})

test_that("contrast, linear trend: matches the G*Power 3.1 manual example (published)", {
  skip_unless_full_validation()
  # Source: as above. The table's second row, "lin. trend".
  means <- c(1.5, 2, 3, 4)
  sd <- 2
  n <- 20
  weights <- c(-3, -1, 1, 3)
  alpha <- 0.05
  published_power <- 0.514736
  skip_if_todo(means, sd, n, weights, alpha, published_power)

  spec <- contrast_spec(means, sd, weights, alpha, seed = 202, n = n)
  expect_power_exact(engine_power(spec), published_power)
})

test_that("contrast, quadratic trend: matches the G*Power 3.1 manual example (published)", {
  skip_unless_full_validation()
  # Source: as above. The table's third row, "quad. trend". This row is the
  # useful one for the engine's arithmetic: its power is close to alpha, so
  # a sign or weighting mistake shows up plainly.
  means <- c(1.5, 2, 3, 4)
  sd <- 2
  n <- 20
  weights <- c(1, -1, -1, 1)
  alpha <- 0.05
  published_power <- 0.057970
  skip_if_todo(means, sd, n, weights, alpha, published_power)

  spec <- contrast_spec(means, sd, weights, alpha, seed = 203, n = n)
  expect_power_exact(engine_power(spec), published_power)
})
