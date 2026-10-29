# Validation: a yes/no outcome with two crossed factors (logistic
# regression with both factors and their interaction, effect coding; the
# Wald test of one effect's coefficients). Backend: Spower's p_glm(),
# simulated. Build guide section 6:
#   1. analytic agreement: none (no closed form for these Wald tests)
#   2. published examples: placeholders below, for the maintainer
#   3. direct-call agreement with Spower
#   4. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

logit_factorial_validation_spec <- function(probabilities, effect, seed, n = NULL, target_power = NULL, alpha = 0.05) {
  v <- validation_variable
  a <- length(probabilities)
  b <- length(probabilities[[1]])
  validation_spec(
    design = "logistic_regression",
    template = "factorial",
    variables = list(
      A = v("between_factor", "First factor", levels = as.list(paste0("a", seq_len(a)))),
      B = v("between_factor", "Second factor", levels = as.list(paste0("b", seq_len(b)))),
      Y = v("binary", "Outcome", levels = list("No", "Yes"))
    ),
    population = list(metric = "proportion", probabilities = probabilities),
    target_test = list(effect = effect, method = "wald_chi_square", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power
  )
}

cells_2x3 <- list(list(0.3, 0.4, 0.25), list(0.4, 0.45, 0.3))

# 1. Published example -----------------------------------------------------------

test_that("logistic factorial: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE (the maintainer chooses a published power
  #   example for a factorial logistic regression and records it here).
  probabilities <- TODO_PUBLISHED_VALUE # proportion of 'yes' per cell, one row per level of A
  effect <- TODO_PUBLISHED_VALUE # "main_effect_A", "main_effect_B" or "interaction"
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(probabilities, effect, n, published_power, reference_nrep)
  spec <- logit_factorial_validation_spec(probabilities, effect, seed = 801, n = n)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Direct call -------------------------------------------------------------------

test_that("logistic factorial: powerkit matches Spower called directly", {
  skip_unless_full_validation()
  spec <- logit_factorial_validation_spec(cells_2x3, "main_effect_A", seed = 901, n = 600)
  cells <- expand.grid(A = factor(1:2), B = factor(1:3))
  contrasts(cells$A) <- contr.sum(2)
  contrasts(cells$B) <- contr.sum(3)
  p <- matrix(unlist(cells_2x3), nrow = 2, byrow = TRUE)
  betas <- drop(solve(model.matrix(~ A * B, cells), qlogis(p[cbind(as.integer(cells$A), as.integer(cells$B))])))
  X <- cells[rep(1:6, each = 100), ]
  power <- Spower::Spower(
    Spower::p_glm(y ~ A * B, X = X, betas = betas, test = "A1 = 0", family = binomial()),
    replications = validation_nrep(), seed = 902, parallel = FALSE, verbose = FALSE
  )$power
  direct <- list(power = power, mcse = sqrt(power * (1 - power) / validation_nrep()))
  expect_power_agrees(engine_power(spec), direct)
})

# 4. Type I error ------------------------------------------------------------------

test_that("logistic factorial: Type I error is near alpha when the interaction is 0 on the log-odds scale", {
  skip_unless_full_validation()
  # Additive on the log-odds scale: A shifts every column by the same log
  # odds ratio, so the interaction's coefficients are 0.
  row1 <- c(0.3, 0.4, 0.25)
  row2 <- plogis(qlogis(row1) + 0.4)
  spec <- logit_factorial_validation_spec(list(as.list(row1), as.list(row2)), "interaction", seed = 1001, n = 600)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
