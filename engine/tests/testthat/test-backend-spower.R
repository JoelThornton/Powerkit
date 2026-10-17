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
  # Spower's two-sample, paired and two-proportion tests compare the first
  # group with the second, and powerkit passes the effect with its sign
  # reversed, so the spec's "greater" is Spower's "less" for those.
  expect_equal(spower_alternative("independent_t", "greater"), "less")
  expect_equal(spower_alternative("paired_t", "less"), "greater")
  expect_equal(spower_alternative("two_proportions", "greater"), "less")
  expect_equal(spower_alternative("one_sample_t", "greater"), "greater")
  expect_equal(spower_alternative("correlation", "less"), "less")
  expect_equal(spower_alternative("independent_t", "two_sided"), "two.sided")
  # A large positive effect in the spec's own terms: almost every data set
  # rejects for "greater", almost none for "less".
  rate <- function(template, alternative, population) {
    spec <- sim_spec(template, goal = list(type = "power", n = 200))
    spec$population <- utils::modifyList(spec$population, population)
    spec$target_test$alternative <- alternative
    inputs <- spower_inputs(validate_quietly(spec))
    spower_rejections(inputs, 200, 200, seed = 1) / 200
  }
  for (case in list(
    list("independent_t", list(d = 0.8)),
    list("paired_t", list(dz = 0.6)),
    list("correlation", list(r = 0.5)),
    list("two_proportions", list(p1 = 0.3, p2 = 0.7)),
    list("one_sample_t", list(d = 0.6))
  )) {
    expect_gt(rate(case[[1]], "greater", case[[2]]), 0.95)
    expect_lt(rate(case[[1]], "less", case[[2]]), 0.01)
  }
})

test_that("a one-sided run records Spower's alternative", {
  spec <- sim_spec("correlation", goal = list(type = "power", n = 80))
  spec$target_test$alternative <- "less"
  result <- run_quietly(spec)
  expect_match(result$provenance$backend_function, "Spower::p_r(alternative = \"less\")", fixed = TRUE)
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

# Departures from Spower's defaults (docs/conventions.md) ------------------------

test_that("one-sided tests: powerkit and Spower's own one-sided test agree", {
  # Spower 0.7 and later test one side with `alternative`; powerkit calls
  # Spower's own functions (Departure 4, retired 17 October 2026). The same
  # seed gives the same data sets, so the results are identical.
  independent <- function(d, alternative) {
    spec <- sim_spec("independent_t", goal = list(type = "power", n = 100))
    spec$population$d <- d
    spec$target_test$alternative <- alternative
    spower_inputs(validate_quietly(spec))
  }
  direct <- function(d_spower, ...) {
    set.seed(4)
    Spower::Spower(
      Spower::p_t.test(n = 50, d = d_spower, ...),
      replications = 2000, parallel = FALSE, verbose = FALSE
    )$power
  }
  # No effect: both reject about alpha (Spower 0.6.4's halved p-value
  # rejected about twice alpha).
  powerkit_null <- spower_rejections(independent(0, "greater"), 100, 2000, seed = 4) / 2000
  expect_equal(powerkit_null, direct(0, alternative = "less"))
  expect_equal(direct(0, two.tailed = FALSE), direct(0, alternative = "greater"))
  expect_lt(abs(powerkit_null - 0.05), 0.015)
  # An effect in the tested direction: identical to Spower's own call.
  powerkit_right <- spower_rejections(independent(0.5, "greater"), 100, 2000, seed = 4) / 2000
  expect_equal(powerkit_right, direct(-0.5, alternative = "less"))
  expect_gt(powerkit_right, 0.75)
  # The wrong direction: the true effect is negative (group 2 lower) but the
  # test expects it to be positive. Neither powerkit nor Spower's own
  # one-sided test (two.tailed = FALSE, effect in Spower's orientation)
  # counts it as significant.
  powerkit_wrong <- spower_rejections(independent(-0.5, "greater"), 100, 2000, seed = 4) / 2000
  spower_wrong <- direct(-0.5, two.tailed = FALSE)
  expect_lt(powerkit_wrong, 0.001)
  expect_lt(spower_wrong, 0.001)
})

test_that("departure: no continuity correction, unlike Spower's default (correct = TRUE)", {
  # Same seed, so the same simulated data: the difference is the correction
  # alone. Yates' correction lowers power by about .03 here.
  # Vectors are passed by name: Spower turns each length-one argument into
  # a column of its design table and warns about longer ones.
  prop <- c(0.5, 0.65)
  ratios <- c(1, 1)
  power_with <- function(correct) {
    set.seed(3)
    Spower::Spower(
      Spower::p_prop.test(n = 170, prop = prop, n.ratios = ratios, correct = correct),
      replications = 5000, verbose = FALSE
    )$power
  }
  corrected <- power_with(TRUE)
  uncorrected <- power_with(FALSE)
  expect_equal(corrected, 0.7894)
  expect_equal(uncorrected, 0.8178)
  # powerkit's two-proportions z test is the uncorrected one.
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  spec <- sim_spec(
    "two_proportions", nrep = 5000,
    population = list(metric = "proportion", p1 = 0.5, p2 = 0.65),
    goal = list(type = "power", n = 340)
  )
  spec$options$seed <- 3
  expect_equal(run_quietly(spec)$curve$power, uncorrected)
})
