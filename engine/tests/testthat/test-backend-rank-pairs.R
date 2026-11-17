# Pairwise rank comparisons after the Kruskal-Wallis test (a Mann-Whitney
# test of each pair, or Dunn's test) and after Friedman's test (a
# signed-rank test of each pair, or Conover's test), simulated with Spower
# (17 November 2026). Few replications; accuracy is checked by
# test-validation-rank-pairs.R.

rank_pairs_spec <- function(method, shape = "skewed", n = NULL, nrep = 200, p_adjust = "holm", pair = c(1, 3)) {
  within <- method %in% c("wilcoxon_signed_rank", "conover")
  spec <- example_spec(if (within) "anova_oneway_within" else "anova_oneway_between")
  levels <- unlist(spec$variables$A$levels)
  spec$target_test$effect <- "pairwise"
  spec$target_test$method <- method
  spec$target_test$comparison <- as.list(levels[pair])
  spec$target_test$p_adjust <- p_adjust
  spec$population$score_shape <- shape
  spec$goal <- list(type = "power", n = n %||% if (within) 30 else 90)
  spec$options <- list(seed = 5, nrep = nrep)
  spec
}

test_that("each pairwise rank test equals a direct Spower call of powerkit's experiment", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  for (method in c("mann_whitney", "dunn", "wilcoxon_signed_rank", "conover")) {
    result <- run_quietly(rank_pairs_spec(method))
    expect_identical(result$provenance$backend, "Spower")
    expect_match(result$provenance$backend_function, "p_rank_pairs()", fixed = TRUE)
    expect_true(all(result$check_run$ok), label = method)
    # Spower reads its experiment unevaluated; vectors go in by name.
    within_means <- c(6, 6.2, 6.5)
    group_means <- c(10, 11, 13) / 6
    set.seed(5)
    direct <- if (method %in% c("wilcoxon_signed_rank", "conover")) {
      Spower::Spower(p_rank_pairs(n = 30, means = within_means, r = 0.6, shape = "skewed", test = method,
        first = 1, second = 3, p_adjust = "holm"), replications = 200, verbose = FALSE)
    } else {
      draw <- score_shape_sampler("skewed")
      gen <- function(n, k, n.ratios, means, ...) lapply(seq_len(k), function(g) means[g] + draw(n * n.ratios[g]))
      Spower::Spower(p_rank_pairs(n = 30, k = 3, means = group_means, gen_fun = gen, test = method,
        first = 1, second = 3, p_adjust = "holm"), replications = 200, verbose = FALSE)
    }
    expect_equal(result$curve$power, direct$power, label = method)
  }
})

test_that("the adjusted p-values are the packages' own, pair by pair", {
  set.seed(2)
  groups <- lapply(c(0, 0.3, 0.8), function(m) m + stats::rnorm(25))
  raw <- c(stats::wilcox.test(groups[[1]], groups[[2]])$p.value, stats::wilcox.test(groups[[1]], groups[[3]])$p.value,
    stats::wilcox.test(groups[[2]], groups[[3]])$p.value)
  expect_equal(rank_pair_p_values(groups, "mann_whitney", "holm"), stats::p.adjust(raw, "holm"))
  expect_equal(rank_pair_p_values(groups, "mann_whitney", "none"), raw)
  dunn <- PMCMRplus::kwAllPairsDunnTest(unlist(groups), factor(rep(1:3, each = 25)), p.adjust.method = "bonferroni")$p.value
  expect_equal(rank_pair_p_values(groups, "dunn", "bonferroni"), c(dunn["2", "1"], dunn["3", "1"], dunn["3", "2"]))
  y <- friedman_scores(20, c(0, 0.3, 0.8), 0.5, "normal")
  raw <- c(stats::wilcox.test(y[, 1], y[, 2], paired = TRUE)$p.value, stats::wilcox.test(y[, 1], y[, 3], paired = TRUE)$p.value,
    stats::wilcox.test(y[, 2], y[, 3], paired = TRUE)$p.value)
  expect_equal(rank_pair_p_values(y, "wilcoxon_signed_rank", "holm"), stats::p.adjust(raw, "holm"))
  conover <- PMCMRplus::frdAllPairsConoverTest(c(y), factor(rep(1:3, each = 20)), factor(rep(1:20, 3)), p.adjust.method = "holm")$p.value
  expect_equal(rank_pair_p_values(y, "conover", "holm"), c(conover["2", "1"], conover["3", "1"], conover["3", "2"]))
  # The pair is chosen by its places, whichever order it is named in.
  spec <- validate_quietly(rank_pairs_spec("dunn", pair = c(3, 1)))
  expect_identical(spower_inputs(spec)$args(90)[c("first", "second")], list(first = 1L, second = 3L))
})

test_that("the exported scripts reproduce the pairwise rank tests' power", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  for (method in c("mann_whitney", "conover")) {
    spec <- rank_pairs_spec(method, nrep = 100)
    expect_script_reproduces_power(spec, run_quietly(spec))
  }
})

test_that("pairwise rank specs are refused in plain English when they can't be run", {
  wrong_template <- rank_pairs_spec("conover")
  wrong_template$template <- "oneway_between"
  wrong_template$variables$A$type <- "between_factor"
  wrong_template$population$r <- NULL
  expect_spec_problem(wrong_template, "conover")
  not_pairwise <- rank_pairs_spec("dunn")
  not_pairwise$target_test$effect <- "main_effect_A"
  not_pairwise$target_test$comparison <- NULL
  not_pairwise$target_test$p_adjust <- NULL
  expect_spec_problem(not_pairwise, "compares pairs of groups: set 'target_test > effect' to \"pairwise\"")
  expect_spec_problem(rank_pairs_spec("conover") |> (\(s) { s$population$r <- -0.1; s })(), "its pairwise comparisons")
  several <- rank_pairs_spec("wilcoxon_signed_rank")
  several$population$sd <- list(90, 100, 110)
  expect_spec_problem(several, "the rank tests of pairs of conditions take one of each")
})
