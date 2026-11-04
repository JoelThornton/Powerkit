# PERMANOVA (permutational MANOVA) as a test version on the MANOVA template,
# simulated with Spower by powerkit's experiment p_permanova(), which calls
# vegan's adonis2(). Translation, routing, the check run, refusals and the
# exported script; accuracy is checked by test-validation-permanova.R.

perm_spec <- function(n = 90, nrep = 100, shape = NULL, groups = 3, two_factor = FALSE) {
  spec <- example_spec("manova")
  spec$target_test$method <- "permanova"
  spec$population$score_shape <- shape
  if (groups == 2) {
    spec$variables$A$levels <- spec$variables$A$levels[1:2]
    spec$population$means <- spec$population$means[1:2]
  }
  if (two_factor) {
    spec$variables$A$levels <- list("Control", "Course")
    spec$variables$B <- list(type = "between_factor", label = "Format", levels = list("Online", "In person"))
    spec$population$means <- list(list(20, 18, 22), list(20, 18, 22), list(18, 16.5, 20), list(16, 15, 18))
    spec$target_test$effect <- "interaction"
  }
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  spec
}

test_that("PERMANOVA runs on Spower with vegan, for two or more groups and two factors, and passes its check run", {
  for (case in list(perm_spec(), perm_spec(shape = "skewed"), perm_spec(groups = 2, n = 80), perm_spec(two_factor = TRUE, n = 120))) {
    result <- run_quietly(case)
    expect_equal(result$provenance$backend, "Spower")
    expect_match(result$provenance$backend_function, "adonis2", fixed = TRUE)
    expect_true("vegan" %in% names(result$provenance$packages))
    expect_true(all(result$check_run$ok))
    expect_gt(result$curve$mcse, 0)
  }
})

test_that("on one core, it equals a direct Spower call of the experiment", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  means <- manova_means(perm_spec())
  sds <- c(6, 5, 7)
  set.seed(7)
  direct <- Spower::Spower(p_permanova(n = 30, means = means, sds = sds, r = 0.5, shape = "normal"), replications = 100, verbose = FALSE)
  expect_equal(run_quietly(perm_spec())$curve$power, direct$power)
})

test_that("the shaped scores have their means, SDs and correlation", {
  # Skewed scores (a heavy-tailed t with 3 df has no fourth moment, so its
  # sample SD and correlation settle slowly).
  data <- with_seed(3, permanova_scores(30000, matrix(c(0, 1, 2, 3, 4, 5), 2, byrow = TRUE), c(1, 2, 3), 0.4, "skewed"))
  y <- unname(as.matrix(data[data$group == 2, -1]))
  expect_equal(colMeans(y), c(3, 4, 5), tolerance = 0.02)
  expect_equal(apply(y, 2, stats::sd), c(1, 2, 3), tolerance = 0.03)
  expect_equal(stats::cor(y)[1, 2], 0.4, tolerance = 0.05)
})

test_that("plain-English refusals for PERMANOVA", {
  spec <- perm_spec(shape = "skewed")
  spec$population$r <- -0.2
  expect_spec_problem(spec, "must be at least 0")
  spec <- perm_spec(shape = "skewed")
  spec$target_test$method <- "pillai_trace"
  expect_spec_problem(spec, "only used by PERMANOVA")
})

test_that("the R script reproduces the run, and the simulated data have the shape asked for", {
  skip_unless_scripts_can_run()
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  for (spec in list(perm_spec(n = 60, shape = "skewed"), perm_spec(n = 80, two_factor = TRUE))) {
    out <- run_exported_script(spec, run_quietly(spec))
    expect_equal(out$reproduced, out$powerkit)
  }
  spec <- perm_spec(shape = "skewed")
  spec$options$nrep <- 1000L
  data <- simulated_data(spec, 90)
  expect_equal(nrow(data), 90)
})
