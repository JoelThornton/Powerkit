# Moderation of a count outcome (E32): Poisson or negative binomial
# regression with X x W, simulated by Spower.

cint_spec <- function(n = 300, nrep = 100, method = "negative_binomial") {
  spec <- read_spec(system.file("specs", "poisson_interaction.json", package = "powerkit"))
  spec$goal <- list(type = "power", n = n)
  spec$options$nrep <- nrep
  if (identical(method, "wald_z")) {
    spec$target_test$method <- "wald_z"
    spec$population$dispersion <- NULL
  }
  spec
}

test_that("the inputs read the model, with dispersion only for negative binomial counts", {
  inputs <- count_interaction_inputs(validate_quietly(cint_spec()))
  expect_identical(c(inputs$base_rate, inputs$rate_ratio_xw, inputs$dispersion), c(6, 0.85, 0.5))
  expect_true(inputs$x_binary)
  expect_false(inputs$w_binary)
  expect_identical(count_interaction_inputs(validate_quietly(cint_spec(method = "wald_z")))$dispersion, 0)
})

test_that("the direction is spelled as R spells it, and every direction gives a p value", {
  for (alt in c("two_sided", "greater", "less")) {
    spec <- cint_spec()
    spec$target_test$alternative <- alt
    inputs <- count_interaction_inputs(validate_quietly(spec))
    expect_identical(inputs$alternative, c(two_sided = "two.sided", greater = "greater", less = "less")[[alt]])
    set.seed(1)
    p <- do.call(p_count_interaction, c(list(n = 200), inputs))
    expect_true(is.numeric(p) && length(p) == 1 && p >= 0 && p <= 1, label = alt)
  }
})

test_that("the simulated data recover the model", {
  set.seed(5)
  data <- count_interaction_data(60000, 4, 0.8, 1.2, 0.75, 0.5, TRUE, FALSE, 0.5, 0.5, 0)
  expect_identical(sum(data$x), 30000)
  fit <- MASS::glm.nb(y ~ x * w, data = data)
  expect_lt(max(abs(unname(stats::coef(fit)) - log(c(4, 0.8, 1.2, 0.75)))), 0.04)
  expect_equal(1 / fit$theta, 0.5, tolerance = 0.05)
  set.seed(6)
  pois <- count_interaction_data(60000, 2, 1.2, 1.1, 1.15, 0, FALSE, FALSE, 0.5, 0.5, 0.3)
  expect_equal(stats::cor(pois$x, pois$w), 0.3, tolerance = 0.03)
  mu <- 2 * 1.2^pois$x * 1.1^pois$w * 1.15^(pois$x * pois$w)
  expect_equal(mean((pois$y - mu)^2 / mu), 1, tolerance = 0.03) # Poisson: variance equals the mean
})

test_that("a run gives power with a check run that recovers the inputs", {
  for (method in c("negative_binomial", "wald_z")) {
    result <- run_quietly(cint_spec(method = method))
    expect_identical(result$provenance$backend, "Spower")
    expect_true(result$curve$power > 0.1 && result$curve$power <= 1)
    expect_true(all(result$check_run$ok))
  }
})

test_that("an experiment that can't fit counts as not significant", {
  expect_identical(p_count_interaction(40, 0.001, 1, 1, 2, 0, TRUE, TRUE, 0.5, 0.5, 0), 1)
})

test_that("problems are named in plain words", {
  spec <- cint_spec()
  spec$population$dispersion <- NULL
  expect_spec_problem(spec, "Negative binomial regression needs 'population > dispersion'")
  spec <- cint_spec(method = "wald_z")
  spec$population$dispersion <- 0.5
  expect_spec_problem(spec, "'population > dispersion' is only used by the negative binomial models")
  spec <- cint_spec()
  spec$population$x_prob <- 0.5
  spec$variables$X <- list(type = "continuous", label = "Motivation")
  expect_spec_problem(spec, "'population > x_prob' is the proportion in the second group")
  spec <- cint_spec()
  spec$population$r_xw <- 0.2
  expect_spec_problem(spec, "'population > r_xw' (the correlation between X and W) is only used when both are scores")
})

test_that("the simulated-data code draws the same model", {
  spec <- validate_quietly(cint_spec(method = "wald_z"))
  data <- simulated_data(spec, 40000, seed = 3)
  means <- tapply(data$Drinking_days_in_a_month, data$Condition, mean)
  expect_equal(unname(means[["Usual care"]]), 6 * exp(log(1.2)^2 / 2), tolerance = 0.03)
})

test_that("the R script reproduces the run", {
  skip_unless_scripts_can_run()
  spec <- cint_spec(n = 200)
  run <- expect_script_reproduces_power(spec, run_quietly(spec))
  expect_true(any(grepl("glm.nb(", run$script, fixed = TRUE)))
})
