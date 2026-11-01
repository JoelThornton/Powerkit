# Validation: a predictor measured on each item (E67). Backend: simr's
# powerSim(), Satterthwaite's t test for a score, glmer's Wald z test for
# a yes/no outcome.
#   1. analytic agreement: an independent simulation. The participants'
#      intercepts and slopes (bivariate normal, MASS::mvrnorm()) and the
#      items' intercepts are drawn directly, each data set fitted with
#      lmerTest::lmer() or lme4::glmer() without simr
#   2. published examples: a placeholder, for the maintainer
#   3. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

item_reps <- 1000L

item_validation_spec <- function(population, binary, seed, n) {
  validation_spec(
    design = "mixed_model",
    template = "item_predictor",
    variables = list(X = validation_variable("continuous", "Item score"),
      Y = validation_variable(if (binary) "binary" else "continuous", "Outcome")),
    population = c(list(metric = if (binary) "probability" else "raw"), population),
    target_test = list(effect = "slope", method = if (binary) "wald" else "satterthwaite_t", alpha = 0.05),
    seed = seed,
    n = n,
    options = list(nrep = item_reps)
  )
}

item_by_hand <- function(p, binary, n, nrep, seed) {
  x <- stats::qnorm(seq_len(p$items) / (p$items + 1))
  x <- (x - mean(x)) / sqrt(mean((x - mean(x))^2))
  design <- expand.grid(participant = seq_len(n), item = seq_len(p$items))
  design$x <- x[design$item]
  r <- p$r_participant %||% 0
  sigma_p <- matrix(c(p$sd_participant^2, r * p$sd_participant * p$sd_participant_slope,
    r * p$sd_participant * p$sd_participant_slope, p$sd_participant_slope^2), 2)
  with_seed(seed, mean(vapply(seq_len(nrep), function(i) {
    u <- MASS::mvrnorm(n, c(0, 0), sigma_p)
    w <- stats::rnorm(p$items, sd = p$sd_item)
    d <- design
    eta <- (if (binary) stats::qlogis(p$probability) else 0) + p$slope * d$x + u[d$participant, 1] + u[d$participant, 2] * d$x + w[d$item]
    d$y <- if (binary) stats::rbinom(nrow(d), 1, stats::plogis(eta)) else eta + stats::rnorm(nrow(d), sd = p$sd_residual)
    d$participant <- factor(d$participant)
    d$item <- factor(d$item)
    p_value <- tryCatch(suppressMessages(suppressWarnings(if (binary) {
      summary(lme4::glmer(y ~ x + (1 + x | participant) + (1 | item), data = d, family = stats::binomial()))$coefficients["x", "Pr(>|z|)"]
    } else {
      summary(lmerTest::lmer(y ~ x + (1 + x | participant) + (1 | item), data = d))$coefficients["x", "Pr(>|t|)"]
    })), error = function(e) NA)
    isTRUE(p_value < 0.05)
  }, logical(1))))
}

score_population <- list(slope = -15, sd_participant = 60, sd_participant_slope = 10, r_participant = 0.2, sd_item = 30,
  sd_residual = 120, items = 40)
binary_population <- list(slope = 0.3, probability = 0.75, sd_participant = 0.6, sd_participant_slope = 0.2, sd_item = 0.5, items = 40)

for (binary in c(FALSE, TRUE)) {
  test_that(sprintf("item predictor, %s outcome: agrees with an independent simulation (analytic)", if (binary) "yes/no" else "score"), {
    skip_unless_full_validation()
    skip_if_not_installed("lmerTest")
    p <- if (binary) binary_population else score_population
    reference <- item_by_hand(p, binary, 20, item_reps, seed = 6701)
    expect_power_near(engine_power(item_validation_spec(p, binary, seed = 6702, n = 20)), reference, reference_nrep = item_reps)
  })
}

test_that("item predictor, score: Type I error near alpha with no effect", {
  skip_unless_full_validation()
  p <- score_population
  p$slope <- 0
  estimate <- engine_power(item_validation_spec(p, FALSE, seed = 6703, n = 20))
  expect_lt(abs(estimate$power - 0.05), 3 * sqrt(0.05 * 0.95 / item_reps))
})

test_that("item predictor: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (a published power analysis
  # for an item-level predictor with participants and items).
  population <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(population, n, published_power, reference_nrep)
  expect_power_near(engine_power(item_validation_spec(population, FALSE, seed = 6704, n = n)), published_power, reference_nrep = reference_nrep)
})
