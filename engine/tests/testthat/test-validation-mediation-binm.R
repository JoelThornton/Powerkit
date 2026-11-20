# Validation: mediation with a yes/no mediator (E39; regression-based causal
# mediation analysis, Valeri and VanderWeele 2013).
# Backend: Spower runs the studies; each is analysed by regmedint, whose
# natural indirect effect is tested by its delta-method standard error.
# Build guide section 6:
#   1. analytic agreement: an independent simulation. Each data set is
#      drawn in base R, M fitted by glm() and Y by lm() or glm(), and the
#      natural indirect effect computed from Valeri and VanderWeele's (2013)
#      formulas without an exposure-mediator interaction, written out here,
#      with its delta-method standard error from a numerical gradient and
#      the two models' covariance matrices (the models are fitted
#      separately, so their estimates are uncorrelated).
#   2. published examples: placeholders below, for the maintainer
#   3. Type I error, when X doesn't change M (odds ratio 1) and M's effect
#      on Y is large
# Values transcribed from a published source or G*Power (tests marked
# "(published)" or "(G*Power value)", or a value whose comment cites its
# source) are owned by the maintainer: do not edit them. Other expected
# values were written with the code (CLAUDE.md, Non-negotiables).
# Skipped unless POWERKIT_FULL_VALIDATION=true.

binm_validation_spec <- function(x_binary, y_binary, population, seed, n) {
  validation_spec(
    design = "mediation",
    template = "binary_mediator",
    variables = list(
      X = if (x_binary) validation_variable("binary", "Condition", levels = list("Control", "Treatment")) else
        validation_variable("continuous", "Exposure"),
      M = validation_variable("binary", "Mediator", levels = list("No", "Yes")),
      Y = if (y_binary) validation_variable("binary", "Outcome", levels = list("No", "Yes")) else
        validation_variable("continuous", "Outcome")
    ),
    population = c(list(metric = "odds_ratio"), population),
    target_test = list(effect = "indirect_effect", path = "X->M->Y", method = "delta_method", alpha = 0.05),
    seed = seed,
    n = n
  )
}

# The natural indirect effect of X from 0 to 1, without an interaction
# (Valeri and VanderWeele, 2013): beta are M's logistic coefficients
# (intercept, X), theta2 is M's coefficient in Y's model. For a score Y the
# difference theta2 * (P(M | X = 1) - P(M | X = 0)); for a yes/no Y the log
# odds ratio.
binm_reference_nie <- function(beta, theta2, y_binary) {
  if (!y_binary) return(theta2 * (stats::plogis(beta[1] + beta[2]) - stats::plogis(beta[1])))
  log((1 + exp(beta[1])) * (1 + exp(beta[1] + beta[2] + theta2))) -
    log((1 + exp(beta[1] + beta[2])) * (1 + exp(beta[1] + theta2)))
}

binm_reference_power <- function(x_binary, y_binary, m_baseline, m_or, y_baseline = 0.5, b, direct, n, seed) {
  reps <- validation_nrep()
  rejected <- with_seed(seed, vapply(seq_len(reps), function(i) {
    x <- if (x_binary) rep(0:1, each = n / 2) else stats::rnorm(n)
    m <- stats::rbinom(n, 1, stats::plogis(stats::qlogis(m_baseline) + log(m_or) * x))
    y <- if (y_binary) stats::rbinom(n, 1, stats::plogis(stats::qlogis(y_baseline) + b * m + direct * x)) else
      b * m + direct * x + stats::rnorm(n)
    fm <- suppressWarnings(stats::glm(m ~ x, family = stats::binomial()))
    fy <- suppressWarnings(if (y_binary) stats::glm(y ~ m + x, family = stats::binomial()) else stats::lm(y ~ m + x))
    par <- c(stats::coef(fm), stats::coef(fy)[["m"]])
    if (!all(is.finite(par))) return(FALSE)
    v <- matrix(0, 3, 3)
    v[1:2, 1:2] <- stats::vcov(fm)
    v[3, 3] <- stats::vcov(fy)["m", "m"]
    f <- function(p) binm_reference_nie(p[1:2], p[3], y_binary)
    grad <- vapply(1:3, function(j) {
      h <- 1e-6 * max(1, abs(par[j]))
      up <- par
      down <- par
      up[j] <- up[j] + h
      down[j] <- down[j] - h
      (f(up) - f(down)) / (2 * h)
    }, numeric(1))
    se <- sqrt(drop(t(grad) %*% v %*% grad))
    is.finite(se) && se > 0 && abs(f(par) / se) > stats::qnorm(0.975)
  }, logical(1)))
  list(power = mean(rejected), mcse = sqrt(mean(rejected) * (1 - mean(rejected)) / reps))
}

binm_agrees <- function(estimate, reference) {
  expect_lt(abs(estimate$power - reference$power), 3.29 * sqrt(estimate$mcse^2 + reference$mcse^2))
}

# 1. Independent simulation ----------------------------------------------------------

test_that("mediation with a yes/no mediator: agrees with an independent simulation, X two groups and Y a score (analytic)", {
  skip_unless_full_validation()
  spec <- binm_validation_spec(TRUE, FALSE, list(m_baseline = 0.3, m_odds_ratio = 2, b = 0.4, direct = 0.1), seed = 3901, n = 300)
  reference <- binm_reference_power(TRUE, FALSE, 0.3, 2, b = 0.4, direct = 0.1, n = 300, seed = 3902)
  binm_agrees(engine_power(spec), reference)
})

test_that("mediation with a yes/no mediator: agrees with an independent simulation, X a score and Y a score (analytic)", {
  skip_unless_full_validation()
  spec <- binm_validation_spec(FALSE, FALSE, list(m_baseline = 0.4, m_odds_ratio = 1.6, b = 0.5, direct = 0), seed = 3903, n = 200)
  reference <- binm_reference_power(FALSE, FALSE, 0.4, 1.6, b = 0.5, direct = 0, n = 200, seed = 3904)
  binm_agrees(engine_power(spec), reference)
})

test_that("mediation with a yes/no mediator: agrees with an independent simulation, X two groups and Y yes/no (analytic)", {
  skip_unless_full_validation()
  spec <- binm_validation_spec(TRUE, TRUE, list(m_baseline = 0.3, m_odds_ratio = 2.5, y_baseline = 0.2, b_odds_ratio = 2.5,
    direct_odds_ratio = 1.2), seed = 3905, n = 400)
  reference <- binm_reference_power(TRUE, TRUE, 0.3, 2.5, 0.2, b = log(2.5), direct = log(1.2), n = 400, seed = 3906)
  binm_agrees(engine_power(spec), reference)
})

test_that("mediation with a yes/no mediator: agrees with an independent simulation, X a score and Y yes/no (analytic)", {
  skip_unless_full_validation()
  spec <- binm_validation_spec(FALSE, TRUE, list(m_baseline = 0.5, m_odds_ratio = 1.8, y_baseline = 0.3, b_odds_ratio = 2,
    direct_odds_ratio = 1), seed = 3907, n = 300)
  reference <- binm_reference_power(FALSE, TRUE, 0.5, 1.8, 0.3, b = log(2), direct = 0, n = 300, seed = 3908)
  binm_agrees(engine_power(spec), reference)
})

# 2. Published example ------------------------------------------------------------

test_that("mediation with a yes/no mediator: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE (the maintainer chooses a published power
  #   example for mediation with a binary mediator).
  x_binary <- TODO_PUBLISHED_VALUE
  y_binary <- TODO_PUBLISHED_VALUE
  population <- TODO_PUBLISHED_VALUE # list(m_baseline = , m_odds_ratio = , ...)
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(x_binary, y_binary, population, n, published_power, reference_nrep)
  spec <- binm_validation_spec(x_binary, y_binary, population, seed = 3909, n = n)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Type I error ------------------------------------------------------------------

test_that("mediation with a yes/no mediator: Type I error is at or below alpha when X doesn't change M and M's effect is large", {
  skip_unless_full_validation()
  # With b large the delta-method test of the natural indirect effect
  # behaves like a test of path a alone, so the rejection rate should be
  # near alpha.
  spec <- binm_validation_spec(TRUE, FALSE, list(m_baseline = 0.4, m_odds_ratio = 1, b = 1, direct = 0.2), seed = 3910, n = 400)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
