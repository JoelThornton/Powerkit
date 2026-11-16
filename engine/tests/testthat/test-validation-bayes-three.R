# Validation: the Bayes factor of an effect in a three-factor ANOVA (E56's
# test version), the inclusion Bayes factor JASP's Bayesian ANOVA reports.
#   1. agreement with a simulation written separately: each study's data
#      drawn by hand (equal groups; with a within factor, each person's own
#      level giving the correlation r between any two of their scores),
#      every model that respects marginality written out and fitted on its
#      own with BayesFactor's lmBF() (an interaction only with every effect
#      it contains; with repeated measures the participants in every
#      model), and the inclusion Bayes factor across all models computed by
#      hand from the models' Bayes factors with uniform model priors
#      (posterior inclusion odds over prior inclusion odds), without
#      anovaBF() or bayestestR; a main effect with every factor between
#      participants, and the three-way interaction with two within factors
#   2. the no-effect side (strong evidence for no effect, and misleading
#      evidence for one) against the same loop with the effect removed
#   3. published example: placeholder for the maintainer
# Both are simulations, so no allowance beyond their Monte Carlo error.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

bf3_spec <- function(means, sd, within, r, effect, n, nrep, threshold = 3, seed = 7501) {
  level <- function(v, k) validation_variable(if (within[[v]]) "within_factor" else "between_factor", v,
    levels = as.list(paste0(tolower(v), seq_len(k))))
  d <- dim(means)
  population <- list(metric = "raw", means = lapply(seq_len(d[1]), function(i) lapply(seq_len(d[2]), function(j) as.list(means[i, j, ]))),
    sd = sd)
  if (any(within)) population$r <- r
  validation_spec(
    design = "factorial_anova", template = "factorial_three",
    variables = list(A = level("A", d[1]), B = level("B", d[2]), C = level("C", d[3]), Y = validation_variable("continuous", "Y")),
    population = population,
    target_test = list(effect = effect, method = "bayes_factor", evidence_threshold = threshold),
    seed = seed, n = n, options = list(nrep = nrep)
  )
}

# Every model that respects marginality, as a list of its terms: each set
# of the seven effects in which every interaction comes with every effect
# it contains.
bf3_models <- function() {
  terms <- c("A", "B", "C", "A:B", "A:C", "B:C", "A:B:C")
  parts <- lapply(terms, function(t) {
    f <- strsplit(t, ":")[[1]]
    if (length(f) == 1) return(character())
    unlist(lapply(seq_len(length(f) - 1), function(k) apply(utils::combn(f, k), 2, paste, collapse = ":")))
  })
  keep <- list()
  for (k in 0:(2^7 - 1)) {
    m <- terms[bitwAnd(k, 2^(0:6)) > 0]
    if (all(vapply(m, function(t) all(parts[[match(t, terms)]] %in% m), logical(1)))) keep[[length(keep) + 1]] <- m
  }
  keep
}

# One study drawn by hand: people split equally across the combinations of
# the between factors, each with every combination of the within factors.
bf3_draw <- function(means, sd, within, r, n) {
  d <- dim(means)
  cells <- expand.grid(A = seq_len(d[1]), B = seq_len(d[2]), C = seq_len(d[3]))
  group_of <- if (any(!within)) interaction(cells[!within], drop = TRUE) else factor(rep(1, nrow(cells)))
  groups <- levels(group_of)
  per_group <- n / length(groups)
  rows <- list()
  person <- 0
  for (g in groups) {
    own <- cells[group_of == g, , drop = FALSE]
    for (i in seq_len(per_group)) {
      person <- person + 1
      rows[[person]] <- data.frame(id = person, own)
    }
  }
  data <- do.call(rbind, rows)
  own_level <- if (any(within)) stats::rnorm(n, 0, sd * sqrt(r)) else rep(0, n)
  data$y <- means[cbind(data$A, data$B, data$C)] + own_level[data$id] +
    stats::rnorm(nrow(data), 0, if (any(within)) sd * sqrt(1 - r) else sd)
  for (v in c("id", "A", "B", "C")) data[[v]] <- factor(data[[v]])
  data
}

bf3_by_hand <- function(means, sd, within, r, term, n, nrep, seed, threshold = 3, outcome = "effect") {
  models <- bf3_models()
  stopifnot(length(models) == 19)
  has <- vapply(models, function(m) term %in% m, logical(1))
  repeated <- any(within)
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    data <- bf3_draw(means, sd, within, r, n)
    base <- if (repeated) {
      BayesFactor::extractBF(BayesFactor::lmBF(y ~ id, data = data, whichRandom = "id", rscaleRandom = 1, progress = FALSE),
        logbf = TRUE)$bf
    } else {
      0
    }
    log_bf <- vapply(models, function(m) {
      if (length(m) == 0) return(base)
      rhs <- paste(c(m, if (repeated) "id"), collapse = " + ")
      fit <- if (repeated) {
        BayesFactor::lmBF(stats::as.formula(paste("y ~", rhs)), data = data, whichRandom = "id", rscaleFixed = 0.5,
          rscaleRandom = 1, progress = FALSE)
      } else {
        BayesFactor::lmBF(stats::as.formula(paste("y ~", rhs)), data = data, rscaleFixed = 0.5, progress = FALSE)
      }
      BayesFactor::extractBF(fit, logbf = TRUE)$bf
    }, numeric(1))
    post <- exp(log_bf - max(log_bf))
    post <- post / sum(post)
    inclusion <- log((sum(post[has]) / sum(post[!has])) / (sum(has) / sum(!has)))
    if (identical(outcome, "effect")) inclusion >= log(threshold) else inclusion <= -log(threshold)
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

bf3_between <- array(c(0, 0, 0, 0, 0.5, 0.5, 0.5, 0.5), dim = c(2, 2, 2))
bf3_mixed <- aperm(array(c(80, 60, 81, 61, 80, 60, 84, 70), dim = c(2, 2, 2)), 3:1)

test_that("Bayes factor three-factor ANOVA effect: agrees with a simulation written separately (simulation)", {
  skip_unless_full_validation()
  cases <- list(
    list(means = bf3_between, sd = 1, within = c(A = FALSE, B = FALSE, C = FALSE), r = 0, effect = "main_effect_C", term = "C",
      n = 80, nrep = 300L),
    list(means = bf3_mixed, sd = 12, within = c(A = FALSE, B = TRUE, C = TRUE), r = 0.5, effect = "interaction_ABC", term = "A:B:C",
      n = 60, nrep = 200L)
  )
  for (i in seq_along(cases)) {
    case <- cases[[i]]
    reference <- bf3_by_hand(case$means, case$sd, case$within, case$r, case$term, case$n, case$nrep, 7510L + i)
    estimate <- engine_power(bf3_spec(case$means, case$sd, case$within, case$r, case$effect, case$n, case$nrep, seed = 7520 + i))
    expect_power_agrees(estimate, reference)
  }
})

test_that("Bayes factor three-factor ANOVA effect: evidence for no effect and misleading evidence agree with the same loop (simulation)", {
  skip_unless_full_validation()
  within <- c(A = FALSE, B = FALSE, C = FALSE)
  result <- engine_function("run_spec")(bf3_spec(bf3_between, 1, within, 0, "main_effect_C", 80, 300L, seed = 7531))
  null_means <- array(0.25, dim = c(2, 2, 2))
  for_null <- bf3_by_hand(null_means, 1, within, 0, "C", 80, 300L, 7532L, outcome = "null")
  misleading <- bf3_by_hand(null_means, 1, within, 0, "C", 80, 300L, 7533L)
  n_null <- result$bayes$null_nrep
  expect_power_agrees(list(power = result$bayes$evidence_for_null,
    mcse = sqrt(result$bayes$evidence_for_null * (1 - result$bayes$evidence_for_null) / n_null)), for_null)
  expect_power_agrees(list(power = result$bayes$misleading_evidence,
    mcse = sqrt(result$bayes$misleading_evidence * (1 - result$bayes$misleading_evidence) / n_null)), misleading)
})

test_that("Bayes factor three-factor ANOVA effect: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE (the maintainer chooses a published
  #   Bayes factor design analysis of a three-factor ANOVA with JASP's
  #   default priors).
  means <- TODO_PUBLISHED_VALUE # array of cell means[A, B, C]
  sd <- TODO_PUBLISHED_VALUE
  within <- TODO_PUBLISHED_VALUE # c(A = , B = , C = ), TRUE for a within factor
  r <- TODO_PUBLISHED_VALUE
  effect <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  threshold <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(means, sd, within, r, effect, n, threshold, published_power, reference_nrep)
  expect_power_near(engine_power(bf3_spec(means, sd, within, r, effect, n, 1000L, threshold, seed = 7541)), published_power,
    reference_nrep = reference_nrep)
})
