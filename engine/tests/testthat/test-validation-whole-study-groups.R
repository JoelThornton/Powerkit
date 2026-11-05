# Validation: the whole-study simulation with a two-group X correlated with
# the moderator W or the baseline B (experimental; docs/conventions.md,
# Departure 13), as for non-randomised groups. powerkit draws W and B from
# X in the population, supplies every residual variance from the exact
# moments of the products (whole_study_moments()) and switches power4mome's
# own standardisation off.
#
# Checked against a simulation written separately: X drawn as two groups
# and standardised, W and B drawn from it with the correlations entered,
# Y's residual SD found numerically from a million draws (so not from
# powerkit's moments), each analysis fitted by lm() as on its own, and the
# joint power counted in the same replications. Both are simulations, so
# no allowance beyond their Monte Carlo error.
#
# Run as part of the whole-study chunk: scripts/run-validation.R --only
# whole_study. Skipped unless POWERKIT_FULL_VALIDATION=true.

groups_spec <- function(x_prob, correlations, paths, baseline, n, seed) {
  variables <- list(X = list(type = "binary", label = "Group"), W = list(type = "continuous", label = "Moderator"),
    Y = list(type = "continuous", label = "Outcome"))
  if (baseline) variables$B <- list(type = "continuous", label = "Before")
  validate_whole_study(list(
    spec_version = "0.1", kind = "whole_study", variables = variables,
    population = list(paths = paths, correlations = correlations, x_prob = x_prob),
    analyses = list(
      list(id = "compare", label = "Groups", test = "x_y", role = "main"),
      list(id = "moderation", label = "Moderation", test = "interaction", role = "main")
    ),
    claim = "all", alpha = 0.05,
    effect_justification = list(type = "smallest_effect_of_interest", source = "powerkit validation benchmark (not a real study)"),
    goal = list(type = "power", n = n),
    options = list(nrep = validation_nrep(), seed = seed)
  ))
}

groups_by_hand <- function(x_prob, correlations, paths, baseline, n, nrep, seed) {
  r <- function(key) correlations[[key]] %||% 0
  draw <- function(m) {
    x <- (stats::rbinom(m, 1, x_prob) - x_prob) / sqrt(x_prob * (1 - x_prob))
    w <- r("X<->W") * x + sqrt(1 - r("X<->W")^2) * stats::rnorm(m)
    out <- data.frame(X = x, W = w)
    if (baseline) {
      beta <- solve(matrix(c(1, r("X<->W"), r("X<->W"), 1), 2), c(r("X<->B"), r("W<->B")))
      out$B <- beta[1] * x + beta[2] * w + sqrt(1 - drop(t(beta) %*% matrix(c(1, r("X<->W"), r("X<->W"), 1), 2) %*% beta)) * stats::rnorm(m)
    }
    out
  }
  mean_y <- function(d) {
    paths[["X->Y"]] * d$X + paths[["W->Y"]] * d$W + paths[["XW->Y"]] * d$X * d$W + (if (baseline) paths[["B->Y"]] * d$B else 0)
  }
  residual_sd <- with_seed(seed, sqrt(1 - stats::var(mean_y(draw(1e6)))))
  with_seed(seed + 1L, {
    hits <- t(vapply(seq_len(nrep), function(i) {
      d <- draw(n)
      d$Y <- mean_y(d) + residual_sd * stats::rnorm(n)
      b <- if (baseline) " + B" else ""
      p1 <- summary(stats::lm(stats::as.formula(paste0("Y ~ X", b)), data = d))$coefficients["X", 4]
      p2 <- summary(stats::lm(stats::as.formula(paste0("Y ~ X * W", b)), data = d))$coefficients["X:W", 4]
      c(p1 < 0.05, p2 < 0.05)
    }, logical(2)))
  })
  estimate <- function(x) list(power = mean(x), mcse = sqrt(mean(x) * (1 - mean(x)) / nrep))
  list(compare = estimate(hits[, 1]), moderation = estimate(hits[, 2]), joint = estimate(hits[, 1] & hits[, 2]))
}

groups_estimates <- function(result) {
  row <- function(id) {
    a <- result$analyses[result$analyses$id == id, ]
    list(power = a$power, mcse = a$mcse)
  }
  list(compare = row("compare"), moderation = row("moderation"),
    joint = list(power = result$joint$power, mcse = result$joint$mcse))
}

test_that("whole study, a two-group X correlated with W: agrees with a simulation written separately (simulation)", {
  skip_unless_full_validation()
  cases <- list(
    list(x_prob = 0.5, correlations = list("X<->W" = 0.4), paths = list("X->Y" = 0.15, "W->Y" = 0.3, "XW->Y" = -0.15), baseline = FALSE, n = 300),
    list(x_prob = 0.25, correlations = list("X<->W" = -0.3), paths = list("X->Y" = 0.2, "W->Y" = 0.2, "XW->Y" = 0.2), baseline = FALSE, n = 250),
    list(x_prob = 0.35, correlations = list("X<->W" = 0.3, "X<->B" = 0.2, "W<->B" = 0.25),
      paths = list("X->Y" = 0.15, "W->Y" = 0.2, "XW->Y" = -0.15, "B->Y" = 0.5), baseline = TRUE, n = 300)
  )
  for (i in seq_along(cases)) {
    case <- cases[[i]]
    spec <- groups_spec(case$x_prob, case$correlations, case$paths, case$baseline, case$n, seed = 900L + i)
    ours <- groups_estimates(run_whole_study(spec))
    reference <- groups_by_hand(case$x_prob, case$correlations, case$paths, case$baseline, case$n, validation_nrep(), 950L + i)
    for (what in c("compare", "moderation", "joint")) {
      expect_power_agrees(ours[[what]], reference[[what]])
    }
  }
})
