# Validation: how often a p-value and a Bayes factor agree on a t-test
# (bayes_companion()'s agreement table, "Plan for both").
#   1. agreement with a simulation written separately: data drawn study by
#      study, the p-value from t.test() and the JZS Bayes factor from
#      BayesFactor's ttestBF() (not bfpwr, which powerkit's bounds use),
#      each study classed by both decisions; a one-sample test two-sided,
#      two groups one-sided, and paired data one-sided towards a negative
#      effect, with and without an effect
#   2. published example: a placeholder for the maintainer
# The simulation is the only random part, so no allowance beyond its Monte
# Carlo error. About a minute. Skipped unless POWERKIT_FULL_VALIDATION=true.

companion_reps <- 4000L

companion_by_hand <- function(type, n, d, alternative, k, alpha, seed) {
  side <- switch(alternative, two_sided = "two.sided", greater = "greater", less = "less")
  interval <- switch(alternative, two_sided = NULL, greater = c(0, Inf), less = c(-Inf, 0))
  with_seed(seed, {
    rows <- lapply(seq_len(companion_reps), function(i) {
      if (type == "two.sample") {
        x <- stats::rnorm(n / 2, d); y <- stats::rnorm(n / 2)
        p <- stats::t.test(x, y, var.equal = TRUE, alternative = side)$p.value
        bf <- BayesFactor::ttestBF(x = x, y = y, rscale = 1 / sqrt(2), nullInterval = interval)
      } else {
        x <- stats::rnorm(n, d)
        p <- stats::t.test(x, alternative = side)$p.value
        bf <- BayesFactor::ttestBF(x = x, rscale = 1 / sqrt(2), nullInterval = interval)
      }
      bf10 <- exp(BayesFactor::extractBF(bf, logbf = TRUE)$bf[1])
      data.frame(p_significant = p < alpha, bayes = if (bf10 >= k) "effect" else if (bf10 <= 1 / k) "null" else "neither")
    })
    do.call(rbind, rows)
  })
}

test_that("p-value and Bayes factor agreement: a simulation written separately", {
  skip_unless_full_validation()
  skip_if_not_installed("BayesFactor")
  cases <- list(
    list(template = "one_sample_t", type = "one.sample", n = 40L, d = 0.4, alternative = "two_sided", k = 3),
    list(template = "independent_t", type = "two.sample", n = 80L, d = 0.5, alternative = "greater", k = 10),
    list(template = "paired_t", type = "paired", n = 60L, d = -0.3, alternative = "less", k = 3)
  )
  for (i in seq_along(cases)) {
    case <- cases[[i]]
    spec <- example_spec(case$template)
    spec$target_test <- list(effect = spec$target_test$effect, method = if (case$type == "two.sample") "student_t" else "t_test",
      alpha = 0.05, alternative = case$alternative)
    if (case$type == "paired") spec$population$dz <- case$d else spec$population$d <- case$d
    spec$population$metric <- "standardised"
    spec$population$raw <- NULL
    spec$options <- NULL
    spec$goal <- list(type = "power", n = case$n)
    table <- engine_function("bayes_companion")(spec, case$n, thresholds = case$k)$agreement
    for (truth in c("effect", "none")) {
      sim <- companion_by_hand(case$type, case$n, if (truth == "effect") case$d else 0, case$alternative, case$k, 0.05, 7500L + 10L * i + (truth == "none"))
      for (j in which(table$truth == truth)) {
        row <- table[j, ]
        observed <- mean(sim$p_significant == row$p_significant & sim$bayes == row$bayes)
        allowance <- 4 * sqrt(max(row$probability * (1 - row$probability), 1e-4) / companion_reps)
        expect_lt(abs(observed - row$probability), allowance,
          label = sprintf("%s, %s, p %s, BF %s: %.4f against %.4f", case$template, truth,
            if (row$p_significant) "significant" else "not", row$bayes, observed, row$probability))
      }
    }
  }
})

test_that("p-value and Bayes factor agreement: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published comparison of p-value and Bayes
  # factor decisions for a t-test at a planned sample size; section, page).
  n <- TODO_PUBLISHED_VALUE
  published_both <- TODO_PUBLISHED_VALUE
  skip_if_todo(n, published_both)
  spec <- example_spec("one_sample_t")
  table <- engine_function("bayes_companion")(spec, n, thresholds = 3)$agreement
  both <- sum(table$probability[table$truth == "effect" & table$p_significant & table$bayes == "effect"])
  expect_equal(both, published_both, tolerance = 0.01)
})
