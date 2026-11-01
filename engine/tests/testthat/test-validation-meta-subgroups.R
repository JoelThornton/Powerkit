# Validation: a planned meta-analysis of subgroups (E66), the test that
# the average effect differs between kinds of studies.
#   1. analytic agreement: simulated meta-analyses written here. Under the
#      fixed-effect model, the between-groups Q statistic computed by
#      hand (sum of w_g (mean_g - grand mean)^2, chi-square with g - 1 df)
#      against metapower's mod_power(); under the random-effects model,
#      tau^2 known (metapower's model) against metapower's random-effects
#      power; and powerkit's Hartung-Knapp simulation against metafor
#      called directly in a loop, without Spower
#   2. published examples: a placeholder, for the maintainer
#   3. Type I error of the Hartung-Knapp test
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

subgroup_validation_spec <- function(effects, k, test = NULL, model = "random", nrep = NULL, seed = 1) {
  validation_spec(
    design = "meta_analysis",
    template = "subgroups",
    variables = list(Y = validation_variable("continuous", "Outcome")),
    population = list(metric = "d", effects = effects, study_size = 40, i2 = 0.5),
    target_test = c(list(effect = "moderator", method = "q_test", model = model, alpha = 0.05), if (!is.null(test)) list(test = test)),
    seed = seed,
    n = k,
    options = if (is.null(nrep)) list(nrep = NULL) else list(nrep = nrep)
  )
}

# k studies split equally between the kinds, the true effects within a
# kind from N(theta_g, tau2), each estimated with variance v.
subgroup_by_hand <- function(effects, k, model, nrep, seed) {
  theta <- unlist(effects)
  g <- length(theta)
  kind <- rep(seq_len(g), each = k / g)
  v <- 4 / 40 + mean(theta)^2 / (2 * 40)
  tau2 <- if (model == "fixed") 0 else 0.5 * v / 0.5
  w <- 1 / (v + tau2)
  with_seed(seed, mean(vapply(seq_len(nrep), function(i) {
    yi <- stats::rnorm(k, stats::rnorm(k, theta[kind], sqrt(tau2)), sqrt(v))
    means <- tapply(yi, kind, mean)
    q <- sum(w * (k / g) * (means - mean(yi))^2)
    q > stats::qchisq(0.95, g - 1)
  }, logical(1))))
}

for (model in c("fixed", "random")) {
  test_that(sprintf("subgroups, %s-effect model: metapower agrees with simulated meta-analyses (analytic)", model), {
    skip_unless_full_validation()
    spec <- subgroup_validation_spec(list(0.2, 0.5), 20, test = if (model == "random") "z", model = model)
    reference <- subgroup_by_hand(list(0.2, 0.5), 20, model, validation_nrep(), seed = 6601)
    expect_power_near(engine_power(spec), reference, reference_nrep = validation_nrep())
  })
}

test_that("subgroups, Hartung-Knapp: powerkit's simulation agrees with metafor called directly (analytic)", {
  skip_unless_full_validation()
  theta <- c(0.2, 0.5, 0.35)
  k <- 30
  kind <- rep(1:3, each = 10)
  v <- 4 / 40 + mean(theta)^2 / (2 * 40)
  reference <- with_seed(6602, mean(vapply(seq_len(2000), function(i) {
    yi <- stats::rnorm(k, stats::rnorm(k, theta[kind], sqrt(v)), sqrt(v))
    metafor::rma(yi = yi, vi = rep(v, k), mods = ~ factor(kind), method = "DL", test = "knha")$QMp < 0.05
  }, logical(1))))
  spec <- subgroup_validation_spec(as.list(theta), k, nrep = 2000L, seed = 6603)
  expect_power_near(engine_power(spec), reference, reference_nrep = 2000)
})

test_that("subgroups, Hartung-Knapp: Type I error near alpha when the kinds don't differ", {
  skip_unless_full_validation()
  expect_type1_near(engine_power(subgroup_validation_spec(list(0.3, 0.3), 20, nrep = 4000L, seed = 6604)), alpha = 0.05)
})

test_that("subgroups: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (a published power analysis of
  # a subgroup comparison in a meta-analysis).
  effects <- TODO_PUBLISHED_VALUE
  k <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(effects, k, published_power)
  expect_power_near(engine_power(subgroup_validation_spec(effects, k, test = "z")), published_power)
})
