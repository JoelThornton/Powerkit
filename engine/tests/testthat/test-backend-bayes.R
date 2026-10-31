# Bayes factor t-tests via bfpwr: one sample, paired, two groups. The
# translation, the no-effect side, refusals and the exported script.
# Accuracy against simulated Bayes factors is checked by
# test-validation-bayes-factor.R.

bayes_spec <- function(template, goal = list(type = "power", n = 100), ...) {
  spec <- example_spec(template)
  spec$target_test$method <- "bayes_factor"
  spec$target_test$alpha <- NULL
  spec$population$score_shape <- NULL
  spec$options <- list(seed = 7)
  spec$goal <- goal
  changes <- list(...)
  for (path in names(changes)) {
    parts <- strsplit(path, ".", fixed = TRUE)[[1]]
    spec[[parts]] <- changes[[path]]
  }
  spec
}

direct_bayes <- function(n, d, type, k = 10, scale = 1 / sqrt(2), dpsd = 0, alternative = "two.sided") {
  bfpwr::powertbf01(
    n = n, k = 1 / k, plocation = 0, pscale = scale, pdf = 1, type = type,
    alternative = alternative, dpm = d, dpsd = dpsd
  )$power
}

test_that("each Bayes factor t-test runs on bfpwr and equals a direct powertbf01() call", {
  one <- run_quietly(bayes_spec("one_sample_t"))
  expect_equal(one$provenance$backend, "bfpwr")
  expect_equal(one$provenance$method, "exact")
  expect_true(all(one$check_run$ok))
  expect_equal(one$curve$power, direct_bayes(100, example_spec("one_sample_t")$population$d, "one.sample"))
  paired <- run_quietly(bayes_spec("paired_t"))
  expect_equal(paired$curve$power, direct_bayes(100, example_spec("paired_t")$population$dz, "paired"))
  # Two groups: n is the total, bfpwr takes the size of each group.
  two <- run_quietly(bayes_spec("independent_t"))
  expect_equal(two$curve$power, direct_bayes(50, 0.4, "two.sample"))
})

test_that("the threshold, the prior's scale, the design prior and the direction reach bfpwr", {
  spec <- bayes_spec(
    "independent_t",
    target_test.evidence_threshold = 6, target_test.prior_scale = 1,
    population.effect_sd = 0.1, target_test.alternative = "greater"
  )
  expect_equal(
    run_quietly(spec)$curve$power,
    direct_bayes(50, 0.4, "two.sample", k = 6, scale = 1, dpsd = 0.1, alternative = "greater")
  )
})

test_that("the sample size search finds the smallest total n, in steps of 2 for two groups", {
  result <- run_quietly(bayes_spec("independent_t", goal = list(type = "sample_size", power = 0.8)))
  n <- result$n_required$n
  expect_equal(n %% 2, 0)
  expect_gte(direct_bayes(n / 2, 0.4, "two.sample"), 0.8)
  expect_lt(direct_bayes(n / 2 - 1, 0.4, "two.sample"), 0.8)
  # bfpwr's own sample size function agrees (per group, rounded up).
  per_group <- bfpwr::ntbf01(k = 1 / 10, power = 0.8, dpm = 0.4, dpsd = 0, type = "two.sample")
  expect_equal(n, 2 * per_group)
})

test_that("the result says what the same sample would show with no effect", {
  result <- run_quietly(bayes_spec("paired_t", goal = list(type = "power", n = 80)))
  b <- result$bayes
  expect_equal(b$evidence_threshold, 10)
  expect_equal(b$prior_scale, 1 / sqrt(2))
  expect_equal(b$effect_sd, 0)
  expect_equal(b$n, 80)
  expect_equal(
    b$evidence_for_null,
    bfpwr::ptbf01(k = 10, n = 80, pscale = 1 / sqrt(2), type = "paired", dpm = 0, dpsd = 0, lower.tail = FALSE)
  )
  expect_equal(
    b$misleading_evidence,
    bfpwr::ptbf01(k = 1 / 10, n = 80, pscale = 1 / sqrt(2), type = "paired", dpm = 0, dpsd = 0)
  )
  # Other tests carry no Bayes factor summary.
  expect_null(run_quietly(example_spec("paired_t"))$bayes)
})

test_that("Bayes factor settings belong to the Bayes factor tests, which have no alpha", {
  spec <- bayes_spec("one_sample_t")
  spec$target_test$alpha <- 0.05
  expect_error(validate_quietly(spec), "alpha")
  spec <- example_spec("one_sample_t")
  spec$target_test$evidence_threshold <- 10
  expect_error(validate_quietly(spec), "evidence_threshold")
  spec <- example_spec("one_sample_t")
  spec$population$effect_sd <- 0.1
  expect_spec_problem(spec, "'population > effect_sd' is only used by the Bayes factor t-tests")
  spec <- bayes_spec("independent_t")
  spec$options$allocation_ratio <- 2
  expect_spec_problem(spec, "equal groups only")
  spec <- bayes_spec("independent_t")
  spec$options$method <- "simulation"
  expect_spec_problem(spec, "'options > method' 'simulation' isn't available for this test")
  spec <- bayes_spec("one_sample_t", goal = list(type = "sensitivity", n = 50, power = 0.8))
  expect_error(run_quietly(spec), "smallest detectable effect")
})

test_that("the exported script reproduces each Bayes factor t-test", {
  skip_unless_scripts_can_run()
  for (template in c("one_sample_t", "paired_t", "independent_t")) {
    spec <- bayes_spec(template, goal = list(type = "power", n = 60))
    run <- expect_script_reproduces_power(spec, run_for_export(spec))
    expect_match(paste(run$script, collapse = "\n"), "powertbf01", fixed = TRUE)
  }
})
