# Moderation by a factor with three or more groups (does X's slope on Y
# differ between groups?), simulated with Spower by powerkit's experiment
# p_group_moderator(), which fits lm(). Translation, the check run,
# refusals and the exported script; accuracy is checked by
# test-validation-group-moderator.R.

gm_spec <- function(n = 450, nrep = 100, ratio = NULL) {
  spec <- example_spec("group_moderator")
  if (!is.null(ratio)) spec$options$group_ratio <- as.list(ratio)
  spec$goal <- list(type = "power", n = n)
  spec$options$seed <- 7
  spec$options$nrep <- nrep
  spec
}

test_that("moderation by groups runs on Spower and passes its check run, with equal or unequal groups", {
  for (case in list(gm_spec(), gm_spec(n = 400, ratio = c(1, 2, 1)))) {
    result <- run_quietly(case)
    expect_equal(result$provenance$backend, "Spower")
    expect_match(result$provenance$backend_function, "p_group_moderator", fixed = TRUE)
    expect_true(all(result$check_run$ok))
  }
})

test_that("on one core, it equals a direct Spower call of the experiment", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  r <- c(-0.1, -0.2, -0.35)
  means <- c(0, 0, 0)
  ratio <- c(1, 1, 1)
  set.seed(7)
  direct <- Spower::Spower(p_group_moderator(n = 450, r = r, means = means, group_ratio = ratio), replications = 100, verbose = FALSE)
  expect_equal(run_quietly(gm_spec())$curve$power, direct$power)
})

test_that("the groups have their sizes, correlations and SD 1", {
  d <- with_seed(1, group_moderator_data(40000, c(0.1, 0.4, -0.3), c(0, 0.5, 1), c(1, 2, 1)))
  expect_equal(as.numeric(table(d$a)), c(10000, 20000, 10000))
  g2 <- d[d$a == 2, ]
  expect_equal(stats::cor(g2$x, g2$y), 0.4, tolerance = 0.03)
  expect_equal(stats::sd(g2$y), 1, tolerance = 0.02)
  expect_equal(mean(g2$y), 0.5, tolerance = 0.03)
})

test_that("plain-English refusals for moderation by groups", {
  spec <- gm_spec()
  spec$population$r_xy <- list(0.1, 0.2, 0.3, 0.4)
  expect_spec_problem(spec, "needs one correlation for each")
  spec <- gm_spec()
  spec$population$means <- list(0, 1, 2, 3)
  expect_spec_problem(spec, "needs one mean for each")
  spec <- gm_spec(ratio = c(1, 2))
  expect_spec_problem(spec, "one number per group")
  expect_equal(minimum_n(gm_spec()), 15)
})

test_that("the R script reproduces the run, and the simulated data have every group", {
  skip_unless_scripts_can_run()
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  spec <- gm_spec(n = 200, ratio = c(1, 2, 1))
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit)
  spec$options$nrep <- 1000L
  data <- simulated_data(spec, 200)
  expect_equal(nrow(data), 200)
  expect_equal(length(unique(data[[3]])), 3)
})
