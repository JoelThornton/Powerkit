# The variance tests by their exact distributions (backend-variance.R):
# the G*Power 3.1 manual's own examples (sections 26.3 and 15.3) and its
# critical values, the formula against Spower's simulation, and the R
# script reproducing the result.

variance_test_spec <- function(template, population, goal, alternative = "two_sided", options = list(seed = 1L)) {
  list(
    spec_version = "0.1", design = "basic_test", template = template,
    variables = if (template == "one_variance") {
      list(Y = list(type = "continuous", label = "Score"))
    } else {
      list(G = list(type = "binary", label = "Group", levels = list("A", "B")), Y = list(type = "continuous", label = "Score"))
    },
    population = c(list(metric = "variance"), population),
    target_test = list(
      effect = "variance_ratio", method = if (template == "one_variance") "chi_square_var" else "f_var",
      alternative = alternative, alpha = 0.05
    ),
    effect_justification = list(type = "none"),
    goal = goal, options = options
  )
}

test_that("one and two variances are computed by formula by default, with the manual's numbers", {
  # Section 26.3: ratio 1 / 1.5, one-sided, 80% power: N = 81, critical
  # chi-square 60.391478; two-sided, N = 103.
  one <- run_spec(variance_test_spec("one_variance", list(var = 1, var0 = 1.5), list(type = "sample_size", power = 0.8), "less"))
  expect_identical(one$provenance$backend, "stats")
  expect_identical(one$provenance$method, "exact")
  expect_equal(one$n_required$n, 81)
  expect_equal(one$details$critical, 60.391478, tolerance = 1e-6)
  expect_equal(one$details$df, 80)
  two_sided <- run_spec(variance_test_spec("one_variance", list(var = 1, var0 = 1.5), list(type = "sample_size", power = 0.8)))
  expect_equal(two_sided$n_required$n, 103)
  # Section 15.3: ratio 1.5, two-sided, equal groups: 193 per group,
  # actual power 0.800105, critical F 0.752964 and 1.328085.
  two <- run_spec(variance_test_spec("two_variances", list(var1 = 1.5, var2 = 1), list(type = "sample_size", power = 0.8)))
  expect_equal(two$n_required$n, 386)
  power <- run_spec(variance_test_spec("two_variances", list(var1 = 1.5, var2 = 1), list(type = "power", n = 386L)))
  expect_equal(power$curve$power, 0.800105, tolerance = 1e-6)
  expect_equal(power$details$critical, c(0.752964, 1.328085), tolerance = 1e-6)
  expect_equal(power$details$df, c(192, 192))
})

test_that("unequal groups work by formula, keeping the ratio exact", {
  # Section 15.3 with N2/N1 = 2: G*Power gives 148 and 295 (N = 443), the
  # 1.5 variance in the larger group. powerkit keeps the ratio exact
  # (148 and 296), so it needs one more person.
  r <- run_spec(variance_test_spec("two_variances", list(var1 = 1, var2 = 1.5), list(type = "sample_size", power = 0.8),
    options = list(seed = 1L, allocation_ratio = 2)))
  expect_equal(r$n_required$n, 444)
  # The simulation still draws equal groups only, and says so.
  expect_error(
    validate_spec(variance_test_spec("two_variances", list(var1 = 1, var2 = 1.5), list(type = "power", n = 90L),
      options = list(seed = 1L, allocation_ratio = 2, method = "simulation"))),
    "simulated two-variance test"
  )
})

test_that("the formula agrees with Spower's simulation of the same test", {
  skip_if_not_installed("Spower")
  spec <- variance_test_spec("two_variances", list(var1 = 1.5, var2 = 1), list(type = "power", n = 120L),
    options = list(seed = 7L, method = "simulation", nrep = 2000L))
  simulated <- run_spec(spec)
  expect_identical(simulated$provenance$backend, "Spower")
  spec$options$method <- NULL
  spec$options$nrep <- NULL
  exact <- run_spec(spec)
  expect_lt(abs(exact$curve$power - simulated$curve$power), 4 * simulated$curve$mcse)
})

test_that("the R script reproduces the formula's result with base R alone", {
  for (template in c("one_variance", "two_variances")) {
    pop <- if (template == "one_variance") list(var = 1, var0 = 1.5) else list(var1 = 1.5, var2 = 1)
    for (goal in list(list(type = "power", n = 60L), list(type = "sample_size", power = 0.8))) {
      spec <- variance_test_spec(template, pop, goal)
      result <- run_spec(spec)
      text <- export_script(spec, result)
      expect_no_match(text, "library(", fixed = TRUE)
      out <- utils::capture.output(eval(parse(text = text), envir = new.env()))
      expect_true(any(grepl("Reproduced powerkit's result.", out, fixed = TRUE)), info = paste(template, goal$type))
    }
  }
})
