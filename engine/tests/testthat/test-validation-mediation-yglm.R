# Validation: mediation with a yes/no or count outcome (E32; regression-based
# causal mediation analysis, Valeri and VanderWeele 2013).
# Backend: Spower runs the studies; each is analysed by regmedint (a linear
# model for the mediator, a logistic, Poisson or negative binomial model for
# the outcome), whose natural indirect effect is tested by its delta-method
# standard error.
# Build guide section 6:
#   1. analytic agreement: an independent simulation. Each data set is
#      drawn in base R, M fitted by lm() and Y by glm() or MASS::glm.nb(),
#      and the natural indirect effect without an exposure-mediator
#      interaction written out from Valeri and VanderWeele (2013): a * b on
#      the log odds-ratio or log rate-ratio scale, with its delta-method
#      standard error sqrt(b^2 var(a) + a^2 var(b)) (the two models are
#      fitted separately, so their estimates are uncorrelated). A
#      normal-approximation power formula isn't used as a reference: at
#      the sample sizes planned, the delta-method statistic's own standard
#      error moves with the estimates, and its power differs from that
#      formula's by several points (with a = 0.25, rate ratio 0.85 and n =
#      300, 0.98 simulated against 0.90 from the formula);
#   2. published examples: placeholders below, for the maintainer
#   3. Type I error, when X doesn't change M and M's effect on Y is large
# Values transcribed from a published source or G*Power (tests marked
# "(published)" or "(G*Power value)", or a value whose comment cites its
# source) are owned by the maintainer: do not edit them. Other expected
# values were written with the code (CLAUDE.md, Non-negotiables).
# Skipped unless POWERKIT_FULL_VALIDATION=true.

yglm_validation_spec <- function(x_binary, outcome, population, seed, n) {
  validation_spec(
    design = "mediation",
    template = "binary_or_count_outcome",
    variables = list(
      X = if (x_binary) validation_variable("binary", "Condition", levels = list("Control", "Treatment")) else
        validation_variable("continuous", "Exposure"),
      M = validation_variable("continuous", "Mediator"),
      Y = if (identical(outcome, "binary")) validation_variable("binary", "Outcome", levels = list("No", "Yes")) else
        validation_variable("count", "Outcome")
    ),
    population = c(
      list(metric = if (identical(outcome, "binary")) "odds_ratio" else "rate_ratio"),
      population,
      if (identical(outcome, "negbin")) list(count_model = "negative_binomial")
    ),
    target_test = list(effect = "indirect_effect", path = "X->M->Y", method = "delta_method", alpha = 0.05),
    seed = seed,
    n = n
  )
}

# The outcome's model for one data set: y0 and b, direct on the link scale.
yglm_reference_y <- function(n, outcome, eta, k) {
  switch(outcome,
    binary = stats::rbinom(n, 1, stats::plogis(eta)),
    poisson = stats::rpois(n, exp(eta)),
    negbin = stats::rnbinom(n, size = 1 / k, mu = exp(eta))
  )
}

yglm_reference_power <- function(x_binary, outcome, a, y0, b, direct, k = 0, n, seed) {
  reps <- validation_nrep()
  rejected <- with_seed(seed, vapply(seq_len(reps), function(i) {
    x <- if (x_binary) rep(0:1, each = n / 2) else stats::rnorm(n)
    m <- a * x + stats::rnorm(n)
    y <- yglm_reference_y(n, outcome, y0 + b * m + direct * x, k)
    fm <- stats::lm(m ~ x)
    fy <- tryCatch(suppressWarnings(switch(outcome,
      binary = stats::glm(y ~ m + x, family = stats::binomial()),
      poisson = stats::glm(y ~ m + x, family = stats::poisson()),
      negbin = MASS::glm.nb(y ~ m + x)
    )), error = function(e) NULL)
    if (is.null(fy)) return(FALSE)
    a_hat <- stats::coef(fm)[["x"]]
    b_hat <- stats::coef(fy)[["m"]]
    se <- sqrt(b_hat^2 * stats::vcov(fm)["x", "x"] + a_hat^2 * stats::vcov(fy)["m", "m"])
    is.finite(se) && se > 0 && abs(a_hat * b_hat / se) > stats::qnorm(0.975)
  }, logical(1)))
  list(power = mean(rejected), mcse = sqrt(mean(rejected) * (1 - mean(rejected)) / reps))
}

yglm_agrees <- function(estimate, reference) {
  expect_lt(abs(estimate$power - reference$power), 3.29 * sqrt(estimate$mcse^2 + reference$mcse^2))
}

# 1. Independent simulation ---------------------------------------------------------

test_that("mediation with a yes/no or count outcome: agrees with an independent simulation, X two groups and Y yes/no (analytic)", {
  skip_unless_full_validation()
  spec <- yglm_validation_spec(TRUE, "binary", list(a = 0.4, y_baseline = 0.3, b_odds_ratio = 1.5, direct_odds_ratio = 1.1),
    seed = 3211, n = 400)
  reference <- yglm_reference_power(TRUE, "binary", 0.4, stats::qlogis(0.3), log(1.5), log(1.1), n = 400, seed = 3212)
  yglm_agrees(engine_power(spec), reference)
})

test_that("mediation with a yes/no or count outcome: agrees with an independent simulation, X a score and Y yes/no (analytic)", {
  skip_unless_full_validation()
  spec <- yglm_validation_spec(FALSE, "binary", list(a = 0.3, y_baseline = 0.2, b_odds_ratio = 1.6), seed = 3213, n = 300)
  reference <- yglm_reference_power(FALSE, "binary", 0.3, stats::qlogis(0.2), log(1.6), 0, n = 300, seed = 3214)
  yglm_agrees(engine_power(spec), reference)
})

test_that("mediation with a yes/no or count outcome: agrees with an independent simulation, X two groups and Y a Poisson count (analytic)", {
  skip_unless_full_validation()
  spec <- yglm_validation_spec(TRUE, "poisson", list(a = 0.3, base_rate = 2, b_rate_ratio = 0.85, direct_rate_ratio = 0.95),
    seed = 3215, n = 200)
  reference <- yglm_reference_power(TRUE, "poisson", 0.3, log(2), log(0.85), log(0.95), n = 200, seed = 3216)
  yglm_agrees(engine_power(spec), reference)
})

test_that("mediation with a yes/no or count outcome: agrees with an independent simulation, X a score and Y a negative binomial count (analytic)", {
  skip_unless_full_validation()
  spec <- yglm_validation_spec(FALSE, "negbin", list(a = 0.3, base_rate = 5, b_rate_ratio = 0.8, dispersion = 0.5),
    seed = 3217, n = 300)
  reference <- yglm_reference_power(FALSE, "negbin", 0.3, log(5), log(0.8), 0, k = 0.5, n = 300, seed = 3218)
  yglm_agrees(engine_power(spec), reference)
})

# 2. Published example ------------------------------------------------------------

test_that("mediation with a yes/no or count outcome: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE (the maintainer chooses a published power
  #   example for mediation with a binary or count outcome).
  x_binary <- TODO_PUBLISHED_VALUE
  outcome <- TODO_PUBLISHED_VALUE # "binary", "poisson" or "negbin"
  population <- TODO_PUBLISHED_VALUE # list(a = , y_baseline = , b_odds_ratio = , ...)
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(x_binary, outcome, population, n, published_power, reference_nrep)
  spec <- yglm_validation_spec(x_binary, outcome, population, seed = 3221, n = n)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Type I error ------------------------------------------------------------------

test_that("mediation with a yes/no or count outcome: Type I error is near alpha when X doesn't change M and M's effect is large", {
  skip_unless_full_validation()
  # With b large and precisely estimated the delta-method test of the
  # natural indirect effect behaves like a test of path a alone, so the
  # rejection rate should be near alpha.
  spec <- yglm_validation_spec(TRUE, "poisson", list(a = 0, base_rate = 3, b_rate_ratio = 1.6, direct_rate_ratio = 1.1),
    seed = 3222, n = 400)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
