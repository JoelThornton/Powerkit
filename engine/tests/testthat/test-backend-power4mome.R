# Mediation and moderated mediation via power4mome: translation,
# reproducibility and check runs. Simulations are slow (about 0.35 s per
# replication), so only one end-to-end run is made here; accuracy is
# checked by test-validation-mediation-*.R and test-validation-modmed-*.R.

inputs_for <- function(name, ...) {
  power4mome_inputs(validate_quietly(continuous_and_reliable(sim_spec(name, ...))))
}

lines_of <- function(x) strsplit(x, "\n", fixed = TRUE)[[1]]

test_that("PROCESS models are translated to power4mome's model and population values", {
  simple <- inputs_for("mediation_simple")
  expect_equal(lines_of(simple$model), c("M ~ X", "Y ~ X + M"))
  expect_setequal(lines_of(simple$pop_es), c("M ~ X: -0.25", "Y ~ X: 0.1", "Y ~ M: -0.3"))
  expect_equal(simple$test_name, "test_indirect_effect")
  expect_equal(simple$test_args[c("x", "m", "y")], list(x = "X", m = "M", y = "Y"))

  serial <- inputs_for("mediation_serial")
  expect_equal(lines_of(serial$model), c("M1 ~ X", "M2 ~ X + M1", "Y ~ X + M1 + M2"))
  expect_equal(serial$test_args$m, c("M1", "M2"))

  p7 <- inputs_for("process_7")
  expect_equal(lines_of(p7$model), c("M ~ X + W + X:W", "Y ~ X + M"))
  expect_true("M ~ X:W: 0.15" %in% lines_of(p7$pop_es))
  expect_true("X ~~ W: 0" %in% lines_of(p7$pop_es))
  expect_equal(p7$test_name, "test_index_of_mome")

  p14 <- inputs_for("process_14")
  expect_equal(lines_of(p14$model), c("M ~ X", "Y ~ X + M + W + M:W"))
  expect_true("Y ~ M:W: 0.12" %in% lines_of(p14$pop_es))
})

test_that("parallel mediators' residual correlation becomes power4mome's residual covariance", {
  parallel <- inputs_for("mediation_parallel")
  # The fitted model always frees the residual covariance, as PROCESS does.
  expect_true("M1 ~~ M2" %in% lines_of(parallel$model))
  # Residual correlation 0.3; residual variances 1 - 0.4^2 and 1 - 0.3^2.
  expected <- 0.3 * sqrt((1 - 0.4^2) * (1 - 0.3^2))
  value <- as.numeric(sub("M1 ~~ M2: ", "", grep("^M1 ~~ M2:", lines_of(parallel$pop_es), value = TRUE)))
  expect_equal(value, expected)
})

test_that("the CI method and level follow the spec", {
  spec <- continuous_and_reliable(sim_spec("mediation_simple"))
  spec$target_test$method <- "percentile_bootstrap"
  spec$target_test$alpha <- 0.01
  spec$options$ci_draws <- 500
  inputs <- power4mome_inputs(validate_quietly(spec))
  expect_equal(inputs$ci_type, "boot")
  expect_true(inputs$test_args$boot_ci)
  expect_false(inputs$test_args$mc_ci)
  expect_equal(inputs$test_args$level, 0.99)
  expect_equal(inputs$ci_draws, 500)
})

test_that("on one core, a simple mediation run equals a direct power4test call", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  spec <- continuous_and_reliable(sim_spec("mediation_simple", goal = list(type = "power", n = 100)))
  result <- run_quietly(spec)
  expect_equal(result$provenance$backend, "power4mome")
  expect_true(all(result$check_run$ok))
  expect_true(all(c("power4mome", "manymome", "lavaan") %in% names(result$provenance$packages)))
  direct <- power4mome::power4test(
    nrep = 100, model = "M ~ X\nY ~ X + M", pop_es = "M ~ X: -0.25\nY ~ X: 0.1\nY ~ M: -0.3",
    n = 100, R = 100, ci_type = "mc", test_fun = power4mome::test_indirect_effect,
    test_args = list(x = "X", m = "M", y = "Y", mc_ci = TRUE, boot_ci = FALSE, level = 0.95),
    iseed = 7, parallel = FALSE, progress = FALSE
  )
  expect_equal(result$curve$power, power4mome::rejection_rates(direct)$reject[1])
})

test_that("the check run catches a path put in the wrong place", {
  spec <- validate_quietly(continuous_and_reliable(sim_spec("process_7")))
  inputs <- power4mome_inputs(spec)
  expect_true(all(power4mome_check_run(spec, inputs, seed = 1)$ok))
  # X->M and W->M swapped in the population values.
  inputs$pop_es <- sub("M ~ X: 0.2", "M ~ X: 0.1", sub("M ~ W: 0.1", "M ~ W: 0.2", inputs$pop_es, fixed = TRUE), fixed = TRUE)
  check <- power4mome_check_run(spec, inputs, seed = 1)
  expect_setequal(check$parameter[!check$ok], c("X->M", "W->M"))
})

test_that("binary variables and measurement error aren't available yet", {
  spec <- sim_spec("process_7")
  spec$variables$W$reliability <- NULL
  expect_error(run_quietly(spec), "binary.*aren't available yet", class = "powerkit_not_available")
  spec <- continuous_and_reliable(sim_spec("process_7"))
  spec$variables$M$reliability <- 0.8
  expect_error(run_quietly(spec), "measurement error.*aren't available yet", class = "powerkit_not_available")
})
