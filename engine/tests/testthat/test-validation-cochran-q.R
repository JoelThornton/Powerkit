# Validation: Cochran's Q, a yes/no answer from every person once in each of
# three or more conditions (design "mixed_model", template "repeated_glmm",
# target_test > method "cochran_q", E75; E26 points to it).
# Backend: Spower running powerkit's experiment p_repeated_cochran(): each
# person's intercept from N(0, sd_person^2), each answer with chance
# plogis(log odds of the condition + intercept), each study tested with
# stats::friedman.test() on the 0/1 answers, which is Cochran's Q.
#   1. analytic agreement: an independent simulation, each answer drawn by
#      cutting a latent logistic variable (not rbinom()), and Cochran's Q
#      computed from its own formula, Q = (k - 1) (k sum C_j^2 - N^2) /
#      (k N - sum R_i^2), with C_j the column totals, R_i the row totals and
#      N the grand total, referred to the chi-square distribution on k - 1
#      degrees of freedom, without friedman.test() or Spower
#   2. Type I error with the same chance of 'yes' in every condition
#   3. published example: a placeholder, for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

cochran_reps <- 4000L

cochran_validation_spec <- function(probabilities, sd_person, n, seed, nrep = cochran_reps) {
  validation_spec(
    design = "mixed_model",
    template = "repeated_glmm",
    variables = list(
      X = validation_variable("within_factor", "Condition", levels = as.list(LETTERS[seq_along(probabilities)])),
      Y = validation_variable("binary", "Outcome")
    ),
    population = list(metric = "probability", probabilities = as.list(probabilities), sd_person = sd_person, measurements = 1L),
    target_test = list(effect = "condition", method = "cochran_q", alpha = 0.05),
    seed = seed,
    n = n,
    options = list(nrep = nrep)
  )
}

# An independent simulation: the share of studies with Cochran's Q
# significant at alpha 0.05.
cochran_by_hand <- function(probabilities, sd_person, n, nrep, seed) {
  k <- length(probabilities)
  eta <- stats::qlogis(probabilities)
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    u <- stats::rnorm(n, sd = sd_person)
    latent <- matrix(rep(eta, each = n) + rep(u, times = k) + stats::rlogis(n * k), nrow = n)
    x <- latent > 0
    rows <- rowSums(x)
    cols <- colSums(x)
    total <- sum(x)
    denominator <- k * total - sum(rows^2)
    if (denominator == 0) return(FALSE)
    q <- (k - 1) * (k * sum(cols^2) - total^2) / denominator
    stats::pchisq(q, k - 1, lower.tail = FALSE) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

cochran_cases <- list(
  list(label = "three conditions, people who differ", probabilities = c(0.5, 0.6, 0.65), sd_person = 1, n = 100),
  list(label = "four conditions, little difference between people", probabilities = c(0.3, 0.3, 0.4, 0.45), sd_person = 0.3, n = 80),
  list(label = "three conditions, rare answers and people who differ a lot", probabilities = c(0.1, 0.15, 0.25), sd_person = 1.5, n = 120)
)

for (case in cochran_cases) {
  test_that(sprintf("Cochran's Q, %s: agrees with an independent simulation (analytic)", case$label), {
    skip_unless_full_validation()
    spec <- cochran_validation_spec(case$probabilities, case$sd_person, case$n, seed = 2601)
    reference <- cochran_by_hand(case$probabilities, case$sd_person, case$n, cochran_reps, seed = 2602)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0)
  })
}

test_that("Cochran's Q: Type I error near alpha with the same chance in every condition", {
  skip_unless_full_validation()
  # 4,000 replications: within 3 Monte Carlo SEs of 0.05.
  band <- 3 * sqrt(0.05 * 0.95 / cochran_reps)
  null <- engine_power(cochran_validation_spec(c(0.4, 0.4, 0.4), 1, 60, seed = 2603))
  expect_lt(abs(null$power - 0.05), band)
  rare <- engine_power(cochran_validation_spec(c(0.2, 0.2, 0.2, 0.2), 0.5, 150, seed = 2604))
  expect_lt(abs(rare$power - 0.05), band)
})

test_that("Cochran's Q: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (a published power analysis for
  # Cochran's Q with three or more matched yes/no measurements; source,
  # section, page).
  probabilities <- TODO_PUBLISHED_VALUE
  sd_person <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(probabilities, sd_person, n, published_power, reference_nrep)
  spec <- cochran_validation_spec(probabilities, sd_person, n, seed = 2605)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})
