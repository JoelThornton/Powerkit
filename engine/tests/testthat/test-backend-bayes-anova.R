# The Bayes factor one-way ANOVA (BayesFactor's oneWayAOV.Fstat(), JASP's
# r scale of 0.5), by exact calculation from the noncentral F.

anova_bf_spec <- function(n = NULL, means = list(0, 0.3, 0.5), sd = 1, threshold = NULL, scale = NULL, power = 0.8) {
  spec <- example_spec("anova_oneway_between")
  spec$population <- list(metric = "raw", means = means, sd = sd)
  spec$variables$A$levels <- as.list(paste0("g", seq_along(means)))
  spec$target_test <- list(effect = "main_effect_A", method = "bayes_factor", evidence_threshold = threshold, prior_scale = scale)
  spec$target_test <- Filter(Negate(is.null), spec$target_test)
  spec$goal <- if (is.null(n)) list(type = "sample_size", power = power) else list(type = "power", n = n)
  spec$options <- NULL
  spec
}

test_that("oneWayAOV.Fstat() gives anovaBF()'s Bayes factor, with JASP's r scale of 0.5 by default", {
  inputs <- bfanova_inputs(anova_bf_spec(90))
  expect_equal(inputs$prior_scale, 0.5)
  set.seed(4)
  data <- data.frame(g = factor(rep(1:3, each = 30)), y = stats::rnorm(90) + rep(c(0, 0.3, 0.5), each = 30))
  f_stat <- stats::anova(stats::lm(y ~ g, data))[["F value"]][1]
  bf <- BayesFactor::extractBF(BayesFactor::anovaBF(y ~ g, data = data, rscaleFixed = 0.5, progress = FALSE), logbf = TRUE)$bf
  expect_equal(bfanova_log_bf10(f_stat, 30, inputs), bf, tolerance = 1e-8)
})

test_that("power is the chance of an F beyond the one where BF10 reaches the threshold", {
  spec <- anova_bf_spec(150)
  inputs <- bfanova_inputs(spec)
  f_star <- bfanova_f_at(log(10), 50, inputs)
  expect_equal(exp(bfanova_log_bf10(f_star, 50, inputs)), 10, tolerance = 1e-6)
  result <- run_spec(spec)
  expect_equal(result$curve$power, stats::pf(f_star, 2, 147, ncp = inputs$f^2 * 150, lower.tail = FALSE))
  expect_true(all(result$check_run$ok))
  expect_equal(result$bayes$misleading_evidence, stats::pf(f_star, 2, 147, lower.tail = FALSE))
  expect_gt(result$bayes$evidence_for_null, 0)
  # A wider prior and a higher threshold both need more evidence here.
  expect_lt(run_spec(anova_bf_spec(150, threshold = 30))$curve$power, result$curve$power)
})

test_that("the sample size is in whole groups and the script reproduces it", {
  spec <- anova_bf_spec()
  result <- run_spec(spec)
  expect_equal(result$n_required$n %% 3, 0)
  expect_gte(bfanova_power(bfanova_inputs(spec), result$n_required$n), 0.8)
  expect_lt(bfanova_power(bfanova_inputs(spec), result$n_required$n - 3), 0.8)
})

test_that("the exported script reproduces the Bayes factor ANOVA", {
  skip_unless_scripts_can_run()
  spec <- anova_bf_spec(150)
  run <- expect_script_reproduces_power(spec, run_for_export(spec))
  expect_match(paste(run$script, collapse = "\n"), "oneWayAOV.Fstat", fixed = TRUE)
})

test_that("the Bayes factor ANOVA is refused where it doesn't apply", {
  spec <- anova_bf_spec(90)
  spec$target_test$alternative <- "greater"
  expect_spec_problem(spec, "two_sided")
  spec <- anova_bf_spec(90)
  spec$target_test$alpha <- 0.05
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})

# The Bayes factor of an effect in a two-factor between-participants ANOVA
# (5 November 2026): JASP's inclusion Bayes factor, simulated with Spower.

bff_example <- function(effect = "interaction", inclusion = NULL, n = 200L) {
  spec <- example_spec("anova_2x2_between")
  spec$target_test <- list(effect = effect, method = "bayes_factor", evidence_threshold = 10)
  if (!is.null(inclusion)) spec$target_test$inclusion <- inclusion
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = 100L, seed = 5L)
  spec
}

test_that("a factorial ANOVA's Bayes factor runs on BayesFactor and bayestestR, with the no-effect side", {
  result <- run_quietly(bff_example())
  expect_identical(result$provenance$backend, "BayesFactor")
  expect_true(all(c("BayesFactor", "bayestestR") %in% names(result$provenance$packages)))
  expect_true(all(result$check_run$ok))
  expect_identical(result$bayes$inclusion, "all_models")
  expect_identical(result$bayes$null_nrep, 100L)
  expect_lt(result$bayes$misleading_evidence, 0.05)
})

test_that("the no-effect side removes only the tested effect from the cell means", {
  means <- matrix(c(10, 10, 10, 13), 2, byrow = TRUE)
  additive <- bffactorial_null_means(means, "A:B")
  expect_equal(additive[1, 1] - additive[1, 2], additive[2, 1] - additive[2, 2])
  no_a <- bffactorial_null_means(means, "A")
  expect_equal(rowMeans(no_a)[1], rowMeans(no_a)[2])
  # The interaction is kept when A's main effect is removed.
  expect_equal(no_a[1, 1] - no_a[1, 2] - no_a[2, 1] + no_a[2, 2], means[1, 1] - means[1, 2] - means[2, 1] + means[2, 2])
})

test_that("bayestestR's inclusion Bayes factor across all models is posterior over prior inclusion odds", {
  set.seed(11)
  data <- bffactorial_data(120, matrix(c(0, 0, 0, 0.6), 2, byrow = TRUE), 1, matrix(1, 2, 2))
  bf <- BayesFactor::anovaBF(y ~ A * B, data = data, whichModels = "withmain", rscaleFixed = 0.5, progress = FALSE)
  log_bf <- c(0, BayesFactor::extractBF(bf, logbf = TRUE)$bf)
  post <- exp(log_bf - max(log_bf))
  post <- post / sum(post)
  has <- grepl(":", c("", names(bf)$numerator), fixed = TRUE)
  by_hand <- log((sum(post[has]) / sum(post[!has])) / (sum(has) / sum(!has)))
  inc <- bayestestR::bayesfactor_inclusion(bf, match_models = FALSE)
  expect_equal(inc$log_BF[rownames(inc) == "A:B"], by_hand, tolerance = 1e-8)
})

test_that("plain-English refusals for a factorial ANOVA's Bayes factor", {
  spec <- bff_example()
  spec$target_test$alternative <- "greater"
  expect_spec_problem(spec, "must be 'two_sided'")
  spec <- bff_example()
  spec$options$method <- "exact"
  expect_spec_problem(spec, "is simulated")
})

test_that("the R script reproduces the factorial Bayes factor run", {
  skip_unless_scripts_can_run()
  spec <- bff_example(n = 120L)
  out <- run_exported_script(spec, run_quietly(spec))
  expect_equal(out$reproduced, out$powerkit, tolerance = 1e-8)
})

# Repeated measures (5 November 2026): participants a random factor, one
# correlation r between a person's scores. A full run takes minutes (about
# 0.8 s per simulated study), so the parts are tested directly here and the
# whole in test-validation-bayes-repeated.R.

bfr_spec <- function(file, effect = NULL) {
  spec <- example_spec(file)
  spec$target_test <- list(effect = effect %||% spec$target_test$effect, method = "bayes_factor", evidence_threshold = 10)
  validate_spec(spec)
}

test_that("repeated measures: each person's scores share their level, with the spec's correlation", {
  inputs <- bffactorial_inputs(bfr_spec("anova_factorial_within"))
  expect_true(all(inputs$within))
  data <- with_seed(3, bffactorial_data_within(4000, inputs$means, inputs$sd, inputs$within, inputs$r))
  expect_equal(nrow(data), 4000 * length(inputs$means))
  wide <- tapply(data$y, list(data$id, interaction(data$A, data$B)), mean)
  expect_equal(stats::cor(wide[, 1], wide[, 2]), inputs$r, tolerance = 0.03)
  expect_equal(unname(colMeans(wide)), as.vector(inputs$means), tolerance = 4 * inputs$sd / sqrt(4000))
  # A mixed design: each person in one group, with all the within cells.
  mixed <- bffactorial_inputs(bfr_spec("anova_mixed"))
  expect_identical(unname(mixed$within), c(FALSE, TRUE))
  data <- with_seed(3, bffactorial_data_within(60, mixed$means, mixed$sd, mixed$within, mixed$r))
  expect_true(all(tapply(as.integer(data$A), data$id, function(a) length(unique(a))) == 1))
  expect_equal(as.vector(table(data$A)), c(30, 30) * ncol(mixed$means))
})

test_that("repeated measures: anovaBF() takes the participants as a random factor, and the check run recovers the population", {
  for (file in c("anova_oneway_within", "anova_2x2_mixed")) {
    spec <- bfr_spec(file)
    inputs <- bffactorial_inputs(spec)
    check <- bffactorial_check_run(spec, inputs, 7L)
    expect_true(all(check$ok), label = file)
    expect_true("Correlation of a person's scores in two cells" %in% check$parameter, label = file)
  }
})

test_that("repeated measures: the Bayes factor needs one non-negative correlation and equal groups", {
  spec <- example_spec("anova_mixed")
  spec$target_test <- list(effect = "interaction", method = "bayes_factor", evidence_threshold = 10)
  spec$population$r <- -0.2
  expect_spec_problem(spec, "one correlation between a person's scores")
  spec$population$r <- 0.5
  spec$options$group_ratio <- list(1, 2)
  expect_spec_problem(spec, "groups of equal size")
})
