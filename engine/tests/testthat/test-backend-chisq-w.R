# Chi-square tests given by Cohen's w (population > metric "w"), as G*Power
# takes them: pwr's pwr.chisq.test() for independence and pwrss's
# power.chisq.gof() for goodness of fit, with the df from the numbers of
# levels.

w_spec <- function(name, w, goal = list(type = "power", n = 200L)) {
  spec <- example_spec(name)
  spec$population <- list(metric = "w", w = w)
  spec$goal <- goal
  spec
}

# Power from the noncentral chi-square, as G*Power computes it: lambda = w^2 N.
chisq_power <- function(w, df, n, alpha = 0.05) {
  stats::pchisq(stats::qchisq(1 - alpha, df), df, ncp = n * w^2, lower.tail = FALSE)
}

test_that("a test of independence given by Cohen's w runs on pwr.chisq.test(), with df from the levels", {
  result <- run_spec(w_spec("chi_square_independence", 0.2))
  expect_identical(result$provenance$backend_function, "pwr::pwr.chisq.test")
  expect_true(all(result$check_run$ok))
  # Three levels of X and two of Y: df = 2.
  expect_equal(result$curve$power, chisq_power(0.2, 2, 200), tolerance = 1e-8)
})

test_that("a goodness-of-fit test given by Cohen's w runs on power.chisq.gof(), with df = categories - 1", {
  result <- run_spec(w_spec("chi_square_gof", 0.25, goal = list(type = "power", n = 150L)))
  expect_identical(result$provenance$backend_function, "pwrss::power.chisq.gof")
  expect_true(all(result$check_run$ok))
  expect_equal(result$curve$power, chisq_power(0.25, 2, 150), tolerance = 1e-8)
})

test_that("the same table gives the same power from its proportions and from its Cohen's w", {
  spec <- example_spec("chi_square_independence")
  spec$goal <- list(type = "power", n = 200L)
  from_table <- run_spec(spec)$curve$power
  w <- pwr::ES.w2(probability_matrix(validate_spec(spec)))
  expect_equal(run_spec(w_spec("chi_square_independence", w))$curve$power, from_table, tolerance = 1e-10)

  gof <- example_spec("chi_square_gof")
  gof$goal <- list(type = "power", n = 150L)
  w <- pwrss::probs.to.w(c(0.25, 0.3, 0.45), verbose = 0)$w
  expect_equal(run_spec(w_spec("chi_square_gof", w, goal = gof$goal))$curve$power, run_spec(gof)$curve$power, tolerance = 1e-10)
})

test_that("Cohen's w gives a sample size and the smallest detectable w", {
  result <- run_spec(w_spec("chi_square_independence", 0.2, goal = list(type = "sample_size", power = 0.8)))
  n <- result$n_required$n
  expect_gte(chisq_power(0.2, 2, n), 0.8)
  expect_lt(chisq_power(0.2, 2, n - 1), 0.8)
  sens <- run_spec(w_spec("chi_square_independence", 0.2, goal = list(type = "sensitivity", n = 200L, power = 0.8)))
  expect_equal(chisq_power(sens$sensitivity$effect, 2, 200), 0.8, tolerance = 1e-4)
})

test_that("Cohen's w is refused with a simulation or alongside the proportions, and gives no simulated data set", {
  spec <- w_spec("chi_square_independence", 0.2)
  spec$options$method <- "simulation"
  expect_spec_problem(spec, "a simulation needs the proportions")
  both <- w_spec("chi_square_independence", 0.2)
  both$population$probabilities <- example_spec("chi_square_independence")$population$probabilities
  expect_error(validate_spec(both), class = "powerkit_spec_error")
  expect_null(simulated_data_code(validate_spec(w_spec("chi_square_gof", 0.2)), 100, 1))
})

test_that("the exported scripts reproduce the result from Cohen's w", {
  for (name in c("chi_square_independence", "chi_square_gof")) {
    spec <- w_spec(name, 0.2)
    expect_script_reproduces_power(spec, run_spec(spec))
  }
})
