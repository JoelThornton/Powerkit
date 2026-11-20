# Validation: mediation with a mediator in ordered categories (E39; the
# latent-response model, lavaan).
# Backend: Spower runs the studies; each is analysed by lavaan::sem() with
# the mediator (and a yes/no Y) declared ordered, parameterization "theta",
# and the indirect effect a*b tested by lavaan's delta-method standard error.
# Build guide section 6:
#   1. analytic agreement: an independent simulation. Each data set is
#      drawn here in base R from the model written out separately (the
#      mediator's underlying score cut at the normal quantiles of its
#      cumulative category proportions), fitted by lavaan in its default
#      "delta" parameterization (the underlying scores' total variances
#      fixed at 1, so a and b are on other scales than the engine's), and
#      a*b tested by a first-order delta method written out here from the
#      estimates' covariance matrix. The product a*b is the same in both
#      parameterizations, so the two tests should agree to within
#      simulation error.
#   2. published examples: placeholders below, for the maintainer
#   3. Type I error, when X doesn't change the mediator and the mediator's
#      effect on Y is large
# Values transcribed from a published source or G*Power (tests marked
# "(published)" or "(G*Power value)", or a value whose comment cites its
# source) are owned by the maintainer: do not edit them. Other expected
# values were written with the code (CLAUDE.md, Non-negotiables).
# Skipped unless POWERKIT_FULL_VALIDATION=true.

ordm_validation_spec <- function(x_binary, y_binary, population, seed, n) {
  k <- length(population$m_probabilities)
  validation_spec(
    design = "mediation",
    template = "ordinal_mediator",
    variables = list(
      X = if (x_binary) validation_variable("binary", "Condition", levels = list("Control", "Treatment")) else
        validation_variable("continuous", "Exposure"),
      M = validation_variable("categorical", "Mediator", levels = as.list(paste("Level", seq_len(k)))),
      Y = if (y_binary) validation_variable("binary", "Outcome", levels = list("No", "Yes")) else
        validation_variable("continuous", "Outcome")
    ),
    population = c(list(metric = "latent_response"), population),
    target_test = list(effect = "indirect_effect", path = "X->M->Y", method = "delta_method", alpha = 0.05),
    seed = seed,
    n = n
  )
}

ordm_reference_power <- function(x_binary, y_binary, p, a, b, direct, y_baseline = 0.5, n, seed, reps = 4000L) {
  model <- "M ~ a*X\nY ~ b*M + c*X"
  rejected <- with_seed(seed, vapply(seq_len(reps), function(i) {
    x <- if (x_binary) rep(0:1, each = n / 2) else stats::rnorm(n)
    latent <- a * x + stats::rnorm(n)
    cuts <- stats::qnorm(cumsum(p))
    m <- vapply(latent, function(v) sum(v > cuts[-length(cuts)]) + 1L, integer(1))
    y <- b * latent + direct * x + stats::rnorm(n)
    if (y_binary) y <- as.integer(y > stats::qnorm(1 - y_baseline))
    fit <- NULL
    utils::capture.output(fit <- tryCatch(suppressWarnings(lavaan::sem(model, data = data.frame(X = x, M = m, Y = y),
      ordered = c("M", if (y_binary) "Y"))), error = function(e) NULL))
    if (is.null(fit) || !isTRUE(lavaan::lavInspect(fit, "converged"))) return(FALSE)
    est <- lavaan::coef(fit)[c("a", "b")]
    v <- lavaan::vcov(fit)[c("a", "b"), c("a", "b")]
    grad <- c(est[["b"]], est[["a"]])
    se <- sqrt(drop(t(grad) %*% v %*% grad))
    is.finite(se) && se > 0 && abs(est[["a"]] * est[["b"]] / se) > stats::qnorm(0.975)
  }, logical(1)))
  list(power = mean(rejected), mcse = sqrt(mean(rejected) * (1 - mean(rejected)) / reps))
}

ordm_agrees <- function(estimate, reference) {
  expect_lt(abs(estimate$power - reference$power), 3.29 * sqrt(estimate$mcse^2 + reference$mcse^2))
}

# 1. Independent simulation ----------------------------------------------------------

test_that("mediation with a mediator in ordered categories: agrees with an independent simulation, X two groups and Y a score (analytic)", {
  skip_unless_full_validation()
  p <- c(0.3, 0.3, 0.25, 0.15)
  spec <- ordm_validation_spec(TRUE, FALSE, list(m_probabilities = as.list(p), a = 0.4, b = 0.3, direct = 0.1), seed = 3921, n = 200)
  reference <- ordm_reference_power(TRUE, FALSE, p, 0.4, 0.3, 0.1, n = 200, seed = 3922)
  ordm_agrees(engine_power(spec), reference)
})

test_that("mediation with a mediator in ordered categories: agrees with an independent simulation, X a score and Y a score, three skewed categories (analytic)", {
  skip_unless_full_validation()
  p <- c(0.6, 0.3, 0.1)
  spec <- ordm_validation_spec(FALSE, FALSE, list(m_probabilities = as.list(p), a = 0.25, b = 0.3, direct = 0), seed = 3923, n = 250)
  reference <- ordm_reference_power(FALSE, FALSE, p, 0.25, 0.3, 0, n = 250, seed = 3924)
  ordm_agrees(engine_power(spec), reference)
})

test_that("mediation with a mediator in ordered categories: agrees with an independent simulation, X two groups and Y yes/no (analytic)", {
  skip_unless_full_validation()
  p <- c(0.2, 0.3, 0.3, 0.2)
  spec <- ordm_validation_spec(TRUE, TRUE, list(m_probabilities = as.list(p), a = 0.5, b = 0.4, direct = 0.1, y_baseline = 0.3),
    seed = 3925, n = 300)
  reference <- ordm_reference_power(TRUE, TRUE, p, 0.5, 0.4, 0.1, y_baseline = 0.3, n = 300, seed = 3926)
  ordm_agrees(engine_power(spec), reference)
})

# 2. Published example ------------------------------------------------------------

test_that("mediation with a mediator in ordered categories: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE (the maintainer chooses a published power
  #   example for mediation with an ordinal mediator in a latent-response
  #   model).
  x_binary <- TODO_PUBLISHED_VALUE
  y_binary <- TODO_PUBLISHED_VALUE
  population <- TODO_PUBLISHED_VALUE # list(m_probabilities = , a = , b = , ...)
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(x_binary, y_binary, population, n, published_power, reference_nrep)
  spec <- ordm_validation_spec(x_binary, y_binary, population, seed = 3927, n = n)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 3. Type I error ------------------------------------------------------------------

test_that("mediation with a mediator in ordered categories: Type I error is at or below alpha when X doesn't change the mediator and its effect is large", {
  skip_unless_full_validation()
  # With b large the delta-method test of a*b behaves like a test of path
  # a alone, so the rejection rate should be near alpha.
  spec <- ordm_validation_spec(TRUE, FALSE, list(m_probabilities = list(0.3, 0.4, 0.3), a = 0, b = 0.8, direct = 0.2),
    seed = 3928, n = 300)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})
