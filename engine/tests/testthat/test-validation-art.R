# Validation: the aligned rank transform ANOVA for two between-participants
# factors.
# Backend: Spower simulation of powerkit's experiment p_art(), which calls
# ARTool's art() and artlm() and car's Anova() (Type III).
#   1. agreement with an independent simulation: the same cells drawn and
#      analysed by the aligned rank transform written out from its
#      published definition (Wobbrock, Findlater, Gergle and Higgins,
#      2011: subtract the cell means, add back the estimated effect, rank,
#      and read that effect's F test in the full factorial ANOVA of the
#      ranks), without ARTool, in balanced designs
#   2. Type I error for the interaction with skewed scores and main effects
#      present
#   3. published example: placeholder, for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

art_validation_spec <- function(means, sd, shape, effect, n) {
  a <- nrow(means)
  b <- ncol(means)
  validation_spec(
    design = "factorial_anova",
    template = if (a == 2 && b == 2) "2x2_between" else "factorial_between",
    variables = list(
      A = list(type = "between_factor", label = "A", levels = as.list(paste0("a", seq_len(a)))),
      B = list(type = "between_factor", label = "B", levels = as.list(paste0("b", seq_len(b)))),
      Y = validation_variable("continuous", "Score")
    ),
    population = list(metric = "raw", means = lapply(seq_len(a), function(i) as.list(means[i, ])), sd = sd, score_shape = shape),
    target_test = list(effect = effect, method = "aligned_rank_transform", alpha = 0.05),
    seed = 6301,
    n = n
  )
}

# The aligned rank transform written out for a balanced two-factor design:
# the residuals from the cell means plus the estimated effect (main effect
# of A: the A means minus the grand mean; the interaction: the cell means
# minus the A and B means plus the grand mean), ranked, and that effect's
# F test from the full factorial ANOVA of the ranks (sequential and Type
# III sums of squares agree in a balanced design).
art_p_by_hand <- function(data, effect) {
  cell <- stats::ave(data$Y, data$A, data$B)
  ma <- stats::ave(data$Y, data$A)
  mb <- stats::ave(data$Y, data$B)
  grand <- mean(data$Y)
  estimated <- switch(effect, main_effect_A = ma - grand, main_effect_B = mb - grand, interaction = cell - ma - mb + grand)
  data$R <- rank(data$Y - cell + estimated)
  table <- stats::anova(stats::lm(R ~ A * B, data = data))
  table[switch(effect, main_effect_A = "A", main_effect_B = "B", interaction = "A:B"), "Pr(>F)"]
}

art_by_hand <- function(means, sd, shape, effect, n_cell, nrep, seed) {
  draw <- switch(shape,
    normal = function(n) stats::rnorm(n),
    skewed = function(n) (stats::rchisq(n, df = 10) - 10) / sqrt(20),
    heavy_tailed = function(n) stats::rt(n, df = 3) / sqrt(3))
  cells <- expand.grid(B = seq_len(ncol(means)), A = seq_len(nrow(means)))
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    data <- do.call(rbind, lapply(seq_len(nrow(cells)), function(k) {
      data.frame(A = cells$A[k], B = cells$B[k], Y = means[cells$A[k], cells$B[k]] + sd * draw(n_cell))
    }))
    data$A <- factor(data$A)
    data$B <- factor(data$B)
    art_p_by_hand(data, effect) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

test_that("aligned rank transform: powerkit agrees with the procedure written out (simulation)", {
  skip_unless_full_validation()
  # The procedure written out gives ARTool's p-values on balanced data.
  for (effect in c("main_effect_A", "main_effect_B", "interaction")) {
    data <- with_seed(5, data.frame(A = factor(rep(1:2, each = 30)), B = factor(rep(1:3, 20)), Y = stats::rexp(60)))
    data$Y <- data$Y + (data$A == 2) * (data$B == 3)
    term <- switch(effect, main_effect_A = "A", main_effect_B = "B", interaction = "A:B")
    table <- anova(ARTool::art(Y ~ A * B, data = data))
    expect_equal(art_p_by_hand(data, effect), table$`Pr(>F)`[table$Term == term], tolerance = 1e-8, info = effect)
  }
  cases <- list(
    list(means = matrix(c(0, 0, 0, 0.6), 2), sd = 1, shape = "skewed", effect = "interaction", n = 160),
    list(means = matrix(c(0, 0.5, 0, 0.5, 0, 0.5), 2), sd = 1, shape = "heavy_tailed", effect = "main_effect_A", n = 90)
  )
  for (case in cases) {
    spec <- art_validation_spec(case$means, case$sd, case$shape, case$effect, case$n)
    reference <- art_by_hand(case$means, case$sd, case$shape, case$effect, case$n / length(case$means), 4000L, 63)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  }
})

test_that("aligned rank transform: Type I error of the interaction with main effects present (simulation)", {
  skip_unless_full_validation()
  # Both factors shift the scores, the interaction is 0, skewed scores.
  spec <- art_validation_spec(matrix(c(0, 0.5, 0.5, 1), 2), 1, "skewed", "interaction", 120)
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("aligned rank transform: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: a published power or sample-size example for
  # the aligned rank transform ANOVA; source, section, page).
  interaction_mean <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(interaction_mean, n, published_power)
  spec <- art_validation_spec(matrix(c(0, 0, 0, interaction_mean), 2), 1, "normal", "interaction", n)
  expect_power_near(engine_power(spec), exact_estimate(published_power))
})
