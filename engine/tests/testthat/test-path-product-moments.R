product_moment_spec <- function(template = "process_58", rho = 0) {
  list(design = "moderated_mediation", template = template,
    variables = list(X = list(type = "continuous"), W = list(type = "continuous"),
      M = list(type = "continuous"), Y = list(type = "continuous")),
    population = list(paths = list("X->M" = 0.3, "W->M" = 0, "XW->M" = 0.5,
      "X->Y" = 0.4, "M->Y" = 0.4, "W->Y" = 0, "MW->Y" = 0.5,
      "XW->Y" = 0.1), correlations = list("X<->W" = rho)))
}

test_that("a mediator in a later product keeps its higher-order moments", {
  spec <- product_moment_spec()
  moments <- implied_r_squared(spec, path_model(spec))
  expect_equal(moments$cov["MW", "MW"], 1.5)
  expect_equal(moments$cov["MW", "X"], 0.5)
  expect_equal(moments$r_squared[["Y"]], 1.111)
  expect_match(check_implied_variances(spec, path_model(spec)), "111.1%", fixed = TRUE)
})

test_that("product moments agree with independently generated populations", {
  set.seed(104)
  n <- 400000L
  z1 <- stats::rnorm(n)
  z2 <- stats::rnorm(n)
  error <- stats::rnorm(n)
  for (rho in c(-0.3, 0, 0.4)) {
    spec <- product_moment_spec("process_59", rho)
    spec$population$paths$`MW->Y` <- 0.15
    x <- z1
    w <- rho * z1 + sqrt(1 - rho^2) * z2
    # Independently expanded Var(aX + dXW), before adding M's error.
    r2_m <- 0.3^2 + 0.5^2 * (1 + rho^2)
    m <- 0.3 * x + 0.5 * x * w + sqrt(1 - r2_m) * error
    y_hat <- 0.4 * x + 0.4 * m + 0.1 * x * w + 0.15 * m * w
    expected <- implied_r_squared(spec, path_model(spec))
    observed <- stats::cov(cbind(X = x, W = w, XW = x * w, M = m, MW = m * w))
    expect_equal(unname(expected$cov[1:5, 1:5]), unname(observed), tolerance = 0.02)
    expect_equal(expected$r_squared[["Y"]], stats::var(y_hat), tolerance = 0.015)
  }
})

test_that("models with a later mediator product bypass incorrect population rescaling", {
  spec <- example_spec("process_58")
  spec$options$nrep <- 1000L
  inputs <- power4mome_inputs(validate_spec(spec))
  expect_false(inputs$standardized)
  expect_match(inputs$model, "M ~~ ", fixed = TRUE)
  expect_match(inputs$model, "Y ~~ ", fixed = TRUE)
  check <- power4mome_check_run(spec, inputs, seed = 11L)
  expect_true(all(check$ok), info = paste(capture.output(print(check)), collapse = "\n"))
})
