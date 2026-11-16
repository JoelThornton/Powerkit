# The Bayes factor of an effect in a three-factor ANOVA (E56): JASP's
# Bayesian ANOVA, the effect's inclusion Bayes factor from BayesFactor's
# anovaBF(), simulated with Spower.

bfthree_spec <- function(within = c("B", "C"), n = 40, nrep = 100, ...) {
  spec <- read_spec(system.file("specs", "anova_factorial_three.json", package = "powerkit"))
  for (v in c("A", "B", "C")) spec$variables[[v]]$type <- if (v %in% within) "within_factor" else "between_factor"
  if (!length(within)) spec$population$r <- NULL
  spec$target_test <- utils::modifyList(list(effect = "interaction_ABC", method = "bayes_factor", evidence_threshold = 3), list(...))
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = nrep, seed = 20261115)
  spec
}

test_that("the inputs read the cell means as an array, which factors are within and JASP's default prior", {
  inputs <- bfthree_inputs(validate_quietly(bfthree_spec()))
  expect_identical(unname(dim(inputs$means)), c(2L, 2L, 2L))
  # The spec nests A, then B, then C: means[[2]][[2]] is (84, 70).
  expect_identical(inputs$means[2, 2, ], c(84, 70))
  expect_identical(inputs$means[1, 2, 1], 81)
  expect_identical(inputs$within, c(A = FALSE, B = TRUE, C = TRUE))
  expect_identical(c(inputs$r, inputs$prior_scale), c(0.5, 0.5))
  expect_identical(inputs$term, "A:B:C")
  expect_identical(inputs$inclusion, "all_models")
  between <- bfthree_inputs(validate_quietly(bfthree_spec(within = character(), effect = "interaction_AC", inclusion = "matched_models")))
  expect_identical(between$r, 0)
  expect_identical(between$term, "A:C")
  expect_identical(between$inclusion, "matched_models")
})

test_that("removing an effect leaves the others: the decomposition matches the ANOVA's", {
  means <- bfthree_inputs(validate_quietly(bfthree_spec()))$means
  cells <- expand.grid(A = factor(1:2), B = factor(1:2), C = factor(1:2))
  cells$y <- means[cbind(as.integer(cells$A), as.integer(cells$B), as.integer(cells$C))]
  ss <- function(m) {
    cells$y <- m[cbind(as.integer(cells$A), as.integer(cells$B), as.integer(cells$C))]
    stats::setNames(summary(stats::aov(y ~ A * B * C, data = cells))[[1]][["Sum Sq"]], c("A", "B", "C", "A:B", "A:C", "B:C", "A:B:C"))
  }
  full <- ss(means)
  for (term in names(full)) {
    without <- ss(bfthree_null_means(means, term))
    expect_lt(without[[term]], 1e-10)
    expect_equal(without[names(full) != term], full[names(full) != term])
  }
  # A 2 x 3 x 2 layout too.
  big <- array(seq_len(12)^1.5, dim = c(2, 3, 2))
  part <- bfthree_effect_part(big, "B")
  expect_equal(part[1, , 1], apply(big, 2, mean) - mean(big))
})

test_that("the simulated data have equal groups, the cell means, the SD and the correlation", {
  set.seed(4)
  inputs <- bfthree_inputs(validate_quietly(bfthree_spec()))
  data <- bfthree_data(4000, inputs$means, inputs$sd, inputs$within, inputs$r)
  expect_identical(nrow(data), 16000L)
  expect_identical(as.vector(table(data$A)) / 4, c(2000, 2000))
  expect_true(all(table(data$id) == 4))
  observed <- tapply(data$y, list(data$A, data$B, data$C), mean)
  expect_lt(max(abs(observed - inputs$means)), 1)
  # Within one group, so the groups' different means don't add to it.
  wide <- data[data$A == 2 & data$B == 1 & data$C == 1, "y"]
  wide2 <- data[data$A == 2 & data$B == 2 & data$C == 2, "y"]
  expect_equal(stats::cor(wide, wide2), 0.5, tolerance = 0.05)
  between <- bfthree_data(800, inputs$means, inputs$sd, c(A = FALSE, B = FALSE, C = FALSE), 0)
  expect_false("id" %in% names(between))
  expect_identical(as.vector(table(between$A, between$B, between$C)), rep(100L, 8))
})

test_that("the effect's Bayes factor is anovaBF()'s inclusion Bayes factor with JASP's priors", {
  set.seed(5)
  inputs <- bfthree_inputs(validate_quietly(bfthree_spec()))
  data <- bfthree_data(16, inputs$means, inputs$sd, inputs$within, inputs$r)
  set.seed(6)
  ours <- bfthree_log_bf(data, "A:B:C", 0.5, "all_models")
  set.seed(6)
  bf <- BayesFactor::anovaBF(y ~ A * B * C + id, data = data, whichRandom = "id", whichModels = "withmain", rscaleFixed = 0.5,
    rscaleRandom = 1, progress = FALSE)
  direct <- bayestestR::bayesfactor_inclusion(bf)
  expect_equal(ours, direct$log_BF[rownames(direct) == "A:B:C"])
  # Every model that respects marginality: 18 besides the participants-only
  # model.
  expect_length(bf, 18)
})

test_that("a run gives power, the no-effect side and a check run that recovers the inputs", {
  skip_on_cran()
  result <- run_quietly(bfthree_spec(within = character(), effect = "main_effect_C", n = 80))
  expect_identical(result$provenance$backend, "BayesFactor")
  expect_true(result$curve$power > 0.3 && result$curve$power <= 1)
  expect_true(all(result$check_run$ok))
  expect_lte(result$bayes$misleading_evidence, 0.15)
})

test_that("a sample size search keeps the groups equal", {
  spec <- bfthree_spec()
  spec$goal <- list(type = "sample_size", power = 0.8)
  expect_identical(bfthree_backend(validate_quietly(spec))$n_step, 2)
  spec <- bfthree_spec(within = character())
  spec$goal <- list(type = "sample_size", power = 0.8)
  expect_identical(bfthree_backend(validate_quietly(spec))$n_step, 8)
})

test_that("problems are named in plain words", {
  spec <- bfthree_spec(within = character())
  spec$population <- list(metric = "eta_squared", eta_squared = 0.06)
  expect_spec_problem(spec, "Partial eta-squared works only with the ANOVA F test")
  expect_spec_problem(bfthree_spec(prior_width = 1), "remove the other prior settings")
  expect_spec_problem(bfthree_spec(correction = "GG"), "'target_test > correction' only applies")
  spec <- bfthree_spec()
  spec$options$method <- "exact"
  expect_spec_problem(spec, "is simulated; remove 'options > method'")
})

test_that("the R script reproduces the run", {
  skip_unless_scripts_can_run()
  spec <- bfthree_spec(within = character(), effect = "main_effect_C", n = 40)
  run <- expect_script_reproduces_power(spec, run_quietly(spec))
  expect_true(any(grepl("anovaBF(", run$script, fixed = TRUE)))
})
