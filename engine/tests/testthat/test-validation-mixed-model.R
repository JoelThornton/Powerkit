# Validation: participants responding to many items in two conditions
# (E33). Backend: simr's powerSim() with lmerTest's Satterthwaite test.
# Build guide section 6:
#   1. analytic agreement: an independent simulation. Random effects are
#      drawn directly (participants' intercepts and slopes, bivariate
#      normal; items' intercepts; residuals), each data set is fitted with
#      lme4 and the condition tested with lmerTest's Satterthwaite t test.
#   2. published examples: placeholders below, for the maintainer
#   3. direct-call agreement with simr (the engine's own tests check this
#      replication for replication; here at more replications)
#   4. Type I error
# Departure 16 (Satterthwaite rather than simr's default "z") is sized in
# docs/conventions.md from the same model.
# Mixed models are slow to fit, so these use 2,000 replications rather
# than validation_nrep().
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

mixed_reps <- 2000L

mixed_validation_spec <- function(population, seed, n) {
  validation_spec(
    design = "mixed_model",
    template = "crossed_two_condition",
    variables = list(
      X = validation_variable("within_factor", "Condition", levels = list("First", "Second")),
      Y = validation_variable("continuous", "Outcome")
    ),
    population = c(list(metric = "raw"), population),
    target_test = list(effect = "condition", method = "satterthwaite_t", alpha = 0.05),
    seed = seed,
    n = n,
    options = list(nrep = mixed_reps)
  )
}

pop_crossed <- list(
  difference = 0.3, sd_participant = 0.5, sd_participant_slope = 0.3, r_participant = 0.2,
  sd_item = 0.4, sd_residual = 1, items = 30, item_design = "between"
)

# 1. Independent simulation ----------------------------------------------------------

test_that("crossed design: agrees with an independent simulation (analytic)", {
  skip_unless_full_validation()
  n <- 30
  spec <- mixed_validation_spec(pop_crossed, seed = 3301, n = n)
  p <- pop_crossed
  design <- expand.grid(participant = seq_len(n), item = seq_len(p$items))
  design$cond <- ifelse(design$item <= p$items / 2, -0.5, 0.5)
  sigma_p <- matrix(c(p$sd_participant^2, p$r_participant * p$sd_participant * p$sd_participant_slope,
    p$r_participant * p$sd_participant * p$sd_participant_slope, p$sd_participant_slope^2), 2)
  rejected <- with_seed(3302, vapply(seq_len(mixed_reps), function(i) {
    u <- MASS::mvrnorm(n, c(0, 0), sigma_p)
    w <- stats::rnorm(p$items, sd = p$sd_item)
    d <- design
    d$y <- p$difference * d$cond + u[d$participant, 1] + u[d$participant, 2] * d$cond + w[d$item] +
      stats::rnorm(nrow(d), sd = p$sd_residual)
    d$participant <- factor(d$participant)
    d$item <- factor(d$item)
    fit <- tryCatch(suppressMessages(suppressWarnings(
      lmerTest::lmer(y ~ cond + (1 + cond | participant) + (1 | item), data = d)
    )), error = function(e) NULL)
    !is.null(fit) && summary(fit)$coefficients["cond", "Pr(>|t|)"] < 0.05
  }, logical(1)))
  expect_power_near(engine_power(spec), mean(rejected), reference_nrep = mixed_reps)
})

# 2. Published example ------------------------------------------------------------

test_that("crossed design: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE (the maintainer chooses a published power
  #   example for a design with participants and items as random factors).
  population <- TODO_PUBLISHED_VALUE # list(difference, sd_participant, sd_participant_slope, r_participant, sd_item, sd_residual, items, item_design)
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(population, n, published_power, reference_nrep)
  spec <- mixed_validation_spec(population, seed = 3303, n = n)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Direct call -------------------------------------------------------------------

test_that("crossed design: powerkit matches simr called directly", {
  skip_unless_full_validation()
  spec <- mixed_validation_spec(pop_crossed, seed = 3304, n = 30)
  model <- simr_model(simr_inputs(spec), 30)
  direct <- suppressMessages(suppressWarnings(simr::powerSim(
    model, test = simr::fixed("cond", "sa"), nsim = mixed_reps, seed = 3305, progress = FALSE
  )))
  expect_power_near(engine_power(spec), direct$x / direct$n, reference_nrep = mixed_reps)
})

# 4. Type I error ------------------------------------------------------------------

test_that("crossed design: Type I error is alpha when the conditions don't differ", {
  skip_unless_full_validation()
  spec <- mixed_validation_spec(utils::modifyList(pop_crossed, list(difference = 0)), seed = 3306, n = 30)
  expect_power_near(engine_power(spec), 0.05)
})
