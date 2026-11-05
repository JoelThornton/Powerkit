# Validation: the Bayes factor of an effect in a two-factor
# between-participants ANOVA (E7, E21, E22's test version), the inclusion
# Bayes factor JASP reports.
#   1. agreement with a simulation written separately: each study's data
#      drawn by hand, anovaBF() fitted over the models that respect
#      marginality, and the inclusion Bayes factor across all models
#      computed by hand from the models' Bayes factors with uniform model
#      priors (posterior inclusion odds over prior inclusion odds), without
#      bayestestR; for an interaction and a main effect, equal and unequal
#      cells
#   2. bayestestR's across-matched-models option against the same loop
#      with bayestestR's function, as a check that the option reaches it
#   3. published example: JASP's Bayesian ANOVA tutorial; placeholder for
#      the maintainer
# Both are simulations, so no allowance beyond their Monte Carlo error.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

bff_reps <- 1000L

bff_spec <- function(means, sd, effect, n, ratio = NULL, inclusion = "all_models", seed = 7301) {
  a <- nrow(means)
  b <- ncol(means)
  template <- if (a == 2 && b == 2) "2x2_between" else "factorial_between"
  spec <- validation_spec(
    design = "factorial_anova", template = template,
    variables = list(A = validation_variable("between_factor", "A", levels = as.list(paste0("a", seq_len(a)))),
      B = validation_variable("between_factor", "B", levels = as.list(paste0("b", seq_len(b)))),
      Y = validation_variable("continuous", "Y")),
    population = list(metric = "raw", means = lapply(seq_len(a), function(i) as.list(means[i, ])), sd = sd),
    target_test = list(effect = effect, method = "bayes_factor", evidence_threshold = 10, inclusion = inclusion),
    seed = seed, n = n, options = list(nrep = bff_reps)
  )
  if (!is.null(ratio)) spec$options$cell_ratio <- lapply(seq_len(a), function(i) as.list(ratio[i, ]))
  spec
}

bff_by_hand <- function(means, sd, term, n, nrep, seed, ratio = matrix(1, nrow(means), ncol(means)), matched = FALSE) {
  per_cell <- round(n * as.vector(t(ratio)) / sum(ratio))
  cell_a <- rep(seq_len(nrow(means)), each = ncol(means))
  cell_b <- rep(seq_len(ncol(means)), times = nrow(means))
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    a <- rep(cell_a, per_cell)
    b <- rep(cell_b, per_cell)
    data <- data.frame(A = factor(a), B = factor(b), y = means[cbind(a, b)] + stats::rnorm(length(a), 0, sd))
    bf <- BayesFactor::anovaBF(y ~ A * B, data = data, whichModels = "withmain", rscaleFixed = 0.5, progress = FALSE)
    if (matched) {
      inc <- bayestestR::bayesfactor_inclusion(bf, match_models = TRUE)
      return(inc$log_BF[rownames(inc) == term] >= log(10))
    }
    log_bf <- c(0, BayesFactor::extractBF(bf, logbf = TRUE)$bf)
    terms <- c("", names(bf)$numerator)
    has <- vapply(strsplit(gsub(" ", "", terms), "+", fixed = TRUE), function(parts) {
      any(vapply(parts, function(p) setequal(strsplit(p, ":", fixed = TRUE)[[1]], strsplit(term, ":", fixed = TRUE)[[1]]), logical(1)))
    }, logical(1))
    post <- exp(log_bf - max(log_bf))
    post <- post / sum(post)
    log((sum(post[has]) / sum(post[!has])) / (sum(has) / sum(!has))) >= log(10)
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("Bayes factor ANOVA effect: agrees with a simulation written separately (simulation)", {
  skip_unless_full_validation()
  cases <- list(
    list(means = matrix(c(10, 10, 10, 13), 2, byrow = TRUE), sd = 6, effect = "interaction", term = "A:B", n = 400),
    list(means = matrix(c(0, 0.2, 0.4, 0.1, 0.3, 0.5), 2, byrow = TRUE), sd = 1, effect = "main_effect_A", term = "A", n = 150),
    list(means = matrix(c(20, 18, 30, 24), 2, byrow = TRUE), sd = 8, effect = "interaction", term = "A:B", n = 360,
      ratio = matrix(c(2, 2, 1, 1), 2, byrow = TRUE))
  )
  for (i in seq_along(cases)) {
    case <- cases[[i]]
    ratio <- case$ratio %||% matrix(1, nrow(case$means), ncol(case$means))
    reference <- bff_by_hand(case$means, case$sd, case$term, case$n, bff_reps, 7310L + i, ratio)
    estimate <- engine_power(bff_spec(case$means, case$sd, case$effect, case$n, case$ratio, seed = 7320 + i))
    expect_power_agrees(estimate, reference)
  }
})

test_that("Bayes factor ANOVA effect: the matched-models option agrees with the same loop (simulation)", {
  skip_unless_full_validation()
  means <- matrix(c(10, 10, 10, 13), 2, byrow = TRUE)
  reference <- bff_by_hand(means, 6, "A:B", 400, bff_reps, 7331L, matched = TRUE)
  expect_power_agrees(engine_power(bff_spec(means, 6, "interaction", 400, inclusion = "matched_models", seed = 7332)), reference)
})

test_that("Bayes factor ANOVA effect: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published design analysis for a factorial
  # Bayesian ANOVA, with its cell means, SD, n and probability of strong
  # evidence; section, page).
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(n, published_power)
  estimate <- engine_power(bff_spec(matrix(c(0, 0, 0, 0.5), 2, byrow = TRUE), 1, "interaction", n))
  expect_power_near(estimate, published_power, reference_nrep = bff_reps)
})
