test_that("corrected count tests select simulation and reject incompatible plans", {
  for (name in c("two_proportions_corrected", "chi_square_independence_corrected")) {
    spec <- example_spec(name)
    expect_valid_spec(spec)
    expect_equal(basic_test_method(spec), "simulation")
    spec$options$method <- "exact"
    expect_spec_problem(spec, "power is simulated")
    spec$options$method <- NULL
    spec$goal <- list(type = "sensitivity", n = 340, power = .8)
    expect_spec_problem(spec, "Continuity-corrected tests")
  }
  spec <- example_spec("chi_square_independence_corrected")
  spec$population <- list(metric = "w", w = .3)
  expect_spec_problem(spec, "four population proportions")
  spec <- example_spec("chi_square_independence")
  spec$target_test$method <- "pearson_chi_square_corrected"
  expect_spec_problem(spec, "2 by 2")
  spec <- example_spec("two_proportions_corrected")
  spec$options$proportions_formula <- "arcsine"
  expect_spec_problem(spec, "uncorrected formula")
})

test_that("corrected two-proportion simulation matches R including direction and allocation", {
  skip_if_not_installed("Spower")
  for (alternative in c("two_sided", "greater", "less")) {
    spec <- example_spec("two_proportions_corrected")
    spec$target_test$alternative <- alternative
    spec$options$allocation_ratio <- 2
    spec$goal$n <- 90
    inputs <- spower_inputs(validate_spec(spec))
    got <- spower_rejections(inputs, 90, 40, 71)
    set.seed(71)
    p <- suppressWarnings(replicate(40, {
      x <- c(sum(rbinom(30, 1, .5)), sum(rbinom(60, 1, .65)))
      stats::prop.test(x, c(30, 60), correct = TRUE,
        alternative = switch(alternative, two_sided = "two.sided", greater = "less", less = "greater"))$p.value
    }))
    expect_equal(got, c(sum(p < .05), 40, 40, 40))
  }
})

test_that("corrected contingency simulation matches R's fixed-total multinomial test", {
  skip_if_not_installed("Spower")
  spec <- example_spec("chi_square_independence_corrected")
  inputs <- spower_inputs(validate_spec(spec))
  got <- spower_rejections(inputs, 90, 40, 72)
  P <- matrix(c(.25, .25, .175, .325), 2, byrow = TRUE)
  set.seed(72)
  p <- suppressWarnings(replicate(40, stats::chisq.test(
    matrix(rmultinom(1, 90, as.vector(P)), 2), correct = TRUE)$p.value))
  expect_equal(got, c(sum(p < .05), 40, 40, 40))
})

test_that("unanalysable corrected studies remain in the denominator and exports reproduce the ledger", {
  skip_if_not_installed("Spower")
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  for (name in c("two_proportions_corrected", "chi_square_independence_corrected")) {
    spec <- example_spec(name)
    spec$goal <- list(type = "power", n = 20)
    spec$options$nrep <- 100
    spec$options$seed <- 9
    if (name == "two_proportions_corrected") {
      spec$population$p1 <- .005; spec$population$p2 <- .02
    } else spec$population$probabilities <- list(list(.98, .005), list(.005, .01))
    result <- run_quietly(spec)
    ledger <- result$provenance$simulations
    expect_equal(ledger$attempted, 100)
    expect_gt(ledger$failed, 0)
    expect_lt(ledger$valid, ledger$attempted)
    lines <- export_script(spec, result)
    env <- new.env(parent = globalenv())
    suppressWarnings(capture.output(eval(parse(text = lines), env)))
    expect_equal(env$reproduced$power, result$curve$power)
    counts <- suppressWarnings(env$run_batch(20, 100, 9))
    expect_equal(counts[3] - counts[4], ledger$failed)
  }
})

test_that("corrected sample-size searches and their standalone replays retain the intended test", {
  skip_if_not_installed("Spower")
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  for (name in c("two_proportions_corrected", "chi_square_independence_corrected")) {
    spec <- example_spec(name)
    spec$goal <- list(type = "sample_size", power = .8)
    spec$options$nrep <- 1000
    if (name == "two_proportions_corrected") {
      spec$population$p1 <- .2; spec$population$p2 <- .8
      spec$options$allocation_ratio <- 2
    } else spec$population$probabilities <- list(list(.4, .1), list(.1, .4))
    result <- run_spec(spec)
    expect_gt(result$n_required$n, 0)
    expect_equal(result$provenance$method, "simulation")
    env <- new.env(parent = globalenv())
    suppressWarnings(capture.output(eval(parse(text = export_script(spec, result)), env)))
    expect_equal(env$reproduced, env$powerkit_result)
  }
})
