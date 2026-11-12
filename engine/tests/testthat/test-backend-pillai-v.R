# MANOVA given by Pillai's V (backend-hotelling.R, pillai_backend()): Faul,
# Erdfelder, Lang and Buchner (2007), Table 5, Pillai's V with the O'Brien
# and Shieh approximation. Checked against Spower's simulation of the same
# MANOVA from means whose population V is known, against the exact
# Hotelling's T-squared route with two groups, and by the exported script.

pillai_spec <- function(v = 0.1, goal = list(type = "power", n = 90), ...) {
  spec <- example_spec("manova")
  spec$population <- list(metric = "pillai_v", pillai_v = v)
  spec$goal <- goal
  spec$options <- list(seed = 7, ...)
  spec
}

manova_sigma <- function(sds, r) {
  correlation <- matrix(r, length(sds), length(sds))
  diag(correlation) <- 1
  correlation * outer(sds, sds)
}

test_that("a MANOVA given by Pillai's V is computed by Faul et al.'s formula", {
  result <- run_spec(pillai_spec())
  expect_identical(result$provenance$backend, "stats")
  expect_identical(result$provenance$method, "exact")
  expect_match(result$provenance$backend_function, "Pillai's V", fixed = TRUE)
  # Three groups, three outcomes: s = 2, df1 = 6, df2 = 2 (90 - 3 - 3 + 2),
  # f^2 = 0.1 / 1.9, noncentrality 90 x 2 x f^2.
  f2 <- 0.1 / 1.9
  expect_equal(result$details$df, c(6, 172))
  expect_equal(result$details$ncp, 90 * 2 * f2)
  expected <- stats::pf(stats::qf(0.95, 6, 172), 6, 172, ncp = 180 * f2, lower.tail = FALSE)
  expect_equal(result$curve$power, expected)
})

test_that("the sample size is the smallest n reaching the target power, and the smallest V solves back", {
  spec <- pillai_spec(goal = list(type = "sample_size", power = 0.8))
  result <- run_spec(spec)
  inputs <- pillai_inputs(spec)
  n <- result$n_required$n
  expect_gte(pillai_power(inputs, n), 0.8)
  expect_lt(pillai_power(inputs, n - 3), 0.8)
  found <- run_spec(pillai_spec(goal = list(type = "sensitivity", n = n, power = 0.8)))$sensitivity
  expect_identical(found$effect_name, "V")
  expect_equal(pillai_power(pillai_inputs(spec, found$effect), n), 0.8, tolerance = 1e-6)
  expect_lte(found$effect, 0.1)
})

test_that("with two groups, Pillai's V gives the exact Hotelling's T-squared answer", {
  spec <- example_spec("manova")
  spec$variables$A$levels <- c("Control", "Treatment")
  spec$population$means <- list(c(0, 0, 0), c(0.4, 0.3, 0.1))
  spec$population$sds <- c(1, 1, 1)
  spec$population$r <- 0.3
  spec$goal <- list(type = "power", n = 80)
  exact <- run_spec(spec)$curve$power
  v <- pillai_v_from_means(manova_means(spec), manova_sigma(c(1, 1, 1), 0.3))
  by_v <- spec
  by_v$population <- list(metric = "pillai_v", pillai_v = v)
  expect_equal(run_spec(by_v)$curve$power, exact, tolerance = 1e-10)
})

test_that("the formula agrees with Spower's simulation of the same MANOVA", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  means <- example_spec("manova")
  sigma <- manova_sigma(as.numeric(unlist(means$population$sds)), means$population$r)
  v <- pillai_v_from_means(manova_means(means), sigma)
  for (n in c(90, 180)) {
    simulated_spec <- means
    simulated_spec$goal <- list(type = "power", n = n)
    simulated_spec$options <- list(seed = 11, nrep = 4000, method = "simulation")
    simulated <- run_quietly(simulated_spec)$curve$power
    formula <- run_spec(pillai_spec(v = v, goal = list(type = "power", n = n)))$curve$power
    expect_lt(abs(simulated - formula), 3 * sqrt(formula * (1 - formula) / 4000))
  }
})

test_that("a two-factor MANOVA's interaction given by V uses its own degrees of freedom", {
  spec <- pillai_spec(v = 0.05, goal = list(type = "power", n = 120))
  spec$variables$A$levels <- c("Control", "Course")
  spec$variables$B <- list(type = "between_factor", label = "Delivery", levels = c("Online", "In person", "Mixed"))
  spec$target_test$effect <- "interaction"
  result <- run_spec(spec)
  # Interaction df (2 - 1)(3 - 1) = 2; s = min(3, 2) = 2; six groups.
  expect_equal(result$details$df, c(6, 2 * (120 - 6 - 3 + 2)))
})

test_that("V must be below s, and has no simulation or PERMANOVA", {
  expect_error(run_spec(pillai_spec(v = 2)), "less than 2", class = "powerkit_spec_error")
  expect_error(run_spec(pillai_spec(method = "simulation")), "worked out by formula", class = "powerkit_spec_error")
  spec <- pillai_spec()
  spec$population$means <- list(c(1, 2, 3), c(1, 2, 3), c(1, 2, 3))
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})

test_that("the exported script reproduces the formula with base R alone", {
  skip_unless_scripts_can_run()
  spec <- pillai_spec()
  result <- run_for_export(spec)
  expect_no_match(export_script(spec, result), "library(", fixed = TRUE)
  expect_script_reproduces_power(spec, result)
})

test_that("a result from Pillai's V cites Faul et al. (2007) as its formula", {
  text <- export_citations(run_spec(pillai_spec()))
  expect_match(text, "The published formula powerkit computed power from", fixed = TRUE)
  expect_match(text, "Faul", fixed = TRUE)
  expect_no_match(text, "stats_method", fixed = TRUE)
})
