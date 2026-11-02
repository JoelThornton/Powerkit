# The aligned rank transform ANOVA for two between-participants factors,
# simulated with Spower by powerkit's experiment p_art(), which calls
# ARTool's art() and artlm() and car's Anova(). Translation, check run,
# refusals; accuracy is checked by test-validation-art.R.

art_spec <- function(template = "2x2_between", n = 80, nrep = 100, shape = "skewed", effect = "interaction") {
  spec <- example_spec(if (template == "2x2_between") "anova_2x2_between" else "anova_factorial_between")
  spec$target_test$method <- "aligned_rank_transform"
  spec$target_test$effect <- effect
  spec$population$score_shape <- shape
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  spec
}

test_that("the aligned rank transform runs on Spower with ARTool, and passes its check run", {
  for (template in c("2x2_between", "factorial_between")) {
    result <- run_quietly(art_spec(template, n = if (template == "2x2_between") 80 else 120))
    expect_equal(result$provenance$backend, "Spower", info = template)
    expect_equal(result$provenance$method, "simulation", info = template)
    expect_match(result$provenance$backend_function, "p_art", fixed = TRUE)
    expect_true(all(c("ARTool", "car") %in% names(result$provenance$packages)), info = template)
    expect_true(all(result$check_run$ok), info = template)
  }
})

test_that("p_art() reads the Type III row anova() gives for art()'s model, also with unequal cells", {
  data <- with_seed(3, art_scores(10, matrix(c(0, 0, 0, 1, 0.5, 0), 2), matrix(1, 2, 3), matrix(c(1, 2, 1, 1, 2, 1), 2), "skewed"))
  expect_equal(as.vector(table(data$A, data$B)), c(10, 20, 10, 10, 20, 10))
  table <- anova(ARTool::art(Y ~ A * B, data = data))
  for (term in c("A", "B", "A:B")) {
    by_term <- car::Anova(ARTool::artlm(ARTool::art(Y ~ A * B, data = data), term), type = 3)[term, "Pr(>F)"]
    expect_equal(by_term, table$`Pr(>F)`[table$Term == term], tolerance = 1e-10, info = term)
  }
})

test_that("on one core, it equals a direct Spower call of the experiment", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  spec <- validate_quietly(art_spec(n = 80, nrep = 100, effect = "main_effect_A"))
  cells <- art_cells(spec)
  expect_equal(cells$means, matrix(c(10, 10, 10, 13), 2))
  expect_equal(cells$sds, matrix(6, 2, 2))
  # Spower looks up matrix arguments by name.
  m <- cells$means
  s <- cells$sds
  w <- cells$n.ratios
  set.seed(7)
  direct <- Spower::Spower(p_art(n = 20, means = m, sds = s, n.ratios = w, shape = "skewed", term = "A"),
    replications = 100, verbose = FALSE)
  expect_equal(run_quietly(spec)$curve$power, direct$power)
})

test_that("unequal cells and an SD per cell reach the scores", {
  spec <- art_spec()
  spec$options$cell_ratio <- list(list(2, 1), list(1, 1))
  spec$population$sd <- list(list(4, 6), list(6, 8))
  cells <- art_cells(validate_quietly(spec))
  expect_equal(cells$n.ratios, matrix(c(2, 1, 1, 1), 2))
  expect_equal(cells$sds, matrix(c(4, 6, 6, 8), 2))
  expect_equal(spower_inputs(validate_quietly(spec))$args(100)$n, 20)
  data <- with_seed(1, art_scores(2e4, cells$means, cells$sds, cells$n.ratios, "heavy_tailed"))
  expect_equal(stats::sd(data$Y[data$A == 2 & data$B == 2]), 8, tolerance = 0.05)
  expect_true(all(run_quietly(spec)$check_run$ok))
})

test_that("the aligned rank transform needs cell means, and the shape belongs to it", {
  spec <- art_spec()
  spec$population <- list(metric = "eta_squared", eta_squared = 0.06, score_shape = "normal")
  expect_spec_problem(spec, "The aligned rank transform needs the mean in each group or condition and the SD")
  spec <- art_spec()
  spec$target_test$method <- "anova_f"
  expect_spec_problem(spec, "'population > score_shape' is only used by the rank tests")
})

test_that("the R script reproduces the run, and the simulated data have the cells' sizes", {
  skip_unless_scripts_can_run()
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  spec <- art_spec(n = 80, nrep = 100)
  spec$options$cell_ratio <- list(list(2, 1), list(1, 1))
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
  expect_true(any(grepl("ARTool::artlm(model, term)", out$script, fixed = TRUE)))
  data <- simulated_data(validate_quietly(spec), 100)
  expect_equal(nrow(data), 100)
  expect_equal(as.vector(table(data$Feedback, data$Task_difficulty)), c(40, 20, 20, 20))
})
