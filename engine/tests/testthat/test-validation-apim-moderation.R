# Validation: the actor-partner model with a pair-level moderator W (E44,
# 5 November 2026): W predicts each member's Y and moderates each actor
# effect (X1 x W on Y1, X2 x W on Y2).
#   1. agreement with an independent simulation: X1, X2 and W drawn as
#      correlated normals (MASS::mvrnorm()), the products formed by hand,
#      each Y's residual variance found numerically from a million draws
#      (not from powerkit's moments), the residuals correlated, and the
#      same model fitted with lavaan::sem() directly, without power4mome;
#      the moderation alone and jointly with the actor effects
#   2. Type I error of the moderation's test with no moderation
# Both are simulations of the same model, so no allowance beyond their
# Monte Carlo error. Skipped unless POWERKIT_FULL_VALIDATION=true.

apim_w_reps <- 2000L

apim_w_spec <- function(population, effect, seed, n) {
  validation_spec(
    design = "dyadic",
    template = "apim",
    variables = list(X = validation_variable("continuous", "X"), Y = validation_variable("continuous", "Y"),
      W = validation_variable("continuous", "W")),
    population = c(list(metric = "standardised"), population),
    target_test = list(effect = effect, method = "wald_z", alpha = 0.05),
    seed = seed,
    n = n,
    options = list(nrep = apim_w_reps)
  )
}

apim_w_by_hand <- function(population, labels, n, nrep, seed) {
  d <- isTRUE(population$distinguishable)
  b <- if (d) {
    with(population, c(a1 = actor_1, p21 = partner_21, a2 = actor_2, p12 = partner_12, w1 = w_y_1, w2 = w_y_2, m1 = moderation_1, m2 = moderation_2))
  } else {
    with(population, c(a1 = actor, p21 = partner, a2 = actor, p12 = partner, w1 = w_y, w2 = w_y, m1 = moderation, m2 = moderation))
  }
  r <- population$r_x
  rw <- population$r_xw
  sigma <- matrix(c(1, r, rw, r, 1, rw, rw, rw, 1), 3)
  means <- function(x) {
    cbind(b[["a1"]] * x[, 1] + b[["p21"]] * x[, 2] + b[["w1"]] * x[, 3] + b[["m1"]] * x[, 1] * x[, 3],
      b[["a2"]] * x[, 2] + b[["p12"]] * x[, 1] + b[["w2"]] * x[, 3] + b[["m2"]] * x[, 2] * x[, 3])
  }
  res_sd <- with_seed(seed, sqrt(1 - apply(means(MASS::mvrnorm(1e6, c(0, 0, 0), sigma)), 2, stats::var)))
  res_cov <- population$r_y * res_sd[1] * res_sd[2]
  fit_model <- paste(c("Y1 ~ a1*X1 + p21*X2 + w1*W + m1*X1W", "Y2 ~ a2*X2 + p12*X1 + w2*W + m2*X2W",
    if (!d) c("a1 == a2", "p21 == p12", "w1 == w2", "m1 == m2"), "Y1 ~~ Y2"), collapse = "\n")
  hits <- with_seed(seed + 1L, vapply(seq_len(nrep), function(i) {
    x <- MASS::mvrnorm(n, c(0, 0, 0), sigma)
    e <- MASS::mvrnorm(n, c(0, 0), matrix(c(res_sd[1]^2, res_cov, res_cov, res_sd[2]^2), 2))
    y <- means(x) + e
    data <- data.frame(X1 = x[, 1], X2 = x[, 2], W = x[, 3], X1W = x[, 1] * x[, 3], X2W = x[, 2] * x[, 3], Y1 = y[, 1], Y2 = y[, 2])
    fit <- tryCatch(suppressWarnings(lavaan::sem(fit_model, data = data)), error = function(e) NULL)
    if (is.null(fit) || !lavaan::lavInspect(fit, "converged")) return(NA)
    pe <- lavaan::parameterEstimates(fit)
    all(pe$pvalue[match(labels, pe$label)] < 0.05)
  }, logical(1)))
  hits <- hits[!is.na(hits)]
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / length(hits)))
}

shared_w <- list(distinguishable = FALSE, actor = -0.3, partner = -0.15, w_y = 0.2, moderation = 0.15, r_x = 0.2, r_xw = 0.1, r_y = 0.3)
own_w <- list(distinguishable = TRUE, actor_1 = -0.3, actor_2 = -0.25, partner_12 = -0.1, partner_21 = -0.15,
  w_y_1 = 0.2, w_y_2 = 0.1, moderation_1 = 0.2, moderation_2 = 0.1, r_x = 0.2, r_xw = -0.15, r_y = 0.3)

apim_w_cases <- list(
  list(label = "indistinguishable, the moderation", population = shared_w, effect = "moderation", labels = "m1", n = 200),
  list(label = "indistinguishable, the actor effect and its moderation together", population = shared_w,
    effect = "actor_and_moderation", labels = c("a1", "m1"), n = 200),
  list(label = "distinguishable, both moderations together", population = own_w, effect = "both_moderations", labels = c("m1", "m2"), n = 400)
)

for (case in apim_w_cases) {
  test_that(sprintf("APIM with a moderator, %s: agrees with an independent simulation (simulation)", case$label), {
    skip_unless_full_validation()
    skip_if_not_installed("MASS")
    reference <- apim_w_by_hand(case$population, case$labels, case$n, apim_w_reps, seed = 4451L)
    expect_power_agrees(engine_power(apim_w_spec(case$population, case$effect, seed = 4452, n = case$n)), reference)
  })
}

test_that("APIM with a moderator: Type I error near alpha with no moderation", {
  skip_unless_full_validation()
  null_w <- utils::modifyList(shared_w, list(moderation = 0))
  spec <- apim_w_spec(null_w, "moderation", seed = 4453, n = 200)
  # 4,000 replications: the rate is near 5.3% here, so 2,000 (Monte Carlo
  # SE 0.5 points) can cross 6% by chance.
  spec$options$nrep <- 4000L
  expect_type1_near(engine_power(spec), alpha = 0.05)
})

test_that("APIM with a moderator: with few pairs lavaan's Wald z test of the moderation is liberal (recorded size)", {
  skip_unless_full_validation()
  # lavaan's Wald z test treats the maximum-likelihood standard error as
  # known; with 60 pairs it rejected 7.2% of 4,000 studies with no
  # moderation (an independent simulation with lavaan alone, 5 November
  # 2026), 5.1% with 200 and 800 pairs. powerkit reports the power of the
  # test lavaan prints, so this records the size rather than asserting 5%.
  null_w <- utils::modifyList(shared_w, list(moderation = 0))
  spec <- apim_w_spec(null_w, "moderation", seed = 4454, n = 60)
  spec$options$nrep <- 4000L
  rate <- engine_power(spec)$power
  expect_gt(rate, 0.055)
  expect_lt(rate, 0.09)
})
