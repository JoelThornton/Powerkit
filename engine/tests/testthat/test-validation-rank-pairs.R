# Validation: pairwise rank comparisons after the Kruskal-Wallis test (a
# Mann-Whitney test of each pair, or Dunn's test) and after Friedman's test
# (a signed-rank test of each pair, or Conover's test), with the p-values
# of every pair adjusted together and the power of one pair. Backend:
# Spower simulation of powerkit's p_rank_pairs() experiment; Dunn's and
# Conover's tests are PMCMRplus's. No package powerkit builds on has a
# formula. Build guide section 6:
#   1. published-example agreement (to choose: a published power analysis
#      for a pairwise rank comparison)
#   2. agreement with simulations written out separately: groups drawn here
#      with stats::rt() and Dunn's z tests written out from mean ranks
#      (continuous scores have no ties, so no tie correction); conditions drawn with
#      MASS::mvrnorm() and tested with stats::wilcox.test() and PMCMRplus's
#      Conover test called here
#   3. Type I error, unadjusted, for every test and shape
# Values transcribed from a published source or G*Power (tests marked
# "(published)" or "(G*Power value)", or a value whose comment cites its
# source) are owned by the maintainer: do not edit them. Other expected
# values were written with the code (CLAUDE.md, Non-negotiables).
# Skipped unless POWERKIT_FULL_VALIDATION=true.

rank_pairs_validation_spec <- function(method, means, shape, seed, n, r = NULL, p_adjust = "holm", pair = c(1, 3), alpha = 0.05) {
  v <- validation_variable
  within <- method %in% c("wilcoxon_signed_rank", "conover")
  levels <- paste(if (within) "Condition" else "Group", seq_along(means))
  validation_spec(
    design = "factorial_anova",
    template = if (within) "oneway_within" else "oneway_between",
    variables = list(A = v(if (within) "within_factor" else "between_factor", "Factor", levels = levels), Y = v("continuous", "Score")),
    population = c(list(metric = "standardised", means = as.list(means), sd = 1, score_shape = shape), if (within) list(r = r)),
    target_test = list(effect = "pairwise", method = method, comparison = as.list(levels[pair]), p_adjust = p_adjust, alpha = alpha),
    seed = seed,
    n = n
  )
}

# 1. Published example -----------------------------------------------------------

test_that("pairwise rank comparisons: match a published example (published)", {
  skip_unless_full_validation()
  # Source to choose and transcribe: a published power analysis for a
  #   pairwise rank comparison (Dunn's test after the Kruskal-Wallis test,
  #   or a Mann-Whitney test of each pair) giving the group means in SD
  #   units, the shape of the scores, the pair, the adjustment, the group
  #   size, alpha and the power.
  method <- TODO_PUBLISHED_VALUE # "dunn" or "mann_whitney"
  means <- TODO_PUBLISHED_VALUE # group means in SD units
  shape <- TODO_PUBLISHED_VALUE # "normal", "skewed" or "heavy_tailed"
  p_adjust <- TODO_PUBLISHED_VALUE # "holm", "bonferroni" or "none"
  n_total <- TODO_PUBLISHED_VALUE # total number of participants
  alpha <- TODO_PUBLISHED_VALUE # alpha
  published_power <- TODO_PUBLISHED_VALUE # power of the pair (0 to 1)
  skip_if_todo(method, means, shape, p_adjust, n_total, alpha, published_power)

  spec <- rank_pairs_validation_spec(method, means, shape, seed = 701, n = n_total, p_adjust = p_adjust, alpha = alpha)
  expect_power_near(engine_power(spec), published_power)
})

# 2. Agreement with simulations written out separately ------------------------------

test_that("Dunn's test, heavy-tailed scores: powerkit matches Dunn's z tests written out separately", {
  skip_unless_full_validation()
  means <- c(0, 0.3, 0.7)
  dunn_by_hand <- function(n) {
    y <- unlist(lapply(means, function(m) m + stats::rt(n, df = 3) / sqrt(3)))
    g <- rep(1:3, each = n)
    ranks <- rank(y)
    mean_rank <- tapply(ranks, g, mean)
    N <- length(y)
    pairs <- utils::combn(3, 2)
    z <- (mean_rank[pairs[1, ]] - mean_rank[pairs[2, ]]) / sqrt(N * (N + 1) / 12 * (2 / n))
    stats::p.adjust(2 * stats::pnorm(-abs(z)), "holm")[2] # groups 1 and 3
  }
  direct <- run_spower(quote(dunn_by_hand(n = 40)), 0.05, validation_nrep(), 702,
    data = list(dunn_by_hand = dunn_by_hand, means = means))
  spec <- rank_pairs_validation_spec("dunn", means, "heavy_tailed", seed = 703, n = 120)
  expect_power_agrees(engine_power(spec), direct)
})

test_that("Mann-Whitney tests of each pair, skewed scores: powerkit matches a simulation written out separately", {
  skip_unless_full_validation()
  means <- c(0, 0.3, 0.7)
  mann_whitney_by_hand <- function(n) {
    groups <- lapply(means, function(m) m + (stats::rchisq(n, df = 10) - 10) / sqrt(20))
    p <- c(stats::wilcox.test(groups[[1]], groups[[2]])$p.value, stats::wilcox.test(groups[[1]], groups[[3]])$p.value,
      stats::wilcox.test(groups[[2]], groups[[3]])$p.value)
    stats::p.adjust(p, "bonferroni")[2]
  }
  direct <- run_spower(quote(mann_whitney_by_hand(n = 40)), 0.05, validation_nrep(), 704,
    data = list(mann_whitney_by_hand = mann_whitney_by_hand, means = means))
  spec <- rank_pairs_validation_spec("mann_whitney", means, "skewed", seed = 705, n = 120, p_adjust = "bonferroni")
  expect_power_agrees(engine_power(spec), direct)
})

test_that("signed-rank and Conover tests of pairs of conditions, normal scores: powerkit matches a simulation written out separately", {
  skip_unless_full_validation()
  skip_if_not_installed("MASS")
  means <- c(0, 0.2, 0.5)
  sigma <- matrix(0.5, 3, 3) + diag(0.5, 3)
  for (method in c("wilcoxon_signed_rank", "conover")) {
    pairs_by_hand <- function(n) {
      y <- MASS::mvrnorm(n, means, sigma)
      if (method == "conover") {
        p <- PMCMRplus::frdAllPairsConoverTest(c(y), factor(rep(1:3, each = n)), factor(rep(seq_len(n), 3)), p.adjust.method = "holm")$p.value
        return(p["3", "1"])
      }
      p <- c(stats::wilcox.test(y[, 1], y[, 2], paired = TRUE)$p.value, stats::wilcox.test(y[, 1], y[, 3], paired = TRUE)$p.value,
        stats::wilcox.test(y[, 2], y[, 3], paired = TRUE)$p.value)
      stats::p.adjust(p, "holm")[2]
    }
    direct <- run_spower(quote(pairs_by_hand(n = 40)), 0.05, validation_nrep(), 706,
      data = list(pairs_by_hand = pairs_by_hand, means = means, sigma = sigma, method = method))
    spec <- rank_pairs_validation_spec(method, means, "normal", seed = 707, n = 40, r = 0.5)
    expect_power_agrees(engine_power(spec), direct)
  }
})

# 3. Type I error ------------------------------------------------------------------

test_that("pairwise rank comparisons: Type I error of one pair, unadjusted, is near alpha for every test and shape", {
  skip_unless_full_validation()
  for (method in c("mann_whitney", "dunn", "wilcoxon_signed_rank", "conover")) {
    within <- method %in% c("wilcoxon_signed_rank", "conover")
    # The signed-rank test assumes symmetric differences: skewed scores are
    # its user's choice, not a check of the test.
    for (shape in if (method == "wilcoxon_signed_rank") c("normal", "heavy_tailed") else c("normal", "skewed", "heavy_tailed")) {
      spec <- rank_pairs_validation_spec(method, c(0, 0, 0), shape, seed = 708, n = if (within) 30 else 90,
        r = if (within) 0.5, p_adjust = "none")
      expect_type1_near(engine_power(spec), alpha = 0.05)
    }
  }
})
