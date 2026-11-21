# A predictor measured on each item (mixed_model / item_predictor, E67):
# simr's powerSim() on y ~ x + (1 + x | participant) + (1 | item).

test_that("the model and design: X standardised across the items, every participant responding to every item", {
  inputs <- item_predictor_inputs(validate_spec(item_spec()))
  expect_identical(deparse1(inputs$formula), "y ~ x + (1 + x | participant) + (1 | item)")
  data <- item_predictor_design(inputs, 5)
  expect_equal(nrow(data), 5 * 60)
  x <- tapply(data$x, data$item, unique)
  expect_equal(c(mean(x), mean(x^2)), c(0, 1), tolerance = 1e-12)
})

test_that("a score and a yes/no outcome run on simr, and the check run recovers the population", {
  for (binary in c(FALSE, TRUE)) {
    result <- suppressWarnings(run_spec(item_spec(binary)))
    expect_true(all(result$check_run$ok), label = binary)
    expect_match(result$provenance$backend_function, if (binary) "fixed(\"x\", \"z\")" else "fixed(\"x\", \"sa\")", fixed = TRUE)
  }
})

test_that("item-predictor specs refuse what doesn't fit the outcome, in plain words", {
  spec <- item_spec(binary = TRUE)
  spec$population$sd_residual <- 1
  expect_spec_problem(spec, "no residual SD")
  wrong <- item_spec()
  wrong$target_test$method <- "wald"
  expect_spec_problem(wrong, "\"satterthwaite_t\"")
  zero <- item_spec(goal = list(type = "sample_size", power = 0.8))
  zero$population$slope <- 0
  expect_error(validate_spec(zero), class = "powerkit_spec_error")
})
