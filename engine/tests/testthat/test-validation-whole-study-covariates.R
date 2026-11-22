# Validation: the whole-study simulation with covariates (experimental;
# docs/conventions.md, Departure 13). Every analysis adjusts every
# equation (each mediator and the outcome) for the covariates C1, C2, C3,
# as PROCESS does with covariates. There is no published benchmark for a
# whole-study simulation, so these are agreement checks:
#
#   1. the regressions (the effect of X, the X x W interaction, the effect
#      of X on the mediator) against data simulated here in base R from
#      the same population, with the covariates correlated with X, W and
#      each other, and analysed with stats::lm();
#   2. the indirect effect against the simple mediation card (E10): with a
#      covariate unrelated to X and to the mediator, adjusting Y for it
#      leaves every path to Y as it is in raw units and removes its share
#      of Y's variance (p_CY^2), so each standardised path to Y in the model
#      without it is the whole-study path divided by sqrt(1 - p_CY^2), as
#      for the baseline in test-validation-whole-study-twice.R;
#   3. a two-group X whose groups differ on a covariate (non-randomised
#      groups), against base-R data drawn the same way: the covariate
#      regressed on the standardised groups.
#
# Run as part of the whole-study chunk: scripts/run-validation.R --only
# whole_study. Skipped unless POWERKIT_FULL_VALIDATION=true.

covariate_spec <- function(variables, paths, correlations, analyses, n, seed, binary_x = FALSE) {
  spec <- list(
    spec_version = "0.1", kind = "whole_study",
    variables = lapply(stats::setNames(variables, variables), function(v) list(type = "continuous", label = v)),
    population = list(paths = paths, correlations = correlations),
    analyses = analyses,
    claim = "all", alpha = 0.05,
    effect_justification = list(type = "smallest_effect_of_interest", source = "powerkit validation benchmark (not a real study)"),
    goal = list(type = "power", n = n),
    options = list(nrep = validation_nrep(), ci_draws = validation_ci_draws(), seed = seed)
  )
  if (binary_x) spec$variables$X$type <- "binary"
  validate_whole_study(spec)
}

covariate_estimate <- function(result, id) {
  row <- result$analyses[result$analyses$id == id, ]
  list(power = row$power, mcse = row$mcse)
}

# The correlation matrix of the exogenous variables, from 'A<->B' keys.
exogenous_matrix <- function(names, correlations) {
  r <- diag(length(names))
  dimnames(r) <- list(names, names)
  for (key in names(correlations)) {
    pair <- strsplit(key, "<->", fixed = TRUE)[[1]]
    if (all(pair %in% names)) r[pair[1], pair[2]] <- r[pair[2], pair[1]] <- correlations[[key]]
  }
  r
}

# The proportion of base-R studies in which `term` in `formula` is
# significant at 0.05. The exogenous variables are drawn by `draw(n)`; each
# outcome in `outcomes` (in order) is its linear predictor, from the
# standardised paths, plus normal noise whose variance makes the outcome's
# variance 1, worked out in a large sample. XW is the product of X and W.
base_r_power <- function(draw, outcomes, formula, term, n, nrep, seed) {
  set.seed(seed)
  add_product <- function(d) {
    if (!is.null(d$W)) d$XW <- d$X * d$W
    d
  }
  lp <- function(d, b) drop(as.matrix(d[, names(b), drop = FALSE]) %*% b)
  big <- add_product(draw(2e5))
  residual_sd <- list()
  for (v in names(outcomes)) {
    residual_sd[[v]] <- sqrt(1 - stats::var(lp(big, outcomes[[v]])))
    big[[v]] <- lp(big, outcomes[[v]]) + stats::rnorm(nrow(big), sd = residual_sd[[v]])
  }
  hits <- vapply(seq_len(nrep), function(i) {
    s <- add_product(draw(n))
    for (v in names(outcomes)) s[[v]] <- lp(s, outcomes[[v]]) + stats::rnorm(n, sd = residual_sd[[v]])
    summary(stats::lm(formula, data = s))$coefficients[term, "Pr(>|t|)"] < 0.05
  }, logical(1))
  mean(hits)
}

normal_draw <- function(names, correlations) {
  r <- exogenous_matrix(names, correlations)
  function(n) as.data.frame(MASS::mvrnorm(n, rep(0, length(names)), r))
}

outcomes <- function(...) list(...)

test_that("covariates: the effect of X, adjusted for two correlated covariates, agrees with base-R simulated studies", {
  skip_unless_full_validation()
  paths <- list("X->Y" = 0.15, "C1->Y" = 0.4, "C2->Y" = 0.2)
  correlations <- list("X<->C1" = 0.3, "X<->C2" = 0.2, "C1<->C2" = 0.4)
  result <- run_whole_study(covariate_spec(
    c("X", "C1", "C2", "Y"), paths, correlations,
    analyses = list(list(id = "compare", label = "The effect of X", test = "x_y", role = "main")),
    n = 250, seed = 86001
  ))
  expect_true(all(result$check_run$ok))
  reference <- base_r_power(normal_draw(c("X", "C1", "C2"), correlations),
    outcomes(Y = c(X = 0.15, C1 = 0.4, C2 = 0.2)), Y ~ X + C1 + C2, "X", 250, validation_nrep(), 86002)
  expect_power_near(covariate_estimate(result, "compare"), reference, reference_nrep = validation_nrep())
})

test_that("covariates: the X x W interaction, adjusted for a covariate, agrees with base-R simulated studies", {
  skip_unless_full_validation()
  paths <- list("X->Y" = 0.2, "W->Y" = 0.1, "XW->Y" = 0.15, "C1->Y" = 0.4)
  correlations <- list("X<->W" = 0.2, "X<->C1" = 0.25, "W<->C1" = 0.1)
  result <- run_whole_study(covariate_spec(
    c("X", "W", "C1", "Y"), paths, correlations,
    analyses = list(list(id = "moderation", label = "X x W", test = "interaction", role = "main")),
    n = 300, seed = 86003
  ))
  expect_true(all(result$check_run$ok))
  reference <- base_r_power(normal_draw(c("X", "W", "C1"), correlations),
    outcomes(Y = c(X = 0.2, W = 0.1, XW = 0.15, C1 = 0.4)), Y ~ X + W + X:W + C1, "X:W", 300, validation_nrep(), 86004)
  expect_power_near(covariate_estimate(result, "moderation"), reference, reference_nrep = validation_nrep())
})

test_that("covariates: the effect of X on the mediator, adjusted for a covariate, agrees with base-R simulated studies", {
  skip_unless_full_validation()
  paths <- list("X->M" = 0.2, "C1->M" = 0.35, "X->Y" = 0.1, "M->Y" = 0.3, "C1->Y" = 0.2)
  correlations <- list("X<->C1" = 0.3)
  result <- run_whole_study(covariate_spec(
    c("X", "M", "C1", "Y"), paths, correlations,
    analyses = list(list(id = "check", label = "X on M", test = "x_m", role = "main")),
    n = 200, seed = 86005
  ))
  expect_true(all(result$check_run$ok))
  reference <- base_r_power(normal_draw(c("X", "C1"), correlations),
    outcomes(M = c(X = 0.2, C1 = 0.35)), M ~ X + C1, "X", 200, validation_nrep(), 86006)
  expect_power_near(covariate_estimate(result, "check"), reference, reference_nrep = validation_nrep())
})

test_that("covariates: the indirect effect, with a covariate of the outcome only, agrees with the simple mediation card", {
  skip_unless_full_validation()
  paths <- list("X->M" = 0.3, "C1->M" = 0, "X->Y" = 0.05, "M->Y" = 0.25, "C1->Y" = 0.5)
  result <- run_whole_study(covariate_spec(
    c("X", "M", "C1", "Y"), paths, correlations = list("X<->C1" = 0),
    analyses = list(list(id = "mediation", label = "Mediation", test = "indirect", path = "X->M->Y", role = "main")),
    n = 150, seed = 86007
  ))
  expect_true(all(result$check_run$ok))
  card_paths <- list("X->M" = 0.3, "X->Y" = 0.05 / sqrt(1 - 0.5^2), "M->Y" = 0.25 / sqrt(1 - 0.5^2))
  reference <- engine_power(mediation_spec("process_4", "M", paths = card_paths, path = "X->M->Y", n = 150, seed = 86008))
  expect_power_near(covariate_estimate(result, "mediation"), reference$power, reference_nrep = validation_nrep())
})

test_that("covariates: two groups that differ on a covariate (not randomised) agree with base-R simulated studies", {
  skip_unless_full_validation()
  paths <- list("X->Y" = 0.15, "C1->Y" = 0.4)
  result <- run_whole_study(covariate_spec(
    c("X", "C1", "Y"), paths, correlations = list("X<->C1" = 0.3),
    analyses = list(list(id = "compare", label = "The groups", test = "x_y", role = "main")),
    n = 200, seed = 86009, binary_x = TRUE
  ))
  expect_true(all(result$check_run$ok))
  # Each person in either group with chance 0.5, standardised (X = -1 or
  # 1), and C1 = 0.3 X + normal noise, so that C1 has variance 1 and
  # correlates 0.3 with X.
  draw <- function(n) {
    x <- 2 * stats::rbinom(n, 1, 0.5) - 1
    data.frame(X = x, C1 = 0.3 * x + stats::rnorm(n, sd = sqrt(1 - 0.3^2)))
  }
  reference <- base_r_power(draw, outcomes(Y = c(X = 0.15, C1 = 0.4)), Y ~ X + C1, "X", 200, validation_nrep(), 86010)
  expect_power_near(covariate_estimate(result, "compare"), reference, reference_nrep = validation_nrep())
})
