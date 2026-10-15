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

test_that("mediation designs route to power4mome and pass their check run", {
  spec <- validate_quietly(continuous_and_reliable(sim_spec("mediation_simple")))
  backend <- route_spec(spec, seed = 7)
  expect_equal(backend$name, "power4mome")
  expect_true(all(c("power4mome", "manymome", "lavaan") %in% backend$packages))
  expect_true(all(backend$check_run()$ok))
})

test_that("on one core, simulation equals a direct power4test call", {
  # 10 replications (below the spec's minimum of 100, so the adapter is
  # called directly) with 100 draws each, to keep the test fast.
  spec <- validate_quietly(continuous_and_reliable(sim_spec("mediation_simple")))
  sim <- route_spec(spec, seed = 7)$simulate(100, nrep = 10, seed = 7, cores = 1)
  direct <- power4mome::power4test(
    nrep = 10, model = "M ~ X\nY ~ X + M", pop_es = "M ~ X: -0.25\nY ~ X: 0.1\nY ~ M: -0.3",
    n = 100, R = 100, ci_type = "mc", test_fun = power4mome::test_indirect_effect,
    test_args = list(x = "X", m = "M", y = "Y", mc_ci = TRUE, boot_ci = FALSE, level = 0.95),
    iseed = 7, parallel = FALSE, progress = FALSE
  )
  expect_equal(sim$rejections / sim$nrep, power4mome::rejection_rates(direct)$reject[1])
  expect_equal(sim$nrep, 10)
})

test_that("a batched run gives the same rejections as the same batches run by hand", {
  # power4test() keeps every replication in memory, so large runs are split
  # into batches. A batch size of 4 splits 10 replications into batches of
  # 4, 3 and 3, with seeds 7, 8 and 9.
  local_mocked_bindings(power4mome_batch_size = function(...) 4L)
  spec <- validate_quietly(continuous_and_reliable(sim_spec("mediation_simple")))
  backend <- route_spec(spec, seed = 7)
  expect_equal(backend$batch_size, 4)
  sim <- backend$simulate(100, nrep = 10, seed = 7, cores = 1)
  by_hand <- vapply(1:3, function(i) {
    result <- power4mome::power4test(
      nrep = c(4, 3, 3)[i], model = "M ~ X\nY ~ X + M", pop_es = "M ~ X: -0.25\nY ~ X: 0.1\nY ~ M: -0.3",
      n = 100, R = 100, ci_type = "mc", test_fun = power4mome::test_indirect_effect,
      test_args = list(x = "X", m = "M", y = "Y", mc_ci = TRUE, boot_ci = FALSE, level = 0.95),
      iseed = 6 + i, parallel = FALSE, progress = FALSE
    )
    rates <- power4mome::rejection_rates(result)
    valid <- round(rates$pvalid[1] * c(4, 3, 3)[i])
    c(round(rates$reject[1] * valid), valid)
  }, numeric(2))
  expect_equal(sim$rejections, sum(by_hand[1, ]))
  expect_equal(sim$nrep, sum(by_hand[2, ]))
})

test_that("with as many batches as cores or more, the result doesn't depend on the cores", {
  # 20 replications in batches of at most 4 make 5 batches on 1 core or on
  # 4, with the same seeds, so the results are identical. On Linux and
  # macOS the 4-core run forks (parallel::mclapply()); on Windows it runs
  # the same batches one after another. With fewer batches than cores
  # (10 replications: 3 batches on 1 core, 4 on 4 cores) the batches
  # differ, so cores are recorded in the provenance with the batch size.
  local_mocked_bindings(power4mome_batch_size = function(...) 4L)
  spec <- validate_quietly(continuous_and_reliable(sim_spec("mediation_simple")))
  backend <- route_spec(spec, seed = 7)
  one <- backend$simulate(100, nrep = 20, seed = 7, cores = 1)
  four <- backend$simulate(100, nrep = 20, seed = 7, cores = 4)
  expect_identical(four, one)
  expect_equal(number_of_chunks(10, 1, 4), 3)
  expect_equal(number_of_chunks(10, 4, 4), 4)
})

test_that("power4mome simulations are batched, with the batch size in the adapter", {
  spec <- validate_quietly(continuous_and_reliable(sim_spec("process_7")))
  expect_equal(route_spec(spec, seed = 1)$batch_size, 200)
  # Memory grows with the draws per CI, so batches shrink above 1,000.
  expect_equal(power4mome_batch_size(100), 200)
  expect_equal(power4mome_batch_size(1000), 200)
  expect_equal(power4mome_batch_size(2000), 100)
  expect_equal(power4mome_batch_size(5000), 40)
  expect_equal(power4mome_batch_size(1e6), 10)
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
  error <- expect_error(run_quietly(spec), "binary.*aren't available yet", class = "powerkit_not_available")
  expect_match(conditionMessage(error), "may give an inaccurate power estimate", fixed = TRUE)
  expect_no_match(conditionMessage(error), "treat .* as continuous")
  spec <- continuous_and_reliable(sim_spec("process_7"))
  spec$variables$M$reliability <- 0.8
  expect_error(run_quietly(spec), "measurement error.*aren't available yet", class = "powerkit_not_available")
})

# Departures from PROCESS and power4mome defaults (docs/conventions.md) ----------

test_that("departure: lavaan ML standard errors vs PROCESS's OLS, at N = 50", {
  # powerkit fits the model with lavaan (power4mome's default; its Monte
  # Carlo CIs need a lavaan fit). PROCESS uses OLS. The estimates are the
  # same; ML divides the residual variance by n rather than n - k (k
  # coefficients including the intercept), so ML SEs are OLS SEs times
  # sqrt((n - k) / n): 2.0% smaller for a (k = 2) and 3.0% smaller for b
  # and c' (k = 3) at N = 50.
  inputs <- inputs_for("mediation_simple")
  sim <- power4mome_call(inputs, n = 50, nrep = 1, seed = 1, do_the_test = FALSE)
  data <- as.data.frame(power4mome::pool_sim_data(sim))
  ml <- lavaan::parameterEstimates(lavaan::sem(inputs$model, data = data))
  ml <- ml[ml$op == "~", ]
  ols <- rbind(
    summary(stats::lm(M ~ X, data))$coefficients["X", 1:2],
    summary(stats::lm(Y ~ X + M, data))$coefficients[c("X", "M"), 1:2]
  )
  expect_equal(ml$est, unname(ols[, 1]), tolerance = 1e-6)
  ratio <- ml$se / unname(ols[, 2])
  expect_equal(ratio, sqrt(c(48, 47, 47) / 50), tolerance = 1e-6)
  expect_equal(round(1 - ratio, 3), c(0.020, 0.030, 0.030))
})

test_that("departure: parallel mediators' residuals free to correlate, as in PROCESS", {
  # lavaan (and so power4mome, given a model without 'M1 ~~ M2') fixes the
  # residual covariance at 0. With a residual correlation of 0.4 that
  # understates the SEs of the paths into Y, so it would overstate power.
  spec <- continuous_and_reliable(sim_spec("mediation_parallel"))
  spec$population$residual_correlations <- list("M1<->M2" = 0.4)
  inputs <- power4mome_inputs(validate_quietly(spec))
  sim <- power4mome_call(inputs, n = 200, nrep = 1, seed = 2, do_the_test = FALSE)
  data <- as.data.frame(power4mome::pool_sim_data(sim))
  paths <- function(model) {
    p <- lavaan::parameterEstimates(lavaan::sem(model, data = data))
    p[p$op == "~" & p$lhs == "Y", c("rhs", "est", "se")]
  }
  free <- paths(inputs$model)
  fixed <- paths(sub("\nM1 ~~ M2", "", inputs$model, fixed = TRUE))
  expect_equal(free$est, fixed$est, tolerance = 1e-8)
  ratio <- free$se / fixed$se
  names(ratio) <- free$rhs
  # Fixing the covariance at 0 understates the M1->Y and M2->Y SEs by
  # about 10% here (seeded data, n = 200).
  expect_equal(round(ratio[c("M1", "M2")], 3), c(M1 = 1.111, M2 = 1.111))
})

test_that("departure: Boos-Zhang off makes no difference to power4test()'s rejection rate", {
  # At R = 39 (a value for which power4mome switches Boos and Zhang's
  # p-value rule on), the CI rule powerkit asks for and power4mome's
  # default give the same rejections: at these R the two rules agree, and
  # power4test() does not extrapolate the rate. Seeded, so identical data.
  # (100 replications were checked when this was written; 25 keep the test
  # fast.)
  run <- function(test_method) {
    args <- list(x = "X", m = "M", y = "Y", mc_ci = TRUE)
    args$test_method <- test_method
    result <- power4mome::power4test(
      nrep = 25, model = "M ~ X\nY ~ X + M", pop_es = "M ~ X: 0.3\nY ~ M: 0.3\nY ~ X: 0.1",
      n = 100, R = 39, ci_type = "mc", test_fun = power4mome::test_indirect_effect,
      test_args = args, iseed = 5, parallel = FALSE, progress = FALSE
    )
    power4mome::rejection_rates(result)$reject[1]
  }
  expect_identical(suppressWarnings(run("ci")), suppressWarnings(run(NULL)))
  expect_equal(inputs_for("mediation_simple")$test_args$test_method, "ci")
})

test_that("Monte Carlo draws default to power4mome's own default for mediation power", {
  expect_equal(default_ci_draws(), as.integer(formals(power4mome::q_power_mediation)$R))
  expect_equal(default_ci_draws(), 1000L)
})
