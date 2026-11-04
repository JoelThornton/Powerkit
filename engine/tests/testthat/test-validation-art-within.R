# Validation: the aligned rank transform ANOVA with a within-participants
# factor (a mixed design, A between and B within; and two within-
# participants factors).
# Backend: Spower simulation of powerkit's experiment p_art_within(), which
# calls ARTool's art() with the participants as an error term and artlm().
#   1. agreement with an independent simulation: correlated scores drawn
#      separately and analysed by the aligned rank transform written out
#      from its published definition (Wobbrock, Findlater, Gergle and
#      Higgins, 2011: subtract the cell means, add back the estimated
#      effect, rank, and read that effect's F test in the repeated measures
#      ANOVA of the ranks, with the participants as an error term), without
#      ARTool, in balanced designs
#   2. Type I error of the interaction with skewed scores and both main
#      effects present
#   3. published example: placeholder, for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

artw_validation_spec <- function(means, sd, r, shape, effect, n, within_both = FALSE) {
  a <- nrow(means)
  b <- ncol(means)
  validation_spec(
    design = "factorial_anova",
    template = if (within_both) "factorial_within" else if (a == 2 && b == 2) "2x2_mixed" else "mixed",
    variables = list(
      A = list(type = if (within_both) "within_factor" else "between_factor", label = "A", levels = as.list(paste0("a", seq_len(a)))),
      B = list(type = "within_factor", label = "B", levels = as.list(paste0("b", seq_len(b)))),
      Y = validation_variable("continuous", "Score")
    ),
    population = list(metric = "raw", means = lapply(seq_len(a), function(i) as.list(means[i, ])), sd = sd, r = r, score_shape = shape),
    target_test = list(effect = effect, method = "aligned_rank_transform", alpha = 0.05),
    seed = 6501,
    n = n
  )
}

# The aligned rank transform written out for a balanced two-factor design
# with repeated measures: the residuals from the cell means plus the
# estimated effect, ranked, and that effect's F test in aov() with the
# participants as an error term.
artw_p_by_hand <- function(data, effect) {
  cell <- stats::ave(data$Y, data$A, data$B)
  ma <- stats::ave(data$Y, data$A)
  mb <- stats::ave(data$Y, data$B)
  grand <- mean(data$Y)
  estimated <- switch(effect, main_effect_A = ma - grand, main_effect_B = mb - grand, interaction = cell - ma - mb + grand)
  data$R <- rank(data$Y - cell + estimated)
  term <- switch(effect, main_effect_A = "A", main_effect_B = "B", interaction = "A:B")
  for (stratum in summary(stats::aov(R ~ A * B + Error(id), data = data))) {
    table <- stratum[[1]]
    at <- match(term, trimws(rownames(table)))
    if (!is.na(at)) return(table[at, "Pr(>F)"])
  }
  NA_real_
}

# Correlated scores drawn separately: each person's scores from the
# multivariate normal with compound symmetry (normal scores), or as a
# common level plus independent deviations of the chosen shape.
artw_by_hand <- function(means, sd, r, shape, effect, n, within_both, nrep, seed) {
  draw <- switch(shape,
    normal = function(n) stats::rnorm(n),
    skewed = function(n) (stats::rchisq(n, df = 10) - 10) / sqrt(20),
    heavy_tailed = function(n) stats::rt(n, df = 3) / sqrt(3))
  a <- nrow(means)
  b <- ncol(means)
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    if (within_both) {
      level <- stats::rnorm(n)
      data <- expand.grid(id = seq_len(n), B = seq_len(b), A = seq_len(a))
      data$Y <- means[cbind(data$A, data$B)] + sd * (sqrt(r) * level[data$id] + sqrt(1 - r) * draw(nrow(data)))
    } else {
      per_group <- n / a
      data <- expand.grid(person = seq_len(per_group), B = seq_len(b), A = seq_len(a))
      data$id <- (data$A - 1) * per_group + data$person
      level <- stats::rnorm(n)
      data$Y <- means[cbind(data$A, data$B)] + sd * (sqrt(r) * level[data$id] + sqrt(1 - r) * draw(nrow(data)))
    }
    data$id <- factor(data$id)
    data$A <- factor(data$A)
    data$B <- factor(data$B)
    artw_p_by_hand(data, effect) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("within-participants aligned rank transform: powerkit agrees with the procedure written out (simulation)", {
  skip_unless_full_validation()
  # The procedure written out gives ARTool's p-values on balanced data.
  for (effect in c("main_effect_A", "main_effect_B", "interaction")) {
    data <- with_seed(5, expand.grid(B = factor(1:3), A = factor(1:2), person = 1:15))
    data$id <- factor((as.integer(data$A) - 1) * 15 + data$person)
    data$Y <- with_seed(6, stats::rexp(nrow(data))) + (data$A == 2) * (data$B == 3) + with_seed(7, stats::rnorm(30))[data$id]
    term <- switch(effect, main_effect_A = "A", main_effect_B = "B", interaction = "A:B")
    table <- anova(ARTool::art(Y ~ A * B + Error(id), data = data))
    expect_equal(artw_p_by_hand(data, effect), table$`Pr(>F)`[table$Term == term], tolerance = 1e-8, info = effect)
  }
  cases <- list(
    list(means = matrix(c(0, 0, 0, 0.5), 2), sd = 1, r = 0.5, shape = "skewed", effect = "interaction", n = 60, within_both = FALSE),
    list(means = matrix(c(0, 0.3, 0, 0.3, 0, 0.3), 2), sd = 1, r = 0.6, shape = "heavy_tailed", effect = "main_effect_B", n = 40, within_both = FALSE),
    list(means = matrix(c(0, 0, 0.2, 0.5), 2), sd = 1, r = 0.5, shape = "normal", effect = "interaction", n = 40, within_both = TRUE)
  )
  for (case in cases) {
    spec <- artw_validation_spec(case$means, case$sd, case$r, case$shape, case$effect, case$n, case$within_both)
    reference <- artw_by_hand(case$means, case$sd, case$r, case$shape, case$effect, case$n, case$within_both, 4000L, 65)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  }
})

test_that("within-participants aligned rank transform: Type I error of the interaction with main effects present (simulation)", {
  skip_unless_full_validation()
  # Both factors shift the scores, the interaction is 0, skewed scores.
  spec <- artw_validation_spec(matrix(c(0, 0.5, 0.5, 1), 2), 1, 0.5, "skewed", "interaction", 60)
  expect_type1_near(engine_power(spec), alpha = 0.05)
  spec <- artw_validation_spec(matrix(c(0, 0.5, 0.5, 1), 2), 1, 0.5, "skewed", "interaction", 40, within_both = TRUE)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("within-participants aligned rank transform: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power or sample-size example for
  # the aligned rank transform with a within-participants factor; source,
  # section, page).
  interaction_mean <- TODO_PUBLISHED_VALUE
  r <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(interaction_mean, r, n, published_power)
  spec <- artw_validation_spec(matrix(c(0, 0, 0, interaction_mean), 2), 1, r, "normal", "interaction", n)
  expect_power_near(engine_power(spec), exact_estimate(published_power))
})
