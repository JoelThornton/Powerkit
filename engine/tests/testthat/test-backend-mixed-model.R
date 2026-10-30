# Participants responding to many items in two conditions (E33): simr's
# powerSim() with lmerTest's Satterthwaite test.

crossed_example <- function(goal = list(type = "power", n = 20), ...) {
  spec <- read_spec(system.file("specs", "crossed_two_condition.json", package = "powerkit"))
  spec$goal <- goal
  spec$options <- utils::modifyList(spec$options, list(...))
  spec
}

test_that("the design reaches simr as the specified model, and the check run recovers it", {
  result <- suppressWarnings(run_spec(crossed_example(nrep = 100)))
  expect_true(all(result$check_run$ok))
  expect_identical(result$provenance$backend, "simr")
  expect_setequal(result$check_run$parameter, c(
    "difference between conditions", "SD of participant intercepts", "SD of participant condition slopes",
    "SD of item intercepts", "residual SD", "correlation of participant intercepts and slopes"
  ))
})

test_that("powerkit's simulation is simr's powerSim() with the Satterthwaite test, replication for replication", {
  spec <- crossed_example(nrep = 100, seed = 11)
  result <- suppressWarnings(run_spec(spec))
  inputs <- simr_inputs(validate_spec(spec))
  direct <- suppressMessages(suppressWarnings(simr::powerSim(
    simr_model(inputs, 20), test = simr::fixed("cond", "sa"), nsim = 100, seed = 11, progress = FALSE
  )))
  expect_equal(result$curve$power, direct$x / direct$n)
})

test_that("items in both conditions take a by-item slope, and the check run recovers it", {
  spec <- crossed_example(nrep = 100)
  spec$population$item_design <- "within"
  spec$population$sd_item_slope <- 15
  inputs <- simr_inputs(validate_spec(spec))
  expect_match(deparse1(inputs$formula), "(1 + cond | item)", fixed = TRUE)
  expect_equal(nrow(simr_design(inputs, 10)), 10 * 40 * 2)
  check <- simr_check_run(validate_spec(spec), inputs, seed = 3)
  expect_true(all(check$ok))
  expect_true("SD of item condition slopes" %in% check$parameter)
})

test_that("impossible designs are refused in plain English", {
  spec <- crossed_example()
  spec$population$items <- 41
  expect_error(validate_spec(spec), "must be even")
  spec <- crossed_example()
  spec$population$sd_item_slope <- 10
  expect_error(validate_spec(spec), "only applies when every item appears in both conditions")
  expect_error(validate_spec(crossed_example(goal = list(type = "power", n = 4))), "at least 6")
})

test_that("the exported script and the simulated data use the same model", {
  result <- suppressWarnings(run_spec(crossed_example(nrep = 100)))
  script <- export_script(crossed_example(nrep = 100), result)
  expect_match(script, "fixed(\"cond\", \"sa\")", fixed = TRUE)
  expect_match(script, "makeLmer(y ~ cond + (1 + cond | participant) + (1 | item)", fixed = TRUE)
  data <- simulated_data(crossed_example(), 30, seed = 1)
  expect_equal(nrow(data), 30 * 40)
  expect_setequal(names(data), c("SIMULATED_NOT_REAL_DATA", "participant", "item", "Word_type", "Response_time_ms"))
})
