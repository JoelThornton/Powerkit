# Validation: participants responding to many items in three or more
# conditions (E63). Backend: simr's powerSim() with lmerTest's Satterthwaite
# F test, or a pair's Satterthwaite t test adjusted for all the pairs.
# Build guide section 6:
#   1. analytic agreement: an independent simulation. The random effects
#      are drawn directly (participants, participant-by-condition, items,
#      residuals), each data set is fitted with lmerTest::lmer() and tested
#      with anova() or difflsmeans() and stats::p.adjust(), without simr
#   2. published examples: a placeholder, for the maintainer
#   3. Type I error, the F test and a pair with no difference
# Mixed models are slow to fit, so these use 2,000 replications, as for E33.
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

conditions_reps <- 2000L

conditions_population <- list(means = list(0, 0.15, 0.3), sd_participant = 0.5, sd_participant_condition = 0.2,
  sd_item = 0.3, sd_residual = 1, items = 30, item_design = "between")

conditions_validation_spec <- function(population, effect, seed, n) {
  validation_spec(
    design = "mixed_model",
    template = "crossed_conditions",
    variables = list(
      X = validation_variable("within_factor", "Condition", levels = list("First", "Second", "Third")),
      Y = validation_variable("continuous", "Outcome")
    ),
    population = c(list(metric = "raw"), population),
    target_test = c(list(effect = effect, alpha = 0.05),
      if (effect == "pairwise") list(method = "satterthwaite_t", comparison = list("First", "Second"), p_adjust = "holm") else
        list(method = "satterthwaite_f")),
    seed = seed,
    n = n,
    options = list(nrep = conditions_reps)
  )
}

conditions_by_hand <- function(p, effect, n, nrep, seed) {
  k <- 3
  design <- expand.grid(participant = seq_len(n), item = seq_len(p$items))
  design$cond <- ceiling(design$item / (p$items / k))
  means <- unlist(p$means)
  with_seed(seed, mean(vapply(seq_len(nrep), function(i) {
    u <- stats::rnorm(n, sd = p$sd_participant)
    uc <- matrix(stats::rnorm(n * k, sd = p$sd_participant_condition), n, k)
    w <- stats::rnorm(p$items, sd = p$sd_item)
    d <- design
    d$y <- means[d$cond] + u[d$participant] + uc[cbind(d$participant, d$cond)] + w[d$item] +
      stats::rnorm(nrow(d), sd = p$sd_residual)
    d$participant <- factor(d$participant)
    d$item <- factor(d$item)
    d$cond <- factor(d$cond)
    fit <- tryCatch(suppressMessages(suppressWarnings(
      lmerTest::lmer(y ~ cond + (1 | participant) + (1 | participant:cond) + (1 | item), data = d)
    )), error = function(e) NULL)
    if (is.null(fit)) return(FALSE)
    p_value <- if (effect == "pairwise") {
      lsm <- lmerTest::difflsmeans(fit, which = "cond", ddf = "Satterthwaite")
      stats::p.adjust(lsm[["Pr(>|t|)"]], "holm")[[1]] # the first pair: 1 - 2
    } else {
      stats::anova(fit, ddf = "Satterthwaite")["cond", "Pr(>F)"]
    }
    isTRUE(p_value < 0.05)
  }, logical(1))))
}

for (effect in c("condition", "pairwise")) {
  test_that(sprintf("three conditions, %s: agrees with an independent simulation (analytic)", effect), {
    skip_unless_full_validation()
    skip_if_not_installed("lmerTest")
    spec <- conditions_validation_spec(conditions_population, effect, seed = 6301, n = 30)
    reference <- conditions_by_hand(conditions_population, effect, 30, conditions_reps, seed = 6302)
    expect_power_near(engine_power(spec), reference, reference_nrep = conditions_reps)
  })

  test_that(sprintf("three conditions, %s: Type I error near alpha with no difference", effect), {
    skip_unless_full_validation()
    # The means are set directly: utils::modifyList() leaves an unnamed
    # list as it was.
    null <- conditions_population
    null$means <- if (effect == "condition") list(0, 0, 0) else list(0, 0, 0.3)
    # The pair First-Second has no difference: with Holm's adjustment over
    # the three pairs its rejection rate is at most alpha.
    estimate <- engine_power(conditions_validation_spec(null, effect, seed = 6303, n = 30))
    if (effect == "condition") expect_type1_near(estimate, alpha = 0.05) else expect_lt(estimate$power, 0.05 + 3 * estimate$mcse)
  })
}

test_that("three conditions: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (a published power analysis for
  # participants and items as random factors with three or more
  # conditions). Transcribe the means, the SDs, the number of items, the
  # number of participants and the power.
  population <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(population, n, published_power, reference_nrep)
  spec <- conditions_validation_spec(population, "condition", seed = 6304, n = n)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})
