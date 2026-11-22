# Independent simulations for the validation tests (docs/next.md item 24,
# part 1). Each one draws data from the study as the researcher describes
# it on the input screen and runs the usual test in base R (or MASS), with
# no call to the package the card wraps. A comparison with the package
# called directly checks that powerkit passes the right arguments; these
# check what the arguments mean (direction, one or two groups, per group or
# in total, true or observed correlations), which the package and powerkit
# could otherwise get wrong together. Used only by test-validation-*.R.

# The proportion of `nrep` simulated studies in which `one_study()` (which
# returns TRUE when the test is significant) succeeds.
independent_power <- function(one_study, nrep, seed) {
  set.seed(seed)
  mean(vapply(seq_len(nrep), function(i) isTRUE(one_study()), logical(1)))
}

# Compound symmetry: every pair of conditions correlates r, each with SD sd.
compound_symmetry <- function(k, sd, r) sd^2 * (r + (1 - r) * diag(k))

# Moderation in regression (InteractionPoweR's parametrisation): X and W
# standard normal with correlation r_x_w; the product XW, standardised,
# uncorrelated with both (as it is for normal X and W); Y built from the
# correlations of X, W and XW with Y. The correlations are between true
# scores: each observed score is its true score plus independent error,
# with the reliability given. Each study fits lm(Y ~ X * W) to the
# observed scores and tests the product's coefficient, two-sided.
independent_interaction_power <- function(n, r_x_y, r_w_y, r_xw_y, r_x_w,
                                          rel_x = 1, rel_w = 1, rel_y = 1,
                                          alpha = 0.05, nrep, seed) {
  r <- diag(3)
  r[1, 2] <- r[2, 1] <- r_x_w
  beta <- solve(r, c(r_x_y, r_w_y, r_xw_y))
  residual_sd <- sqrt(1 - sum(beta * (r %*% beta)))
  observed <- function(true, reliability) {
    sqrt(reliability) * true + sqrt(1 - reliability) * stats::rnorm(length(true))
  }
  independent_power(function() {
    xw <- MASS::mvrnorm(n, c(0, 0), r[1:2, 1:2])
    x <- xw[, 1]
    w <- xw[, 2]
    product <- x * w / sqrt(1 + r_x_w^2)
    y <- beta[1] * x + beta[2] * w + beta[3] * product + stats::rnorm(n, sd = residual_sd)
    d <- data.frame(x = observed(x, rel_x), w = observed(w, rel_w), y = observed(y, rel_y))
    summary(stats::lm(y ~ x * w, data = d))$coefficients["x:w", "Pr(>|t|)"] < alpha
  }, nrep, seed)
}

# An ordinal outcome in two groups under proportional odds: group 1's
# shares from the lowest category; in group 2 the odds of being above each
# cut-point are odds_ratio times group 1's. n1 = round(n / (1 + ratio)) and
# the rest are in group 2. Each study fits MASS::polr() and tests the
# group's coefficient by its Wald z test, two-sided.
independent_ordinal_power <- function(shares, odds_ratio, n, ratio = 1, alpha = 0.05, nrep, seed) {
  k <- length(shares)
  n1 <- floor(n / (1 + ratio) + 0.5)
  n2 <- n - n1
  above_1 <- 1 - cumsum(shares)[-k]
  above_2 <- stats::plogis(stats::qlogis(above_1) + log(odds_ratio))
  shares_2 <- -diff(c(1, above_2, 0))
  group <- rep(0:1, c(n1, n2))
  independent_power(function() {
    y <- factor(c(sample.int(k, n1, TRUE, shares), sample.int(k, n2, TRUE, shares_2)),
      levels = seq_len(k), ordered = TRUE)
    # A study that leaves a category empty is analysed with the categories
    # it has, as a researcher would.
    y <- droplevels(y)
    if (nlevels(y) < 2) return(FALSE)
    fit <- suppressWarnings(MASS::polr(y ~ group, Hess = TRUE))
    z <- stats::coef(fit)[["group"]] / sqrt(stats::vcov(fit)["group", "group"])
    abs(z) > stats::qnorm(1 - alpha / 2)
  }, nrep, seed)
}

# Repeated measures: one within-participants factor (rows of `means` are
# the levels of a between-participants factor when there is one, equal
# groups of n / rows). Scores are multivariate normal with compound
# symmetry. Each study runs stats::aov() with an Error stratum for
# participants and reads the uncorrected F test of `term` ("B", "A" or
# "A:B" with groups; "B" alone without).
independent_rm_anova_power <- function(means, sd, r, n, term, alpha = 0.05, nrep, seed) {
  means <- if (is.matrix(means)) means else matrix(means, nrow = 1)
  groups <- nrow(means)
  k <- ncol(means)
  per_group <- n / groups
  stopifnot(per_group == round(per_group))
  sigma <- compound_symmetry(k, sd, r)
  d <- data.frame(
    id = factor(rep(seq_len(n), each = k)),
    A = factor(rep(rep(seq_len(groups), each = per_group), each = k)),
    B = factor(rep(seq_len(k), n))
  )
  formula <- if (groups > 1) y ~ A * B + Error(id / B) else y ~ B + Error(id / B)
  stratum <- if (term == "A") "Error: id" else "Error: id:B"
  independent_power(function() {
    d$y <- unlist(lapply(seq_len(groups), function(g) {
      as.vector(t(MASS::mvrnorm(per_group, means[g, ], sigma)))
    }))
    table <- summary(stats::aov(formula, data = d))[[stratum]][[1]]
    table[trimws(rownames(table)) == term, "Pr(>F)"] < alpha
  }, nrep, seed)
}

# For a large-sample formula against simulated studies: the difference may
# be up to the formula's approximation error, `allowance`, as well as
# Monte Carlo error on both sides (99.9%).
expect_power_within_approximation <- function(estimate, reference, reference_nrep, allowance, level = 0.999) {
  se <- sqrt(estimate$mcse^2 + reference * (1 - reference) / reference_nrep)
  half_width <- z_for(level) * se + allowance
  expect(
    abs(estimate$power - reference) <= half_width,
    sprintf(
      "Simulated power %.4f; powerkit's %.4f differs by %.4f, more than %.4f (Monte Carlo error at %g%% plus the formula's allowance of %.3f).",
      reference, estimate$power, abs(estimate$power - reference), half_width, 100 * level, allowance
    )
  )
  invisible(estimate)
}

# Equivalence by two one-sided t-tests (TOST) at alpha each: "two" groups
# of n / 2 (Student's t, the second group's mean delta SDs above the
# first), or "one" sample of n (a one-sample or paired test of the mean or
# mean difference delta). Equivalence is shown when both tests reject.
independent_tost_power <- function(type, delta, bound, n, alpha = 0.05, nrep, seed) {
  independent_power(function() {
    if (type == "two") {
      first <- stats::rnorm(n / 2)
      second <- stats::rnorm(n / 2, delta)
      args <- list(second, first, var.equal = TRUE)
    } else {
      args <- list(stats::rnorm(n, delta))
    }
    lower <- do.call(stats::t.test, c(args, list(mu = -bound, alternative = "greater")))$p.value
    upper <- do.call(stats::t.test, c(args, list(mu = bound, alternative = "less")))$p.value
    max(lower, upper) < alpha
  }, nrep, seed)
}

# Score shapes as the input screen names them, each with mean 0 and SD 1.
independent_score_shape <- function(shape) {
  switch(shape,
    normal = function(n) stats::rnorm(n),
    skewed = function(n) (stats::rchisq(n, df = 10) - 10) / sqrt(20),
    heavy_tailed = function(n) stats::rt(n, df = 3) / sqrt(3)
  )
}

# Rank tests by stats::wilcox.test(): two groups (n1 control, n2 treated,
# the treated scores shifted up by d SDs) or one set of differences (n,
# shifted by d), each of the chosen shape; `alternative` as wilcox.test()
# reads it, the treated group or the difference first.
independent_wilcox_power <- function(d, shape, n1, n2 = NULL, alternative = "two.sided",
                                     alpha = 0.05, nrep, seed) {
  draw <- independent_score_shape(shape)
  independent_power(function() {
    p <- if (is.null(n2)) {
      stats::wilcox.test(draw(n1) + d, alternative = alternative)$p.value
    } else {
      stats::wilcox.test(draw(n2) + d, draw(n1), alternative = alternative)$p.value
    }
    p < alpha
  }, nrep, seed)
}

# A yes/no outcome in a between-participants factorial: `probabilities`
# lists each level of A's chance of "yes" at each level of B; n / cells
# people per cell. Each study fits glm(y ~ A * B, binomial) with sum-to-zero
# contrasts and tests `term` ("A", "B" or "A:B") by the Wald chi-square of
# its coefficients.
independent_logistic_factorial_power <- function(probabilities, term, n, alpha = 0.05, nrep, seed) {
  p <- matrix(unlist(probabilities), nrow = length(probabilities), byrow = TRUE)
  d <- expand.grid(A = factor(seq_len(nrow(p))), B = factor(seq_len(ncol(p))))
  per_cell <- n / nrow(d)
  stopifnot(per_cell == round(per_cell))
  d <- d[rep(seq_len(nrow(d)), each = per_cell), ]
  chance <- p[cbind(as.integer(d$A), as.integer(d$B))]
  independent_power(function() {
    d$y <- stats::rbinom(nrow(d), 1, chance)
    fit <- stats::glm(y ~ A * B, family = stats::binomial(), data = d,
      contrasts = list(A = stats::contr.sum, B = stats::contr.sum))
    columns <- which(attr(stats::model.matrix(fit), "assign") == match(term, attr(stats::terms(fit), "term.labels")))
    b <- stats::coef(fit)[columns]
    v <- stats::vcov(fit)[columns, columns, drop = FALSE]
    stats::pchisq(drop(t(b) %*% solve(v, b)), length(columns), lower.tail = FALSE) < alpha
  }, nrep, seed)
}

# Three-way moderation (InteractionPoweR's parametrisation): X, W and Z
# standard normal with the given correlations; the products XW, XZ, WZ
# and XWZ of the standardised scores; Y's correlations with X, W, Z and
# the two-way products as given, and b_XWZ the coefficient of the product
# XWZ itself (not standardised again). The predictors' correlations come
# from a large sample (`big` draws). Returns the population: the
# correlation matrix of the seven terms, Y's coefficients on the
# standardised terms, the terms' means and SDs, R-squared with and
# without XWZ, and the predictors' correlations.
independent_three_way_population <- function(pop, big = 2e6, seed = 1) {
  set.seed(seed)
  rx <- diag(3)
  rx[1, 2] <- rx[2, 1] <- pop$r_X_W
  rx[1, 3] <- rx[3, 1] <- pop$r_X_Z
  rx[2, 3] <- rx[3, 2] <- pop$r_W_Z
  terms <- three_way_terms(MASS::mvrnorm(big, rep(0, 3), rx))
  r <- stats::cor(terms)
  scale <- apply(terms, 2, stats::sd)
  y_r <- c(pop$r_X_Y, pop$r_W_Y, pop$r_Z_Y, pop$r_XW_Y, pop$r_XZ_Y, pop$r_WZ_Y)
  b7 <- pop$b_XWZ * scale[[7]]
  beta <- c(solve(r[1:6, 1:6], y_r - r[1:6, 7] * b7), b7)
  list(
    rx = rx, r = r, beta = beta, centre = colMeans(terms), scale = scale,
    r2_full = sum(beta * (r %*% beta)),
    r2_without = sum(y_r * solve(r[1:6, 1:6], y_r))
  )
}

three_way_terms <- function(m) {
  cbind(m, m[, 1] * m[, 2], m[, 1] * m[, 3], m[, 2] * m[, 3], m[, 1] * m[, 2] * m[, 3])
}

# Simulated studies of that population: new predictors in every study,
# each observed score its true score plus error at the reliability given,
# and lm(y ~ x * w * z) testing the three-way product, two-sided.
independent_three_way_power <- function(population, n, rel = c(X = 1, W = 1, Z = 1, Y = 1),
                                        alpha = 0.05, nrep, seed) {
  residual_sd <- sqrt(1 - population$r2_full)
  observed <- function(true, reliability) {
    sqrt(reliability) * true + sqrt(1 - reliability) * stats::rnorm(length(true))
  }
  independent_power(function() {
    m <- MASS::mvrnorm(n, rep(0, 3), population$rx)
    standardised <- sweep(sweep(three_way_terms(m), 2, population$centre), 2, population$scale, "/")
    y <- drop(standardised %*% population$beta) + stats::rnorm(n, sd = residual_sd)
    d <- data.frame(
      x = observed(m[, 1], rel[["X"]]), w = observed(m[, 2], rel[["W"]]),
      z = observed(m[, 3], rel[["Z"]]), y = observed(y, rel[["Y"]])
    )
    summary(stats::lm(y ~ x * w * z, data = d))$coefficients["x:w:z", "Pr(>|t|)"] < alpha
  }, nrep, seed)
}

# First-stage moderated mediation (PROCESS model 7): X and W standard
# normal with correlation r_x_w; M = a1 X + a2 W + a3 XW + error, where XW
# is the product of the standardised X and W (not standardised again, as
# power4mome builds it); Y = b M + c' X + error; errors set so that M and
# Y have variance 1. Each study fits the two regressions with lm() and
# tests the index of moderated mediation, a3 * b, by a Monte Carlo
# interval (`draws` draws of a3 and b from normal distributions at their
# estimates and standard errors, independent across the two equations).
independent_modmed7_power <- function(a1, a2, a3, b, c_prime, n, r_x_w = 0, draws = 1000,
                                      alpha = 0.05, nrep, seed) {
  sigma <- matrix(c(1, r_x_w, r_x_w, 1), 2)
  var_m <- a1^2 + a2^2 + 2 * a1 * a2 * r_x_w + a3^2 * (1 + r_x_w^2)
  var_y <- b^2 + c_prime^2 + 2 * b * c_prime * (a1 + a2 * r_x_w)
  independent_power(function() {
    xw <- MASS::mvrnorm(n, c(0, 0), sigma)
    x <- xw[, 1]
    w <- xw[, 2]
    m <- a1 * x + a2 * w + a3 * x * w + stats::rnorm(n, sd = sqrt(1 - var_m))
    y <- b * m + c_prime * x + stats::rnorm(n, sd = sqrt(1 - var_y))
    first <- summary(stats::lm(m ~ x * w))$coefficients
    second <- summary(stats::lm(y ~ m + x))$coefficients
    index <- stats::rnorm(draws, first["x:w", 1], first["x:w", 2]) *
      stats::rnorm(draws, second["m", 1], second["m", 2])
    limits <- stats::quantile(index, c(alpha / 2, 1 - alpha / 2))
    limits[[1]] > 0 || limits[[2]] < 0
  }, nrep, seed)
}

# PROCESS model 14 (W moderates M -> Y), drawn from the standardised paths
# as the input screen describes them: X and W standard normal with
# correlation r_x_w, M = a X + e, Y = b1 M + b2 W + b3 M W + c' X + e,
# each residual variance set so that M and Y have variance 1 (the
# product M W is not standardised again). Under normality the product is
# uncorrelated with X, W and M, and its variance is 1 + cor(M, W)^2.
# Both equations are fitted by lm(), and the index of moderated
# mediation, a * b3, is tested by a Monte Carlo interval as for model 7.
independent_modmed14_power <- function(a, b1, b2, b3, c_prime, n, r_x_w = 0, draws = 1000,
                                       alpha = 0.05, nrep, seed) {
  sigma <- matrix(c(1, r_x_w, r_x_w, 1), 2)
  r_m_w <- a * r_x_w
  var_y <- b1^2 + b2^2 + c_prime^2 + b3^2 * (1 + r_m_w^2) +
    2 * b1 * b2 * r_m_w + 2 * b1 * c_prime * a + 2 * b2 * c_prime * r_x_w
  independent_power(function() {
    xw <- MASS::mvrnorm(n, c(0, 0), sigma)
    x <- xw[, 1]
    w <- xw[, 2]
    m <- a * x + stats::rnorm(n, sd = sqrt(1 - a^2))
    y <- b1 * m + b2 * w + b3 * m * w + c_prime * x + stats::rnorm(n, sd = sqrt(1 - var_y))
    first <- summary(stats::lm(m ~ x))$coefficients
    second <- summary(stats::lm(y ~ m * w + x))$coefficients
    index <- stats::rnorm(draws, first["x", 1], first["x", 2]) *
      stats::rnorm(draws, second["m:w", 1], second["m:w", 2])
    limits <- stats::quantile(index, c(alpha / 2, 1 - alpha / 2))
    limits[[1]] > 0 || limits[[2]] < 0
  }, nrep, seed)
}

# Moderated mediation with two parallel mediators, W on both X -> M links
# (PROCESS model 7 with two mediators): X and W independent standard
# normals; M_k = a1_k X + a2_k W + a3_k X W + e_k, the residuals of M1
# and M2 correlated `residual`, each M with variance 1; Y = b1 M1 + b2 M2
# + c' X + e with variance 1. The index through M1, a3_1 * b1, is tested
# by a Monte Carlo interval from lm(m1 ~ x * w) and lm(y ~ m1 + m2 + x).
independent_parallel_modmed7_power <- function(a_m1, a_m2, b1, b2, c_prime, residual, n,
                                               draws = 1000, alpha = 0.05, nrep, seed) {
  systematic <- function(a) a[[1]]^2 + a[[2]]^2 + a[[3]]^2
  e1 <- 1 - systematic(a_m1)
  e2 <- 1 - systematic(a_m2)
  error_cov <- residual * sqrt(e1 * e2)
  cov_m <- sum(a_m1 * a_m2) + error_cov
  var_y <- b1^2 + b2^2 + c_prime^2 + 2 * b1 * b2 * cov_m +
    2 * b1 * c_prime * a_m1[[1]] + 2 * b2 * c_prime * a_m2[[1]]
  errors <- matrix(c(e1, error_cov, error_cov, e2), 2)
  independent_power(function() {
    x <- stats::rnorm(n)
    w <- stats::rnorm(n)
    e <- MASS::mvrnorm(n, c(0, 0), errors)
    m1 <- a_m1[[1]] * x + a_m1[[2]] * w + a_m1[[3]] * x * w + e[, 1]
    m2 <- a_m2[[1]] * x + a_m2[[2]] * w + a_m2[[3]] * x * w + e[, 2]
    y <- b1 * m1 + b2 * m2 + c_prime * x + stats::rnorm(n, sd = sqrt(1 - var_y))
    first <- summary(stats::lm(m1 ~ x * w))$coefficients
    second <- summary(stats::lm(y ~ m1 + m2 + x))$coefficients
    index <- stats::rnorm(draws, first["x:w", 1], first["x:w", 2]) *
      stats::rnorm(draws, second["m1", 1], second["m1", 2])
    limits <- stats::quantile(index, c(alpha / 2, 1 - alpha / 2))
    limits[[1]] > 0 || limits[[2]] < 0
  }, nrep, seed)
}
