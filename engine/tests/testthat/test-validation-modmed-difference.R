# Validation: moderated mediation with W on both links or the direct path
# (PROCESS models 8, 58 and 59, E38): the difference between the
# conditional indirect effects at W = 1 and W = -1. Backend: power4mome,
# with powerkit's test_cond_indirect_diff() (manymome's
# cond_indirect_diff()).
#   1. analytic agreement: an independent simulation. X and W are drawn
#      as correlated standard normals, M and Y from the standardised paths,
#      each residual variance set so that M and Y have variance 1 (worked
#      out from a million draws of the systematic part). Each data set is
#      fitted by OLS, one equation at a time (PROCESS's way, each model
#      with its own terms), and the
#      difference gets its own Monte Carlo interval: the coefficients drawn
#      from each equation's estimated sampling distribution, independently,
#      without power4mome or manymome
#   2. published examples: a placeholder, for the maintainer
#   3. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

difference_reps <- 500L
difference_draws <- 1000L

difference_spec <- function(template, paths, seed, n, nrep = difference_reps) {
  v <- validation_variable
  validation_spec(
    design = "moderated_mediation",
    template = template,
    variables = list(X = v("continuous", "Predictor"), W = v("continuous", "Moderator"),
      M = v("continuous", "Mediator"), Y = v("continuous", "Outcome")),
    population = list(metric = "standardised", paths = paths),
    target_test = list(effect = "conditional_indirect_difference", method = "monte_carlo_ci", w_values = list(-1, 1), alpha = 0.05),
    seed = seed,
    n = n,
    options = list(ci_draws = difference_draws, nrep = nrep)
  )
}

difference_by_hand <- function(paths, n, nrep, seed) {
  get <- function(name) as.numeric(paths[[name]] %||% 0)
  with_seed(seed, {
    big <- 1e6
    x <- stats::rnorm(big); w <- stats::rnorm(big)
    m_sys <- get("X->M") * x + get("W->M") * w + get("XW->M") * x * w
    e_m <- 1 - stats::var(m_sys)
    m <- m_sys + stats::rnorm(big, 0, sqrt(e_m))
    y_sys <- get("X->Y") * x + get("M->Y") * m + get("W->Y") * w + get("XW->Y") * x * w + get("MW->Y") * m * w
    e_y <- 1 - stats::var(y_sys)
    # Each model's own Y equation: W on the direct path (models 8 and 59)
    # and on M -> Y (models 58 and 59) only where the model has them.
    has_mw <- !is.null(paths[["MW->Y"]])
    y_terms <- c("x", "m", "w", if (!is.null(paths[["XW->Y"]])) "x:w", if (has_mw) "m:w")
    y_formula <- stats::reformulate(y_terms, response = "y")
    mean(vapply(seq_len(nrep), function(i) {
      d <- data.frame(x = stats::rnorm(n), w = stats::rnorm(n))
      d$m <- get("X->M") * d$x + get("W->M") * d$w + get("XW->M") * d$x * d$w + stats::rnorm(n, 0, sqrt(e_m))
      d$y <- get("X->Y") * d$x + get("M->Y") * d$m + get("W->Y") * d$w + get("XW->Y") * d$x * d$w +
        get("MW->Y") * d$m * d$w + stats::rnorm(n, 0, sqrt(e_y))
      fm <- stats::lm(m ~ x + w + x:w, data = d)
      fy <- stats::lm(y_formula, data = d)
      a <- MASS::mvrnorm(difference_draws, stats::coef(fm), stats::vcov(fm))
      b <- MASS::mvrnorm(difference_draws, stats::coef(fy), stats::vcov(fy))
      b_mw <- if (has_mw) b[, "m:w"] else 0
      indirect <- function(wv) (a[, "x"] + a[, "x:w"] * wv) * (b[, "m"] + b_mw * wv)
      ci <- stats::quantile(indirect(1) - indirect(-1), c(0.025, 0.975))
      ci[1] > 0 || ci[2] < 0
    }, logical(1)))
  })
}

model_58 <- list("X->M" = 0.3, "W->M" = 0.1, "XW->M" = 0.15, "M->Y" = 0.3, "X->Y" = 0.1, "W->Y" = 0.1, "MW->Y" = 0.1)
model_8 <- list("X->M" = 0.3, "W->M" = 0.1, "XW->M" = 0.15, "M->Y" = 0.3, "X->Y" = 0.1, "W->Y" = 0.1, "XW->Y" = 0.1)

for (case in list(list("process_58", model_58), list("process_8", model_8))) {
  test_that(sprintf("%s, the difference between conditional indirect effects: agrees with an independent simulation (analytic)", case[[1]]), {
    skip_unless_full_validation()
    skip_if_not_installed("MASS")
    reference <- difference_by_hand(case[[2]], n = 250, nrep = difference_reps, seed = 3801)
    estimate <- engine_power(difference_spec(case[[1]], case[[2]], seed = 3802, n = 250))
    expect_power_near(estimate, reference, reference_nrep = difference_reps)
  })
}

test_that("model 58: Type I error at most alpha when W changes neither link", {
  skip_unless_full_validation()
  null <- modifyList(model_58, list("XW->M" = 0, "MW->Y" = 0))
  estimate <- engine_power(difference_spec("process_58", null, seed = 3803, n = 250, nrep = 1000L))
  # A Monte Carlo interval for a product of coefficients is conservative
  # when they are 0, as for the index of moderated mediation.
  expect_lte(estimate$power, 0.05 + 3 * sqrt(0.05 * 0.95 / 1000))
})

test_that("models 8, 58 and 59: match a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (a published power analysis of a
  # moderated mediation model with W on both links, PROCESS model 58).
  template <- TODO_PUBLISHED_VALUE
  paths <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(template, paths, n, published_power, reference_nrep)
  expect_power_near(engine_power(difference_spec(template, paths, seed = 3804, n = n)), published_power, reference_nrep = reference_nrep)
})
