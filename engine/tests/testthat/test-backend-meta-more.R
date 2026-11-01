# A moderator that is a score (meta_analysis / meta_regression) and the
# test of heterogeneity (meta_analysis / heterogeneity), both simulated
# with Spower and metafor (E61).

meta_more_spec <- function(name, ...) {
  spec <- example_spec(name)
  spec$population <- utils::modifyList(spec$population, list(...))
  spec
}

test_that("a score moderator's slope is tested by Hartung-Knapp or z, and the check run recovers the model", {
  result <- suppressWarnings(run_spec(meta_more_spec("meta_regression")))
  expect_identical(result$provenance$backend, "Spower")
  expect_match(result$provenance$backend_function, "test = \"knha\"", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  z <- meta_more_spec("meta_regression")
  z$target_test$test <- "z"
  expect_match(suppressWarnings(run_spec(z))$provenance$backend_function, "test = \"z\"", fixed = TRUE)
})

test_that("the moderator's values are standardised across the studies", {
  x <- meta_moderator_values(23)
  expect_equal(mean(x), 0, tolerance = 1e-12)
  expect_equal(mean(x^2), 1)
})

test_that("the test of heterogeneity is Cochran's Q from the fixed-effect fit", {
  result <- suppressWarnings(run_spec(meta_more_spec("meta_heterogeneity")))
  expect_match(result$provenance$backend_function, "Cochran's Q", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  more <- suppressWarnings(run_spec(meta_more_spec("meta_heterogeneity", i2 = 0.75)))
  expect_gt(more$curve$power, result$curve$power)
})

test_that("both tests are two-sided and simulated, in plain English", {
  one <- meta_more_spec("meta_regression")
  one$target_test$alternative <- "greater"
  expect_spec_problem(one, "two-sided")
  exact <- meta_more_spec("meta_heterogeneity")
  exact$options$method <- "exact"
  expect_spec_problem(exact, "simulated")
})

test_that("the exported scripts reproduce both results with Spower and metafor alone", {
  for (name in c("meta_regression", "meta_heterogeneity")) {
    spec <- meta_more_spec(name)
    expect_script_reproduces_power(spec, suppressWarnings(run_spec(spec)))
  }
})

test_that("Hartung-Knapp power for the moderator's slope: the size of the difference from the z test (Departure 18)", {
  # The same simulated meta-analyses tested both ways (docs/conventions.md,
  # 18): with 10 studies about 18% against 22%.
  spec <- validate_spec(meta_more_spec("meta_regression"))
  model <- meta_study_model(spec)
  both <- with_seed(1, replicate(400, {
    state <- .Random.seed
    hk <- p_meta_reg(10, model$theta, 0.15, model$v, model$tau2, "knha")
    assign(".Random.seed", state, envir = .GlobalEnv)
    z <- p_meta_reg(10, model$theta, 0.15, model$v, model$tau2, "z")
    c(hk < 0.05, z < 0.05)
  }))
  expect_lt(mean(both[1, ]), mean(both[2, ]))
  expect_true(all(both[1, ] <= both[2, ] | !both[1, ]) || mean(both[1, ] & !both[2, ]) < 0.02)
})
