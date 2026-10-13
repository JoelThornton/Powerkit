# Basic tests via Spower: translation, reproducibility and check runs.
# Few replications; accuracy is checked by test-validation-basic-tests.R.

basic_templates <- c(
  "one_sample_t", "independent_t", "paired_t", "correlation",
  "two_proportions", "chi_square_independence"
)

test_that("every basic test runs on Spower and passes its check run", {
  for (template in basic_templates) {
    spec <- sim_spec(template, goal = list(type = "power", n = 120))
    result <- run_quietly(spec)
    expect_s3_class(result, "powerkit_result")
    expect_true(all(result$check_run$ok), label = template)
    expect_equal(result$provenance$backend, "Spower")
    expect_equal(result$provenance$method, "simulation")
    expect_equal(result$provenance$nrep, 100)
    expect_true(all(c("Spower", "SimDesign", "powerkit") %in% names(result$provenance$packages)))
    expect_equal(nrow(result$curve), 1)
  }
})

test_that("on one core, a two-sided run equals a direct Spower call", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  spec <- sim_spec("independent_t", nrep = 200, goal = list(type = "power", n = 100))
  result <- run_quietly(spec)
  expect_equal(result$provenance$backend_function, "Spower::Spower(Spower::p_t.test())")
  # The spec's d is group 2 minus group 1; Spower puts d in group 1.
  set.seed(7)
  direct <- Spower::Spower(
    Spower::p_t.test(n = 50, d = -0.4, type = "two.sample", n2_n1 = 1, var.equal = TRUE),
    replications = 200, verbose = FALSE
  )
  expect_equal(result$curve$power, direct$power)
})

test_that("runs are reproducible for a given seed", {
  spec <- sim_spec("correlation", goal = list(type = "power", n = 80))
  expect_identical(run_quietly(spec)$curve, run_quietly(spec)$curve)
})

test_that("specs are translated to Spower's parametrisation", {
  args <- function(template, ...) {
    spec <- validate_quietly(sim_spec(template, ...))
    spower_inputs(spec)$args(spec$goal$n %||% 120)
  }
  # Paired: Spower draws two independent time points with SD 1, so its d is
  # sqrt(2) * dz, with the sign reversed (Spower's d is in the first).
  paired <- args("paired_t", goal = list(type = "power", n = 40))
  expect_equal(paired$d, -sqrt(2) * 0.35)
  expect_equal(paired$type, "paired")
  # Unequal groups: n is group 1's size and n2_n1 the ratio.
  spec <- sim_spec("independent_t", goal = list(type = "power", n = 150))
  spec$options$allocation_ratio <- 2
  spec$target_test$method <- "welch_t"
  unequal <- spower_inputs(validate_quietly(spec))$args(150)
  expect_equal(unequal[c("n", "n2_n1", "var.equal")], list(n = 50, n2_n1 = 2, var.equal = FALSE))
  # Proportions and chi-square: no continuity correction.
  expect_false(args("two_proportions", goal = list(type = "power", n = 300))$correct)
  chisq <- args("chi_square_independence", goal = list(type = "power", n = 200))
  expect_false(chisq$correct)
  expect_equal(dim(chisq$P), c(3, 2))
})

test_that("unequal groups need a total n that splits in the allocation ratio", {
  spec <- sim_spec("two_proportions", goal = list(type = "power", n = 300))
  spec$options$allocation_ratio <- 2
  backend <- spower_backend(validate_quietly(spec))
  expect_equal(backend$n_step, 3)
  result <- run_quietly(spec)
  expect_equal(result$check_run$recovered[result$check_run$parameter == "group size ratio (group 2 / group 1)"], 2)
})

test_that("one-sided tests use the direction of the spec's effect", {
  p_value <- function(template, alternative, ...) {
    set.seed(1)
    spower_one_sided_p(template, alternative, ...)
  }
  # A large positive effect: tiny p for "greater", p near 1 for "less".
  expect_lt(p_value("independent_t", "greater", "gen_t.test", n = 200, d = -1, type = "two.sample", n2_n1 = 1, var.equal = TRUE), 1e-6)
  expect_gt(p_value("independent_t", "less", "gen_t.test", n = 200, d = -1, type = "two.sample", n2_n1 = 1, var.equal = TRUE), 1 - 1e-6)
  expect_lt(p_value("paired_t", "greater", "gen_t.test", n = 200, d = -sqrt(2), type = "paired"), 1e-6)
  expect_lt(p_value("correlation", "greater", "gen_r", n = 200, r = 0.6), 1e-6)
  expect_lt(p_value("two_proportions", "greater", "gen_prop.test", n = 500, prop = c(0.2, 0.6), n.ratios = c(1, 1)), 1e-6)
  expect_lt(p_value("one_sample_t", "greater", "gen_t.test", n = 200, d = 1, type = "one.sample"), 1e-6)
})

test_that("a one-sided run records its stats test", {
  spec <- sim_spec("correlation", goal = list(type = "power", n = 80))
  spec$target_test$alternative <- "less"
  result <- run_quietly(spec)
  expect_match(result$provenance$backend_function, "stats::cor.test(alternative = \"less\")", fixed = TRUE)
  # The example's r is negative, so a test for "less" has more power than a
  # two-sided one.
  two_sided <- run_quietly(sim_spec("correlation", goal = list(type = "power", n = 80)))
  expect_gt(result$curve$power, two_sided$curve$power)
})

test_that("the check run catches a translation error", {
  spec <- validate_quietly(sim_spec("independent_t", goal = list(type = "power", n = 100)))
  inputs <- spower_inputs(spec)
  right <- spower_check_run(spec, inputs, 100000, seed = 1)
  expect_true(all(right$ok))
  # d passed without reversing its sign.
  args <- inputs$args
  inputs$args <- function(n) utils::modifyList(args(n), list(d = 0.4))
  wrong <- spower_check_run(spec, inputs, 100000, seed = 1)
  expect_false(all(wrong$ok))
})

test_that("a sample-size search brackets n by coarse simulation", {
  spec <- sim_spec("one_sample_t", nrep = 400, goal = list(type = "sample_size", power = 0.8))
  result <- run_quietly(spec)
  est <- result$n_required
  expect_true(est$lower <= est$n && est$n <= est$upper)
  # Exact power for a one-sample t-test (stats::power.t.test) is 0.8 at
  # about n = 89 for d = 0.3.
  expect_true(est$lower <= 89 && 89 <= est$upper)
  expect_true(nrow(result$curve) >= 5)
})
