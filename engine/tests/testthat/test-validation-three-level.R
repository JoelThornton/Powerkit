# Validation: three levels (E64), people in groups in sites, the condition
# assigned to sites, groups or people. Backend: simr's powerSim() with
# lmerTest's Satterthwaite t test.
#   1. analytic agreement: an independent simulation. The site and group
#      effects (and the effect's variation) are drawn directly and the
#      residuals, each data set fitted with lmerTest::lmer() without simr
#   2. published examples: a placeholder, for the maintainer
#   3. Type I error
# 2,000 replications, as for the other mixed models.
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

three_reps <- 2000L

three_population <- list(icc_site = 0.1, icc_group = 0.05, group_size = 10, groups_per_site = 4)

three_validation_spec <- function(population, seed, n) {
  validation_spec(
    design = "mixed_model",
    template = "three_level",
    variables = list(X = validation_variable("between_factor", "Condition", levels = list("First", "Second")),
      Y = validation_variable("continuous", "Outcome")),
    population = c(list(metric = "standardised"), population),
    target_test = list(effect = "condition", method = "satterthwaite_t", alpha = 0.05),
    seed = seed,
    n = n,
    options = list(nrep = three_reps)
  )
}

three_by_hand <- function(p, n, nrep, seed) {
  sites <- n / (p$group_size * p$groups_per_site)
  d <- expand.grid(person = seq_len(p$group_size), group = seq_len(p$groups_per_site), site = seq_len(sites))
  half <- switch(p$assignment, site = d$site <= sites / 2, group = d$group <= p$groups_per_site / 2, person = d$person <= p$group_size / 2)
  d$cond <- ifelse(half, -0.5, 0.5)
  d$g <- (d$site - 1) * p$groups_per_site + d$group
  groups <- sites * p$groups_per_site
  effect_site <- p$icc_effect_site %||% 0
  effect_group <- p$icc_effect_group %||% 0
  terms <- c(if (effect_site > 0) "(1 + cond | site)" else "(1 | site)", if (effect_group > 0) "(1 + cond | site:group)" else "(1 | site:group)")
  formula <- stats::as.formula(paste("y ~ cond +", paste(terms, collapse = " + ")))
  sigma <- sqrt(1 - p$icc_site - p$icc_group)
  with_seed(seed, mean(vapply(seq_len(nrep), function(i) {
    u <- stats::rnorm(sites, sd = sqrt(p$icc_site))
    us <- stats::rnorm(sites, sd = sqrt(effect_site))
    v <- stats::rnorm(groups, sd = sqrt(p$icc_group))
    vs <- stats::rnorm(groups, sd = sqrt(effect_group))
    data <- d
    data$y <- p$d * d$cond + u[d$site] + us[d$site] * d$cond + v[d$g] + vs[d$g] * d$cond + stats::rnorm(nrow(d), sd = sigma)
    data$site <- factor(data$site)
    data$group <- factor(data$group)
    fit <- tryCatch(suppressMessages(suppressWarnings(lmerTest::lmer(formula, data = data))), error = function(e) NULL)
    !is.null(fit) && isTRUE(summary(fit)$coefficients["cond", "Pr(>|t|)"] < 0.05)
  }, logical(1))))
}

three_cases <- list(
  list(assignment = "site", d = 0.4, n = 640),
  list(assignment = "group", d = 0.3, n = 320, icc_effect_site = 0.02),
  list(assignment = "person", d = 0.25, n = 320, icc_effect_group = 0.02)
)

for (case in three_cases) {
  test_that(sprintf("three levels, %s assigned: agrees with an independent simulation (analytic)", case$assignment), {
    skip_unless_full_validation()
    skip_if_not_installed("lmerTest")
    p <- c(three_population, case[setdiff(names(case), "n")])
    reference <- three_by_hand(p, case$n, three_reps, seed = 6501)
    expect_power_near(engine_power(three_validation_spec(p, seed = 6502, n = case$n)), reference, reference_nrep = three_reps)
  })
}

# With no effect, the Satterthwaite test is never liberal, and its
# rejection rate agrees with the independent simulation's. It can be
# conservative: with groups assigned within 8 sites and the effect varying
# a little across them (icc_effect_site 0.02), 3.1% in powerkit and 3.65%
# in the independent simulation (2,000 data sets each, 1 November 2026),
# so a fixed band around alpha would fail a test that is behaving as it
# should.
test_that("three levels: Type I error at most alpha, and as in the independent simulation, for each assignment", {
  skip_unless_full_validation()
  for (case in three_cases) {
    p <- c(three_population, case[setdiff(names(case), "n")])
    p$d <- 0
    estimate <- engine_power(three_validation_spec(p, seed = 6503, n = case$n))
    expect_lt(estimate$power, 0.05 + 3 * sqrt(0.05 * 0.95 / three_reps))
    expect_power_near(estimate, three_by_hand(p, case$n, three_reps, seed = 6505), reference_nrep = three_reps)
  }
})

test_that("three levels: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer (a published three-level power
  # analysis, for example a cluster-randomised trial of schools).
  population <- TODO_PUBLISHED_VALUE
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE
  skip_if_todo(population, n, published_power, reference_nrep)
  expect_power_near(engine_power(three_validation_spec(population, seed = 6504, n = n)), published_power, reference_nrep = reference_nrep)
})
