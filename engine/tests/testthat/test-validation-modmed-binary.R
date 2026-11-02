# Validation: moderated mediation with a yes/no X or W (PROCESS models 7 and
# 14, E17). Backend: power4mome with rbinary_rs(). The questions the
# decision of 1 November 2026 asked (decisions.md) are answered here:
#   - how a yes/no W is standardised in a model with a product term: the
#     independent simulation standardises it by its population mean and SD
#     (as rbinary_rs() is documented to), forms the product from the
#     standardised variables and sets each residual variance so that M and
#     Y have variance 1; power agreeing means power4mome does the same;
#   - the Monte Carlo interval with a yes/no X: the Type I error stays at
#     most alpha with no moderation.
#   1. analytic agreement: the independent simulation, OLS for each
#      equation (PROCESS's way) and its own Monte Carlo interval for the
#      index, without power4mome or manymome
#   2. published examples: a placeholder, for the maintainer
#   3. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

binary_reps <- 500L
binary_draws <- 1000L

binary_modmed_validation_spec <- function(template, paths, x_binary, w_binary, seed, n, nrep = binary_reps) {
  v <- validation_variable
  validation_spec(
    design = "moderated_mediation",
    template = template,
    variables = list(X = if (x_binary) v("binary", "Condition") else v("continuous", "Predictor"),
      W = if (w_binary) v("binary", "Group") else v("continuous", "Moderator"),
      M = v("continuous", "Mediator"), Y = v("continuous", "Outcome")),
    population = c(list(metric = "standardised", paths = paths), if (x_binary) list(x_prob = 0.5), if (w_binary) list(w_prob = 0.4)),
    target_test = list(effect = "index_of_moderated_mediation", method = "monte_carlo_ci", alpha = 0.05),
    seed = seed,
    n = n,
    options = list(ci_draws = binary_draws, nrep = nrep)
  )
}

binary_modmed_by_hand <- function(template, paths, x_binary, w_binary, n, nrep, seed) {
  get <- function(name) as.numeric(paths[[name]] %||% 0)
  draw <- function(k, binary, p) if (binary) (stats::rbinom(k, 1, p) - p) / sqrt(p * (1 - p)) else stats::rnorm(k)
  model14 <- identical(template, "process_14")
  m_part <- function(x, w) get("X->M") * x + (if (!model14) get("W->M") * w + get("XW->M") * x * w else 0)
  y_part <- function(x, w, m) get("X->Y") * x + get("M->Y") * m + (if (model14) get("W->Y") * w + get("MW->Y") * m * w else 0)
  with_seed(seed, {
    big <- 1e6
    x <- draw(big, x_binary, 0.5); w <- draw(big, w_binary, 0.4)
    e_m <- 1 - stats::var(m_part(x, w))
    m <- m_part(x, w) + stats::rnorm(big, 0, sqrt(e_m))
    e_y <- 1 - stats::var(y_part(x, w, m))
    mean(vapply(seq_len(nrep), function(i) {
      d <- data.frame(x = draw(n, x_binary, 0.5), w = draw(n, w_binary, 0.4))
      d$m <- m_part(d$x, d$w) + stats::rnorm(n, 0, sqrt(e_m))
      d$y <- y_part(d$x, d$w, d$m) + stats::rnorm(n, 0, sqrt(e_y))
      fm <- stats::lm(if (model14) m ~ x else m ~ x + w + x:w, data = d)
      fy <- stats::lm(if (model14) y ~ x + m + w + m:w else y ~ x + m, data = d)
      a <- MASS::mvrnorm(binary_draws, stats::coef(fm), stats::vcov(fm))
      b <- MASS::mvrnorm(binary_draws, stats::coef(fy), stats::vcov(fy))
      index <- if (model14) a[, "x"] * b[, "m:w"] else a[, "x:w"] * b[, "m"]
      ci <- stats::quantile(index, c(0.025, 0.975))
      ci[1] > 0 || ci[2] < 0
    }, logical(1)))
  })
}

model_7_paths <- list("X->M" = 0.3, "W->M" = 0.1, "XW->M" = 0.2, "M->Y" = 0.35, "X->Y" = 0.05)
model_14_paths <- list("X->M" = 0.35, "M->Y" = 0.25, "W->Y" = 0.1, "MW->Y" = 0.2, "X->Y" = 0.05)

for (case in list(list("process_7", model_7_paths, TRUE, FALSE), list("process_14", model_14_paths, FALSE, TRUE),
                  list("process_7", model_7_paths, TRUE, TRUE))) {
  test_that(sprintf("%s with a yes/no %s: agrees with an independent simulation (analytic)", case[[1]],
                    paste(c("X", "W")[c(case[[3]], case[[4]])], collapse = " and ")), {
    skip_unless_full_validation()
    skip_if_not_installed("MASS")
    reference <- binary_modmed_by_hand(case[[1]], case[[2]], case[[3]], case[[4]], n = 250, nrep = binary_reps, seed = 1701)
    estimate <- engine_power(binary_modmed_validation_spec(case[[1]], case[[2]], case[[3]], case[[4]], seed = 1702, n = 250))
    expect_power_near(estimate, reference, reference_nrep = binary_reps)
  })
}

test_that("model 7 with a yes/no X: the Monte Carlo interval keeps the Type I error at most alpha", {
  skip_unless_full_validation()
  null <- modifyList(model_7_paths, list("XW->M" = 0))
  estimate <- engine_power(binary_modmed_validation_spec("process_7", null, TRUE, FALSE, seed = 1703, n = 250, nrep = 1000L))
  expect_lte(estimate$power, 0.05 + 3 * sqrt(0.05 * 0.95 / 1000))
})

test_that("a yes/no X or W in moderated mediation: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (a published power analysis of
  # PROCESS model 7 or 14 with a randomised condition as X or a two-group W).
  template <- TODO_PUBLISHED_VALUE
  paths <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(template, paths, n, published_power, reference_nrep)
})
