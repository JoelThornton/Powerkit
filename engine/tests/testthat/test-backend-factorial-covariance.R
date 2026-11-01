# Two-factor designs with repeated measures and an SD per cell, a
# correlation per pair and a sphericity correction: the mixed design
# (template mixed, Superpower's "kb*mw"), the two-factor within design
# (factorial_within, "kw*mw") and the 2 x 2 mixed design (2x2_mixed, a
# correlation per group). Superpower's ANOVA_design() takes the SDs and the
# whole correlation matrix's upper triangle; ANOVA_exact(correction =).

mixed_cov_spec <- function(correction = NULL, sd = list(list(6, 7, 8), list(6, 8, 10)), r = list(0.6, 0.4, 0.6), n = 40) {
  spec <- example_spec("anova_mixed")
  spec$population$sd <- sd
  spec$population$r <- r
  spec$target_test$effect <- "interaction"
  spec$target_test$correction <- correction
  spec$goal <- list(type = "power", n = n)
  spec
}

within_cov_spec <- function(correction = NULL) {
  spec <- example_spec("anova_factorial_within")
  k <- length(spec$variables$A$levels)
  m <- length(spec$variables$B$levels)
  spec$population$sd <- rep(list(as.list(seq(70, 100, length.out = m))), k)
  cells <- k * m
  rr <- 0.7 - 0.08 * abs(outer(seq_len(cells), seq_len(cells), "-"))
  spec$population$r <- as.list(t(rr)[lower.tri(rr)])
  spec$target_test$effect <- "interaction"
  spec$target_test$correction <- correction
  spec$goal <- list(type = "power", n = 20)
  spec
}

test_that("a mixed design's SDs per cell and correlations per pair reach Superpower, with each correction", {
  spec <- mixed_cov_spec()
  mu <- as.numeric(unlist(spec$population$means))
  # The whole correlation matrix: each group's block, 0 between groups.
  r_full <- c(0.6, 0.4, 0, 0, 0, 0.6, 0, 0, 0, 0, 0, 0, 0.6, 0.4, 0.6)
  expect_equal(superpower_r(validate_quietly(spec)), r_full)
  design <- suppressWarnings(with_seed(NULL, Superpower::ANOVA_design("2b*3w", n = 20, mu = mu, sd = c(6, 7, 8, 6, 8, 10), r = r_full, plot = FALSE)))
  for (correction in c("none", "GG", "HF")) {
    result <- run_quietly(mixed_cov_spec(correction))
    direct <- suppressWarnings(Superpower::ANOVA_exact(design, correction = correction, verbose = FALSE))
    expect_equal(result$curve$power, direct$main_results["a:b", "power"] / 100, tolerance = 1e-8, label = correction)
    expect_true(all(result$check_run$ok), label = correction)
  }
  expect_false(is.null(run_quietly(mixed_cov_spec())$manova))
  # Without sphericity the correction costs power; with one SD and one
  # correlation it changes nothing.
  expect_gt(run_quietly(mixed_cov_spec("none"))$curve$power - run_quietly(mixed_cov_spec("GG"))$curve$power, 0.005)
  same <- mixed_cov_spec("GG", sd = 6, r = 0.5)
  expect_equal(run_quietly(same)$curve$power, run_quietly(mixed_cov_spec("none", sd = 6, r = 0.5))$curve$power, tolerance = 1e-6)
})

test_that("a two-factor within design takes an SD per cell and a correlation per pair of cells", {
  spec <- within_cov_spec("GG")
  result <- run_quietly(spec)
  expect_true(all(result$check_run$ok))
  design <- suppressWarnings(with_seed(NULL, Superpower::ANOVA_design(superpower_inputs(validate_quietly(spec))$design, n = 20,
    mu = as.numeric(unlist(spec$population$means)), sd = as.numeric(unlist(spec$population$sd)),
    r = as.numeric(unlist(spec$population$r)), plot = FALSE)))
  direct <- suppressWarnings(Superpower::ANOVA_exact(design, correction = "GG", verbose = FALSE))
  expect_equal(result$curve$power, direct$main_results["a:b", "power"] / 100, tolerance = 1e-8)
})

test_that("a 2 x 2 mixed design takes a correlation per group and an SD per cell", {
  spec <- example_spec("anova_2x2_mixed")
  spec$population$metric <- "raw"
  spec$population$sd <- list(list(1, 1.2), list(1, 1.5))
  spec$population$r <- list(0.3, 0.7)
  spec$goal <- list(type = "power", n = 60)
  result <- run_quietly(spec)
  expect_true(all(result$check_run$ok))
  expect_equal(superpower_r(validate_quietly(spec)), c(0.3, 0, 0, 0, 0, 0.7))
  expect_equal(result$check_run$specified[grepl("^r between", result$check_run$parameter)], c(0.3, 0.7))
})

test_that("mismatched or impossible SDs and correlations are refused in plain words", {
  expect_spec_problem(mixed_cov_spec(r = list(0.9, -0.9, 0.9)), "can't all hold at once")
  expect_spec_problem(mixed_cov_spec(r = list(0.5, 0.5, 0.5, 0.5)), "one correlation per pair of B's levels")
  expect_spec_problem(mixed_cov_spec(sd = list(list(6, 7), list(6, 8))), "one SD per cell")
  wrong <- within_cov_spec()
  wrong$population$r <- list(0.5, 0.5, 0.5, 0.5, 0.5, 0.5)
  expect_spec_problem(wrong, "one correlation per pair of cells")
  two <- example_spec("anova_2x2_mixed")
  two$target_test$correction <- "GG"
  expect_spec_problem(two, "sphericity can't fail")
  eta <- example_spec("anova_mixed")
  eta$population <- list(metric = "eta_squared", eta_squared = 0.06, eta_source = "published")
  eta$target_test$correction <- "GG"
  expect_spec_problem(eta, "needs the cell means, SDs and correlations")
})

test_that("the exported scripts reproduce corrected mixed and within designs", {
  skip_unless_scripts_can_run()
  spec <- mixed_cov_spec("GG")
  expect_script_reproduces_power(spec, run_for_export(spec))
  spec <- within_cov_spec("GG")
  expect_script_reproduces_power(spec, run_for_export(spec))
  spec <- mixed_cov_spec("GG")
  spec$options <- list(method = "simulation", nrep = 100, seed = 3)
  expect_script_reproduces_power(spec, run_for_export(spec))
})
