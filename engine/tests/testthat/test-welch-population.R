test_that("raw and standardised Welch inputs describe the same fixed population", {
  raw <- welch_spread_spec()
  standardised <- welch_spread_spec(raw = FALSE)
  expect_equal(raw$population$d, 4 / sqrt(125))
  expect_equal(raw$population$sd_ratio, 3)
  expect_equal(pwrss_inputs(raw)$args(120), pwrss_inputs(standardised)$args(120))
  args <- pwrss_inputs(raw)$args(120)
  expect_equal(args$d, 4 / sqrt((39 * 25 + 79 * 225) / 118))
  expect_equal(args$var.ratio, 1 / 9)
  expect_equal(args$n.ratio, 0.5)
  expect_true(all(pwrss_check_run(raw, pwrss_inputs(raw))$ok))
  expect_equal(spower_inputs(raw)$args(120)$sds, c(5, 15) / sqrt(125))
  # Revalidation and allocation changes keep raw means/spreads fixed.
  expect_identical(spec_hash(validate_spec(raw)), spec_hash(raw))
  raw$options$allocation_ratio <- 0.5
  expect_equal(validate_spec(raw)$population$d, standardised$population$d)
})

test_that("unsupported or incomplete spread definitions fail clearly", {
  spec <- welch_spread_spec()
  spec$population$raw$sd2 <- NULL
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
  spec <- welch_spread_spec()
  spec$target_test$method <- "student_t"
  expect_error(validate_spec(spec), "Separate group SDs")
  spec <- welch_spread_spec(raw = FALSE)
  spec$population$metric <- "point_biserial"
  spec$population$r <- 0.2
  expect_error(validate_spec(spec), "Point-biserial")
})

test_that("equal-SD Welch populations preserve the original backend call", {
  spec <- welch_spread_spec(raw = FALSE)
  spec$population$sd_ratio <- 1
  args <- pwrss_inputs(spec)$args(120)
  expect_equal(args$d, spec$population$d)
  expect_equal(args$var.ratio, 1)
  expect_null(spower_inputs(spec)$args(120)$sds)
  spec$target_test$method <- "student_t"
  expect_s3_class(validate_spec(spec), "powerkit_spec")
  spec$population$sd_ratio <- 2
  expect_error(validate_spec(spec), "only used by")
})

test_that("Welch example data recover the group spreads and effect", {
  spec <- welch_spread_spec("simulation")
  inputs <- spower_inputs(spec)
  expect_true(all(spower_check_run(spec, inputs, 120000, 271)$ok))
  data <- simulated_data(spec, n = 12000, seed = 971)
  groups <- split(data[[4]], data[[3]])
  expect_equal(stats::sd(groups[[2]]) / stats::sd(groups[[1]]), 3, tolerance = 0.1)
  expect_match(simulated_data_note(spec), "root-mean-square", fixed = TRUE)
})

test_that("Welch searches keep the same population and whole allocation", {
  spec <- welch_spread_spec()
  spec$goal <- list(type = "sample_size", power = 0.8)
  result <- run_spec(spec)
  n <- result$n_required$n
  expect_equal(n %% 3, 0)
  power_at <- pwrss_backend(spec)$exact_power
  expect_gte(power_at(n), 0.8)
  expect_lt(power_at(n - 3), 0.8)
})

test_that("both Welch reproduction scripts retain unequal spreads", {
  skip_unless_scripts_can_run()
  for (method in c("exact", "simulation")) {
    spec <- welch_spread_spec(method)
    result <- run_spec(spec)
    run <- expect_script_reproduces_power(spec, result)
    expect_match(paste(run$script, collapse = "\n"), "sds <-", fixed = TRUE)
  }
})
