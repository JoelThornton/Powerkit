# People nested in groups (mixed_model / two_level, E41): simr's powerSim()
# on y ~ x + w + x:w + (1 + x | group), Satterthwaite's t test of the
# effect chosen.

two_level_spec <- function(effect = "cross_level_interaction", goal = list(type = "power", n = 400L), nrep = 100L) {
  spec <- example_spec("mixed_two_level")
  spec$target_test$effect <- effect
  spec$goal <- goal
  spec$options <- list(nrep = nrep, seed = 7L)
  spec
}

test_that("a two-level design tests each effect with simr, and its check run recovers the population", {
  for (effect in c("within_effect", "between_effect", "cross_level_interaction")) {
    result <- suppressWarnings(run_spec(two_level_spec(effect)))
    term <- c(within_effect = "x", between_effect = "w", cross_level_interaction = "x:w")[[effect]]
    expect_match(result$provenance$backend_function, sprintf("fixed(\"%s\", \"sa\")", term), fixed = TRUE, label = effect)
    expect_true(all(result$check_run$ok), label = effect)
  }
})

test_that("the design centres X within every group and spreads W across the groups", {
  inputs <- two_level_inputs(validate_spec(two_level_spec()))
  data <- two_level_design(inputs, 400)
  expect_equal(nlevels(data$group), 20)
  expect_equal(tapply(data$x, data$group, mean), rep(0, 20), ignore_attr = TRUE, tolerance = 1e-12)
  expect_equal(mean(data$x^2), 1)
  expect_equal(stats::cor(data$x, data$w), 0, tolerance = 1e-12)
  expect_equal(mean(tapply(data$w, data$group, mean)^2), 1)
})

test_that("a two-level design needs whole groups, at least ten of them, and a non-zero effect for a sample size", {
  expect_spec_problem(two_level_spec(goal = list(type = "power", n = 410L)), "a whole number of groups of 20")
  expect_spec_problem(two_level_spec(goal = list(type = "power", n = 180L)), "at least 200")
  zero <- two_level_spec("between_effect", goal = list(type = "sample_size", power = 0.8))
  zero$population$b_W <- 0
  expect_error(validate_spec(zero), class = "powerkit_spec_error")
})

test_that("the exported script reproduces a two-level result with simr alone, and the data set has one row per person", {
  spec <- two_level_spec("within_effect", nrep = 100L)
  expect_script_reproduces_power(spec, suppressWarnings(run_spec(spec)))
  code <- simulated_data_code(validate_spec(spec), 400, 1)
  expect_true(any(grepl("group = design$group", code, fixed = TRUE)))
})

test_that("Satterthwaite's test is never more liberal than simr's z test (Departure 16)", {
  # The same t statistic, referred to a t distribution rather than the
  # normal: on the same data sets every rejection by Satterthwaite's test
  # is also one by z. Ten classes of 20, the group-level effect: 21.6%
  # against 31.4% over 1,000 data sets (docs/conventions.md, 16).
  inputs <- two_level_inputs(validate_spec(two_level_spec("between_effect")))
  model <- simr_model(inputs, 200)
  power <- vapply(c("sa", "z"), function(m) {
    r <- suppressMessages(suppressWarnings(simr::powerSim(model, test = simr::fixed("w", m), nsim = 100, seed = 11,
                                                          progress = FALSE)))
    r$x / r$n
  }, numeric(1))
  expect_lt(power[["sa"]], power[["z"]])
})

# Three levels (1 November 2026): the groups in sites, a predictor Z on
# each site and its interaction with X.
three_level_predictor_spec <- function(effect = "site_interaction", site_slope = 0.1, goal = list(type = "power", n = 1600L), nrep = 100L) {
  spec <- two_level_spec(effect, goal = goal, nrep = nrep)
  spec$variables$Z <- list(type = "continuous", label = "School funding")
  spec$population <- c(spec$population, list(b_Z = 0.3, b_XZ = 0.1, sd_site = 0.3, groups_per_site = 4L))
  if (!is.null(site_slope)) spec$population$sd_site_slope <- site_slope
  spec
}

test_that("three levels with predictors at each level: the model, and W and Z uncorrelated with each other and with X", {
  inputs <- two_level_inputs(validate_spec(three_level_predictor_spec()))
  expect_identical(deparse1(inputs$formula), "y ~ x + w + z + x:w + x:z + (1 + x | site) + (1 + x | site:group)")
  expect_identical(inputs$term, "x:z")
  data <- two_level_design(inputs, 1600)
  expect_equal(nlevels(data$site), 20)
  expect_equal(stats::cor(data$w, data$z), 0, tolerance = 1e-12)
  expect_equal(stats::cor(data$x, data$z), 0, tolerance = 1e-12)
  expect_equal(tapply(data$w, data$site, mean), rep(0, 20), ignore_attr = TRUE, tolerance = 1e-12)
  no_slope <- two_level_inputs(validate_spec(three_level_predictor_spec(site_slope = NULL)))
  expect_identical(deparse1(no_slope$formula), "y ~ x + w + z + x:w + x:z + (1 | site) + (1 + x | site:group)")
})

test_that("three levels with predictors run on simr, and the check run recovers every effect and SD", {
  for (effect in c("site_effect", "site_interaction")) {
    result <- suppressWarnings(run_spec(three_level_predictor_spec(effect)))
    expect_true(all(result$check_run$ok), label = effect)
    expect_true("SD of site X slopes" %in% result$check_run$parameter)
  }
})

test_that("three levels need whole sites, the site's predictor and SDs; site effects need the sites", {
  expect_spec_problem(three_level_predictor_spec(goal = list(type = "power", n = 1620L)), "a whole number of sites of 4 groups of 20")
  missing <- three_level_predictor_spec()
  missing$population$sd_site <- NULL
  expect_spec_problem(missing, "'population > sd_site'")
  two <- two_level_spec("site_effect")
  expect_spec_problem(two, "needs the groups in sites")
  extra <- two_level_spec()
  extra$population$b_Z <- 0.2
  expect_spec_problem(extra, "only apply when the groups are in sites")
})

test_that("the exported script reproduces a three-level result with simr alone, and the data set has the site and its predictor", {
  spec <- three_level_predictor_spec("site_effect")
  expect_script_reproduces_power(spec, suppressWarnings(run_spec(spec)))
  code <- simulated_data_code(validate_spec(spec), 1600, 1)
  expect_true(any(grepl("School_funding = design$z", code, fixed = TRUE)))
})
