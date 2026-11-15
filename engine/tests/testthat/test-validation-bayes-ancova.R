# Validation: the Bayes factor of an effect in an ANCOVA (E23's test
# version), the inclusion Bayes factor JASP's Bayesian ANCOVA reports.
#   1. agreement with a simulation written separately: each study's data
#      drawn by hand (equal cells, independent standard normal covariates
#      explaining the given share of the variance within cells), every
#      model that respects marginality written out and fitted on its own
#      with BayesFactor's lmBF() (the factors in or out, an interaction
#      only with both main effects, each covariate in or out), and the
#      inclusion Bayes factor across all models computed by hand from the
#      models' Bayes factors with uniform model priors (posterior inclusion
#      odds over prior inclusion odds), without generalTestBF() or
#      bayestestR; one factor with one and with two covariates, and an
#      interaction in a two-factor ANCOVA
#   2. the no-effect side (strong evidence for no effect, and misleading
#      evidence for one) against the same loop with the effect removed
#   3. published example: placeholder for the maintainer
# Both are simulations, so no allowance beyond their Monte Carlo error.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

bfa_reps <- 1000L

bfa_spec <- function(means, sd, r2, q, effect, n, threshold = 10, seed = 7401) {
  two <- ncol(means) > 1
  variables <- list(A = validation_variable("between_factor", "A", levels = as.list(paste0("a", seq_len(nrow(means))))),
    Y = validation_variable("continuous", "Y"))
  if (two) variables$B <- validation_variable("between_factor", "B", levels = as.list(paste0("b", seq_len(ncol(means)))))
  validation_spec(
    design = "factorial_anova", template = if (two) "factorial_ancova" else "oneway_ancova",
    variables = variables,
    population = list(metric = "raw", means = if (two) lapply(seq_len(nrow(means)), function(i) as.list(means[i, ])) else as.list(means[, 1]),
      sd = sd, r2_covariates = r2, covariates = q),
    target_test = list(effect = effect, method = "bayes_factor", evidence_threshold = threshold),
    seed = seed, n = n, options = list(nrep = bfa_reps)
  )
}

# Every model that respects marginality, as a list of its terms.
bfa_models <- function(two, q) {
  factor_sets <- if (two) list(character(), "A", "B", c("A", "B"), c("A", "B", "A:B")) else list(character(), "A")
  cov_sets <- lapply(0:(2^q - 1), function(k) paste0("cov", seq_len(q))[bitwAnd(k, 2^(seq_len(q) - 1)) > 0])
  models <- list()
  for (f in factor_sets) for (cv in cov_sets) models[[length(models) + 1]] <- c(f, cv)
  models
}

bfa_by_hand <- function(means, sd, r2, q, term, n, nrep, seed, threshold = 10, outcome = "effect") {
  two <- ncol(means) > 1
  per_cell <- n / length(means)
  a <- rep(rep(seq_len(nrow(means)), each = ncol(means)), each = per_cell)
  b <- rep(rep(seq_len(ncol(means)), times = nrow(means)), each = per_cell)
  models <- bfa_models(two, q)
  has <- vapply(models, function(m) term %in% m, logical(1))
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    covs <- matrix(stats::rnorm(length(a) * q), ncol = q, dimnames = list(NULL, paste0("cov", seq_len(q))))
    y <- means[cbind(a, b)] + sd * sqrt(r2 / q) * rowSums(covs) + stats::rnorm(length(a), 0, sd * sqrt(1 - r2))
    data <- data.frame(A = factor(a), B = factor(b), covs, y = y)
    log_bf <- vapply(models, function(m) {
      if (length(m) == 0) return(0)
      fit <- BayesFactor::lmBF(stats::as.formula(paste("y ~", paste(m, collapse = " + "))), data = data,
        rscaleFixed = 0.5, rscaleCont = 0.354, progress = FALSE)
      BayesFactor::extractBF(fit, logbf = TRUE)$bf
    }, numeric(1))
    post <- exp(log_bf - max(log_bf))
    post <- post / sum(post)
    inclusion <- log((sum(post[has]) / sum(post[!has])) / (sum(has) / sum(!has)))
    if (identical(outcome, "effect")) inclusion >= log(threshold) else inclusion <= -log(threshold)
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("Bayes factor ANCOVA effect: agrees with a simulation written separately (simulation)", {
  skip_unless_full_validation()
  cases <- list(
    list(means = matrix(c(20, 18, 16), ncol = 1), sd = 6, r2 = 0.36, q = 1, effect = "main_effect_A", term = "A", n = 120),
    list(means = matrix(c(0, 0.3, 0.5), ncol = 1), sd = 1, r2 = 0.5, q = 2, effect = "main_effect_A", term = "A", n = 90, threshold = 3),
    list(means = matrix(c(20, 20, 20, 16, 17, 18), 2, byrow = TRUE), sd = 6, r2 = 0.36, q = 1, effect = "interaction", term = "A:B", n = 360,
      threshold = 3)
  )
  for (i in seq_along(cases)) {
    case <- cases[[i]]
    threshold <- case$threshold %||% 10
    reference <- bfa_by_hand(case$means, case$sd, case$r2, case$q, case$term, case$n, bfa_reps, 7410L + i, threshold)
    estimate <- engine_power(bfa_spec(case$means, case$sd, case$r2, case$q, case$effect, case$n, threshold, seed = 7420 + i))
    expect_power_agrees(estimate, reference)
  }
})

test_that("Bayes factor ANCOVA effect: evidence for no effect and misleading evidence agree with the same loop (simulation)", {
  skip_unless_full_validation()
  means <- matrix(c(20, 18, 16), ncol = 1)
  result <- engine_function("run_spec")(bfa_spec(means, 6, 0.36, 1, "main_effect_A", 120, seed = 7431))
  null_means <- matrix(18, 3, 1)
  for_null <- bfa_by_hand(null_means, 6, 0.36, 1, "A", 120, bfa_reps, 7432L, outcome = "null")
  misleading <- bfa_by_hand(null_means, 6, 0.36, 1, "A", 120, bfa_reps, 7433L)
  n_null <- result$bayes$null_nrep
  expect_power_agrees(list(power = result$bayes$evidence_for_null,
    mcse = sqrt(result$bayes$evidence_for_null * (1 - result$bayes$evidence_for_null) / n_null)), for_null)
  expect_power_agrees(list(power = result$bayes$misleading_evidence,
    mcse = sqrt(result$bayes$misleading_evidence * (1 - result$bayes$misleading_evidence) / n_null)), misleading)
})

test_that("Bayes factor ANCOVA effect: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE (the maintainer chooses a published
  #   Bayes factor design analysis of an ANCOVA with JASP's default priors).
  means <- TODO_PUBLISHED_VALUE # matrix of adjusted cell means (one column for one factor)
  sd <- TODO_PUBLISHED_VALUE
  r2 <- TODO_PUBLISHED_VALUE
  q <- TODO_PUBLISHED_VALUE
  effect <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  threshold <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(means, sd, r2, q, effect, n, threshold, published_power, reference_nrep)
  expect_power_near(engine_power(bfa_spec(means, sd, r2, q, effect, n, threshold, seed = 7441)), published_power,
    reference_nrep = reference_nrep)
})
