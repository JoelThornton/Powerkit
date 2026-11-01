# Trend tests, simulated with Spower by powerkit's own experiments: the
# Cochran-Armitage test of a trend in proportions (stats::prop.trend.test())
# and the Jonckheere-Terpstra test of a trend in scores across groups in
# order (PMCMRplus's jonckheereTest()). Few replications; accuracy is
# checked by test-validation-trend.R.

trend_spec <- function(n = 400, nrep = 200, proportions = NULL, scores = "keep") {
  spec <- example_spec("proportion_trend")
  if (!is.null(proportions)) spec$population$proportions <- proportions
  if (is.null(scores)) spec$population$scores <- NULL
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 5, nrep = nrep)
  spec
}

jt_spec <- function(n = 60, nrep = 200, shape = NULL, means = NULL) {
  spec <- example_spec("anova_oneway_between")
  spec$target_test$method <- "jonckheere_terpstra"
  if (!is.null(shape)) spec$population$score_shape <- shape
  if (!is.null(means)) spec$population$means <- means
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 6, nrep = nrep)
  spec
}

test_that("the Cochran-Armitage test runs on Spower, equals a direct call and recovers its proportions", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  result <- run_quietly(trend_spec())
  expect_identical(result$provenance$backend, "Spower")
  expect_match(result$provenance$backend_function, "prop.trend.test", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  expect_equal(nrow(result$check_run), 4)
  # Spower takes vector arguments by name.
  props <- c(0.2, 0.25, 0.3, 0.35)
  sc <- c(0, 1, 2, 3)
  set.seed(5)
  # prop.trend.test() fits its trend with lm() and anova(), which warn on a
  # near-perfect fit of the few group proportions; powerkit silences them.
  direct <- suppressWarnings(Spower::Spower(p_cochran_armitage(n = 100, proportions = props, scores = sc),
    replications = 200, verbose = FALSE))
  expect_equal(result$curve$power, direct$power)
  # Without scores, the groups are scored 1, 2, 3, ... as prop.trend.test() does.
  expect_equal(trend_scores(validate_quietly(trend_spec(scores = NULL))), 1:4)
})

test_that("the Cochran-Armitage experiment is prop.trend.test() on binomial counts", {
  set.seed(9)
  p <- p_cochran_armitage(50, c(0.1, 0.2, 0.4), c(1, 2, 3))
  set.seed(9)
  yes <- stats::rbinom(3, 50, c(0.1, 0.2, 0.4))
  expect_equal(p, stats::prop.trend.test(yes, rep(50, 3), score = c(1, 2, 3))$p.value)
})

test_that("the Cochran-Armitage test holds alpha when the proportions are equal", {
  spec <- trend_spec(n = 300, nrep = 2000, proportions = list(0.3, 0.3, 0.3, 0.3))
  expect_lt(abs(run_quietly(spec)$curve$power - 0.05), 0.02)
})

test_that("Cochran-Armitage specs are refused in plain English when they can't be run", {
  wrong <- trend_spec()
  wrong$population$proportions <- list(0.2, 0.3, 0.4)
  expect_spec_problem(wrong, "should have one proportion per group")
  flat <- trend_spec()
  flat$population$scores <- list(1, 1, 1, 1)
  expect_spec_problem(flat, "are all the same")
  odd <- trend_spec(n = 401)
  expect_spec_problem(odd, "split into 4 equal groups")
  zero <- trend_spec(proportions = list(0.3, 0.3, 0.3, 0.3))
  zero$goal <- list(type = "sample_size", power = 0.8)
  expect_error(validate_spec(zero), class = "powerkit_spec_error")
})

test_that("one-sided Cochran-Armitage tests halve the two-sided p-value in the direction predicted", {
  set.seed(3)
  two <- p_cochran_armitage(60, c(0.2, 0.3, 0.5), c(0, 1, 2))
  set.seed(3)
  up <- p_cochran_armitage(60, c(0.2, 0.3, 0.5), c(0, 1, 2), alternative = "greater")
  set.seed(3)
  down <- p_cochran_armitage(60, c(0.2, 0.3, 0.5), c(0, 1, 2), alternative = "less")
  set.seed(3)
  yes <- stats::rbinom(3, 60, c(0.2, 0.3, 0.5))
  expect_gt(yes[3] / 60, yes[1] / 60)
  expect_equal(up, two / 2)
  expect_equal(down, 1 - two / 2)
  # The Cochran-Armitage z statistic, written out: its one-sided p-value is
  # the same.
  sizes <- rep(60, 3)
  sc <- c(0, 1, 2)
  p_bar <- sum(yes) / sum(sizes)
  s_bar <- sum(sizes * sc) / sum(sizes)
  z <- sum(yes * (sc - s_bar)) / sqrt(p_bar * (1 - p_bar) * sum(sizes * (sc - s_bar)^2))
  expect_equal(up, stats::pnorm(-z))
})

test_that("one-sided and unequal-group trend tests run, equal direct calls and are refused where they don't apply", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  spec <- trend_spec(n = 396)
  spec$target_test$alternative <- "greater"
  spec$options$group_ratio <- list(2, 1, 1, 2)
  spec$options$attrition <- 0.1
  result <- run_quietly(spec)
  expect_match(result$provenance$backend_function, "alternative = \"greater\"", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  props <- c(0.2, 0.25, 0.3, 0.35)
  sc <- c(0, 1, 2, 3)
  w <- c(2, 1, 1, 2)
  set.seed(5)
  direct <- suppressWarnings(Spower::Spower(p_cochran_armitage(n = 66, proportions = props, scores = sc, n.ratios = w,
    alternative = "greater"), replications = 200, verbose = FALSE))
  expect_equal(result$curve$power, direct$power)
  # Each group's recruitment allows for attrition in its own share.
  expect_equal(result$recruitment$groups_recruit, c(147, 74, 74, 147))
  expect_spec_problem(trend_spec(n = 400) |> within(options$group_ratio <- list(2, 1, 1, 2)), "split into 4 whole groups in the ratio 2 : 1 : 1 : 2")
  wrong <- trend_spec()
  wrong$options$group_ratio <- list(1, 2, 1)
  expect_spec_problem(wrong, "one number per group")
  other <- example_spec("anova_oneway_between")
  other$options$group_ratio <- list(1, 1, 2)
  expect_spec_problem(other, "only applies to the trend tests")
  kw <- example_spec("anova_oneway_between")
  kw$target_test$alternative <- "greater"
  expect_error(validate_spec(kw), class = "powerkit_spec_error")

  jt <- jt_spec(n = 60, nrep = 200)
  jt$target_test$alternative <- "greater"
  jt$options$group_ratio <- list(1, 1, 2)
  result <- run_quietly(jt)
  expect_true(all(result$check_run$ok))
  means <- c(10, 11, 13) / 6
  gen <- function(n, k, n.ratios, means, ...) lapply(seq_len(k), function(g) means[g] + stats::rnorm(n * n.ratios[g]))
  w <- c(1, 1, 2)
  set.seed(6)
  direct <- Spower::Spower(p_jonckheere(n = 15, k = 3, means = means, gen_fun = gen, n.ratios = w,
    alternative = "greater"), replications = 200, verbose = FALSE)
  expect_equal(result$curve$power, direct$power)
  # One-sided in the direction of the trend has more power than two-sided.
  jt$target_test$alternative <- NULL
  expect_gt(result$curve$power, run_quietly(jt)$curve$power)
})

test_that("the Jonckheere-Terpstra experiment passes its direction to PMCMRplus", {
  # Given a list of groups, jonckheereTest() ignores `alternative`; given the
  # scores and their groups, it uses it.
  set.seed(4)
  groups <- list(stats::rnorm(20), stats::rnorm(20, 0.4), stats::rnorm(20, 0.8))
  two <- PMCMRplus::jonckheereTest(groups)$p.value
  expect_equal(PMCMRplus::jonckheereTest(groups, alternative = "greater")$p.value, two)
  gen <- function(n, k, n.ratios, means, ...) groups
  expect_equal(p_jonckheere(20, 3, c(0, 0, 0), gen, alternative = "greater"), unname(two) / 2)
  expect_equal(p_jonckheere(20, 3, c(0, 0, 0), gen), unname(two))
})

test_that("the Jonckheere-Terpstra test runs on Spower, equals a direct call and has more power than Kruskal-Wallis for a trend", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  result <- run_quietly(jt_spec(nrep = 400))
  expect_identical(result$provenance$backend, "Spower")
  expect_match(result$provenance$backend_function, "jonckheereTest", fixed = TRUE)
  expect_true("PMCMRplus" %in% names(result$provenance$packages))
  expect_true(all(result$check_run$ok))
  means <- c(10, 11, 13) / 6
  gen <- function(n, k, n.ratios, means, ...) lapply(seq_len(k), function(g) means[g] + stats::rnorm(n * n.ratios[g]))
  set.seed(6)
  direct <- Spower::Spower(p_jonckheere(n = 20, k = 3, means = means, gen_fun = gen), replications = 400, verbose = FALSE)
  expect_equal(result$curve$power, direct$power)
  kw <- jt_spec(nrep = 400)
  kw$target_test$method <- "kruskal_wallis"
  expect_gt(result$curve$power, run_quietly(kw)$curve$power)
})

test_that("the Jonckheere-Terpstra test holds alpha when the groups don't differ", {
  spec <- jt_spec(nrep = 2000, shape = "skewed", means = list(10, 10, 10))
  expect_lt(abs(run_quietly(spec)$curve$power - 0.05), 0.02)
})

test_that("the Jonckheere-Terpstra test is refused where it doesn't apply", {
  within <- example_spec("anova_oneway_within")
  within$target_test$method <- "jonckheere_terpstra"
  expect_spec_problem(within, "'target_test > method' must be one of")
  exact <- jt_spec()
  exact$options$method <- "exact"
  expect_spec_problem(exact, "'options > method' 'exact' isn't available for this test")
})

test_that("the exported scripts reproduce both trend tests", {
  skip_unless_scripts_can_run()
  spec <- trend_spec(nrep = 100)
  expect_script_reproduces_power(spec, run_for_export(spec))
  spec <- jt_spec(nrep = 100, shape = "heavy_tailed")
  expect_script_reproduces_power(spec, run_for_export(spec))
  spec <- trend_spec(n = 396, nrep = 100)
  spec$target_test$alternative <- "greater"
  spec$options$group_ratio <- list(2, 1, 1, 2)
  spec$options$attrition <- 0.1
  expect_script_reproduces_power(spec, run_for_export(spec))
  spec <- jt_spec(n = 60, nrep = 100)
  spec$target_test$alternative <- "less"
  spec$population$means <- list(13, 11, 10)
  spec$options$group_ratio <- list(1, 1, 2)
  expect_script_reproduces_power(spec, run_for_export(spec))
})
