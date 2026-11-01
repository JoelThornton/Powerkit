# Three levels (mixed_model / three_level, E68): people in groups in sites,
# the condition assigned to sites, groups or people; simr's powerSim() with
# Satterthwaite's t test.

three_spec <- function(assignment = "site", ..., goal = list(type = "power", n = 960L), nrep = 100L) {
  spec <- example_spec("mixed_three_level")
  spec$population$assignment <- assignment
  spec$population <- utils::modifyList(spec$population, list(...))
  spec$goal <- goal
  spec$options <- list(nrep = nrep, seed = 8L)
  spec
}

test_that("the model and design for each assignment", {
  inputs <- three_level_inputs(validate_spec(three_spec("site")))
  expect_identical(deparse1(inputs$formula), "y ~ cond + (1 | site) + (1 | site:group)")
  expect_equal(inputs$sigma, sqrt(1 - 0.1 - 0.05))
  data <- three_level_design(inputs, 960)
  expect_equal(nlevels(data$site), 12)
  expect_equal(as.vector(tapply(data$cond, data$site, function(x) length(unique(x)))), rep(1, 12))
  inputs <- three_level_inputs(validate_spec(three_spec("group", icc_effect_site = 0.02)))
  expect_identical(deparse1(inputs$formula), "y ~ cond + (1 + cond | site) + (1 | site:group)")
  data <- three_level_design(inputs, 960)
  expect_equal(as.vector(tapply(data$cond, interaction(data$site, data$group), function(x) length(unique(x)))), rep(1, 48))
  inputs <- three_level_inputs(validate_spec(three_spec("person", icc_effect_site = 0.02, icc_effect_group = 0.01)))
  expect_identical(deparse1(inputs$formula), "y ~ cond + (1 + cond | site) + (1 + cond | site:group)")
  data <- three_level_design(inputs, 960)
  expect_equal(as.vector(table(data$cond)), c(480, 480))
})

test_that("each assignment runs on simr, and the check run recovers the population", {
  for (spec in list(three_spec("site"), three_spec("group", icc_effect_site = 0.02), three_spec("person", icc_effect_group = 0.02))) {
    result <- suppressWarnings(run_spec(spec))
    expect_identical(result$provenance$backend, "simr")
    expect_true(all(result$check_run$ok), label = spec$population$assignment)
  }
})

test_that("impossible three-level designs are refused in plain English", {
  expect_spec_problem(three_spec(icc_site = 0.6, icc_group = 0.5), "must be below 1")
  expect_spec_problem(three_spec("group", groups_per_site = 3L, goal = list(type = "power", n = 720L)), "must be even")
  expect_spec_problem(three_spec("site", icc_effect_site = 0.02), "remove it when whole sites are assigned")
  expect_spec_problem(three_spec("site", goal = list(type = "power", n = 880L)), "an even number of them")
  zero <- three_spec(d = 0, goal = list(type = "sample_size", power = 0.8))
  expect_error(validate_spec(zero), class = "powerkit_spec_error")
})

test_that("the exported script reproduces the result with simr alone, and the data set has a row per person", {
  spec <- three_spec("group")
  expect_script_reproduces_power(spec, suppressWarnings(run_spec(spec)))
  expect_true(any(grepl("design$group <=", simulated_data_code(validate_spec(spec), 960, 1), fixed = TRUE)))
})

test_that("Satterthwaite's test is never more liberal than simr's z test (Departure 16)", {
  # The same t statistic referred to a t distribution: on the same data
  # sets every rejection by Satterthwaite's test is one by z too
  # (docs/conventions.md, 16, gives the size at 12 and 30 schools).
  inputs <- three_level_inputs(validate_spec(three_spec("site")))
  model <- simr_model(inputs, 960)
  power <- vapply(c("sa", "z"), function(m) {
    r <- suppressMessages(suppressWarnings(simr::powerSim(model, test = simr::fixed("cond", m), nsim = 100, seed = 11, progress = FALSE)))
    r$x / r$n
  }, numeric(1))
  expect_lte(power[["sa"]], power[["z"]])
})
