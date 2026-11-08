# Whole-study simulation of an experiment: every F test of one factorial
# ANOVA, read from the same simulated data sets (Superpower::ANOVA_power()).

experiment_whole_study <- function(template = "anova_2x2_between", effects = c("main_effect_A", "interaction"),
                                   claim = "all", goal = list(type = "power", n = 160L), nrep = 400L) {
  exp <- unclass(read_spec(system.file("specs", paste0(template, ".json"), package = "powerkit")))
  exp$goal <- NULL
  exp$options <- NULL
  exp$effect_justification <- NULL
  list(spec_version = "0.1", kind = "whole_study", experiment = exp,
    analyses = lapply(seq_along(effects), function(i) list(id = paste0("t", i), label = effects[[i]],
      test = "anova_effect", effect = effects[[i]], role = "main")),
    claim = claim, alpha = 0.05, effect_justification = list(type = "none"),
    goal = goal, options = list(nrep = nrep, seed = 11L))
}

test_that("an experiment's whole study checks its design and its analyses plainly", {
  expect_s3_class(validate_whole_study(experiment_whole_study()), "powerkit_whole_study")
  spec <- experiment_whole_study()
  spec$analyses[[2]]$effect <- "main_effect_A"
  expect_error(validate_whole_study(spec), "different effect")
  spec <- experiment_whole_study()
  spec$analyses[[1]]$test <- "x_y"
  spec$analyses[[1]]$effect <- NULL
  expect_error(validate_whole_study(spec), "anova_effect")
  spec <- experiment_whole_study()
  spec$experiment$population$sd <- -1
  expect_error(validate_whole_study(spec), "In the experiment")
  spec <- experiment_whole_study()
  spec$variables <- list(X = list(type = "continuous", label = "X"))
  expect_error(validate_whole_study(spec))
  spec <- experiment_whole_study("anova_oneway_between", "interaction")
  expect_error(validate_whole_study(spec), "one factor")
  spec <- experiment_whole_study("anova_factorial_three")
  expect_error(validate_whole_study(spec), "one or two factors")
})

test_that("each test's power matches its exact power, and joint power an independent simulation", {
  skip_on_cran()
  spec <- experiment_whole_study(nrep = 2000L)
  r <- run_whole_study(spec)
  expect_true(all(r$check_run$ok))
  # Each F test alone: Superpower's exact power (ANOVA_exact()), within 4.5
  # Monte Carlo standard errors.
  exact <- vapply(r$implied, function(i) i$values$power_alone, numeric(1))
  expect_true(all(abs(r$analyses$power - exact) < 4.5 * sqrt(exact * (1 - exact) / 2000)))
  # Joint power: every main test significant in the same data set, against
  # a simulation written independently with stats::aov() (balanced cells,
  # so sequential and Type III sums of squares agree).
  pop <- spec$experiment$population
  means <- matrix(unlist(pop$means), 2, byrow = TRUE)
  set.seed(5)
  both <- replicate(2000, {
    d <- expand.grid(i = 1:40, a = factor(1:2), b = factor(1:2))
    d$y <- stats::rnorm(nrow(d), means[cbind(as.integer(d$a), as.integer(d$b))], pop$sd)
    p <- summary(stats::aov(y ~ a * b, data = d))[[1]][["Pr(>F)"]]
    p[1] < 0.05 && p[3] < 0.05
  })
  independent <- mean(both)
  se <- sqrt(independent * (1 - independent) * (1 / 2000 + 1 / 2000))
  expect_lt(abs(r$joint$power - independent), 4.5 * se)
  expect_identical(r$provenance$backend, "Superpower")
  expect_s3_class(r, "powerkit_whole_study_result")
})

test_that("a mixed design reads the within factor and the interaction from the same ANOVA", {
  skip_on_cran()
  r <- run_whole_study(experiment_whole_study("anova_2x2_mixed", c("main_effect_B", "interaction"), claim = "any",
    goal = list(type = "power", n = 120L), nrep = 300L))
  expect_equal(r$analyses$alpha, c(0.025, 0.025))
  expect_identical(r$joint$rule, "any")
  expect_gte(r$joint$power, max(r$analyses$power))
})

test_that("an experiment's sample size search finds the n for joint power", {
  skip_on_cran()
  spec <- experiment_whole_study("anova_oneway_between", "main_effect_A", claim = "each",
    goal = list(type = "sample_size", power = 0.8), nrep = 300L)
  r <- run_whole_study(spec)
  expect_identical(r$n %% 3, 0)
  # The one-way card's exact n (equal groups), within the search's error.
  exp <- spec$experiment
  exp$goal <- list(type = "sample_size", power = 0.8)
  exp$effect_justification <- list(type = "none")
  exact <- run_spec(exp)$n_required$n
  expect_lt(abs(r$n - exact) / exact, 0.2)
  expect_match(export_whole_study_script(spec), "Superpower")
})

test_that("an experiment's result prints with its own backend, and its script saves before printing", {
  skip_on_cran()
  r <- run_whole_study(experiment_whole_study(nrep = 100L))
  out <- capture.output(print(r))
  expect_true(any(grepl(sprintf("Backend: Superpower %s", utils::packageVersion("Superpower")), out, fixed = TRUE)))
  script <- export_whole_study_script(experiment_whole_study(nrep = 100L))
  expect_lt(regexpr("saveRDS(result", script, fixed = TRUE), regexpr("print(result)", script, fixed = TRUE))
})
