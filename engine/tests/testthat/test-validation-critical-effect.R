# Validation: the critical effect size (critical-effect.R), the closed form
# of Perugini et al. (2025, Table 1). Build guide section 6:
#   1. published examples: placeholders below, for the maintainer
#      (Perugini et al., 2025, pp. 1-3, worked examples)
#   2. an independent check: in simulated studies of the size analysed, an
#      observed effect beyond the critical value is exactly an observed
#      p below alpha, by R's own t.test() and cor.test() (the tests a
#      researcher runs), for each test and side
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

critical_validation_spec <- function(template, n, alternative = "two_sided", ratio = 1) {
  spec <- unclass(read_spec(system.file("specs", paste0(template, ".json"), package = "powerkit"), validate = FALSE))
  if (identical(template, "independent_t")) spec$target_test$method <- "student_t"
  spec$target_test$alternative <- alternative
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 1L)
  if (ratio != 1) spec$options$allocation_ratio <- ratio
  spec
}

# The observed effect and p of one simulated study, as a researcher would
# compute them: Cohen's d with the pooled SD, d_z, d against 0, or r.
critical_simulated_study <- function(template, groups, alternative, effect) {
  alt <- switch(alternative, two_sided = "two.sided", greater = "greater", less = "less")
  switch(template,
    independent_t = {
      x <- stats::rnorm(groups[1]); y <- stats::rnorm(groups[2], effect)
      sp <- sqrt(((groups[1] - 1) * stats::var(x) + (groups[2] - 1) * stats::var(y)) / (sum(groups) - 2))
      c(observed = (mean(y) - mean(x)) / sp, p = stats::t.test(y, x, var.equal = TRUE, alternative = alt)$p.value)
    },
    one_sample_t = , paired_t = {
      z <- stats::rnorm(groups, effect)
      c(observed = mean(z) / stats::sd(z), p = stats::t.test(z, alternative = alt)$p.value)
    },
    correlation = {
      x <- stats::rnorm(groups); y <- effect * x + sqrt(1 - effect^2) * stats::rnorm(groups)
      c(observed = stats::cor(x, y), p = stats::cor.test(x, y, alternative = alt)$p.value)
    }
  )
}

critical_cases <- list(
  list("independent_t", 40, "two_sided", 1, 0.3), list("independent_t", 90, "greater", 2, 0.3),
  list("one_sample_t", 25, "two_sided", 1, 0.3), list("paired_t", 30, "less", 1, -0.3),
  list("correlation", 50, "two_sided", 1, 0.2), list("correlation", 120, "greater", 1, 0.1)
)

for (case in critical_cases) {
  test_that(sprintf("%s, n = %s, %s: an observed effect beyond the critical value is exactly a significant test (analytic)",
                    case[[1]], case[[2]], case[[3]]), {
    skip_unless_full_validation()
    ce <- critical_effect(validate_spec(critical_validation_spec(case[[1]], case[[2]], case[[3]], case[[4]])), case[[2]])
    groups <- ce$groups %||% case[[2]]
    set.seed(9101)
    studies <- t(replicate(5000, critical_simulated_study(case[[1]], groups, case[[3]], case[[5]])))
    beyond <- switch(case[[3]], two_sided = abs(studies[, "observed"]) > ce$value,
      greater = studies[, "observed"] > ce$value, less = studies[, "observed"] < -ce$value)
    # Both sides of the comparison come from the same simulated studies, so
    # agreement must be exact, apart from studies within rounding of the
    # boundary (none expected in 5,000).
    expect_identical(beyond, studies[, "p"] < 0.05)
    expect_gt(mean(beyond), 0.05)
  })
}

test_that("two groups and a correlation: match Perugini et al.'s worked examples (published)", {
  skip_unless_full_validation()
  # Source: Perugini et al. (2025), Advances in Methods and Practices in
  #   Psychological Science, 8(2), the worked examples on pp. 1-3 (a
  #   correlation with n = 20, two groups of 15, and N = 5,000). Transcribe
  #   each design's n (and group sizes), alpha, sides and the critical value
  #   the article reports.
  # Note for the maintainer: the article's example of 42 and 15 participants
  #   (t(55)) reports a critical d of 0.62; Table 1's formula for Student's
  #   t gives 0.603 at those group sizes, so that example may use another
  #   standardiser and is best checked before transcribing.
  template <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  ratio <- TODO_PUBLISHED_VALUE
  published_critical <- TODO_PUBLISHED_VALUE
  skip_if_todo(template, n, ratio, published_critical)
  ce <- critical_effect(validate_spec(critical_validation_spec(template, n, ratio = ratio)), n)
  expect_equal(round(ce$value, 2), published_critical)
})
