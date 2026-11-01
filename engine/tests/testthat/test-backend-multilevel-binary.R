# A yes/no outcome in the two-level (E62) and three-level (E68) designs:
# logistic mixed models built by simr's makeGlmer(), every effect and SD on
# the log-odds scale, tested by glmer's Wald z test or the likelihood ratio.

two_binary_spec <- function(method = "wald", effect = "cross_level_interaction", goal = list(type = "power", n = 400L), nrep = 100L) {
  spec <- example_spec("mixed_two_level")
  spec$variables$Y <- list(type = "binary", label = "Passed")
  spec$population <- list(metric = "probability", probability = 0.6, b_X = 0.3, b_W = 0.3, b_XW = 0.2,
    sd_group = 0.5, sd_group_slope = 0.2, cluster_size = spec$population$cluster_size)
  spec$target_test$method <- method
  spec$target_test$effect <- effect
  spec$goal <- goal
  spec$options <- list(nrep = nrep, seed = 11L)
  spec
}

three_binary_spec <- function(assignment = "site", method = "wald", ..., goal = list(type = "power", n = 960L), nrep = 100L) {
  spec <- example_spec("mixed_three_level")
  spec$variables$Y <- list(type = "binary", label = "Passed")
  spec$population <- utils::modifyList(list(metric = "probability", probabilities = list(0.5, 0.65), sd_site = 0.4, sd_group = 0.3,
    group_size = spec$population$group_size, groups_per_site = spec$population$groups_per_site, assignment = assignment), list(...))
  spec$target_test$method <- method
  spec$goal <- goal
  spec$options <- list(nrep = nrep, seed = 12L)
  spec
}

test_that("the yes/no two-level model: probability as the intercept's log odds, no residual SD, simr's z or lr test", {
  inputs <- two_level_inputs(validate_spec(two_binary_spec()))
  expect_true(inputs$binary)
  expect_equal(inputs$fixef, c(stats::qlogis(0.6), 0.3, 0.3, 0.2))
  expect_null(inputs$sigma)
  expect_identical(inputs$method, "z")
  expect_identical(two_level_inputs(validate_spec(two_binary_spec("likelihood_ratio")))$method, "lr")
})

test_that("the yes/no three-level model: each condition's log odds, the SDs on the log-odds scale", {
  inputs <- three_level_inputs(validate_spec(three_binary_spec("person", sd_effect_group = 0.2)))
  logits <- stats::qlogis(c(0.5, 0.65))
  expect_equal(inputs$fixef, c(mean(logits), diff(logits)))
  expect_identical(deparse1(inputs$formula), "y ~ cond + (1 | site) + (1 + cond | site:group)")
  expect_equal(inputs$VarCorr$site, 0.4^2)
  expect_equal(diag(inputs$VarCorr$`site:group`), c(0.3^2, 0.2^2))
  expect_null(inputs$sigma)
})

test_that("both designs run on simr with a yes/no outcome, and their check runs recover the population", {
  for (spec in list(two_binary_spec(), three_binary_spec("site"), three_binary_spec("group", "likelihood_ratio", sd_effect_site = 0.2))) {
    result <- suppressWarnings(run_spec(spec))
    expect_identical(result$provenance$backend, "simr")
    expect_true(all(result$check_run$ok), label = spec$template)
    expect_false("residual SD" %in% result$check_run$parameter, label = spec$template)
  }
})

test_that("a yes/no outcome refuses score inputs, and a score outcome yes/no ones, in plain English", {
  two <- two_binary_spec()
  two$population$sd_residual <- 1
  expect_spec_problem(two, "has no residual SD")
  two <- two_binary_spec()
  two$target_test$method <- "satterthwaite_t"
  expect_spec_problem(two, "\"wald\" or \"likelihood_ratio\"")
  three <- three_binary_spec()
  three$population$icc_site <- 0.1
  expect_spec_problem(three, "is for a score outcome")
  expect_spec_problem(three_binary_spec("site", sd_effect_site = 0.2), "remove it when whole sites are assigned")
  score <- example_spec("mixed_three_level")
  score$population$sd_site <- 0.4
  expect_spec_problem(score, "is for a yes/no outcome")
})

test_that("the exported scripts reproduce the yes/no results with simr alone, and the data sets use glmer's model", {
  for (spec in list(two_binary_spec(), three_binary_spec("group"))) {
    expect_script_reproduces_power(spec, suppressWarnings(run_spec(spec)))
    code <- simulated_data_code(validate_spec(spec), spec$goal$n, 1)
    expect_true(any(grepl("makeGlmer", code, fixed = TRUE)), label = spec$template)
  }
})
