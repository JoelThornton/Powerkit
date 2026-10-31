# Validation: people nested in groups (E62), a person-level X, a
# group-level W and their cross-level interaction. Backend: simr's
# powerSim() with lmerTest's Satterthwaite test.
#   1. analytic agreement: an independent simulation. The groups' random
#      intercepts and slopes are drawn directly (bivariate normal, with
#      MASS::mvrnorm()) and the residuals, on the same fixed design; each
#      data set is fitted with lmerTest::lmer() and the effect tested with
#      its Satterthwaite t test, without simr
#   2. published examples: a placeholder, for the maintainer
#   3. Type I error, for each effect
# Mixed models are slow to fit, so these use 2,000 replications rather
# than validation_nrep(), as for E33.
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

two_level_reps <- 2000L

two_level_population <- list(b_X = 0.25, b_W = 0.3, b_XW = 0.15, sd_group = 0.4, sd_group_slope = 0.15,
  r_group = 0.2, sd_residual = 1, cluster_size = 10)

two_level_validation_spec <- function(population, effect, seed, n) {
  validation_spec(
    design = "mixed_model",
    template = "two_level",
    variables = list(X = validation_variable("continuous", "Person level"), W = validation_variable("continuous", "Group level"),
      Y = validation_variable("continuous", "Outcome")),
    population = c(list(metric = "raw"), population),
    target_test = list(effect = effect, method = "satterthwaite_t", alpha = 0.05),
    seed = seed,
    n = n,
    options = list(nrep = two_level_reps)
  )
}

# The independent simulation's share of significant results.
two_level_by_hand <- function(population, term, n, nrep, seed) {
  set.seed(seed)
  m <- population$cluster_size
  groups <- n / m
  x <- stats::qnorm(seq_len(m) / (m + 1))
  x <- (x - mean(x)) / sqrt(mean((x - mean(x))^2))
  w <- stats::qnorm((seq_len(groups) - 0.5) / groups)
  w <- (w - mean(w)) / sqrt(mean((w - mean(w))^2))
  covariance <- with(population, matrix(c(sd_group^2, r_group * sd_group * sd_group_slope,
    r_group * sd_group * sd_group_slope, sd_group_slope^2), 2))
  data <- data.frame(group = factor(rep(seq_len(groups), each = m)), x = rep(x, groups), w = rep(w, each = m))
  mean(vapply(seq_len(nrep), function(i) {
    u <- MASS::mvrnorm(groups, c(0, 0), covariance)
    g <- as.integer(data$group)
    data$y <- with(population, b_X * data$x + b_W * data$w + b_XW * data$x * data$w +
      u[g, 1] + u[g, 2] * data$x + stats::rnorm(n, 0, sd_residual))
    fit <- suppressMessages(suppressWarnings(lmerTest::lmer(y ~ x + w + x:w + (1 + x | group), data = data)))
    summary(fit)$coefficients[term, "Pr(>|t|)"] < 0.05
  }, logical(1)))
}

for (case in list(c("within_effect", "x"), c("between_effect", "w"), c("cross_level_interaction", "x:w"))) {
  test_that(sprintf("two levels, %s: agrees with an independent simulation (analytic)", case[1]), {
    skip_unless_full_validation()
    skip_if_not_installed("MASS")
    skip_if_not_installed("lmerTest")
    reference <- two_level_by_hand(two_level_population, case[2], n = 300, nrep = two_level_reps, seed = 4101)
    spec <- two_level_validation_spec(two_level_population, case[1], seed = 4102, n = 300)
    expect_power_near(engine_power(spec), reference, reference_nrep = two_level_reps)
  })
}

test_that("two levels: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (for example a worked example
  # of a cross-level interaction in a multilevel power tutorial).
  # Transcribe the fixed effects, the groups' SDs, the residual SD, the
  # group size, the number of groups, the effect tested and the power.
  population <- TODO_PUBLISHED_VALUE
  effect <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(population, effect, n, published_power, reference_nrep)
  spec <- two_level_validation_spec(population, effect, seed = 4103, n = n)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# The Satterthwaite test of the person-level effect is slightly
# conservative here, in powerkit and in the independent simulation alike
# (about 4.5% at alpha = .05 over 6,000 data sets each, 31 October 2026),
# so 2,000 replications would leave the 4%-6% band too often by chance:
# the Type I check uses 6,000.
test_that("two levels: Type I error is near alpha for each effect", {
  skip_unless_full_validation()
  null <- modifyList(two_level_population, list(b_X = 0, b_W = 0, b_XW = 0))
  for (effect in c("within_effect", "between_effect", "cross_level_interaction")) {
    spec <- two_level_validation_spec(null, effect, seed = 4104, n = 300)
    spec$options$nrep <- 6000L
    expect_type1_near(engine_power(spec), alpha = 0.05)
  }
})
