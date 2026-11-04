# Validation: PERMANOVA (permutational MANOVA) of several outcomes across
# groups.
# Backend: Spower simulation of powerkit's experiment p_permanova(), which
# calls vegan's adonis2() on Euclidean distances between the standardised
# outcomes.
#   1. the pseudo-F written out from its definition (Anderson, 2001, cited
#      by adonis2()'s help: with Euclidean distances, the between-group sum
#      of squared distances over k - 1, divided by the within-group sum over
#      n - k) equals adonis2()'s F statistic
#   2. agreement with an independent simulation: the same groups drawn and
#      tested by that pseudo-F and 999 random permutations of the group
#      labels, without vegan
#   3. Type I error with skewed scores
#   4. published example: placeholder, for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

perm_validation_spec <- function(means, sds, r, shape, n) {
  k <- nrow(means)
  p <- ncol(means)
  validation_spec(
    design = "basic_test",
    template = "manova",
    variables = c(
      list(A = list(type = "between_factor", label = "Group", levels = as.list(paste0("g", seq_len(k))))),
      stats::setNames(lapply(seq_len(p), function(j) validation_variable("continuous", paste0("Outcome ", j))), paste0("Y", seq_len(p)))
    ),
    population = list(metric = "raw", means = lapply(seq_len(k), function(g) as.list(means[g, ])), sds = as.list(sds), r = r, score_shape = shape),
    target_test = list(effect = "main_effect_A", method = "permanova", alpha = 0.05),
    seed = 6601,
    n = n
  )
}

# The pseudo-F of Euclidean distances: with the outcomes standardised, the
# between-group and within-group sums of squares, summed over outcomes.
perm_pseudo_f <- function(y, group) {
  k <- nlevels(group)
  n <- nrow(y)
  centred <- scale(y, scale = FALSE)
  means <- rowsum(centred, group) / as.vector(table(group))
  between <- sum(as.vector(table(group)) * rowSums(means^2))
  within <- sum(centred^2) - between
  (between / (k - 1)) / (within / (n - k))
}

perm_p_by_hand <- function(y, group, permutations = 999) {
  observed <- perm_pseudo_f(y, group)
  permuted <- vapply(seq_len(permutations), function(i) perm_pseudo_f(y, sample(group)), numeric(1))
  (1 + sum(permuted >= observed - 1e-12)) / (permutations + 1)
}

perm_by_hand <- function(means, sds, r, shape, n_group, nrep, seed) {
  k <- nrow(means)
  p <- ncol(means)
  draw <- switch(shape,
    normal = function(n) stats::rnorm(n),
    skewed = function(n) (stats::rchisq(n, df = 10) - 10) / sqrt(20),
    heavy_tailed = function(n) stats::rt(n, df = 3) / sqrt(3))
  group <- factor(rep(seq_len(k), each = n_group))
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    common <- stats::rnorm(k * n_group)
    y <- vapply(seq_len(p), function(j) means[as.integer(group), j] + sds[j] * (sqrt(r) * common + sqrt(1 - r) * draw(k * n_group)), numeric(k * n_group))
    perm_p_by_hand(scale(y), group) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("PERMANOVA: the pseudo-F written out is adonis2()'s F, and powerkit agrees with a separate permutation test (simulation)", {
  skip_unless_full_validation()
  data <- with_seed(5, permanova_scores(25, matrix(c(0, 0, 0, 0.5, 0.3, 0.1, 0.2, 0.6, 0), 3, byrow = TRUE), c(1, 2, 3), 0.3, "skewed"))
  y <- scale(as.matrix(data[, -1]))
  fit <- vegan::adonis2(y ~ group, data = data, method = "euclidean", permutations = 99, by = "terms")
  expect_equal(perm_pseudo_f(y, data$group), fit["group", "F"], tolerance = 1e-10)
  cases <- list(
    list(means = matrix(c(0, 0, 0, 0.4, 0.3, 0.2, 0.5, 0.4, 0.4), 3, byrow = TRUE), sds = c(1, 1, 1), r = 0.4, shape = "skewed", n_group = 30),
    list(means = matrix(c(0, 0, 0.5, 0), 2, byrow = TRUE), sds = c(2, 1), r = 0.2, shape = "heavy_tailed", n_group = 40)
  )
  for (case in cases) {
    spec <- perm_validation_spec(case$means, case$sds, case$r, case$shape, nrow(case$means) * case$n_group)
    reference <- perm_by_hand(case$means, case$sds, case$r, case$shape, case$n_group, 2000L, 66)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  }
})

test_that("PERMANOVA: Type I error with skewed scores (simulation)", {
  skip_unless_full_validation()
  spec <- perm_validation_spec(matrix(0, 3, 3), c(1, 2, 3), 0.5, "skewed", 90)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("PERMANOVA: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power or sample-size example for
  # PERMANOVA; source, section, page).
  difference <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(difference, n, published_power)
  spec <- perm_validation_spec(matrix(c(0, 0, difference, difference), 2, byrow = TRUE), c(1, 1), 0.3, "normal", n)
  expect_power_near(engine_power(spec), exact_estimate(published_power))
})
