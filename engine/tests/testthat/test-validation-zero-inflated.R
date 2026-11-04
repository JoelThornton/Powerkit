# Validation: zero-inflated Poisson and negative binomial regression of a
# count on one predictor.
# Backend: Spower simulation of powerkit's experiment p_zero_inflated(),
# which fits pscl's zeroinfl().
#   1. agreement with an independent simulation: the counts drawn as a
#      mixture (each person an extra zero with the zero part's probability,
#      otherwise a Poisson count, or for negative binomial counts a Poisson
#      count with a gamma frailty), and the zero-inflated likelihood
#      written out and maximised by stats::optim(), without powerkit's
#      code or pscl; the Wald z test of the count part and the
#      likelihood-ratio test of both parts
#   2. Type I error of the count part's test when the predictor changes
#      only the share of extra zeros, and of the zero part's test when it
#      changes only the rate
#   3. published example: placeholder, for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

zi_validation_spec <- function(rate_ratio, base_rate, zero_prob, zero_odds_ratio, n, dispersion = NULL, effect = "rate_ratio") {
  validation_spec(
    design = "poisson_regression",
    template = "single_predictor_count",
    variables = list(X = validation_variable("continuous", "Score"), Y = validation_variable("count", "Events")),
    population = c(list(metric = "rate_ratio", rate_ratio = rate_ratio, base_rate = base_rate, zero_prob = zero_prob,
      zero_odds_ratio = zero_odds_ratio), if (!is.null(dispersion)) list(dispersion = dispersion)),
    target_test = list(effect = effect, alpha = 0.05,
      method = if (is.null(dispersion)) "zero_inflated_poisson" else "zero_inflated_negative_binomial"),
    seed = 7101,
    n = n
  )
}

# The zero-inflated log-likelihood, written out: an extra zero with
# probability pi = plogis(g0 + g1 x), otherwise a Poisson (or negative
# binomial, log theta as the last parameter) count with mean exp(b0 + b1 x).
zi_loglik <- function(theta, x, y, negbin, with_x = TRUE) {
  if (!with_x) theta <- c(theta[1], 0, theta[2], 0, theta[-(1:2)])
  mu <- exp(theta[1] + theta[2] * x)
  pi <- stats::plogis(theta[3] + theta[4] * x)
  count <- if (negbin) stats::dnbinom(y, size = exp(theta[5]), mu = mu, log = TRUE) else stats::dpois(y, mu, log = TRUE)
  sum(ifelse(y == 0, log(pi + (1 - pi) * exp(count)), log(1 - pi) + count))
}

zi_by_hand <- function(rate_ratio, base_rate, zero_prob, zero_odds_ratio, n, nrep, seed, dispersion = NULL, joint = FALSE) {
  negbin <- !is.null(dispersion)
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    x <- stats::rnorm(n)
    frailty <- if (negbin) stats::rgamma(n, shape = 1 / dispersion, scale = dispersion) else 1
    counts <- stats::rpois(n, base_rate * rate_ratio^x * frailty)
    y <- ifelse(stats::runif(n) < stats::plogis(stats::qlogis(zero_prob) + log(zero_odds_ratio) * x), 0, counts)
    start <- c(log(mean(y[y > 0])), 0, stats::qlogis(max(mean(y == 0) - 0.05, 0.05)), 0, if (negbin) 0)
    fit <- stats::optim(start, zi_loglik, x = x, y = y, negbin = negbin, method = "BFGS", hessian = TRUE,
      control = list(fnscale = -1, maxit = 500, reltol = 1e-12))
    if (joint) {
      reduced <- stats::optim(start[-c(2, 4)], zi_loglik, x = x, y = y, negbin = negbin, with_x = FALSE, method = "BFGS",
        control = list(fnscale = -1, maxit = 500, reltol = 1e-12))
      return(stats::pchisq(2 * (fit$value - reduced$value), df = 2, lower.tail = FALSE) < 0.05)
    }
    se <- sqrt(diag(solve(-fit$hessian)))
    2 * stats::pnorm(-abs(fit$par[2] / se[2])) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("zero-inflated: powerkit agrees with the likelihood written out and maximised separately (simulation)", {
  skip_unless_full_validation()
  spec <- zi_validation_spec(0.85, 2, 0.3, 1, 300)
  expect_power_agrees_within(engine_power(spec), zi_by_hand(0.85, 2, 0.3, 1, 300, 4000L, 711), allowance = 0)
  spec <- zi_validation_spec(0.85, 2, 0.3, 1.5, 250, effect = "rate_and_zero")
  expect_power_agrees_within(engine_power(spec), zi_by_hand(0.85, 2, 0.3, 1.5, 250, 4000L, 712, joint = TRUE), allowance = 0)
  spec <- zi_validation_spec(1.3, 3, 0.25, 1, 250, dispersion = 0.5)
  expect_power_agrees_within(engine_power(spec), zi_by_hand(1.3, 3, 0.25, 1, 250, 4000L, 713, dispersion = 0.5), allowance = 0)
})

test_that("zero-inflated: each part's test keeps its Type I error when the predictor changes only the other part (simulation)", {
  skip_unless_full_validation()
  spec <- zi_validation_spec(1, 2, 0.3, 1.8, 400)
  expect_type1_near(engine_power(spec), alpha = 0.05)
  spec <- zi_validation_spec(0.7, 2, 0.3, 1, 400, dispersion = 0.5, effect = "zero_odds_ratio")
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("zero-inflated: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power or sample-size example for
  # zero-inflated Poisson or negative binomial regression with one
  # predictor; source, section, page).
  rate_ratio <- TODO_PUBLISHED_VALUE
  base_rate <- TODO_PUBLISHED_VALUE
  zero_prob <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(rate_ratio, base_rate, zero_prob, n, published_power)
  spec <- zi_validation_spec(rate_ratio, base_rate, zero_prob, 1, n)
  expect_power_near(engine_power(spec), exact_estimate(published_power))
})
