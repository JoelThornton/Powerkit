# Validation: Bayes factor t-tests with an informed analysis prior (a t
# prior with a location other than 0 or degrees of freedom other than 1).
# Method: powerkit's exact calculation around bfpwr's Bayes factor,
# bfpwr::tbf01() (bayes-informed-t.R; docs/conventions.md, Departure 37).
# Build guide section 6:
#   1. published examples (placeholders for the maintainer)
#   2. agreement with simulated Bayes factors: data drawn under the design
#      prior, the t statistic from stats::t.test(), and the Bayes factor
#      from bfpwr::tbf01(), so the check relies on neither powerkit's
#      crossing points nor its noncentral t sums; small samples included,
#      where bfpwr's powertbf01() fails for these priors
#   3. the no-effect side: strong evidence for no effect, and misleading
#      strong evidence for an effect, when there is none
# Values transcribed from a published source (tests marked "(published)",
# or a value whose comment cites its source) are owned by the maintainer:
# do not edit them. Other expected values were written with the code
# (CLAUDE.md, Non-negotiables).
# Skipped unless POWERKIT_FULL_VALIDATION=true.

informed_validation_spec <- function(template, effect, seed, n, effect_sd = 0, threshold = 10,
                                     location = 0.3, scale = 0.15, df = 1, alternative = "two_sided") {
  v <- validation_variable
  variables <- switch(
    template,
    one_sample_t = list(Y = v("continuous", "Score")),
    paired_t = list(X = v("within_factor", "Time", levels = list("Before", "After")), Y = v("continuous", "Score")),
    independent_t = list(X = v("binary", "Group", levels = list("Control", "Treatment")), Y = v("continuous", "Score"))
  )
  population <- list(metric = "standardised", effect_sd = effect_sd)
  population[[if (template == "paired_t") "dz" else "d"]] <- effect
  validation_spec(
    design = "basic_test",
    template = template,
    variables = variables,
    population = population,
    target_test = list(
      effect = if (template == "one_sample_t") "mean" else "mean_difference",
      method = "bayes_factor", alternative = alternative, evidence_threshold = threshold,
      prior_location = location, prior_scale = scale, prior_df = df
    ),
    seed = seed,
    n = n
  )
}

# The proportion of simulated studies whose Bayes factor reaches the
# threshold. `n` is per group for two groups and the number of people (or
# pairs) otherwise.
simulated_informed_power <- function(type, n, effect, effect_sd, threshold, location, scale, df,
                                     alternative, nrep, seed, evidence_for_null = FALSE) {
  set.seed(seed)
  t <- vapply(seq_len(nrep), function(i) {
    delta <- stats::rnorm(1, effect, effect_sd)
    if (type == "two.sample") {
      stats::t.test(stats::rnorm(n, delta), stats::rnorm(n), var.equal = TRUE)$statistic
    } else {
      stats::t.test(stats::rnorm(n, delta))$statistic
    }
  }, numeric(1))
  bf01 <- bfpwr::tbf01(t = t, n = n, plocation = location, pscale = scale, pdf = df, type = type,
    alternative = alternative)
  mean(if (evidence_for_null) bf01 >= threshold else bf01 <= 1 / threshold)
}

# 1. Published examples ------------------------------------------------------------

test_that("an informed prior: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: to be chosen by the maintainer: a published power or sample
  #   size for an informed Bayes factor t-test (for example from a paper
  #   on design analysis with informed priors). Transcribe the design
  #   (one sample, paired or two groups), the prior's location, scale and
  #   degrees of freedom, the design prior's mean and SD, the threshold
  #   (as BF10), the direction, the sample size per group or in total, and
  #   the probability of strong evidence. If the figure comes from a
  #   simulation, also transcribe its number of simulated studies.
  template <- TODO_PUBLISHED_VALUE # "independent_t", "paired_t" or "one_sample_t"
  effect <- TODO_PUBLISHED_VALUE
  effect_sd <- TODO_PUBLISHED_VALUE
  location <- TODO_PUBLISHED_VALUE
  scale <- TODO_PUBLISHED_VALUE
  df <- TODO_PUBLISHED_VALUE
  threshold <- TODO_PUBLISHED_VALUE
  alternative <- TODO_PUBLISHED_VALUE # "greater", "less" or "two_sided"
  total_n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  reference_nrep <- TODO_PUBLISHED_VALUE # NULL if not from a simulation
  skip_if_todo(template, effect, effect_sd, location, scale, df, threshold, alternative, total_n, published_power, reference_nrep)
  spec <- informed_validation_spec(template, effect, seed = 301, n = total_n, effect_sd = effect_sd, threshold = threshold,
    location = location, scale = scale, df = df, alternative = alternative)
  expect_power_near(engine_power(spec), published_power, reference_nrep = reference_nrep)
})

# 2. Agreement with simulated Bayes factors ----------------------------------------

informed_cases <- list(
  # bfpwr question 2's prior and design prior, at sizes where powertbf01() fails.
  list("one_sample_t", "one.sample", n = 5, effect = 0.4, effect_sd = 0.1, location = 0.3, scale = 0.15, df = 1, alternative = "two_sided"),
  list("one_sample_t", "one.sample", n = 10, effect = 0.4, effect_sd = 0.1, location = 0.3, scale = 0.15, df = 1, alternative = "two_sided"),
  list("one_sample_t", "one.sample", n = 40, effect = 0.4, effect_sd = 0.1, location = 0.3, scale = 0.15, df = 1, alternative = "two_sided"),
  list("paired_t", "paired", n = 25, effect = 0.35, effect_sd = 0, location = 0.35, scale = 0.1, df = 3, alternative = "greater"),
  list("independent_t", "two.sample", n = 30, effect = 0.5, effect_sd = 0, location = 0.5, scale = 0.2, df = 3, alternative = "two_sided"),
  list("independent_t", "two.sample", n = 15, effect = -0.6, effect_sd = 0.2, location = -0.5, scale = 0.3, df = 30, alternative = "less")
)

for (case in informed_cases) {
  label <- sprintf("informed prior t(%s, %s, %s df), %s, n %s, effect %s (SD %s), %s", case$location, case$scale, case$df,
    case[[1]], case$n, case$effect, case$effect_sd, case$alternative)
  test_that(paste0(label, ": matches simulated Bayes factors"), {
    skip_unless_full_validation()
    total <- if (case[[2]] == "two.sample") 2 * case$n else case$n
    spec <- informed_validation_spec(case[[1]], case$effect, seed = 311, n = total, effect_sd = case$effect_sd,
      location = case$location, scale = case$scale, df = case$df, alternative = case$alternative)
    alternative <- if (case$alternative == "two_sided") "two.sided" else case$alternative
    nrep <- validation_nrep()
    simulated <- simulated_informed_power(case[[2]], case$n, case$effect, case$effect_sd, 10, case$location, case$scale,
      case$df, alternative, nrep, seed = 311)
    expect_power_near(engine_power(spec), simulated, reference_nrep = nrep)
  })
}

# 3. The no-effect side ------------------------------------------------------------

test_that("an informed prior: with no effect, the chances of evidence for no effect and of misleading evidence match simulated Bayes factors", {
  skip_unless_full_validation()
  spec <- validate_quietly(informed_validation_spec("independent_t", 0.5, seed = 321, n = 60, location = 0.5, scale = 0.2, df = 3))
  inputs <- bfpwr_inputs(spec)
  nrep <- validation_nrep()
  for_null <- simulated_informed_power("two.sample", 30, 0, 0, 10, 0.5, 0.2, 3, "two.sided", nrep, seed = 322, evidence_for_null = TRUE)
  misleading <- simulated_informed_power("two.sample", 30, 0, 0, 10, 0.5, 0.2, 3, "two.sided", nrep, seed = 323)
  exact <- list(
    for_null = bft_chance_exact(inputs, 60, for_effect = FALSE, dpm = 0, dpsd = 0),
    misleading = bft_chance_exact(inputs, 60, for_effect = TRUE, dpm = 0, dpsd = 0)
  )
  expect_power_near(list(power = exact$for_null, mcse = 0), for_null, reference_nrep = nrep)
  expect_power_near(list(power = exact$misleading, mcse = 0), misleading, reference_nrep = nrep)
})
