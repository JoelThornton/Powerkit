# Validation: dyadic data, the actor-partner interdependence model (E44).
# Backend: power4mome's power4test() with test_parameters() on the APIM
# fitted by lavaan.
#   1. analytic agreement: an independent simulation. Both members' X are
#      drawn as correlated normals and each member's Y from the actor and
#      partner paths plus correlated residuals (MASS::mvrnorm()), then the
#      APIM is fitted with lavaan::sem() and the effect tested by its z
#      test, without power4mome
#   2. published examples: a placeholder, for the maintainer
#   3. Type I error
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

apim_reps <- 2000L

apim_validation_spec <- function(population, effect, seed, n) {
  validation_spec(
    design = "dyadic",
    template = "apim",
    variables = list(X = validation_variable("continuous", "X"), Y = validation_variable("continuous", "Y")),
    population = c(list(metric = "standardised"), population),
    target_test = list(effect = effect, method = "wald_z", alpha = 0.05),
    seed = seed,
    n = n,
    options = list(nrep = apim_reps)
  )
}

apim_by_hand <- function(population, effect, n, nrep, seed) {
  d <- isTRUE(population$distinguishable)
  b <- if (d) c(a1 = population$actor_1, p21 = population$partner_21, a2 = population$actor_2, p12 = population$partner_12) else
    c(a1 = population$actor, p21 = population$partner, a2 = population$actor, p12 = population$partner)
  r <- population$r_x
  r2 <- c(b[["a1"]]^2 + b[["p21"]]^2 + 2 * b[["a1"]] * b[["p21"]] * r, b[["a2"]]^2 + b[["p12"]]^2 + 2 * b[["a2"]] * b[["p12"]] * r)
  res_sd <- sqrt(1 - r2)
  res_cov <- population$r_y * res_sd[1] * res_sd[2]
  fit_model <- paste(c("Y1 ~ a1*X1 + p21*X2", "Y2 ~ a2*X2 + p12*X1", if (!d) c("a1 == a2", "p21 == p12"),
    "X1 ~~ X2", "Y1 ~~ Y2"), collapse = "\n")
  label <- c(actor = "a1", partner = "p21", actor_1 = "a1", actor_2 = "a2", partner_12 = "p12", partner_21 = "p21")[[effect]]
  with_seed(seed, mean(vapply(seq_len(nrep), function(i) {
    x <- MASS::mvrnorm(n, c(0, 0), matrix(c(1, r, r, 1), 2))
    e <- MASS::mvrnorm(n, c(0, 0), matrix(c(res_sd[1]^2, res_cov, res_cov, res_sd[2]^2), 2))
    data <- data.frame(X1 = x[, 1], X2 = x[, 2],
      Y1 = b[["a1"]] * x[, 1] + b[["p21"]] * x[, 2] + e[, 1], Y2 = b[["a2"]] * x[, 2] + b[["p12"]] * x[, 1] + e[, 2])
    fit <- tryCatch(suppressWarnings(lavaan::sem(fit_model, data = data)), error = function(e) NULL)
    if (is.null(fit) || !lavaan::lavInspect(fit, "converged")) return(FALSE)
    pe <- lavaan::parameterEstimates(fit)
    isTRUE(pe$pvalue[pe$label == label][1] < 0.05)
  }, logical(1))))
}

indistinguishable <- list(distinguishable = FALSE, actor = -0.3, partner = -0.15, r_x = 0.2, r_y = 0.3)
distinguishable <- list(distinguishable = TRUE, actor_1 = -0.3, actor_2 = -0.25, partner_12 = -0.1, partner_21 = -0.2,
  r_x = 0.2, r_y = 0.3)

apim_cases <- list(
  list(label = "indistinguishable, partner", population = indistinguishable, effect = "partner", n = 120),
  list(label = "indistinguishable, actor", population = indistinguishable, effect = "actor", n = 60),
  list(label = "distinguishable, partner of member 2 on member 1", population = distinguishable, effect = "partner_21", n = 120)
)

for (case in apim_cases) {
  test_that(sprintf("APIM, %s: agrees with an independent simulation (analytic)", case$label), {
    skip_unless_full_validation()
    skip_if_not_installed("MASS")
    reference <- apim_by_hand(case$population, case$effect, case$n, apim_reps, seed = 4401)
    expect_power_near(engine_power(apim_validation_spec(case$population, case$effect, seed = 4402, n = case$n)), reference,
      reference_nrep = apim_reps)
  })
}

test_that("APIM: Type I error near alpha with no partner effect, for both kinds of dyad", {
  skip_unless_full_validation()
  null_ind <- utils::modifyList(indistinguishable, list(partner = 0))
  expect_type1_near(engine_power(apim_validation_spec(null_ind, "partner", seed = 4403, n = 120)), alpha = 0.05)
  null_dis <- utils::modifyList(distinguishable, list(partner_21 = 0))
  expect_type1_near(engine_power(apim_validation_spec(null_dis, "partner_21", seed = 4404, n = 120)), alpha = 0.05)
})

test_that("APIM: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (a published APIM power
  # analysis). Transcribe the actor and partner effects, the correlations,
  # the number of dyads and the power.
  population <- TODO_PUBLISHED_VALUE
  effect <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(population, effect, n, published_power, reference_nrep)
  expect_power_near(engine_power(apim_validation_spec(population, effect, seed = 4405, n = n)), published_power,
    reference_nrep = reference_nrep)
})
