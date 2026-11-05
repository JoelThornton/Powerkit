# Validation: multinomial logistic regression of an outcome in three or
# more unordered categories on one predictor.
# Backend: Spower simulation of powerkit's experiment p_multinomial(),
# which fits nnet's multinom().
#   1. a yes/no predictor and no other predictors: the likelihood-ratio
#      test of the predictor is then the likelihood-ratio (G) test of
#      independence in the 2 x K table, which an independent simulation
#      computes from counts drawn with stats::rmultinom(), without powerkit's
#      code or nnet
#   2. a score predictor: an independent simulation that draws each
#      category by the Gumbel-maximum rule and fits the same model as a
#      Poisson log-linear model in stats::glm() (one term per person; the
#      multinomial-Poisson equivalence), testing the predictor by the change
#      in deviance; and the Wald z test of one category against the
#      reference, from glm()'s standard error
#   3. a yes/no predictor: the power of the Pearson chi-square test of the
#      same table by pwr's formula (pwr.chisq.test()), a large-sample
#      approximation of the same test
#   4. Type I error with a score predictor and another predictor
#   5. published example: placeholder, for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

mn_validation_spec <- function(probabilities, second, n, binary = FALSE, x_prob = 0.5, r2 = 0, method = "likelihood_ratio", category = NULL) {
  levels <- as.list(paste("Category", seq_along(probabilities)))
  validation_spec(
    design = "logistic_regression",
    template = "multinomial",
    variables = list(
      X = if (binary) validation_variable("binary", "Group", levels = list("Control", "Treatment")) else validation_variable("continuous", "Score"),
      Y = validation_variable("categorical", "Choice", levels = levels)
    ),
    population = c(list(metric = "proportion", probabilities = as.list(probabilities), probabilities_second = as.list(second)),
      if (binary) list(x_prob = x_prob), if (r2 > 0) list(r2_other_predictors = r2)),
    target_test = c(list(effect = "odds_ratios", method = method, alpha = 0.05), if (!is.null(category)) list(category = category)),
    seed = 7001,
    n = n
  )
}

# The G test of a 2 x K table drawn group by group with stats::rmultinom().
mn_table_by_hand <- function(probabilities, second, n, x_prob, nrep, seed) {
  n2 <- round(n * x_prob)
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    observed <- rbind(stats::rmultinom(1, n - n2, probabilities)[, 1], stats::rmultinom(1, n2, second)[, 1])
    if (any(colSums(observed) == 0)) {
      return(FALSE)
    }
    expected <- outer(rowSums(observed), colSums(observed)) / n
    g <- 2 * sum(ifelse(observed > 0, observed * log(observed / expected), 0))
    stats::pchisq(g, df = length(probabilities) - 1, lower.tail = FALSE) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

# A score predictor: the categories by the Gumbel-maximum rule (the
# category with the largest linear predictor plus a standard Gumbel draw
# has the multinomial logit's probabilities), fitted as a Poisson
# log-linear model with a term per person.
mn_score_by_hand <- function(probabilities, second, n, nrep, seed, wald_category = NULL) {
  k <- length(probabilities)
  intercepts <- c(0, log(probabilities[-1] / probabilities[1]))
  slopes <- c(0, log(second[-1] / second[1])) - intercepts
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    x <- stats::rnorm(n)
    gumbel <- matrix(-log(-log(stats::runif(n * k))), n, k)
    eta <- outer(rep(1, n), intercepts) + outer(x, slopes) + gumbel
    y <- max.col(eta, ties.method = "first")
    if (length(unique(y)) < k) {
      return(FALSE)
    }
    long <- data.frame(person = factor(rep(seq_len(n), each = k)), category = factor(rep(seq_len(k), n)),
      count = as.numeric(rep(y, each = k) == rep(seq_len(k), n)))
    # x's slope for each category against the first, as its own column.
    slopes_of <- paste0("x", 2:k)
    for (j in 2:k) long[[slopes_of[j - 1]]] <- rep(x, each = k) * (as.integer(long$category) == j)
    full <- stats::glm(stats::reformulate(c("person", "category", slopes_of), "count"), family = stats::poisson(), data = long)
    if (!is.null(wald_category)) {
      return(stats::coef(summary(full))[sprintf("x%d", wald_category), "Pr(>|z|)"] < 0.05)
    }
    reduced <- stats::glm(count ~ person + category, family = stats::poisson(), data = long)
    stats::pchisq(stats::deviance(reduced) - stats::deviance(full), df = k - 1, lower.tail = FALSE) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("multinomial: with a yes/no predictor, powerkit agrees with the G test of the table (simulation)", {
  skip_unless_full_validation()
  cases <- list(
    list(p = c(0.5, 0.3, 0.2), q = c(0.4, 0.3, 0.3), n = 300, x_prob = 0.5),
    list(p = c(0.25, 0.25, 0.25, 0.25), q = c(0.15, 0.25, 0.3, 0.3), n = 250, x_prob = 0.4)
  )
  for (case in cases) {
    spec <- mn_validation_spec(case$p, case$q, case$n, binary = TRUE, x_prob = case$x_prob)
    reference <- mn_table_by_hand(case$p, case$q, case$n, case$x_prob, 10000L, 71)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  }
})

test_that("multinomial: with a score predictor, powerkit agrees with a Poisson log-linear fit (simulation)", {
  skip_unless_full_validation()
  p <- c(0.5, 0.3, 0.2)
  q <- c(0.42, 0.38, 0.2)
  spec <- mn_validation_spec(p, q, 250)
  expect_power_agrees_within(engine_power(spec), mn_score_by_hand(p, q, 250, 2000L, 72), allowance = 0)
  spec <- mn_validation_spec(p, q, 250, method = "wald_z", category = "Category 2")
  expect_power_agrees_within(engine_power(spec), mn_score_by_hand(p, q, 250, 2000L, 73, wald_category = 2), allowance = 0)
})

test_that("multinomial: with a yes/no predictor, close to the chi-square test's power by pwr's formula", {
  skip_unless_full_validation()
  # The likelihood-ratio and Pearson chi-square tests of the same 2 x K
  # table share their large-sample distribution; pwr's formula is that
  # approximation. Allow 0.02 besides the Monte Carlo error, as for the
  # other comparisons with large-sample formulas.
  p <- c(0.5, 0.3, 0.2)
  q <- c(0.4, 0.3, 0.3)
  cells <- rbind(p, q) / 2
  expected <- outer(rowSums(cells), colSums(cells))
  w <- sqrt(sum((cells - expected)^2 / expected))
  formula <- pwr::pwr.chisq.test(w = w, N = 400, df = 2, sig.level = 0.05)$power
  spec <- mn_validation_spec(p, q, 400, binary = TRUE)
  expect_power_agrees_within(engine_power(spec), exact_estimate(formula), allowance = 0.02)
})

test_that("multinomial: Type I error with a score predictor and another predictor (simulation)", {
  skip_unless_full_validation()
  spec <- mn_validation_spec(c(0.5, 0.3, 0.2), c(0.5, 0.3, 0.2), 300, r2 = 0.3)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("multinomial: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power or sample-size example for
  # multinomial logistic regression with one predictor; source, section,
  # page).
  probabilities <- TODO_PUBLISHED_VALUE
  probabilities_second <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(probabilities, probabilities_second, n, published_power)
  spec <- mn_validation_spec(probabilities, probabilities_second, n)
  expect_power_near(engine_power(spec), exact_estimate(published_power))
})
