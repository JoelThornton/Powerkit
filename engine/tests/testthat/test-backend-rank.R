# Rank tests via Spower: the Wilcoxon signed-rank test (one sample,
# paired), the Mann-Whitney test and the Kruskal-Wallis test. Translation,
# check runs, refusals and the exported script. Few replications; accuracy
# is checked by test-validation-rank-tests.R.

rank_spec <- function(template, method, shape = NULL, n = 120, nrep = 100, ...) {
  name <- if (template == "oneway_between") "anova_oneway_between" else template
  spec <- example_spec(name)
  spec$target_test$method <- method
  spec$population$score_shape <- shape
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  changes <- list(...)
  spec[names(changes)] <- changes
  spec
}

rank_cases <- list(
  list("one_sample_t", "wilcoxon_signed_rank", "heavy_tailed"),
  list("paired_t", "wilcoxon_signed_rank", "normal"),
  list("independent_t", "mann_whitney", "skewed"),
  list("oneway_between", "kruskal_wallis", "skewed")
)

test_that("every rank test runs on Spower by simulation and passes its check run", {
  for (case in rank_cases) {
    spec <- rank_spec(case[[1]], case[[2]], case[[3]])
    result <- run_quietly(spec)
    expect_equal(result$provenance$backend, "Spower", label = case[[1]])
    expect_equal(result$provenance$method, "simulation", label = case[[1]])
    expect_true(all(result$check_run$ok), label = case[[1]])
    expect_match(result$provenance$backend_function, if (case[[1]] == "oneway_between") "p_kruskal.test" else "p_wilcox.test")
  }
})

test_that("on one core, a rank test equals a direct Spower call", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  # One sample, heavy-tailed: the scores are d plus t (3 df) / sqrt(3).
  spec <- rank_spec("one_sample_t", "wilcoxon_signed_rank", "heavy_tailed", n = 40, nrep = 200)
  set.seed(7)
  direct <- Spower::Spower(
    Spower::p_wilcox.test(
      n = 40, d = 0.3, type = "one.sample",
      parent1 = function(n, d) d + stats::rt(n, df = 3) / sqrt(3)
    ),
    replications = 200, verbose = FALSE
  )
  expect_equal(run_quietly(spec)$curve$power, direct$power)
  # Two groups, skewed: Spower's own example parents, with the spec's d
  # (group 2 minus group 1) reversed into group 1.
  spec <- rank_spec("independent_t", "mann_whitney", "skewed", n = 100, nrep = 200)
  set.seed(7)
  direct <- Spower::Spower(
    Spower::p_wilcox.test(
      n = 50, d = -0.4,
      parent1 = function(n, d) (stats::rchisq(n, df = 10) - 10) / sqrt(20) + d,
      parent2 = function(n, d) (stats::rchisq(n, df = 10) - 10) / sqrt(20)
    ),
    replications = 200, verbose = FALSE
  )
  expect_equal(run_quietly(spec)$curve$power, direct$power)
  # Kruskal-Wallis, normal scores: Spower's default generator, with the
  # means over the SD and n per group.
  spec <- rank_spec("oneway_between", "kruskal_wallis", "normal", n = 90, nrep = 200)
  # Spower reads vector arguments by name.
  means <- c(10, 11, 13) / 6
  set.seed(7)
  direct <- Spower::Spower(
    Spower::p_kruskal.test(n = 30, k = 3, means = means),
    replications = 200, verbose = FALSE
  )
  expect_equal(run_quietly(spec)$curve$power, direct$power)
})

test_that("rank tests are translated to Spower's parametrisation", {
  args <- function(spec) {
    spec <- validate_quietly(spec)
    spower_inputs(spec)$args(spec$goal$n)
  }
  # Paired: the differences are drawn directly (second sample 0), shifted
  # by -dz (Spower compares first with second).
  paired <- args(rank_spec("paired_t", "wilcoxon_signed_rank", n = 40))
  expect_equal(paired[c("n", "d", "type")], list(n = 40, d = -0.35, type = "paired"))
  expect_equal(paired$parent2(5, 1), rep(0, 5))
  # Unequal groups: n is group 1's size and n2_n1 the ratio.
  spec <- rank_spec("independent_t", "mann_whitney", n = 150)
  spec$options$allocation_ratio <- 2
  expect_equal(args(spec)[c("n", "d", "n2_n1")], list(n = 50, d = -0.4, n2_n1 = 2))
  # Kruskal-Wallis: n per group, means in SD units.
  kw <- args(rank_spec("oneway_between", "kruskal_wallis", n = 90))
  expect_equal(kw[c("n", "k", "means")], list(n = 30, k = 3, means = c(10, 11, 13) / 6))
  # Every shape has mean 0 and SD 1.
  for (shape in c("normal", "skewed", "heavy_tailed")) {
    x <- with_seed(1, score_shape_sampler(shape)(2e5))
    expect_equal(mean(x), 0, tolerance = 0.02, label = shape)
    expect_equal(stats::sd(x), 1, tolerance = 0.03, label = shape)
  }
})

test_that("one-sided rank tests use Spower's orientation", {
  spec <- validate_quietly(rank_spec(
    "paired_t", "wilcoxon_signed_rank", n = 40,
    target_test = list(effect = "mean_difference", method = "wilcoxon_signed_rank", alpha = 0.05, alternative = "greater")
  ))
  expect_match(spower_inputs(spec)$description, "alternative = \"less\"", fixed = TRUE)
  spec <- validate_quietly(rank_spec(
    "one_sample_t", "wilcoxon_signed_rank", n = 40,
    target_test = list(effect = "mean", method = "wilcoxon_signed_rank", alpha = 0.05, alternative = "greater")
  ))
  expect_match(spower_inputs(spec)$description, "alternative = \"greater\"", fixed = TRUE)
})

test_that("rank tests have no formula, and the score shape belongs to them alone", {
  spec <- rank_spec("independent_t", "mann_whitney", "skewed")
  spec$options$method <- "exact"
  expect_spec_problem(spec, "'options > method' 'exact' isn't available for this test")
  spec <- rank_spec("oneway_between", "kruskal_wallis")
  spec$options$method <- "exact"
  expect_spec_problem(spec, "'options > method' 'exact' isn't available for this test")
  spec <- rank_spec("independent_t", "student_t", "skewed")
  expect_spec_problem(spec, "'population > score_shape' is only used by the rank tests")
  spec <- rank_spec("oneway_between", "anova_f", "normal")
  expect_spec_problem(spec, "'population > score_shape' is only used by the rank tests")
  # The signed-rank test assumes symmetric scores, so no skewed shape.
  spec <- rank_spec("one_sample_t", "wilcoxon_signed_rank", "skewed")
  expect_error(validate_quietly(spec), "score_shape")
  # Without options > method, a rank test is simulated.
  spec <- validate_quietly(rank_spec("paired_t", "wilcoxon_signed_rank"))
  expect_true(uses_simulation(spec))
})

test_that("the exported script reproduces each rank test", {
  skip_unless_scripts_can_run()
  for (case in rank_cases) {
    spec <- rank_spec(case[[1]], case[[2]], case[[3]], n = 60, nrep = 100)
    run <- expect_script_reproduces_power(spec, run_for_export(spec))
    expect_match(paste(run$script, collapse = "\n"), "draw_scores", fixed = TRUE)
  }
})
