# Validation: moderation with an outcome in three or more unordered
# categories (design "logistic_regression", template
# "multinomial_interaction", E32).
# Backend: Spower simulation of powerkit's experiment
# p_multinomial_interaction(), which fits nnet's multinom() of y ~ x * w.
#   1. analytic agreement: an independent simulation that draws each
#      category by the Gumbel-maximum rule and fits the same model by
#      maximising the multinomial log-likelihood written out here (with
#      its gradient, by stats::optim()'s BFGS), without nnet or powerkit's
#      code, testing the X x W terms by the change in deviance (every
#      category together) or one category's X x W coefficient by its Wald
#      z, from the inverse of the Hessian (the multinomial-Poisson form in
#      stats::glm() gives the same fit but takes seconds per data set)
#   2. Type I error with X and W both affecting the outcome and no
#      interaction
#   3. published example: placeholder, for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

mi_reps <- 2000L

mi_validation_spec <- function(probabilities, or_x, or_w, or_xw, n, x_binary = FALSE, w_binary = FALSE, r = 0,
                               method = "likelihood_ratio", category = NULL, seed = 3201) {
  levels <- as.list(paste("Category", seq_along(probabilities)))
  variable <- function(binary, label) {
    if (binary) validation_variable("binary", label, levels = list("First", "Second")) else validation_variable("continuous", label)
  }
  validation_spec(
    design = "logistic_regression",
    template = "multinomial_interaction",
    variables = list(X = variable(x_binary, "X"), W = variable(w_binary, "W"),
      Y = validation_variable("categorical", "Choice", levels = levels)),
    population = c(list(metric = "odds_ratio", probabilities = as.list(probabilities), odds_ratios_x = as.list(or_x),
      odds_ratios_w = as.list(or_w), odds_ratios_xw = as.list(or_xw)), if (!x_binary && !w_binary && r != 0) list(r_xw = r)),
    target_test = c(list(effect = "interaction", method = method, alpha = 0.05), if (!is.null(category)) list(category = category)),
    seed = seed,
    n = n,
    options = list(nrep = mi_reps)
  )
}

# The multinomial logit's maximum likelihood fit: one column of
# coefficients for each category but the first, stacked; value is the
# negative log-likelihood and hessian its second derivatives.
mi_fit_by_hand <- function(design, y, k) {
  p <- ncol(design)
  indicator <- outer(y, seq_len(k), "==")[, -1, drop = FALSE]
  shares <- function(beta) {
    eta <- design %*% matrix(beta, p, k - 1)
    list(eta = eta, total = log1p(rowSums(exp(eta))))
  }
  value <- function(beta) {
    s <- shares(beta)
    -(sum(s$eta * indicator) - sum(s$total))
  }
  gradient <- function(beta) {
    s <- shares(beta)
    -as.vector(crossprod(design, indicator - exp(s$eta - s$total)))
  }
  stats::optim(rep(0, p * (k - 1)), value, gradient, method = "BFGS", hessian = TRUE,
    control = list(maxit = 500, reltol = 1e-12))
}

# The independent simulation: X and W drawn directly, each category by the
# Gumbel-maximum rule, the model fitted as a Poisson log-linear model.
mi_by_hand <- function(probabilities, or_x, or_w, or_xw, n, nrep, seed, x_binary = FALSE, w_binary = FALSE, r = 0,
                       wald_category = NULL) {
  k <- length(probabilities)
  b0 <- c(0, log(probabilities[-1] / probabilities[1]))
  bx <- c(0, log(or_x))
  bw <- c(0, log(or_w))
  bxw <- c(0, log(or_xw))
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    if (!x_binary && !w_binary) {
      z <- matrix(stats::rnorm(2 * n), n)
      x <- z[, 1]
      w <- r * z[, 1] + sqrt(1 - r^2) * z[, 2]
    } else {
      x <- if (x_binary) sample(rep(0:1, c(n - n %/% 2, n %/% 2))) else stats::rnorm(n)
      w <- if (w_binary) stats::rbinom(n, 1, 0.5) else stats::rnorm(n)
    }
    gumbel <- matrix(-log(-log(stats::runif(n * k))), n, k)
    eta <- outer(rep(1, n), b0) + outer(x, bx) + outer(w, bw) + outer(x * w, bxw) + gumbel
    y <- max.col(eta, ties.method = "first")
    if (length(unique(y)) < k) return(FALSE)
    design <- cbind(1, x, w, x * w)
    full <- mi_fit_by_hand(design, y, k)
    if (!is.null(wald_category)) {
      # The X x W coefficient of category wald_category against the first.
      index <- (wald_category - 2) * ncol(design) + 4
      z <- full$par[index] / sqrt(solve(full$hessian)[index, index])
      return(2 * stats::pnorm(-abs(z)) < 0.05)
    }
    reduced <- mi_fit_by_hand(design[, 1:3], y, k)
    stats::pchisq(2 * (reduced$value - full$value), df = k - 1, lower.tail = FALSE) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

mi_cases <- list(
  list(label = "two scores, likelihood ratio", p = c(0.5, 0.3, 0.2), or_x = c(1.3, 1), or_w = c(1.2, 0.9), or_xw = c(0.7, 0.9),
    n = 300, r = 0.3),
  list(label = "a yes/no X and a score W, likelihood ratio, four categories", p = c(0.4, 0.3, 0.2, 0.1), or_x = c(0.8, 1, 1.2),
    or_w = c(1.3, 1.1, 1), or_xw = c(0.6, 0.9, 1.1), n = 500, x_binary = TRUE),
  list(label = "two scores, Wald z of one category", p = c(0.5, 0.3, 0.2), or_x = c(1.3, 1), or_w = c(1.2, 0.9), or_xw = c(0.7, 0.9),
    n = 300, method = "wald_z", category = 2L)
)

for (case in mi_cases) {
  test_that(sprintf("multinomial moderation, %s: agrees with an independent simulation (analytic)", case$label), {
    skip_unless_full_validation()
    x_binary <- isTRUE(case$x_binary)
    spec <- mi_validation_spec(case$p, case$or_x, case$or_w, case$or_xw, case$n, x_binary = x_binary, r = case$r %||% 0,
      method = case$method %||% "likelihood_ratio", category = if (!is.null(case$category)) paste("Category", case$category))
    reference <- mi_by_hand(case$p, case$or_x, case$or_w, case$or_xw, case$n, mi_reps, seed = 3202, x_binary = x_binary,
      r = case$r %||% 0, wald_category = case$category)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  })
}

test_that("multinomial moderation: Type I error near alpha with main effects and no interaction", {
  skip_unless_full_validation()
  band <- 3 * sqrt(0.05 * 0.95 / mi_reps)
  null <- engine_power(mi_validation_spec(c(0.5, 0.3, 0.2), c(1.5, 0.8), c(1.3, 1.2), c(1, 1), 250, seed = 3203))
  expect_lt(abs(null$power - 0.05), band)
  wald <- engine_power(mi_validation_spec(c(0.4, 0.4, 0.2), c(1.4, 1), c(1, 1.3), c(1, 1), 300, x_binary = TRUE,
    method = "wald_z", category = "Category 3", seed = 3204))
  expect_lt(abs(wald$power - 0.05), band)
})

test_that("multinomial moderation: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (a published power analysis for
  # an interaction in a multinomial logistic regression; source, section,
  # page).
  probabilities <- TODO_PUBLISHED_VALUE
  odds_ratios_x <- TODO_PUBLISHED_VALUE
  odds_ratios_w <- TODO_PUBLISHED_VALUE
  odds_ratios_xw <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(probabilities, odds_ratios_x, odds_ratios_w, odds_ratios_xw, n, published_power, reference_nrep)
  spec <- mi_validation_spec(probabilities, odds_ratios_x, odds_ratios_w, odds_ratios_xw, n, seed = 3205)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})
