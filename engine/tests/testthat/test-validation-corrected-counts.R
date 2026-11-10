# Selected corrected analyses only. Published examples remain to be transcribed.
test_that("corrected count tests match an archived published power reference", {
  skip_unless_full_validation()
  reference <- TODO_PUBLISHED_VALUE
  skip_if_todo(reference)
  expect_power_near(engine_power(reference$spec), reference$power)
})

for (alternative in c("two_sided", "greater", "less")) {
  test_that(paste("corrected proportions match finite enumeration:", alternative), {
    skip_unless_full_validation()
    skip_if_not_installed("Spower")
    spec <- example_spec("two_proportions_corrected")
    spec$options$nrep <- validation_nrep()
    spec$options$seed <- 2026111041
    spec$options$allocation_ratio <- 2
    spec$goal$n <- 180
    spec$target_test$alternative <- alternative
    spec$population$p2 <- if (alternative == "less") .35 else .65
    reference <- corrected_prop_reference(60, 120, .5, spec$population$p2,
      alternative = switch(alternative, two_sided = "two.sided", greater = "less", less = "greater"))
    expect_power_near(engine_power(spec), reference)
  })
}

test_that("corrected proportion null rejection agrees with its finite reference", {
  skip_unless_full_validation()
  skip_if_not_installed("Spower")
  spec <- example_spec("two_proportions_corrected")
  spec$population$p1 <- .5; spec$population$p2 <- .5
  spec$goal$n <- 120
  spec$options$nrep <- validation_nrep()
  spec$options$seed <- 2026111042
  reference <- corrected_prop_reference(60, 60, .5, .5)
  expect_power_near(engine_power(spec), reference)
  # Discreteness/correction can make the test conservative, so do not
  # require exactly .05 under a sparse or discrete null.
  expect_lte(reference, .05)
})

test_that("corrected contingency power agrees with an independent multinomial simulation", {
  skip_unless_full_validation()
  skip_if_not_installed("Spower")
  spec <- example_spec("chi_square_independence_corrected")
  spec$options$nrep <- validation_nrep()
  spec$options$seed <- 2026111043
  set.seed(2026111044)
  P <- matrix(c(.25, .25, .175, .325), 2, byrow = TRUE)
  p <- suppressWarnings(replicate(validation_nrep(), stats::chisq.test(
    matrix(rmultinom(1, 340, as.vector(P)), 2), correct = TRUE)$p.value))
  reference <- mean(is.finite(p) & p < .05)
  expect_power_near(engine_power(spec), reference, reference_nrep = validation_nrep())
})

test_that("corrected contingency null rejection agrees with independent simulation", {
  skip_unless_full_validation()
  skip_if_not_installed("Spower")
  spec <- example_spec("chi_square_independence_corrected")
  spec$population$probabilities <- list(list(.25, .25), list(.25, .25))
  spec$goal$n <- 120
  spec$options$nrep <- validation_nrep()
  spec$options$seed <- 2026111045
  set.seed(2026111046)
  p <- suppressWarnings(replicate(validation_nrep(), stats::chisq.test(
    matrix(rmultinom(1, 120, rep(.25, 4)), 2), correct = TRUE)$p.value))
  reference <- mean(is.finite(p) & p < .05)
  estimate <- engine_power(spec)
  expect_power_near(estimate, reference, reference_nrep = validation_nrep())
  expect_lte(estimate$power, .05 + 3.29 * estimate$mcse)
})
