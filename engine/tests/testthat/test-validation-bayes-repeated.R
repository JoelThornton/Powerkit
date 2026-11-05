# Validation: the Bayes factor of an effect in a repeated-measures ANOVA
# (E8, E54, E55, E20's test version), the inclusion Bayes factor JASP's
# Bayesian repeated-measures ANOVA reports.
#   1. agreement with a simulation written separately: each person's scores
#      drawn by hand from a multivariate normal with the cells' means, one
#      SD and correlation r between any two of their scores
#      (MASS::mvrnorm(), not powerkit's generator), anovaBF() with the
#      participants as a random factor, and the inclusion Bayes factor
#      across all models computed by hand from the models' Bayes factors;
#      a two-factor within-participants design and a 2 x 2 mixed design
#   2. published example: a placeholder for the maintainer
# Both are simulations, so no allowance beyond their Monte Carlo error.
# About 0.8 s per simulated study. Skipped unless
# POWERKIT_FULL_VALIDATION=true.

bfr_reps <- 400L

bfr_spec <- function(file, means, effect, n, seed) {
  spec <- engine_function("read_spec")(system.file("specs", paste0(file, ".json"), package = "powerkit"))
  spec$population$means <- lapply(seq_len(nrow(means)), function(i) as.list(means[i, ]))
  spec$target_test <- list(effect = effect, method = "bayes_factor", evidence_threshold = 10)
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = bfr_reps, seed = seed)
  spec$effect_justification <- list(type = "smallest_effect_of_interest", source = "powerkit validation benchmark (not a real study)")
  spec
}

bfr_by_hand <- function(means, sd, r, between_a, term, n, nrep, seed) {
  a <- nrow(means)
  b <- ncol(means)
  k <- if (between_a) b else a * b
  sigma <- sd^2 * (matrix(r, k, k) + diag(1 - r, k))
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    if (between_a) {
      per_group <- n / a
      rows <- lapply(seq_len(a), function(g) {
        y <- MASS::mvrnorm(per_group, means[g, ], sigma)
        data.frame(id = rep((g - 1) * per_group + seq_len(per_group), times = b), A = g, B = rep(seq_len(b), each = per_group), y = as.vector(y))
      })
      data <- do.call(rbind, rows)
    } else {
      y <- MASS::mvrnorm(n, as.vector(t(means)), sigma)
      cells <- expand.grid(B = seq_len(b), A = seq_len(a))
      data <- data.frame(id = rep(seq_len(n), times = k), A = rep(cells$A, each = n), B = rep(cells$B, each = n), y = as.vector(y))
    }
    data[c("id", "A", "B")] <- lapply(data[c("id", "A", "B")], factor)
    bf <- BayesFactor::anovaBF(y ~ A * B + id, data = data, whichRandom = "id", whichModels = "withmain",
      rscaleFixed = 0.5, rscaleRandom = 1, progress = FALSE)
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

test_that("Bayes factor, repeated measures: agrees with a simulation written separately (simulation)", {
  skip_unless_full_validation()
  skip_if_not_installed("MASS")
  cases <- list(
    list(file = "anova_factorial_within", means = matrix(c(0, 0, 0, 0, 0.25, 0.5), 2, byrow = TRUE), sd = 1, r = 0.6,
      between_a = FALSE, effect = "interaction", term = "A:B", n = 40),
    list(file = "anova_2x2_mixed", means = matrix(c(0, 0, 0, -0.5), 2, byrow = TRUE), sd = 1, r = 0.6,
      between_a = TRUE, effect = "interaction", term = "A:B", n = 80)
  )
  for (i in seq_along(cases)) {
    case <- cases[[i]]
    spec <- bfr_spec(case$file, case$means, case$effect, case$n, 7400L + i)
    spec$population$sd <- case$sd
    spec$population$r <- case$r
    spec$population$metric <- "standardised"
    reference <- bfr_by_hand(case$means, case$sd, case$r, case$between_a, case$term, case$n, bfr_reps, 7410L + i)
    expect_power_agrees(engine_power(spec), reference)
  }
})

test_that("Bayes factor, repeated measures: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published design analysis for a Bayesian
  # repeated-measures ANOVA effect; section, page).
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(n, published_power)
  estimate <- engine_power(bfr_spec("anova_factorial_within", matrix(c(0, 0, 0, 0, 0.25, 0.5), 2, byrow = TRUE), "interaction", n, 7420L))
  expect_power_near(estimate, published_power, reference_nrep = bfr_reps)
})
