# The aligned rank transform ANOVA with a within-participants factor (the
# 2 x 2 and larger mixed designs, and two within-participants factors),
# simulated with Spower by powerkit's experiment p_art_within(), which calls
# ARTool's art() with the participants as an error term (or, with unequal
# groups, a random intercept for each person). Translation, the check run,
# refusals and the exported script; accuracy is checked by
# test-validation-art-within.R.

artw_spec <- function(name = "anova_2x2_mixed", n = 60, nrep = 100, shape = "skewed", effect = NULL, r = NULL, group_ratio = NULL) {
  spec <- example_spec(name)
  spec$target_test$method <- "aligned_rank_transform"
  spec$target_test$correction <- NULL
  if (!is.null(effect)) spec$target_test$effect <- effect
  spec$population$score_shape <- shape
  spec$population$r <- r %||% (if (name == "anova_2x2_mixed") spec$population$r else unlist(spec$population$r)[1])
  if (!is.null(group_ratio)) spec$options$group_ratio <- as.list(group_ratio)
  spec$goal <- list(type = "power", n = n)
  spec$options$seed <- 7
  spec$options$nrep <- nrep
  spec
}

test_that("the within-participants aligned rank transform runs on Spower with ARTool, and passes its check run", {
  for (name in c("anova_2x2_mixed", "anova_mixed", "anova_factorial_within")) {
    result <- run_quietly(artw_spec(name))
    expect_equal(result$provenance$backend, "Spower")
    expect_match(result$provenance$backend_function, "p_art_within", fixed = TRUE)
    expect_true("ARTool" %in% names(result$provenance$packages))
    expect_true(all(result$check_run$ok), info = name)
  }
  # A correlation per group in the 2 x 2 mixed design.
  result <- run_quietly(artw_spec(r = list(0.3, 0.7)))
  expect_true(all(result$check_run$ok))
  expect_equal(result$check_run$specified[grepl("correlation", result$check_run$parameter)], c(0.3, 0.7))
})

test_that("on one core, it equals a direct Spower call of the experiment", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  spec <- artw_spec()
  means <- art_cells(spec)$means
  sds <- art_cells(spec)$sds
  r <- c(0.6, 0.6)
  ratio <- c(1, 1)
  term <- art_term(spec$target_test$effect)
  set.seed(7)
  direct <- Spower::Spower(p_art_within(n = 60, means = means, sds = sds, r = r, group_ratio = ratio,
    shape = "skewed", term = term), replications = 100, verbose = FALSE)
  expect_equal(run_quietly(spec)$curve$power, direct$power)
})

test_that("with equal groups, the error-term analysis gives ARTool's documented random-intercept model's tests", {
  # ARTool's help analyses repeated measures with art(y ~ a * b + (1 | id))
  # and anova(), Kenward-Roger F tests; aov() with Error(id) gives the same
  # p-values in a balanced design, and is what powerkit simulates.
  for (within_both in c(FALSE, TRUE)) {
    data <- with_seed(3, art_within_scores(30, matrix(c(0, 0, 0.3, 0.8), 2), matrix(1, 2, 2), c(0.5, 0.5), c(1, 1), "skewed", within_both))
    mixed <- anova(ARTool::art(Y ~ A * B + (1 | id), data = data))
    for (term in c("A", "B", "A:B")) {
      fit <- ARTool::artlm(ARTool::art(Y ~ A * B + Error(id), data = data), term)
      expect_equal(art_aov_p(fit, term), mixed$`Pr(>F)`[mixed$Term == term], tolerance = 1e-6, info = paste(term, within_both))
    }
  }
})

test_that("the scores have the cells' means and SDs, and one correlation between any two of a person's scores", {
  means <- matrix(c(1, 2, 3, 4, 5, 6), 2, byrow = TRUE)
  sds <- matrix(c(1, 2, 1, 2, 1, 2), 2, byrow = TRUE)
  data <- with_seed(4, art_within_scores(20000, means, sds, 0.4, 1, "heavy_tailed", within_both = TRUE))
  wide <- matrix(data$Y, ncol = 6)
  expect_equal(colMeans(wide), as.numeric(t(means)), tolerance = 0.02)
  expect_equal(apply(wide, 2, stats::sd), as.numeric(t(sds)), tolerance = 0.03)
  r <- stats::cor(wide)
  expect_equal(mean(r[upper.tri(r)]), 0.4, tolerance = 0.02)
  # Unequal groups: n split by the ratio.
  data <- with_seed(5, art_within_scores(90, means, sds, c(0.5, 0.5), c(1, 2), "normal"))
  expect_equal(as.numeric(table(data$A[data$B == 1])), c(30, 60))
})

test_that("unequal groups use the random-intercept model with Type III F tests", {
  spec <- artw_spec("anova_mixed", n = 60, nrep = 100, group_ratio = c(1, 2))
  result <- run_quietly(spec)
  expect_match(result$provenance$backend_function, "Kenward-Roger", fixed = TRUE)
  expect_true(all(c("lme4", "pbkrtest") %in% names(result$provenance$packages)))
  expect_true(all(result$check_run$ok))
})

test_that("plain-English refusals for the within-participants aligned rank transform", {
  expect_spec_problem(artw_spec("anova_mixed", r = list(0.5, 0.6, 0.7)), "give one correlation")
  expect_spec_problem(artw_spec(r = -0.2), "must be at least 0")
  spec <- artw_spec("anova_mixed")
  spec$target_test$correction <- "GG"
  expect_spec_problem(spec, "no correction")
  spec <- artw_spec()
  spec$population$score_shape <- NULL
  spec$target_test$method <- "anova_f"
  spec$population$score_shape <- "skewed"
  expect_spec_problem(spec, "only used by the rank tests")
})

test_that("the R script reproduces the run, and the simulated data are in long format", {
  skip_unless_scripts_can_run()
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  for (spec in list(artw_spec(n = 40, r = list(0.3, 0.7)), artw_spec("anova_factorial_within", n = 20, shape = "normal"),
                    artw_spec("anova_mixed", n = 30, group_ratio = c(1, 2)))) {
    out <- run_exported_script(spec, run_quietly(spec))
    expect_equal(out$reproduced, out$powerkit)
  }
  spec <- artw_spec("anova_mixed", n = 60)
  spec$options$nrep <- 1000L
  data <- simulated_data(spec, 60)
  expect_equal(nrow(data), 60 * 3)
  expect_true("Participant" %in% names(data))
})
