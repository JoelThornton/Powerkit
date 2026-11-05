# What a Bayes factor would add to a p-value plan (bayes_companion()).

companion_t_spec <- function(template = "independent_t", alternative = "two_sided", effect = 0.5) {
  spec <- example_spec(template)
  spec$target_test$alpha <- 0.05
  spec$target_test$alternative <- alternative
  spec$target_test$method <- if (template == "independent_t") "student_t" else "t_test"
  spec$options <- NULL
  if (template == "paired_t") spec$population$dz <- effect else spec$population$d <- effect
  spec$goal <- list(type = "power", n = 100L)
  spec
}

test_that("for a t-test, the agreement table matches each test's own chances", {
  skip_if_not_installed("bfpwr")
  for (tmpl in c("one_sample_t", "independent_t")) for (alt in c("two_sided", "greater", "less")) {
    effect <- if (alt == "less") -0.4 else 0.4
    spec <- companion_t_spec(tmpl, alt, effect)
    x <- bayes_companion(spec, 100)
    expect_true(x$available)
    for (k in x$thresholds) {
      a <- x$agreement[x$agreement$threshold == k, ]
      o <- x$outcomes[x$outcomes$threshold == k, ]
      eff <- a[a$truth == "effect", ]; none <- a[a$truth == "none", ]
      label <- paste(tmpl, alt, k)
      expect_equal(sum(eff$probability), 1, tolerance = 1e-6, label = label)
      expect_equal(sum(none$probability), 1, tolerance = 1e-6, label = label)
      # The p-value's chances: alpha with no effect, the t-test's power
      # (run_spec(), pwr) with the effect.
      expect_equal(sum(none$probability[none$p_significant]), 0.05, tolerance = 1e-6, label = label)
      freq <- run_spec(spec)$curve$power[1]
      expect_equal(sum(eff$probability[eff$p_significant]), freq, tolerance = 1e-4, label = label)
      # The Bayes factor's chances: bfpwr's, through the Bayes factor
      # version. The table is exact (the t distribution); bfpwr's closed
      # form is a normal approximation, slightly low (Known difference 6),
      # within a point at 100 participants.
      expect_lt(abs(sum(eff$probability[eff$bayes == "effect"]) - o$for_effect), 0.01, label = label)
      expect_lt(abs(sum(none$probability[none$bayes == "null"]) - o$for_null), 0.01, label = label)
      expect_lt(abs(sum(none$probability[none$bayes == "effect"]) - o$misleading), 0.01, label = label)
    }
  }
})

test_that("planning for both takes the larger sample size, and plans without a Bayes counterpart say why", {
  skip_if_not_installed("bfpwr")
  spec <- companion_t_spec("one_sample_t")
  x <- bayes_companion(spec, 52, target = 0.8)
  expect_true(all(x$n_for_both$n_both == pmax(52, x$n_for_both$n_bayes)))
  b <- companion_spec(spec)
  b$target_test$evidence_threshold <- 3
  b$goal <- list(type = "sample_size", power = 0.8)
  expect_equal(x$n_for_both$n_bayes[x$n_for_both$threshold == 3], run_spec(b)$n_required$n)
  # Welch's t-test with unequal SDs has no Bayes factor counterpart here.
  w <- companion_t_spec("independent_t")
  w$target_test$method <- "welch_t"
  w$population$sd_ratio <- 1.5
  y <- bayes_companion(w, 100)
  expect_false(y$available)
  expect_match(y$reason, "SDs are equal", fixed = TRUE)
  # Equal SDs under Welch's test: the Student counterpart.
  w$population$sd_ratio <- 1
  expect_true(bayes_companion(w, 100)$available)
  # Designs or tests without one: nothing to show.
  r <- companion_t_spec("one_sample_t"); r$target_test$method <- "wilcoxon_signed_rank"
  expect_null(bayes_companion(r, 100))
  r$target_test$method <- "bayes_factor"
  expect_null(bayes_companion(r, 100))
})
