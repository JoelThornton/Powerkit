# Validation: a yes/no outcome on each trial (E33 and E63 with Y binary).
# Backend: simr's powerSim() on makeGlmer(), with the Wald test glmer
# reports (or, for three or more conditions, simr's Wald chi-square through
# car) or the likelihood-ratio test.
#   1. analytic agreement: an independent simulation. The random effects
#      are drawn directly on the log-odds scale, each 0/1 response from its
#      probability, each data set fitted with lme4::glmer() and tested with
#      summary(), car::Anova() or anova(), without simr
#   2. published examples: a placeholder, for the maintainer
#   3. Type I error
# Logistic mixed models are slow to fit, so these use 1,000 replications.
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

binary_reps <- 1000L

binary_validation_spec <- function(template, levels, population, method, seed, n) {
  validation_spec(
    design = "mixed_model",
    template = template,
    variables = list(
      X = validation_variable("within_factor", "Condition", levels = levels),
      Y = validation_variable("binary", "Correct")
    ),
    population = c(list(metric = "probability"), population),
    target_test = list(effect = "condition", method = method, alpha = 0.05),
    seed = seed,
    n = n,
    options = list(nrep = binary_reps)
  )
}

pop_binary_two <- list(probabilities = list(0.7, 0.8), sd_participant = 0.6, sd_participant_slope = 0.3,
  sd_item = 0.5, items = 40, item_design = "between")
pop_binary_three <- list(probabilities = list(0.7, 0.8, 0.75), sd_participant = 0.6, sd_participant_condition = 0.3,
  sd_item = 0.5, items = 60, item_design = "between")

binary_by_hand <- function(p, three, method, n, nrep, seed) {
  probs <- unlist(p$probabilities)
  k <- length(probs)
  design <- expand.grid(participant = seq_len(n), item = seq_len(p$items))
  design$c <- ceiling(design$item / (p$items / k))
  logit <- stats::qlogis(probs)
  with_seed(seed, mean(vapply(seq_len(nrep), function(i) {
    u <- stats::rnorm(n, sd = p$sd_participant)
    w <- stats::rnorm(p$items, sd = p$sd_item)
    d <- design
    if (three) {
      uc <- matrix(stats::rnorm(n * k, sd = p$sd_participant_condition), n, k)
      eta <- logit[d$c] + u[d$participant] + uc[cbind(d$participant, d$c)] + w[d$item]
      d$cond <- factor(d$c)
      formula <- y ~ cond + (1 | participant) + (1 | participant:cond) + (1 | item)
    } else {
      # Conditions coded -0.5 and 0.5, the participants' slopes beside
      # their intercepts (uncorrelated here).
      d$cond <- ifelse(d$c == 1, -0.5, 0.5)
      v <- stats::rnorm(n, sd = p$sd_participant_slope)
      eta <- mean(logit) + diff(logit) * d$cond + u[d$participant] + v[d$participant] * d$cond + w[d$item]
      formula <- y ~ cond + (1 + cond | participant) + (1 | item)
    }
    d$y <- stats::rbinom(nrow(d), 1, stats::plogis(eta))
    d$participant <- factor(d$participant)
    d$item <- factor(d$item)
    fit <- tryCatch(suppressMessages(suppressWarnings(lme4::glmer(formula, data = d, family = stats::binomial()))),
      error = function(e) NULL)
    if (is.null(fit)) return(FALSE)
    p_value <- if (method == "likelihood_ratio") {
      reduced <- suppressMessages(suppressWarnings(stats::update(fit, . ~ . - cond)))
      stats::anova(reduced, fit)[["Pr(>Chisq)"]][2]
    } else if (three) {
      car::Anova(fit)["cond", "Pr(>Chisq)"]
    } else {
      summary(fit)$coefficients["cond", "Pr(>|z|)"]
    }
    isTRUE(p_value < 0.05)
  }, logical(1))))
}

cases <- list(
  list(label = "two conditions, Wald z", three = FALSE, method = "wald"),
  list(label = "two conditions, likelihood ratio", three = FALSE, method = "likelihood_ratio"),
  list(label = "three conditions, Wald chi-square", three = TRUE, method = "wald"),
  list(label = "three conditions, likelihood ratio (the app's default)", three = TRUE, method = "likelihood_ratio")
)

for (case in cases) {
  test_that(sprintf("yes/no trials, %s: agrees with an independent simulation (analytic)", case$label), {
    skip_unless_full_validation()
    p <- if (case$three) pop_binary_three else pop_binary_two
    template <- if (case$three) "crossed_conditions" else "crossed_two_condition"
    levels <- if (case$three) list("First", "Second", "Third") else list("First", "Second")
    spec <- binary_validation_spec(template, levels, p, case$method, seed = 6401, n = 30)
    reference <- binary_by_hand(p, case$three, case$method, 30, binary_reps, seed = 6402)
    expect_power_near(engine_power(spec), reference, reference_nrep = binary_reps)
  })
}

test_that("yes/no trials: Type I error near alpha with no difference", {
  skip_unless_full_validation()
  p <- pop_binary_two
  p$probabilities <- list(0.75, 0.75)
  estimate <- engine_power(binary_validation_spec("crossed_two_condition", list("First", "Second"), p, "wald", seed = 6403, n = 30))
  # 1,000 replications: a wider band than the 2,000-replication checks.
  expect_lt(abs(estimate$power - 0.05), 3 * sqrt(0.05 * 0.95 / binary_reps))
})

test_that("yes/no trials: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (a published power analysis for
  # a logistic mixed model with participants and items).
  population <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(population, n, published_power, reference_nrep)
  spec <- binary_validation_spec("crossed_two_condition", list("First", "Second"), population, "wald", seed = 6404, n = n)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})
