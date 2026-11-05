# Dyadic data, the actor-partner interdependence model (dyadic / apim,
# E44): power4mome generates each data set and fits the APIM with lavaan.

apim_spec <- function(effect = "partner", ..., goal = list(type = "power", n = 120L), nrep = 100L) {
  spec <- example_spec("dyadic_apim")
  spec$population <- utils::modifyList(spec$population, list(...))
  spec$target_test$effect <- effect
  spec$goal <- goal
  spec$options <- list(nrep = nrep, seed = 3L)
  spec
}

distinguishable_spec <- function(effect = "partner_21", ...) {
  spec <- apim_spec(effect, ...)
  spec$population <- c(list(metric = "standardised", distinguishable = TRUE, members = list("Woman", "Man"),
    actor_1 = -0.3, actor_2 = -0.25, partner_12 = -0.1, partner_21 = -0.2, r_x = 0.2, r_y = 0.3))
  spec
}

test_that("the population and fitted models: shared effects constrained equal, or one per member", {
  inputs <- apim_inputs(validate_spec(apim_spec()))
  expect_match(inputs$fit_model, "a1 == a2", fixed = TRUE)
  expect_identical(inputs$label, "p21")
  # The residual covariance is r_y times both residual SDs.
  r2 <- 0.3^2 + 0.15^2 + 2 * 0.3 * 0.15 * 0.2
  expect_match(inputs$pop_es, sprintf("Y1 ~~ Y2: %s", format_pop_value(0.3 * (1 - r2))), fixed = TRUE)
  inputs <- apim_inputs(validate_spec(distinguishable_spec("actor_2")))
  expect_false(grepl("==", inputs$fit_model, fixed = TRUE))
  expect_identical(inputs$label, "a2")
})

test_that("both kinds of dyad run on power4mome, and the check run recovers the population", {
  for (spec in list(apim_spec(), distinguishable_spec())) {
    result <- suppressWarnings(run_spec(spec))
    expect_identical(result$provenance$backend, "power4mome")
    expect_true(all(result$check_run$ok))
  }
})

test_that("the test is lavaan's Wald z test of the effect, as power4mome counts it", {
  spec <- validate_spec(apim_spec())
  inputs <- apim_inputs(spec)
  sim <- power4mome_call(inputs, 120, 1, 9, fit_model_args = list(model = inputs$fit_model), do_the_test = FALSE)
  data <- as.data.frame(power4mome::pool_sim_data(sim))
  fit <- lavaan::sem(inputs$fit_model, data = data)
  pe <- lavaan::parameterEstimates(fit)
  p <- pe$pvalue[pe$label == "p21"]
  tested <- power4mome::test_parameters(fit = fit, pars = "p21")
  expect_equal(tested$pvalue[tested$test_label == "p21"], p, tolerance = 1e-6)
})

test_that("inconsistent dyad specs are refused in plain words", {
  spec <- apim_spec()
  spec$population$actor_1 <- 0.2
  expect_spec_problem(spec, "for distinguishable members")
  expect_spec_problem(apim_spec("actor_1"), "should be one of")
  expect_spec_problem(apim_spec(actor = 0.9, partner = 0.6), "impossible together")
  zero <- apim_spec(partner = 0, goal = list(type = "sample_size", power = 0.8))
  expect_error(validate_spec(zero), class = "powerkit_spec_error")
})

test_that("the exported script reproduces the result with power4mome alone, and the data set has a row per dyad", {
  spec <- apim_spec()
  expect_script_reproduces_power(spec, suppressWarnings(run_spec(spec)))
  data <- simulated_data(distinguishable_spec(), 25)
  expect_equal(nrow(data), 25)
  expect_true(all(c("Daily_stress_Woman", "Relationship_satisfaction_Man") %in% names(data)))
})

test_that("several effects tested together: joint power counts the studies in which every one is significant", {
  spec <- apim_spec("actor_and_partner", goal = list(type = "power", n = 80L))
  joint <- suppressWarnings(run_spec(spec))
  expect_match(joint$provenance$backend_function, "pars = \"a1\", \"p21\"", fixed = TRUE)
  # On the same simulated studies (same seed), the joint rate is at most
  # each effect's own power.
  partner <- suppressWarnings(run_spec(apim_spec("partner", goal = list(type = "power", n = 80L))))
  actor <- suppressWarnings(run_spec(apim_spec("actor", goal = list(type = "power", n = 80L))))
  expect_lte(joint$curve$power, min(partner$curve$power, actor$curve$power))
  expect_spec_problem(apim_spec("all_four"), "should be one of")
  zero <- apim_spec("actor_and_partner", partner = 0, goal = list(type = "sample_size", power = 0.8))
  expect_error(validate_spec(zero), class = "powerkit_spec_error")
  expect_script_reproduces_power(spec, joint)
})

# A pair-level moderator W of the actor effects (5 November 2026) ----------

moderated_spec <- function(effect = "actor_and_moderation", ...) {
  spec <- apim_spec(effect)
  spec$variables$W <- list(type = "continuous", label = "Relationship length")
  spec$population <- utils::modifyList(spec$population, list(r_xw = 0.1, w_y = 0.2, moderation = 0.15, ...))
  spec
}

test_that("with W: the products' moments give each Y's residual variance, supplied with power4mome's standardisation off", {
  spec <- validate_spec(moderated_spec())
  inputs <- apim_inputs(spec)
  expect_false(inputs$standardized)
  expect_identical(inputs$label, c("a1", "m1"))
  expect_match(inputs$fit_model, "m1 == m2", fixed = TRUE)
  # R-squared: the linear part through the predictors' correlations, plus
  # the product's variance 1 + r_xw^2.
  s <- matrix(c(1, 0.2, 0.1, 0.2, 1, 0.1, 0.1, 0.1, 1), 3)
  b <- c(-0.3, -0.15, 0.2)
  r2 <- drop(t(b) %*% s %*% b) + 0.15^2 * (1 + 0.1^2)
  expect_equal(apim_r_squared(spec)[["Y1"]], r2)
  expect_match(inputs$model, sprintf("Y1 ~~ %s*Y1", format_pop_value(1 - r2)), fixed = TRUE)
  result <- run_quietly(moderated_spec())
  expect_true(all(result$check_run$ok))
  expect_true(all(c("moderation, member 1 (X1 x W->Y1)", "X1<->W", "variance of W") %in% result$check_run$parameter))
})

test_that("with W: plain-English refusals", {
  spec <- moderated_spec()
  spec$population$moderation <- NULL
  expect_spec_problem(spec, "Give 'population > moderation'")
  spec <- apim_spec()
  spec$population$moderation <- 0.1
  expect_spec_problem(spec, "only with a pair-level moderator")
  spec <- apim_spec("moderation")
  expect_spec_problem(spec, "'target_test > effect' should be one of")
})

test_that("with W: the exported script reproduces the result with power4mome alone", {
  skip_unless_scripts_can_run()
  spec <- moderated_spec("moderation")
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit, tolerance = 1e-8)
})
